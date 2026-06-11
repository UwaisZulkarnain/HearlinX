import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../config/api_config.dart';
import '../models/screening.dart';
import 'api_service.dart';

class OfflineService {
  OfflineService({ApiService? apiService}) {
    if (apiService != null) {
      // Kept for constructor compatibility; sync uses ApiConfig.baseUrl.
    }
  }

  static const _databaseName = 'hearlinx_offline.db';
  static const _databaseVersion = 4;
  static const _pendingScreeningsTable = 'pending_screenings';
  static const _syncStatusPending = 'pending';
  static const _syncStatusSyncing = 'syncing';
  static const _syncStatusFailed = 'failed';
  static Database? _database;

  Future<String> get databasePath async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/$_databaseName';
  }

  Future<Database> get database async {
    final existingDatabase = _database;
    if (existingDatabase != null) {
      return existingDatabase;
    }

    final path = await databasePath;
    final openedDatabase = await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: (db, version) async {
        await _createPendingScreeningsTable(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
            'ALTER TABLE $_pendingScreeningsTable ADD COLUMN screening_date TEXT',
          );
        }
        if (oldVersion < 4) {
          await _addPendingScreeningSyncColumns(db);
        }
      },
    );

    _database = openedDatabase;
    return openedDatabase;
  }

  Future<void> _createPendingScreeningsTable(Database db) async {
    await db.execute('''
      CREATE TABLE $_pendingScreeningsTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        baby_id TEXT NOT NULL,
        screening_type TEXT NOT NULL,
        ear_left TEXT NOT NULL,
        ear_right TEXT NOT NULL,
        notes TEXT,
        screening_date TEXT,
        created_at TEXT NOT NULL,
        sync_status TEXT NOT NULL DEFAULT 'pending',
        sync_attempts INTEGER NOT NULL DEFAULT 0,
        last_sync_attempt TEXT,
        error_code TEXT,
        error_message TEXT
      )
    ''');
  }

  Future<void> _addPendingScreeningSyncColumns(Database db) async {
    await db.execute(
      'ALTER TABLE $_pendingScreeningsTable ADD COLUMN sync_status TEXT NOT NULL DEFAULT \'pending\'',
    );
    await db.execute(
      'ALTER TABLE $_pendingScreeningsTable ADD COLUMN sync_attempts INTEGER NOT NULL DEFAULT 0',
    );
    await db.execute(
      'ALTER TABLE $_pendingScreeningsTable ADD COLUMN last_sync_attempt TEXT',
    );
    await db.execute(
      'ALTER TABLE $_pendingScreeningsTable ADD COLUMN error_code TEXT',
    );
    await db.execute(
      'ALTER TABLE $_pendingScreeningsTable ADD COLUMN error_message TEXT',
    );
  }

  Future<void> savePendingScreening(Screening screening) async {
    final db = await database;
    await db.insert(_pendingScreeningsTable, {
      'baby_id': screening.babyId,
      'screening_type': screening.screeningType,
      'ear_left': screening.earLeft,
      'ear_right': screening.earRight,
      'notes': screening.notes,
      'screening_date': screening.screeningDate,
      'created_at': DateTime.now().toIso8601String(),
      'sync_status': _syncStatusPending,
      'sync_attempts': 0,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> getPendingScreeningCount() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) AS count FROM $_pendingScreeningsTable WHERE sync_status IN (?, ?, ?)',
      [_syncStatusPending, _syncStatusFailed, _syncStatusSyncing],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<List<Map<String, dynamic>>> getPendingScreenings() async {
    final db = await database;
    return db.query(
      _pendingScreeningsTable,
      where: 'sync_status IN (?, ?)',
      whereArgs: [_syncStatusPending, _syncStatusFailed],
      orderBy: 'created_at ASC',
    );
  }

  Future<Map<String, dynamic>> syncPendingScreenings(String token) async {
    final db = await database;
    final rows = await db.rawQuery(
      '''
      SELECT * FROM $_pendingScreeningsTable
      WHERE sync_status IN (?, ?)
        AND (
          sync_status != ?
          OR last_sync_attempt IS NULL
          OR datetime(last_sync_attempt) < datetime('now', '-5 minutes')
        )
      ORDER BY created_at ASC
    ''',
      [_syncStatusPending, _syncStatusFailed, _syncStatusSyncing],
    );

    var syncedCount = 0;
    var failedCount = 0;

    for (final row in rows) {
      final localId = row['id'] as int?;
      if (localId == null) {
        continue;
      }

      final now = DateTime.now().toIso8601String();
      final currentAttempts = await _getSyncAttempts(db, localId);

      await db.update(
        _pendingScreeningsTable,
        {
          'sync_status': _syncStatusSyncing,
          'sync_attempts': currentAttempts + 1,
          'last_sync_attempt': now,
          'error_code': null,
          'error_message': null,
        },
        where: 'id = ?',
        whereArgs: [localId],
      );

      final screening = Screening(
        babyId: row['baby_id'] as String? ?? '',
        screeningType: row['screening_type'] as String? ?? '',
        earLeft: row['ear_left'] as String? ?? '',
        earRight: row['ear_right'] as String? ?? '',
        notes: row['notes'] as String?,
        screeningDate: row['screening_date'] as String?,
      );

      try {
        final response = await http.Client()
            .post(
              Uri.parse('${ApiConfig.baseUrl}/screenings/'),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $token',
              },
              body: jsonEncode({
                'baby_id': screening.babyId,
                'screening_type': screening.screeningType,
                'ear_left': screening.earLeft,
                'ear_right': screening.earRight,
                'notes': screening.notes,
                if (screening.screeningDate != null)
                  'screening_date': screening.screeningDate,
              }),
            )
            .timeout(const Duration(seconds: 15));

        if (response.statusCode >= 200 && response.statusCode < 300) {
          await db.delete(
            _pendingScreeningsTable,
            where: 'id = ?',
            whereArgs: [localId],
          );
          syncedCount += 1;
          continue;
        }

        if (response.statusCode == 401) {
          return {
            'synced': syncedCount,
            'failed': failedCount,
            'authError': true,
          };
        }

        if (response.statusCode == 404) {
          await _markFailedScreening(
            db,
            localId,
            '404',
            'Baby not found or no longer exists',
          );
          failedCount += 1;
          continue;
        }

        final errorMessage = response.reasonPhrase?.isNotEmpty == true
            ? response.reasonPhrase!
            : response.body.isNotEmpty
            ? response.body
            : 'Request failed';
        await _markFailedScreening(
          db,
          localId,
          'network',
          'HTTP ${response.statusCode}: $errorMessage',
        );
        failedCount += 1;
      } on TimeoutException {
        await _markFailedScreening(
          db,
          localId,
          'timeout',
          'Connection timed out',
        );
        failedCount += 1;
      } catch (e) {
        await _markFailedScreening(db, localId, 'network', e.toString());
        failedCount += 1;
      }
    }

    return {'synced': syncedCount, 'failed': failedCount, 'authError': false};
  }

  Future<List<Map<String, dynamic>>> getFailedScreenings() async {
    final db = await database;
    return db.query(
      _pendingScreeningsTable,
      where: 'sync_status = ?',
      whereArgs: [_syncStatusFailed],
      orderBy: 'created_at DESC',
    );
  }

  Future<void> retryFailedScreening(int id) async {
    final db = await database;
    await db.update(
      _pendingScreeningsTable,
      {
        'sync_status': _syncStatusPending,
        'error_code': null,
        'error_message': null,
        'last_sync_attempt': null,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteFailedScreening(int id) async {
    final db = await database;
    await db.delete(_pendingScreeningsTable, where: 'id = ?', whereArgs: [id]);
  }

  Future<Map<String, int>> getSyncStats() async {
    final db = await database;
    final rows = await db.rawQuery(
      'SELECT sync_status, COUNT(*) AS count FROM $_pendingScreeningsTable GROUP BY sync_status',
    );

    final stats = <String, int>{
      _syncStatusPending: 0,
      _syncStatusSyncing: 0,
      _syncStatusFailed: 0,
    };

    for (final row in rows) {
      final status = row['sync_status'] as String?;
      final count = Sqflite.firstIntValue([row]) ?? 0;
      if (status == null || !stats.containsKey(status)) {
        continue;
      }
      stats[status] = count;
    }

    final totalRows = await db.rawQuery(
      'SELECT COUNT(*) AS count FROM $_pendingScreeningsTable',
    );

    return {
      _syncStatusPending: stats[_syncStatusPending] ?? 0,
      _syncStatusSyncing: stats[_syncStatusSyncing] ?? 0,
      _syncStatusFailed: stats[_syncStatusFailed] ?? 0,
      'total': Sqflite.firstIntValue(totalRows) ?? 0,
    };
  }

  Future<int> _getSyncAttempts(Database db, int id) async {
    final rows = await db.rawQuery(
      'SELECT sync_attempts FROM $_pendingScreeningsTable WHERE id = ?',
      [id],
    );
    return Sqflite.firstIntValue(rows) ?? 0;
  }

  Future<void> _markFailedScreening(
    Database db,
    int id,
    String errorCode,
    String errorMessage,
  ) async {
    await db.update(
      _pendingScreeningsTable,
      {
        'sync_status': _syncStatusFailed,
        'error_code': errorCode,
        'error_message': errorMessage,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}

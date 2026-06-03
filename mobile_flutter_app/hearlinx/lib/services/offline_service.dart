import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../models/screening.dart';
import 'api_service.dart';

class OfflineService {
  OfflineService({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  static const _databaseName = 'hearlinx_offline.db';
  static const _databaseVersion = 2;
  static const _pendingScreeningsTable = 'pending_screenings';
  static Database? _database;

  final ApiService _apiService;

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
        await db.execute('''
          CREATE TABLE $_pendingScreeningsTable (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            baby_id TEXT NOT NULL,
            screening_type TEXT NOT NULL,
            ear_left TEXT NOT NULL,
            ear_right TEXT NOT NULL,
            notes TEXT,
            screening_date TEXT,
            created_at TEXT NOT NULL
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
            'ALTER TABLE $_pendingScreeningsTable ADD COLUMN screening_date TEXT',
          );
        }
      },
    );

    _database = openedDatabase;
    return openedDatabase;
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
    });
  }

  Future<int> getPendingScreeningCount() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) AS count FROM $_pendingScreeningsTable',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> syncPendingScreenings(String token) async {
    final db = await database;
    final rows = await db.query(_pendingScreeningsTable, orderBy: 'id ASC');
    var syncedCount = 0;

    for (final row in rows) {
      final localId = row['id'] as int;
      final screening = Screening(
        babyId: row['baby_id'] as String? ?? '',
        screeningType: row['screening_type'] as String? ?? '',
        earLeft: row['ear_left'] as String? ?? '',
        earRight: row['ear_right'] as String? ?? '',
        notes: row['notes'] as String?,
        screeningDate: row['screening_date'] as String?,
      );

      try {
        final response = await _apiService.client.post(
          Uri.parse('${_apiService.baseEndpoint}/screenings/'),
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
        );

        if (response.statusCode >= 200 && response.statusCode < 300) {
          await db.delete(
            _pendingScreeningsTable,
            where: 'id = ?',
            whereArgs: [localId],
          );
          syncedCount += 1;
          continue;
        }

        break;
      } on SocketException {
        break;
      } on http.ClientException {
        break;
      }
    }

    return syncedCount;
  }
}

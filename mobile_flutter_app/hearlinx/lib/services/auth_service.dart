import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/user.dart';

class AuthService {
  AuthService({
    FlutterSecureStorage? storage,
    http.Client? client,
  })  : _storage = storage ?? const FlutterSecureStorage(),
        _client = client ?? http.Client();

  final FlutterSecureStorage _storage;
  final http.Client _client;

  FlutterSecureStorage get storage => _storage;

  Future<String?> getToken() {
    return _storage.read(key: 'jwt_token');
  }

  Future<void> logout() async {
    await _storage.delete(key: 'jwt_token');
    await _storage.delete(key: 'selected_hospital');
    await _storage.delete(key: 'staff_id');
  }

  Future<String> getDisplayName() async {
    final token = await _storage.read(key: 'jwt_token');
    if (token == null || token.isEmpty) {
      return '';
    }

    try {
      final parts = token.split('.');
      if (parts.length != 3) {
        return '';
      }

      final normalized = base64Url.normalize(parts[1]);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final payload = jsonDecode(decoded) as Map<String, dynamic>;

      final fullName = payload['full_name'] as String?;
      if (fullName != null && fullName.trim().isNotEmpty) {
        return fullName.trim();
      }

      final name = payload['name'] as String?;
      if (name != null && name.trim().isNotEmpty) {
        return name.trim();
      }

      final staffId = payload['staff_id'] as String?;
      if (staffId != null && staffId.trim().isNotEmpty) {
        return staffId.trim();
      }
    } catch (_) {
      // Fall back to stored staff id when token parsing fails.
    }

    return (await _storage.read(key: 'staff_id')) ?? '';
  }

  Future<String> getRole() async {
    final token = await _storage.read(key: 'jwt_token');
    if (token == null || token.isEmpty) {
      return '';
    }

    try {
      final parts = token.split('.');
      final normalized = base64Url.normalize(parts[1]);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final payload = jsonDecode(decoded) as Map<String, dynamic>;
      return payload['role'] as String? ?? '';
    } catch (_) {
      return '';
    }
  }

  Future<User?> getCurrentUser() async {
    final token = await _storage.read(key: 'jwt_token');
    if (token == null || token.isEmpty) {
      return null;
    }

    final response = await _client.get(
      Uri.parse('$baseUrl/auth/me'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      return null;
    }

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    return User.fromJson(payload);
  }

  Future<bool> login({
    required String hospitalCode,
    required String staffId,
    required String pin,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: const {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'staff_id': staffId,
        'pin': pin,
        'hospital_code': hospitalCode,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      return false;
    }

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    final token = payload['access_token'] as String?;
    if (token == null || token.isEmpty) {
      return false;
    }

    await _storage.write(key: 'jwt_token', value: token);
    await _storage.write(key: 'selected_hospital', value: hospitalCode);
    await _storage.write(key: 'staff_id', value: staffId);
    return true;
  }
}

import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:http/http.dart' as http;

import '../config/api_config.dart';

class ApiService {
  ApiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  String get baseEndpoint => ApiConfig.baseUrl;
  http.Client get client => _client;

  /// GET request with latency tracking
  Future<http.Response> get(Uri url, {Map<String, String>? headers}) async {
    final stopwatch = Stopwatch()..start();
    try {
      final response = await _client
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 15));
      stopwatch.stop();

      ApiConfig.updateLatency(stopwatch.elapsed);
      _logRequest(
        'GET',
        url.toString(),
        response.statusCode,
        stopwatch.elapsedMilliseconds,
      );

      return response;
    } catch (e) {
      stopwatch.stop();
      _logRequest(
        'GET',
        url.toString(),
        null,
        stopwatch.elapsedMilliseconds,
        error: e,
      );
      rethrow;
    }
  }

  /// POST request with latency tracking
  Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async {
    final stopwatch = Stopwatch()..start();
    try {
      final response = await _client
          .post(url, headers: headers, body: body, encoding: encoding)
          .timeout(const Duration(seconds: 15));
      stopwatch.stop();

      ApiConfig.updateLatency(stopwatch.elapsed);
      _logRequest(
        'POST',
        url.toString(),
        response.statusCode,
        stopwatch.elapsedMilliseconds,
      );

      return response;
    } catch (e) {
      stopwatch.stop();
      _logRequest(
        'POST',
        url.toString(),
        null,
        stopwatch.elapsedMilliseconds,
        error: e,
      );
      rethrow;
    }
  }

  /// PATCH request with latency tracking
  Future<http.Response> patch(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async {
    final stopwatch = Stopwatch()..start();
    try {
      final response = await _client
          .patch(url, headers: headers, body: body, encoding: encoding)
          .timeout(const Duration(seconds: 15));
      stopwatch.stop();

      ApiConfig.updateLatency(stopwatch.elapsed);
      _logRequest(
        'PATCH',
        url.toString(),
        response.statusCode,
        stopwatch.elapsedMilliseconds,
      );

      return response;
    } catch (e) {
      stopwatch.stop();
      _logRequest(
        'PATCH',
        url.toString(),
        null,
        stopwatch.elapsedMilliseconds,
        error: e,
      );
      rethrow;
    }
  }

  /// PUT request with latency tracking
  Future<http.Response> put(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async {
    final stopwatch = Stopwatch()..start();
    try {
      final response = await _client.put(
        url,
        headers: headers,
        body: body,
        encoding: encoding,
      );
      stopwatch.stop();

      ApiConfig.updateLatency(stopwatch.elapsed);
      _logRequest(
        'PUT',
        url.toString(),
        response.statusCode,
        stopwatch.elapsedMilliseconds,
      );

      return response;
    } catch (e) {
      stopwatch.stop();
      _logRequest(
        'PUT',
        url.toString(),
        null,
        stopwatch.elapsedMilliseconds,
        error: e,
      );
      rethrow;
    }
  }

  /// DELETE request with latency tracking
  Future<http.Response> delete(Uri url, {Map<String, String>? headers}) async {
    final stopwatch = Stopwatch()..start();
    try {
      final response = await _client.delete(url, headers: headers);
      stopwatch.stop();

      ApiConfig.updateLatency(stopwatch.elapsed);
      _logRequest(
        'DELETE',
        url.toString(),
        response.statusCode,
        stopwatch.elapsedMilliseconds,
      );

      return response;
    } catch (e) {
      stopwatch.stop();
      _logRequest(
        'DELETE',
        url.toString(),
        null,
        stopwatch.elapsedMilliseconds,
        error: e,
      );
      rethrow;
    }
  }

  /// Log request with latency in debug mode
  void _logRequest(
    String method,
    String url,
    int? statusCode,
    int latencyMs, {
    Object? error,
  }) {
    final status = statusCode ?? 'ERROR';
    final message = error != null
        ? '$method $url → $status (${latencyMs}ms) - $error'
        : '$method $url → $status (${latencyMs}ms)';

    developer.log(message, name: 'ApiService', time: DateTime.now());
  }
}

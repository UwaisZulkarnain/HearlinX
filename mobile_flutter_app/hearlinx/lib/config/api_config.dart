import 'dart:async';
import 'dart:developer' as developer;

import 'package:http/http.dart' as http;

class ApiConfig {
  // URLs
  static const String _productionUrl =
      'https://hearlinx-production.up.railway.app';
  static const String _localUrl = 'http://10.20.88.90:8000';

  // Configuration
  static const Duration _healthCheckTimeout = Duration(seconds: 5);
  static bool _debugMode = true; // Set to false in production builds
  static bool _useDebugOverride = false; // Override to use local URL

  // State
  static String _activeUrl = _productionUrl;
  static int _latencyMs = 0;
  static bool _initialized = false;
  static final http.Client _httpClient = http.Client();

  /// Initialize API config on app startup
  /// Attempts production first, falls back to local if timeout
  static Future<void> initialize() async {
    if (_initialized) return;

    _log('Initializing ApiConfig...');

    if (_useDebugOverride) {
      _activeUrl = _localUrl;
      _log('DEBUG OVERRIDE: Using local URL', force: true);
      _initialized = true;
      return;
    }

    // Try production first
    final prodConnected = await checkConnectivity(url: _productionUrl);
    if (prodConnected) {
      _activeUrl = _productionUrl;
      _log('✓ Production URL is reachable');
    } else {
      // Fallback to local
      final localConnected = await checkConnectivity(url: _localUrl);
      if (localConnected) {
        _activeUrl = _localUrl;
        _log('⚠ Production unreachable, switched to local URL', force: true);
      } else {
        // Default to production if both fail
        _activeUrl = _productionUrl;
        _log('✗ Both URLs unreachable, defaulting to production', force: true);
      }
    }

    _initialized = true;
    _log('ApiConfig initialized: $_activeUrl');
  }

  /// Get current active base URL
  static String get baseUrl => _activeUrl;

  /// Get last measured latency in milliseconds
  static int get latency => _latencyMs;

  /// Check if using production URL
  static bool get isProduction => _activeUrl == _productionUrl;

  /// Set debug mode logging
  static void setDebugMode(bool enabled) {
    _debugMode = enabled;
  }

  /// Override to use local URL (debug only)
  static void setDebugOverride(bool useLocal) {
    _useDebugOverride = useLocal;
    if (useLocal) {
      _activeUrl = _localUrl;
      _log('DEBUG: Switched to local URL', force: true);
    } else {
      _activeUrl = _productionUrl;
      _log('DEBUG: Switched to production URL', force: true);
    }
  }

  /// Health check - ping the server and measure latency
  /// [url] - optional URL to check, defaults to current active URL
  /// Returns true if server is reachable, false otherwise
  static Future<bool> checkConnectivity({String? url}) async {
    final checkUrl = url ?? _activeUrl;
    final stopwatch = Stopwatch()..start();

    try {
      final response = await _httpClient
          .get(Uri.parse('$checkUrl/'), headers: {'Connection': 'keep-alive'})
          .timeout(_healthCheckTimeout);

      stopwatch.stop();
      _latencyMs = stopwatch.elapsedMilliseconds;

      final isHealthy = response.statusCode >= 200 && response.statusCode < 300;
      _log(
        'Health check: ${isHealthy ? '✓' : '✗'} $checkUrl (${_latencyMs}ms)',
        force: false,
      );

      return isHealthy;
    } on TimeoutException {
      stopwatch.stop();
      _log(
        'Health check TIMEOUT: $checkUrl (>${_healthCheckTimeout.inSeconds}s)',
        force: true,
      );
      return false;
    } catch (e) {
      stopwatch.stop();
      _log('Health check ERROR: $checkUrl - $e', force: true);
      return false;
    }
  }

  /// Update latency from request duration
  /// Called by ApiService after each request
  static void updateLatency(Duration duration) {
    _latencyMs = duration.inMilliseconds;
  }

  /// Internal logging with debug mode control
  static void _log(String message, {bool force = false}) {
    if (_debugMode || force) {
      developer.log(message, name: 'ApiConfig', time: DateTime.now());
    }
  }

  /// Get current configuration status
  static String getStatus() {
    return '''
ApiConfig Status:
  Active URL: $_activeUrl
  Is Production: $isProduction
  Last Latency: ${_latencyMs}ms
  Debug Mode: $_debugMode
  Initialized: $_initialized
''';
  }
}

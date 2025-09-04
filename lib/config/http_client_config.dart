import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'api_config.dart';

/// Enhanced HTTP client configuration with better defaults and interceptors
class HttpClientConfig {
  static http.Client? _client;

  /// Get configured HTTP client with custom settings
  static http.Client get client {
    _client ??= _createClient();
    return _client!;
  }

  /// Create a configured HTTP client
  static http.Client _createClient() {
    final client = http.Client();
    
    // Wrap the client to add interceptors
    return _InterceptedClient(client);
  }

  /// Close the HTTP client
  static void dispose() {
    _client?.close();
    _client = null;
  }

  /// Reset the client (useful for testing or configuration changes)
  static void reset() {
    dispose();
    _client = _createClient();
  }
}

/// Custom HTTP client that adds request/response interceptors
class _InterceptedClient extends http.BaseClient {
  final http.Client _inner;

  _InterceptedClient(this._inner);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    // Add custom headers to every request
    request.headers.addAll(ApiConfig.appHeaders);
    
    // Log request if enabled
    if (ApiConfig.enableNetworkLogging) {
      _logRequest(request);
    }

    try {
      final response = await _inner.send(request);
      
      // Log response if enabled
      if (ApiConfig.enableNetworkLogging) {
        _logResponse(request, response);
      }
      
      return response;
    } catch (e) {
      // Log error if enabled
      if (ApiConfig.enableNetworkLogging) {
        _logError(request, e);
      }
      rethrow;
    }
  }

  void _logRequest(http.BaseRequest request) {
    if (kDebugMode) {
      print('🌐 HTTP Request: ${request.method} ${request.url}');
      print('📋 Headers: ${_sanitizeHeaders(request.headers)}');
      
      if (request is http.Request && request.body.isNotEmpty) {
        // Don't log sensitive data in production
        if (request.url.path.contains('/auth/')) {
          print('📦 Body: [AUTH REQUEST - BODY HIDDEN]');
        } else {
          print('📦 Body: ${request.body}');
        }
      }
    }
  }

  void _logResponse(http.BaseRequest request, http.StreamedResponse response) {
    if (kDebugMode) {
      print('📨 HTTP Response: ${response.statusCode} for ${request.method} ${request.url}');
      print('⏱️  Response Time: ${DateTime.now().millisecondsSinceEpoch}ms');
      
      // Log response headers (sanitized)
      print('📋 Response Headers: ${_sanitizeHeaders(response.headers)}');
    }
  }

  void _logError(http.BaseRequest request, dynamic error) {
    if (kDebugMode) {
      print('❌ HTTP Error for ${request.method} ${request.url}: $error');
    }
  }

  Map<String, String> _sanitizeHeaders(Map<String, String> headers) {
    final sanitized = Map<String, String>.from(headers);
    
    // Remove sensitive headers from logs
    const sensitiveHeaders = [
      'authorization',
      'cookie',
      'x-api-key',
      'x-auth-token',
    ];
    
    for (final header in sensitiveHeaders) {
      if (sanitized.containsKey(header.toLowerCase())) {
        sanitized[header] = '[HIDDEN]';
      }
    }
    
    return sanitized;
  }

  @override
  void close() {
    _inner.close();
    super.close();
  }
}

/// Connection configuration for different environments
class ConnectionConfig {
  static const Map<String, int> _connectionPoolSizes = {
    'development': 10,
    'staging': 20,
    'production': 50,
  };

  static const Map<String, Duration> _keepAliveDurations = {
    'development': Duration(seconds: 30),
    'staging': Duration(minutes: 2),
    'production': Duration(minutes: 5),
  };

  /// Get connection pool size for current environment
  static int get connectionPoolSize {
    final env = EnvironmentConfig.current.name;
    return _connectionPoolSizes[env] ?? 10;
  }

  /// Get keep alive duration for current environment
  static Duration get keepAliveDuration {
    final env = EnvironmentConfig.current.name;
    return _keepAliveDurations[env] ?? const Duration(seconds: 30);
  }
}

/// Network quality and retry configuration
class RetryConfig {
  /// Determine if an error should trigger a retry
  static bool shouldRetry(dynamic error, int attemptNumber, int maxRetries) {
    if (attemptNumber >= maxRetries) return false;

    // Retry on network errors
    if (error is SocketException) return true;
    if (error is HttpException) return true;
    if (error.toString().contains('TimeoutException')) return true;

    // Retry on specific HTTP status codes (server errors)
    if (error is http.Response && error.statusCode >= 500) return true;

    return false;
  }

  /// Calculate delay before retry (exponential backoff)
  static Duration getRetryDelay(int attemptNumber) {
    final baseDelay = Duration(seconds: attemptNumber * 2);
    final jitter = Duration(milliseconds: (DateTime.now().millisecond % 1000));
    return baseDelay + jitter;
  }
}
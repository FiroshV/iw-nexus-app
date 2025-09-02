import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  // Environment-based configuration
  static const String _developmentUrl = 'http://localhost:3000/api';
  static const String _productionUrl = 'https://your-production-api.com/api'; // Update when deploying
  
  static String get baseUrl {
    // You can also use flutter_dotenv or similar for environment variables
    const bool isDevelopment = bool.fromEnvironment('dart.vm.product') == false;
    return isDevelopment ? _developmentUrl : _productionUrl;
  }
  
  static const String _tokenKey = 'session_token';
  static const String _userKey = 'user_data';
  static const String _lastLoginKey = 'last_login_time';
  
  static const _storage = FlutterSecureStorage();

  // HTTP client with longer timeout for real API calls
  static final http.Client _client = http.Client();
  
  // Headers for API requests
  static Future<Map<String, String>> _getHeaders({bool includeAuth = true}) async {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (includeAuth) {
      final token = await getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  // Enhanced token and user data management
  static Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
    await _storage.write(key: _lastLoginKey, value: DateTime.now().toIso8601String());
  }

  static Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  static Future<void> saveUserData(Map<String, dynamic> userData) async {
    await _storage.write(key: _userKey, value: jsonEncode(userData));
  }

  static Future<Map<String, dynamic>?> getUserData() async {
    final userDataStr = await _storage.read(key: _userKey);
    if (userDataStr != null) {
      try {
        return jsonDecode(userDataStr);
      } catch (e) {
        // If parsing fails, clear corrupt data
        await clearUserData();
        return null;
      }
    }
    return null;
  }

  static Future<DateTime?> getLastLoginTime() async {
    final lastLoginStr = await _storage.read(key: _lastLoginKey);
    if (lastLoginStr != null) {
      try {
        return DateTime.parse(lastLoginStr);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  static Future<void> clearToken() async {
    await _storage.delete(key: _tokenKey);
  }

  static Future<void> clearUserData() async {
    await _storage.delete(key: _userKey);
  }

  static Future<void> clearAllAuthData() async {
    await Future.wait([
      _storage.delete(key: _tokenKey),
      _storage.delete(key: _userKey),
      _storage.delete(key: _lastLoginKey),
    ]);
  }

  static Future<bool> hasValidSession() async {
    final token = await getToken();
    final userData = await getUserData();
    final lastLogin = await getLastLoginTime();
    
    if (token == null || userData == null || lastLogin == null) {
      return false;
    }
    
    // Check if session is older than 7 days (configurable)
    final sessionAge = DateTime.now().difference(lastLogin);
    if (sessionAge.inDays > 7) {
      await clearAllAuthData();
      return false;
    }
    
    return true;
  }

  // Generic API request method with retry logic
  static Future<ApiResponse<T>> _makeRequest<T>(
    String endpoint,
    String method, {
    Map<String, dynamic>? body,
    bool includeAuth = true,
    Duration timeout = const Duration(seconds: 30),
    int maxRetries = 3,
  }) async {
    ApiResponse<T>? lastResponse;
    
    for (int attempt = 0; attempt < maxRetries; attempt++) {
      try {
        final url = Uri.parse('$baseUrl$endpoint');
        final headers = await _getHeaders(includeAuth: includeAuth);

        http.Response response;

        switch (method.toUpperCase()) {
          case 'GET':
            response = await _client.get(url, headers: headers).timeout(timeout);
            break;
          case 'POST':
            response = await _client.post(
              url,
              headers: headers,
              body: body != null ? jsonEncode(body) : null,
            ).timeout(timeout);
            break;
          case 'PUT':
            response = await _client.put(
              url,
              headers: headers,
              body: body != null ? jsonEncode(body) : null,
            ).timeout(timeout);
            break;
          case 'DELETE':
            response = await _client.delete(url, headers: headers).timeout(timeout);
            break;
          default:
            throw ApiException('Unsupported HTTP method: $method');
        }

        final result = _handleResponse<T>(response);
        
        // If successful or client error (4xx), don't retry
        if (result.success || (result.statusCode != null && result.statusCode! < 500)) {
          return result;
        }
        
        lastResponse = result;
        
        // Wait before retrying (exponential backoff)
        if (attempt < maxRetries - 1) {
          await Future.delayed(Duration(seconds: (attempt + 1) * 2));
        }
        
      } catch (e) {
        if (e is ApiException) rethrow;
        
        lastResponse = ApiResponse<T>(
          success: false,
          message: _getErrorMessage(e),
          error: e.toString(),
        );
        
        // Don't retry for certain errors
        if (e.toString().contains('SocketException') && attempt < maxRetries - 1) {
          await Future.delayed(Duration(seconds: (attempt + 1) * 2));
          continue;
        }
        
        // For other errors or last attempt, return the error
        if (attempt == maxRetries - 1) {
          return lastResponse;
        }
      }
    }
    
    return lastResponse ?? ApiResponse<T>(
      success: false,
      message: 'Request failed after $maxRetries attempts',
      error: 'Max retries exceeded',
    );
  }

  // Handle HTTP response with enhanced error handling
  static ApiResponse<T> _handleResponse<T>(http.Response response) {
    try {
      late Map<String, dynamic> data;
      
      // Try to parse JSON response
      try {
        data = jsonDecode(response.body);
      } catch (e) {
        // If JSON parsing fails, create a basic error response
        return ApiResponse<T>(
          success: false,
          message: _getHttpErrorMessage(response.statusCode),
          error: 'Invalid JSON response: ${response.body}',
          statusCode: response.statusCode,
        );
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ApiResponse<T>(
          success: data['success'] ?? true,
          message: data['message'] ?? 'Success',
          data: data['data'],
          statusCode: response.statusCode,
        );
      } else {
        // Handle specific HTTP error codes
        String errorMessage = data['message'] ?? _getHttpErrorMessage(response.statusCode);
        
        // Handle Clerk-specific errors
        if (data.containsKey('errors') && data['errors'] is List) {
          final errors = data['errors'] as List;
          if (errors.isNotEmpty && errors[0] is Map) {
            final clerkError = errors[0] as Map<String, dynamic>;
            errorMessage = clerkError['longMessage'] ?? clerkError['message'] ?? errorMessage;
          }
        }
        
        return ApiResponse<T>(
          success: false,
          message: errorMessage,
          error: data['error'],
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse<T>(
        success: false,
        message: 'Failed to process response',
        error: e.toString(),
        statusCode: response.statusCode,
      );
    }
  }

  // Get user-friendly HTTP error messages
  static String _getHttpErrorMessage(int statusCode) {
    switch (statusCode) {
      case 400:
        return 'Invalid request. Please check your input.';
      case 401:
        return 'Authentication required. Please log in again.';
      case 403:
        return 'Access denied. You don\'t have permission.';
      case 404:
        return 'The requested resource was not found.';
      case 409:
        return 'Conflict. The resource already exists.';
      case 422:
        return 'Invalid data provided. Please check your input.';
      case 429:
        return 'Too many requests. Please wait and try again.';
      case 500:
        return 'Server error. Please try again later.';
      case 503:
        return 'Service temporarily unavailable.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }

  // Get error message from exception
  static String _getErrorMessage(dynamic error) {
    if (error.toString().contains('TimeoutException')) {
      return 'Request timed out. Please check your connection.';
    } else if (error.toString().contains('SocketException')) {
      return 'No internet connection. Please check your network.';
    } else {
      return 'Something went wrong. Please try again.';
    }
  }

  // Authentication endpoints
  static Future<ApiResponse<Map<String, dynamic>>> sendOtp({
    required String identifier,
    required String method, // 'email' or 'phone'
  }) async {
    return await _makeRequest<Map<String, dynamic>>(
      '/auth/send-otp',
      'POST',
      body: {
        'identifier': identifier,
        'method': method,
      },
      includeAuth: false,
    );
  }

  static Future<ApiResponse<Map<String, dynamic>>> verifyOtp({
    required String signInId,
    required String code,
  }) async {
    return await _makeRequest<Map<String, dynamic>>(
      '/auth/verify-otp',
      'POST',
      body: {
        'signInId': signInId,
        'code': code,
      },
      includeAuth: false,
    );
  }

  static Future<ApiResponse<Map<String, dynamic>>> resendOtp({
    required String signInId,
    required String method,
  }) async {
    return await _makeRequest<Map<String, dynamic>>(
      '/auth/resend-otp',
      'POST',
      body: {
        'signInId': signInId,
        'method': method,
      },
      includeAuth: false,
    );
  }

  static Future<ApiResponse<Map<String, dynamic>>> getCurrentUser() async {
    return await _makeRequest<Map<String, dynamic>>(
      '/auth/me',
      'GET',
    );
  }

  static Future<ApiResponse<Map<String, dynamic>>> logout() async {
    final response = await _makeRequest<Map<String, dynamic>>(
      '/auth/logout',
      'POST',
    );
    
    // Clear local data regardless of API response
    // This ensures user is logged out locally even if server request fails
    await clearAllAuthData();
    
    return response;
  }

  static Future<ApiResponse<bool>> validateSession() async {
    final response = await _makeRequest<Map<String, dynamic>>(
      '/auth/session/validate',
      'GET',
    );
    
    return ApiResponse<bool>(
      success: response.success,
      message: response.message,
      data: response.success,
      statusCode: response.statusCode,
    );
  }

  // User endpoints
  static Future<ApiResponse<Map<String, dynamic>>> getUserProfile() async {
    return await _makeRequest<Map<String, dynamic>>(
      '/users/profile',
      'GET',
    );
  }

  static Future<ApiResponse<Map<String, dynamic>>> updateUserProfile({
    required Map<String, dynamic> profileData,
  }) async {
    return await _makeRequest<Map<String, dynamic>>(
      '/users/profile',
      'PUT',
      body: profileData,
    );
  }

  // Attendance endpoints
  static Future<ApiResponse<Map<String, dynamic>>> checkIn({
    Map<String, dynamic>? location,
    String? notes,
  }) async {
    return await _makeRequest<Map<String, dynamic>>(
      '/attendance/check-in',
      'POST',
      body: {
        if (location != null) 'location': location,
        if (notes != null) 'notes': notes,
      },
    );
  }

  static Future<ApiResponse<Map<String, dynamic>>> checkOut({
    Map<String, dynamic>? location,
    String? notes,
  }) async {
    return await _makeRequest<Map<String, dynamic>>(
      '/attendance/check-out',
      'POST',
      body: {
        if (location != null) 'location': location,
        if (notes != null) 'notes': notes,
      },
    );
  }

  static Future<ApiResponse<Map<String, dynamic>>> startBreak({
    String? type,
    String? notes,
  }) async {
    return await _makeRequest<Map<String, dynamic>>(
      '/attendance/break-out',
      'POST',
      body: {
        if (type != null) 'type': type,
        if (notes != null) 'notes': notes,
      },
    );
  }

  static Future<ApiResponse<Map<String, dynamic>>> endBreak() async {
    return await _makeRequest<Map<String, dynamic>>(
      '/attendance/break-in',
      'POST',
    );
  }

  static Future<ApiResponse<Map<String, dynamic>>> getTodayAttendance() async {
    return await _makeRequest<Map<String, dynamic>>(
      '/attendance/today',
      'GET',
    );
  }

  static Future<ApiResponse<Map<String, dynamic>>> getAttendanceHistory({
    int page = 1,
    int limit = 30,
    String? startDate,
    String? endDate,
    String? status,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };

    if (startDate != null) queryParams['startDate'] = startDate;
    if (endDate != null) queryParams['endDate'] = endDate;
    if (status != null) queryParams['status'] = status;

    final queryString = queryParams.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');

    return await _makeRequest<Map<String, dynamic>>(
      '/attendance/history?$queryString',
      'GET',
    );
  }

  static Future<ApiResponse<Map<String, dynamic>>> getAttendanceSummary({
    int? year,
    int? month,
  }) async {
    final queryParams = <String, String>{};
    
    if (year != null) queryParams['year'] = year.toString();
    if (month != null) queryParams['month'] = month.toString();

    final queryString = queryParams.isNotEmpty 
        ? '?${queryParams.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&')}'
        : '';

    return await _makeRequest<Map<String, dynamic>>(
      '/attendance/summary$queryString',
      'GET',
    );
  }

  // Health check and connectivity test
  static Future<ApiResponse<Map<String, dynamic>>> healthCheck() async {
    return await _makeRequest<Map<String, dynamic>>(
      '/health',
      'GET',
      includeAuth: false,
      timeout: const Duration(seconds: 10), // Shorter timeout for health checks
      maxRetries: 1, // Don't retry health checks
    );
  }

  // Test backend connectivity
  static Future<bool> testConnection() async {
    try {
      final response = await healthCheck();
      return response.success;
    } catch (e) {
      return false;
    }
  }

  // Cleanup
  static void dispose() {
    _client.close();
  }
}

// API Response class
class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;
  final String? error;
  final int? statusCode;

  ApiResponse({
    required this.success,
    required this.message,
    this.data,
    this.error,
    this.statusCode,
  });

  @override
  String toString() {
    return 'ApiResponse{success: $success, message: $message, data: $data}';
  }
}

// Custom exception for API errors
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, [this.statusCode]);

  @override
  String toString() => 'ApiException: $message';
}
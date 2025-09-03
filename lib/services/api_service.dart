import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  static const String _authStateKey = 'auth_state';
  
  static const _storage = FlutterSecureStorage();
  
  // Singleton SharedPreferences instance with error handling
  static SharedPreferences? _sharedPrefs;
  static bool _sharedPrefsInitialized = false;
  
  // Add auth debug logging
  static void _authLog(String message) {
    if (kDebugMode) {
      debugPrint('🔐 AUTH: $message');
    }
  }
  
  // Safe SharedPreferences getter with error handling
  static Future<SharedPreferences?> _getSharedPrefs() async {
    if (!_sharedPrefsInitialized) {
      try {
        _authLog('Initializing SharedPreferences');
        _sharedPrefs = await SharedPreferences.getInstance();
        _sharedPrefsInitialized = true;
        _authLog('SharedPreferences initialized successfully');
      } catch (e) {
        _authLog('Failed to initialize SharedPreferences: $e');
        _sharedPrefs = null;
        _sharedPrefsInitialized = true; // Mark as tried to avoid repeated attempts
      }
    }
    return _sharedPrefs;
  }

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

  // Enhanced token and user data management with fallback storage
  static Future<void> saveToken(String token) async {
    _authLog('Saving authentication token');
    
    // Always try to save to secure storage first (critical)
    try {
      await _storage.write(key: _tokenKey, value: token);
      await _storage.write(key: _lastLoginKey, value: DateTime.now().toIso8601String());
      _authLog('Token saved successfully to secure storage');
    } catch (e) {
      _authLog('CRITICAL: Failed to save token to secure storage: $e');
      rethrow; // This is critical, so we rethrow
    }
    
    // Try to save to shared preferences as fallback (non-critical)
    try {
      final prefs = await _getSharedPrefs();
      if (prefs != null) {
        await prefs.setString(_tokenKey, token);
        await prefs.setString(_lastLoginKey, DateTime.now().toIso8601String());
        await prefs.setBool(_authStateKey, true);
        _authLog('Token also saved to shared preferences fallback');
      } else {
        _authLog('SharedPreferences not available - continuing with secure storage only');
      }
    } catch (e) {
      _authLog('Failed to save token to shared preferences (non-critical): $e');
      // Don't rethrow - this is just fallback storage
    }
  }

  static Future<String?> getToken() async {
    try {
      // Try secure storage first (primary storage)
      final secureToken = await _storage.read(key: _tokenKey);
      if (secureToken != null) {
        _authLog('Token retrieved from secure storage');
        return secureToken;
      }
      _authLog('No token found in secure storage');
    } catch (e) {
      _authLog('Error reading from secure storage: $e');
    }
    
    // Fallback to shared preferences only if secure storage failed
    try {
      final prefs = await _getSharedPrefs();
      if (prefs != null) {
        final prefToken = prefs.getString(_tokenKey);
        if (prefToken != null) {
          _authLog('Token retrieved from shared preferences fallback');
          // Try to restore to secure storage if possible
          try {
            await _storage.write(key: _tokenKey, value: prefToken);
            _authLog('Token restored to secure storage from fallback');
          } catch (e) {
            _authLog('Could not restore token to secure storage: $e');
          }
          return prefToken;
        }
      }
    } catch (e) {
      _authLog('Error retrieving token from shared preferences: $e');
    }
    
    _authLog('No token found in any storage');
    return null;
  }

  static Future<void> saveUserData(Map<String, dynamic> userData) async {
    _authLog('Saving user data');
    
    // Always try to save to secure storage first (critical)
    try {
      final userDataJson = jsonEncode(userData);
      await _storage.write(key: _userKey, value: userDataJson);
      _authLog('User data saved successfully to secure storage');
    } catch (e) {
      _authLog('CRITICAL: Failed to save user data to secure storage: $e');
      rethrow; // This is critical, so we rethrow
    }
    
    // Try to save to shared preferences as fallback (non-critical)
    try {
      final prefs = await _getSharedPrefs();
      if (prefs != null) {
        final userDataJson = jsonEncode(userData);
        await prefs.setString(_userKey, userDataJson);
        _authLog('User data also saved to shared preferences fallback');
      }
    } catch (e) {
      _authLog('Failed to save user data to shared preferences (non-critical): $e');
      // Don't rethrow - this is just fallback storage
    }
  }

  static Future<Map<String, dynamic>?> getUserData() async {
    try {
      // Try secure storage first (primary storage)
      final secureUserData = await _storage.read(key: _userKey);
      if (secureUserData != null) {
        try {
          final userData = jsonDecode(secureUserData);
          _authLog('User data retrieved from secure storage');
          return userData;
        } catch (e) {
          _authLog('Error parsing user data from secure storage: $e');
        }
      }
      _authLog('No user data found in secure storage');
    } catch (e) {
      _authLog('Error reading from secure storage: $e');
    }
    
    // Fallback to shared preferences only if secure storage failed
    try {
      final prefs = await _getSharedPrefs();
      if (prefs != null) {
        final prefUserData = prefs.getString(_userKey);
        if (prefUserData != null) {
          try {
            final userData = jsonDecode(prefUserData);
            _authLog('User data retrieved from shared preferences fallback');
            // Try to restore to secure storage if possible
            try {
              await _storage.write(key: _userKey, value: prefUserData);
              _authLog('User data restored to secure storage from fallback');
            } catch (e) {
              _authLog('Could not restore user data to secure storage: $e');
            }
            return userData;
          } catch (e) {
            _authLog('Error parsing user data from shared preferences: $e');
            // Clear corrupt data
            try {
              await prefs.remove(_userKey);
            } catch (e2) {
              _authLog('Could not clear corrupt user data from shared preferences: $e2');
            }
          }
        }
      }
    } catch (e) {
      _authLog('Error retrieving user data from shared preferences: $e');
    }
    
    _authLog('No user data found in any storage');
    return null;
  }

  static Future<DateTime?> getLastLoginTime() async {
    try {
      // Try secure storage first (primary storage)
      final secureLastLogin = await _storage.read(key: _lastLoginKey);
      if (secureLastLogin != null) {
        try {
          return DateTime.parse(secureLastLogin);
        } catch (e) {
          _authLog('Error parsing last login time from secure storage: $e');
        }
      }
    } catch (e) {
      _authLog('Error reading last login time from secure storage: $e');
    }
    
    // Fallback to shared preferences only if needed
    try {
      final prefs = await _getSharedPrefs();
      if (prefs != null) {
        final prefLastLogin = prefs.getString(_lastLoginKey);
        if (prefLastLogin != null) {
          try {
            return DateTime.parse(prefLastLogin);
          } catch (e) {
            _authLog('Error parsing last login time from shared preferences: $e');
          }
        }
      }
    } catch (e) {
      _authLog('Error retrieving last login time from shared preferences: $e');
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
    _authLog('Clearing all authentication data');
    
    // Clear secure storage (critical)
    try {
      await Future.wait([
        _storage.delete(key: _tokenKey),
        _storage.delete(key: _userKey),
        _storage.delete(key: _lastLoginKey),
      ]);
      _authLog('Secure storage cleared successfully');
    } catch (e) {
      _authLog('Error clearing secure storage: $e');
      // Continue even if clearing fails
    }
    
    // Clear shared preferences (non-critical)
    try {
      final prefs = await _getSharedPrefs();
      if (prefs != null) {
        await Future.wait([
          prefs.remove(_tokenKey),
          prefs.remove(_userKey),
          prefs.remove(_lastLoginKey),
          prefs.remove(_authStateKey),
        ]);
        _authLog('Shared preferences cleared successfully');
      } else {
        _authLog('SharedPreferences not available during clear operation');
      }
    } catch (e) {
      _authLog('Error clearing shared preferences (non-critical): $e');
      // Continue even if clearing fails
    }
    
    _authLog('Authentication data clear operation completed');
  }

  static Future<bool> hasValidSession() async {
    _authLog('Checking for valid session');
    
    final token = await getToken();
    final userData = await getUserData();
    final lastLogin = await getLastLoginTime();
    
    _authLog('Session check - Token: ${token != null}, UserData: ${userData != null}, LastLogin: ${lastLogin != null}');
    
    if (token == null) {
      _authLog('No token found - session invalid');
      return false;
    }
    
    if (userData == null) {
      _authLog('No user data found - session invalid');
      return false;
    }
    
    if (lastLogin == null) {
      _authLog('No last login time found - assuming valid session');
      return true; // If we have token and user data, don't invalidate just because no timestamp
    }
    
    // Extended session timeout to 30 days (was 7)
    final sessionAge = DateTime.now().difference(lastLogin);
    _authLog('Session age: ${sessionAge.inDays} days');
    
    if (sessionAge.inDays > 30) {
      _authLog('Session expired (older than 30 days) - clearing data');
      await clearAllAuthData();
      return false;
    }
    
    _authLog('Session is valid');
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

  // Handle HTTP response with enhanced error handling for both Map and List responses
  static ApiResponse<T> _handleResponse<T>(http.Response response) {
    try {
      dynamic parsedResponse;
      
      // Try to parse JSON response
      try {
        parsedResponse = jsonDecode(response.body);
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
        // Handle successful responses
        if (parsedResponse is Map<String, dynamic>) {
          // Standard object response
          return ApiResponse<T>(
            success: parsedResponse['success'] ?? true,
            message: parsedResponse['message'] ?? 'Success',
            data: parsedResponse['data'], // No casting - let caller handle type
            statusCode: response.statusCode,
          );
        } else {
          // Non-map responses (List, primitives, etc.) - treat as raw data
          return ApiResponse<T>(
            success: true,
            message: 'Success',
            data: parsedResponse, // No casting - let caller handle type
            statusCode: response.statusCode,
          );
        }
      } else {
        // Handle error responses
        if (parsedResponse is Map<String, dynamic>) {
          // Standard object error response
          String errorMessage = parsedResponse['message'] ?? _getHttpErrorMessage(response.statusCode);
          
          // Handle specific errors
          if (parsedResponse.containsKey('errors') && parsedResponse['errors'] is List) {
            final errors = parsedResponse['errors'] as List;
            if (errors.isNotEmpty && errors[0] is Map) {
              final specificError = errors[0] as Map<String, dynamic>;
              errorMessage = specificError['longMessage'] ?? specificError['message'] ?? errorMessage;
            }
          }
          
          return ApiResponse<T>(
            success: false,
            message: errorMessage,
            error: parsedResponse['error'],
            statusCode: response.statusCode,
          );
        } else {
          // Non-standard error response (array or primitive)
          return ApiResponse<T>(
            success: false,
            message: _getHttpErrorMessage(response.statusCode),
            error: parsedResponse.toString(),
            statusCode: response.statusCode,
          );
        }
      }
    } catch (e) {
      return ApiResponse<T>(
        success: false,
        message: 'Failed to process response: ${e.toString()}',
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
  static Future<ApiResponse<Map<String, dynamic>>> checkUserExists({
    required String identifier,
    required String method, // 'email' or 'phone'
  }) async {
    return await _makeRequest<Map<String, dynamic>>(
      '/auth/check-user-exists',
      'POST',
      body: {
        'identifier': identifier,
        'method': method,
      },
      includeAuth: false,
    );
  }

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

  static Future<ApiResponse<Map<String, dynamic>>> verifyFirebaseToken({
    required String idToken,
  }) async {
    return await _makeRequest<Map<String, dynamic>>(
      '/auth/verify-firebase-token',
      'POST',
      body: {
        'idToken': idToken,
      },
      includeAuth: false,
    );
  }

  static Future<ApiResponse<Map<String, dynamic>>> notifyFirebaseSignin({
    required String firebaseUid,
    required String phoneNumber,
    String? displayName,
  }) async {
    return await _makeRequest<Map<String, dynamic>>(
      '/auth/firebase-signin',
      'POST',
      body: {
        'firebaseUid': firebaseUid,
        'phoneNumber': phoneNumber,
        if (displayName != null) 'displayName': displayName,
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
    _authLog('Validating session with server');
    
    try {
      final response = await _makeRequest<Map<String, dynamic>>(
        '/auth/session/validate',
        'GET',
        timeout: const Duration(seconds: 10), // Shorter timeout for session validation
        maxRetries: 2, // Fewer retries for session validation
      );
      
      _authLog('Session validation response: ${response.success}, Status: ${response.statusCode}');
      
      // Only consider explicit auth errors as session invalid
      if (response.statusCode == 401 || response.statusCode == 403) {
        _authLog('Session explicitly invalid (401/403 response)');
        return ApiResponse<bool>(
          success: false,
          message: response.message,
          data: false,
          statusCode: response.statusCode,
        );
      }
      
      // For network errors or server errors, assume session is still valid
      // to avoid unnecessary logouts
      if (!response.success && (response.statusCode == null || response.statusCode! >= 500)) {
        _authLog('Network/server error during validation - assuming session valid');
        return ApiResponse<bool>(
          success: true,
          message: 'Session validation skipped due to network error',
          data: true,
          statusCode: 200,
        );
      }
      
      return ApiResponse<bool>(
        success: response.success,
        message: response.message,
        data: response.success,
        statusCode: response.statusCode,
      );
    } catch (e) {
      _authLog('Session validation error (assuming valid): $e');
      // On error, assume session is valid to prevent unnecessary logouts
      return ApiResponse<bool>(
        success: true,
        message: 'Session validation skipped due to error',
        data: true,
        statusCode: 200,
      );
    }
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

  // User Management endpoints (Admin only)
  static Future<ApiResponse<Map<String, dynamic>>> createUser({
    required String firstName,
    required String lastName,
    required String email,
    required String phoneNumber,
    required String department,
    required String role,
    required String designation,
    String? dateOfJoining,
    String? managerId,
    Map<String, dynamic>? workSchedule,
  }) async {
    return await _makeRequest<Map<String, dynamic>>(
      '/users',
      'POST',
      body: {
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'phoneNumber': phoneNumber,
        'department': department,
        'role': role,
        'designation': designation,
        if (dateOfJoining != null) 'dateOfJoining': dateOfJoining,
        if (managerId != null) 'managerId': managerId,
        if (workSchedule != null) 'workSchedule': workSchedule,
      },
    );
  }

  static Future<ApiResponse<Map<String, dynamic>>> getAllUsers({
    int page = 1,
    int limit = 20,
    String? department,
    String? role,
    String? status,
    String? search,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };

    if (department != null) queryParams['department'] = department;
    if (role != null) queryParams['role'] = role;
    if (status != null) queryParams['status'] = status;
    if (search != null) queryParams['search'] = search;

    final queryString = queryParams.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');

    return await _makeRequest<Map<String, dynamic>>(
      '/users?$queryString',
      'GET',
    );
  }

  static Future<ApiResponse<Map<String, dynamic>>> getUserById(String userId) async {
    return await _makeRequest<Map<String, dynamic>>(
      '/users/$userId',
      'GET',
    );
  }

  static Future<ApiResponse<Map<String, dynamic>>> updateUser({
    required String userId,
    required Map<String, dynamic> userData,
  }) async {
    return await _makeRequest<Map<String, dynamic>>(
      '/users/$userId',
      'PUT',
      body: userData,
    );
  }

  static Future<ApiResponse<Map<String, dynamic>>> deleteUser(String userId) async {
    return await _makeRequest<Map<String, dynamic>>(
      '/users/$userId',
      'DELETE',
    );
  }

  static Future<ApiResponse<Map<String, dynamic>>> getManagers() async {
    return await _makeRequest<Map<String, dynamic>>(
      '/users?role=manager&status=active&limit=100',
      'GET',
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
  final dynamic data; // Changed from T? to dynamic to prevent casting issues
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
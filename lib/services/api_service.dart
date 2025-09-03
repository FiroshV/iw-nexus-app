import 'dart:convert';
import 'package:flutter/foundation.dart';
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
  static const String _refreshTokenKey = 'refresh_token';
  static const String _tokenExpiryKey = 'token_expiry';
  static const String _userKey = 'user_data';
  static const String _lastLoginKey = 'last_login_time';
  
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );
  
  // Add auth debug logging
  static void _authLog(String message) {
    if (kDebugMode) {
      debugPrint('🔐 AUTH: $message');
    }
  }
  
  // Token expiry management
  static Future<void> _saveTokenExpiry(DateTime expiry) async {
    try {
      await _storage.write(key: _tokenExpiryKey, value: expiry.toIso8601String());
      _authLog('Token expiry saved: $expiry');
    } catch (e) {
      _authLog('Failed to save token expiry: $e');
    }
  }

  static Future<DateTime?> _getTokenExpiry() async {
    try {
      final expiryStr = await _storage.read(key: _tokenExpiryKey);
      if (expiryStr != null) {
        return DateTime.parse(expiryStr);
      }
    } catch (e) {
      _authLog('Failed to read token expiry: $e');
    }
    return null;
  }

  static Future<bool> _isTokenNearExpiry() async {
    final expiry = await _getTokenExpiry();
    if (expiry == null) return false;
    
    final now = DateTime.now();
    final timeUntilExpiry = expiry.difference(now);
    
    // Consider token near expiry if less than 30 minutes remain
    return timeUntilExpiry.inMinutes < 30;
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

  // Enhanced token management with expiry and refresh tokens
  static Future<void> saveToken(String token, {String? refreshToken, DateTime? expiresAt}) async {
    _authLog('Saving authentication tokens');
    
    try {
      await _storage.write(key: _tokenKey, value: token);
      await _storage.write(key: _lastLoginKey, value: DateTime.now().toIso8601String());
      
      if (refreshToken != null) {
        await _storage.write(key: _refreshTokenKey, value: refreshToken);
        _authLog('Refresh token saved');
      }
      
      if (expiresAt != null) {
        await _saveTokenExpiry(expiresAt);
      } else {
        // If no expiry provided, set a long-lived default (30 days)
        final defaultExpiry = DateTime.now().add(const Duration(days: 30));
        await _saveTokenExpiry(defaultExpiry);
      }
      
      _authLog('Tokens saved successfully to secure storage');
    } catch (e) {
      _authLog('CRITICAL: Failed to save tokens to secure storage: $e');
      rethrow;
    }
  }

  static Future<String?> getToken() async {
    try {
      final token = await _storage.read(key: _tokenKey);
      if (token != null) {
        _authLog('Token retrieved from secure storage');
        
        // Check if token needs refresh
        final needsRefresh = await _isTokenNearExpiry();
        if (needsRefresh) {
          _authLog('Token is near expiry, attempting refresh');
          final refreshed = await _refreshTokenIfNeeded();
          if (refreshed) {
            // Return the refreshed token
            return await _storage.read(key: _tokenKey);
          }
        }
        
        return token;
      }
      _authLog('No token found in secure storage');
    } catch (e) {
      _authLog('Error reading token from secure storage: $e');
    }
    
    return null;
  }

  static Future<String?> getRefreshToken() async {
    try {
      final refreshToken = await _storage.read(key: _refreshTokenKey);
      if (refreshToken != null) {
        _authLog('Refresh token retrieved from secure storage');
      }
      return refreshToken;
    } catch (e) {
      _authLog('Error reading refresh token: $e');
      return null;
    }
  }

  static Future<void> saveUserData(Map<String, dynamic> userData) async {
    _authLog('Saving user data');
    
    try {
      final userDataJson = jsonEncode(userData);
      await _storage.write(key: _userKey, value: userDataJson);
      _authLog('User data saved successfully to secure storage');
    } catch (e) {
      _authLog('CRITICAL: Failed to save user data to secure storage: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>?> getUserData() async {
    try {
      final userData = await _storage.read(key: _userKey);
      if (userData != null) {
        try {
          final parsedUserData = jsonDecode(userData);
          _authLog('User data retrieved from secure storage');
          return parsedUserData;
        } catch (e) {
          _authLog('Error parsing user data: $e');
          // Clear corrupt data
          await _storage.delete(key: _userKey);
        }
      }
    } catch (e) {
      _authLog('Error reading user data from secure storage: $e');
    }
    
    _authLog('No user data found in storage');
    return null;
  }

  static Future<DateTime?> getLastLoginTime() async {
    try {
      final lastLoginStr = await _storage.read(key: _lastLoginKey);
      if (lastLoginStr != null) {
        try {
          return DateTime.parse(lastLoginStr);
        } catch (e) {
          _authLog('Error parsing last login time: $e');
        }
      }
    } catch (e) {
      _authLog('Error reading last login time: $e');
    }
    
    return null;
  }

  static Future<void> clearToken() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _tokenExpiryKey);
  }

  static Future<void> clearUserData() async {
    await _storage.delete(key: _userKey);
  }

  static Future<void> clearAllAuthData() async {
    _authLog('Clearing all authentication data');
    
    try {
      await Future.wait([
        _storage.delete(key: _tokenKey),
        _storage.delete(key: _refreshTokenKey),
        _storage.delete(key: _tokenExpiryKey),
        _storage.delete(key: _userKey),
        _storage.delete(key: _lastLoginKey),
      ]);
      _authLog('All authentication data cleared successfully');
    } catch (e) {
      _authLog('Error clearing authentication data: $e');
    }
  }

  static Future<bool> hasValidSession() async {
    _authLog('Checking for valid session');
    
    final token = await getToken();
    final userData = await getUserData();
    
    _authLog('Session check - Token: ${token != null}, UserData: ${userData != null}');
    
    if (token == null) {
      _authLog('No token found - session invalid');
      return false;
    }
    
    if (userData == null) {
      _authLog('No user data found - session invalid');
      return false;
    }
    
    // Check if token is near expiry and needs refresh
    final nearExpiry = await _isTokenNearExpiry();
    if (nearExpiry) {
      _authLog('Token is near expiry but session still valid (will refresh automatically)');
    }
    
    _authLog('Session is valid');
    return true;
  }

  // Token refresh mechanism
  static Future<bool> _refreshTokenIfNeeded() async {
    final refreshToken = await getRefreshToken();
    if (refreshToken == null) {
      _authLog('No refresh token available for token refresh');
      return false;
    }

    try {
      _authLog('Attempting to refresh token');
      final response = await _makeRequest<Map<String, dynamic>>(
        '/auth/refresh-token',
        'POST',
        body: {
          'refreshToken': refreshToken,
        },
        includeAuth: false,
        timeout: const Duration(seconds: 15),
        maxRetries: 2,
      );

      if (response.success && response.data != null) {
        final newToken = response.data!['accessToken'] as String?;
        final newRefreshToken = response.data!['refreshToken'] as String?;
        final expiresIn = response.data!['expiresIn'] as int?;

        if (newToken != null) {
          DateTime? expiresAt;
          if (expiresIn != null) {
            expiresAt = DateTime.now().add(Duration(seconds: expiresIn));
          }

          await saveToken(
            newToken,
            refreshToken: newRefreshToken ?? refreshToken,
            expiresAt: expiresAt,
          );

          _authLog('Token refreshed successfully');
          return true;
        }
      }

      _authLog('Token refresh failed: ${response.message}');
      return false;
    } catch (e) {
      _authLog('Token refresh error: $e');
      return false;
    }
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
    final response = await _makeRequest<Map<String, dynamic>>(
      '/auth/verify-otp',
      'POST',
      body: {
        'signInId': signInId,
        'code': code,
      },
      includeAuth: false,
    );

    // If login successful, extract and save tokens with expiry
    if (response.success && response.data != null) {
      final sessionToken = response.data!['sessionToken'] as String?;
      final refreshToken = response.data!['refreshToken'] as String?;
      final expiresIn = response.data!['expiresIn'] as int?;

      if (sessionToken != null) {
        DateTime? expiresAt;
        if (expiresIn != null) {
          expiresAt = DateTime.now().add(Duration(seconds: expiresIn));
        }
        
        await saveToken(sessionToken, refreshToken: refreshToken, expiresAt: expiresAt);
        _authLog('Tokens saved after OTP verification');
      }
    }

    return response;
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
    final response = await _makeRequest<Map<String, dynamic>>(
      '/auth/firebase-signin',
      'POST',
      body: {
        'firebaseUid': firebaseUid,
        'phoneNumber': phoneNumber,
        if (displayName != null) 'displayName': displayName,
      },
      includeAuth: false,
    );

    // If login successful, extract and save tokens with expiry
    if (response.success && response.data != null) {
      final sessionToken = response.data!['sessionToken'] as String?;
      final refreshToken = response.data!['refreshToken'] as String?;
      final expiresIn = response.data!['expiresIn'] as int?;

      if (sessionToken != null) {
        DateTime? expiresAt;
        if (expiresIn != null) {
          expiresAt = DateTime.now().add(Duration(seconds: expiresIn));
        }
        
        await saveToken(sessionToken, refreshToken: refreshToken, expiresAt: expiresAt);
        _authLog('Tokens saved after Firebase signin');
      }
    }

    return response;
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
    
    // First check if we need to refresh the token
    final needsRefresh = await _isTokenNearExpiry();
    if (needsRefresh) {
      _authLog('Token needs refresh before validation');
      final refreshed = await _refreshTokenIfNeeded();
      if (!refreshed) {
        _authLog('Token refresh failed, but continuing with current token');
      }
    }
    
    try {
      final response = await _makeRequest<Map<String, dynamic>>(
        '/auth/session/validate',
        'GET',
        timeout: const Duration(seconds: 10),
        maxRetries: 1, // Reduced retries for validation
      );
      
      _authLog('Session validation response: ${response.success}, Status: ${response.statusCode}');
      
      // Only consider explicit auth errors as session invalid
      if (response.statusCode == 401 || response.statusCode == 403) {
        _authLog('Session explicitly invalid (401/403 response)');
        // Try token refresh one more time before declaring invalid
        if (response.statusCode == 401) {
          _authLog('Attempting token refresh on 401 response');
          final refreshed = await _refreshTokenIfNeeded();
          if (refreshed) {
            _authLog('Token refreshed on 401, re-validating');
            // Retry validation with refreshed token
            final retryResponse = await _makeRequest<Map<String, dynamic>>(
              '/auth/session/validate',
              'GET',
              timeout: const Duration(seconds: 10),
              maxRetries: 1,
            );
            return ApiResponse<bool>(
              success: retryResponse.success,
              message: retryResponse.message,
              data: retryResponse.success,
              statusCode: retryResponse.statusCode,
            );
          }
        }
        
        return ApiResponse<bool>(
          success: false,
          message: response.message,
          data: false,
          statusCode: response.statusCode,
        );
      }
      
      // For network errors, server errors, or timeouts, assume session is valid
      // This prevents unnecessary logouts due to connectivity issues
      if (!response.success) {
        if (response.statusCode == null || response.statusCode! >= 500 || response.statusCode! == 408) {
          _authLog('Network/server error during validation - assuming session valid');
          return ApiResponse<bool>(
            success: true,
            message: 'Session assumed valid (network error)',
            data: true,
            statusCode: 200,
          );
        }
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
        message: 'Session assumed valid (validation error)',
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
    String? department,
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
        if (department != null) 'department': department,
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
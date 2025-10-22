import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../config/api_endpoints.dart';
import '../config/http_client_config.dart';
import '../utils/timezone_util.dart';

/// Centralized API service for handling all HTTP requests to the IW Nexus backend.
/// 
/// This service provides:
/// - Environment-based URL management
/// - Secure token storage and management
/// - Automatic token refresh
/// - Comprehensive error handling
/// - Request retry logic
/// - Standardized response handling
/// 
/// Usage:
/// ```dart
/// // Check user existence
/// final response = await ApiService.checkUserExists(
///   identifier: 'user@example.com',
///   method: 'email',
/// );
/// 
/// if (response.success) {
///   // User exists, proceed with OTP
/// }
/// ```
class ApiService {
  // Base URL from configuration
  static String get baseUrl => ApiConfig.baseUrl;
  
  // Storage keys from configuration
  static const String _tokenKey = ApiConfig.tokenKey;
  static const String _refreshTokenKey = ApiConfig.refreshTokenKey;
  static const String _tokenExpiryKey = ApiConfig.tokenExpiryKey;
  static const String _userKey = ApiConfig.userDataKey;
  static const String _lastLoginKey = ApiConfig.lastLoginKey;
  
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );
  
  // Add auth debug logging with IST timestamp
  static void _authLog(String message) {
    if (ApiConfig.enableAuthDebugLogging) {
      final timestamp = TimezoneUtil.formatIST(TimezoneUtil.nowIST(), 'HH:mm:ss');
      debugPrint('🔐 AUTH [$timestamp IST]: $message');
    }
  }
  
  // Token expiry management - now handles IST timezone
  static Future<void> _saveTokenExpiry(tz.TZDateTime expiry) async {
    try {
      // Store as UTC but log as IST
      await _storage.write(key: _tokenExpiryKey, value: TimezoneUtil.toApiString(expiry));
      final istTime = TimezoneUtil.formatIST(expiry, 'dd MMM yyyy, HH:mm:ss');
      _authLog('Token expiry saved: $istTime IST');
    } catch (e) {
      _authLog('Failed to save token expiry: $e');
    }
  }

  static Future<tz.TZDateTime?> _getTokenExpiry() async {
    try {
      final expiryStr = await _storage.read(key: _tokenExpiryKey);
      if (expiryStr != null) {
        return TimezoneUtil.parseToIST(expiryStr);
      }
    } catch (e) {
      _authLog('Failed to read token expiry: $e');
    }
    return null;
  }

  static Future<bool> _isTokenNearExpiry() async {
    final expiry = await _getTokenExpiry();
    if (expiry == null) return false;
    
    final now = TimezoneUtil.nowIST();
    final timeUntilExpiry = expiry.difference(now);
    
    _authLog('Token expiry check - Expires: ${TimezoneUtil.formatIST(expiry, 'HH:mm:ss')}, Now: ${TimezoneUtil.formatIST(now, 'HH:mm:ss')}, Until expiry: ${timeUntilExpiry.inMinutes}min');
    
    // Consider token near expiry based on configuration
    return timeUntilExpiry < ApiConfig.tokenExpiryBuffer;
  }

  // HTTP client with enhanced configuration
  static http.Client get _client => HttpClientConfig.client;
  
  // Headers for API requests
  static Future<Map<String, String>> _getHeaders({bool includeAuth = true}) async {
    final headers = Map<String, String>.from(ApiConfig.appHeaders);

    if (includeAuth) {
      final token = await getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  // Enhanced token management with expiry and refresh tokens - now IST timezone aware
  static Future<void> saveToken(String token, {String? refreshToken, DateTime? expiresAt}) async {
    _authLog('Saving authentication tokens');
    
    try {
      await _storage.write(key: _tokenKey, value: token);
      await _storage.write(key: _lastLoginKey, value: TimezoneUtil.nowToApiString());
      
      if (refreshToken != null) {
        await _storage.write(key: _refreshTokenKey, value: refreshToken);
        _authLog('Refresh token saved');
      }
      
      if (expiresAt != null) {
        // Convert received DateTime to IST TZDateTime
        final istExpiry = TimezoneUtil.utcToIST(expiresAt);
        await _saveTokenExpiry(istExpiry);
      } else {
        // If no expiry provided, set a long-lived default
        final defaultExpiry = TimezoneUtil.nowIST().add(ApiConfig.defaultTokenExpiry);
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

  static Future<tz.TZDateTime?> getLastLoginTime() async {
    try {
      final lastLoginStr = await _storage.read(key: _lastLoginKey);
      if (lastLoginStr != null) {
        try {
          return TimezoneUtil.parseToIST(lastLoginStr);
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
        ApiEndpoints.refreshToken,
        HttpMethods.post,
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
          tz.TZDateTime? istExpiresAt;
          if (expiresIn != null) {
            istExpiresAt = TimezoneUtil.nowIST().add(Duration(seconds: expiresIn));
          }
          final expiresAt = istExpiresAt?.toUtc();

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
          case 'PATCH':
            response = await _client.patch(
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
        
        // Wait before retrying (faster linear backoff for better performance)
        if (attempt < maxRetries - 1) {
          await Future.delayed(Duration(seconds: attempt + 1)); // 1s, 2s instead of 2s, 4s, 6s
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
          await Future.delayed(Duration(seconds: attempt + 1)); // Faster retry for network errors
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
            data: parsedResponse, // IMPORTANT: Preserve entire response for error handling
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

  // ============================================================================
  // AUTHENTICATION ENDPOINTS
  // ============================================================================
  /// Checks if a user exists in the system before sending OTP.
  /// 
  /// This is typically the first step in the authentication flow.
  /// 
  /// Parameters:
  /// - [identifier]: User's email address or phone number
  /// - [method]: Authentication method - either 'email' or 'phone'
  /// 
  /// Returns:
  /// - Success: User existence status and user data if exists
  /// - Error: User not found or validation errors
  /// 
  /// Example:
  /// ```dart
  /// final response = await ApiService.checkUserExists(
  ///   identifier: 'john.doe@company.com',
  ///   method: 'email',
  /// );
  /// 
  /// if (response.success) {
  ///   print('User exists: ${response.data!['exists']}');
  /// }
  /// ```
  static Future<ApiResponse<Map<String, dynamic>>> checkUserExists({
    required String identifier,
    required String method, // 'email' or 'phone'
  }) async {
    return await _makeRequest<Map<String, dynamic>>(
      ApiEndpoints.checkUserExists,
      HttpMethods.post,
      body: {
        'identifier': identifier,
        'method': method,
      },
      includeAuth: false,
    );
  }

  /// Sends OTP (One-Time Password) to the user for authentication.
  /// 
  /// Should be called after confirming user exists via [checkUserExists].
  /// 
  /// Parameters:
  /// - [identifier]: User's email address or phone number
  /// - [method]: Authentication method - either 'email' or 'phone'
  /// 
  /// Returns:
  /// - Success: Contains signInId for OTP verification
  /// - Error: Failed to send OTP or user validation errors
  /// 
  /// Example:
  /// ```dart
  /// final response = await ApiService.sendOtp(
  ///   identifier: '+1234567890',
  ///   method: 'phone',
  /// );
  /// 
  /// if (response.success) {
  ///   final signInId = response.data!['signInId'];
  ///   // Proceed to OTP verification
  /// }
  /// ```
  static Future<ApiResponse<Map<String, dynamic>>> sendOtp({
    required String identifier,
    required String method, // 'email' or 'phone'
  }) async {
    return await _makeRequest<Map<String, dynamic>>(
      ApiEndpoints.sendOtp,
      HttpMethods.post,
      body: {
        'identifier': identifier,
        'method': method,
      },
      includeAuth: false,
    );
  }

  /// Verifies the OTP code and completes the authentication process.
  /// 
  /// This method automatically handles token storage upon successful verification.
  /// 
  /// Parameters:
  /// - [signInId]: Unique identifier from the [sendOtp] response
  /// - [code]: 6-digit OTP code entered by the user
  /// 
  /// Returns:
  /// - Success: User authentication data with session tokens
  /// - Error: Invalid OTP, expired code, or verification failure
  /// 
  /// Example:
  /// ```dart
  /// final response = await ApiService.verifyOtp(
  ///   signInId: 'sign_in_123456',
  ///   code: '123456',
  /// );
  /// 
  /// if (response.success) {
  ///   // User is now authenticated
  ///   final user = response.data!['user'];
  ///   print('Welcome ${user['firstName']}!');
  /// }
  /// ```
  static Future<ApiResponse<Map<String, dynamic>>> verifyOtp({
    required String signInId,
    required String code,
  }) async {
    final response = await _makeRequest<Map<String, dynamic>>(
      ApiEndpoints.verifyOtp,
      HttpMethods.post,
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
        tz.TZDateTime? istExpiresAt;
        if (expiresIn != null) {
          istExpiresAt = TimezoneUtil.nowIST().add(Duration(seconds: expiresIn));
        }
        final expiresAt = istExpiresAt?.toUtc();
        
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
      ApiEndpoints.resendOtp,
      HttpMethods.post,
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
      ApiEndpoints.verifyFirebaseToken,
      HttpMethods.post,
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
      ApiEndpoints.firebaseSignin,
      HttpMethods.post,
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
        tz.TZDateTime? istExpiresAt;
        if (expiresIn != null) {
          istExpiresAt = TimezoneUtil.nowIST().add(Duration(seconds: expiresIn));
        }
        final expiresAt = istExpiresAt?.toUtc();
        
        await saveToken(sessionToken, refreshToken: refreshToken, expiresAt: expiresAt);
        _authLog('Tokens saved after Firebase signin');
      }
    }

    return response;
  }

  static Future<ApiResponse<Map<String, dynamic>>> getCurrentUser() async {
    return await _makeRequest<Map<String, dynamic>>(
      ApiEndpoints.getCurrentUser,
      HttpMethods.get,
    );
  }

  static Future<ApiResponse<Map<String, dynamic>>> logout() async {
    final response = await _makeRequest<Map<String, dynamic>>(
      ApiEndpoints.logout,
      HttpMethods.post,
      timeout: ApiConfig.shortTimeout, // Use shorter timeout (10s) for logout
    );

    // Note: Local data clearing is now handled by AuthProvider
    // This method is now called in background for server cleanup

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
        ApiEndpoints.validateSession,
        HttpMethods.get,
        timeout: ApiConfig.shortTimeout,
        maxRetries: ApiConfig.validationMaxRetries,
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
              ApiEndpoints.validateSession,
              HttpMethods.get,
              timeout: ApiConfig.shortTimeout,
              maxRetries: ApiConfig.validationMaxRetries,
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

  // ============================================================================
  // USER MANAGEMENT ENDPOINTS
  // ============================================================================
  static Future<ApiResponse<Map<String, dynamic>>> getUserProfile() async {
    return await _makeRequest<Map<String, dynamic>>(
      ApiEndpoints.getUserProfile,
      HttpMethods.get,
    );
  }

  static Future<ApiResponse<Map<String, dynamic>>> updateUserProfile({
    required Map<String, dynamic> profileData,
  }) async {
    return await _makeRequest<Map<String, dynamic>>(
      ApiEndpoints.updateUserProfile,
      HttpMethods.put,
      body: profileData,
    );
  }

  /// Upload profile photo
  static Future<ApiResponse<Map<String, dynamic>>> uploadProfilePhoto(
    File imageFile,
  ) async {
    try {
      final token = await _storage.read(key: _tokenKey);
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final dio = Dio();
      
      // Prepare multipart form data
      final formData = FormData.fromMap({
        'photo': await MultipartFile.fromFile(
          imageFile.path,
          filename: imageFile.path.split('/').last,
        ),
      });

      debugPrint('Uploading profile photo to $baseUrl/api/users/profile/photo');
      // Make the request
      final response = await dio.put(
        '$baseUrl/users/profile/photo',
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      // Handle success response
      if (response.statusCode == 200 && response.data['success'] == true) {
        return ApiResponse<Map<String, dynamic>>(
          success: true,
          data: response.data['data'],
          message: response.data['message'],
        );
      } else {
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          message: response.data['message'] ?? 'Upload failed',
          error: response.data['error'],
        );
      }
    } on DioException catch (e) {
      String errorMessage;
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          errorMessage = 'Upload timeout. Please check your internet connection.';
          break;
        case DioExceptionType.badResponse:
          final data = e.response?.data;
          if (data is Map && data['message'] != null) {
            errorMessage = data['message'];
          } else {
            errorMessage = 'Upload failed. Please try again.';
          }
          break;
        default:
          errorMessage = 'Network error. Please check your connection.';
      }
      
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: errorMessage,
        error: e.toString(),
      );
    } catch (e) {
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: 'An unexpected error occurred during upload',
        error: e.toString(),
      );
    }
  }

  /// Delete profile photo
  static Future<ApiResponse<Map<String, dynamic>>> deleteProfilePhoto() async {
    return await _makeRequest<Map<String, dynamic>>(
      '/api/users/profile/photo',
      HttpMethods.delete,
    );
  }

  // User Management endpoints (Admin only)
  /// Creates a new user in the system (Admin only).
  /// 
  /// This endpoint requires admin privileges and creates a complete user profile.
  /// 
  /// Parameters:
  /// - [firstName]: User's first name (required)
  /// - [lastName]: User's last name (required)
  /// - [email]: User's email address (required, must be unique)
  /// - [phoneNumber]: User's phone number (required, must be unique)
  /// - [role]: User's role - 'admin', 'manager', 'director', 'field_staff', 'telecaller' (required)
  /// - [designation]: User's job title/designation (required)
  /// - [dateOfJoining]: Date when user joined (ISO string, optional)
  /// - [managerId]: ID of the user's manager (optional)
  /// - [workSchedule]: User's work schedule configuration (optional)
  /// 
  /// Returns:
  /// - Success: Created user data with generated ID
  /// - Error: Validation errors, duplicate email/phone, or permission denied
  /// 
  /// Example:
  /// ```dart
  /// final response = await ApiService.createUser(
  ///   firstName: 'John',
  ///   lastName: 'Doe',
  ///   email: 'john.doe@company.com',
  ///   phoneNumber: '+1234567890',
  ///   role: 'field_staff',
  ///   designation: 'Software Engineer',
  /// );
  /// 
  /// if (response.success) {
  ///   print('User created with ID: ${response.data!['id']}');
  /// }
  /// ```
  static Future<ApiResponse<Map<String, dynamic>>> createUser({
    required String firstName,
    required String lastName,
    required String email,
    required String phoneNumber,
    required String role,
    required String designation,
    String? employmentType,
    String? dateOfJoining,
    String? managerId,
    String? branchId,
    Map<String, dynamic>? workSchedule,
  }) async {
    return await _makeRequest<Map<String, dynamic>>(
      ApiEndpoints.createUser,
      HttpMethods.post,
      body: {
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'phoneNumber': phoneNumber,
        'role': role,
        'designation': designation,
        if (employmentType != null) 'employmentType': employmentType,
        if (dateOfJoining != null) 'dateOfJoining': dateOfJoining,
        if (managerId != null) 'managerId': managerId,
        if (branchId != null) 'branchId': branchId,
        if (workSchedule != null) 'workSchedule': workSchedule,
      },
    );
  }

  static Future<ApiResponse<Map<String, dynamic>>> getAllUsers({
    int page = 1,
    int limit = 20,
    String? role,
    String? status,
    String? search,
  }) async {
    final endpoint = ApiEndpoints.buildUsersQuery(
      page: page,
      limit: limit,
      role: role,
      status: status,
      search: search,
    );

    return await _makeRequest<Map<String, dynamic>>(
      endpoint,
      HttpMethods.get,
    );
  }

  static Future<ApiResponse<Map<String, dynamic>>> getUserById(String userId) async {
    return await _makeRequest<Map<String, dynamic>>(
      ApiEndpoints.userByIdEndpoint(userId),
      HttpMethods.get,
    );
  }

  static Future<ApiResponse<Map<String, dynamic>>> updateUser({
    required String userId,
    required Map<String, dynamic> userData,
  }) async {
    return await _makeRequest<Map<String, dynamic>>(
      ApiEndpoints.userByIdEndpoint(userId),
      HttpMethods.put,
      body: userData,
    );
  }

  /// Update user's employment type
  static Future<ApiResponse<Map<String, dynamic>>> updateEmploymentType({
    required String userId,
    required String employmentType,
  }) async {
    return await _makeRequest<Map<String, dynamic>>(
      '${ApiEndpoints.userByIdEndpoint(userId)}/employment-type',
      HttpMethods.put,
      body: {'employmentType': employmentType},
    );
  }

  static Future<ApiResponse<Map<String, dynamic>>> deleteUser(String userId) async {
    return await _makeRequest<Map<String, dynamic>>(
      ApiEndpoints.userByIdEndpoint(userId),
      HttpMethods.delete,
    );
  }

  static Future<ApiResponse<Map<String, dynamic>>> getManagers() async {
    return await _makeRequest<Map<String, dynamic>>(
      ApiEndpoints.getManagers,
      HttpMethods.get,
    );
  }


  // ============================================================================
  // ATTENDANCE TRACKING ENDPOINTS
  // ============================================================================
  /// Records user check-in for attendance tracking.
  /// 
  /// Creates a new attendance record for the current day or updates existing one.
  /// 
  /// Parameters:
  /// - [location]: GPS coordinates and address information (optional)
  ///   Format: {'latitude': 40.7128, 'longitude': -74.0060, 'address': 'New York, NY'}
  /// - [notes]: Additional notes for the check-in (optional)
  /// - [lateReason]: Reason for late arrival if applicable (optional)
  /// 
  /// Returns:
  /// - Success: Updated attendance record with check-in time
  /// - Error: Already checked in, invalid data, or system error
  /// 
  /// Example:
  /// ```dart
  /// final response = await ApiService.checkIn(
  ///   location: {
  ///     'latitude': 40.7128,
  ///     'longitude': -74.0060,
  ///     'address': 'Office Building, New York, NY'
  ///   },
  ///   notes: 'Started early today',
  /// );
  /// 
  /// if (response.success) {
  ///   print('Checked in at: ${response.data!['checkInTime']}');
  /// }
  /// ```
  static Future<ApiResponse<Map<String, dynamic>>> checkIn({
    Map<String, dynamic>? location,
    String? notes,
    String? lateReason,
  }) async {
    return await _makeRequest<Map<String, dynamic>>(
      ApiEndpoints.checkIn,
      HttpMethods.post,
      body: {
        if (location != null) 'location': location,
        if (notes != null) 'notes': notes,
        if (lateReason != null) 'lateReason': lateReason,
      },
      timeout: const Duration(seconds: 5), // Ultra-fast timeout for attendance
      maxRetries: 1, // Single attempt for fastest response
    );
  }

  /// Records user check-out for attendance tracking.
  /// 
  /// Updates the current day's attendance record with check-out time.
  /// 
  /// Parameters:
  /// - [location]: GPS coordinates and address information (optional)
  ///   Format: {'latitude': 40.7128, 'longitude': -74.0060, 'address': 'New York, NY'}
  /// - [notes]: Additional notes for the check-out (optional)
  /// 
  /// Returns:
  /// - Success: Updated attendance record with check-out time and total hours
  /// - Error: Not checked in, already checked out, or system error
  /// 
  /// Example:
  /// ```dart
  /// final response = await ApiService.checkOut(
  ///   location: {
  ///     'latitude': 40.7128,
  ///     'longitude': -74.0060,
  ///     'address': 'Office Building, New York, NY'
  ///   },
  ///   notes: 'Completed all tasks for today',
  /// );
  /// 
  /// if (response.success) {
  ///   print('Total hours worked: ${response.data!['totalHours']}');
  /// }
  /// ```
  static Future<ApiResponse<Map<String, dynamic>>> checkOut({
    Map<String, dynamic>? location,
    String? notes,
  }) async {
    return await _makeRequest<Map<String, dynamic>>(
      ApiEndpoints.checkOut,
      HttpMethods.post,
      body: {
        if (location != null) 'location': location,
        if (notes != null) 'notes': notes,
      },
      timeout: const Duration(seconds: 5), // Ultra-fast timeout for attendance
      maxRetries: 1, // Single attempt for fastest response
    );
  }

  static Future<ApiResponse<Map<String, dynamic>>> startBreak({
    String? type,
    String? notes,
  }) async {
    return await _makeRequest<Map<String, dynamic>>(
      ApiEndpoints.breakOut,
      HttpMethods.post,
      body: {
        if (type != null) 'type': type,
        if (notes != null) 'notes': notes,
      },
    );
  }

  static Future<ApiResponse<Map<String, dynamic>>> endBreak() async {
    return await _makeRequest<Map<String, dynamic>>(
      ApiEndpoints.breakIn,
      HttpMethods.post,
    );
  }

  static Future<ApiResponse<Map<String, dynamic>>> getTodayAttendance() async {
    return await _makeRequest<Map<String, dynamic>>(
      ApiEndpoints.todayAttendance,
      HttpMethods.get,
      timeout: const Duration(seconds: 4), // Ultra-fast timeout for attendance data
      maxRetries: 1, // Single attempt for fastest response
    );
  }

  static Future<ApiResponse<Map<String, dynamic>>> getAttendanceHistory({
    int page = 1,
    int limit = 30,
    String? startDate,
    String? endDate,
    String? status,
  }) async {
    final endpoint = ApiEndpoints.buildAttendanceHistoryQuery(
      page: page,
      limit: limit,
      startDate: startDate,
      endDate: endDate,
      status: status,
    );

    return await _makeRequest<Map<String, dynamic>>(
      endpoint,
      HttpMethods.get,
    );
  }

  static Future<ApiResponse<Map<String, dynamic>>> getAttendanceSummary({
    int? year,
    int? month,
  }) async {
    final endpoint = ApiEndpoints.buildAttendanceSummaryQuery(
      year: year,
      month: month,
    );

    return await _makeRequest<Map<String, dynamic>>(
      endpoint,
      HttpMethods.get,
    );
  }

  static Future<ApiResponse<Map<String, dynamic>>> getWeeklyAttendance({
    int? year,
    int? week,
  }) async {
    final Map<String, String> queryParams = {};
    if (year != null) queryParams['year'] = year.toString();
    if (week != null) queryParams['week'] = week.toString();

    final endpoint = queryParams.isEmpty
      ? '${ApiEndpoints.attendance}/weekly'
      : '${ApiEndpoints.attendance}/weekly?${Uri(queryParameters: queryParams).query}';

    return await _makeRequest<Map<String, dynamic>>(
      endpoint,
      HttpMethods.get,
    );
  }

  static Future<ApiResponse<Map<String, dynamic>>> getMonthlyAttendance({
    int? year,
    int? month,
  }) async {
    final endpoint = ApiEndpoints.buildAttendanceSummaryQuery(
      year: year,
      month: month,
    );

    return await _makeRequest<Map<String, dynamic>>(
      endpoint,
      HttpMethods.get,
    );
  }

  static Future<ApiResponse<dynamic>> getPendingApprovals() async {
    debugPrint('🔍 API: Calling getPendingApprovals endpoint');
    final result = await _makeRequest<dynamic>(
      '${ApiEndpoints.attendance}/pending-approvals',
      HttpMethods.get,
    );
    debugPrint('🔍 API: getPendingApprovals response - Success: ${result.success}, Status: ${result.statusCode}');
    if (!result.success) {
      debugPrint('🔍 API: getPendingApprovals error - Message: ${result.message}, Error: ${result.error}');
    }
    return result;
  }

  static Future<ApiResponse<Map<String, dynamic>>> approveAttendance(
    String attendanceId, {
    String? comments,
  }) async {
    final Map<String, dynamic> data = {};
    if (comments != null && comments.isNotEmpty) {
      data['comments'] = comments;
    }

    return await _makeRequest<Map<String, dynamic>>(
      '${ApiEndpoints.attendance}/$attendanceId/approve',
      HttpMethods.put,
      body: data,
    );
  }

  static Future<ApiResponse<Map<String, dynamic>>> rejectAttendance(
    String attendanceId, {
    required String comments,
  }) async {
    return await _makeRequest<Map<String, dynamic>>(
      '${ApiEndpoints.attendance}/$attendanceId/reject',
      HttpMethods.put,
      body: {'comments': comments},
    );
  }

  static Future<ApiResponse<Map<String, dynamic>>> getTeamAttendance({
    String? date,
    String? status,
  }) async {
    final Map<String, String> queryParams = {};
    if (date != null) queryParams['date'] = date;
    if (status != null) queryParams['status'] = status;

    final endpoint = queryParams.isEmpty
      ? '${ApiEndpoints.attendance}/team'
      : '${ApiEndpoints.attendance}/team?${Uri(queryParameters: queryParams).query}';

    return await _makeRequest<Map<String, dynamic>>(
      endpoint,
      HttpMethods.get,
    );
  }

  /// Get staff attendance for a specific user (Admin/Director only)
  ///
  /// Parameters:
  /// - [userId]: The user ID to fetch attendance for
  /// - [startDate]: Start date in ISO format (optional)
  /// - [endDate]: End date in ISO format (optional)
  /// - [page]: Page number (default: 1)
  /// - [limit]: Items per page (default: 30)
  ///
  /// Returns:
  /// - Success: Staff attendance records with pagination
  /// - Error: Failed to fetch attendance or access denied
  static Future<ApiResponse<Map<String, dynamic>>> getStaffAttendance({
    required String userId,
    String? startDate,
    String? endDate,
    int page = 1,
    int limit = 30,
  }) async {
    final Map<String, String> queryParams = {
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (startDate != null) queryParams['startDate'] = startDate;
    if (endDate != null) queryParams['endDate'] = endDate;

    final endpoint = '${ApiEndpoints.attendance}/staff/$userId?${Uri(queryParameters: queryParams).query}';

    return await _makeRequest<Map<String, dynamic>>(
      endpoint,
      HttpMethods.get,
    );
  }

  // ============================================================================
  // REPORTS ENDPOINTS
  // ============================================================================

  static Future<ApiResponse<Map<String, dynamic>>> getAttendanceSummaryReport({
    String? startDate,
    String? endDate,
    String? branchId,
    String? period,
  }) async {
    final Map<String, String> queryParams = {};
    if (startDate != null) queryParams['startDate'] = startDate;
    if (endDate != null) queryParams['endDate'] = endDate;
    if (branchId != null) queryParams['branchId'] = branchId;
    if (period != null) queryParams['period'] = period;

    final endpoint = queryParams.isEmpty
        ? ApiEndpoints.attendanceSummaryReport
        : '${ApiEndpoints.attendanceSummaryReport}?${Uri(queryParameters: queryParams).query}';

    return await _makeRequest<Map<String, dynamic>>(
      endpoint,
      HttpMethods.get,
    );
  }

  static Future<ApiResponse<Map<String, dynamic>>> getEmployeeAttendanceReport({
    String? employeeId,
    String? startDate,
    String? endDate,
    String? period,
  }) async {
    final Map<String, String> queryParams = {};
    if (employeeId != null) queryParams['employeeId'] = employeeId;
    if (startDate != null) queryParams['startDate'] = startDate;
    if (endDate != null) queryParams['endDate'] = endDate;
    if (period != null) queryParams['period'] = period;

    final endpoint = queryParams.isEmpty
        ? ApiEndpoints.employeeAttendanceReport
        : '${ApiEndpoints.employeeAttendanceReport}?${Uri(queryParameters: queryParams).query}';

    return await _makeRequest<Map<String, dynamic>>(
      endpoint,
      HttpMethods.get,
    );
  }

  static Future<ApiResponse<Map<String, dynamic>>> getBranchComparisonReport({
    String? startDate,
    String? endDate,
    String? period,
  }) async {
    final Map<String, String> queryParams = {};
    if (startDate != null) queryParams['startDate'] = startDate;
    if (endDate != null) queryParams['endDate'] = endDate;
    if (period != null) queryParams['period'] = period;

    final endpoint = queryParams.isEmpty
        ? ApiEndpoints.branchComparisonReport
        : '${ApiEndpoints.branchComparisonReport}?${Uri(queryParameters: queryParams).query}';

    return await _makeRequest<Map<String, dynamic>>(
      endpoint,
      HttpMethods.get,
    );
  }

  // ============================================================================
  // BRANCH MANAGEMENT ENDPOINTS
  // ============================================================================
  
  /// Get list of branches with pagination and filtering
  /// 
  /// Parameters:
  /// - [page]: Page number (default: 1)
  /// - [limit]: Items per page (default: 10)
  /// - [search]: Search query for branch name, ID, city, or state
  /// - [status]: Filter by status - 'active', 'inactive', 'temporarily_closed', or 'all'
  /// 
  /// Returns:
  /// - Success: List of branches with pagination info
  /// - Error: Failed to fetch branches
  static Future<ApiResponse<Map<String, dynamic>>> getBranches({
    int page = 1,
    int limit = 10,
    String? search,
    String? status,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    
    if (search != null && search.isNotEmpty) {
      queryParams['search'] = search;
    }
    
    if (status != null && status.isNotEmpty) {
      queryParams['status'] = status;
    }
    
    final uri = Uri(path: '/branches', queryParameters: queryParams);
    
    return await _makeRequest<Map<String, dynamic>>(
      uri.toString(),
      HttpMethods.get,
    );
  }

  /// Get single branch details by ID
  /// 
  /// Parameters:
  /// - [branchId]: The MongoDB ObjectId of the branch
  /// 
  /// Returns:
  /// - Success: Branch details with employee list
  /// - Error: Branch not found or access denied
  static Future<ApiResponse<Map<String, dynamic>>> getBranchById(String branchId) async {
    return await _makeRequest<Map<String, dynamic>>(
      '/branches/$branchId',
      HttpMethods.get,
    );
  }

  /// Create a new branch
  /// 
  /// Parameters:
  /// - [branchData]: Map containing branch information:
  ///   - branchName (required): Name of the branch
  ///   - branchAddress (required): Address object with street, city, state, pincode, country
  ///   - branchManager (optional): User ID of the branch manager
  ///   - contactInfo (optional): Contact information with phone and email
  ///   - status (optional): Branch status - defaults to 'active'
  ///   - establishedDate (optional): Date when branch was established
  /// 
  /// Returns:
  /// - Success: Created branch with auto-generated branchId
  /// - Error: Validation errors or creation failure
  static Future<ApiResponse<Map<String, dynamic>>> createBranch(Map<String, dynamic> branchData) async {
    return await _makeRequest<Map<String, dynamic>>(
      '/branches',
      HttpMethods.post,
      body: branchData,
    );
  }

  /// Update an existing branch
  /// 
  /// Parameters:
  /// - [branchId]: The MongoDB ObjectId of the branch to update
  /// - [branchData]: Map containing updated branch information
  /// 
  /// Returns:
  /// - Success: Updated branch data
  /// - Error: Branch not found, validation errors, or update failure
  static Future<ApiResponse<Map<String, dynamic>>> updateBranch(String branchId, Map<String, dynamic> branchData) async {
    return await _makeRequest<Map<String, dynamic>>(
      '/branches/$branchId',
      HttpMethods.put,
      body: branchData,
    );
  }

  /// Delete a branch
  /// 
  /// Parameters:
  /// - [branchId]: The MongoDB ObjectId of the branch to delete
  /// 
  /// Returns:
  /// - Success: Confirmation message
  /// - Error: Branch not found, has active employees, or deletion failure
  static Future<ApiResponse<Map<String, dynamic>>> deleteBranch(String branchId) async {
    return await _makeRequest<Map<String, dynamic>>(
      '/branches/$branchId',
      HttpMethods.delete,
    );
  }

  /// Get users assigned to a specific branch
  /// 
  /// Parameters:
  /// - [branchId]: The MongoDB ObjectId of the branch
  /// 
  /// Returns:
  /// - Success: List of users with branch info and summary
  /// - Error: Branch not found or access denied
  static Future<ApiResponse<Map<String, dynamic>>> getBranchUsers(String branchId) async {
    return await _makeRequest<Map<String, dynamic>>(
      '/branches/$branchId/users',
      HttpMethods.get,
    );
  }

  /// Get branch management statistics
  /// 
  /// Returns:
  /// - Success: Branch statistics including counts and distribution
  /// - Error: Failed to fetch statistics
  static Future<ApiResponse<Map<String, dynamic>>> getBranchStats() async {
    return await _makeRequest<Map<String, dynamic>>(
      '/branches/admin/stats',
      HttpMethods.get,
    );
  }

  // Health check and connectivity test
  static Future<ApiResponse<Map<String, dynamic>>> healthCheck() async {
    return await _makeRequest<Map<String, dynamic>>(
      ApiEndpoints.healthCheck,
      HttpMethods.get,
      includeAuth: false,
      timeout: ApiConfig.shortTimeout,
      maxRetries: ApiConfig.healthCheckMaxRetries,
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

  // ID Card Management
  static Future<ApiResponse> generateIdCard() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl${ApiEndpoints.generateIdCard}'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        // Backend returns PDF as binary data
        return ApiResponse(
          success: true,
          message: 'ID card generated successfully',
          data: response.bodyBytes, // Binary PDF data
          statusCode: response.statusCode,
        );
      } else {
        // Try to parse error response
        try {
          final Map<String, dynamic> errorData = jsonDecode(response.body);
          return ApiResponse(
            success: false,
            message: errorData['message'] ?? 'Failed to generate ID card',
            statusCode: response.statusCode,
            error: errorData['error']?.toString(),
          );
        } catch (e) {
          return ApiResponse(
            success: false,
            message: 'Failed to generate ID card',
            statusCode: response.statusCode,
            error: 'Server error: ${response.statusCode}',
          );
        }
      }
    } catch (e) {
      debugPrint('🔥 ID card generation error: $e');
      return ApiResponse(
        success: false,
        message: 'Failed to generate ID card',
        error: e.toString(),
      );
    }
  }

  // Visiting Card Management
  static Future<ApiResponse> generateVisitingCard() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl${ApiEndpoints.generateVisitingCard}'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        // Backend returns PDF as binary data
        return ApiResponse(
          success: true,
          message: 'Visiting card generated successfully',
          data: response.bodyBytes, // Binary PDF data
          statusCode: response.statusCode,
        );
      } else {
        // Try to parse error response
        try {
          final Map<String, dynamic> errorData = jsonDecode(response.body);
          return ApiResponse(
            success: false,
            message: errorData['message'] ?? 'Failed to generate visiting card',
            statusCode: response.statusCode,
            error: errorData['error']?.toString(),
          );
        } catch (e) {
          return ApiResponse(
            success: false,
            message: 'Failed to generate visiting card',
            statusCode: response.statusCode,
            error: 'Server error: ${response.statusCode}',
          );
        }
      }
    } catch (e) {
      debugPrint('🔥 Visiting card generation error: $e');
      return ApiResponse(
        success: false,
        message: 'Failed to generate visiting card',
        error: e.toString(),
      );
    }
  }

  // ============================================================================
  // DOCUMENT MANAGEMENT ENDPOINTS
  // ============================================================================

  /// Get user's documents
  static Future<ApiResponse<Map<String, dynamic>>> getUserDocuments() async {
    return await _makeRequest<Map<String, dynamic>>(
      '/users/documents',
      HttpMethods.get,
    );
  }

  /// Upload a document with optional naming
  static Future<ApiResponse<Map<String, dynamic>>> uploadDocument(
    File documentFile, {
    String? documentName,
  }) async {
    try {
      final token = await _storage.read(key: _tokenKey);
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final dio = Dio();

      // Prepare multipart form data
      final formData = FormData.fromMap({
        'document': await MultipartFile.fromFile(
          documentFile.path,
          filename: documentFile.path.split('/').last,
        ),
        if (documentName != null && documentName.isNotEmpty) 'documentName': documentName,
      });

      debugPrint('Uploading document to $baseUrl/users/documents');

      // Make the request
      final response = await dio.post(
        '$baseUrl/users/documents',
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      // Handle success response
      if (response.statusCode == 201 && response.data['success'] == true) {
        return ApiResponse<Map<String, dynamic>>(
          success: true,
          data: response.data['data'],
          message: response.data['message'],
        );
      } else {
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          message: response.data['message'] ?? 'Upload failed',
          error: response.data['error'],
        );
      }
    } on DioException catch (e) {
      String errorMessage;
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          errorMessage = 'Upload timeout. Please check your internet connection.';
          break;
        case DioExceptionType.badResponse:
          final data = e.response?.data;
          if (data is Map && data['message'] != null) {
            errorMessage = data['message'];
          } else {
            errorMessage = 'Upload failed. Please try again.';
          }
          break;
        default:
          errorMessage = 'Network error. Please check your connection.';
      }

      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: errorMessage,
        error: e.toString(),
      );
    } catch (e) {
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: 'An unexpected error occurred during upload',
        error: e.toString(),
      );
    }
  }

  /// Update document name
  static Future<ApiResponse<Map<String, dynamic>>> updateDocument({
    required String documentId,
    required String documentName,
  }) async {
    return await _makeRequest<Map<String, dynamic>>(
      '/users/documents/$documentId',
      HttpMethods.put,
      body: {
        'documentName': documentName,
      },
    );
  }

  /// Delete a document
  static Future<ApiResponse<Map<String, dynamic>>> deleteDocument(String documentId) async {
    return await _makeRequest<Map<String, dynamic>>(
      '/users/documents/$documentId',
      HttpMethods.delete,
    );
  }

  /// Get document download URL
  static String getDocumentDownloadUrl(String documentId) {
    return '$baseUrl/users/documents/$documentId';
  }

  // ============================================================================
  // FEEDBACK MANAGEMENT ENDPOINTS
  // ============================================================================

  /// Submit feedback/complaint/bug report with attachments
  static Future<ApiResponse<Map<String, dynamic>>> submitFeedback({
    required String type,
    required String title,
    required String description,
    List<File>? attachments,
  }) async {
    try {
      final token = await _storage.read(key: _tokenKey);
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final dio = Dio();

      // Prepare multipart form data
      final formData = FormData.fromMap({
        'type': type,
        'title': title,
        'description': description,
      });

      // Add attachments if provided
      if (attachments != null && attachments.isNotEmpty) {
        for (var file in attachments) {
          formData.files.add(
            MapEntry(
              'attachments',
              await MultipartFile.fromFile(
                file.path,
                filename: file.path.split('/').last,
              ),
            ),
          );
        }
      }

      debugPrint('Submitting feedback to $baseUrl/feedback');

      // Make the request
      final response = await dio.post(
        '$baseUrl/feedback',
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      // Handle success response
      if (response.statusCode == 201 && response.data['success'] == true) {
        return ApiResponse<Map<String, dynamic>>(
          success: true,
          data: response.data['data'],
          message: response.data['message'],
        );
      } else {
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          message: response.data['message'] ?? 'Submission failed',
          error: response.data['error'],
        );
      }
    } on DioException catch (e) {
      String errorMessage;
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          errorMessage = 'Submission timeout. Please check your internet connection.';
          break;
        case DioExceptionType.badResponse:
          final data = e.response?.data;
          if (data is Map && data['message'] != null) {
            errorMessage = data['message'];
          } else {
            errorMessage = 'Submission failed. Please try again.';
          }
          break;
        default:
          errorMessage = 'Network error. Please check your connection.';
      }

      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: errorMessage,
        error: e.toString(),
      );
    } catch (e) {
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: 'An unexpected error occurred during submission',
        error: e.toString(),
      );
    }
  }

  /// Get user's feedback list
  static Future<ApiResponse<Map<String, dynamic>>> getUserFeedback({
    int page = 1,
    int limit = 10,
    String? type,
    String? status,
  }) async {
    final endpoint = ApiEndpoints.buildFeedbackQuery(
      page: page,
      limit: limit,
      type: type,
      status: status,
    );

    return await _makeRequest<Map<String, dynamic>>(
      endpoint,
      HttpMethods.get,
    );
  }

  /// Get all feedback (Admin/Director only)
  static Future<ApiResponse<Map<String, dynamic>>> getAllFeedback({
    int page = 1,
    int limit = 20,
    String? type,
    String? status,
    String? priority,
    String? search,
  }) async {
    final endpoint = ApiEndpoints.buildAllFeedbackQuery(
      page: page,
      limit: limit,
      type: type,
      status: status,
      priority: priority,
      search: search,
    );

    return await _makeRequest<Map<String, dynamic>>(
      endpoint,
      HttpMethods.get,
    );
  }

  /// Get feedback statistics (Admin/Director only)
  static Future<ApiResponse<Map<String, dynamic>>> getFeedbackStats() async {
    return await _makeRequest<Map<String, dynamic>>(
      ApiEndpoints.getFeedbackStats,
      HttpMethods.get,
    );
  }

  /// Get feedback by ID
  static Future<ApiResponse<Map<String, dynamic>>> getFeedbackById(String feedbackId) async {
    return await _makeRequest<Map<String, dynamic>>(
      ApiEndpoints.feedbackByIdEndpoint(feedbackId),
      HttpMethods.get,
    );
  }

  /// Update feedback status and/or priority (Admin/Director only)
  static Future<ApiResponse<Map<String, dynamic>>> updateFeedbackStatus({
    required String feedbackId,
    String? status,
    String? priority,
    String? internalNotes,
  }) async {
    return await _makeRequest<Map<String, dynamic>>(
      ApiEndpoints.updateFeedbackStatusEndpoint(feedbackId),
      HttpMethods.patch,
      body: {
        if (status != null) 'status': status,
        if (priority != null) 'priority': priority,
        if (internalNotes != null) 'internalNotes': internalNotes,
      },
    );
  }

  /// Add response to feedback (Admin/Director only)
  static Future<ApiResponse<Map<String, dynamic>>> addFeedbackResponse({
    required String feedbackId,
    required String message,
  }) async {
    return await _makeRequest<Map<String, dynamic>>(
      ApiEndpoints.addFeedbackResponseEndpoint(feedbackId),
      HttpMethods.post,
      body: {
        'message': message,
      },
    );
  }

  /// Delete feedback (Admin only)
  static Future<ApiResponse<Map<String, dynamic>>> deleteFeedback(String feedbackId) async {
    return await _makeRequest<Map<String, dynamic>>(
      ApiEndpoints.feedbackByIdEndpoint(feedbackId),
      HttpMethods.delete,
    );
  }

  /// Send appointment letter to employee (Admin/Director only)
  static Future<ApiResponse<Map<String, dynamic>>> sendAppointmentLetter(String userId) async {
    return await _makeRequest<Map<String, dynamic>>(
      '/users/$userId/appointment-letter',
      HttpMethods.post,
    );
  }

  static Future<ApiResponse<Map<String, dynamic>>> sendManualAppointmentLetter({
    required String firstName,
    required String lastName,
    required String email,
    required String phoneNumber,
    required String address,
    required String designation,
    required String dateOfJoining,
    required String branchName,
    required String netSalary,
  }) async {
    return await _makeRequest<Map<String, dynamic>>(
      '/users/appointment-letter/manual',
      HttpMethods.post,
      body: {
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'phoneNumber': phoneNumber,
        'address': address,
        'designation': designation,
        'dateOfJoining': dateOfJoining,
        'branchName': branchName,
        'netSalary': netSalary,
      },
    );
  }

  // Cleanup
  static void dispose() {
    HttpClientConfig.dispose();
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
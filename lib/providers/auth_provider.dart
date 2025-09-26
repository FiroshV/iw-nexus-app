import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/firebase_phone_auth_service.dart';

enum AuthStatus {
  uninitialized,
  unauthenticated,
  authenticated,
  loading,
}

class AuthProvider extends ChangeNotifier {
  AuthStatus _status = AuthStatus.uninitialized;
  Map<String, dynamic>? _user;
  String? _error;
  bool _isLoading = false;

  // Getters
  AuthStatus get status => _status;
  Map<String, dynamic>? get user => _user;
  String? get error => _error;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  // Initialize authentication state with enhanced persistence
  Future<void> initializeAuth() async {
    if (_status != AuthStatus.uninitialized) return;

    debugPrint('🔐 AUTH: Starting authentication initialization');
    _setLoading(true);

    try {
      // Check if we have a valid session stored locally
      final hasValidSession = await ApiService.hasValidSession();
      debugPrint('🔐 AUTH: Has valid local session: $hasValidSession');
      
      if (hasValidSession) {
        // Try to restore user data from local storage first
        final localUserData = await ApiService.getUserData();
        if (localUserData != null) {
          debugPrint('🔐 AUTH: Restored user data from local storage');
          _user = localUserData;
          _status = AuthStatus.authenticated;
          _setLoading(false);
          
          // Validate with server in the background (non-blocking)
          _validateSessionInBackground();
          return;
        } else {
          debugPrint('🔐 AUTH: Valid session but no user data found');
        }
      }

      // If no valid local session or no user data, try server validation
      final token = await ApiService.getToken();
      if (token != null) {
        debugPrint('🔐 AUTH: Token found, validating with server');
        
        try {
          // Validate existing token with server (with timeout protection)
          final response = await ApiService.validateSession();
          
          if (response.success) {
            debugPrint('🔐 AUTH: Server validation successful, fetching user data');
            
            // Get fresh user info from server (with populated branch data)
            try {
              final userResponse = await ApiService.getUserProfile();
              if (userResponse.success && userResponse.data != null) {
                _user = userResponse.data!;
                _status = AuthStatus.authenticated;

                // Save user data locally for faster future loads
                await ApiService.saveUserData(_user!);
                debugPrint('🔐 AUTH: User profile data fetched and saved successfully with branch info');
              } else {
                debugPrint('🔐 AUTH: Failed to fetch user profile data: ${userResponse.message}');
                // Only clear auth if we get explicit auth errors
                if (userResponse.statusCode == 401 || userResponse.statusCode == 403) {
                  await _clearAuth();
                } else {
                  // For other errors, set unauthenticated but don't clear stored data
                  _status = AuthStatus.unauthenticated;
                }
              }
            } catch (e) {
              debugPrint('🔐 AUTH: Error fetching user data: $e');
              // Don't clear auth on network errors, just set unauthenticated
              _status = AuthStatus.unauthenticated;
            }
          } else {
            debugPrint('🔐 AUTH: Server validation failed: ${response.message}');
            // Only clear auth for explicit auth failures (401/403)
            if (response.statusCode == 401 || response.statusCode == 403) {
              await _clearAuth();
            } else {
              // For other errors (network, server), keep existing data and set unauthenticated
              _status = AuthStatus.unauthenticated;
            }
          }
        } catch (e) {
          debugPrint('🔐 AUTH: Server validation error: $e');
          // On network/server errors, don't clear auth data
          _status = AuthStatus.unauthenticated;
        }
      } else {
        debugPrint('🔐 AUTH: No token found, setting unauthenticated');
        _status = AuthStatus.unauthenticated;
      }
    } catch (e) {
      debugPrint('🔐 AUTH: Initialization error: $e');
      _error = 'Failed to initialize authentication: ${e.toString()}';
      // Don't clear auth data on initialization errors
      _status = AuthStatus.unauthenticated;
    }

    _setLoading(false);
    debugPrint('🔐 AUTH: Initialization completed with status: $_status');
  }

  // Validate session in background without affecting UI
  Future<void> _validateSessionInBackground() async {
    debugPrint('🔐 AUTH: Starting background session validation');
    
    try {
      final response = await ApiService.validateSession();
      
      if (!response.success) {
        // Only clear auth if we get explicit auth errors (401/403)
        if (response.statusCode == 401 || response.statusCode == 403) {
          debugPrint('🔐 AUTH: Background validation failed with auth error - clearing session');
          await _clearAuth();
        } else {
          debugPrint('🔐 AUTH: Background validation failed with non-auth error - keeping session');
        }
      } else {
        debugPrint('🔐 AUTH: Background validation successful');
        
        // Optionally refresh user data (but don't fail if this fails)
        try {
          final userResponse = await ApiService.getUserProfile();
          if (userResponse.success && userResponse.data != null) {
            _user = userResponse.data!;
            await ApiService.saveUserData(_user!);
            notifyListeners();
            debugPrint('🔐 AUTH: User profile data refreshed in background with branch info');
          }
        } catch (e) {
          // Silently continue if user data refresh fails
          debugPrint('🔐 AUTH: Failed to refresh user profile data in background: $e');
        }
      }
    } catch (e) {
      // Don't clear auth for background validation errors
      // User can continue with cached data
      debugPrint('🔐 AUTH: Background session validation error (continuing with cached data): $e');
    }
  }

  // Send OTP
  Future<ApiResponse<Map<String, dynamic>>> sendOtp({
    required String identifier,
    required String method,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      // First check if user exists in the database
      final userCheckResponse = await ApiService.checkUserExists(
        identifier: identifier,
        method: method,
      );

      if (!userCheckResponse.success) {
        _error = userCheckResponse.message;
        return userCheckResponse;
      }

      if (method == 'phone') {
        // Use Firebase for phone OTP
        final firebaseResponse = await FirebasePhoneAuthService.sendPhoneOTP(identifier);
        
        if (firebaseResponse['success'] == true) {
          return ApiResponse<Map<String, dynamic>>(
            success: true,
            message: firebaseResponse['message'],
            data: {
              'signInId': firebaseResponse['verificationId'],
              'identifier': identifier,
              'provider': 'firebase'
            },
          );
        } else {
          _error = firebaseResponse['message'];
          return ApiResponse<Map<String, dynamic>>(
            success: false,
            message: firebaseResponse['message'],
          );
        }
      } else {
        // Use regular API for email OTP
        final response = await ApiService.sendOtp(
          identifier: identifier,
          method: method,
        );

        if (!response.success) {
          _error = response.message;
        }

        return response;
      }
    } catch (e) {
      _error = 'Failed to send OTP: ${e.toString()}';
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: _error!,
      );
    } finally {
      _setLoading(false);
    }
  }

  // Verify OTP and login
  Future<bool> verifyOtpAndLogin({
    required String signInId,
    required String code,
    String? provider,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      // Check if this is a Firebase phone verification
      if (provider == 'firebase') {
        // This is Firebase phone authentication - simplified flow
        final firebaseResponse = await FirebasePhoneAuthService.verifyPhoneOTP(code);
        
        if (firebaseResponse['success'] == true) {
          // Firebase verification successful - send ID token to backend
          final idToken = firebaseResponse['idToken'];
          
          final backendResponse = await ApiService.verifyFirebaseToken(
            idToken: idToken,
          );
          
          if (backendResponse.success) {
            // Save session token with refresh token and expiry
            final sessionToken = backendResponse.data?['sessionToken'] as String?;
            final refreshToken = backendResponse.data?['refreshToken'] as String?;
            final expiresIn = backendResponse.data?['expiresIn'] as int?;
            
            if (sessionToken != null) {
              DateTime? expiresAt;
              if (expiresIn != null) {
                expiresAt = DateTime.now().add(Duration(seconds: expiresIn));
              }
              
              await ApiService.saveToken(
                sessionToken, 
                refreshToken: refreshToken, 
                expiresAt: expiresAt
              );
            }

            // Store user info both locally and in memory
            if (backendResponse.data?['user'] != null) {
              _user = backendResponse.data!['user'];
              await ApiService.saveUserData(_user!);
            }
            
            _status = AuthStatus.authenticated;
            notifyListeners();
            return true;
          } else {
            _error = backendResponse.message;
            return false;
          }
        } else {
          _error = firebaseResponse['message'];
          return false;
        }
      } else {
        // This is email OTP verification via regular API
        final response = await ApiService.verifyOtp(
          signInId: signInId,
          code: code,
        );

        if (response.success) {
          // Save session token with refresh token and expiry
          final sessionToken = response.data?['sessionToken'] as String?;
          final refreshToken = response.data?['refreshToken'] as String?;
          final expiresIn = response.data?['expiresIn'] as int?;
          
          if (sessionToken != null) {
            DateTime? expiresAt;
            if (expiresIn != null) {
              expiresAt = DateTime.now().add(Duration(seconds: expiresIn));
            }
            
            await ApiService.saveToken(
              sessionToken, 
              refreshToken: refreshToken, 
              expiresAt: expiresAt
            );
          }

          // Store user info both locally and in memory
          if (response.data?['user'] != null) {
            _user = response.data!['user'];
            await ApiService.saveUserData(_user!);
          }
          
          _status = AuthStatus.authenticated;
          notifyListeners();
          return true;
        } else {
          _error = response.message;
          return false;
        }
      }
    } catch (e) {
      _error = 'Failed to verify OTP: ${e.toString()}';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Resend OTP
  Future<ApiResponse<Map<String, dynamic>>> resendOtp({
    required String signInId,
    required String method,
    String? provider,
    String? identifier,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      if (provider == 'firebase' && method == 'phone') {
        // Use Firebase for phone OTP resend
        final phoneNumber = identifier ?? signInId; // Use identifier if available, fallback to signInId
        final firebaseResponse = await FirebasePhoneAuthService.resendPhoneOTP(phoneNumber);
        
        if (firebaseResponse['success'] == true) {
          return ApiResponse<Map<String, dynamic>>(
            success: true,
            message: firebaseResponse['message'],
            data: {
              'signInId': firebaseResponse['verificationId'],
              'identifier': identifier ?? signInId,
              'provider': 'firebase'
            },
          );
        } else {
          _error = firebaseResponse['message'];
          return ApiResponse<Map<String, dynamic>>(
            success: false,
            message: firebaseResponse['message'],
          );
        }
      } else {
        // Use regular API for email OTP resend
        final response = await ApiService.resendOtp(
          signInId: signInId,
          method: method,
        );

        if (!response.success) {
          _error = response.message;
        }

        return response;
      }
    } catch (e) {
      _error = 'Failed to resend OTP: ${e.toString()}';
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: _error!,
      );
    } finally {
      _setLoading(false);
    }
  }

  // Logout
  Future<void> logout() async {
    _setLoading(true);

    try {
      await ApiService.logout();
    } catch (e) {
      // Even if logout API fails, we should clear local auth
      debugPrint('Logout API failed: $e');
    }

    await _clearAuth();
    _setLoading(false);
  }

  // Refresh user data
  Future<void> refreshUser() async {
    if (!isAuthenticated) return;

    try {
      final response = await ApiService.getCurrentUser();
      if (response.success) {
        _user = response.data?['user'];
        notifyListeners();
      } else {
        // If user fetch fails with auth errors, clear session
        await _clearAuth();
      }
    } catch (e) {
      debugPrint('Failed to refresh user: $e');
    }
  }

  // Update user profile
  Future<bool> updateProfile(Map<String, dynamic> profileData) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await ApiService.updateUserProfile(
        profileData: profileData,
      );

      if (response.success) {
        // Update local user data
        if (response.data != null) {
          _user = response.data;
        }
        notifyListeners();
        return true;
      } else {
        _error = response.message;
        return false;
      }
    } catch (e) {
      _error = 'Failed to update profile: ${e.toString()}';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Private methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> _clearAuth() async {
    await ApiService.clearAllAuthData();
    _user = null;
    _status = AuthStatus.unauthenticated;
    _error = null;
    notifyListeners();
  }

  // Manually set error (for UI components)
  void setError(String error) {
    _error = error;
    notifyListeners();
  }

  // Clear error manually
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Handle app lifecycle changes
  Future<void> onAppResumed() async {
    if (_status == AuthStatus.authenticated) {
      debugPrint('🔐 AUTH: App resumed, checking session validity');
      
      // Check if session is still valid when app is resumed
      try {
        final hasValidSession = await ApiService.hasValidSession();
        if (!hasValidSession) {
          debugPrint('🔐 AUTH: Local session expired on app resume');
          await _clearAuth();
        } else {
          debugPrint('🔐 AUTH: Local session still valid on app resume');
          
          // Background validation and user refresh (non-blocking)
          _validateSessionInBackground();
        }
      } catch (e) {
        // Handle silently - user can continue with cached data
        debugPrint('🔐 AUTH: App resume auth check failed (continuing with cached data): $e');
      }
    } else {
      debugPrint('🔐 AUTH: App resumed but user not authenticated');
    }
  }

  // Force logout with confirmation
  Future<bool> confirmLogout(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Logout'),
          content: const Text('Are you sure you want to log out?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      await logout();
      return true;
    }
    return false;
  }
}
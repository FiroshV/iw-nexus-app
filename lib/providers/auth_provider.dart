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

    _setLoading(true);

    try {
      // Check if we have a valid session stored locally
      final hasValidSession = await ApiService.hasValidSession();
      
      if (hasValidSession) {
        // Try to restore user data from local storage first
        final localUserData = await ApiService.getUserData();
        if (localUserData != null) {
          _user = localUserData;
          _status = AuthStatus.authenticated;
          _setLoading(false);
          
          // Validate with server in the background
          _validateSessionInBackground();
          return;
        }
      }

      // If no valid local session, check with server
      final token = await ApiService.getToken();
      if (token != null) {
        // Validate existing token with server
        final response = await ApiService.validateSession();
        if (response.success) {
          // Get fresh user info from server
          final userResponse = await ApiService.getCurrentUser();
          if (userResponse.success && userResponse.data?['user'] != null) {
            _user = userResponse.data!['user'];
            _status = AuthStatus.authenticated;
            
            // Save user data locally for faster future loads
            await ApiService.saveUserData(_user!);
          } else {
            await _clearAuth();
          }
        } else {
          await _clearAuth();
        }
      } else {
        _status = AuthStatus.unauthenticated;
      }
    } catch (e) {
      _error = 'Failed to initialize authentication: ${e.toString()}';
      _status = AuthStatus.unauthenticated;
    }

    _setLoading(false);
  }

  // Validate session in background without affecting UI
  Future<void> _validateSessionInBackground() async {
    try {
      final response = await ApiService.validateSession();
      if (!response.success) {
        // Session is no longer valid, clear auth
        await _clearAuth();
      } else {
        // Optionally refresh user data
        final userResponse = await ApiService.getCurrentUser();
        if (userResponse.success && userResponse.data?['user'] != null) {
          _user = userResponse.data!['user'];
          await ApiService.saveUserData(_user!);
          notifyListeners();
        }
      }
    } catch (e) {
      // Don't clear auth for background validation errors
      // User can continue with cached data
      debugPrint('Background session validation failed: $e');
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
  }) async {
    _setLoading(true);
    _clearError();

    try {
      // Check if this is a Firebase phone verification (signInId starts with phone number)
      if (signInId.startsWith('+')) {
        // This is Firebase phone authentication - simplified flow
        final firebaseResponse = await FirebasePhoneAuthService.verifyPhoneOTP(code);
        
        if (firebaseResponse['success'] == true) {
          // Firebase verification successful - directly notify backend and create session
          final firebaseUser = firebaseResponse['user'];
          final firebaseUid = firebaseUser['uid'];
          final phoneNumber = firebaseUser['phoneNumber'];
          
          final backendResponse = await ApiService.notifyFirebaseSignin(
            firebaseUid: firebaseUid,
            phoneNumber: phoneNumber,
          );
          
          if (backendResponse.success) {
            // Save session token
            if (backendResponse.data?['sessionToken'] != null) {
              await ApiService.saveToken(backendResponse.data!['sessionToken']);
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
          // Save session token
          if (response.data?['sessionToken'] != null) {
            await ApiService.saveToken(response.data!['sessionToken']);
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
  }) async {
    _setLoading(true);
    _clearError();

    try {
      if (method == 'phone' && signInId.startsWith('+')) {
        // Use Firebase for phone OTP resend
        final firebaseResponse = await FirebasePhoneAuthService.resendPhoneOTP(signInId);
        
        if (firebaseResponse['success'] == true) {
          return ApiResponse<Map<String, dynamic>>(
            success: true,
            message: firebaseResponse['message'],
            data: {
              'signInId': firebaseResponse['verificationId'],
              'identifier': signInId,
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
        // If user fetch fails, might be token expired
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
      // Check if session is still valid when app is resumed
      try {
        final hasValidSession = await ApiService.hasValidSession();
        if (!hasValidSession) {
          await _clearAuth();
        } else {
          // Optionally refresh user data
          await refreshUser();
        }
      } catch (e) {
        // Handle silently - user can continue with cached data
        debugPrint('App resume auth check failed: $e');
      }
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
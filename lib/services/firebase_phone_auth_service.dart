import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class FirebasePhoneAuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Store verification data
  static String? _verificationId;
  static int? _resendToken;

  /// Send OTP to phone number using Firebase Auth
  static Future<Map<String, dynamic>> sendPhoneOTP(String phoneNumber) async {
    try {
      debugPrint('🔥 Firebase: Sending OTP to $phoneNumber');
      
      // Reset any existing verification data
      _verificationId = null;
      _resendToken = null;
      
      final completer = Completer<Map<String, dynamic>>();
      
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) {
          debugPrint('🔥 Firebase: Phone verification completed automatically');
          // This happens on Android when SMS is auto-retrieved
          // We don't complete here because we want to handle it in verifyOTP
        },
        verificationFailed: (FirebaseAuthException e) {
          debugPrint('🔥 Firebase: Phone verification failed - ${e.message}');
          if (!completer.isCompleted) {
            completer.complete({
              'success': false,
              'message': _getFirebaseErrorMessage(e),
            });
          }
        },
        codeSent: (String verificationId, int? resendToken) {
          debugPrint('🔥 Firebase: OTP code sent. Verification ID: $verificationId');
          _verificationId = verificationId;
          _resendToken = resendToken;
          
          if (!completer.isCompleted) {
            completer.complete({
              'success': true,
              'message': 'OTP sent to your phone number',
              'verificationId': verificationId,
            });
          }
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          debugPrint('🔥 Firebase: Auto-retrieval timeout for verification ID: $verificationId');
          _verificationId = verificationId;
          
          // If we haven't completed yet, it means codeSent wasn't called
          if (!completer.isCompleted) {
            completer.complete({
              'success': false,
              'message': 'Failed to send OTP. Please try again.',
            });
          }
        },
        timeout: const Duration(seconds: 60),
        forceResendingToken: _resendToken,
      );

      return await completer.future;
    } catch (e) {
      debugPrint('🔥 Firebase: Error sending phone OTP - $e');
      return {
        'success': false,
        'message': 'Error sending OTP: ${e.toString()}',
      };
    }
  }

  /// Verify OTP and get Firebase ID token
  static Future<Map<String, dynamic>> verifyPhoneOTP(String otp) async {
    try {
      if (_verificationId == null) {
        return {
          'success': false,
          'message': 'Verification ID not found. Please request OTP again.',
        };
      }

      debugPrint('🔥 Firebase: Verifying OTP - $otp');

      // Create a PhoneAuthCredential with the code
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otp,
      );

      // Sign in the user with the credential
      UserCredential result = await _auth.signInWithCredential(credential);
      
      if (result.user != null) {
        // Get the ID token to send to our backend
        final idToken = await result.user!.getIdToken(false);
        
        debugPrint('🔥 Firebase: Phone verification successful for UID: ${result.user!.uid}');
        
        return {
          'success': true,
          'message': 'Phone verification successful',
          'idToken': idToken,
          'user': {
            'uid': result.user!.uid,
            'phoneNumber': result.user!.phoneNumber ?? '',
          },
        };
      } else {
        return {
          'success': false,
          'message': 'Verification failed. Please try again.',
        };
      }
    } catch (e) {
      debugPrint('🔥 Firebase: Error verifying phone OTP - $e');
      
      String errorMessage = 'Verification failed. Please try again.';
      
      if (e is FirebaseAuthException) {
        errorMessage = _getFirebaseErrorMessage(e);
      }
      
      return {
        'success': false,
        'message': errorMessage,
      };
    }
  }

  /// Resend OTP
  static Future<Map<String, dynamic>> resendPhoneOTP(String phoneNumber) async {
    try {
      debugPrint('🔥 Firebase: Resending OTP to $phoneNumber');
      
      final completer = Completer<Map<String, dynamic>>();
      
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) {
          debugPrint('🔥 Firebase: Phone verification completed automatically (resend)');
        },
        verificationFailed: (FirebaseAuthException e) {
          debugPrint('🔥 Firebase: Phone verification failed (resend) - ${e.message}');
          if (!completer.isCompleted) {
            completer.complete({
              'success': false,
              'message': _getFirebaseErrorMessage(e),
            });
          }
        },
        codeSent: (String verificationId, int? resendToken) {
          debugPrint('🔥 Firebase: OTP code resent. Verification ID: $verificationId');
          _verificationId = verificationId;
          _resendToken = resendToken;
          
          if (!completer.isCompleted) {
            completer.complete({
              'success': true,
              'message': 'OTP resent to your phone number',
              'verificationId': verificationId,
            });
          }
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          debugPrint('🔥 Firebase: Auto-retrieval timeout (resend): $verificationId');
          _verificationId = verificationId;
          
          if (!completer.isCompleted) {
            completer.complete({
              'success': false,
              'message': 'Failed to resend OTP. Please try again.',
            });
          }
        },
        timeout: const Duration(seconds: 60),
        forceResendingToken: _resendToken,
      );

      return await completer.future;
    } catch (e) {
      debugPrint('🔥 Firebase: Error resending phone OTP - $e');
      return {
        'success': false,
        'message': 'Error resending OTP: ${e.toString()}',
      };
    }
  }

  /// Get user-friendly error messages for Firebase Auth exceptions
  static String _getFirebaseErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-phone-number':
        return 'Invalid phone number format. Please check and try again.';
      case 'too-many-requests':
        return 'Too many requests. Please wait and try again later.';
      case 'invalid-verification-code':
        return 'Invalid OTP. Please check and try again.';
      case 'invalid-verification-id':
        return 'Verification session expired. Please request OTP again.';
      case 'session-expired':
        return 'OTP session expired. Please request a new OTP.';
      case 'quota-exceeded':
        return 'SMS quota exceeded. Please try again later.';
      case 'missing-phone-number':
        return 'Phone number is required.';
      case 'credential-already-in-use':
        return 'This phone number is already registered with another account.';
      case 'operation-not-allowed':
        return 'Phone authentication is not enabled. Please contact support.';
      default:
        return e.message ?? 'Authentication failed. Please try again.';
    }
  }

  /// Sign out current user
  static Future<void> signOut() async {
    try {
      await _auth.signOut();
      _verificationId = null;
      _resendToken = null;
      debugPrint('🔥 Firebase: User signed out');
    } catch (e) {
      debugPrint('🔥 Firebase: Error signing out - $e');
    }
  }

  /// Get current Firebase user
  static User? getCurrentUser() {
    return _auth.currentUser;
  }

  /// Check if user is signed in
  static bool isSignedIn() {
    return _auth.currentUser != null;
  }

  /// Clear verification data
  static void clearVerificationData() {
    _verificationId = null;
    _resendToken = null;
  }
}
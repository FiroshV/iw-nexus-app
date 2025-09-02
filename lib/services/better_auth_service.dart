import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class BetterAuthService {
  static const String _baseUrl = 'http://localhost:3000/api/better-auth';
  
  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  static const String _tokenKey = 'better_auth_token';
  static const String _userDataKey = 'better_auth_user';

  // Send Email OTP
  static Future<Map<String, dynamic>> sendEmailOTP(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/sign-in/email-otp'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'email': email,
        }),
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'OTP sent to your email',
          'data': json.decode(response.body),
        };
      } else {
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to send OTP',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Verify Email OTP
  static Future<Map<String, dynamic>> verifyEmailOTP(String email, String otp) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/sign-in/email-otp/verify'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'email': email,
          'otp': otp,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Save session data
        if (data['session'] != null) {
          await _storage.write(key: _tokenKey, value: data['session']['token']);
        }
        if (data['user'] != null) {
          await _storage.write(key: _userDataKey, value: json.encode(data['user']));
        }

        return {
          'success': true,
          'message': 'Login successful',
          'user': data['user'],
          'session': data['session'],
        };
      } else {
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Invalid OTP',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Send Phone OTP
  static Future<Map<String, dynamic>> sendPhoneOTP(String phoneNumber) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/sign-in/phone-otp'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'phoneNumber': phoneNumber,
        }),
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'OTP sent to your phone',
          'data': json.decode(response.body),
        };
      } else {
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to send OTP',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Verify Phone OTP
  static Future<Map<String, dynamic>> verifyPhoneOTP(String phoneNumber, String otp) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/sign-in/phone-otp/verify'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'phoneNumber': phoneNumber,
          'otp': otp,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Save session data
        if (data['session'] != null) {
          await _storage.write(key: _tokenKey, value: data['session']['token']);
        }
        if (data['user'] != null) {
          await _storage.write(key: _userDataKey, value: json.encode(data['user']));
        }

        return {
          'success': true,
          'message': 'Login successful',
          'user': data['user'],
          'session': data['session'],
        };
      } else {
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Invalid OTP',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Get current session
  static Future<Map<String, dynamic>?> getCurrentSession() async {
    try {
      final token = await _storage.read(key: _tokenKey);
      if (token == null) return null;

      final response = await http.get(
        Uri.parse('$_baseUrl/session'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }

  // Sign out
  static Future<bool> signOut() async {
    try {
      final token = await _storage.read(key: _tokenKey);
      
      if (token != null) {
        // Call server logout endpoint
        await http.post(
          Uri.parse('$_baseUrl/sign-out'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );
      }

      // Clear local storage
      await _storage.delete(key: _tokenKey);
      await _storage.delete(key: _userDataKey);
      
      return true;
    } catch (e) {
      // Still clear local storage even if server request fails
      await _storage.delete(key: _tokenKey);
      await _storage.delete(key: _userDataKey);
      return true;
    }
  }

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    try {
      final token = await _storage.read(key: _tokenKey);
      if (token == null) return false;

      // Validate token with server
      final session = await getCurrentSession();
      return session != null;
    } catch (e) {
      return false;
    }
  }

  // Get cached user data
  static Future<Map<String, dynamic>?> getUserData() async {
    try {
      final userDataString = await _storage.read(key: _userDataKey);
      if (userDataString == null) return null;
      
      return json.decode(userDataString);
    } catch (e) {
      return null;
    }
  }

  // Get auth token
  static Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }
}
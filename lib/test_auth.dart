import 'dart:developer';
import 'services/api_service.dart';

/// Test script for authentication token management
/// This can be called from main.dart to test token persistence
Future<void> testAuthPersistence() async {
  log('🔒 Starting authentication persistence test');

  try {
    // Test 1: Save a mock token with expiry
    log('Test 1: Saving mock token with expiry');
    final testToken = 'test_token_12345';
    final testRefreshToken = 'refresh_token_12345';
    final expiresAt = DateTime.now().add(const Duration(hours: 1));
    
    await ApiService.saveToken(
      testToken,
      refreshToken: testRefreshToken,
      expiresAt: expiresAt,
    );
    log('✅ Token saved successfully');

    // Test 2: Retrieve the token
    log('Test 2: Retrieving saved token');
    final retrievedToken = await ApiService.getToken();
    final retrievedRefreshToken = await ApiService.getRefreshToken();
    
    if (retrievedToken == testToken) {
      log('✅ Token retrieved successfully: $retrievedToken');
    } else {
      log('❌ Token mismatch. Expected: $testToken, Got: $retrievedToken');
    }
    
    if (retrievedRefreshToken == testRefreshToken) {
      log('✅ Refresh token retrieved successfully: $retrievedRefreshToken');
    } else {
      log('❌ Refresh token mismatch. Expected: $testRefreshToken, Got: $retrievedRefreshToken');
    }

    // Test 3: Check session validity
    log('Test 3: Checking session validity');
    final hasValidSession = await ApiService.hasValidSession();
    log('Session validity: $hasValidSession');

    // Test 4: Save mock user data
    log('Test 4: Saving mock user data');
    final mockUserData = {
      'id': 'user123',
      'firstName': 'Test',
      'lastName': 'User',
      'email': 'test@example.com',
      'phoneNumber': '+1234567890',
    };
    
    await ApiService.saveUserData(mockUserData);
    log('✅ User data saved successfully');

    // Test 5: Retrieve user data
    log('Test 5: Retrieving user data');
    final retrievedUserData = await ApiService.getUserData();
    if (retrievedUserData != null && retrievedUserData['id'] == mockUserData['id']) {
      log('✅ User data retrieved successfully: ${retrievedUserData['firstName']} ${retrievedUserData['lastName']}');
    } else {
      log('❌ User data retrieval failed');
    }

    // Test 6: Clear all data
    log('Test 6: Clearing all auth data');
    await ApiService.clearAllAuthData();
    
    final tokenAfterClear = await ApiService.getToken();
    final userDataAfterClear = await ApiService.getUserData();
    
    if (tokenAfterClear == null && userDataAfterClear == null) {
      log('✅ All auth data cleared successfully');
    } else {
      log('❌ Auth data not cleared properly');
    }

    log('🔒 Authentication persistence test completed successfully');
  } catch (e) {
    log('❌ Authentication test failed: $e');
  }
}
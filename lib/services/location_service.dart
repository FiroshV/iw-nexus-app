import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  Position? _lastKnownPosition;
  DateTime? _lastPositionUpdate;

  // Location settings for high accuracy
  static const LocationSettings _locationSettings = LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 10, // Only update if moved 10 meters
    timeLimit: Duration(seconds: 30), // Timeout after 30 seconds
  );

  /// Check if location permissions are granted
  Future<bool> hasLocationPermission() async {
    try {
      final permission = await Permission.location.status;
      return permission == PermissionStatus.granted;
    } catch (e) {
      debugPrint('❌ Error checking location permission: $e');
      return false;
    }
  }

  /// Request location permissions from user
  Future<LocationPermissionResult> requestLocationPermission() async {
    try {
      debugPrint('🌍 Checking location services...');
      
      // Platform-specific permission handling
      if (Platform.isIOS || Platform.isAndroid) {
        // Check if location services are enabled on the device
        bool serviceEnabled;
        try {
          serviceEnabled = await Geolocator.isLocationServiceEnabled();
        } catch (e) {
          debugPrint('❌ Error checking location services: $e');
          // Fallback: assume services are enabled and let permission check handle it
          serviceEnabled = true;
        }
        
        if (!serviceEnabled) {
          debugPrint('❌ Location services are disabled');
          return LocationPermissionResult(
            granted: false,
            message: 'Location services are disabled. Please enable location services in your device settings.',
            canOpenSettings: true,
          );
        }

        // Check current permission status
        LocationPermission permission;
        try {
          permission = await Geolocator.checkPermission();
          debugPrint('🔍 Current location permission: $permission');
        } catch (e) {
          debugPrint('❌ Error checking location permission: $e');
          // Try using permission_handler as fallback
          return await _requestLocationPermissionFallback();
        }

        // Handle different permission states
        if (permission == LocationPermission.denied) {
          debugPrint('📱 Requesting location permission...');
          try {
            permission = await Geolocator.requestPermission();
          } catch (e) {
            debugPrint('❌ Error requesting permission via Geolocator: $e');
            return await _requestLocationPermissionFallback();
          }
          
          if (permission == LocationPermission.denied) {
            debugPrint('❌ Location permissions are denied');
            return LocationPermissionResult(
              granted: false,
              message: 'Location permissions are denied. Please grant location access to use attendance features.',
              canOpenSettings: false,
            );
          }
        }
        
        if (permission == LocationPermission.deniedForever) {
          debugPrint('❌ Location permissions are permanently denied');
          return LocationPermissionResult(
            granted: false,
            message: 'Location permissions are permanently denied. Please enable location access in app settings.',
            canOpenSettings: true,
          );
        }

        debugPrint('✅ Location permission granted');
        return LocationPermissionResult(
          granted: true,
          message: 'Location access granted',
          canOpenSettings: false,
        );
      } else {
        // Web or other platforms
        debugPrint('✅ Web/desktop platform - assuming location access');
        return LocationPermissionResult(
          granted: true,
          message: 'Location access available',
          canOpenSettings: false,
        );
      }

    } catch (e) {
      debugPrint('❌ Error requesting location permission: $e');
      // Try fallback method
      return await _requestLocationPermissionFallback();
    }
  }

  /// Fallback permission request using permission_handler
  Future<LocationPermissionResult> _requestLocationPermissionFallback() async {
    try {
      debugPrint('🔄 Using fallback permission method...');
      
      final permission = await Permission.location.status;
      debugPrint('🔍 Permission status (fallback): $permission');
      
      if (permission.isDenied) {
        debugPrint('📱 Requesting permission (fallback)...');
        final result = await Permission.location.request();
        
        if (result.isGranted) {
          debugPrint('✅ Location permission granted (fallback)');
          return LocationPermissionResult(
            granted: true,
            message: 'Location access granted',
            canOpenSettings: false,
          );
        } else if (result.isPermanentlyDenied) {
          debugPrint('❌ Location permissions permanently denied (fallback)');
          return LocationPermissionResult(
            granted: false,
            message: 'Location permissions are permanently denied. Please enable location access in app settings.',
            canOpenSettings: true,
          );
        } else {
          debugPrint('❌ Location permissions denied (fallback)');
          return LocationPermissionResult(
            granted: false,
            message: 'Location permissions are denied. Please grant location access to use attendance features.',
            canOpenSettings: false,
          );
        }
      } else if (permission.isGranted) {
        debugPrint('✅ Location permission already granted (fallback)');
        return LocationPermissionResult(
          granted: true,
          message: 'Location access granted',
          canOpenSettings: false,
        );
      } else if (permission.isPermanentlyDenied) {
        debugPrint('❌ Location permissions permanently denied (fallback)');
        return LocationPermissionResult(
          granted: false,
          message: 'Location permissions are permanently denied. Please enable location access in app settings.',
          canOpenSettings: true,
        );
      } else {
        debugPrint('❌ Location permissions in unknown state (fallback)');
        return LocationPermissionResult(
          granted: false,
          message: 'Unable to determine location permission status.',
          canOpenSettings: true,
        );
      }
    } catch (e) {
      debugPrint('❌ Fallback permission request failed: $e');
      return LocationPermissionResult(
        granted: false,
        message: 'Failed to request location permission: ${e.toString()}',
        canOpenSettings: false,
      );
    }
  }

  /// Get current position with error handling
  Future<LocationResult> getCurrentPosition() async {
    try {
      debugPrint('📍 Getting current location...');
      
      // Check permissions first
      final permissionResult = await requestLocationPermission();
      if (!permissionResult.granted) {
        return LocationResult(
          success: false,
          message: permissionResult.message,
          canOpenSettings: permissionResult.canOpenSettings,
        );
      }

      // Get current position with platform-specific handling
      Position position;
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        ).timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            throw TimeoutException('Location request timed out', const Duration(seconds: 30));
          },
        );
      } catch (e) {
        debugPrint('❌ Error getting current position: $e');
        
        // Try to get last known position as fallback
        try {
          position = await Geolocator.getLastKnownPosition() ?? 
            (throw Exception('No last known position available'));
          debugPrint('🔄 Using last known position as fallback');
        } catch (e2) {
          debugPrint('❌ Could not get last known position: $e2');
          rethrow;
        }
      }

      _lastKnownPosition = position;
      _lastPositionUpdate = DateTime.now();

      debugPrint('✅ Location obtained: ${position.latitude}, ${position.longitude}');
      debugPrint('📊 Accuracy: ${position.accuracy}m, Altitude: ${position.altitude}m');
      
      return LocationResult(
        success: true,
        message: 'Location obtained successfully',
        position: position,
        accuracy: position.accuracy,
      );

    } on LocationServiceDisabledException {
      debugPrint('❌ Location services are disabled');
      return LocationResult(
        success: false,
        message: 'Location services are disabled. Please enable GPS.',
        canOpenSettings: true,
      );
    } on PermissionDeniedException {
      debugPrint('❌ Location permissions denied');
      return LocationResult(
        success: false,
        message: 'Location permission denied. Please enable location access.',
        canOpenSettings: true,
      );
    } on TimeoutException catch (e) {
      debugPrint('⏰ Location request timed out: ${e.message}');
      
      // Try to return last known position if available
      if (_lastKnownPosition != null && _isRecentPosition()) {
        debugPrint('🔄 Using last known position');
        return LocationResult(
          success: true,
          message: 'Using recent location (GPS timeout)',
          position: _lastKnownPosition!,
          accuracy: _lastKnownPosition!.accuracy,
          isFromCache: true,
        );
      }
      
      return LocationResult(
        success: false,
        message: 'Location request timed out. Please try again.',
      );
    } catch (e) {
      debugPrint('❌ Error getting location: $e');
      
      // Try to return last known position as fallback
      if (_lastKnownPosition != null && _isRecentPosition()) {
        debugPrint('🔄 Using last known position as fallback');
        return LocationResult(
          success: true,
          message: 'Using recent location (error fallback)',
          position: _lastKnownPosition!,
          accuracy: _lastKnownPosition!.accuracy,
          isFromCache: true,
        );
      }
      
      return LocationResult(
        success: false,
        message: 'Failed to get location: ${e.toString()}',
      );
    }
  }

  /// Check if last known position is recent (within 5 minutes)
  bool _isRecentPosition() {
    if (_lastPositionUpdate == null) return false;
    final now = DateTime.now();
    final difference = now.difference(_lastPositionUpdate!);
    return difference.inMinutes <= 5;
  }

  /// Open device location settings
  Future<void> openLocationSettings() async {
    try {
      await Geolocator.openLocationSettings();
    } catch (e) {
      debugPrint('❌ Failed to open location settings: $e');
      // Fallback to app settings
      await openAppSettings();
    }
  }

  /// Open app settings
  Future<void> openAppSettings() async {
    try {
      await Geolocator.openAppSettings();
    } catch (e) {
      debugPrint('❌ Failed to open app settings: $e');
    }
  }

  /// Get last known position (cached)
  Position? getLastKnownPosition() {
    return _lastKnownPosition;
  }

  /// Clear cached position
  void clearCache() {
    _lastKnownPosition = null;
    _lastPositionUpdate = null;
  }

  /// Calculate distance between two positions in meters
  double calculateDistance(Position start, Position end) {
    return Geolocator.distanceBetween(
      start.latitude,
      start.longitude,
      end.latitude,
      end.longitude,
    );
  }

  /// Convert position to map for API calls
  Map<String, dynamic> positionToMap(Position position) {
    return {
      'latitude': position.latitude,
      'longitude': position.longitude,
      'accuracy': position.accuracy,
      'altitude': position.altitude,
      'heading': position.heading,
      'speed': position.speed,
      'speedAccuracy': position.speedAccuracy,
      'timestamp': position.timestamp?.millisecondsSinceEpoch,
    };
  }

  /// Check if position has good accuracy (less than 50 meters)
  bool hasGoodAccuracy(Position position) {
    return position.accuracy <= 50.0;
  }

  /// Get location accuracy description
  String getAccuracyDescription(double accuracy) {
    if (accuracy <= 10) {
      return 'Excellent (±${accuracy.toStringAsFixed(1)}m)';
    } else if (accuracy <= 25) {
      return 'Good (±${accuracy.toStringAsFixed(1)}m)';
    } else if (accuracy <= 50) {
      return 'Fair (±${accuracy.toStringAsFixed(1)}m)';
    } else {
      return 'Poor (±${accuracy.toStringAsFixed(1)}m)';
    }
  }
}

/// Result class for location operations
class LocationResult {
  final bool success;
  final String message;
  final Position? position;
  final double? accuracy;
  final bool canOpenSettings;
  final bool isFromCache;

  LocationResult({
    required this.success,
    required this.message,
    this.position,
    this.accuracy,
    this.canOpenSettings = false,
    this.isFromCache = false,
  });

  @override
  String toString() {
    return 'LocationResult{success: $success, message: $message, position: $position}';
  }
}

/// Result class for permission requests
class LocationPermissionResult {
  final bool granted;
  final String message;
  final bool canOpenSettings;

  LocationPermissionResult({
    required this.granted,
    required this.message,
    required this.canOpenSettings,
  });

  @override
  String toString() {
    return 'LocationPermissionResult{granted: $granted, message: $message}';
  }
}
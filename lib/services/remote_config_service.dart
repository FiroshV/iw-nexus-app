import 'package:flutter/foundation.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';

/// Service for managing Firebase Remote Config
class RemoteConfigService {
  static FirebaseRemoteConfig? _remoteConfig;
  static bool _initialized = false;

  // Remote config parameter keys
  static const String _backendApiUrlKey = 'backend_api_url';
  static const String _latestVersionAndroidKey = 'latest_app_version_android';
  static const String _latestVersionIosKey = 'latest_app_version_ios';
  static const String _androidDownloadUrlKey = 'android_download_url';
  static const String _iosDownloadUrlKey = 'ios_download_url';
  static const String _forceUpdateRequiredKey = 'force_update_required';
  static const String _enableVersionCheckKey = 'enable_version_check';

  // Default values (fallbacks when remote config fails)
  static const Map<String, dynamic> _defaults = {
    _backendApiUrlKey: 'http://localhost:3000/api', // Default to development URL
    _latestVersionAndroidKey: '1.0.0',
    _latestVersionIosKey: '1.0.0',
    _androidDownloadUrlKey: 'https://play.google.com/store/apps/details?id=com.iwn.iwNexus',
    _iosDownloadUrlKey: 'https://apps.apple.com/app/iw-nexus/id123456789',
    _forceUpdateRequiredKey: false,
    _enableVersionCheckKey: true,
  };

  /// Initialize Firebase Remote Config
  static Future<bool> initialize() async {
    try {
      if (_initialized && _remoteConfig != null) {
        return true;
      }

      _remoteConfig = FirebaseRemoteConfig.instance;

      // Configure settings
      await _remoteConfig!.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          minimumFetchInterval: kDebugMode
              ? const Duration(minutes: 1) // Shorter interval for development
              : const Duration(hours: 1),   // Longer interval for production
        ),
      );

      // Set default values
      await _remoteConfig!.setDefaults(_defaults);

      // Fetch and activate
      await fetchAndActivate();

      _initialized = true;
      debugPrint('🔧 RemoteConfigService: Initialized successfully');

      return true;
    } catch (e) {
      debugPrint('❌ RemoteConfigService: Initialization failed: $e');
      return false;
    }
  }

  /// Fetch and activate remote config values
  static Future<bool> fetchAndActivate() async {
    try {
      if (_remoteConfig == null) {
        await initialize();
      }

      final bool fetched = await _remoteConfig!.fetchAndActivate();

      if (fetched) {
        debugPrint('🔄 RemoteConfigService: New config values fetched and activated');
      } else {
        debugPrint('🔄 RemoteConfigService: Using cached config values');
      }

      return true;
    } catch (e) {
      debugPrint('❌ RemoteConfigService: Fetch failed: $e');
      return false;
    }
  }

  /// Get backend API URL
  static String getBackendApiUrl() {
    try {
      if (_remoteConfig == null) {
        return _defaults[_backendApiUrlKey] as String;
      }
      final url = _remoteConfig!.getString(_backendApiUrlKey);
      debugPrint('🌐 RemoteConfigService: Backend API URL: $url');
      return url.isNotEmpty ? url : _defaults[_backendApiUrlKey] as String;
    } catch (e) {
      debugPrint('❌ RemoteConfigService: Error getting backend API URL: $e');
      return _defaults[_backendApiUrlKey] as String;
    }
  }

  /// Get latest app version for Android
  static String getLatestVersionAndroid() {
    try {
      if (_remoteConfig == null) {
        return _defaults[_latestVersionAndroidKey] as String;
      }
      final version = _remoteConfig!.getString(_latestVersionAndroidKey);
      debugPrint('📱 RemoteConfigService: Latest Android version: $version');
      return version.isNotEmpty ? version : _defaults[_latestVersionAndroidKey] as String;
    } catch (e) {
      debugPrint('❌ RemoteConfigService: Error getting latest Android version: $e');
      return _defaults[_latestVersionAndroidKey] as String;
    }
  }

  /// Get latest app version for iOS
  static String getLatestVersionIos() {
    try {
      if (_remoteConfig == null) {
        return _defaults[_latestVersionIosKey] as String;
      }
      final version = _remoteConfig!.getString(_latestVersionIosKey);
      debugPrint('🍎 RemoteConfigService: Latest iOS version: $version');
      return version.isNotEmpty ? version : _defaults[_latestVersionIosKey] as String;
    } catch (e) {
      debugPrint('❌ RemoteConfigService: Error getting latest iOS version: $e');
      return _defaults[_latestVersionIosKey] as String;
    }
  }

  /// Get Android download URL
  static String getAndroidDownloadUrl() {
    try {
      if (_remoteConfig == null) {
        return _defaults[_androidDownloadUrlKey] as String;
      }
      final url = _remoteConfig!.getString(_androidDownloadUrlKey);
      return url.isNotEmpty ? url : _defaults[_androidDownloadUrlKey] as String;
    } catch (e) {
      debugPrint('❌ RemoteConfigService: Error getting Android download URL: $e');
      return _defaults[_androidDownloadUrlKey] as String;
    }
  }

  /// Get iOS download URL
  static String getIosDownloadUrl() {
    try {
      if (_remoteConfig == null) {
        return _defaults[_iosDownloadUrlKey] as String;
      }
      final url = _remoteConfig!.getString(_iosDownloadUrlKey);
      return url.isNotEmpty ? url : _defaults[_iosDownloadUrlKey] as String;
    } catch (e) {
      debugPrint('❌ RemoteConfigService: Error getting iOS download URL: $e');
      return _defaults[_iosDownloadUrlKey] as String;
    }
  }

  /// Check if force update is required
  static bool isForceUpdateRequired() {
    try {
      if (_remoteConfig == null) {
        return _defaults[_forceUpdateRequiredKey] as bool;
      }
      final forceUpdate = _remoteConfig!.getBool(_forceUpdateRequiredKey);
      debugPrint('⚠️ RemoteConfigService: Force update required: $forceUpdate');
      return forceUpdate;
    } catch (e) {
      debugPrint('❌ RemoteConfigService: Error checking force update: $e');
      return _defaults[_forceUpdateRequiredKey] as bool;
    }
  }

  /// Check if version checking is enabled
  static bool isVersionCheckEnabled() {
    try {
      if (_remoteConfig == null) {
        return _defaults[_enableVersionCheckKey] as bool;
      }
      final enabled = _remoteConfig!.getBool(_enableVersionCheckKey);
      debugPrint('✅ RemoteConfigService: Version check enabled: $enabled');
      return enabled;
    } catch (e) {
      debugPrint('❌ RemoteConfigService: Error checking version check enabled: $e');
      return _defaults[_enableVersionCheckKey] as bool;
    }
  }

  /// Get all config values for debugging
  static Map<String, dynamic> getAllConfigValues() {
    try {
      if (_remoteConfig == null) {
        return Map<String, dynamic>.from(_defaults);
      }

      return {
        'backend_api_url': getBackendApiUrl(),
        'latest_version_android': getLatestVersionAndroid(),
        'latest_version_ios': getLatestVersionIos(),
        'android_download_url': getAndroidDownloadUrl(),
        'ios_download_url': getIosDownloadUrl(),
        'force_update_required': isForceUpdateRequired(),
        'enable_version_check': isVersionCheckEnabled(),
        'last_fetch_time': _remoteConfig!.lastFetchTime.toIso8601String(),
        'last_fetch_status': _remoteConfig!.lastFetchStatus.toString(),
      };
    } catch (e) {
      debugPrint('❌ RemoteConfigService: Error getting all config values: $e');
      return Map<String, dynamic>.from(_defaults);
    }
  }

  /// Force refresh config (useful for testing)
  static Future<bool> forceRefresh() async {
    try {
      if (_remoteConfig == null) {
        await initialize();
      }

      await _remoteConfig!.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          minimumFetchInterval: Duration.zero, // Force immediate fetch
        ),
      );

      final success = await fetchAndActivate();

      // Reset to normal fetch interval
      await _remoteConfig!.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          minimumFetchInterval: kDebugMode
              ? const Duration(minutes: 1)
              : const Duration(hours: 1),
        ),
      );

      return success;
    } catch (e) {
      debugPrint('❌ RemoteConfigService: Force refresh failed: $e');
      return false;
    }
  }

  /// Check if remote config is available and initialized
  static bool get isAvailable => _initialized && _remoteConfig != null;

  /// Get the underlying FirebaseRemoteConfig instance (for advanced usage)
  static FirebaseRemoteConfig? get instance => _remoteConfig;
}
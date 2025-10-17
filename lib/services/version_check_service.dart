import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'remote_config_service.dart';

/// Result of version check
class VersionCheckResult {
  final bool updateAvailable;
  final bool forceUpdate;
  final String currentVersion;
  final String latestVersion;
  final String downloadUrl;
  final String platform;

  VersionCheckResult({
    required this.updateAvailable,
    required this.forceUpdate,
    required this.currentVersion,
    required this.latestVersion,
    required this.downloadUrl,
    required this.platform,
  });

  @override
  String toString() {
    return 'VersionCheckResult(updateAvailable: $updateAvailable, forceUpdate: $forceUpdate, '
        'currentVersion: $currentVersion, latestVersion: $latestVersion, '
        'platform: $platform, downloadUrl: $downloadUrl)';
  }
}

/// Service for checking app version updates
class VersionCheckService {
  static PackageInfo? _packageInfo;
  static bool _initialized = false;

  /// Initialize the service by loading package info
  static Future<bool> initialize() async {
    try {
      if (_initialized && _packageInfo != null) {
        return true;
      }

      _packageInfo = await PackageInfo.fromPlatform();
      _initialized = true;

      debugPrint('📱 VersionCheckService: Initialized successfully');
      debugPrint('📱 App Name: ${_packageInfo!.appName}');
      debugPrint('📱 Package Name: ${_packageInfo!.packageName}');
      debugPrint('📱 Current Version: ${_packageInfo!.version}');
      debugPrint('📱 Build Number: ${_packageInfo!.buildNumber}');

      return true;
    } catch (e) {
      debugPrint('❌ VersionCheckService: Initialization failed: $e');
      return false;
    }
  }

  /// Get current app version
  static String getCurrentVersion() {
      return dotenv.maybeGet('APP_VERSION') ?? '1.0.0';
  }

  /// Get current app build number
  static String getCurrentBuildNumber() {
    if (_packageInfo == null) {
      debugPrint('⚠️ VersionCheckService: Package info not initialized, returning fallback build number');
      return '1';
    }
    return _packageInfo!.buildNumber;
  }

  /// Get app package name
  static String getPackageName() {
    if (_packageInfo == null) {
      debugPrint('⚠️ VersionCheckService: Package info not initialized, returning fallback package name');
      return 'com.iwn.iwNexus';
    }
    return _packageInfo!.packageName;
  }

  /// Get current platform string
  static String getCurrentPlatform() {
    if (kIsWeb) return 'web';
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    if (Platform.isMacOS) return 'macos';
    if (Platform.isWindows) return 'windows';
    if (Platform.isLinux) return 'linux';
    return 'unknown';
  }

  /// Check for app updates
  static Future<VersionCheckResult> checkForUpdate() async {
    try {
      // Ensure both services are initialized
      if (!_initialized) {
        await initialize();
      }

      if (!RemoteConfigService.isAvailable) {
        await RemoteConfigService.initialize();
      }

      // Check if version checking is enabled
      if (!RemoteConfigService.isVersionCheckEnabled()) {
        debugPrint('⏭️ VersionCheckService: Version checking is disabled via remote config');
        return _createNoUpdateResult();
      }

      final currentVersion = getCurrentVersion();
      final platform = getCurrentPlatform();

      String latestVersion;
      String downloadUrl;

      // Get platform-specific version and download URL
      if (platform == 'android') {
        latestVersion = RemoteConfigService.getLatestVersionAndroid();
        downloadUrl = RemoteConfigService.getAndroidDownloadUrl();
      } else if (platform == 'ios') {
        latestVersion = RemoteConfigService.getLatestVersionIos();
        downloadUrl = RemoteConfigService.getIosDownloadUrl();
      } else {
        debugPrint('⚠️ VersionCheckService: Unsupported platform for version check: $platform');
        return _createNoUpdateResult();
      }

      // Compare versions
      final updateAvailable = _isUpdateAvailable(currentVersion, latestVersion);
      final forceUpdate = RemoteConfigService.isForceUpdateRequired();

      final result = VersionCheckResult(
        updateAvailable: updateAvailable,
        forceUpdate: forceUpdate && updateAvailable,
        currentVersion: currentVersion,
        latestVersion: latestVersion,
        downloadUrl: downloadUrl,
        platform: platform,
      );

      debugPrint('🔍 VersionCheckResult: $result');

      return result;
    } catch (e) {
      debugPrint('❌ VersionCheckService: Error checking for update: $e');
      return _createNoUpdateResult();
    }
  }

  /// Create a no-update-available result
  static VersionCheckResult _createNoUpdateResult() {
    return VersionCheckResult(
      updateAvailable: false,
      forceUpdate: false,
      currentVersion: getCurrentVersion(),
      latestVersion: getCurrentVersion(),
      downloadUrl: '',
      platform: getCurrentPlatform(),
    );
  }

  /// Compare version strings to determine if update is available
  /// Returns true if remote version is newer than current version
  static bool _isUpdateAvailable(String currentVersion, String latestVersion) {
    try {
      // Parse version strings (e.g., "1.2.3" -> [1, 2, 3])
      final current = _parseVersion(currentVersion);
      final latest = _parseVersion(latestVersion);

      // Compare version components
      for (int i = 0; i < 3; i++) {
        if (latest[i] > current[i]) {
          return true; // Remote version is newer
        } else if (latest[i] < current[i]) {
          return false; // Current version is newer
        }
      }

      return false; // Versions are equal
    } catch (e) {
      debugPrint('❌ VersionCheckService: Error comparing versions: $e');
      return false;
    }
  }

  /// Parse version string into numeric components
  /// E.g., "1.2.3" -> [1, 2, 3]
  static List<int> _parseVersion(String version) {
    try {
      final parts = version.split('.');
      final parsed = <int>[];

      // Ensure we have at least 3 components (major.minor.patch)
      for (int i = 0; i < 3; i++) {
        if (i < parts.length) {
          // Extract numeric part only (handle cases like "1.2.3-beta")
          final numericPart = parts[i].replaceAll(RegExp(r'[^0-9]'), '');
          parsed.add(int.tryParse(numericPart) ?? 0);
        } else {
          parsed.add(0);
        }
      }

      return parsed;
    } catch (e) {
      debugPrint('❌ VersionCheckService: Error parsing version "$version": $e');
      return [0, 0, 0];
    }
  }

  /// Launch store to download update
  static Future<bool> launchStore(String downloadUrl) async {
    try {
      final uri = Uri.parse(downloadUrl);

      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        debugPrint('✅ VersionCheckService: Launched store successfully');
        return true;
      } else {
        debugPrint('❌ VersionCheckService: Cannot launch URL: $downloadUrl');
        return false;
      }
    } catch (e) {
      debugPrint('❌ VersionCheckService: Error launching store: $e');
      return false;
    }
  }

  /// Get app information for debugging
  static Map<String, dynamic> getAppInfo() {
    return {
      'app_name': _packageInfo?.appName ?? 'Unknown',
      'package_name': getPackageName(),
      'current_version': getCurrentVersion(),
      'build_number': getCurrentBuildNumber(),
      'platform': getCurrentPlatform(),
      'initialized': _initialized,
    };
  }

  /// Check if service is available and initialized
  static bool get isAvailable => _initialized && _packageInfo != null;
}
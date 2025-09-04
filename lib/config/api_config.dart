import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Configuration class for API settings and environment management
class ApiConfig {
  // Environment detection
  static bool get isDevelopment => kDebugMode;
  static bool get isProduction => kReleaseMode;
  static bool get isStaging => kProfileMode;

  // Base URLs - can be overridden by environment variables
  static const String _developmentUrl = 'http://localhost:3000/api';
  static const String _stagingUrl = 'https://staging-api.iwnexus.com/api';
  static const String _productionUrl = 'https://api.iwnexus.com/api';

  /// Get the current base URL based on environment
  static String get baseUrl {
    // Try to get from environment variables first
    final envUrl = dotenv.maybeGet('API_BASE_URL');
    if (envUrl != null && envUrl.isNotEmpty) {
      return envUrl;
    }

    // Fallback to hardcoded URLs based on build mode
    if (isProduction) {
      return _productionUrl;
    } else if (isStaging) {
      return _stagingUrl;
    } else {
      return _developmentUrl;
    }
  }

  // HTTP Client Configuration
  static const Duration defaultTimeout = Duration(seconds: 30);
  static const Duration shortTimeout = Duration(seconds: 10);
  static const Duration longTimeout = Duration(seconds: 60);
  
  static const int defaultMaxRetries = 3;
  static const int healthCheckMaxRetries = 1;
  static const int validationMaxRetries = 1;

  // Token and session configuration
  static const Duration tokenExpiryBuffer = Duration(minutes: 30);
  static const Duration defaultTokenExpiry = Duration(days: 30);

  // Secure storage keys
  static const String tokenKey = 'session_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String tokenExpiryKey = 'token_expiry';
  static const String userDataKey = 'user_data';
  static const String lastLoginKey = 'last_login_time';

  // HTTP Headers
  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  /// Get app-specific headers including version info
  static Map<String, String> get appHeaders {
    return {
      ...defaultHeaders,
      'User-Agent': 'IWNexus-Mobile/${_getAppVersion()}',
      'X-App-Platform': _getPlatform(),
      'X-App-Environment': _getEnvironment(),
    };
  }

  // Debug configuration
  static bool get enableAuthDebugLogging => isDevelopment;
  static bool get enableNetworkLogging => isDevelopment;
  
  // Timezone configuration for India
  static const String appTimezone = 'Asia/Kolkata';
  static const String timezoneDisplayName = 'IST';
  static const Duration istOffset = Duration(hours: 5, minutes: 30);

  // Pagination defaults
  static const int defaultPageSize = 20;
  static const int defaultUsersPageSize = 20;
  static const int defaultAttendanceHistorySize = 30;
  static const int maxManagersLimit = 100;

  // Private helper methods
  static String _getAppVersion() {
    // You might want to get this from package_info_plus package
    return '1.0.0';
  }

  static String _getPlatform() {
    if (kIsWeb) return 'web';
    if (defaultTargetPlatform == TargetPlatform.android) return 'android';
    if (defaultTargetPlatform == TargetPlatform.iOS) return 'ios';
    if (defaultTargetPlatform == TargetPlatform.macOS) return 'macos';
    if (defaultTargetPlatform == TargetPlatform.windows) return 'windows';
    if (defaultTargetPlatform == TargetPlatform.linux) return 'linux';
    return 'unknown';
  }

  static String _getEnvironment() {
    if (isProduction) return 'production';
    if (isStaging) return 'staging';
    return 'development';
  }

  /// Initialize configuration - call this in main.dart
  static Future<void> initialize() async {
    try {
      await dotenv.load(fileName: ".env");
    } catch (e) {
      // .env file not found or error loading it - continue with defaults
      if (kDebugMode) {
        print('Warning: Could not load .env file: $e');
      }
    }
  }
}

/// Environment-specific configurations
class EnvironmentConfig {
  final String name;
  final String baseUrl;
  final bool enableLogging;
  final Duration timeout;

  const EnvironmentConfig({
    required this.name,
    required this.baseUrl,
    required this.enableLogging,
    required this.timeout,
  });

  static const EnvironmentConfig development = EnvironmentConfig(
    name: 'development',
    baseUrl: 'http://localhost:3000/api',
    enableLogging: true,
    timeout: Duration(seconds: 30),
  );

  static const EnvironmentConfig staging = EnvironmentConfig(
    name: 'staging',
    baseUrl: 'https://staging-api.iwnexus.com/api',
    enableLogging: true,
    timeout: Duration(seconds: 30),
  );

  static const EnvironmentConfig production = EnvironmentConfig(
    name: 'production',
    baseUrl: 'https://api.iwnexus.com/api',
    enableLogging: false,
    timeout: Duration(seconds: 30),
  );

  static EnvironmentConfig get current {
    if (ApiConfig.isProduction) return production;
    if (ApiConfig.isStaging) return staging;
    return development;
  }
}
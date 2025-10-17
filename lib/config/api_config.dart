import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../services/remote_config_service.dart';

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
    // Check if Remote Config should be used based on .env setting
    final useRemoteConfig = _shouldUseRemoteConfig();

    if (useRemoteConfig) {
      // REMOTE CONFIG MODE: Remote Config first, then fallbacks
      debugPrint('🔧 ApiConfig: Remote Config mode - checking Firebase first');

      // First priority: Firebase Remote Config
      if (RemoteConfigService.isAvailable) {
        final remoteUrl = RemoteConfigService.getBackendApiUrl();
        if (remoteUrl.isNotEmpty) {
          debugPrint('🔧 ApiConfig: Using Remote Config API URL: $remoteUrl');
          return remoteUrl;
        }
      }

      debugPrint('⚠️ ApiConfig: Remote Config not available, falling back to .env');
    } else {
      // LOCAL CONFIG MODE: .env first, skip Remote Config
      debugPrint('🔧 ApiConfig: Local config mode - using .env and fallbacks only');
    }

    // Environment variables (.env file)
    final envUrl = dotenv.maybeGet('API_BASE_URL');
    if (envUrl != null && envUrl.isNotEmpty) {
      debugPrint('🔧 ApiConfig: Using .env API URL: $envUrl');
      return envUrl;
    }

    // Fallback to hardcoded URLs based on build mode
    String fallbackUrl;
    if (isProduction) {
      fallbackUrl = _productionUrl;
    } else if (isStaging) {
      fallbackUrl = _stagingUrl;
    } else {
      fallbackUrl = _developmentUrl;
    }

    debugPrint('🔧 ApiConfig: Using fallback URL: $fallbackUrl');
    return fallbackUrl;
  }

  /// Check if Remote Config should be used based on .env setting
  static bool _shouldUseRemoteConfig() {
    final useRemoteConfig = dotenv.maybeGet('USE_REMOTE_CONFIG')?.toLowerCase();
    return useRemoteConfig == 'true' || useRemoteConfig == '1';
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
      'User-Agent': 'IWNexus-Phone/${_getAppVersion()}',
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
    return dotenv.maybeGet('APP_VERSION') ?? '1.0.0';
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

  /// Force refresh configuration (useful when Remote Config values change)
  static Future<void> refreshConfiguration() async {
    try {
      if (RemoteConfigService.isAvailable) {
        await RemoteConfigService.fetchAndActivate();
        debugPrint('🔄 ApiConfig: Configuration refreshed from Remote Config');
      }
    } catch (e) {
      debugPrint('❌ ApiConfig: Failed to refresh configuration: $e');
    }
  }

  /// Get current configuration info for debugging
  static Map<String, dynamic> getConfigInfo() {
    return {
      'current_base_url': baseUrl,
      'remote_config_available': RemoteConfigService.isAvailable,
      'environment': _getEnvironment(),
      'is_production': isProduction,
      'is_staging': isStaging,
      'is_development': isDevelopment,
      'remote_config_values': RemoteConfigService.isAvailable
          ? {
              'backend_api_url': RemoteConfigService.getBackendApiUrl(),
              'remote_config_status': 'available',
            }
          : {'remote_config_status': 'not_available'},
      'env_variables': {
        'API_BASE_URL': dotenv.maybeGet('API_BASE_URL') ?? 'not_set',
      },
      'fallback_urls': {
        'development': _developmentUrl,
        'staging': _stagingUrl,
        'production': _productionUrl,
      },
    };
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
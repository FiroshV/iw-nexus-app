import 'package:flutter/foundation.dart';
import 'timezone_util.dart';

/// Test function to verify timezone functionality
/// This is for debugging and testing purposes only
Future<void> testTimezoneUtility() async {
  if (!kDebugMode) return; // Only run in debug mode
  
  try {
    // Initialize timezone
    await TimezoneUtil.initialize();
    
    debugPrint('🧪 TIMEZONE TEST RESULTS:');
    debugPrint('=' * 50);
    
    // Test current time
    final now = TimezoneUtil.nowIST();
    debugPrint('📅 Current IST Time: ${TimezoneUtil.fullDateTimeIST(now)}');
    debugPrint('🕐 Time Only: ${TimezoneUtil.timeOnlyIST(now)}');
    debugPrint('📆 Date Only: ${TimezoneUtil.dateOnlyIST(now)}');
    
    // Test UTC conversion
    final utc = now.toUtc();
    debugPrint('🌍 UTC Time: ${utc.toIso8601String()}');
    debugPrint('↩️  Back to IST: ${TimezoneUtil.formatIST(TimezoneUtil.utcToIST(utc), 'yyyy-MM-dd HH:mm:ss')}');
    
    // Test API string conversion
    final apiString = TimezoneUtil.nowToApiString();
    debugPrint('📡 API Format: $apiString');
    debugPrint('↩️  Parsed back: ${TimezoneUtil.formatIST(TimezoneUtil.parseToIST(apiString), 'yyyy-MM-dd HH:mm:ss')}');
    
    // Test work hours calculation
    final startTime = now.subtract(const Duration(hours: 8, minutes: 30));
    final endTime = now;
    final workHours = TimezoneUtil.formatDurationFromIST(startTime, endTime);
    debugPrint('⏰ Work Hours Test: $workHours');
    
    // Test timezone info
    final info = TimezoneUtil.getTimezoneInfo();
    debugPrint('ℹ️ Timezone Info:');
    info.forEach((key, value) {
      debugPrint('  $key: $value');
    });
    
    debugPrint('=' * 50);
    debugPrint('✅ All timezone tests completed successfully!');
    
  } catch (e, stackTrace) {
    debugPrint('❌ Timezone test failed: $e');
    debugPrint('Stack trace: $stackTrace');
  }
}
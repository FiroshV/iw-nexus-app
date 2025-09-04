import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:intl/intl.dart';

/// Utility class for handling timezone operations specifically for India (Asia/Kolkata)
/// 
/// This class ensures all datetime operations use Indian Standard Time (IST)
/// regardless of device timezone settings, providing consistent behavior
/// across the HRMS application.
/// 
/// Usage:
/// ```dart
/// // Get current IST time
/// final istNow = TimezoneUtil.nowIST();
/// 
/// // Convert UTC to IST
/// final istTime = TimezoneUtil.utcToIST(utcDateTime);
/// 
/// // Format time in IST
/// final formatted = TimezoneUtil.formatTimeIST(dateTime, 'h:mm a');
/// ```
class TimezoneUtil {
  static tz.Location? _istLocation;
  static String? _deviceTimezone;
  
  /// Initialize timezone data and set up IST location
  /// This should be called during app initialization
  static Future<void> initialize() async {
    try {
      // Initialize timezone database
      await _initializeTimezoneDatabase();
      
      // Get device timezone for logging/debugging
      _deviceTimezone = await FlutterTimezone.getLocalTimezone();
      
      // Set IST location
      _istLocation = tz.getLocation('Asia/Kolkata');
      
      print('🌍 Timezone initialized: Device=$_deviceTimezone, App=Asia/Kolkata');
    } catch (e) {
      print('❌ Timezone initialization error: $e');
      // Fallback: try to set location anyway
      try {
        _istLocation = tz.getLocation('Asia/Kolkata');
      } catch (e2) {
        print('❌ Critical: Could not set Asia/Kolkata timezone: $e2');
      }
    }
  }
  
  /// Initialize timezone database with fallback handling
  static Future<void> _initializeTimezoneDatabase() async {
    try {
      // Try to initialize with default database
      tz.initializeTimeZones();
    } catch (e) {
      print('Warning: Could not initialize timezone database: $e');
      // In production, you might want to bundle timezone data
      rethrow;
    }
  }
  
  /// Get current time in Indian Standard Time (IST)
  /// Returns TZDateTime for timezone-aware operations
  static tz.TZDateTime nowIST() {
    if (_istLocation == null) {
      print('Warning: IST location not initialized, using system timezone');
      return tz.TZDateTime.now(tz.local);
    }
    return tz.TZDateTime.now(_istLocation!);
  }
  
  /// Convert UTC DateTime to IST TZDateTime
  static tz.TZDateTime utcToIST(DateTime utcDateTime) {
    if (_istLocation == null) {
      print('Warning: IST location not initialized, using system timezone');
      return tz.TZDateTime.from(utcDateTime, tz.local);
    }
    
    // If the input is already timezone-aware, convert it
    if (utcDateTime is tz.TZDateTime) {
      return tz.TZDateTime.from(utcDateTime.toUtc(), _istLocation!);
    }
    
    // Assume input is UTC if it's a regular DateTime
    final utcTz = tz.TZDateTime.utc(
      utcDateTime.year,
      utcDateTime.month,
      utcDateTime.day,
      utcDateTime.hour,
      utcDateTime.minute,
      utcDateTime.second,
      utcDateTime.millisecond,
    );
    
    return tz.TZDateTime.from(utcTz, _istLocation!);
  }
  
  /// Convert IST TZDateTime to UTC DateTime for API calls
  static DateTime istToUtc(tz.TZDateTime istDateTime) {
    return istDateTime.toUtc();
  }
  
  /// Parse ISO string and convert to IST
  /// Handles both UTC and timezone-aware ISO strings
  static tz.TZDateTime parseToIST(String isoString) {
    try {
      final parsed = DateTime.parse(isoString);
      
      // If the string contains timezone info, parse as TZDateTime
      if (isoString.contains('Z') || isoString.contains('+') || isoString.contains('-')) {
        // This is likely UTC or has timezone info
        return utcToIST(parsed.toUtc());
      } else {
        // Assume it's local time that should be interpreted as IST
        if (_istLocation != null) {
          return tz.TZDateTime(_istLocation!, parsed.year, parsed.month, parsed.day,
              parsed.hour, parsed.minute, parsed.second, parsed.millisecond);
        }
      }
    } catch (e) {
      print('Error parsing datetime string: $isoString, error: $e');
    }
    
    // Fallback: treat as current IST time
    return nowIST();
  }
  
  /// Format TZDateTime in IST with custom pattern
  static String formatIST(tz.TZDateTime dateTime, String pattern) {
    final formatter = DateFormat(pattern);
    return formatter.format(dateTime);
  }
  
  /// Format any DateTime as IST time with custom pattern
  /// Automatically converts to IST if needed
  static String formatAsIST(DateTime dateTime, String pattern) {
    final istTime = dateTime is tz.TZDateTime 
        ? tz.TZDateTime.from(dateTime, _istLocation ?? tz.local)
        : utcToIST(dateTime);
    return formatIST(istTime, pattern);
  }
  
  /// Common time formats for the app
  static String timeOnlyIST(tz.TZDateTime dateTime) => formatIST(dateTime, 'h:mm a');
  static String dateOnlyIST(tz.TZDateTime dateTime) => formatIST(dateTime, 'dd MMM yyyy');
  static String dateTimeIST(tz.TZDateTime dateTime) => formatIST(dateTime, 'dd MMM yyyy, h:mm a');
  static String fullDateTimeIST(tz.TZDateTime dateTime) => formatIST(dateTime, 'EEEE, dd MMMM yyyy, h:mm a');
  
  /// Format duration between two times in IST
  static String formatDurationFromIST(tz.TZDateTime startTime, tz.TZDateTime endTime) {
    final duration = endTime.difference(startTime);
    
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }
  
  /// Get work hours between check-in and check-out in IST
  static String calculateWorkHours(String? checkInTime, String? checkOutTime) {
    if (checkInTime == null || checkOutTime == null) return '0h 0m';
    
    try {
      final checkIn = parseToIST(checkInTime);
      final checkOut = parseToIST(checkOutTime);
      return formatDurationFromIST(checkIn, checkOut);
    } catch (e) {
      print('Error calculating work hours: $e');
      return '0h 0m';
    }
  }
  
  /// Convert current time to API-friendly ISO string in UTC
  static String nowToApiString() {
    return nowIST().toUtc().toIso8601String();
  }
  
  /// Convert TZDateTime to API-friendly ISO string in UTC
  static String toApiString(tz.TZDateTime dateTime) {
    return dateTime.toUtc().toIso8601String();
  }
  
  /// Check if a datetime is today in IST
  static bool isToday(tz.TZDateTime dateTime) {
    final now = nowIST();
    return dateTime.year == now.year && 
           dateTime.month == now.month && 
           dateTime.day == now.day;
  }
  
  /// Get start of day in IST (00:00:00)
  static tz.TZDateTime startOfDayIST([tz.TZDateTime? dateTime]) {
    final date = dateTime ?? nowIST();
    if (_istLocation != null) {
      return tz.TZDateTime(_istLocation!, date.year, date.month, date.day);
    }
    return tz.TZDateTime(tz.local, date.year, date.month, date.day);
  }
  
  /// Get end of day in IST (23:59:59)
  static tz.TZDateTime endOfDayIST([tz.TZDateTime? dateTime]) {
    final date = dateTime ?? nowIST();
    if (_istLocation != null) {
      return tz.TZDateTime(_istLocation!, date.year, date.month, date.day, 23, 59, 59, 999);
    }
    return tz.TZDateTime(tz.local, date.year, date.month, date.day, 23, 59, 59, 999);
  }
  
  /// Debug info about current timezone setup
  static Map<String, dynamic> getTimezoneInfo() {
    final now = nowIST();
    return {
      'deviceTimezone': _deviceTimezone,
      'appTimezone': 'Asia/Kolkata',
      'istLocationSet': _istLocation != null,
      'currentISTTime': formatIST(now, 'yyyy-MM-dd HH:mm:ss'),
      'currentUTCTime': now.toUtc().toIso8601String(),
      'istOffset': now.timeZoneOffset.inHours,
    };
  }
}
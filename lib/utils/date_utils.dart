import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

/// Utility class for handling date/time formatting.
/// Stores UTC in database, displays local time to users.
class DateTimeUtils {
  static const Duration _timeOffset = Duration(hours: 5, minutes: 30);

  /// Parse a UTC date string and convert to local time.
  ///
  /// Handles both:
  /// - ISO8601 strings from API (e.g., "2025-12-18T04:47:00.000Z")
  /// - Already-parsed DateTime objects
  static DateTime parseFromUTC(dynamic date) {
    if (date == null) return DateTime.now();
    if (date is DateTime) {
      if (!date.isUtc) return date;
      return date.add(_timeOffset);
    }

    try {
      final parsed = DateTime.parse(date.toString()).toUtc();
      return parsed.add(_timeOffset);
    } catch (e) {
      debugPrint('ERROR: Could not parse date: $date, error: $e');
      return DateTime.now();
    }
  }

  /// Format a date/time for timeline display.
  /// Example: "18 Dec 2025, 10:17 AM"
  static String formatActivityDate(dynamic date) {
    try {
      final dateTime = parseFromUTC(date);
      return DateFormat('dd MMM yyyy, hh:mm a').format(dateTime);
    } catch (e) {
      debugPrint('ERROR: Could not format activity date: $date, error: $e');
      return 'Invalid date';
    }
  }

  /// Format a date for stats display.
  /// Example: "18 Dec 2025"
  static String formatShortDate(dynamic date) {
    if (date == null) return 'Never';
    try {
      final dateTime = parseFromUTC(date);
      return DateFormat('dd MMM yyyy').format(dateTime);
    } catch (e) {
        debugPrint('ERROR: Could not format short date: $date, error: $e');
      return 'Unknown';
    }
  }

  /// Format a date showing relative time or date.
  /// Example: "Today", "Yesterday", or "18 Dec"
  static String formatRelativeDate(dynamic date) {
    if (date == null) return 'Never';
    try {
      final dateTime = parseFromUTC(date);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final dateOnly = DateTime(dateTime.year, dateTime.month, dateTime.day);
      final yesterday = today.subtract(const Duration(days: 1));

      if (dateOnly == today) {
        return 'Today';
      } else if (dateOnly == yesterday) {
        return 'Yesterday';
      } else {
        return DateFormat('dd MMM').format(dateTime);
      }
    } catch (e) {
        debugPrint('ERROR: Could not format relative date: $date, error: $e');
      return 'Unknown';
    }
  }

  /// Format time only.
  /// Example: "10:17 AM"
  static String formatTimeOnly(dynamic date) {
    try {
      final dateTime = parseFromUTC(date);
      return DateFormat('hh:mm a').format(dateTime);
    } catch (e) {
      debugPrint('ERROR: Could not format time: $date, error: $e');
      return 'Unknown';
    }
  }

  /// Check if two dates are on the same day.
  static bool isSameDay(dynamic date1, dynamic date2) {
    try {
      final dt1 = parseFromUTC(date1);
      final dt2 = parseFromUTC(date2);
      return dt1.year == dt2.year &&
          dt1.month == dt2.month &&
          dt1.day == dt2.day;
    } catch (e) {
      debugPrint('ERROR: Could not compare dates: $e');
      return false;
    }
  }

  /// Convert a local DateTime to ISO8601 string for API.
  static String localToISO8601(DateTime localDateTime) {
    final utcEquivalent = localDateTime.subtract(_timeOffset);
    return utcEquivalent.toIso8601String();
  }
}

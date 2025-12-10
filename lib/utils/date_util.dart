import 'package:intl/intl.dart';

/// Centralized utility for handling date-only fields (no time component).
/// Solves timezone issues by using UTC midnight for storage and proper formatting for display.
class DateUtil {
  /// Converts a local date from date picker to UTC midnight.
  /// This ensures the date component is preserved regardless of timezone.
  ///
  /// Example: Jan 15 local time → Jan 15 UTC midnight
  /// NOT Jan 14 UTC (which was the bug)
  static DateTime dateOnlyToUtcMidnight(DateTime localDate) {
    return DateTime.utc(localDate.year, localDate.month, localDate.day, 0, 0, 0);
  }

  /// Converts UTC midnight DateTime to ISO 8601 string for API submission.
  /// Assumes input is already in UTC midnight format.
  static String utcMidnightToApiString(DateTime utcDate) {
    return utcDate.toIso8601String();
  }

  /// Parses ISO 8601 string from API response to DateTime.
  /// Handles null/empty strings gracefully.
  static DateTime? parseDateFromApi(String? isoString) {
    if (isoString == null || isoString.isEmpty) {
      return null;
    }
    try {
      return DateTime.parse(isoString);
    } catch (e) {
      return null;
    }
  }

  /// Formats DateTime for display as DD/MM/YYYY.
  /// Used in date input fields and form displays.
  /// Handles null dates gracefully.
  static String formatDateForDisplay(DateTime? date) {
    if (date == null) {
      return 'Select date';
    }
    try {
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (e) {
      return 'Invalid date';
    }
  }

  /// Formats DateTime for display as "15 Jan 2024" (long format).
  /// Used in detail views and lists.
  /// Handles null dates gracefully.
  static String formatDateForDisplayLong(DateTime? date) {
    if (date == null) {
      return 'Not set';
    }
    try {
      return DateFormat('dd MMM yyyy').format(date);
    } catch (e) {
      return 'Invalid date';
    }
  }

  /// Checks if a DateTime is at midnight UTC.
  /// Useful for validation purposes.
  static bool isMidnightUtc(DateTime date) {
    return date.hour == 0 &&
        date.minute == 0 &&
        date.second == 0 &&
        date.millisecond == 0 &&
        date.microsecond == 0;
  }
}

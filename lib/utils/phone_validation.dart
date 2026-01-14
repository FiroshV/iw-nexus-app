/// Utility class for phone number validation and formatting.
///
/// Provides consistent validation and formatting for Indian phone numbers
/// across the application.
class PhoneValidation {
  /// Validates an Indian mobile number.
  ///
  /// Mobile numbers must be exactly 10 digits and start with 6, 7, 8, or 9.
  ///
  /// Returns an error message if invalid, null if valid.
  static String? validateIndianMobile(String? value, {bool isRequired = true}) {
    if (value == null || value.trim().isEmpty) {
      return isRequired ? 'Phone number is required' : null;
    }

    final cleaned = value.replaceAll(RegExp(r'\D'), '');

    if (cleaned.length != 10) {
      return 'Please enter exactly 10 digits';
    }

    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(cleaned)) {
      return 'Mobile number must start with 6, 7, 8, or 9';
    }

    return null;
  }

  /// Validates an Indian landline number.
  ///
  /// Landline numbers must be exactly 10 digits (including STD code).
  /// More flexible than mobile validation - accepts any 10 digits.
  ///
  /// Returns an error message if invalid, null if valid.
  static String? validateIndianLandline(String? value,
      {bool isRequired = true}) {
    if (value == null || value.trim().isEmpty) {
      return isRequired ? 'Phone number is required' : null;
    }

    final cleaned = value.replaceAll(RegExp(r'\D'), '');

    if (cleaned.length != 10) {
      return 'Please enter exactly 10 digits';
    }

    return null;
  }

  /// Formats a 10-digit phone number for API submission.
  ///
  /// Adds the +91 prefix to create the international format.
  ///
  /// Example: "9876543210" -> "+919876543210"
  static String formatForApi(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'\D'), '');
    if (cleaned.length == 10) {
      return '+91$cleaned';
    }
    // If already has country code, ensure it has + prefix
    if (cleaned.length == 12 && cleaned.startsWith('91')) {
      return '+$cleaned';
    }
    return phone;
  }

  /// Parses a phone number from API response for display.
  ///
  /// Strips the +91 prefix to get the 10-digit number for input fields.
  ///
  /// Example: "+919876543210" -> "9876543210"
  static String parseFromApi(String? phone) {
    if (phone == null || phone.isEmpty) return '';

    final cleaned = phone.replaceAll(RegExp(r'\D'), '');

    // Handle +91 or 91 prefix
    if (cleaned.length == 12 && cleaned.startsWith('91')) {
      return cleaned.substring(2);
    }

    // Already 10 digits
    if (cleaned.length == 10) {
      return cleaned;
    }

    // Return last 10 digits if longer
    if (cleaned.length > 10) {
      return cleaned.substring(cleaned.length - 10);
    }

    return phone;
  }

  /// Checks if a phone number is valid (10 digits starting with 6-9).
  static bool isValidIndianMobile(String? phone) {
    if (phone == null || phone.isEmpty) return false;
    final cleaned = phone.replaceAll(RegExp(r'\D'), '');
    return RegExp(r'^[6-9]\d{9}$').hasMatch(cleaned);
  }

  /// Checks if a string looks like a phone number (has 10+ digits).
  static bool looksLikePhone(String? value) {
    if (value == null || value.isEmpty) return false;
    final digits = value.replaceAll(RegExp(r'\D'), '');
    return digits.length >= 10;
  }

  /// Masks a phone number for display (e.g., "98****3210").
  static String maskPhone(String? phone, {int visibleStart = 2, int visibleEnd = 4}) {
    if (phone == null || phone.isEmpty) return '';

    final cleaned = parseFromApi(phone);
    if (cleaned.length != 10) return phone;

    final start = cleaned.substring(0, visibleStart);
    final end = cleaned.substring(cleaned.length - visibleEnd);
    final masked = '*' * (10 - visibleStart - visibleEnd);

    return '$start$masked$end';
  }

  /// Formats phone number for display with spacing (e.g., "98765 43210").
  static String formatForDisplay(String? phone) {
    if (phone == null || phone.isEmpty) return '';

    final cleaned = parseFromApi(phone);
    if (cleaned.length != 10) return phone;

    return '${cleaned.substring(0, 5)} ${cleaned.substring(5)}';
  }
}

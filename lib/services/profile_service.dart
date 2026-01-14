import 'api_service.dart';

class ProfileService {
  static const List<String> requiredFields = [
    'firstName',
    'lastName',
    'email',
    'designation',
    'address',
    'homePhoneNumber',
    'phoneNumber',
    'dateOfBirth',
    'bloodGroup',
  ];

  /// Roles exempt from mandatory profile completion for attendance
  static const List<String> _exemptRoles = ['admin', 'director'];

  // Cache for document completion status to avoid repeated API calls
  static Map<String, dynamic>? _documentCompletionCache;
  static DateTime? _lastDocumentCheck;

  static bool isProfileComplete(Map<String, dynamic>? userData) {
    if (userData == null) return false;

    // Check all required text fields
    for (String field in requiredFields) {
      final value = userData[field];
      if (value == null || value.toString().trim().isEmpty) {
        return false;
      }
    }

    // Check profile image (avatar)
    final avatar = userData['avatar'];
    if (avatar == null || avatar.toString().trim().isEmpty) {
      return false;
    }

    return true;
  }

  /// Check if role is exempt from profile completion requirement
  static bool isRoleExempt(String? role) {
    if (role == null || role.isEmpty) return false;
    return _exemptRoles.contains(role.toLowerCase());
  }

  /// Combined check - returns true if user can access attendance
  /// Either their role is exempt OR their profile is complete
  static bool canAccessAttendance(Map<String, dynamic>? userData) {
    if (userData == null) return false;

    final role = userData['role'] as String?;

    // Exempt roles always have access
    if (isRoleExempt(role)) return true;

    // Non-exempt roles must have complete profile
    return isProfileComplete(userData);
  }

  /// Get list of missing fields for messaging
  static List<String> getMissingFields(Map<String, dynamic>? userData) {
    if (userData == null) return [...requiredFields, 'avatar'];

    final missing = <String>[];
    for (String field in requiredFields) {
      final value = userData[field];
      if (value == null || value.toString().trim().isEmpty) {
        missing.add(field);
      }
    }

    // Check avatar separately
    final avatar = userData['avatar'];
    if (avatar == null || avatar.toString().trim().isEmpty) {
      missing.add('avatar');
    }

    return missing;
  }

  // ============================================================================
  // DOCUMENT COMPLETION METHODS
  // ============================================================================

  /// Clear the document completion cache
  static void clearDocumentCache() {
    _documentCompletionCache = null;
    _lastDocumentCheck = null;
  }

  /// Check if all mandatory documents are uploaded
  /// Returns true if documents are complete, false otherwise
  static Future<bool> areDocumentsComplete({bool forceRefresh = false}) async {
    final details = await getDocumentCompletionDetails(forceRefresh: forceRefresh);
    return details['isComplete'] == true;
  }

  /// Get detailed document completion status
  /// Returns a map with: isComplete, uploadedCount, totalRequired, missingCategories, uploadedCategories
  static Future<Map<String, dynamic>> getDocumentCompletionDetails({
    bool forceRefresh = false,
  }) async {
    // Use cache if available and not expired (valid for 30 seconds)
    if (!forceRefresh &&
        _documentCompletionCache != null &&
        _lastDocumentCheck != null &&
        DateTime.now().difference(_lastDocumentCheck!).inSeconds < 30) {
      return _documentCompletionCache!;
    }

    try {
      final response = await ApiService.getDocumentCompletionStatus();
      if (response.success && response.data != null) {
        _documentCompletionCache = response.data;
        _lastDocumentCheck = DateTime.now();
        return response.data!;
      }
    } catch (e) {
      // On error, return incomplete status
    }

    return {
      'isComplete': false,
      'uploadedCount': 0,
      'totalRequired': 7,
      'missingCategories': <String>[],
      'uploadedCategories': <String>[],
    };
  }

  /// Get set of uploaded document categories
  static Future<Set<String>> getUploadedCategories({bool forceRefresh = false}) async {
    final details = await getDocumentCompletionDetails(forceRefresh: forceRefresh);
    final uploaded = details['uploadedCategories'];
    if (uploaded is List) {
      return uploaded.map((e) => e.toString()).toSet();
    }
    return <String>{};
  }

  /// Async version of canAccessAttendance that also checks document completion
  /// Use this for navigation guards that need to check both profile AND documents
  static Future<bool> canAccessAttendanceAsync(Map<String, dynamic>? userData) async {
    if (userData == null) return false;

    final role = userData['role'] as String?;

    // Exempt roles always have access
    if (isRoleExempt(role)) return true;

    // Non-exempt roles must have complete profile AND all mandatory documents
    final profileComplete = isProfileComplete(userData);
    if (!profileComplete) return false;

    final documentsComplete = await areDocumentsComplete();
    return documentsComplete;
  }

  /// Get completion status for both profile and documents
  /// Returns a map with profileComplete, documentsComplete, and overall isComplete
  static Future<Map<String, dynamic>> getFullCompletionStatus(
    Map<String, dynamic>? userData,
  ) async {
    final profileComplete = isProfileComplete(userData);
    final missingFields = getMissingFields(userData);
    final documentDetails = await getDocumentCompletionDetails();

    return {
      'profileComplete': profileComplete,
      'missingFields': missingFields,
      'documentsComplete': documentDetails['isComplete'] == true,
      'documentDetails': documentDetails,
      'isComplete': profileComplete && documentDetails['isComplete'] == true,
    };
  }
}
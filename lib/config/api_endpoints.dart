/// API endpoint constants organized by feature
class ApiEndpoints {
  // Private constructor to prevent instantiation
  ApiEndpoints._();

  // Base paths
  static const String auth = '/auth';
  static const String users = '/users';
  static const String branches = '/branches';
  static const String attendance = '/attendance';
  static const String reports = '/reports';
  static const String feedback = '/feedback';
  static const String health = '/health';

  // Authentication endpoints
  static const String checkUserExists = '$auth/check-user-exists';
  static const String sendOtp = '$auth/send-otp';
  static const String verifyOtp = '$auth/verify-otp';
  static const String resendOtp = '$auth/resend-otp';
  static const String verifyFirebaseToken = '$auth/verify-firebase-token';
  static const String firebaseSignin = '$auth/firebase-signin';
  static const String refreshToken = '$auth/refresh-token';
  static const String getCurrentUser = '$auth/me';
  static const String logout = '$auth/logout';
  static const String validateSession = '$auth/session/validate';

  // User management endpoints
  static const String createUser = users;
  static const String getAllUsers = users;
  static const String getUserById = '$users/{userId}';
  static const String updateUser = '$users/{userId}';
  static const String deleteUser = '$users/{userId}';
  static const String getUserProfile = '$users/profile';
  static const String updateUserProfile = '$users/profile';
  static const String generateIdCard = '$users/id-card';
  static const String generateVisitingCard = '$users/visiting-card';

  // Document management endpoints
  static const String userDocuments = '$users/documents';
  static const String uploadDocument = '$users/documents';
  static const String getUserDocuments = '$users/documents';
  static const String updateDocument = '$users/documents/{documentId}';
  static const String deleteDocument = '$users/documents/{documentId}';
  static const String downloadDocument = '$users/documents/{documentId}';
  
  // User queries
  static const String getManagers = '$users?role=manager&status=active&limit=100';

  // Attendance endpoints
  static const String checkIn = '$attendance/check-in';
  static const String checkOut = '$attendance/check-out';
  static const String breakOut = '$attendance/break-out';
  static const String breakIn = '$attendance/break-in';
  static const String todayAttendance = '$attendance/today';
  static const String attendanceHistory = '$attendance/history';
  static const String attendanceSummary = '$attendance/summary';

  // Reports endpoints
  static const String attendanceSummaryReport = '$reports/attendance-summary';
  static const String employeeAttendanceReport = '$reports/employee-attendance';
  static const String branchComparisonReport = '$reports/branch-comparison';

  // Feedback endpoints
  static const String createFeedback = feedback;
  static const String getUserFeedback = feedback;
  static const String getAllFeedback = '$feedback/admin/all';
  static const String getFeedbackStats = '$feedback/admin/stats';
  static const String getFeedbackById = '$feedback/{feedbackId}';
  static const String updateFeedbackStatus = '$feedback/{feedbackId}/status';
  static const String addFeedbackResponse = '$feedback/{feedbackId}/response';
  static const String deleteFeedback = '$feedback/{feedbackId}';

  // CRM endpoints
  static const String crm = '/crm';
  static const String crmSales = '$crm/sales';
  static const String crmCustomers = '$crm/customers';
  static const String crmVisits = '$crm/visits';
  static const String crmReports = '$crm/reports';
  static const String salesByProduct = '$crmReports/sales-by-product';
  static const String employeePerformance = '$crmReports/employee-performance';
  static const String visitEffectiveness = '$crmReports/visit-effectiveness';
  static const String branchSales = '$crmReports/branch-sales';

  // Incentive Management endpoints
  static const String incentives = '/incentives';
  static const String incentiveTemplates = '$incentives/templates';
  static const String incentiveAssignments = '$incentives/assignments';
  static const String myIncentive = '$incentives/my-incentive';
  static const String myIncentiveProgress = '$incentives/my-incentive/progress';
  static const String pendingPromotions = '$incentives/promotions/pending';

  // System endpoints
  static const String healthCheck = health;

  // Helper methods for dynamic endpoints
  static String userByIdEndpoint(String userId) => '$users/$userId';

  static String feedbackByIdEndpoint(String feedbackId) => '$feedback/$feedbackId';

  static String updateFeedbackStatusEndpoint(String feedbackId) => '$feedback/$feedbackId/status';

  static String addFeedbackResponseEndpoint(String feedbackId) => '$feedback/$feedbackId/response';

  // Query builders for complex endpoints
  static String buildUsersQuery({
    int page = 1,
    int limit = 20,
    String? role,
    String? status,
    String? search,
  }) {
    final params = <String>[];
    params.add('page=$page');
    params.add('limit=$limit');
    
    if (role != null) params.add('role=${Uri.encodeComponent(role)}');
    if (status != null) params.add('status=${Uri.encodeComponent(status)}');
    if (search != null) params.add('search=${Uri.encodeComponent(search)}');

    return '$users?${params.join('&')}';
  }

  static String buildAttendanceHistoryQuery({
    int page = 1,
    int limit = 30,
    String? startDate,
    String? endDate,
    String? status,
  }) {
    final params = <String>[];
    params.add('page=$page');
    params.add('limit=$limit');
    
    if (startDate != null) params.add('startDate=${Uri.encodeComponent(startDate)}');
    if (endDate != null) params.add('endDate=${Uri.encodeComponent(endDate)}');
    if (status != null) params.add('status=${Uri.encodeComponent(status)}');

    return '$attendanceHistory?${params.join('&')}';
  }

  static String buildAttendanceSummaryQuery({
    int? year,
    int? month,
  }) {
    final params = <String>[];

    if (year != null) params.add('year=$year');
    if (month != null) params.add('month=$month');

    return params.isEmpty
        ? attendanceSummary
        : '$attendanceSummary?${params.join('&')}';
  }

  static String buildFeedbackQuery({
    int page = 1,
    int limit = 10,
    String? type,
    String? status,
  }) {
    final params = <String>[];
    params.add('page=$page');
    params.add('limit=$limit');

    if (type != null) params.add('type=${Uri.encodeComponent(type)}');
    if (status != null) params.add('status=${Uri.encodeComponent(status)}');

    return '$feedback?${params.join('&')}';
  }

  static String buildAllFeedbackQuery({
    int page = 1,
    int limit = 20,
    String? type,
    String? status,
    String? priority,
    String? search,
  }) {
    final params = <String>[];
    params.add('page=$page');
    params.add('limit=$limit');

    if (type != null) params.add('type=${Uri.encodeComponent(type)}');
    if (status != null) params.add('status=${Uri.encodeComponent(status)}');
    if (priority != null) params.add('priority=${Uri.encodeComponent(priority)}');
    if (search != null) params.add('search=${Uri.encodeComponent(search)}');

    return '$getAllFeedback?${params.join('&')}';
  }

  // CRM query builders
  static String buildSalesQuery({
    int skip = 0,
    int limit = 20,
    String? productType,
    String? startDate,
    String? endDate,
    String? branch,
    String? status,
    String? search,
    String view = 'assigned',
  }) {
    final params = <String>[];
    params.add('skip=$skip');
    params.add('limit=$limit');
    params.add('view=$view');

    if (productType != null) params.add('productType=${Uri.encodeComponent(productType)}');
    if (startDate != null) params.add('startDate=${Uri.encodeComponent(startDate)}');
    if (endDate != null) params.add('endDate=${Uri.encodeComponent(endDate)}');
    if (branch != null) params.add('branch=${Uri.encodeComponent(branch)}');
    if (status != null) params.add('status=${Uri.encodeComponent(status)}');
    if (search != null) params.add('search=${Uri.encodeComponent(search)}');

    return '$crmSales?${params.join('&')}';
  }

  static String buildCustomersQuery({
    int skip = 0,
    int limit = 20,
    String? search,
  }) {
    final params = <String>[];
    params.add('skip=$skip');
    params.add('limit=$limit');

    if (search != null) params.add('search=${Uri.encodeComponent(search)}');

    return '$crmCustomers?${params.join('&')}';
  }

  static String buildVisitsQuery({
    int skip = 0,
    int limit = 20,
    String? customerId,
    String? linkedSaleId,
    String? startDate,
    String? endDate,
    String? outcome,
    String? search,
    String? followupFilter,
  }) {
    final params = <String>[];
    params.add('skip=$skip');
    params.add('limit=$limit');

    if (customerId != null) params.add('customerId=${Uri.encodeComponent(customerId)}');
    if (linkedSaleId != null) params.add('linkedSaleId=${Uri.encodeComponent(linkedSaleId)}');
    if (startDate != null) params.add('startDate=${Uri.encodeComponent(startDate)}');
    if (endDate != null) params.add('endDate=${Uri.encodeComponent(endDate)}');
    if (outcome != null) params.add('outcome=${Uri.encodeComponent(outcome)}');
    if (search != null && search.isNotEmpty) params.add('search=${Uri.encodeComponent(search)}');
    if (followupFilter != null) params.add('followupFilter=${Uri.encodeComponent(followupFilter)}');

    return '$crmVisits?${params.join('&')}';
  }

  static String saleByIdEndpoint(String saleId) => '$crmSales/$saleId';

  static String customerByIdEndpoint(String customerId) => '$crmCustomers/$customerId';

  static String visitByIdEndpoint(String visitId) => '$crmVisits/$visitId';

  static String linkVisitToSaleEndpoint(String visitId, String saleId) => '$crmVisits/$visitId/link-sale/$saleId';

  static String unlinkVisitFromSaleEndpoint(String visitId, String saleId) => '$crmVisits/$visitId/unlink-sale/$saleId';

  // Incentive helper methods
  static String incentiveTemplateByIdEndpoint(String templateId) => '$incentiveTemplates/$templateId';

  static String incentiveAssignmentByUserIdEndpoint(String userId) => '$incentiveAssignments/$userId';

  static String approvePromotionEndpoint(String userId) => '$incentives/promotions/$userId/approve';

  static String rejectPromotionEndpoint(String userId) => '$incentives/promotions/$userId/reject';

  static String calculateIncentiveEndpoint(String userId) => '$incentives/calculate/$userId';

  static String buildIncentiveTemplatesQuery({
    int skip = 0,
    int limit = 50,
    String? search,
    bool? active,
  }) {
    final params = <String>[];
    params.add('skip=$skip');
    params.add('limit=$limit');

    if (search != null) params.add('search=${Uri.encodeComponent(search)}');
    if (active != null) params.add('active=$active');

    return '$incentiveTemplates?${params.join('&')}';
  }

  static String buildIncentiveAssignmentsQuery({
    int skip = 0,
    int limit = 50,
    String? search,
    String? templateId,
    bool? hasPromotion,
  }) {
    final params = <String>[];
    params.add('skip=$skip');
    params.add('limit=$limit');

    if (search != null) params.add('search=${Uri.encodeComponent(search)}');
    if (templateId != null) params.add('templateId=${Uri.encodeComponent(templateId)}');
    if (hasPromotion != null) params.add('hasPromotion=$hasPromotion');

    return '$incentiveAssignments?${params.join('&')}';
  }
}

/// HTTP methods constants
class HttpMethods {
  static const String get = 'GET';
  static const String post = 'POST';
  static const String put = 'PUT';
  static const String delete = 'DELETE';
  static const String patch = 'PATCH';
}

/// Common query parameters
class QueryParams {
  static const String page = 'page';
  static const String limit = 'limit';
  static const String search = 'search';
  static const String startDate = 'startDate';
  static const String endDate = 'endDate';
  static const String status = 'status';
  static const String role = 'role';
  static const String year = 'year';
  static const String month = 'month';
}
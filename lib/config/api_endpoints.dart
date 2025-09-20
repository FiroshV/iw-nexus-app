/// API endpoint constants organized by feature
class ApiEndpoints {
  // Private constructor to prevent instantiation
  ApiEndpoints._();

  // Base paths
  static const String auth = '/auth';
  static const String users = '/users';
  static const String branches = '/branches';
  static const String attendance = '/attendance';
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

  // System endpoints
  static const String healthCheck = health;

  // Helper methods for dynamic endpoints
  static String userByIdEndpoint(String userId) => '$users/$userId';

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
import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../models/activity.dart';
import 'api_service.dart';

class ApiResponse<T> {
  final bool success;
  final String? message;
  final T? data;
  final dynamic error;

  ApiResponse({
    required this.success,
    this.message,
    this.data,
    this.error,
  });
}

class ActivityService {
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: '${ApiConfig.baseUrl}/crm/activities',
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );

  static Future<String?> _getToken() async {
    return await ApiService.getToken();
  }

  static Future<void> _setupHeaders() async {
    final token = await _getToken();
    if (token != null) {
      _dio.options.headers['Authorization'] = 'Bearer $token';
    }
  }

  /// Create a new activity (quick log)
  static Future<ApiResponse<Activity>> createActivity({
    required String customerId,
    required String type,
    required String outcome,
    DateTime? activityDate,
    String? notes,
    int? durationMinutes,
    List<Map<String, dynamic>>? assignedEmployees,
  }) async {
    try {
      await _setupHeaders();
      final response = await _dio.post(
        '/',
        data: {
          'customerId': customerId,
          'type': type,
          'outcome': outcome,
          if (activityDate != null) 'activityDate': activityDate.toIso8601String(),
          if (notes != null) 'notes': notes,
          if (durationMinutes != null) 'durationMinutes': durationMinutes,
          if (assignedEmployees != null && assignedEmployees.isNotEmpty)
            'assignedEmployees': assignedEmployees,
        },
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return ApiResponse<Activity>(
          success: true,
          data: Activity.fromJson(response.data['data'] ?? response.data),
          message: response.data['message'] ?? 'Activity recorded successfully',
        );
      }
      return ApiResponse<Activity>(
        success: false,
        error: response.data['error'] ?? 'Failed to create activity',
      );
    } catch (e) {
      return ApiResponse<Activity>(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Get all activities for a customer
  static Future<ApiResponse<List<Activity>>> getCustomerActivities({
    required String customerId,
    int limit = 50,
    int skip = 0,
  }) async {
    try {
      await _setupHeaders();
      final response = await _dio.get(
        '/?customerId=$customerId&limit=$limit&skip=$skip',
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? [];
        return ApiResponse<List<Activity>>(
          success: true,
          data: data.map((json) => Activity.fromJson(json as Map<String, dynamic>)).toList(),
          message: response.data['message'] ?? 'Activities fetched successfully',
        );
      }
      return ApiResponse<List<Activity>>(
        success: false,
        error: response.data['error'] ?? 'Failed to fetch activities',
      );
    } catch (e) {
      return ApiResponse<List<Activity>>(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Get activities by type
  static Future<ApiResponse<List<Activity>>> getActivitiesByType({
    required String type,
    int limit = 50,
  }) async {
    try {
      await _setupHeaders();
      final response = await _dio.get(
        '/?type=$type&limit=$limit',
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? [];
        return ApiResponse<List<Activity>>(
          success: true,
          data: data.map((json) => Activity.fromJson(json as Map<String, dynamic>)).toList(),
        );
      }
      return ApiResponse<List<Activity>>(
        success: false,
        error: response.data['error'] ?? 'Failed to fetch activities',
      );
    } catch (e) {
      return ApiResponse<List<Activity>>(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Get activities filtered by user (creator or assigned)
  static Future<ApiResponse<List<Activity>>> getUserActivities({
    required String userId,
    String? type,
    String? outcome,
    DateTime? startDate,
    DateTime? endDate,
    String? search,
    int limit = 50,
    int skip = 0,
    String view = 'assigned',
  }) async {
    try {
      await _setupHeaders();

      final queryParams = <String, dynamic>{
        'userId': userId,
        'limit': limit,
        'skip': skip,
        'view': view,
      };

      if (type != null) queryParams['type'] = type;
      if (outcome != null) queryParams['outcome'] = outcome;
      if (startDate != null) queryParams['startDate'] = startDate.toIso8601String();
      if (endDate != null) queryParams['endDate'] = endDate.toIso8601String();
      if (search != null) queryParams['search'] = search;

      final queryString = queryParams.entries
          .map((e) => '${e.key}=${Uri.encodeComponent(e.value.toString())}')
          .join('&');

      final response = await _dio.get('/?$queryString');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? [];
        return ApiResponse<List<Activity>>(
          success: true,
          data: data.map((json) => Activity.fromJson(json as Map<String, dynamic>)).toList(),
          message: response.data['message'] ?? 'Activities fetched successfully',
        );
      }
      return ApiResponse<List<Activity>>(
        success: false,
        error: response.data['error'] ?? 'Failed to fetch activities',
      );
    } catch (e) {
      return ApiResponse<List<Activity>>(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Get single activity by ID
  static Future<ApiResponse<Activity>> getActivity(String activityId) async {
    try {
      await _setupHeaders();
      final response = await _dio.get('/$activityId');

      if (response.statusCode == 200) {
        return ApiResponse<Activity>(
          success: true,
          data: Activity.fromJson(response.data['data'] ?? response.data),
        );
      }
      return ApiResponse<Activity>(
        success: false,
        error: response.data['error'] ?? 'Failed to fetch activity',
      );
    } catch (e) {
      return ApiResponse<Activity>(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Update activity
  static Future<ApiResponse<Activity>> updateActivity({
    required String activityId,
    String? type,
    String? outcome,
    String? direction,
    int? durationMinutes,
    String? notes,
    String? followupAppointmentId,
  }) async {
    try {
      await _setupHeaders();
      final response = await _dio.put(
        '/$activityId',
        data: {
          if (type != null) 'type': type,
          if (outcome != null) 'outcome': outcome,
          if (direction != null) 'direction': direction,
          if (durationMinutes != null) 'durationMinutes': durationMinutes,
          if (notes != null) 'notes': notes,
          if (followupAppointmentId != null) 'followupAppointmentId': followupAppointmentId,
        },
      );

      if (response.statusCode == 200) {
        return ApiResponse<Activity>(
          success: true,
          data: Activity.fromJson(response.data['data'] ?? response.data),
          message: response.data['message'] ?? 'Activity updated successfully',
        );
      }
      return ApiResponse<Activity>(
        success: false,
        error: response.data['error'] ?? 'Failed to update activity',
      );
    } catch (e) {
      return ApiResponse<Activity>(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Delete activity
  static Future<ApiResponse<void>> deleteActivity(String activityId) async {
    try {
      await _setupHeaders();
      final response = await _dio.delete('/$activityId');

      if (response.statusCode == 200) {
        return ApiResponse<void>(
          success: true,
          message: response.data['message'] ?? 'Activity deleted successfully',
        );
      }
      return ApiResponse<void>(
        success: false,
        error: response.data['error'] ?? 'Failed to delete activity',
      );
    } catch (e) {
      return ApiResponse<void>(
        success: false,
        error: e.toString(),
      );
    }
  }
}

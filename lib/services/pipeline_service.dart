import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../models/customer.dart';
import '../models/pipeline_stats.dart';
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

class PipelineService {
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: '${ApiConfig.baseUrl}/crm/pipeline',
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

  /// Get pipeline dashboard stats
  static Future<ApiResponse<PipelineStatsData>> getPipelineDashboard({
    String view = 'assigned',
  }) async {
    try {
      await _setupHeaders();
      final response = await _dio.get(
        '/dashboard',
        queryParameters: {'view': view},
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] as Map<String, dynamic>;
        return ApiResponse(
          success: true,
          message: response.data['message'],
          data: PipelineStatsData.fromJson(data),
        );
      } else {
        return ApiResponse(
          success: false,
          message: response.data['message'] ?? 'Failed to fetch dashboard',
          error: response.data,
        );
      }
    } catch (error) {
      return ApiResponse(
        success: false,
        message: 'Error fetching pipeline dashboard',
        error: error.toString(),
      );
    }
  }

  /// Get customers by stage
  static Future<ApiResponse<List<Customer>>> getCustomersByStage(
    String stage, {
    String view = 'assigned',
    String? priority,
    String? search,
    int limit = 50,
    int skip = 0,
  }) async {
    try {
      await _setupHeaders();

      final queryParams = {
        'view': view,
        'limit': limit,
        'skip': skip,
      };

      if (priority != null) {
        queryParams['priority'] = priority;
      }

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      final response = await _dio.get(
        '/stage/$stage',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? [];
        final customers = data
            .map((item) => Customer.fromJson(item as Map<String, dynamic>))
            .toList();

        return ApiResponse(
          success: true,
          message: response.data['message'],
          data: customers,
        );
      } else {
        return ApiResponse(
          success: false,
          message: response.data['message'] ?? 'Failed to fetch stage customers',
          error: response.data,
        );
      }
    } catch (error) {
      return ApiResponse(
        success: false,
        message: 'Error fetching pipeline stage',
        error: error.toString(),
      );
    }
  }

  /// Get customers with overdue follow-ups
  static Future<ApiResponse<List<Customer>>> getOverdueFollowups({
    String view = 'assigned',
    int limit = 50,
    int skip = 0,
  }) async {
    try {
      await _setupHeaders();
      final response = await _dio.get(
        '/overdue-followups',
        queryParameters: {
          'view': view,
          'limit': limit,
          'skip': skip,
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? [];
        final customers = data
            .map((item) => Customer.fromJson(item as Map<String, dynamic>))
            .toList();

        return ApiResponse(
          success: true,
          message: response.data['message'],
          data: customers,
        );
      } else {
        return ApiResponse(
          success: false,
          message: response.data['message'] ?? 'Failed to fetch overdue followups',
          error: response.data,
        );
      }
    } catch (error) {
      return ApiResponse(
        success: false,
        message: 'Error fetching overdue followups',
        error: error.toString(),
      );
    }
  }

  /// Update customer lead status
  static Future<ApiResponse<Customer>> updateCustomerStatus(
    String customerId, {
    required String leadStatus,
    String? lostReason,
    String? lostReasonNotes,
    String? notes,
  }) async {
    try {
      await _setupHeaders();

      final Dio statusDio = Dio(
        BaseOptions(
          baseUrl: '${ApiConfig.baseUrl}/crm/customers',
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );
      final token = await _getToken();
      if (token != null) {
        statusDio.options.headers['Authorization'] = 'Bearer $token';
      }

      final response = await statusDio.put(
        '/$customerId/status',
        data: {
          'leadStatus': leadStatus,
          if (lostReason != null) 'lostReason': lostReason,
          if (lostReasonNotes != null) 'lostReasonNotes': lostReasonNotes,
          if (notes != null) 'notes': notes,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] as Map<String, dynamic>;
        return ApiResponse(
          success: true,
          message: response.data['message'],
          data: Customer.fromJson(data),
        );
      } else {
        return ApiResponse(
          success: false,
          message: response.data['message'] ?? 'Failed to update status',
          error: response.data,
        );
      }
    } catch (error) {
      return ApiResponse(
        success: false,
        message: 'Error updating customer status',
        error: error.toString(),
      );
    }
  }
}

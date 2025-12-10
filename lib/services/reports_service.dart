import 'package:dio/dio.dart';
import '../config/api_config.dart';
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

class ReportsService {
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: '${ApiConfig.baseUrl}/api/crm/reports',
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

  /// Get sales breakdown by product type
  static Future<ApiResponse<Map<String, dynamic>>> getSalesByProduct({
    String? startDate,
    String? endDate,
    String? branchId,
    String? userId,
  }) async {
    try {
      await _setupHeaders();
      final queryParams = {
        if (startDate != null) 'startDate': startDate,
        if (endDate != null) 'endDate': endDate,
        if (branchId != null) 'branchId': branchId,
        if (userId != null) 'userId': userId,
      };

      final response = await _dio.get(
        '/sales-by-product',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        return ApiResponse(
          success: true,
          message: 'Sales by product fetched successfully',
          data: response.data['data'] as Map<String, dynamic>,
        );
      }

      return ApiResponse(
        success: false,
        message: response.data['message'] ?? 'Failed to fetch sales by product',
      );
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message: e.response?.data['message'] ?? 'Error fetching sales by product',
        error: e,
      );
    }
  }

  /// Get employee performance metrics
  static Future<ApiResponse<List<Map<String, dynamic>>>> getEmployeePerformance({
    String? startDate,
    String? endDate,
    String? branchId,
    String? sortBy,
  }) async {
    try {
      await _setupHeaders();
      final queryParams = {
        if (startDate != null) 'startDate': startDate,
        if (endDate != null) 'endDate': endDate,
        if (branchId != null) 'branchId': branchId,
        if (sortBy != null) 'sortBy': sortBy,
      };

      final response = await _dio.get(
        '/employee-performance',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] as List;
        return ApiResponse(
          success: true,
          message: 'Employee performance fetched successfully',
          data: data.cast<Map<String, dynamic>>(),
        );
      }

      return ApiResponse(
        success: false,
        message: response.data['message'] ?? 'Failed to fetch employee performance',
      );
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message: e.response?.data['message'] ?? 'Error fetching employee performance',
        error: e,
      );
    }
  }

  /// Get visit effectiveness metrics
  static Future<ApiResponse<Map<String, dynamic>>> getVisitEffectiveness({
    String? startDate,
    String? endDate,
    String? branchId,
  }) async {
    try {
      await _setupHeaders();
      final queryParams = {
        if (startDate != null) 'startDate': startDate,
        if (endDate != null) 'endDate': endDate,
        if (branchId != null) 'branchId': branchId,
      };

      final response = await _dio.get(
        '/visit-effectiveness',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        return ApiResponse(
          success: true,
          message: 'Visit effectiveness fetched successfully',
          data: response.data['data'] as Map<String, dynamic>,
        );
      }

      return ApiResponse(
        success: false,
        message: response.data['message'] ?? 'Failed to fetch visit effectiveness',
      );
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message: e.response?.data['message'] ?? 'Error fetching visit effectiveness',
        error: e,
      );
    }
  }

  /// Get branch sales performance
  static Future<ApiResponse<List<Map<String, dynamic>>>> getBranchSales({
    String? startDate,
    String? endDate,
  }) async {
    try {
      await _setupHeaders();
      final queryParams = {
        if (startDate != null) 'startDate': startDate,
        if (endDate != null) 'endDate': endDate,
      };

      final response = await _dio.get(
        '/branch-sales',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] as List;
        return ApiResponse(
          success: true,
          message: 'Branch sales fetched successfully',
          data: data.cast<Map<String, dynamic>>(),
        );
      }

      return ApiResponse(
        success: false,
        message: response.data['message'] ?? 'Failed to fetch branch sales',
      );
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message: e.response?.data['message'] ?? 'Error fetching branch sales',
        error: e,
      );
    }
  }
}

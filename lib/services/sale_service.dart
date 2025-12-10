import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../models/sale.dart';
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

class SaleService {
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: '${ApiConfig.baseUrl}/api/crm/sales',
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

  /// Create a new sale
  static Future<ApiResponse<Sale>> createSale(
    Map<String, dynamic> saleData,
  ) async {
    try {
      await _setupHeaders();
      final response = await _dio.post(
        '/',
        data: saleData,
      );

      if (response.statusCode == 201) {
        final sale = Sale.fromJson(response.data['data']);
        return ApiResponse(
          success: true,
          message: response.data['message'],
          data: sale,
        );
      }

      return ApiResponse(
        success: false,
        message: response.data['message'] ?? 'Failed to create sale',
      );
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message: e.response?.data['message'] ?? 'Error creating sale',
        error: e,
      );
    }
  }

  /// Get sales with filters and pagination
  static Future<ApiResponse<List<Sale>>> getSales({
    int limit = 20,
    int skip = 0,
    String? productType,
    String? status,
    String? customerId,
    String? startDate,
    String? endDate,
    String? branchId,
  }) async {
    try {
      await _setupHeaders();
      final queryParams = {
        'limit': limit,
        'skip': skip,
        if (productType != null) 'productType': productType,
        if (status != null) 'status': status,
        if (customerId != null) 'customerId': customerId,
        if (startDate != null) 'startDate': startDate,
        if (endDate != null) 'endDate': endDate,
        if (branchId != null) 'branchId': branchId,
      };

      final response = await _dio.get(
        '/',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final sales = (response.data['data'] as List)
            .map((s) => Sale.fromJson(s as Map<String, dynamic>))
            .toList();

        return ApiResponse(
          success: true,
          message: 'Sales fetched successfully',
          data: sales,
        );
      }

      return ApiResponse(
        success: false,
        message: response.data['message'] ?? 'Failed to fetch sales',
      );
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message: e.response?.data['message'] ?? 'Error fetching sales',
        error: e,
      );
    }
  }

  /// Get a single sale
  static Future<ApiResponse<Sale>> getSale(String saleId) async {
    try {
      await _setupHeaders();
      final response = await _dio.get('/$saleId');

      if (response.statusCode == 200) {
        final sale = Sale.fromJson(response.data['data']);
        return ApiResponse(
          success: true,
          data: sale,
        );
      }

      return ApiResponse(
        success: false,
        message: response.data['message'] ?? 'Failed to fetch sale',
      );
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message: e.response?.data['message'] ?? 'Error fetching sale',
        error: e,
      );
    }
  }

  /// Update a sale
  static Future<ApiResponse<Sale>> updateSale(
    String saleId,
    Map<String, dynamic> updates,
  ) async {
    try {
      await _setupHeaders();
      final response = await _dio.put(
        '/$saleId',
        data: updates,
      );

      if (response.statusCode == 200) {
        final sale = Sale.fromJson(response.data['data']);
        return ApiResponse(
          success: true,
          message: response.data['message'],
          data: sale,
        );
      }

      return ApiResponse(
        success: false,
        message: response.data['message'] ?? 'Failed to update sale',
      );
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message: e.response?.data['message'] ?? 'Error updating sale',
        error: e,
      );
    }
  }

  /// Delete a sale
  static Future<ApiResponse<void>> deleteSale(String saleId) async {
    try {
      await _setupHeaders();
      final response = await _dio.delete('/$saleId');

      if (response.statusCode == 200) {
        return ApiResponse(
          success: true,
          message: response.data['message'],
        );
      }

      return ApiResponse(
        success: false,
        message: response.data['message'] ?? 'Failed to delete sale',
      );
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message: e.response?.data['message'] ?? 'Error deleting sale',
        error: e,
      );
    }
  }
}

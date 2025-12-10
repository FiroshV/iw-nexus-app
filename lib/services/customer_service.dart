import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../models/customer.dart';
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

class CustomerService {
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: '${ApiConfig.baseUrl}/crm/customers',
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

  /// Create a new customer
  static Future<ApiResponse<Customer>> createCustomer(
    Map<String, dynamic> customerData,
  ) async {
    try {
      await _setupHeaders();
      final response = await _dio.post(
        '/',
        data: customerData,
      );

      if (response.statusCode == 201) {
        final customer = Customer.fromJson(response.data['data']);
        return ApiResponse(
          success: true,
          message: response.data['message'],
          data: customer,
        );
      }

      return ApiResponse(
        success: false,
        message: response.data['message'] ?? 'Failed to create customer',
      );
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message: e.response?.data['message'] ?? 'Error creating customer',
        error: e,
      );
    }
  }

  /// Get customers with filters and pagination
  static Future<ApiResponse<List<Customer>>> getCustomers({
    int limit = 20,
    int skip = 0,
    String? search,
  }) async {
    try {
      await _setupHeaders();
      final queryParams = {
        'limit': limit,
        'skip': skip,
        if (search != null) 'search': search,
      };

      final response = await _dio.get(
        '/',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final customers = (response.data['data'] as List)
            .map((c) => Customer.fromJson(c as Map<String, dynamic>))
            .toList();

        return ApiResponse(
          success: true,
          message: 'Customers fetched successfully',
          data: customers,
        );
      }

      return ApiResponse(
        success: false,
        message: response.data['message'] ?? 'Failed to fetch customers',
      );
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message: e.response?.data['message'] ?? 'Error fetching customers',
        error: e,
      );
    }
  }

  /// Get a single customer
  static Future<ApiResponse<Customer>> getCustomer(String customerId) async {
    try {
      await _setupHeaders();
      final response = await _dio.get('/$customerId');

      if (response.statusCode == 200) {
        final customer = Customer.fromJson(response.data['data']);
        return ApiResponse(
          success: true,
          data: customer,
        );
      }

      return ApiResponse(
        success: false,
        message: response.data['message'] ?? 'Failed to fetch customer',
      );
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message: e.response?.data['message'] ?? 'Error fetching customer',
        error: e,
      );
    }
  }

  /// Get customer timeline (all activities)
  static Future<ApiResponse<Map<String, dynamic>>> getCustomerTimeline(
    String customerId,
  ) async {
    try {
      await _setupHeaders();
      final response = await _dio.get('/$customerId/timeline');

      if (response.statusCode == 200) {
        return ApiResponse(
          success: true,
          data: response.data['data'] as Map<String, dynamic>,
        );
      }

      return ApiResponse(
        success: false,
        message: response.data['message'] ?? 'Failed to fetch timeline',
      );
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message: e.response?.data['message'] ?? 'Error fetching timeline',
        error: e,
      );
    }
  }

  /// Update a customer
  static Future<ApiResponse<Customer>> updateCustomer(
    String customerId,
    Map<String, dynamic> updates,
  ) async {
    try {
      await _setupHeaders();
      final response = await _dio.put(
        '/$customerId',
        data: updates,
      );

      if (response.statusCode == 200) {
        final customer = Customer.fromJson(response.data['data']);
        return ApiResponse(
          success: true,
          message: response.data['message'],
          data: customer,
        );
      }

      return ApiResponse(
        success: false,
        message: response.data['message'] ?? 'Failed to update customer',
      );
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message: e.response?.data['message'] ?? 'Error updating customer',
        error: e,
      );
    }
  }

  /// Delete a customer
  static Future<ApiResponse<void>> deleteCustomer(String customerId) async {
    try {
      await _setupHeaders();
      final response = await _dio.delete('/$customerId');

      if (response.statusCode == 200) {
        return ApiResponse(
          success: true,
          message: response.data['message'],
        );
      }

      return ApiResponse(
        success: false,
        message: response.data['message'] ?? 'Failed to delete customer',
      );
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message: e.response?.data['message'] ?? 'Error deleting customer',
        error: e,
      );
    }
  }
}

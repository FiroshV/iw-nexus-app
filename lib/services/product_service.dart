import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import '../config/api_endpoints.dart';
import '../models/product.dart';
import 'api_service.dart';

class ProductApiResponse<T> {
  final bool success;
  final String? message;
  final T? data;
  final dynamic error;
  final int? total;
  final int? page;
  final int? totalPages;

  ProductApiResponse({
    required this.success,
    this.message,
    this.data,
    this.error,
    this.total,
    this.page,
    this.totalPages,
  });
}

class ProductService {
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: ApiConfig.baseUrl,
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

  /// Get all products with optional filters
  static Future<ProductApiResponse<List<Product>>> getProducts({
    int skip = 0,
    int limit = 50,
    String? category,
    String? companyName,
    String? search,
    bool? isActive,
  }) async {
    try {
      await _setupHeaders();

      final params = <String>[];
      params.add('skip=$skip');
      params.add('limit=$limit');

      if (category != null) params.add('category=${Uri.encodeComponent(category)}');
      if (companyName != null) params.add('companyName=${Uri.encodeComponent(companyName)}');
      if (search != null) params.add('search=${Uri.encodeComponent(search)}');
      if (isActive != null) params.add('isActive=$isActive');

      final endpoint = '${ApiEndpoints.products}?${params.join('&')}';

      final response = await _dio.get(endpoint);

      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> dataList = response.data['data'] ?? [];
        final products = dataList
            .map((json) => Product.fromJson(json as Map<String, dynamic>))
            .toList();

        return ProductApiResponse(
          success: true,
          data: products,
          total: response.data['total'],
          page: response.data['page'],
          totalPages: response.data['totalPages'],
        );
      }

      return ProductApiResponse(
        success: false,
        message: response.data['message'] ?? 'Failed to fetch products',
      );
    } catch (e) {
      debugPrint('ProductService.getProducts error: $e');
      return ProductApiResponse(
        success: false,
        message: 'Error fetching products: ${e.toString()}',
        error: e,
      );
    }
  }

  /// Get products by category
  static Future<ProductApiResponse<List<Product>>> getProductsByCategory(
    String category, {
    bool activeOnly = true,
  }) async {
    try {
      await _setupHeaders();

      final endpoint = '${ApiEndpoints.products}/by-category/$category?activeOnly=$activeOnly';

      final response = await _dio.get(endpoint);

      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> dataList = response.data['data'] ?? [];
        final products = dataList
            .map((json) => Product.fromJson(json as Map<String, dynamic>))
            .toList();

        return ProductApiResponse(
          success: true,
          data: products,
          total: products.length,
        );
      }

      return ProductApiResponse(
        success: false,
        message: response.data['message'] ?? 'Failed to fetch products',
      );
    } catch (e) {
      debugPrint('ProductService.getProductsByCategory error: $e');
      return ProductApiResponse(
        success: false,
        message: 'Error fetching products: ${e.toString()}',
        error: e,
      );
    }
  }

  /// Get all products grouped by category
  static Future<ProductApiResponse<GroupedProducts>> getGroupedProducts() async {
    try {
      await _setupHeaders();

      final endpoint = '${ApiEndpoints.products}/grouped';

      final response = await _dio.get(endpoint);

      if (response.statusCode == 200 && response.data['success'] == true) {
        return ProductApiResponse(
          success: true,
          data: GroupedProducts.fromJson(response.data['data']),
        );
      }

      return ProductApiResponse(
        success: false,
        message: response.data['message'] ?? 'Failed to fetch products',
      );
    } catch (e) {
      debugPrint('ProductService.getGroupedProducts error: $e');
      return ProductApiResponse(
        success: false,
        message: 'Error fetching products: ${e.toString()}',
        error: e,
      );
    }
  }

  /// Get distinct company names
  static Future<ProductApiResponse<List<String>>> getCompanyNames({
    String? category,
  }) async {
    try {
      await _setupHeaders();

      String endpoint = '${ApiEndpoints.products}/companies';
      if (category != null) {
        endpoint = '$endpoint?category=${Uri.encodeComponent(category)}';
      }

      final response = await _dio.get(endpoint);

      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> dataList = response.data['data'] ?? [];
        final companies = dataList.map((e) => e.toString()).toList();

        return ProductApiResponse(
          success: true,
          data: companies,
        );
      }

      return ProductApiResponse(
        success: false,
        message: response.data['message'] ?? 'Failed to fetch companies',
      );
    } catch (e) {
      debugPrint('ProductService.getCompanyNames error: $e');
      return ProductApiResponse(
        success: false,
        message: 'Error fetching companies: ${e.toString()}',
        error: e,
      );
    }
  }

  /// Get single product by ID
  static Future<ProductApiResponse<Product>> getProductById(String productId) async {
    try {
      await _setupHeaders();

      final response = await _dio.get('${ApiEndpoints.products}/$productId');

      if (response.statusCode == 200 && response.data['success'] == true) {
        return ProductApiResponse(
          success: true,
          data: Product.fromJson(response.data['data']),
        );
      }

      return ProductApiResponse(
        success: false,
        message: response.data['message'] ?? 'Product not found',
      );
    } catch (e) {
      debugPrint('ProductService.getProductById error: $e');
      return ProductApiResponse(
        success: false,
        message: 'Error fetching product: ${e.toString()}',
        error: e,
      );
    }
  }

  /// Create a new product
  static Future<ProductApiResponse<Product>> createProduct({
    required String name,
    required String category,
    required String companyName,
    String? description,
    required double commissionRate,
  }) async {
    try {
      await _setupHeaders();

      final data = {
        'name': name,
        'category': category,
        'companyName': companyName,
        'description': description,
        'commissionRate': commissionRate,
      };

      final response = await _dio.post(
        ApiEndpoints.products,
        data: data,
      );

      if (response.statusCode == 201 && response.data['success'] == true) {
        return ProductApiResponse(
          success: true,
          message: response.data['message'] ?? 'Product created successfully',
          data: Product.fromJson(response.data['data']),
        );
      }

      return ProductApiResponse(
        success: false,
        message: response.data['message'] ?? 'Failed to create product',
      );
    } catch (e) {
      String errorMessage = 'Error creating product';
      if (e is DioException && e.response?.data != null) {
        errorMessage = e.response?.data['message'] ?? errorMessage;
      }
      debugPrint('ProductService.createProduct error: $e');
      return ProductApiResponse(
        success: false,
        message: errorMessage,
        error: e,
      );
    }
  }

  /// Update a product
  static Future<ProductApiResponse<Product>> updateProduct({
    required String productId,
    required String name,
    required String category,
    required String companyName,
    String? description,
    required double commissionRate,
    bool? isActive,
  }) async {
    try {
      await _setupHeaders();

      final data = {
        'name': name,
        'category': category,
        'companyName': companyName,
        'description': description,
        'commissionRate': commissionRate,
        if (isActive != null) 'isActive': isActive,
      };

      final response = await _dio.put(
        '${ApiEndpoints.products}/$productId',
        data: data,
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return ProductApiResponse(
          success: true,
          message: response.data['message'] ?? 'Product updated successfully',
          data: Product.fromJson(response.data['data']),
        );
      }

      return ProductApiResponse(
        success: false,
        message: response.data['message'] ?? 'Failed to update product',
      );
    } catch (e) {
      String errorMessage = 'Error updating product';
      if (e is DioException && e.response?.data != null) {
        errorMessage = e.response?.data['message'] ?? errorMessage;
      }
      debugPrint('ProductService.updateProduct error: $e');
      return ProductApiResponse(
        success: false,
        message: errorMessage,
        error: e,
      );
    }
  }

  /// Delete a product
  static Future<ProductApiResponse<void>> deleteProduct(String productId) async {
    try {
      await _setupHeaders();

      final response = await _dio.delete('${ApiEndpoints.products}/$productId');

      if (response.statusCode == 200 && response.data['success'] == true) {
        return ProductApiResponse(
          success: true,
          message: response.data['message'] ?? 'Product deleted successfully',
        );
      }

      return ProductApiResponse(
        success: false,
        message: response.data['message'] ?? 'Failed to delete product',
      );
    } catch (e) {
      String errorMessage = 'Error deleting product';
      if (e is DioException && e.response?.data != null) {
        errorMessage = e.response?.data['message'] ?? errorMessage;
      }
      debugPrint('ProductService.deleteProduct error: $e');
      return ProductApiResponse(
        success: false,
        message: errorMessage,
        error: e,
      );
    }
  }

  /// Toggle product active status
  static Future<ProductApiResponse<Map<String, dynamic>>> toggleProductActive(
    String productId,
  ) async {
    try {
      await _setupHeaders();

      final response = await _dio.patch(
        '${ApiEndpoints.products}/$productId/toggle-active',
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return ProductApiResponse(
          success: true,
          message: response.data['message'],
          data: response.data['data'] as Map<String, dynamic>?,
        );
      }

      return ProductApiResponse(
        success: false,
        message: response.data['message'] ?? 'Failed to toggle product status',
      );
    } catch (e) {
      String errorMessage = 'Error toggling product status';
      if (e is DioException && e.response?.data != null) {
        errorMessage = e.response?.data['message'] ?? errorMessage;
      }
      debugPrint('ProductService.toggleProductActive error: $e');
      return ProductApiResponse(
        success: false,
        message: errorMessage,
        error: e,
      );
    }
  }
}

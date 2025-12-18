import 'dart:io';
import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../models/sale.dart';
import '../models/sale_document.dart';
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
      baseUrl: '${ApiConfig.baseUrl}/crm/sales',
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

  /// Create a new sale with optional document uploads
  static Future<ApiResponse<Sale>> createSale({
    required String customerId,
    required String productType,
    required DateTime dateOfSale,
    required String companyName,
    required String productPlanName,
    double? premiumAmount,
    double? investmentAmount,
    double? sipAmount,
    String? paymentFrequency,
    String? investmentType,
    String? notes,
    List<dynamic>? documents, // PendingDocument
  }) async {
    try {
      await _setupHeaders();

      // Create multipart form data
      final formData = FormData.fromMap({
        'customerId': customerId,
        'productType': productType,
        'dateOfSale': dateOfSale.toIso8601String(),
        'companyName': companyName,
        'productPlanName': productPlanName,
        if (premiumAmount != null) 'premiumAmount': premiumAmount.toString(),
        if (investmentAmount != null) 'investmentAmount': investmentAmount.toString(),
        if (sipAmount != null) 'sipAmount': sipAmount.toString(),
        if (paymentFrequency != null) 'paymentFrequency': paymentFrequency,
        if (investmentType != null) 'investmentType': investmentType,
        if (notes != null) 'notes': notes,
      });

      // Add documents if any
      if (documents != null && documents.isNotEmpty) {
        for (int i = 0; i < documents.length; i++) {
          final doc = documents[i];
          formData.files.add(MapEntry(
            'documents',
            await MultipartFile.fromFile(
              doc.file.path,
              filename: doc.file.path.split('/').last,
            ),
          ));
          formData.fields.add(MapEntry('documentName_$i', doc.documentName));
          formData.fields.add(MapEntry('documentType_$i', doc.documentType));
        }
      }

      final response = await _dio.post(
        '/',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
          sendTimeout: const Duration(seconds: 60),
          receiveTimeout: const Duration(seconds: 60),
        ),
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

  /// Update a sale with optional document uploads
  static Future<ApiResponse<Sale>> updateSale({
    required String saleId,
    String? productType,
    DateTime? dateOfSale,
    String? companyName,
    String? productPlanName,
    double? premiumAmount,
    double? investmentAmount,
    double? sipAmount,
    String? paymentFrequency,
    String? investmentType,
    String? notes,
    List<dynamic>? documents, // PendingDocument
  }) async {
    try {
      await _setupHeaders();

      // Create multipart form data
      final formData = FormData.fromMap({
        if (productType != null) 'productType': productType,
        if (dateOfSale != null) 'dateOfSale': dateOfSale.toIso8601String(),
        if (companyName != null) 'companyName': companyName,
        if (productPlanName != null) 'productPlanName': productPlanName,
        if (premiumAmount != null) 'premiumAmount': premiumAmount.toString(),
        if (investmentAmount != null) 'investmentAmount': investmentAmount.toString(),
        if (sipAmount != null) 'sipAmount': sipAmount.toString(),
        if (paymentFrequency != null) 'paymentFrequency': paymentFrequency,
        if (investmentType != null) 'investmentType': investmentType,
        if (notes != null) 'notes': notes,
      });

      // Add documents if any
      if (documents != null && documents.isNotEmpty) {
        for (int i = 0; i < documents.length; i++) {
          final doc = documents[i];
          formData.files.add(MapEntry(
            'documents',
            await MultipartFile.fromFile(
              doc.file.path,
              filename: doc.file.path.split('/').last,
            ),
          ));
          formData.fields.add(MapEntry('documentName_$i', doc.documentName));
          formData.fields.add(MapEntry('documentType_$i', doc.documentType));
        }
      }

      final response = await _dio.put(
        '/$saleId',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
          sendTimeout: const Duration(seconds: 60),
          receiveTimeout: const Duration(seconds: 60),
        ),
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

  /// Get all documents for a sale
  static Future<ApiResponse<List<SaleDocument>>> getSaleDocuments(
    String saleId,
  ) async {
    try {
      await _setupHeaders();
      final response = await _dio.get(
        '/$saleId/documents',
      );

      if (response.statusCode == 200) {
        final documents = (response.data['data'] as List)
            .map((d) => SaleDocument.fromJson(d as Map<String, dynamic>))
            .toList();

        return ApiResponse(
          success: true,
          data: documents,
        );
      }

      return ApiResponse(
        success: false,
        message: response.data['message'] ?? 'Failed to fetch documents',
      );
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message: e.response?.data['message'] ?? 'Error fetching documents',
        error: e,
      );
    }
  }

  /// Upload a document to a sale
  static Future<ApiResponse<SaleDocument>> uploadSaleDocument(
    String saleId,
    File documentFile, {
    required String documentName,
    required String documentType,
  }) async {
    try {
      await _setupHeaders();

      // Create multipart form data
      final formData = FormData.fromMap({
        'document': await MultipartFile.fromFile(
          documentFile.path,
          filename: documentFile.path.split('/').last,
        ),
        'documentName': documentName,
        'documentType': documentType,
      });

      final response = await _dio.post(
        '/$saleId/documents',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      if (response.statusCode == 201) {
        final document = SaleDocument.fromJson(response.data['data']);
        return ApiResponse(
          success: true,
          message: response.data['message'],
          data: document,
        );
      }

      return ApiResponse(
        success: false,
        message: response.data['message'] ?? 'Failed to upload document',
      );
    } on DioException catch (e) {
      String errorMessage = 'Error uploading document';
      if (e.response != null) {
        errorMessage = e.response?.data['message'] ?? errorMessage;
      } else if (e.type == DioExceptionType.connectionTimeout) {
        errorMessage = 'Upload timeout. Please check your connection.';
      } else if (e.type == DioExceptionType.receiveTimeout) {
        errorMessage = 'Upload timeout. Please try again.';
      }

      return ApiResponse(
        success: false,
        message: errorMessage,
        error: e,
      );
    }
  }

  /// Update document name
  static Future<ApiResponse<SaleDocument>> updateSaleDocument({
    required String saleId,
    required String documentId,
    required String documentName,
  }) async {
    try {
      await _setupHeaders();
      final response = await _dio.put(
        '/$saleId/documents/$documentId',
        data: {
          'documentName': documentName,
        },
      );

      if (response.statusCode == 200) {
        final document = SaleDocument.fromJson(response.data['data']);
        return ApiResponse(
          success: true,
          message: response.data['message'],
          data: document,
        );
      }

      return ApiResponse(
        success: false,
        message: response.data['message'] ?? 'Failed to update document',
      );
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message: e.response?.data['message'] ?? 'Error updating document',
        error: e,
      );
    }
  }

  /// Delete a sale document
  static Future<ApiResponse<void>> deleteSaleDocument(
    String saleId,
    String documentId,
  ) async {
    try {
      await _setupHeaders();
      final response = await _dio.delete(
        '/$saleId/documents/$documentId',
      );

      if (response.statusCode == 200) {
        return ApiResponse(
          success: true,
          message: response.data['message'],
        );
      }

      return ApiResponse(
        success: false,
        message: response.data['message'] ?? 'Failed to delete document',
      );
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message: e.response?.data['message'] ?? 'Error deleting document',
        error: e,
      );
    }
  }

  /// Get document download URL
  static String getSaleDocumentDownloadUrl(String saleId, String documentId) {
    return '${ApiConfig.baseUrl}/crm/sales/$saleId/documents/$documentId';
  }
}

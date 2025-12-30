import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import '../config/api_endpoints.dart';
import '../models/incentive_template.dart';
import '../models/employee_incentive.dart';
import 'api_service.dart';

class ApiResponse<T> {
  final bool success;
  final String? message;
  final T? data;
  final dynamic error;
  final int? total;
  final int? page;
  final int? totalPages;

  ApiResponse({
    required this.success,
    this.message,
    this.data,
    this.error,
    this.total,
    this.page,
    this.totalPages,
  });
}

class IncentiveService {
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

  // =====================
  // TEMPLATE METHODS
  // =====================

  /// Get all incentive templates
  static Future<ApiResponse<List<IncentiveTemplate>>> getTemplates({
    int skip = 0,
    int limit = 50,
    String? search,
    bool? active,
  }) async {
    try {
      await _setupHeaders();

      final endpoint = ApiEndpoints.buildIncentiveTemplatesQuery(
        skip: skip,
        limit: limit,
        search: search,
        active: active,
      );

      final response = await _dio.get(endpoint);

      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> dataList = response.data['data'] ?? [];
        final templates = dataList
            .map((json) => IncentiveTemplate.fromJson(json as Map<String, dynamic>))
            .toList();

        return ApiResponse(
          success: true,
          data: templates,
          total: response.data['total'],
          page: response.data['page'],
          totalPages: response.data['totalPages'],
        );
      }

      return ApiResponse(
        success: false,
        message: response.data['message'] ?? 'Failed to fetch templates',
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Error fetching templates: ${e.toString()}',
        error: e,
      );
    }
  }

  /// Get single template by ID
  static Future<ApiResponse<IncentiveTemplate>> getTemplateById(String templateId) async {
    try {
      await _setupHeaders();

      final response = await _dio.get(
        ApiEndpoints.incentiveTemplateByIdEndpoint(templateId),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return ApiResponse(
          success: true,
          data: IncentiveTemplate.fromJson(response.data['data']),
        );
      }

      return ApiResponse(
        success: false,
        message: response.data['message'] ?? 'Template not found',
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Error fetching template: ${e.toString()}',
        error: e,
      );
    }
  }

  /// Create a new incentive template
  static Future<ApiResponse<IncentiveTemplate>> createTemplate({
    required String name,
    String? description,
    required double lifeInsuranceRate,
    required double generalInsuranceRate,
    required double mutualFundsRate,
    required String targetType,
    double? overallTargetAmount,
    int? lifeInsuranceCountTarget,
    double? lifeInsuranceAmountTarget,
    int? generalInsuranceCountTarget,
    double? generalInsuranceAmountTarget,
    int? mutualFundsCountTarget,
    double? mutualFundsAmountTarget,
    String? nextTemplateId,
  }) async {
    try {
      await _setupHeaders();

      final data = {
        'name': name,
        'description': description,
        'commissionRates': {
          'life_insurance': lifeInsuranceRate,
          'general_insurance': generalInsuranceRate,
          'mutual_funds': mutualFundsRate,
        },
        'targetType': targetType,
        'overallTarget': {
          'amount': overallTargetAmount ?? 0,
        },
        'productTargets': {
          'life_insurance': {
            'count': lifeInsuranceCountTarget ?? 0,
            'amount': lifeInsuranceAmountTarget ?? 0,
          },
          'general_insurance': {
            'count': generalInsuranceCountTarget ?? 0,
            'amount': generalInsuranceAmountTarget ?? 0,
          },
          'mutual_funds': {
            'count': mutualFundsCountTarget ?? 0,
            'amount': mutualFundsAmountTarget ?? 0,
          },
        },
        'nextTemplateId': nextTemplateId,
      };

      final response = await _dio.post(
        ApiEndpoints.incentiveTemplates,
        data: data,
      );

      if (response.statusCode == 201 && response.data['success'] == true) {
        return ApiResponse(
          success: true,
          message: response.data['message'] ?? 'Template created successfully',
          data: IncentiveTemplate.fromJson(response.data['data']),
        );
      }

      return ApiResponse(
        success: false,
        message: response.data['message'] ?? 'Failed to create template',
      );
    } catch (e) {
      String errorMessage = 'Error creating template';
      if (e is DioException && e.response?.data != null) {
        errorMessage = e.response?.data['message'] ?? errorMessage;
      }
      return ApiResponse(
        success: false,
        message: errorMessage,
        error: e,
      );
    }
  }

  /// Update an incentive template
  static Future<ApiResponse<IncentiveTemplate>> updateTemplate({
    required String templateId,
    required String name,
    String? description,
    required double lifeInsuranceRate,
    required double generalInsuranceRate,
    required double mutualFundsRate,
    required String targetType,
    double? overallTargetAmount,
    int? lifeInsuranceCountTarget,
    double? lifeInsuranceAmountTarget,
    int? generalInsuranceCountTarget,
    double? generalInsuranceAmountTarget,
    int? mutualFundsCountTarget,
    double? mutualFundsAmountTarget,
    String? nextTemplateId,
  }) async {
    try {
      await _setupHeaders();

      final data = {
        'name': name,
        'description': description,
        'commissionRates': {
          'life_insurance': lifeInsuranceRate,
          'general_insurance': generalInsuranceRate,
          'mutual_funds': mutualFundsRate,
        },
        'targetType': targetType,
        'overallTarget': {
          'amount': overallTargetAmount ?? 0,
        },
        'productTargets': {
          'life_insurance': {
            'count': lifeInsuranceCountTarget ?? 0,
            'amount': lifeInsuranceAmountTarget ?? 0,
          },
          'general_insurance': {
            'count': generalInsuranceCountTarget ?? 0,
            'amount': generalInsuranceAmountTarget ?? 0,
          },
          'mutual_funds': {
            'count': mutualFundsCountTarget ?? 0,
            'amount': mutualFundsAmountTarget ?? 0,
          },
        },
        'nextTemplateId': nextTemplateId,
      };

      final response = await _dio.put(
        ApiEndpoints.incentiveTemplateByIdEndpoint(templateId),
        data: data,
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return ApiResponse(
          success: true,
          message: response.data['message'] ?? 'Template updated successfully',
          data: IncentiveTemplate.fromJson(response.data['data']),
        );
      }

      return ApiResponse(
        success: false,
        message: response.data['message'] ?? 'Failed to update template',
      );
    } catch (e) {
      String errorMessage = 'Error updating template';
      if (e is DioException && e.response?.data != null) {
        errorMessage = e.response?.data['message'] ?? errorMessage;
      }
      return ApiResponse(
        success: false,
        message: errorMessage,
        error: e,
      );
    }
  }

  /// Delete an incentive template
  static Future<ApiResponse<void>> deleteTemplate(String templateId) async {
    try {
      await _setupHeaders();

      final response = await _dio.delete(
        ApiEndpoints.incentiveTemplateByIdEndpoint(templateId),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return ApiResponse(
          success: true,
          message: response.data['message'] ?? 'Template deleted successfully',
        );
      }

      return ApiResponse(
        success: false,
        message: response.data['message'] ?? 'Failed to delete template',
      );
    } catch (e) {
      String errorMessage = 'Error deleting template';
      if (e is DioException && e.response?.data != null) {
        errorMessage = e.response?.data['message'] ?? errorMessage;
      }
      return ApiResponse(
        success: false,
        message: errorMessage,
        error: e,
      );
    }
  }

  // =====================
  // ASSIGNMENT METHODS
  // =====================

  /// Get all employee incentive assignments
  static Future<ApiResponse<List<EmployeeIncentive>>> getAssignments({
    int skip = 0,
    int limit = 50,
    String? search,
    String? templateId,
    bool? hasPromotion,
  }) async {
    try {
      await _setupHeaders();

      final endpoint = ApiEndpoints.buildIncentiveAssignmentsQuery(
        skip: skip,
        limit: limit,
        search: search,
        templateId: templateId,
        hasPromotion: hasPromotion,
      );

      final response = await _dio.get(endpoint);

      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> dataList = response.data['data'] ?? [];
        final assignments = dataList
            .map((json) => EmployeeIncentive.fromJson(json as Map<String, dynamic>))
            .toList();

        return ApiResponse(
          success: true,
          data: assignments,
          total: response.data['total'],
          page: response.data['page'],
          totalPages: response.data['totalPages'],
        );
      }

      return ApiResponse(
        success: false,
        message: response.data['message'] ?? 'Failed to fetch assignments',
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Error fetching assignments: ${e.toString()}',
        error: e,
      );
    }
  }

  /// Assign incentive template to employee
  static Future<ApiResponse<EmployeeIncentive>> assignIncentive({
    required String userId,
    required String templateId,
  }) async {
    try {
      await _setupHeaders();

      final response = await _dio.post(
        ApiEndpoints.incentiveAssignments,
        data: {
          'userId': userId,
          'templateId': templateId,
        },
      );

      if ((response.statusCode == 200 || response.statusCode == 201) &&
          response.data['success'] == true) {
        return ApiResponse(
          success: true,
          message: response.data['message'] ?? 'Incentive assigned successfully',
          data: EmployeeIncentive.fromJson(response.data['data']),
        );
      }

      return ApiResponse(
        success: false,
        message: response.data['message'] ?? 'Failed to assign incentive',
      );
    } catch (e) {
      String errorMessage = 'Error assigning incentive';
      if (e is DioException && e.response?.data != null) {
        errorMessage = e.response?.data['message'] ?? errorMessage;
      }
      return ApiResponse(
        success: false,
        message: errorMessage,
        error: e,
      );
    }
  }

  /// Get employee's incentive details
  static Future<ApiResponse<EmployeeIncentive>> getEmployeeIncentive(String userId) async {
    try {
      await _setupHeaders();

      final response = await _dio.get(
        ApiEndpoints.incentiveAssignmentByUserIdEndpoint(userId),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return ApiResponse(
          success: true,
          data: EmployeeIncentive.fromJson(response.data['data']),
        );
      }

      return ApiResponse(
        success: false,
        message: response.data['message'] ?? 'No incentive found for this user',
      );
    } catch (e) {
      String errorMessage = 'Error fetching employee incentive';
      if (e is DioException && e.response?.data != null) {
        errorMessage = e.response?.data['message'] ?? errorMessage;
      }
      return ApiResponse(
        success: false,
        message: errorMessage,
        error: e,
      );
    }
  }

  // =====================
  // MY INCENTIVE METHODS
  // =====================

  /// Get current user's incentive
  static Future<ApiResponse<EmployeeIncentive>> getMyIncentive() async {
    try {
      await _setupHeaders();

      debugPrint('🔄 IncentiveService.getMyIncentive: Fetching...');
      final response = await _dio.get(ApiEndpoints.myIncentive);

      debugPrint('📡 IncentiveService.getMyIncentive: Response received');
      debugPrint('   Status: ${response.statusCode}');
      debugPrint('   Success: ${response.data['success']}');
      debugPrint('   Has data: ${response.data['data'] != null}');

      if (response.statusCode == 200 && response.data['success'] == true) {
        if (response.data['data'] == null) {
          debugPrint('⚠️ IncentiveService.getMyIncentive: Backend returned success but null data');
          return ApiResponse(
            success: false,
            message: 'No data returned from server',
          );
        }

        try {
          debugPrint('🔧 IncentiveService.getMyIncentive: Attempting to parse data...');

          final rawData = response.data['data'];
          debugPrint('   Raw data type: ${rawData.runtimeType}');
          debugPrint('   Raw data keys: ${rawData is Map ? rawData.keys.toList() : 'N/A'}');

          final incentive = EmployeeIncentive.fromJson(response.data['data']);

          debugPrint('✅ IncentiveService.getMyIncentive: Parse successful!');
          return ApiResponse(
            success: true,
            data: incentive,
          );
        } catch (parseError, stack) {
          debugPrint('❌ IncentiveService.getMyIncentive: PARSE ERROR');
          debugPrint('   Error Type: ${parseError.runtimeType}');
          debugPrint('   Error Message: $parseError');
          debugPrint('   Stack Trace: $stack');

          return ApiResponse(
            success: false,
            message: 'Failed to parse incentive data: ${parseError.toString()}',
            error: parseError,
          );
        }
      }

      debugPrint('⚠️ IncentiveService.getMyIncentive: Non-success response');
      return ApiResponse(
        success: false,
        message: response.data['message'] ?? 'No incentive assignment found',
      );
    } catch (e, stack) {
      debugPrint('❌ IncentiveService.getMyIncentive: NETWORK/API ERROR');
      debugPrint('   Error: $e');
      debugPrint('   Stack: $stack');

      String errorMessage = 'Error fetching your incentive';
      if (e is DioException) {
        debugPrint('   DioException type: ${e.type}');
        debugPrint('   DioException message: ${e.message}');
        if (e.response?.data != null) {
          errorMessage = e.response?.data['message'] ?? errorMessage;
        }
      }
      return ApiResponse(
        success: false,
        message: errorMessage,
        error: e,
      );
    }
  }

  /// Get current user's monthly progress
  static Future<ApiResponse<Map<String, dynamic>>> getMyProgress({String? month}) async {
    try {
      await _setupHeaders();

      String endpoint = ApiEndpoints.myIncentiveProgress;
      if (month != null) {
        endpoint = '$endpoint?month=$month';
      }

      final response = await _dio.get(endpoint);

      if (response.statusCode == 200 && response.data['success'] == true) {
        return ApiResponse(
          success: true,
          data: response.data['data'] as Map<String, dynamic>,
        );
      }

      return ApiResponse(
        success: false,
        message: response.data['message'] ?? 'Failed to fetch progress',
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Error fetching progress: ${e.toString()}',
        error: e,
      );
    }
  }

  // =====================
  // PROMOTION METHODS
  // =====================

  /// Get pending promotions for approval
  static Future<ApiResponse<List<EmployeeIncentive>>> getPendingPromotions() async {
    try {
      await _setupHeaders();

      final response = await _dio.get(ApiEndpoints.pendingPromotions);

      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> dataList = response.data['data'] ?? [];
        final promotions = dataList
            .map((json) => EmployeeIncentive.fromJson(json as Map<String, dynamic>))
            .toList();

        return ApiResponse(
          success: true,
          data: promotions,
          total: response.data['total'],
        );
      }

      return ApiResponse(
        success: false,
        message: response.data['message'] ?? 'Failed to fetch pending promotions',
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Error fetching pending promotions: ${e.toString()}',
        error: e,
      );
    }
  }

  /// Approve promotion for employee
  static Future<ApiResponse<EmployeeIncentive>> approvePromotion({
    required String userId,
    String? notes,
  }) async {
    try {
      await _setupHeaders();

      final response = await _dio.post(
        ApiEndpoints.approvePromotionEndpoint(userId),
        data: {'notes': notes},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return ApiResponse(
          success: true,
          message: response.data['message'] ?? 'Promotion approved successfully',
          data: EmployeeIncentive.fromJson(response.data['data']),
        );
      }

      return ApiResponse(
        success: false,
        message: response.data['message'] ?? 'Failed to approve promotion',
      );
    } catch (e) {
      String errorMessage = 'Error approving promotion';
      if (e is DioException && e.response?.data != null) {
        errorMessage = e.response?.data['message'] ?? errorMessage;
      }
      return ApiResponse(
        success: false,
        message: errorMessage,
        error: e,
      );
    }
  }

  /// Reject promotion for employee
  static Future<ApiResponse<void>> rejectPromotion({
    required String userId,
    required String notes,
  }) async {
    try {
      await _setupHeaders();

      final response = await _dio.post(
        ApiEndpoints.rejectPromotionEndpoint(userId),
        data: {'notes': notes},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return ApiResponse(
          success: true,
          message: response.data['message'] ?? 'Promotion rejected',
        );
      }

      return ApiResponse(
        success: false,
        message: response.data['message'] ?? 'Failed to reject promotion',
      );
    } catch (e) {
      String errorMessage = 'Error rejecting promotion';
      if (e is DioException && e.response?.data != null) {
        errorMessage = e.response?.data['message'] ?? errorMessage;
      }
      return ApiResponse(
        success: false,
        message: errorMessage,
        error: e,
      );
    }
  }

  // =====================
  // CALCULATION METHODS
  // =====================

  /// Recalculate incentives for a user
  static Future<ApiResponse<Map<String, dynamic>>> recalculateIncentive({
    required String userId,
    String? month,
  }) async {
    try {
      await _setupHeaders();

      final response = await _dio.post(
        ApiEndpoints.calculateIncentiveEndpoint(userId),
        data: {'month': month},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return ApiResponse(
          success: true,
          message: response.data['message'] ?? 'Incentives recalculated',
          data: response.data['data'] as Map<String, dynamic>?,
        );
      }

      return ApiResponse(
        success: false,
        message: response.data['message'] ?? 'Failed to recalculate incentives',
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Error recalculating incentives: ${e.toString()}',
        error: e,
      );
    }
  }
}

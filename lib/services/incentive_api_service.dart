import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'api_service.dart';

/// Service for handling incentive structure API operations
class IncentiveApiService {
  static const String _baseUrl = '/incentives';

  // ==================== TEMPLATES ====================

  /// Get all active incentive templates
  static Future<List<Map<String, dynamic>>> getAllTemplates() async {
    try {
      debugPrint('📥 Fetching all incentive templates...');

      final token = await ApiService.getToken();
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}$_baseUrl/templates'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        List<Map<String, dynamic>> templates = [];

        if (json['data'] is List) {
          templates = List<Map<String, dynamic>>.from(json['data'] as List);
        }

        debugPrint('✅ Loaded ${templates.length} incentive templates');
        return templates;
      }

      debugPrint('⚠️ Failed to fetch templates: ${response.statusCode}');
      return [];
    } catch (e) {
      debugPrint('❌ Error fetching templates: $e');
      return [];
    }
  }

  /// Get single template by ID
  static Future<Map<String, dynamic>?> getTemplateById(String templateId) async {
    try {
      debugPrint('📥 Fetching template: $templateId');

      final token = await ApiService.getToken();
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}$_baseUrl/templates/$templateId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        debugPrint('✅ Loaded template');
        return json['data'] as Map<String, dynamic>;
      }

      debugPrint('⚠️ Template not found: ${response.statusCode}');
      return null;
    } catch (e) {
      debugPrint('❌ Error fetching template: $e');
      return null;
    }
  }

  /// Create a new incentive template
  static Future<Map<String, dynamic>?> createTemplate({
    required String templateName,
    String? description,
    required String structureType,
    List<Map<String, dynamic>>? tiers,
    double? flatPercentage,
    double? fixedAmount,
  }) async {
    try {
      debugPrint('📤 Creating incentive template: $templateName');

      final token = await ApiService.getToken();
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final body = <String, dynamic>{
        'templateName': templateName,
        'description': description,
        'structureType': structureType,
      };

      if (structureType == 'tiered' && tiers != null) {
        body['tiers'] = tiers;
      } else if (structureType == 'flat_percentage' && flatPercentage != null) {
        body['flatPercentage'] = flatPercentage;
      } else if (structureType == 'fixed' && fixedAmount != null) {
        body['fixedAmount'] = fixedAmount;
      }

      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}$_baseUrl/templates'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 201) {
        final json = jsonDecode(response.body);
        debugPrint('✅ Template created successfully');
        return json['data'] as Map<String, dynamic>;
      }

      debugPrint('⚠️ Failed to create template: ${response.statusCode}');
      return null;
    } catch (e) {
      debugPrint('❌ Error creating template: $e');
      return null;
    }
  }

  /// Update an existing template
  static Future<Map<String, dynamic>?> updateTemplate({
    required String templateId,
    String? templateName,
    String? description,
    String? structureType,
    List<Map<String, dynamic>>? tiers,
    double? flatPercentage,
    double? fixedAmount,
    bool? isActive,
  }) async {
    try {
      debugPrint('📤 Updating template: $templateId');

      final token = await ApiService.getToken();
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final body = <String, dynamic>{};
      if (templateName != null) body['templateName'] = templateName;
      if (description != null) body['description'] = description;
      if (structureType != null) body['structureType'] = structureType;
      if (tiers != null) body['tiers'] = tiers;
      if (flatPercentage != null) body['flatPercentage'] = flatPercentage;
      if (fixedAmount != null) body['fixedAmount'] = fixedAmount;
      if (isActive != null) body['isActive'] = isActive;

      final response = await http.put(
        Uri.parse('${ApiService.baseUrl}$_baseUrl/templates/$templateId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        debugPrint('✅ Template updated successfully');
        return json['data'] as Map<String, dynamic>;
      }

      debugPrint('⚠️ Failed to update template: ${response.statusCode}');
      return null;
    } catch (e) {
      debugPrint('❌ Error updating template: $e');
      return null;
    }
  }

  /// Delete a template
  static Future<bool> deleteTemplate(String templateId) async {
    try {
      debugPrint('📤 Deleting template: $templateId');

      final token = await ApiService.getToken();
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final response = await http.delete(
        Uri.parse('${ApiService.baseUrl}$_baseUrl/templates/$templateId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        debugPrint('✅ Template deleted successfully');
        return true;
      }

      debugPrint('⚠️ Failed to delete template: ${response.statusCode}');
      return false;
    } catch (e) {
      debugPrint('❌ Error deleting template: $e');
      return false;
    }
  }

  // ==================== EMPLOYEE INCENTIVES ====================

  /// Get active incentive structure for an employee
  static Future<Map<String, dynamic>?> getEmployeeIncentive(String employeeId) async {
    try {
      debugPrint('📥 Fetching incentive for employee: $employeeId');

      final token = await ApiService.getToken();
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}$_baseUrl/employees/$employeeId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        debugPrint('✅ Loaded employee incentive');
        return json['data'] as Map<String, dynamic>?;
      }

      debugPrint('⚠️ Failed to fetch employee incentive: ${response.statusCode}');
      return null;
    } catch (e) {
      debugPrint('❌ Error fetching employee incentive: $e');
      return null;
    }
  }

  /// Get incentive history for an employee
  static Future<List<Map<String, dynamic>>> getEmployeeIncentiveHistory(
    String employeeId,
  ) async {
    try {
      debugPrint('📥 Fetching incentive history for employee: $employeeId');

      final token = await ApiService.getToken();
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}$_baseUrl/employees/$employeeId/history'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        List<Map<String, dynamic>> history = [];

        if (json['data'] is List) {
          history = List<Map<String, dynamic>>.from(json['data'] as List);
        }

        debugPrint('✅ Loaded ${history.length} history records');
        return history;
      }

      debugPrint('⚠️ Failed to fetch history: ${response.statusCode}');
      return [];
    } catch (e) {
      debugPrint('❌ Error fetching history: $e');
      return [];
    }
  }

  /// Assign a template to an employee
  static Future<Map<String, dynamic>?> assignTemplate({
    required String employeeId,
    required String templateId,
    DateTime? effectiveFrom,
    double? performanceMultiplier,
    String? notes,
  }) async {
    try {
      debugPrint('📤 Assigning template to employee: $employeeId');

      final token = await ApiService.getToken();
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final body = {
        'employeeId': employeeId,
        'templateId': templateId,
        'effectiveFrom': effectiveFrom?.toIso8601String() ?? DateTime.now().toIso8601String(),
        'performanceMultiplier': performanceMultiplier ?? 1.0,
      };

      if (notes != null) {
        body['notes'] = notes;
      }

      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}$_baseUrl/employees/assign-template'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 201) {
        final json = jsonDecode(response.body);
        debugPrint('✅ Template assigned successfully');
        return json['data'] as Map<String, dynamic>;
      }

      debugPrint('⚠️ Failed to assign template: ${response.statusCode}');
      return null;
    } catch (e) {
      debugPrint('❌ Error assigning template: $e');
      return null;
    }
  }

  /// Assign a custom incentive structure to an employee
  static Future<Map<String, dynamic>?> assignCustomStructure({
    required String employeeId,
    required Map<String, dynamic> customStructure,
    DateTime? effectiveFrom,
    double? performanceMultiplier,
    String? notes,
  }) async {
    try {
      debugPrint('📤 Assigning custom structure to employee: $employeeId');

      final token = await ApiService.getToken();
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final body = {
        'employeeId': employeeId,
        'customStructure': customStructure,
        'effectiveFrom': effectiveFrom?.toIso8601String() ?? DateTime.now().toIso8601String(),
        'performanceMultiplier': performanceMultiplier ?? 1.0,
      };

      if (notes != null) {
        body['notes'] = notes;
      }

      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}$_baseUrl/employees/assign-custom'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 201) {
        final json = jsonDecode(response.body);
        debugPrint('✅ Custom structure assigned successfully');
        return json['data'] as Map<String, dynamic>;
      }

      debugPrint('⚠️ Failed to assign custom structure: ${response.statusCode}');
      return null;
    } catch (e) {
      debugPrint('❌ Error assigning custom structure: $e');
      return null;
    }
  }

  /// Bulk assign template to multiple employees
  static Future<Map<String, dynamic>?> bulkAssignTemplate({
    required String templateId,
    List<String>? employeeIds,
    String? role,
    DateTime? effectiveFrom,
    double? performanceMultiplier,
    String? notes,
  }) async {
    try {
      debugPrint('📤 Bulk assigning template...');

      final token = await ApiService.getToken();
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final body = {
        'templateId': templateId,
        'effectiveFrom': effectiveFrom?.toIso8601String() ?? DateTime.now().toIso8601String(),
        'performanceMultiplier': performanceMultiplier ?? 1.0,
      };

      if (employeeIds != null && employeeIds.isNotEmpty) {
        body['employeeIds'] = employeeIds;
      }
      if (role != null) {
        body['role'] = role;
      }
      if (notes != null) {
        body['notes'] = notes;
      }

      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}$_baseUrl/bulk-assign'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 201) {
        final json = jsonDecode(response.body);
        debugPrint('✅ Bulk assignment completed');
        return json['data'] as Map<String, dynamic>;
      }

      debugPrint('⚠️ Bulk assignment failed: ${response.statusCode}');
      return null;
    } catch (e) {
      debugPrint('❌ Error bulk assigning: $e');
      return null;
    }
  }

  /// Update performance multiplier for an employee
  static Future<Map<String, dynamic>?> updatePerformanceMultiplier({
    required String employeeId,
    required double performanceMultiplier,
    String? notes,
  }) async {
    try {
      debugPrint('📤 Updating performance multiplier for employee: $employeeId');

      final token = await ApiService.getToken();
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final body = <String, dynamic>{
        'performanceMultiplier': performanceMultiplier,
      };

      if (notes != null) {
        body['notes'] = notes;
      }

      final response = await http.put(
        Uri.parse('${ApiService.baseUrl}$_baseUrl/employees/$employeeId/performance-multiplier'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        debugPrint('✅ Performance multiplier updated');
        return json['data'] as Map<String, dynamic>;
      }

      debugPrint('⚠️ Failed to update multiplier: ${response.statusCode}');
      return null;
    } catch (e) {
      debugPrint('❌ Error updating multiplier: $e');
      return null;
    }
  }

  /// Remove incentive structure from an employee
  static Future<bool> removeEmployeeIncentive(String employeeId) async {
    try {
      debugPrint('📤 Removing incentive for employee: $employeeId');

      final token = await ApiService.getToken();
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final response = await http.delete(
        Uri.parse('${ApiService.baseUrl}$_baseUrl/employees/$employeeId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        debugPrint('✅ Incentive removed successfully');
        return true;
      }

      debugPrint('⚠️ Failed to remove incentive: ${response.statusCode}');
      return false;
    } catch (e) {
      debugPrint('❌ Error removing incentive: $e');
      return false;
    }
  }

  // ==================== ANALYTICS ====================

  /// Get all employees with their incentives (Admin/Director view)
  static Future<List<Map<String, dynamic>>> getAllEmployeesWithIncentives({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      debugPrint('📥 Fetching employees with incentives (page: $page)...');

      final token = await ApiService.getToken();
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}$_baseUrl/list/all-employees?page=$page&limit=$limit'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        List<Map<String, dynamic>> employees = [];

        if (json['data'] is List) {
          employees = List<Map<String, dynamic>>.from(json['data'] as List);
        }

        debugPrint('✅ Loaded ${employees.length} employees');
        return employees;
      }

      debugPrint('⚠️ Failed to fetch employees: ${response.statusCode}');
      return [];
    } catch (e) {
      debugPrint('❌ Error fetching employees: $e');
      return [];
    }
  }
}

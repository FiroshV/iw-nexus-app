import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'api_service.dart';

/// Service for handling salary template API operations
class SalaryTemplateApiService {
  static const String _baseUrl = '/payroll/salary-templates';

  /// Get all active salary templates
  static Future<List<Map<String, dynamic>>> getAllTemplates() async {
    try {
      debugPrint('📥 Fetching all salary templates...');

      final token = await ApiService.getToken();
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}$_baseUrl'),
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

        debugPrint('✅ Loaded ${templates.length} salary templates');
        return templates;
      }

      debugPrint('⚠️ Failed to fetch salary templates: ${response.statusCode}');
      return [];
    } catch (e) {
      debugPrint('❌ Error fetching salary templates: $e');
      return [];
    }
  }

  /// Get default salary template
  static Future<Map<String, dynamic>?> getDefaultTemplate() async {
    try {
      debugPrint('📥 Fetching default salary template...');

      final token = await ApiService.getToken();
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}$_baseUrl/default'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final template = json['data'] as Map<String, dynamic>;
        debugPrint('✅ Loaded default template: ${template['templateName']}');
        return template;
      }

      debugPrint('⚠️ No default template found');
      return null;
    } catch (e) {
      debugPrint('❌ Error fetching default template: $e');
      return null;
    }
  }

  /// Get single salary template by ID
  static Future<Map<String, dynamic>?> getTemplateById(String templateId) async {
    try {
      debugPrint('📥 Fetching salary template: $templateId');

      final token = await ApiService.getToken();
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}$_baseUrl/$templateId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final template = json['data'] as Map<String, dynamic>;
        debugPrint('✅ Loaded template: ${template['templateName']}');
        return template;
      }

      debugPrint('⚠️ Template not found: $templateId');
      return null;
    } catch (e) {
      debugPrint('❌ Error fetching template: $e');
      return null;
    }
  }

  /// Create new salary template
  static Future<Map<String, dynamic>?> createTemplate({
    required String templateName,
    required Map<String, double> percentages,
    Map<String, double>? deductions,
    bool isDefault = false,
  }) async {
    try {
      debugPrint('📤 Creating salary template: $templateName');

      // Validate percentages
      final total = percentages.values.fold(0.0, (a, b) => a + b);
      if ((total - 100).abs() > 0.01) {
        debugPrint('❌ Invalid percentages: total = $total (must be 100)');
        return null;
      }

      final token = await ApiService.getToken();
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final data = {
        'templateName': templateName,
        'percentages': {
          'basic': percentages['basic'] ?? 0.0,
          'hra': percentages['hra'] ?? 0.0,
          'da': percentages['da'] ?? 0.0,
          'conveyance': percentages['conveyance'] ?? 0.0,
          'specialAllowance': percentages['specialAllowance'] ?? 0.0,
          'otherAllowances': percentages['otherAllowances'] ?? 0.0,
        },
        'deductions': {
          'pfEmployee': deductions?['pfEmployee'] ?? 0.0,
          'pfEmployer': deductions?['pfEmployer'] ?? 0.0,
          'esiEmployee': deductions?['esiEmployee'] ?? 0.0,
          'esiEmployer': deductions?['esiEmployer'] ?? 0.0,
          'professionalTax': deductions?['professionalTax'] ?? 0.0,
          'tds': deductions?['tds'] ?? 0.0,
        },
        'isDefault': isDefault,
      };

      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}$_baseUrl'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 201 || response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final template = json['data'] as Map<String, dynamic>;
        debugPrint('✅ Salary template created: $templateName');
        return template;
      }

      // Parse error response
      debugPrint('❌ Failed to create template: ${response.statusCode}');
      try {
        final errorJson = jsonDecode(response.body);
        final errorMessage = errorJson['message'] ?? 'Unknown error';
        final errorCode = errorJson['errorCode'] ?? 'UNKNOWN';

        // Throw exception with error code for frontend parsing
        throw Exception('$errorCode|$errorMessage');
      } catch (e) {
        throw Exception('UNKNOWN|Failed to create template: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error creating template: $e');
      rethrow;
    }
  }

  /// Update salary template
  static Future<Map<String, dynamic>?> updateTemplate({
    required String templateId,
    String? templateName,
    Map<String, double>? percentages,
    Map<String, double>? deductions,
    bool? isDefault,
    bool? isActive,
  }) async {
    try {
      debugPrint('📤 Updating salary template: $templateId');

      // Validate percentages if provided
      if (percentages != null) {
        final total = percentages.values.fold(0.0, (a, b) => a + b);
        if ((total - 100).abs() > 0.01) {
          debugPrint('❌ Invalid percentages: total = $total (must be 100)');
          return null;
        }
      }

      final token = await ApiService.getToken();
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final data = <String, dynamic>{};
      if (templateName != null) data['templateName'] = templateName;
      if (percentages != null) {
        data['percentages'] = {
          'basic': percentages['basic'] ?? 0.0,
          'hra': percentages['hra'] ?? 0.0,
          'da': percentages['da'] ?? 0.0,
          'conveyance': percentages['conveyance'] ?? 0.0,
          'specialAllowance': percentages['specialAllowance'] ?? 0.0,
          'otherAllowances': percentages['otherAllowances'] ?? 0.0,
        };
      }
      if (deductions != null) {
        data['deductions'] = {
          'pfEmployee': deductions['pfEmployee'] ?? 0.0,
          'pfEmployer': deductions['pfEmployer'] ?? 0.0,
          'esiEmployee': deductions['esiEmployee'] ?? 0.0,
          'esiEmployer': deductions['esiEmployer'] ?? 0.0,
          'professionalTax': deductions['professionalTax'] ?? 0.0,
          'tds': deductions['tds'] ?? 0.0,
        };
      }
      if (isDefault != null) data['isDefault'] = isDefault;
      if (isActive != null) data['isActive'] = isActive;

      final response = await http.put(
        Uri.parse('${ApiService.baseUrl}$_baseUrl/$templateId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final template = json['data'] as Map<String, dynamic>;
        debugPrint('✅ Salary template updated: $templateId');
        return template;
      }

      // Parse error response
      debugPrint('❌ Failed to update template: ${response.statusCode}');
      try {
        final errorJson = jsonDecode(response.body);
        final errorMessage = errorJson['message'] ?? 'Unknown error';
        final errorCode = errorJson['errorCode'] ?? 'UNKNOWN';

        // Throw exception with error code for frontend parsing
        throw Exception('$errorCode|$errorMessage');
      } catch (e) {
        throw Exception('UNKNOWN|Failed to update template: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error updating template: $e');
      rethrow;
    }
  }

  /// Delete salary template
  static Future<bool> deleteTemplate(String templateId) async {
    try {
      debugPrint('📤 Deleting salary template: $templateId');

      final token = await ApiService.getToken();
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final response = await http.delete(
        Uri.parse('${ApiService.baseUrl}$_baseUrl/$templateId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        debugPrint('✅ Salary template deleted: $templateId');
        return true;
      }

      debugPrint('❌ Failed to delete template: ${response.statusCode}');
      return false;
    } catch (e) {
      debugPrint('❌ Error deleting template: $e');
      return false;
    }
  }

  /// Set template as default
  static Future<bool> setAsDefault(String templateId) async {
    try {
      debugPrint('📤 Setting template as default: $templateId');

      final token = await ApiService.getToken();
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}$_baseUrl/$templateId/set-default'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({}),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        debugPrint('✅ Template set as default: $templateId');
        return true;
      }

      debugPrint('❌ Failed to set default template: ${response.statusCode}');
      return false;
    } catch (e) {
      debugPrint('❌ Error setting default template: $e');
      return false;
    }
  }

  /// Calculate salary components from CTC using template percentages
  static Map<String, double> calculateFromCTC({
    required double ctc,
    required Map<String, double> percentages,
  }) {
    return {
      'basic': (ctc * (percentages['basic'] ?? 40)) / 100,
      'hra': (ctc * (percentages['hra'] ?? 30)) / 100,
      'da': (ctc * (percentages['da'] ?? 10)) / 100,
      'conveyance': (ctc * (percentages['conveyance'] ?? 5)) / 100,
      'specialAllowance': (ctc * (percentages['specialAllowance'] ?? 15)) / 100,
      'otherAllowances': (ctc * (percentages['otherAllowances'] ?? 0)) / 100,
    };
  }

  /// Validate percentages total to 100
  static bool validatePercentages(Map<String, double> percentages) {
    final total = percentages.values.fold(0.0, (a, b) => a + b);
    return (total - 100).abs() <= 0.01;
  }

  /// Get total percentage from percentages map
  static double getTotalPercentage(Map<String, double> percentages) {
    return percentages.values.fold(0.0, (a, b) => a + b);
  }
}

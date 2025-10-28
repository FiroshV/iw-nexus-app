import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';

/// Payroll API Service for managing payroll operations
///
/// This service handles all payroll-related API requests including:
/// - Company settings management
/// - Salary structure operations
/// - Payslip generation and retrieval
class PayrollApiService {
  /// Get company payroll settings
  static Future<Map<String, dynamic>> getCompanySettings() async {
    try {
      final token = await ApiService.getToken();
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/payroll/company-settings'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return json['data'] ?? {};
      } else {
        throw Exception('Failed to fetch company settings: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Update company payroll settings
  static Future<Map<String, dynamic>> updateCompanySettings(
      Map<String, dynamic> settings) async {
    try {
      final token = await ApiService.getToken();
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/payroll/company-settings'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(settings),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return json['data'] ?? {};
      } else {
        throw Exception('Failed to update company settings: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Get salary structure for a specific user
  static Future<Map<String, dynamic>?> getSalaryStructure(String userId) async {
    try {
      final token = await ApiService.getToken();
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/payroll/salary-structure/$userId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return json['data'];
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception('Failed to fetch salary structure: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Update salary structure for a user
  static Future<Map<String, dynamic>> updateSalaryStructure(
      String userId, Map<String, dynamic> salaryData) async {
    try {
      final token = await ApiService.getToken();
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/payroll/salary-structure/$userId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(salaryData),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return json['data'] ?? {};
      } else {
        throw Exception('Failed to update salary structure: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Get all salary structures
  static Future<List<Map<String, dynamic>>> getSalaryStructures() async {
    try {
      final token = await ApiService.getToken();
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/payroll/salary-structures'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final data = json['data'] as List?;
        return data?.cast<Map<String, dynamic>>() ?? [];
      } else {
        throw Exception('Failed to fetch salary structures: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Generate payslip for a user
  static Future<Map<String, dynamic>> generatePayslip(
      Map<String, dynamic> payslipData) async {
    try {
      final token = await ApiService.getToken();
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/payroll/generate-payslip'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payslipData),
      ).timeout(const Duration(seconds: 60)); // Longer timeout for PDF generation

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return json['data'] ?? {};
      } else {
        throw Exception('Failed to generate payslip: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Get payslips for the current user
  static Future<List<Map<String, dynamic>>> getMyPayslips({int page = 1, int limit = 10}) async {
    try {
      final token = await ApiService.getToken();
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/payroll/payslips?page=$page&limit=$limit'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final data = json['data'] as List?;
        return data?.cast<Map<String, dynamic>>() ?? [];
      } else {
        throw Exception('Failed to fetch payslips: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Get payslips for a specific user (admin/director/manager)
  static Future<List<Map<String, dynamic>>> getUserPayslips(
      String userId, {int page = 1, int limit = 10}) async {
    try {
      final token = await ApiService.getToken();
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/payroll/payslips/all?employeeId=$userId&page=$page&limit=$limit'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final data = json['data'] as List?;
        return data?.cast<Map<String, dynamic>>() ?? [];
      } else {
        throw Exception('Failed to fetch user payslips: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Get a specific payslip by ID
  static Future<Map<String, dynamic>?> getPayslip(String payslipId) async {
    try {
      final token = await ApiService.getToken();
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/payroll/payslips/$payslipId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return json['data'];
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception('Failed to fetch payslip: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Generate payslips for multiple employees (bulk operation)
  static Future<Map<String, dynamic>> generatePayslips(
      Map<String, dynamic> data) async {
    try {
      final token = await ApiService.getToken();
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/payroll/generate'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(data),
      ).timeout(const Duration(minutes: 5)); // Long timeout for bulk generation

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return json['data'] ?? {};
      } else {
        throw Exception('Failed to generate payslips: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Calculate payslip preview (for viewing before generation)
  /// Takes userId, month, year, and optional overrides
  static Future<Map<String, dynamic>> calculatePayslipPreview({
    required String userId,
    required int month,
    required int year,
    Map<String, dynamic>? overrides,
  }) async {
    try {
      final token = await ApiService.getToken();
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final body = jsonEncode({
        'userId': userId,
        'month': month,
        'year': year,
        if (overrides != null) 'overrides': overrides,
      });

      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/payroll/calculate-payslip-preview'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: body,
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return json['data'] ?? {};
      } else {
        throw Exception('Failed to calculate payslip preview: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Get all payslips for a specific month/year
  /// Used to show which employees already have generated payslips
  static Future<List<Map<String, dynamic>>> getPayslipsForMonth({
    required int month,
    required int year,
  }) async {
    try {
      final token = await ApiService.getToken();
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/payroll/payslips-by-month/$year/$month'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final data = json['data'] as List?;
        return data?.cast<Map<String, dynamic>>() ?? [];
      } else {
        throw Exception('Failed to fetch payslips for month: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Send payslip email to single employee
  static Future<Map<String, dynamic>> sendPayslipEmail(String payslipId, {String? email}) async {
    try {
      final token = await ApiService.getToken();
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final body = email != null ? jsonEncode({'email': email}) : '';

      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/payroll/payslips/$payslipId/send-email'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: body,
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return json['data'] ?? {};
      } else {
        throw Exception('Failed to send payslip email: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Send payslips to all employees for a month
  static Future<Map<String, dynamic>> sendBulkPayslipEmails(int year, int month, {List<String>? employeeIds}) async {
    try {
      final token = await ApiService.getToken();
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final body = jsonEncode({'employeeIds': employeeIds ?? []});

      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/payroll/send-emails/$year/$month'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: body,
      ).timeout(const Duration(minutes: 5));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return json['data'] ?? {};
      } else {
        throw Exception('Failed to send bulk emails: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Download payslip PDF
  static Future<String> downloadPayslip(String pdfUrl) async {
    // Return the PDF URL - the frontend can open it in browser or download
    return pdfUrl;
  }

  /// Format currency for display (Indian rupee format)
  static String formatCurrency(double amount) {
    final formatted = amount.toStringAsFixed(2);
    final parts = formatted.split('.');
    final intPart = parts[0];
    final decPart = parts[1];

    // Indian number formatting (lakhs, crores)
    if (intPart.length <= 3) {
      return '₹$intPart.$decPart';
    }

    String result = '';
    int count = 0;
    for (int i = intPart.length - 1; i >= 0; i--) {
      if (count == 3 || (count > 3 && (count - 3) % 2 == 0)) {
        result = ',$result';
      }
      result = intPart[i] + result;
      count++;
    }

    return '₹$result.$decPart';
  }

  /// Get month name from month number
  static String getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return months[month - 1];
  }

  /// Get previous month and year
  static Map<String, int> getPreviousMonth() {
    final now = DateTime.now();
    final previousMonth = DateTime(now.year, now.month - 1);
    return {
      'month': previousMonth.month,
      'year': previousMonth.year,
    };
  }

  /// Get month short name from month number
  static String getMonthShortName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }
}

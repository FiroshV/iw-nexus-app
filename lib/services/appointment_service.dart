import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../models/appointment.dart';
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

class AppointmentService {
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: '${ApiConfig.baseUrl}/crm/appointments',
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

  /// Create a new appointment
  static Future<ApiResponse<Appointment>> createAppointment(
    Map<String, dynamic> appointmentData,
  ) async {
    try {
      await _setupHeaders();
      final response = await _dio.post(
        '/',
        data: appointmentData,
      );

      if (response.statusCode == 201) {
        try {
          final data = response.data?['data'];
          if (data == null) {
            return ApiResponse(
              success: false,
              message: 'Invalid response: missing appointment data',
            );
          }
          final appointment = Appointment.fromJson(data as Map<String, dynamic>);
          return ApiResponse(
            success: true,
            message: response.data?['message'],
            data: appointment,
          );
        } catch (e) {
          return ApiResponse(
            success: false,
            message: 'Error parsing appointment: ${e.toString()}',
            error: e,
          );
        }
      }

      return ApiResponse(
        success: false,
        message: response.data?['message'] ?? 'Failed to create appointment',
      );
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message: e.response?.data?['message'] ?? 'Error creating appointment',
        error: e,
      );
    }
  }

  /// Get appointments with filters and pagination
  static Future<ApiResponse<List<Appointment>>> getAppointments({
    int limit = 20,
    int skip = 0,
    String? startDate,
    String? endDate,
    String? status,
    String? employeeId,
    String? customerId,
    String view = 'assigned',
  }) async {
    try {
      await _setupHeaders();
      final queryParams = {
        'limit': limit,
        'skip': skip,
        'view': view,
        if (startDate != null) 'startDate': startDate,
        if (endDate != null) 'endDate': endDate,
        if (status != null) 'status': status,
        if (employeeId != null) 'employeeId': employeeId,
        if (customerId != null) 'customerId': customerId,
      };

      final response = await _dio.get(
        '/',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        try {
          // Safely extract data from response
          final data = response.data;
          if (data == null || data['data'] == null) {
            return ApiResponse(
              success: true,
              message: 'Appointments fetched successfully',
              data: [],
            );
          }

          final appointmentList = data['data'] as List?;
          if (appointmentList == null) {
            return ApiResponse(
              success: true,
              message: 'Appointments fetched successfully',
              data: [],
            );
          }

          final appointments = appointmentList
              .map((a) => Appointment.fromJson(a as Map<String, dynamic>))
              .toList();

          return ApiResponse(
            success: true,
            message: 'Appointments fetched successfully',
            data: appointments,
          );
        } catch (e) {
          return ApiResponse(
            success: false,
            message: 'Error parsing appointments: ${e.toString()}',
            error: e,
          );
        }
      }

      return ApiResponse(
        success: false,
        message: response.data?['message'] ?? 'Failed to fetch appointments',
      );
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message: e.response?.data?['message'] ?? 'Error fetching appointments',
        error: e,
      );
    }
  }

  /// Get a single appointment
  static Future<ApiResponse<Appointment>> getAppointment(String appointmentId) async {
    try {
      await _setupHeaders();
      final response = await _dio.get('/$appointmentId');

      if (response.statusCode == 200) {
        try {
          final data = response.data?['data'];
          if (data == null) {
            return ApiResponse(
              success: false,
              message: 'Invalid response: missing appointment data',
            );
          }
          final appointment = Appointment.fromJson(data as Map<String, dynamic>);
          return ApiResponse(
            success: true,
            data: appointment,
          );
        } catch (e) {
          return ApiResponse(
            success: false,
            message: 'Error parsing appointment: ${e.toString()}',
            error: e,
          );
        }
      }

      return ApiResponse(
        success: false,
        message: response.data?['message'] ?? 'Failed to fetch appointment',
      );
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message: e.response?.data?['message'] ?? 'Error fetching appointment',
        error: e,
      );
    }
  }

  /// Update an appointment
  static Future<ApiResponse<Appointment>> updateAppointment(
    String appointmentId,
    Map<String, dynamic> updates,
  ) async {
    try {
      await _setupHeaders();
      final response = await _dio.put(
        '/$appointmentId',
        data: updates,
      );

      if (response.statusCode == 200) {
        try {
          final data = response.data?['data'];
          if (data == null) {
            return ApiResponse(
              success: false,
              message: 'Invalid response: missing appointment data',
            );
          }
          final appointment = Appointment.fromJson(data as Map<String, dynamic>);
          return ApiResponse(
            success: true,
            message: response.data?['message'],
            data: appointment,
          );
        } catch (e) {
          return ApiResponse(
            success: false,
            message: 'Error parsing appointment: ${e.toString()}',
            error: e,
          );
        }
      }

      return ApiResponse(
        success: false,
        message: response.data?['message'] ?? 'Failed to update appointment',
      );
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message: e.response?.data?['message'] ?? 'Error updating appointment',
        error: e,
      );
    }
  }

  /// Delete an appointment
  static Future<ApiResponse<void>> deleteAppointment(String appointmentId) async {
    try {
      await _setupHeaders();
      final response = await _dio.delete('/$appointmentId');

      if (response.statusCode == 200) {
        return ApiResponse(
          success: true,
          message: response.data?['message'],
        );
      }

      return ApiResponse(
        success: false,
        message: response.data?['message'] ?? 'Failed to delete appointment',
      );
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message: e.response?.data?['message'] ?? 'Error deleting appointment',
        error: e,
      );
    }
  }

  /// Complete an appointment
  static Future<ApiResponse<Appointment>> completeAppointment(
    String appointmentId,
    Map<String, dynamic> completionData,
  ) async {
    try {
      await _setupHeaders();
      final response = await _dio.post(
        '/$appointmentId/complete',
        data: completionData,
      );

      if (response.statusCode == 200) {
        try {
          final data = response.data?['data'];
          if (data == null) {
            return ApiResponse(
              success: false,
              message: 'Invalid response: missing appointment data',
            );
          }
          final appointment = Appointment.fromJson(data as Map<String, dynamic>);
          return ApiResponse(
            success: true,
            message: response.data?['message'],
            data: appointment,
          );
        } catch (e) {
          return ApiResponse(
            success: false,
            message: 'Error parsing appointment: ${e.toString()}',
            error: e,
          );
        }
      }

      return ApiResponse(
        success: false,
        message: response.data?['message'] ?? 'Failed to complete appointment',
      );
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message: e.response?.data?['message'] ?? 'Error completing appointment',
        error: e,
      );
    }
  }

  /// Cancel an appointment
  static Future<ApiResponse<Appointment>> cancelAppointment(
    String appointmentId,
  ) async {
    try {
      await _setupHeaders();
      final response = await _dio.post(
        '/$appointmentId/cancel',
      );

      if (response.statusCode == 200) {
        try {
          final data = response.data?['data'];
          if (data == null) {
            return ApiResponse(
              success: false,
              message: 'Invalid response: missing appointment data',
            );
          }
          final appointment = Appointment.fromJson(data as Map<String, dynamic>);
          return ApiResponse(
            success: true,
            message: response.data?['message'],
            data: appointment,
          );
        } catch (e) {
          return ApiResponse(
            success: false,
            message: 'Error parsing appointment: ${e.toString()}',
            error: e,
          );
        }
      }

      return ApiResponse(
        success: false,
        message: response.data?['message'] ?? 'Failed to cancel appointment',
      );
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message: e.response?.data?['message'] ?? 'Error cancelling appointment',
        error: e,
      );
    }
  }

  /// Check employee availability
  static Future<ApiResponse<Map<String, dynamic>>> checkAvailability({
    required List<String> employeeIds,
    required DateTime scheduledDate,
    required TimeSlot timeSlot,
    String? excludeAppointmentId,
  }) async {
    try {
      await _setupHeaders();
      final response = await _dio.post(
        '/availability/check',
        data: {
          'employeeIds': employeeIds,
          'scheduledDate': scheduledDate.toIso8601String(),
          'scheduledTimeSlot': timeSlot.toJson(),
          if (excludeAppointmentId != null) 'excludeAppointmentId': excludeAppointmentId,
        },
      );

      if (response.statusCode == 200) {
        return ApiResponse(
          success: true,
          data: response.data as Map<String, dynamic>,
        );
      }

      return ApiResponse(
        success: false,
        message: response.data['message'] ?? 'Failed to check availability',
      );
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message: e.response?.data['message'] ?? 'Error checking availability',
        error: e,
      );
    }
  }

  /// Get employee's schedule for a date
  static Future<ApiResponse<Map<String, dynamic>>> getEmployeeSchedule(
    String employeeId,
    DateTime date,
  ) async {
    try {
      await _setupHeaders();
      final response = await _dio.get(
        '/employee-schedule/$employeeId',
        queryParameters: {
          'date': date.toIso8601String(),
        },
      );

      if (response.statusCode == 200) {
        try {
          final data = response.data?['data'];
          if (data == null) {
            return ApiResponse(
              success: false,
              message: 'Invalid response: missing schedule data',
            );
          }
          return ApiResponse(
            success: true,
            data: data as Map<String, dynamic>,
          );
        } catch (e) {
          return ApiResponse(
            success: false,
            message: 'Error parsing schedule: ${e.toString()}',
            error: e,
          );
        }
      }

      return ApiResponse(
        success: false,
        message: response.data?['message'] ?? 'Failed to fetch schedule',
      );
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message: e.response?.data?['message'] ?? 'Error fetching schedule',
        error: e,
      );
    }
  }
}

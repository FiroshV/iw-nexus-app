import 'package:flutter/foundation.dart';
import 'package:timezone/timezone.dart' as tz;
import 'api_service.dart';
import 'location_service.dart';
import '../utils/timezone_util.dart';

/// Result of an attendance action (clock-in/clock-out)
class AttendanceActionResult {
  final bool success;
  final String message;
  final bool requiresLateReason;
  final int lateByMinutes;
  final bool canOpenSettings;
  final Map<String, dynamic>? data;

  AttendanceActionResult({
    required this.success,
    required this.message,
    this.requiresLateReason = false,
    this.lateByMinutes = 0,
    this.canOpenSettings = false,
    this.data,
  });
}

/// Shared service for attendance clock-in/clock-out actions.
/// Used by both DashboardAttendanceStrip and EnhancedAttendanceScreen.
class AttendanceActionService {
  final LocationService _locationService = LocationService();

  /// Pre-fetch location for faster clock-in
  void preFetchLocation() {
    _locationService.preFetchLocation();
  }

  /// Perform clock-in. Returns result indicating success, failure, or need for late reason.
  Future<AttendanceActionResult> clockIn({String? lateReason}) async {
    try {
      final locationResult = await _locationService.getCurrentPosition();

      if (!locationResult.success) {
        return AttendanceActionResult(
          success: false,
          message: locationResult.message,
          canOpenSettings: locationResult.canOpenSettings,
        );
      }

      final position = locationResult.position!;
      final locationMap = _locationService.positionToMap(position);

      var response = await ApiService.checkIn(
        location: locationMap,
        notes: 'Clock-in from phone app',
        lateReason: lateReason,
      );

      // Check if late reason is required
      bool requiresLateReason = false;
      int lateByMinutes = 0;

      if (!response.success && response.data?['requiresReason'] == true) {
        requiresLateReason = true;
        lateByMinutes = response.data?['lateBy'] ?? 0;
      } else if (!response.success &&
          response.message.toLowerCase().contains('late reason is required')) {
        requiresLateReason = true;
        lateByMinutes = _calculateClientSideLateMinutes();
      } else if (!response.success &&
          response.statusCode == 400 &&
          (response.message.contains('work hours') ||
              response.message.contains('late'))) {
        requiresLateReason = true;
        lateByMinutes = _calculateClientSideLateMinutes();
      }

      if (requiresLateReason && lateReason == null) {
        return AttendanceActionResult(
          success: false,
          message: 'Late reason required',
          requiresLateReason: true,
          lateByMinutes: lateByMinutes,
        );
      }

      if (response.success) {
        final lateBy = response.data?['lateBy'] ?? 0;
        String successMessage = 'Clocked in successfully!';
        if (lateBy > 0) {
          successMessage = 'Clocked in successfully';
        }
        return AttendanceActionResult(
          success: true,
          message: successMessage,
          data: response.data,
        );
      } else {
        String errorMessage = response.message;
        if (response.data is Map && response.data?['requiresReason'] == true) {
          errorMessage =
              'Failed to process late clock-in. Please check your connection and try again.';
        }
        return AttendanceActionResult(
          success: false,
          message: errorMessage,
        );
      }
    } catch (e) {
      return AttendanceActionResult(
        success: false,
        message: 'Clock in failed: $e',
      );
    }
  }

  /// Perform clock-out
  Future<AttendanceActionResult> clockOut() async {
    try {
      final locationResult = await _locationService.getCurrentPosition();

      if (!locationResult.success) {
        return AttendanceActionResult(
          success: false,
          message: locationResult.message,
          canOpenSettings: locationResult.canOpenSettings,
        );
      }

      final position = locationResult.position!;
      final locationMap = _locationService.positionToMap(position);

      final response = await ApiService.checkOut(
        location: locationMap,
        notes: 'Clock-out from phone app',
      );

      if (response.success) {
        return AttendanceActionResult(
          success: true,
          message: 'Clocked out successfully!',
          data: response.data,
        );
      } else {
        return AttendanceActionResult(
          success: false,
          message: response.message,
        );
      }
    } catch (e) {
      return AttendanceActionResult(
        success: false,
        message: 'Clock out failed: $e',
      );
    }
  }

  /// Fetch today's attendance data
  Future<Map<String, dynamic>?> getTodayAttendance() async {
    try {
      final response = await ApiService.getTodayAttendance();
      if (response.success) {
        return response.data;
      }
    } catch (e) {
      debugPrint('Error fetching today attendance: $e');
    }
    return null;
  }

  int _calculateClientSideLateMinutes() {
    try {
      final now = TimezoneUtil.nowIST();
      final workStartTime = tz.TZDateTime(
        now.location,
        now.year,
        now.month,
        now.day,
        9,
        0,
      );
      if (now.isAfter(workStartTime)) {
        return now.difference(workStartTime).inMinutes;
      }
    } catch (e) {
      debugPrint('Error calculating client-side late minutes: $e');
    }
    return 0;
  }
}

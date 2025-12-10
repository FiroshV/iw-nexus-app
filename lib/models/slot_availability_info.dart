import 'appointment.dart';

/// Information about a time slot's availability and which employees are busy
class SlotAvailabilityInfo {
  final TimeSlot timeSlot;
  final bool isAvailable;
  final List<EmployeeSlotInfo> busyEmployees;

  SlotAvailabilityInfo({
    required this.timeSlot,
    required this.isAvailable,
    this.busyEmployees = const [],
  });
}

/// Details about an employee who is busy at a specific time slot
class EmployeeSlotInfo {
  final String userId;
  final String userName;
  final String? role;
  final AppointmentInfo? conflictingAppointment;

  EmployeeSlotInfo({
    required this.userId,
    required this.userName,
    this.role,
    this.conflictingAppointment,
  });
}

/// Details about an appointment that conflicts with the desired time slot
class AppointmentInfo {
  final String appointmentId;
  final String? customerName;
  final String? customerPhone;
  final String startTime;
  final String endTime;

  AppointmentInfo({
    required this.appointmentId,
    this.customerName,
    this.customerPhone,
    required this.startTime,
    required this.endTime,
  });

  /// Parse appointment info from API response
  factory AppointmentInfo.fromJson(Map<String, dynamic> json) {
    return AppointmentInfo(
      appointmentId: json['appointmentId'] as String? ?? '',
      customerName: json['customer']?['name'] as String?,
      customerPhone: json['customer']?['mobileNumber'] as String?,
      startTime: json['startTime'] as String? ?? '',
      endTime: json['endTime'] as String? ?? '',
    );
  }
}

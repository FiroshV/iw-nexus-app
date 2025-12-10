import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;
import '../utils/timezone_util.dart';

class Appointment {
  final String? id;
  final String appointmentId;
  final String customerId;
  final String? customerName;
  final String? customerMobile;

  final List<EmployeeAssignment> assignedEmployees;

  final tz.TZDateTime scheduledDate;
  final String activityType; // 'in_person_visit', 'phone_call', 'email', etc.
  final TimeSlot? scheduledTimeSlot;

  final String? purpose;
  final String? purposeOther;
  final String? location;
  final String? notes;

  final String status; // 'scheduled', 'completed', 'cancelled'

  // Completion details
  final tz.TZDateTime? completedAt;
  final String? outcome; // 'sale_closed', 'interested_followup_needed', 'not_interested', etc.
  final String? outcomeNotes;
  final String? completionNotes;
  final int? timeSpentMinutes;

  final String? createdBy;
  final tz.TZDateTime createdAt;
  final tz.TZDateTime updatedAt;

  Appointment({
    this.id,
    required this.appointmentId,
    required this.customerId,
    this.customerName,
    this.customerMobile,
    required this.assignedEmployees,
    required this.scheduledDate,
    required this.activityType,
    this.scheduledTimeSlot,
    this.purpose,
    this.purposeOther,
    this.location,
    this.notes,
    this.status = 'scheduled',
    this.completedAt,
    this.outcome,
    this.outcomeNotes,
    this.completionNotes,
    this.timeSpentMinutes,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  // Computed getters
  /// Get the actual scheduled datetime by combining date with time slot
  tz.TZDateTime get _effectiveScheduledDateTime {
    if (scheduledTimeSlot != null) {
      // Parse the start time (format: "HH:mm") and combine with date
      final timeParts = scheduledTimeSlot!.startTime.split(':');
      if (timeParts.length >= 2) {
        try {
          final hour = int.parse(timeParts[0]);
          final minute = int.parse(timeParts[1]);
          // Create a new TZDateTime with the correct time
          return tz.TZDateTime(
            TimezoneUtil.istLocation!,
            scheduledDate.year,
            scheduledDate.month,
            scheduledDate.day,
            hour,
            minute,
            0,
          );
        } catch (e) {
          debugPrint('Error parsing time slot: $e');
          return scheduledDate;
        }
      }
    }
    return scheduledDate;
  }

  bool get isOverdue {
    final now = TimezoneUtil.nowIST();
    final effectiveDate = _effectiveScheduledDateTime;
    final result = effectiveDate.isBefore(now) && status == 'scheduled';
    return result;
  }

  bool get isDueToday {
    final today = TimezoneUtil.nowIST();
    return scheduledDate.year == today.year &&
        scheduledDate.month == today.month &&
        scheduledDate.day == today.day &&
        status == 'scheduled';
  }

  bool get isUpcoming {
    final now = TimezoneUtil.nowIST();
    final effectiveDate = _effectiveScheduledDateTime;
    return effectiveDate.isAfter(now) && status == 'scheduled';
  }

  bool get requiresTimeSlot => activityType == 'in_person_visit';

  String get activityTypeDisplayName {
    const displayMap = {
      'in_person_visit': 'Visit',
      'phone_call': 'Phone Call',
      'email': 'Email',
      'whatsapp_message': 'WhatsApp',
      'document_collection': 'Document Collection',
      'policy_renewal': 'Policy Renewal',
      'other': 'Other',
    };
    return displayMap[activityType] ?? activityType;
  }

  String get statusDisplayName {
    const displayMap = {
      'scheduled': 'Scheduled',
      'completed': 'Completed',
      'cancelled': 'Cancelled',
      'rescheduled': 'Rescheduled',
    };
    return displayMap[status] ?? status;
  }

  String get formattedScheduledDate {
    return DateFormat('dd MMM yyyy').format(scheduledDate);
  }

  String get formattedScheduledDatetime {
    if (scheduledTimeSlot != null) {
      return '${DateFormat('dd MMM yyyy').format(scheduledDate)} at ${scheduledTimeSlot!.startTime}';
    }
    return DateFormat('dd MMM yyyy').format(scheduledDate);
  }

  // Factory constructor for JSON deserialization
  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['_id'] as String?,
      appointmentId: json['appointmentId'] as String? ?? '',
      customerId: json['customerId'] is Map ? (json['customerId'] as Map)['_id'] as String? ?? '' : json['customerId'] as String? ?? '',
      customerName: json['customerId'] is Map ? (json['customerId'] as Map)['name'] as String? : null,
      customerMobile: json['customerId'] is Map ? (json['customerId'] as Map)['mobileNumber'] as String? : null,
      assignedEmployees: json['assignedEmployees'] != null
          ? (json['assignedEmployees'] as List)
              .map((e) => EmployeeAssignment.fromJson(e as Map<String, dynamic>))
              .toList()
          : [],
      scheduledDate: _parseDateTime(json['scheduledDate']),
      activityType: json['activityType'] as String? ?? 'in_person_visit',
      scheduledTimeSlot: json['scheduledTimeSlot'] != null
          ? TimeSlot.fromJson(json['scheduledTimeSlot'] as Map<String, dynamic>)
          : null,
      purpose: json['purpose'] as String?,
      purposeOther: json['purposeOther'] as String?,
      location: json['location'] as String?,
      notes: json['notes'] as String?,
      status: json['status'] as String? ?? 'scheduled',
      completedAt: json['completedAt'] != null ? _parseDateTime(json['completedAt']) : null,
      outcome: json['outcome'] as String?,
      outcomeNotes: json['outcomeNotes'] as String?,
      completionNotes: json['completionNotes'] as String?,
      timeSpentMinutes: json['timeSpentMinutes'] as int?,
      createdBy: json['createdBy'] is Map ? (json['createdBy'] as Map)['_id'] as String? : json['createdBy'] as String?,
      createdAt: _parseDateTime(json['createdAt']),
      updatedAt: _parseDateTime(json['updatedAt']),
    );
  }

  /// Safe DateTime parsing that handles multiple formats with timezone awareness
  static tz.TZDateTime _parseDateTime(dynamic value) {
    try {
      if (value == null) {
        return TimezoneUtil.nowIST();
      }
      if (value is tz.TZDateTime) {
        return value;
      }
      if (value is String) {
        // Backend now sends proper UTC times with 'Z' suffix (e.g., "2025-12-09T04:30:00.000Z")
        // Parse as UTC and convert to IST for display
        final parsed = DateTime.parse(value);
        // The parsed DateTime is in UTC, convert it to IST
        final result = TimezoneUtil.utcToIST(parsed);
        return result;
      }
      if (value is int) {
        // Handle Unix timestamp (milliseconds) and convert to IST
        final dt = DateTime.fromMillisecondsSinceEpoch(value);
        return TimezoneUtil.utcToIST(dt);
      }
      // Fallback for unknown format
      return TimezoneUtil.nowIST();
    } catch (e) {
      return TimezoneUtil.nowIST();
    }
  }

  // Convert to JSON for API requests
  Map<String, dynamic> toJson() {
    return {
      'customerId': customerId,
      'assignedEmployees': assignedEmployees.map((e) => e.toJson()).toList(),
      // Send scheduled date as UTC ISO string for API
      // The scheduledDate is stored as IST TZDateTime, convert to UTC
      'scheduledDate': scheduledDate.toUtc().toIso8601String(),
      'activityType': activityType,
      if (scheduledTimeSlot != null) 'scheduledTimeSlot': scheduledTimeSlot!.toJson(),
      if (purpose != null) 'purpose': purpose,
      if (purposeOther != null) 'purposeOther': purposeOther,
      if (location != null) 'location': location,
      if (notes != null) 'notes': notes,
    };
  }

  // Copy with method for immutable updates
  Appointment copyWith({
    String? id,
    String? appointmentId,
    String? customerId,
    String? customerName,
    String? customerMobile,
    List<EmployeeAssignment>? assignedEmployees,
    tz.TZDateTime? scheduledDate,
    String? activityType,
    TimeSlot? scheduledTimeSlot,
    String? purpose,
    String? purposeOther,
    String? location,
    String? notes,
    String? status,
    tz.TZDateTime? completedAt,
    String? outcome,
    String? outcomeNotes,
    String? completionNotes,
    int? timeSpentMinutes,
    String? createdBy,
    tz.TZDateTime? createdAt,
    tz.TZDateTime? updatedAt,
  }) {
    return Appointment(
      id: id ?? this.id,
      appointmentId: appointmentId ?? this.appointmentId,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerMobile: customerMobile ?? this.customerMobile,
      assignedEmployees: assignedEmployees ?? this.assignedEmployees,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      activityType: activityType ?? this.activityType,
      scheduledTimeSlot: scheduledTimeSlot ?? this.scheduledTimeSlot,
      purpose: purpose ?? this.purpose,
      purposeOther: purposeOther ?? this.purposeOther,
      location: location ?? this.location,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      completedAt: completedAt ?? this.completedAt,
      outcome: outcome ?? this.outcome,
      outcomeNotes: outcomeNotes ?? this.outcomeNotes,
      completionNotes: completionNotes ?? this.completionNotes,
      timeSpentMinutes: timeSpentMinutes ?? this.timeSpentMinutes,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class EmployeeAssignment {
  final String userId;
  final String? userName;
  final String role; // 'primary' | 'secondary'
  final String status; // 'pending' | 'accepted' | 'declined'

  EmployeeAssignment({
    required this.userId,
    this.userName,
    required this.role,
    this.status = 'pending',
  });

  factory EmployeeAssignment.fromJson(Map<String, dynamic> json) {
    return EmployeeAssignment(
      userId: json['userId'] is Map
          ? (json['userId'] as Map)['_id'] as String? ?? ''
          : json['userId'] as String? ?? '',
      userName: json['userId'] is Map
          ? '${(json['userId'] as Map)['firstName']} ${(json['userId'] as Map)['lastName']}'
          : null,
      role: json['role'] as String? ?? 'secondary',
      status: json['status'] as String? ?? 'pending',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'role': role,
      'status': status,
    };
  }
}

class TimeSlot {
  final String startTime; // "09:00"
  final String endTime; // "10:00"
  final bool isAvailable; // Whether slot is available
  final String? reason; // Reason if not available
  final String? appointmentId; // ID of the appointment if slot is occupied

  TimeSlot({
    required this.startTime,
    required this.endTime,
    this.isAvailable = true,
    this.reason,
    this.appointmentId,
  });

  factory TimeSlot.fromJson(Map<String, dynamic> json) {
    return TimeSlot(
      startTime: json['startTime'] as String? ?? '09:00',
      endTime: json['endTime'] as String? ?? '10:00',
      isAvailable: json['isAvailable'] as bool? ?? true,
      reason: json['reason'] as String?,
      appointmentId: json['appointmentId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'startTime': startTime,
      'endTime': endTime,
      'isAvailable': isAvailable,
      if (reason != null) 'reason': reason,
      if (appointmentId != null) 'appointmentId': appointmentId,
    };
  }

  @override
  String toString() => '$startTime - $endTime';
}


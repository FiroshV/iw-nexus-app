import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;
import '../utils/timezone_util.dart';

class Activity {
  final String? id;
  final String activityId;
  final String customerId;
  final String? customerName;
  final String? customerMobile;

  final String type; // 'quick_call', 'walkin_visit', 'email', 'whatsapp', 'sms', 'other'
  final String direction; // 'incoming', 'outgoing', 'both'

  final tz.TZDateTime activityDate;
  final int? durationMinutes;

  final String outcome; // 'connected', 'no_answer', 'voicemail', 'interested', etc.
  final String? notes;

  final String? followupAppointmentId;
  final List<EmployeeAssignmentActivity> assignedEmployees;

  final String? createdBy;
  final String? createdByName;
  final tz.TZDateTime createdAt;
  final tz.TZDateTime updatedAt;

  Activity({
    this.id,
    required this.activityId,
    required this.customerId,
    this.customerName,
    this.customerMobile,
    required this.type,
    this.direction = 'outgoing',
    required this.activityDate,
    this.durationMinutes,
    required this.outcome,
    this.notes,
    this.followupAppointmentId,
    this.assignedEmployees = const [],
    this.createdBy,
    this.createdByName,
    required this.createdAt,
    required this.updatedAt,
  });

  // Getters
  String get typeDisplayName {
    const displayMap = {
      'quick_call': 'Call',
      'walkin_visit': 'Walk-in Visit',
      'email': 'Email',
      'whatsapp': 'WhatsApp',
      'sms': 'SMS',
      'other': 'Other',
    };
    return displayMap[type] ?? type;
  }

  String get outcomeDisplayName {
    const displayMap = {
      'connected': 'Connected',
      'no_answer': 'No Answer',
      'voicemail': 'Voicemail',
      'busy': 'Busy',
      'failed': 'Failed',
      'interested': 'Interested',
      'not_interested': 'Not Interested',
      'callback_requested': 'Callback Requested',
      'other': 'Other',
    };
    return displayMap[outcome] ?? outcome;
  }

  String get directionDisplayName {
    const displayMap = {
      'incoming': 'Incoming',
      'outgoing': 'Outgoing',
      'both': 'Both',
    };
    return displayMap[direction] ?? direction;
  }

  String get formattedActivityDate {
    return DateFormat('dd MMM yyyy').format(activityDate);
  }

  String get formattedActivityDatetime {
    return DateFormat('dd MMM yyyy, hh:mm a').format(activityDate);
  }

  bool get hasFollowup => followupAppointmentId != null && followupAppointmentId!.isNotEmpty;

  // Factory constructor for JSON deserialization
  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      id: json['_id'] as String?,
      activityId: json['activityId'] as String? ?? '',
      customerId: json['customerId'] is Map
          ? (json['customerId'] as Map)['_id'] as String? ?? ''
          : json['customerId'] as String? ?? '',
      customerName: json['customerId'] is Map ? (json['customerId'] as Map)['name'] as String? : null,
      customerMobile: json['customerId'] is Map ? (json['customerId'] as Map)['mobileNumber'] as String? : null,
      type: json['type'] as String? ?? 'quick_call',
      direction: json['direction'] as String? ?? 'outgoing',
      activityDate: _parseDateTime(json['activityDate']),
      durationMinutes: json['durationMinutes'] as int?,
      outcome: json['outcome'] as String? ?? 'other',
      notes: json['notes'] as String?,
      followupAppointmentId: json['followupAppointmentId'] as String?,
      assignedEmployees: json['assignedEmployees'] != null
          ? (json['assignedEmployees'] as List)
              .map((e) => EmployeeAssignmentActivity.fromJson(e as Map<String, dynamic>))
              .toList()
          : [],
      createdBy: json['createdBy'] is Map ? (json['createdBy'] as Map)['_id'] as String? : json['createdBy'] as String?,
      createdByName: json['createdBy'] is Map
          ? '${(json['createdBy'] as Map)['firstName'] ?? ''} ${(json['createdBy'] as Map)['lastName'] ?? ''}'.trim()
          : null,
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
        // Backend sends proper UTC times with 'Z' suffix
        // Parse as UTC and convert to IST for display
        final parsed = DateTime.parse(value);
        // The parsed DateTime is in UTC, convert it to IST
        return TimezoneUtil.utcToIST(parsed);
      }
      if (value is int) {
        // Handle Unix timestamp (milliseconds) and convert to IST
        final dt = DateTime.fromMillisecondsSinceEpoch(value);
        return TimezoneUtil.utcToIST(dt);
      }
      return TimezoneUtil.nowIST();
    } catch (e) {
      return TimezoneUtil.nowIST();
    }
  }

  // Convert to JSON for API requests
  Map<String, dynamic> toJson() {
    return {
      'customerId': customerId,
      'type': type,
      'activityDate': TimezoneUtil.toApiString(activityDate),
      'outcome': outcome,
      if (notes != null) 'notes': notes,
      if (followupAppointmentId != null) 'followupAppointmentId': followupAppointmentId,
      if (assignedEmployees.isNotEmpty)
        'assignedEmployees': assignedEmployees.map((e) => e.toJson()).toList(),
    };
  }

  // Copy with method
  Activity copyWith({
    String? id,
    String? activityId,
    String? customerId,
    String? customerName,
    String? customerMobile,
    String? type,
    String? direction,
    tz.TZDateTime? activityDate,
    int? durationMinutes,
    String? outcome,
    String? notes,
    String? followupAppointmentId,
    List<EmployeeAssignmentActivity>? assignedEmployees,
    String? createdBy,
    String? createdByName,
    tz.TZDateTime? createdAt,
    tz.TZDateTime? updatedAt,
  }) {
    return Activity(
      id: id ?? this.id,
      activityId: activityId ?? this.activityId,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerMobile: customerMobile ?? this.customerMobile,
      type: type ?? this.type,
      direction: direction ?? this.direction,
      activityDate: activityDate ?? this.activityDate,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      outcome: outcome ?? this.outcome,
      notes: notes ?? this.notes,
      followupAppointmentId: followupAppointmentId ?? this.followupAppointmentId,
      assignedEmployees: assignedEmployees ?? this.assignedEmployees,
      createdBy: createdBy ?? this.createdBy,
      createdByName: createdByName ?? this.createdByName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class EmployeeAssignmentActivity {
  final String userId;
  final String? userName;
  final String role; // 'primary' | 'secondary'

  EmployeeAssignmentActivity({
    required this.userId,
    this.userName,
    required this.role,
  });

  factory EmployeeAssignmentActivity.fromJson(Map<String, dynamic> json) {
    return EmployeeAssignmentActivity(
      userId: json['userId'] is Map
          ? (json['userId'] as Map)['_id'] as String? ?? ''
          : json['userId'] as String? ?? '',
      userName: json['userId'] is Map
          ? '${(json['userId'] as Map)['firstName']} ${(json['userId'] as Map)['lastName']}'
          : json['userName'] as String?,
      role: json['role'] as String? ?? 'secondary',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      if (userName != null) 'userName': userName,
      'role': role,
    };
  }
}

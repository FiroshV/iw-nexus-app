import 'package:timezone/timezone.dart' as tz;
import '../utils/timezone_util.dart';

class StatusHistoryItem {
  final String status;
  final tz.TZDateTime changedAt;
  final String? changedBy;
  final String? notes;

  StatusHistoryItem({
    required this.status,
    required this.changedAt,
    this.changedBy,
    this.notes,
  });

  factory StatusHistoryItem.fromJson(Map<String, dynamic> json) {
    return StatusHistoryItem(
      status: json['status'] ?? '',
      changedAt: json['changedAt'] != null
          ? TimezoneUtil.utcToIST(DateTime.parse(json['changedAt'] as String))
          : TimezoneUtil.nowIST(),
      changedBy: json['changedBy'],
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'changedAt': TimezoneUtil.toApiString(changedAt),
      'changedBy': changedBy,
      'notes': notes,
    };
  }
}

class Customer {
  final String id;
  final String customerId;
  final String name;
  final String mobileNumber;
  final String? email;
  final String? address;
  final String? notes;
  final String createdBy;
  final tz.TZDateTime createdAt;
  final tz.TZDateTime updatedAt;
  // Lead Management Fields
  final String leadStatus;
  final String? leadSource;
  final String? leadSourceDetails;
  final String leadPriority;
  final tz.TZDateTime? lastContactDate;
  final tz.TZDateTime? nextFollowupDate;
  final String? lostReason;
  final String? lostReasonNotes;
  final tz.TZDateTime? lostDate;
  final tz.TZDateTime? convertedDate;
  final List<StatusHistoryItem>? statusHistory;

  Customer({
    required this.id,
    required this.customerId,
    required this.name,
    required this.mobileNumber,
    this.email,
    this.address,
    this.notes,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.leadStatus = 'new_lead',
    this.leadSource,
    this.leadSourceDetails,
    this.leadPriority = 'warm',
    this.lastContactDate,
    this.nextFollowupDate,
    this.lostReason,
    this.lostReasonNotes,
    this.lostDate,
    this.convertedDate,
    this.statusHistory,
  });

  // Factory constructor to create Customer from JSON
  factory Customer.fromJson(Map<String, dynamic> json) {
    final statusHistory = (json['statusHistory'] as List<dynamic>?)
        ?.map((item) => StatusHistoryItem.fromJson(item as Map<String, dynamic>))
        .toList();

    return Customer(
      id: json['_id'] ?? '',
      customerId: json['customerId'] ?? '',
      name: json['name'] ?? '',
      mobileNumber: json['mobileNumber'] ?? '',
      email: json['email'],
      address: json['address'],
      notes: json['notes'],
      createdBy: json['createdBy'] ?? '',
      createdAt: json['createdAt'] != null
          ? _parseIST(json['createdAt'] as String)
          : TimezoneUtil.nowIST(),
      updatedAt: json['updatedAt'] != null
          ? _parseIST(json['updatedAt'] as String)
          : TimezoneUtil.nowIST(),
      leadStatus: json['leadStatus'] ?? 'new_lead',
      leadSource: json['leadSource'],
      leadSourceDetails: json['leadSourceDetails'],
      leadPriority: json['leadPriority'] ?? 'warm',
      lastContactDate: json['lastContactDate'] != null
          ? _parseIST(json['lastContactDate'] as String)
          : null,
      nextFollowupDate: json['nextFollowupDate'] != null
          ? _parseIST(json['nextFollowupDate'] as String)
          : null,
      lostReason: json['lostReason'],
      lostReasonNotes: json['lostReasonNotes'],
      lostDate: json['lostDate'] != null
          ? _parseIST(json['lostDate'] as String)
          : null,
      convertedDate: json['convertedDate'] != null
          ? _parseIST(json['convertedDate'] as String)
          : null,
      statusHistory: statusHistory,
    );
  }

  /// Parse UTC time from API response and convert to IST
  static tz.TZDateTime _parseIST(String dateString) {
    final parsed = DateTime.parse(dateString);
    // Parse as UTC and convert to IST
    return TimezoneUtil.utcToIST(parsed);
  }

  // Convert Customer to JSON
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'customerId': customerId,
      'name': name,
      'mobileNumber': mobileNumber,
      'email': email,
      'address': address,
      'notes': notes,
      'createdBy': createdBy,
      'createdAt': TimezoneUtil.toApiString(createdAt),
      'updatedAt': TimezoneUtil.toApiString(updatedAt),
      'leadStatus': leadStatus,
      'leadSource': leadSource,
      'leadSourceDetails': leadSourceDetails,
      'leadPriority': leadPriority,
      'lastContactDate': lastContactDate != null ? TimezoneUtil.toApiString(lastContactDate!) : null,
      'nextFollowupDate': nextFollowupDate != null ? TimezoneUtil.toApiString(nextFollowupDate!) : null,
      'lostReason': lostReason,
      'lostReasonNotes': lostReasonNotes,
      'lostDate': lostDate != null ? TimezoneUtil.toApiString(lostDate!) : null,
      'convertedDate': convertedDate != null ? TimezoneUtil.toApiString(convertedDate!) : null,
      'statusHistory': statusHistory?.map((item) => item.toJson()).toList(),
    };
  }

  // Copy with method for partial updates
  Customer copyWith({
    String? id,
    String? customerId,
    String? name,
    String? mobileNumber,
    String? email,
    String? address,
    String? notes,
    String? createdBy,
    tz.TZDateTime? createdAt,
    tz.TZDateTime? updatedAt,
    String? leadStatus,
    String? leadSource,
    String? leadSourceDetails,
    String? leadPriority,
    tz.TZDateTime? lastContactDate,
    tz.TZDateTime? nextFollowupDate,
    String? lostReason,
    String? lostReasonNotes,
    tz.TZDateTime? lostDate,
    tz.TZDateTime? convertedDate,
    List<StatusHistoryItem>? statusHistory,
  }) {
    return Customer(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      name: name ?? this.name,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      email: email ?? this.email,
      address: address ?? this.address,
      notes: notes ?? this.notes,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      leadStatus: leadStatus ?? this.leadStatus,
      leadSource: leadSource ?? this.leadSource,
      leadSourceDetails: leadSourceDetails ?? this.leadSourceDetails,
      leadPriority: leadPriority ?? this.leadPriority,
      lastContactDate: lastContactDate ?? this.lastContactDate,
      nextFollowupDate: nextFollowupDate ?? this.nextFollowupDate,
      lostReason: lostReason ?? this.lostReason,
      lostReasonNotes: lostReasonNotes ?? this.lostReasonNotes,
      lostDate: lostDate ?? this.lostDate,
      convertedDate: convertedDate ?? this.convertedDate,
      statusHistory: statusHistory ?? this.statusHistory,
    );
  }

  @override
  String toString() => 'Customer(id: $id, name: $name, mobileNumber: $mobileNumber)';
}

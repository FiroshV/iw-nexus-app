import 'package:timezone/timezone.dart' as tz;
import '../utils/timezone_util.dart';

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
  });

  // Factory constructor to create Customer from JSON
  factory Customer.fromJson(Map<String, dynamic> json) {
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
    );
  }

  @override
  String toString() => 'Customer(id: $id, name: $name, mobileNumber: $mobileNumber)';
}

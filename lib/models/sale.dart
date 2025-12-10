import 'package:timezone/timezone.dart' as tz;
import '../utils/timezone_util.dart';

class Sale {
  final String id;
  final String saleId;
  final String userId;
  final String customerId;
  final String customerName;
  final String mobileNumber;
  final String productType; // life_insurance, general_insurance, mutual_funds
  final tz.TZDateTime dateOfSale;
  final String companyName; // Insurer or Fund House
  final String productPlanName;
  final double? premiumAmount; // For insurance
  final double? investmentAmount; // For lumpsum mutual funds
  final double? sipAmount; // For SIP mutual funds
  final String? paymentFrequency;
  final String? investmentType; // sip or lumpsum
  final List<String> relatedVisits;
  final String? initialVisitId;
  final String status; // active, inactive, closed
  final String? notes;
  final String? visitStatus; // Computed field from visits
  final List<EmployeeAssignmentSale> assignedEmployees;
  final WorkflowLinkSale? createdFrom;
  final List<String> relatedAppointments;
  final tz.TZDateTime createdAt;
  final tz.TZDateTime updatedAt;

  Sale({
    required this.id,
    required this.saleId,
    required this.userId,
    required this.customerId,
    required this.customerName,
    required this.mobileNumber,
    required this.productType,
    required this.dateOfSale,
    required this.companyName,
    required this.productPlanName,
    this.premiumAmount,
    this.investmentAmount,
    this.sipAmount,
    this.paymentFrequency,
    this.investmentType,
    this.relatedVisits = const [],
    this.initialVisitId,
    this.status = 'active',
    this.notes,
    this.visitStatus,
    this.assignedEmployees = const [],
    this.createdFrom,
    this.relatedAppointments = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  // Get display amount based on product type
  double get displayAmount {
    if (productType == 'mutual_funds') {
      return investmentType == 'sip' ? sipAmount ?? 0 : investmentAmount ?? 0;
    }
    return premiumAmount ?? 0;
  }

  // Get amount label based on product type
  String get amountLabel {
    if (productType == 'mutual_funds') {
      return investmentType == 'sip' ? 'SIP Amount' : 'Investment Amount';
    }
    return 'Premium Amount';
  }

  // Factory constructor to create Sale from JSON
  factory Sale.fromJson(Map<String, dynamic> json) {
    return Sale(
      id: json['_id'] ?? '',
      saleId: json['saleId'] ?? '',
      userId: json['userId'] ?? '',
      customerId: json['customerId'] is Map ? json['customerId']['_id'] ?? '' : json['customerId'] ?? '',
      customerName: json['customerId'] is Map ? json['customerId']['name'] ?? '' : json['customerName'] ?? '',
      mobileNumber: json['customerId'] is Map ? json['customerId']['mobileNumber'] ?? '' : json['mobileNumber'] ?? '',
      productType: json['productType'] ?? '',
      dateOfSale: json['dateOfSale'] != null ? _parseIST(json['dateOfSale'] as String) : TimezoneUtil.nowIST(),
      companyName: json['companyName'] ?? '',
      productPlanName: json['productPlanName'] ?? '',
      premiumAmount: json['premiumAmount'] != null ? double.tryParse(json['premiumAmount'].toString()) : null,
      investmentAmount: json['investmentAmount'] != null ? double.tryParse(json['investmentAmount'].toString()) : null,
      sipAmount: json['sipAmount'] != null ? double.tryParse(json['sipAmount'].toString()) : null,
      paymentFrequency: json['paymentFrequency'],
      investmentType: json['investmentType'],
      relatedVisits: json['relatedVisits'] != null ? List<String>.from(json['relatedVisits'].map((v) => v is Map ? v['_id'] ?? '' : v)) : [],
      initialVisitId: json['initialVisitId'],
      status: json['status'] ?? 'active',
      notes: json['notes'],
      visitStatus: json['visitStatus'],
      assignedEmployees: json['assignedEmployees'] != null
          ? (json['assignedEmployees'] as List)
              .map((e) => EmployeeAssignmentSale.fromJson(e as Map<String, dynamic>))
              .toList()
          : [],
      createdFrom: json['createdFrom'] != null
          ? WorkflowLinkSale.fromJson(json['createdFrom'] as Map<String, dynamic>)
          : null,
      relatedAppointments: json['relatedAppointments'] != null
          ? List<String>.from(json['relatedAppointments'].map((a) => a is Map ? a['_id'] ?? '' : a))
          : [],
      createdAt: json['createdAt'] != null ? _parseIST(json['createdAt'] as String) : TimezoneUtil.nowIST(),
      updatedAt: json['updatedAt'] != null ? _parseIST(json['updatedAt'] as String) : TimezoneUtil.nowIST(),
    );
  }

  /// Parse UTC time from API response and convert to IST
  static tz.TZDateTime _parseIST(String dateString) {
    final parsed = DateTime.parse(dateString);
    // Parse as UTC and convert to IST
    return TimezoneUtil.utcToIST(parsed);
  }

  // Convert Sale to JSON
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'saleId': saleId,
      'userId': userId,
      'customerId': customerId,
      'customerName': customerName,
      'mobileNumber': mobileNumber,
      'productType': productType,
      'dateOfSale': TimezoneUtil.toApiString(dateOfSale),
      'companyName': companyName,
      'productPlanName': productPlanName,
      'premiumAmount': premiumAmount,
      'investmentAmount': investmentAmount,
      'sipAmount': sipAmount,
      'paymentFrequency': paymentFrequency,
      'investmentType': investmentType,
      'relatedVisits': relatedVisits,
      'initialVisitId': initialVisitId,
      'status': status,
      'notes': notes,
      'visitStatus': visitStatus,
      'assignedEmployees': assignedEmployees.map((e) => e.toJson()).toList(),
      if (createdFrom != null) 'createdFrom': createdFrom!.toJson(),
      'relatedAppointments': relatedAppointments,
      'createdAt': TimezoneUtil.toApiString(createdAt),
      'updatedAt': TimezoneUtil.toApiString(updatedAt),
    };
  }

  // Copy with method
  Sale copyWith({
    String? id,
    String? saleId,
    String? userId,
    String? customerId,
    String? customerName,
    String? mobileNumber,
    String? productType,
    tz.TZDateTime? dateOfSale,
    String? companyName,
    String? productPlanName,
    double? premiumAmount,
    double? investmentAmount,
    double? sipAmount,
    String? paymentFrequency,
    String? investmentType,
    List<String>? relatedVisits,
    String? initialVisitId,
    String? status,
    String? notes,
    String? visitStatus,
    List<EmployeeAssignmentSale>? assignedEmployees,
    WorkflowLinkSale? createdFrom,
    List<String>? relatedAppointments,
    tz.TZDateTime? createdAt,
    tz.TZDateTime? updatedAt,
  }) {
    return Sale(
      id: id ?? this.id,
      saleId: saleId ?? this.saleId,
      userId: userId ?? this.userId,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      productType: productType ?? this.productType,
      dateOfSale: dateOfSale ?? this.dateOfSale,
      companyName: companyName ?? this.companyName,
      productPlanName: productPlanName ?? this.productPlanName,
      premiumAmount: premiumAmount ?? this.premiumAmount,
      investmentAmount: investmentAmount ?? this.investmentAmount,
      sipAmount: sipAmount ?? this.sipAmount,
      paymentFrequency: paymentFrequency ?? this.paymentFrequency,
      investmentType: investmentType ?? this.investmentType,
      relatedVisits: relatedVisits ?? this.relatedVisits,
      initialVisitId: initialVisitId ?? this.initialVisitId,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      visitStatus: visitStatus ?? this.visitStatus,
      assignedEmployees: assignedEmployees ?? this.assignedEmployees,
      createdFrom: createdFrom ?? this.createdFrom,
      relatedAppointments: relatedAppointments ?? this.relatedAppointments,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() => 'Sale(id: $id, saleId: $saleId, customerName: $customerName, productType: $productType)';
}

class EmployeeAssignmentSale {
  final String userId;
  final String? userName;
  final String role; // 'primary' | 'secondary'
  final double? commissionPercentage;

  EmployeeAssignmentSale({
    required this.userId,
    this.userName,
    required this.role,
    this.commissionPercentage,
  });

  factory EmployeeAssignmentSale.fromJson(Map<String, dynamic> json) {
    return EmployeeAssignmentSale(
      userId: json['userId'] is Map
          ? (json['userId'] as Map)['_id'] as String? ?? ''
          : json['userId'] as String? ?? '',
      userName: json['userId'] is Map
          ? '${(json['userId'] as Map)['firstName']} ${(json['userId'] as Map)['lastName']}'
          : null,
      role: json['role'] as String? ?? 'secondary',
      commissionPercentage: json['commissionPercentage'] != null
          ? double.tryParse(json['commissionPercentage'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'role': role,
      if (commissionPercentage != null) 'commissionPercentage': commissionPercentage,
    };
  }
}

class WorkflowLinkSale {
  final String type; // 'visit' | 'appointment' | 'direct'
  final String referenceId;

  WorkflowLinkSale({
    required this.type,
    required this.referenceId,
  });

  factory WorkflowLinkSale.fromJson(Map<String, dynamic> json) {
    return WorkflowLinkSale(
      type: json['type'] as String? ?? 'direct',
      referenceId: json['referenceId'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'referenceId': referenceId,
    };
  }
}

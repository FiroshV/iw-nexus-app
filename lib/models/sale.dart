import 'package:timezone/timezone.dart' as tz;
import '../utils/timezone_util.dart';
import 'sale_extended_details.dart';

class Sale {
  final String id;
  final String saleId;
  final String userId;
  final String customerId;
  final String customerName;
  final String mobileNumber;
  final String productType; // life_insurance, general_insurance, mutual_funds
  final String? productId; // Reference to Product for commission calculation
  final String? productName; // Product name from linked product
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
  // Extended fields
  final PolicyDetails? policyDetails;
  final ProposerDetails? proposerDetails;
  final List<Nominee> nominees;
  final List<InsuredPerson> insuredPersons;
  final MutualFundDetails? mutualFundDetails;

  Sale({
    required this.id,
    required this.saleId,
    required this.userId,
    required this.customerId,
    required this.customerName,
    required this.mobileNumber,
    required this.productType,
    this.productId,
    this.productName,
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
    this.policyDetails,
    this.proposerDetails,
    this.nominees = const [],
    this.insuredPersons = const [],
    this.mutualFundDetails,
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
      userId: json['userId'] is Map ? json['userId']['_id'] ?? '' : json['userId'] ?? '',
      customerId: json['customerId'] is Map ? json['customerId']['_id'] ?? '' : json['customerId'] ?? '',
      customerName: json['customerId'] is Map ? json['customerId']['name'] ?? '' : json['customerName'] ?? '',
      mobileNumber: json['customerId'] is Map ? json['customerId']['mobileNumber'] ?? '' : json['mobileNumber'] ?? '',
      productType: json['productType'] ?? '',
      productId: json['productId'] is Map ? json['productId']['_id'] : json['productId'],
      productName: json['productId'] is Map ? json['productId']['name'] : null,
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
      policyDetails: json['policyDetails'] != null
          ? PolicyDetails.fromJson(json['policyDetails'] as Map<String, dynamic>)
          : null,
      proposerDetails: json['proposerDetails'] != null
          ? ProposerDetails.fromJson(json['proposerDetails'] as Map<String, dynamic>)
          : null,
      nominees: json['nominees'] != null
          ? (json['nominees'] as List)
              .map((n) => Nominee.fromJson(n as Map<String, dynamic>))
              .toList()
          : [],
      insuredPersons: json['insuredPersons'] != null
          ? (json['insuredPersons'] as List)
              .map((p) => InsuredPerson.fromJson(p as Map<String, dynamic>))
              .toList()
          : [],
      mutualFundDetails: json['mutualFundDetails'] != null
          ? MutualFundDetails.fromJson(json['mutualFundDetails'] as Map<String, dynamic>)
          : null,
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
      if (productId != null) 'productId': productId,
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
      if (policyDetails != null) 'policyDetails': policyDetails!.toJson(),
      if (proposerDetails != null) 'proposerDetails': proposerDetails!.toJson(),
      if (nominees.isNotEmpty) 'nominees': nominees.map((n) => n.toJson()).toList(),
      if (insuredPersons.isNotEmpty) 'insuredPersons': insuredPersons.map((p) => p.toJson()).toList(),
      if (mutualFundDetails != null) 'mutualFundDetails': mutualFundDetails!.toJson(),
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
    String? productId,
    String? productName,
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
    PolicyDetails? policyDetails,
    ProposerDetails? proposerDetails,
    List<Nominee>? nominees,
    List<InsuredPerson>? insuredPersons,
    MutualFundDetails? mutualFundDetails,
  }) {
    return Sale(
      id: id ?? this.id,
      saleId: saleId ?? this.saleId,
      userId: userId ?? this.userId,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      productType: productType ?? this.productType,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
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
      policyDetails: policyDetails ?? this.policyDetails,
      proposerDetails: proposerDetails ?? this.proposerDetails,
      nominees: nominees ?? this.nominees,
      insuredPersons: insuredPersons ?? this.insuredPersons,
      mutualFundDetails: mutualFundDetails ?? this.mutualFundDetails,
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

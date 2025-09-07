class ContactInfo {
  final String? phone;
  final String? email;

  ContactInfo({
    this.phone,
    this.email,
  });

  factory ContactInfo.fromJson(Map<String, dynamic>? json) {
    if (json == null) return ContactInfo();
    
    return ContactInfo(
      phone: json['phone'],
      email: json['email'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'phone': phone,
      'email': email,
    };
  }

  ContactInfo copyWith({
    String? phone,
    String? email,
  }) {
    return ContactInfo(
      phone: phone ?? this.phone,
      email: email ?? this.email,
    );
  }
}

class BranchManager {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String? employeeId;
  final String? phone;

  BranchManager({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.employeeId,
    this.phone,
  });

  factory BranchManager.fromJson(Map<String, dynamic> json) {
    return BranchManager(
      id: json['_id'] ?? json['id'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      email: json['email'] ?? '',
      employeeId: json['employeeId'],
      phone: json['phone'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'employeeId': employeeId,
      'phone': phone,
    };
  }

  String get fullName => '$firstName $lastName'.trim();

  BranchManager copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? email,
    String? employeeId,
    String? phone,
  }) {
    return BranchManager(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      employeeId: employeeId ?? this.employeeId,
      phone: phone ?? this.phone,
    );
  }

  @override
  String toString() => fullName;
}

enum BranchStatus {
  active,
  inactive,
  temporarilyClosed;

  static BranchStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return BranchStatus.active;
      case 'inactive':
        return BranchStatus.inactive;
      case 'temporarily_closed':
        return BranchStatus.temporarilyClosed;
      default:
        return BranchStatus.active;
    }
  }

  String toJson() {
    switch (this) {
      case BranchStatus.active:
        return 'active';
      case BranchStatus.inactive:
        return 'inactive';
      case BranchStatus.temporarilyClosed:
        return 'temporarily_closed';
    }
  }

  String get displayName {
    switch (this) {
      case BranchStatus.active:
        return 'Active';
      case BranchStatus.inactive:
        return 'Inactive';
      case BranchStatus.temporarilyClosed:
        return 'Temporarily Closed';
    }
  }
}

class Branch {
  final String id;
  final String branchId;
  final String branchName;
  final String branchAddress;
  final BranchManager? branchManager;
  final ContactInfo contactInfo;
  final BranchStatus status;
  final DateTime? establishedDate;
  final int employeeCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  Branch({
    required this.id,
    required this.branchId,
    required this.branchName,
    required this.branchAddress,
    this.branchManager,
    required this.contactInfo,
    required this.status,
    this.establishedDate,
    required this.employeeCount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Branch.fromJson(Map<String, dynamic> json) {
    return Branch(
      id: json['_id'] ?? json['id'] ?? '',
      branchId: json['branchId'] ?? '',
      branchName: json['branchName'] ?? '',
      branchAddress: json['branchAddress'] ?? '',
      branchManager: json['branchManager'] != null 
          ? BranchManager.fromJson(json['branchManager'])
          : null,
      contactInfo: ContactInfo.fromJson(json['contactInfo']),
      status: BranchStatus.fromString(json['status'] ?? 'active'),
      establishedDate: json['establishedDate'] != null 
          ? DateTime.parse(json['establishedDate'])
          : null,
      employeeCount: json['employeeCount'] ?? 0,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'branchId': branchId,
      'branchName': branchName,
      'branchAddress': branchAddress,
      'branchManager': branchManager?.toJson(),
      'contactInfo': contactInfo.toJson(),
      'status': status.toJson(),
      'establishedDate': establishedDate?.toIso8601String(),
      'employeeCount': employeeCount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // For creating new branches (without server-generated fields)
  Map<String, dynamic> toCreateJson() {
    final Map<String, dynamic> json = {
      'branchName': branchName,
      'branchAddress': branchAddress,
      'contactInfo': contactInfo.toJson(),
      'status': status.toJson(),
    };

    if (branchManager != null) {
      json['branchManager'] = branchManager!.id;
    }

    if (establishedDate != null) {
      json['establishedDate'] = establishedDate!.toIso8601String();
    }

    return json;
  }

  Branch copyWith({
    String? id,
    String? branchId,
    String? branchName,
    String? branchAddress,
    BranchManager? branchManager,
    ContactInfo? contactInfo,
    BranchStatus? status,
    DateTime? establishedDate,
    int? employeeCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Branch(
      id: id ?? this.id,
      branchId: branchId ?? this.branchId,
      branchName: branchName ?? this.branchName,
      branchAddress: branchAddress ?? this.branchAddress,
      branchManager: branchManager ?? this.branchManager,
      contactInfo: contactInfo ?? this.contactInfo,
      status: status ?? this.status,
      establishedDate: establishedDate ?? this.establishedDate,
      employeeCount: employeeCount ?? this.employeeCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get managerName => branchManager?.fullName ?? 'Not Assigned';

  bool get isActive => status == BranchStatus.active;

  @override
  String toString() => '$branchName ($branchId)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Branch &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

// Validation helpers
class BranchValidation {
  static String? validateBranchName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Branch name is required';
    }
    if (value.trim().length > 100) {
      return 'Branch name must not exceed 100 characters';
    }
    return null;
  }

  static String? validateAddress(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Branch address is required';
    }
    if (value.trim().length > 500) {
      return 'Branch address must not exceed 500 characters';
    }
    return null;
  }

  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Phone is optional
    }
    if (!RegExp(r'^\+?[\d\s\-\(\)]{10,15}$').hasMatch(value.trim())) {
      return 'Please enter a valid phone number';
    }
    return null;
  }

  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Email is optional
    }
    if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
        .hasMatch(value.trim())) {
      return 'Please enter a valid email address';
    }
    return null;
  }
}
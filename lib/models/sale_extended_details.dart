import '../utils/timezone_util.dart';

// ============= Policy Details =============
class PolicyDetails {
  final DateTime? policyIssuanceDate;
  final String? policyNumber;

  PolicyDetails({
    this.policyIssuanceDate,
    this.policyNumber,
  });

  factory PolicyDetails.fromJson(Map<String, dynamic> json) {
    return PolicyDetails(
      policyIssuanceDate: json['policyIssuanceDate'] != null
          ? _parseIST(json['policyIssuanceDate'] as String)
          : null,
      policyNumber: json['policyNumber'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (policyIssuanceDate != null)
        'policyIssuanceDate':
            TimezoneUtil.toApiString(TimezoneUtil.utcToIST(policyIssuanceDate!)),
      if (policyNumber != null) 'policyNumber': policyNumber,
    };
  }

  PolicyDetails copyWith({
    DateTime? policyIssuanceDate,
    String? policyNumber,
  }) {
    return PolicyDetails(
      policyIssuanceDate: policyIssuanceDate ?? this.policyIssuanceDate,
      policyNumber: policyNumber ?? this.policyNumber,
    );
  }

  @override
  String toString() =>
      'PolicyDetails(policyIssuanceDate: $policyIssuanceDate, policyNumber: $policyNumber)';
}

// ============= Proposer Details =============
class ProposerDetails {
  final String? fullName;
  final String? gender; // 'male' or 'female'
  final DateTime? dateOfBirth;
  final String? email;
  final String? mobileNumber;

  ProposerDetails({
    this.fullName,
    this.gender,
    this.dateOfBirth,
    this.email,
    this.mobileNumber,
  });

  factory ProposerDetails.fromJson(Map<String, dynamic> json) {
    return ProposerDetails(
      fullName: json['fullName'],
      gender: json['gender'],
      dateOfBirth: json['dateOfBirth'] != null
          ? _parseIST(json['dateOfBirth'] as String)
          : null,
      email: json['email'],
      mobileNumber: json['mobileNumber'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (fullName != null) 'fullName': fullName,
      if (gender != null) 'gender': gender,
      if (dateOfBirth != null)
        'dateOfBirth':
            TimezoneUtil.toApiString(TimezoneUtil.utcToIST(dateOfBirth!)),
      if (email != null) 'email': email,
      if (mobileNumber != null) 'mobileNumber': mobileNumber,
    };
  }

  ProposerDetails copyWith({
    String? fullName,
    String? gender,
    DateTime? dateOfBirth,
    String? email,
    String? mobileNumber,
  }) {
    return ProposerDetails(
      fullName: fullName ?? this.fullName,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      email: email ?? this.email,
      mobileNumber: mobileNumber ?? this.mobileNumber,
    );
  }

  @override
  String toString() =>
      'ProposerDetails(fullName: $fullName, gender: $gender, dateOfBirth: $dateOfBirth, email: $email, mobileNumber: $mobileNumber)';
}

// ============= Nominee =============
class Nominee {
  final String? name;
  final DateTime? dateOfBirth;

  Nominee({
    this.name,
    this.dateOfBirth,
  });

  factory Nominee.fromJson(Map<String, dynamic> json) {
    return Nominee(
      name: json['name'],
      dateOfBirth: json['dateOfBirth'] != null
          ? _parseIST(json['dateOfBirth'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (name != null) 'name': name,
      if (dateOfBirth != null)
        'dateOfBirth':
            TimezoneUtil.toApiString(TimezoneUtil.utcToIST(dateOfBirth!)),
    };
  }

  Nominee copyWith({
    String? name,
    DateTime? dateOfBirth,
  }) {
    return Nominee(
      name: name ?? this.name,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
    );
  }

  @override
  String toString() => 'Nominee(name: $name, dateOfBirth: $dateOfBirth)';
}

// ============= Height/Weight Helper =============
class HeightWeight {
  final double? value;
  final String unit; // 'cm' or 'feet' for height, 'kg' or 'lbs' for weight

  HeightWeight({
    this.value,
    required this.unit,
  });

  factory HeightWeight.fromJson(Map<String, dynamic> json) {
    return HeightWeight(
      value: json['value'] != null ? double.tryParse(json['value'].toString()) : null,
      unit: json['unit'] ?? 'cm',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (value != null) 'value': value,
      'unit': unit,
    };
  }

  HeightWeight copyWith({
    double? value,
    String? unit,
  }) {
    return HeightWeight(
      value: value ?? this.value,
      unit: unit ?? this.unit,
    );
  }

  @override
  String toString() => 'HeightWeight(value: $value, unit: $unit)';
}

// ============= Insured Person =============
class InsuredPerson {
  final String? fullName;
  final String? gender; // 'male' or 'female'
  final DateTime? dateOfBirth;
  final HeightWeight? height;
  final HeightWeight? weight;
  final String? preExistingDiseases;
  final String? medicationDetails;

  InsuredPerson({
    this.fullName,
    this.gender,
    this.dateOfBirth,
    this.height,
    this.weight,
    this.preExistingDiseases,
    this.medicationDetails,
  });

  factory InsuredPerson.fromJson(Map<String, dynamic> json) {
    return InsuredPerson(
      fullName: json['fullName'],
      gender: json['gender'],
      dateOfBirth: json['dateOfBirth'] != null
          ? _parseIST(json['dateOfBirth'] as String)
          : null,
      height: json['height'] != null
          ? HeightWeight.fromJson(json['height'] as Map<String, dynamic>)
          : null,
      weight: json['weight'] != null
          ? HeightWeight.fromJson(json['weight'] as Map<String, dynamic>)
          : null,
      preExistingDiseases: json['preExistingDiseases'],
      medicationDetails: json['medicationDetails'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (fullName != null) 'fullName': fullName,
      if (gender != null) 'gender': gender,
      if (dateOfBirth != null)
        'dateOfBirth':
            TimezoneUtil.toApiString(TimezoneUtil.utcToIST(dateOfBirth!)),
      if (height != null) 'height': height!.toJson(),
      if (weight != null) 'weight': weight!.toJson(),
      if (preExistingDiseases != null) 'preExistingDiseases': preExistingDiseases,
      if (medicationDetails != null) 'medicationDetails': medicationDetails,
    };
  }

  InsuredPerson copyWith({
    String? fullName,
    String? gender,
    DateTime? dateOfBirth,
    HeightWeight? height,
    HeightWeight? weight,
    String? preExistingDiseases,
    String? medicationDetails,
  }) {
    return InsuredPerson(
      fullName: fullName ?? this.fullName,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      preExistingDiseases: preExistingDiseases ?? this.preExistingDiseases,
      medicationDetails: medicationDetails ?? this.medicationDetails,
    );
  }

  @override
  String toString() =>
      'InsuredPerson(fullName: $fullName, gender: $gender, dateOfBirth: $dateOfBirth, height: $height, weight: $weight, preExistingDiseases: $preExistingDiseases, medicationDetails: $medicationDetails)';
}

// ============= Mutual Fund Details =============
class MutualFundDetails {
  final String? folioNumber;

  MutualFundDetails({
    this.folioNumber,
  });

  factory MutualFundDetails.fromJson(Map<String, dynamic> json) {
    return MutualFundDetails(
      folioNumber: json['folioNumber'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (folioNumber != null) 'folioNumber': folioNumber,
    };
  }

  MutualFundDetails copyWith({
    String? folioNumber,
  }) {
    return MutualFundDetails(
      folioNumber: folioNumber ?? this.folioNumber,
    );
  }

  @override
  String toString() =>
      'MutualFundDetails(folioNumber: $folioNumber)';
}

// ============= Helper Functions =============

/// Parse UTC time from API response and convert to IST
DateTime _parseIST(String dateString) {
  final parsed = DateTime.parse(dateString);
  // Parse as UTC and convert to IST - return only the date part
  final ist = TimezoneUtil.utcToIST(parsed);
  return DateTime(ist.year, ist.month, ist.day);
}

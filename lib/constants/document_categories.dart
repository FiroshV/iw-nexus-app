// Document Categories Constants
// Used for mandatory document tracking during employee onboarding

class DocumentCategories {
  // Category identifiers (must match backend)
  static const String educationalCertificate = 'educational_certificate';
  static const String experienceCertificate = 'experience_certificate';
  static const String salarySlips = 'salary_slips';
  static const String identityProof = 'identity_proof';
  static const String addressProof = 'address_proof';
  static const String bankStatement = 'bank_statement';
  static const String panCard = 'pan_card';
  static const String other = 'other';

  /// List of mandatory document categories required for profile completion
  static const List<String> mandatoryCategories = [
    educationalCertificate,
    experienceCertificate,
    salarySlips,
    identityProof,
    addressProof,
    bankStatement,
    panCard,
  ];

  /// All document categories including optional ones
  static const List<String> allCategories = [
    educationalCertificate,
    experienceCertificate,
    salarySlips,
    identityProof,
    addressProof,
    bankStatement,
    panCard,
    other,
  ];

  /// Human-readable labels for each category
  static const Map<String, String> labels = {
    educationalCertificate: 'Educational Certificate',
    experienceCertificate: 'Experience Certificate',
    salarySlips: 'Salary Slips (Last 3 Months)',
    identityProof: 'Identity Proof',
    addressProof: 'Address Proof',
    bankStatement: 'Bank Statement',
    panCard: 'PAN Card',
    other: 'Other',
  };

  /// Descriptions for each category to guide users
  static const Map<String, String> descriptions = {
    educationalCertificate: 'Upload your highest education certificate',
    experienceCertificate:
        'Upload experience/relieving letter from previous employer',
    salarySlips: 'Upload last 3 months salary slips (combined as single PDF)',
    identityProof:
        'Upload government-issued ID (Aadhar, Passport, Voter ID, etc.)',
    addressProof: 'Upload address verification document',
    bankStatement: 'Upload recent bank statement',
    panCard: 'Upload PAN card copy',
    other: 'Upload any additional documents',
  };

  /// Get label for a category
  static String getLabel(String category) {
    return labels[category] ?? category;
  }

  /// Get description for a category
  static String getDescription(String category) {
    return descriptions[category] ?? '';
  }

  /// Check if a category is mandatory
  static bool isMandatory(String category) {
    return mandatoryCategories.contains(category);
  }
}

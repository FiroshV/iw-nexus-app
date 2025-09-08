class ProfileService {
  static const List<String> requiredFields = [
    'address',
    'phoneNumber', 
    'dateOfBirth',
    'bloodGroup',
  ];

  static bool isProfileComplete(Map<String, dynamic>? userData) {
    if (userData == null) return false;
    
    for (String field in requiredFields) {
      final value = userData[field];
      if (value == null || value.toString().trim().isEmpty) {
        return false;
      }
    }
    
    return true;
  }
}
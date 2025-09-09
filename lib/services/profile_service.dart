class ProfileService {
  static const List<String> requiredFields = [
    'firstName',
    'lastName', 
    'email',
    'designation',
    'address',
    'homePhoneNumber',
    'phoneNumber', 
    'dateOfBirth',
    'bloodGroup',
  ];

  static bool isProfileComplete(Map<String, dynamic>? userData) {
    if (userData == null) return false;
    
    // Check all required text fields
    for (String field in requiredFields) {
      final value = userData[field];
      if (value == null || value.toString().trim().isEmpty) {
        return false;
      }
    }
    
    // Check profile image (avatar)
    final avatar = userData['avatar'];
    if (avatar == null || avatar.toString().trim().isEmpty) {
      return false;
    }
    
    return true;
  }
}
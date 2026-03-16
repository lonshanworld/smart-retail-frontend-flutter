// lib/app/data/enums/user_role.dart
enum UserRole {
  admin,
  merchant,
  staff,
  unknown, // For default or error cases
}

// Helper function to convert string to UserRole
UserRole userRoleFromString(String? roleString) {
  if (roleString == null) return UserRole.unknown;
  switch (roleString.toLowerCase()) {
    case 'admin':
      return UserRole.admin;
    case 'merchant':
      return UserRole.merchant;
    case 'staff':
      return UserRole.staff;
    default:
      return UserRole.unknown;
  }
}

// Helper function to convert UserRole to string for display or API
String userRoleToString(UserRole role) {
  switch (role) {
    case UserRole.admin:
      return 'Admin';
    case UserRole.merchant:
      return 'Merchant';
    case UserRole.staff:
      return 'Staff';
    case UserRole.unknown:
      return 'Unknown';
  }
}

// Optional: Extension for easier conversion from string
extension UserRoleExtension on String {
  UserRole toUserRole() {
    return userRoleFromString(this);
  }
}

// Optional: Extension for easier conversion to display string
extension UserRoleDisplayExtension on UserRole {
  String toDisplayString() {
    return userRoleToString(this);
  }
}

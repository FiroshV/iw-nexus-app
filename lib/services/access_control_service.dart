import 'package:flutter/foundation.dart';

/// Centralized Access Control Service for IW Nexus HRMS Flutter App
/// 
/// This service defines feature-based permissions for all user roles.
/// Instead of hardcoding role checks throughout the application,
/// use this service to maintain a single source of truth for access control.
class AccessControlService {
  static const Map<String, Map<String, List<String>>> _accessPermissions = {
    // User Management Features
    'user_management': {
      'view': ['admin', 'director', 'manager'],
      'create': ['admin', 'director'],
      'edit': ['admin', 'director'],
      'delete': ['admin', 'director'],
      'view_profile': ['admin', 'manager', 'director', 'field_staff', 'telecaller']
    },

    // Employment Status Management
    'employment_status': {
      'view': ['admin', 'director', 'manager'],
      'edit': ['admin', 'director', 'manager'],
      'edit_manager': ['admin', 'director']
    },

    // Branch Management Features  
    'branch_management': {
      'view': ['admin', 'manager', 'director'],
      'create': ['admin', 'director'],
      'edit': ['admin', 'director'], 
      'delete': ['admin', 'director']
    },

    // Attendance Features
    'attendance': {
      'view_own': ['admin', 'manager', 'director', 'field_staff', 'telecaller'],
      'view_team': ['admin', 'manager', 'director'],
      'view_all': ['admin', 'director'],
      'check_in': ['admin', 'manager', 'director', 'field_staff', 'telecaller'],
      'check_out': ['admin', 'manager', 'director', 'field_staff', 'telecaller'],
      'edit_attendance': ['admin', 'director', 'manager'],
      'approve_attendance': ['admin', 'director', 'manager']
    },

    // Reports Features
    'reports': {
      'attendance_reports': ['admin', 'manager', 'director'],
      'payroll_reports': ['admin', 'director'],
      'team_reports': ['admin', 'manager', 'director'],
      'export_reports': ['admin', 'director', 'manager']
    },

    // Settings Features
    'settings': {
      'company_settings': ['admin', 'director'],
      'branch_settings': ['admin', 'director', 'manager'],
      'user_preferences': ['admin', 'manager', 'director', 'field_staff', 'telecaller'],
      'system_settings': ['admin', 'director']
    },

    // Dashboard Features
    'dashboard': {
      'admin_dashboard': ['admin', 'director'],
      'manager_dashboard': ['admin', 'manager', 'director'],
      'employee_dashboard': ['admin', 'manager', 'director', 'field_staff', 'telecaller']
    }
  };

  /// Check if a user role has access to a specific feature action
  /// 
  /// [userRole] - The user's role
  /// [feature] - The feature name (e.g., 'user_management')
  /// [action] - The action name (e.g., 'create', 'edit', 'delete')
  /// 
  /// Returns true if user has access, false otherwise
  static bool hasAccess(String? userRole, String feature, [String action = 'view']) {
    if (userRole == null || userRole.isEmpty || feature.isEmpty) {
      return false;
    }

    final featurePermissions = _accessPermissions[feature];
    if (featurePermissions == null) {
      debugPrint('Warning: Feature \'$feature\' not found in access permissions');
      return false;
    }

    final allowedRoles = featurePermissions[action];
    if (allowedRoles == null) {
      debugPrint('Warning: Action \'$action\' not found for feature \'$feature\'');
      return false;
    }

    return allowedRoles.contains(userRole.toLowerCase());
  }

  /// Get all allowed actions for a user role on a specific feature
  /// 
  /// [userRole] - The user's role
  /// [feature] - The feature name
  /// 
  /// Returns array of allowed actions
  static List<String> getAllowedActions(String? userRole, String feature) {
    if (userRole == null || userRole.isEmpty || feature.isEmpty) {
      return [];
    }

    final featurePermissions = _accessPermissions[feature];
    if (featurePermissions == null) {
      return [];
    }

    final allowedActions = <String>[];
    for (final entry in featurePermissions.entries) {
      if (entry.value.contains(userRole.toLowerCase())) {
        allowedActions.add(entry.key);
      }
    }

    return allowedActions;
  }

  /// Get all features accessible to a user role
  /// 
  /// [userRole] - The user's role
  /// 
  /// Returns array of accessible feature names
  static List<String> getAccessibleFeatures(String? userRole) {
    if (userRole == null || userRole.isEmpty) {
      return [];
    }

    final accessibleFeatures = <String>[];
    for (final entry in _accessPermissions.entries) {
      // Check if user has at least view access to the feature
      if (hasAccess(userRole, entry.key, 'view') || hasAccess(userRole, entry.key, 'view_own')) {
        accessibleFeatures.add(entry.key);
      }
    }

    return accessibleFeatures;
  }

  /// Check if user can access their own data vs others' data
  /// 
  /// [userRole] - The user's role
  /// [targetUserId] - The ID of the user being accessed
  /// [currentUserId] - The ID of the current user
  /// [feature] - The feature name
  /// 
  /// Returns true if access is allowed
  static bool canAccessUserData(String? userRole, String? targetUserId, String? currentUserId, [String feature = 'user_management']) {
    if (userRole == null || targetUserId == null || currentUserId == null) {
      return false;
    }

    // Admin and HR can access all user data
    if (hasAccess(userRole, feature, 'view_all') || hasAccess(userRole, feature, 'view_team')) {
      return true;
    }

    // Users can access their own data
    if (targetUserId == currentUserId && hasAccess(userRole, feature, 'view_profile')) {
      return true;
    }

    return false;
  }

  /// Convenient method to check admin access (backward compatibility)
  /// 
  /// [userRole] - The user's role
  /// 
  /// Returns true if user is admin or director
  static bool isAdmin(String? userRole) {
    if (userRole == null || userRole.isEmpty) {
      return false;
    }
    
    final role = userRole.toLowerCase();
    return role == 'admin' || role == 'administrator' || role == 'director';
  }

  /// Check if user can manage other users
  /// 
  /// [userRole] - The user's role
  /// 
  /// Returns true if user can manage users
  static bool canManageUsers(String? userRole) {
    return hasAccess(userRole, 'user_management', 'create') || 
           hasAccess(userRole, 'user_management', 'edit');
  }

  /// Check if user can manage branches
  /// 
  /// [userRole] - The user's role
  /// 
  /// Returns true if user can manage branches
  static bool canManageBranches(String? userRole) {
    return hasAccess(userRole, 'branch_management', 'create') || 
           hasAccess(userRole, 'branch_management', 'edit');
  }

  /// Check if user can view attendance reports
  /// 
  /// [userRole] - The user's role
  /// 
  /// Returns true if user can view attendance reports
  static bool canViewAttendanceReports(String? userRole) {
    return hasAccess(userRole, 'reports', 'attendance_reports');
  }

  /// Check if user can edit attendance
  /// 
  /// [userRole] - The user's role
  /// 
  /// Returns true if user can edit attendance
  static bool canEditAttendance(String? userRole) {
    return hasAccess(userRole, 'attendance', 'edit_attendance');
  }

  /// Get user's dashboard type based on role
  /// 
  /// [userRole] - The user's role
  /// 
  /// Returns dashboard type string
  static String getDashboardType(String? userRole) {
    if (hasAccess(userRole, 'dashboard', 'admin_dashboard')) {
      return 'admin_dashboard';
    } else if (hasAccess(userRole, 'dashboard', 'manager_dashboard')) {
      return 'manager_dashboard';
    } else {
      return 'employee_dashboard';
    }
  }

  /// Check if user can edit employment status based on target user's role
  ///
  /// [requesterRole] - The requesting user's role
  /// [targetUserRole] - The target user's role
  ///
  /// Returns true if requester can edit target's employment status
  static bool canEditEmploymentStatus(String? requesterRole, String? targetUserRole) {
    if (requesterRole == null || targetUserRole == null) {
      return false;
    }

    // Admin and director can edit anyone's employment status
    if (hasAccess(requesterRole, 'employment_status', 'edit_manager')) {
      return true;
    }

    // Manager can only edit employment status for general employees (not other managers/directors)
    if (hasAccess(requesterRole, 'employment_status', 'edit')) {
      final managerRoles = ['manager', 'director', 'admin'];
      return !managerRoles.contains(targetUserRole.toLowerCase());
    }

    return false;
  }

  /// Debug method to print all permissions for a role
  ///
  /// [userRole] - The user's role
  static void debugPermissions(String? userRole) {
    if (!kDebugMode) return;

    debugPrint('🔐 Permissions for role: $userRole');
    for (final feature in _accessPermissions.keys) {
      final actions = getAllowedActions(userRole, feature);
      if (actions.isNotEmpty) {
        debugPrint('  $feature: ${actions.join(', ')}');
      }
    }
  }
}
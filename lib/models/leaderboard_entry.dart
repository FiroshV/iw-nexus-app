library;

/// Leaderboard Entry Models (SIMPLIFIED - Actual Metrics Only)
///
/// Rankings based on actual sales count, sales amount, activities, etc.

import 'gamification_profile.dart';

// ============================================
// HELPER FUNCTIONS
// ============================================

int _parseInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  return int.tryParse(value.toString()) ?? 0;
}

// ============================================
// LEADERBOARD USER INFO
// ============================================

class LeaderboardUserInfo {
  final String id;
  final String firstName;
  final String lastName;
  final String? employeeId;
  final String? branchId;
  final String? role;

  LeaderboardUserInfo({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.employeeId,
    this.branchId,
    this.role,
  });

  factory LeaderboardUserInfo.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return LeaderboardUserInfo(id: '', firstName: '', lastName: '');
    }
    return LeaderboardUserInfo(
      id: json['_id'] as String? ?? '',
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      employeeId: json['employeeId'] as String?,
      branchId: json['branchId'] as String?,
      role: json['role'] as String?,
    );
  }

  String get fullName => '$firstName $lastName'.trim();

  String get initials {
    final first = firstName.isNotEmpty ? firstName[0].toUpperCase() : '';
    final last = lastName.isNotEmpty ? lastName[0].toUpperCase() : '';
    return '$first$last';
  }
}

// ============================================
// LEADERBOARD ENTRY MODEL (SIMPLIFIED - Actual Metrics)
// ============================================

class LeaderboardEntry {
  final int rank;
  final String id;
  final String profileId;
  final String userId;
  final LeaderboardUserInfo user;
  final GamificationStats stats;
  final CurrentStreak currentStreak;
  final LongestStreak longestStreak;
  final DateTime? lastActiveAt;

  LeaderboardEntry({
    required this.rank,
    required this.id,
    required this.profileId,
    required this.userId,
    required this.user,
    required this.stats,
    required this.currentStreak,
    required this.longestStreak,
    this.lastActiveAt,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      rank: _parseInt(json['rank']),
      id: json['id'] as String? ?? '',
      profileId: json['profileId'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      user: LeaderboardUserInfo.fromJson(json['user'] as Map<String, dynamic>?),
      stats: GamificationStats.fromJson(json['stats'] as Map<String, dynamic>?),
      currentStreak:
          CurrentStreak.fromJson(json['currentStreak'] as Map<String, dynamic>?),
      longestStreak:
          LongestStreak.fromJson(json['longestStreak'] as Map<String, dynamic>?),
      lastActiveAt: json['lastActiveAt'] != null
          ? DateTime.tryParse(json['lastActiveAt'].toString())
          : null,
    );
  }

  // Helper to check if this is a top position
  bool get isTop3 => rank <= 3;
  bool get isTop10 => rank <= 10;
}

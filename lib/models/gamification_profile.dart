library;

/// Gamification Profile Models (SIMPLIFIED - Leaderboards Only)
///
/// No points, no badges, no challenges - just leaderboards based on actual metrics

// ============================================
// HELPER FUNCTIONS
// ============================================

int _parseInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  return int.tryParse(value.toString()) ?? 0;
}

double _parseDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0.0;
}

DateTime? _parseDateTime(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  return DateTime.tryParse(value.toString());
}

// ============================================
// STREAK MODELS
// ============================================

class CurrentStreak {
  final String? type;
  final int count;
  final DateTime? startDate;
  final DateTime? lastActivityDate;

  CurrentStreak({
    this.type,
    required this.count,
    this.startDate,
    this.lastActivityDate,
  });

  factory CurrentStreak.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return CurrentStreak(count: 0);
    }
    return CurrentStreak(
      type: json['type'] as String?,
      count: _parseInt(json['count']),
      startDate: _parseDateTime(json['startDate']),
      lastActivityDate: _parseDateTime(json['lastActivityDate']),
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type,
        'count': count,
        'startDate': startDate?.toIso8601String(),
        'lastActivityDate': lastActivityDate?.toIso8601String(),
      };
}

class LongestStreak {
  final int sales;
  final int activity;
  final int login;

  LongestStreak({
    required this.sales,
    required this.activity,
    required this.login,
  });

  factory LongestStreak.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return LongestStreak(sales: 0, activity: 0, login: 0);
    }
    return LongestStreak(
      sales: _parseInt(json['sales']),
      activity: _parseInt(json['activity']),
      login: _parseInt(json['login']),
    );
  }

  Map<String, dynamic> toJson() => {
        'sales': sales,
        'activity': activity,
        'login': login,
      };
}

// ============================================
// STATS MODEL (used for leaderboard rankings)
// ============================================

class GamificationStats {
  final int totalSalesCount;
  final double totalSalesAmount;
  final int totalCallsCount;
  final int totalAppointmentsCompleted;
  final int totalActivitiesCount;
  final int targetsAchievedCount;

  GamificationStats({
    required this.totalSalesCount,
    required this.totalSalesAmount,
    required this.totalCallsCount,
    required this.totalAppointmentsCompleted,
    required this.totalActivitiesCount,
    required this.targetsAchievedCount,
  });

  factory GamificationStats.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return GamificationStats(
        totalSalesCount: 0,
        totalSalesAmount: 0,
        totalCallsCount: 0,
        totalAppointmentsCompleted: 0,
        totalActivitiesCount: 0,
        targetsAchievedCount: 0,
      );
    }
    return GamificationStats(
      totalSalesCount: _parseInt(json['totalSalesCount']),
      totalSalesAmount: _parseDouble(json['totalSalesAmount']),
      totalCallsCount: _parseInt(json['totalCallsCount']),
      totalAppointmentsCompleted: _parseInt(json['totalAppointmentsCompleted']),
      totalActivitiesCount: _parseInt(json['totalActivitiesCount']),
      targetsAchievedCount: _parseInt(json['targetsAchievedCount']),
    );
  }

  Map<String, dynamic> toJson() => {
        'totalSalesCount': totalSalesCount,
        'totalSalesAmount': totalSalesAmount,
        'totalCallsCount': totalCallsCount,
        'totalAppointmentsCompleted': totalAppointmentsCompleted,
        'totalActivitiesCount': totalActivitiesCount,
        'targetsAchievedCount': targetsAchievedCount,
      };
}

// ============================================
// PREFERENCES MODEL (simplified - just leaderboard visibility)
// ============================================

class GamificationPreferences {
  final bool showOnLeaderboard;

  GamificationPreferences({
    required this.showOnLeaderboard,
  });

  factory GamificationPreferences.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return GamificationPreferences(showOnLeaderboard: true);
    }
    return GamificationPreferences(
      showOnLeaderboard: json['showOnLeaderboard'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'showOnLeaderboard': showOnLeaderboard,
      };
}

// ============================================
// USER INFO FOR PROFILE
// ============================================

class ProfileUserInfo {
  final String id;
  final String firstName;
  final String lastName;
  final String? employeeId;
  final String? email;
  final String? role;
  final String? branchId;

  ProfileUserInfo({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.employeeId,
    this.email,
    this.role,
    this.branchId,
  });

  factory ProfileUserInfo.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return ProfileUserInfo(id: '', firstName: '', lastName: '');
    }
    return ProfileUserInfo(
      id: json['_id'] as String? ?? '',
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      employeeId: json['employeeId'] as String?,
      email: json['email'] as String?,
      role: json['role'] as String?,
      branchId: json['branchId'] as String?,
    );
  }

  String get fullName => '$firstName $lastName'.trim();
}

// ============================================
// MAIN GAMIFICATION PROFILE MODEL (SIMPLIFIED - Leaderboards only)
// ============================================

class GamificationProfile {
  final String id;
  final String profileId;
  final ProfileUserInfo? user;
  final CurrentStreak currentStreak;
  final LongestStreak longestStreak;
  final GamificationStats stats;
  final GamificationPreferences preferences;
  final DateTime? lastActiveAt;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  GamificationProfile({
    required this.id,
    required this.profileId,
    this.user,
    required this.currentStreak,
    required this.longestStreak,
    required this.stats,
    required this.preferences,
    this.lastActiveAt,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  factory GamificationProfile.fromJson(Map<String, dynamic> json) {
    return GamificationProfile(
      id: json['_id'] as String? ?? '',
      profileId: json['profileId'] as String? ?? '',
      user: json['userId'] is Map<String, dynamic>
          ? ProfileUserInfo.fromJson(json['userId'] as Map<String, dynamic>)
          : null,
      currentStreak:
          CurrentStreak.fromJson(json['currentStreak'] as Map<String, dynamic>?),
      longestStreak:
          LongestStreak.fromJson(json['longestStreak'] as Map<String, dynamic>?),
      stats: GamificationStats.fromJson(json['stats'] as Map<String, dynamic>?),
      preferences: GamificationPreferences.fromJson(
          json['preferences'] as Map<String, dynamic>?),
      lastActiveAt: _parseDateTime(json['lastActiveAt']),
      isActive: json['isActive'] as bool? ?? true,
      createdAt: _parseDateTime(json['createdAt']),
      updatedAt: _parseDateTime(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'profileId': profileId,
        'currentStreak': currentStreak.toJson(),
        'longestStreak': longestStreak.toJson(),
        'stats': stats.toJson(),
        'preferences': preferences.toJson(),
        'lastActiveAt': lastActiveAt?.toIso8601String(),
        'isActive': isActive,
      };
}

// ============================================
// METRIC RANK (for individual metric rankings)
// ============================================

class MetricRank {
  final int? rank;
  final int totalParticipants;
  final String metric;
  final int value;

  MetricRank({
    this.rank,
    required this.totalParticipants,
    required this.metric,
    required this.value,
  });

  factory MetricRank.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return MetricRank(
        rank: null,
        totalParticipants: 0,
        metric: 'sales_count',
        value: 0,
      );
    }
    return MetricRank(
      rank: json['rank'] as int?,
      totalParticipants: _parseInt(json['totalParticipants']),
      metric: json['metric'] as String? ?? 'sales_count',
      value: _parseInt(json['value']),
    );
  }
}

// ============================================
// RANKINGS (collection of metric ranks)
// ============================================

class Rankings {
  final MetricRank salesCount;
  final MetricRank salesAmount;
  final MetricRank activities;

  Rankings({
    required this.salesCount,
    required this.salesAmount,
    required this.activities,
  });

  factory Rankings.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return Rankings(
        salesCount: MetricRank.fromJson(null),
        salesAmount: MetricRank.fromJson(null),
        activities: MetricRank.fromJson(null),
      );
    }
    return Rankings(
      salesCount:
          MetricRank.fromJson(json['salesCount'] as Map<String, dynamic>?),
      salesAmount:
          MetricRank.fromJson(json['salesAmount'] as Map<String, dynamic>?),
      activities:
          MetricRank.fromJson(json['activities'] as Map<String, dynamic>?),
    );
  }
}

// ============================================
// GAMIFICATION SUMMARY (API RESPONSE)
// ============================================

class GamificationSummary {
  final GamificationProfile profile;
  final Rankings rankings;

  GamificationSummary({
    required this.profile,
    required this.rankings,
  });

  factory GamificationSummary.fromJson(Map<String, dynamic> json) {
    return GamificationSummary(
      profile: GamificationProfile.fromJson(
          json['profile'] as Map<String, dynamic>? ?? {}),
      rankings:
          Rankings.fromJson(json['rankings'] as Map<String, dynamic>?),
    );
  }
}

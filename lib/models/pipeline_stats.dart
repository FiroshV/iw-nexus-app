class PipelineStatsData {
  final int newLeads;
  final ActiveStats active;
  final ClosedWonStats closedWon;
  final int closedLost;
  final int overdueFollowups;
  final String view;

  PipelineStatsData({
    required this.newLeads,
    required this.active,
    required this.closedWon,
    required this.closedLost,
    required this.overdueFollowups,
    required this.view,
  });

  factory PipelineStatsData.fromJson(Map<String, dynamic> json) {
    final activeData = json['active'] as Map<String, dynamic>? ?? {};
    final closedWonData = json['closedWon'] as Map<String, dynamic>? ?? {};

    return PipelineStatsData(
      newLeads: json['newLeads'] ?? 0,
      active: ActiveStats.fromJson(activeData),
      closedWon: ClosedWonStats.fromJson(closedWonData),
      closedLost: json['closedLost'] ?? 0,
      overdueFollowups: json['overdueFollowups'] ?? 0,
      view: json['view'] ?? 'assigned',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'newLeads': newLeads,
      'active': active.toJson(),
      'closedWon': closedWon.toJson(),
      'closedLost': closedLost,
      'overdueFollowups': overdueFollowups,
      'view': view,
    };
  }
}

class ActiveStats {
  final int total;
  final Map<String, int> breakdown;

  ActiveStats({
    required this.total,
    required this.breakdown,
  });

  factory ActiveStats.fromJson(Map<String, dynamic> json) {
    final breakdown = <String, int>{};
    final breakdownData = json['breakdown'] as Map<String, dynamic>? ?? {};

    breakdownData.forEach((key, value) {
      breakdown[key] = (value as num?)?.toInt() ?? 0;
    });

    return ActiveStats(
      total: (json['total'] as num?)?.toInt() ?? 0,
      breakdown: breakdown,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total': total,
      'breakdown': breakdown,
    };
  }

  int getCount(String status) => breakdown[status] ?? 0;
}

class ClosedWonStats {
  final int count;
  final double totalRevenue;

  ClosedWonStats({
    required this.count,
    required this.totalRevenue,
  });

  factory ClosedWonStats.fromJson(Map<String, dynamic> json) {
    return ClosedWonStats(
      count: (json['count'] as num?)?.toInt() ?? 0,
      totalRevenue: (json['totalRevenue'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'count': count,
      'totalRevenue': totalRevenue,
    };
  }
}

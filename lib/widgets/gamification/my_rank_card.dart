import 'package:flutter/material.dart';
import '../../config/crm_colors.dart';
import '../../config/crm_design_system.dart';
import '../../models/gamification_profile.dart';
import '../../utils/currency_formatter.dart';

/// My rank card widget
///
/// Highlighted card showing current user's position in the leaderboard
/// Displayed when user is not in top 10
class MyRankCard extends StatelessWidget {
  final int? rank;
  final int total;
  final GamificationProfile? profile;
  final String metric;

  const MyRankCard({
    super.key,
    this.rank,
    required this.total,
    this.profile,
    this.metric = 'sales_count',
  });

  String _getMetricValue() {
    if (profile == null) return '0';

    final stats = profile!.stats;
    switch (metric) {
      case 'sales_count':
        return '${stats.totalSalesCount} sales';
      case 'sales_amount':
        return CurrencyFormatter.format(stats.totalSalesAmount);
      case 'calls_count':
        return '${stats.totalCallsCount} calls';
      case 'activities_count':
        return '${stats.totalActivitiesCount} activities';
      default:
        return '0';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(CrmDesignSystem.lg),
      padding: EdgeInsets.all(CrmDesignSystem.lg),
      decoration: BoxDecoration(
        color: CrmColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(CrmDesignSystem.radiusLarge),
        border: Border.all(
          color: CrmColors.primary,
          width: 2,
        ),
        boxShadow: CrmDesignSystem.elevationMedium,
      ),
      child: Row(
        children: [
          // Rank badge
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: CrmDesignSystem.lg,
              vertical: CrmDesignSystem.md,
            ),
            decoration: BoxDecoration(
              color: CrmColors.primary,
              borderRadius: BorderRadius.circular(CrmDesignSystem.radiusMedium),
            ),
            child: Column(
              children: [
                Text(
                  rank != null ? '#$rank' : '--',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'of $total',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: CrmDesignSystem.lg),
          // User info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Your Rank',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: CrmDesignSystem.sm),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: CrmDesignSystem.sm,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: CrmColors.primary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'YOU',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: CrmDesignSystem.xs),
                Text(
                  _getMetricValue(),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: CrmColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

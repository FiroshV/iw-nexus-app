import 'package:flutter/material.dart';
import '../../config/crm_colors.dart';
import '../../config/crm_design_system.dart';
import '../../models/leaderboard_entry.dart';
import '../../utils/currency_formatter.dart';

/// Podium widget for top 3 performers
///
/// Visual display with medals and varying heights:
/// - 1st place (center, tallest)
/// - 2nd place (left, medium)
/// - 3rd place (right, shortest)
class PodiumWidget extends StatelessWidget {
  final LeaderboardEntry first;
  final LeaderboardEntry second;
  final LeaderboardEntry third;
  final String metric;

  const PodiumWidget({
    super.key,
    required this.first,
    required this.second,
    required this.third,
    this.metric = 'sales_count',
  });

  String _getMetricValue(LeaderboardEntry entry) {
    final stats = entry.stats;
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

  Widget _buildPodiumPosition({
    required LeaderboardEntry entry,
    required Color color,
    required double height,
    required String medal,
    required int position,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Medal
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: CrmDesignSystem.elevationMedium,
          ),
          child: Center(
            child: Text(
              medal,
              style: const TextStyle(fontSize: 24),
            ),
          ),
        ),
        SizedBox(height: CrmDesignSystem.sm),
        // User name
        Text(
          entry.user.fullName.split(' ')[0], // First name only
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 2),
        // Metric value
        Text(
          _getMetricValue(entry),
          style: TextStyle(
            fontSize: 10,
            color: CrmColors.textLight,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: CrmDesignSystem.sm),
        // Podium stand
        Container(
          width: 100,
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color.withValues(alpha: 0.3),
                color.withValues(alpha: 0.1),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(CrmDesignSystem.radiusMedium),
            ),
            border: Border.all(
              color: color.withValues(alpha: 0.5),
              width: 2,
            ),
          ),
          child: Center(
            child: Text(
              '#$position',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w900,
                color: color.withValues(alpha: 0.3),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(CrmDesignSystem.lg),
      margin: EdgeInsets.symmetric(
        horizontal: CrmDesignSystem.lg,
        vertical: CrmDesignSystem.md,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(CrmDesignSystem.radiusLarge),
        boxShadow: CrmDesignSystem.elevationMedium,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.emoji_events_rounded,
                  color: Colors.amber, size: 24),
              SizedBox(width: CrmDesignSystem.sm),
              const Text(
                'Top 3 Performers',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SizedBox(height: CrmDesignSystem.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 2nd place (left)
              Expanded(
                child: _buildPodiumPosition(
                  entry: second,
                  color: Colors.grey.shade400,
                  height: 100,
                  medal: '🥈',
                  position: 2,
                ),
              ),
              SizedBox(width: CrmDesignSystem.sm),
              // 1st place (center, tallest)
              Expanded(
                child: _buildPodiumPosition(
                  entry: first,
                  color: Colors.amber,
                  height: 120,
                  medal: '🥇',
                  position: 1,
                ),
              ),
              SizedBox(width: CrmDesignSystem.sm),
              // 3rd place (right)
              Expanded(
                child: _buildPodiumPosition(
                  entry: third,
                  color: Colors.orange.shade300,
                  height: 80,
                  medal: '🥉',
                  position: 3,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

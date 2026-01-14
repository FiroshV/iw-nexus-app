import 'package:flutter/material.dart';
import '../../config/crm_colors.dart';
import '../../config/crm_design_system.dart';
import '../../models/leaderboard_entry.dart';
import 'leaderboard_item.dart';

/// Leaderboard card widget for gamification dashboard
///
/// Shows top 10 performers with a "View All" button
/// Displays loading and empty states
class LeaderboardCard extends StatelessWidget {
  final List<LeaderboardEntry> leaderboard;
  final bool isLoading;
  final VoidCallback? onViewAll;

  const LeaderboardCard({
    super.key,
    required this.leaderboard,
    this.isLoading = false,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(CrmDesignSystem.radiusLarge),
        boxShadow: CrmDesignSystem.elevationMedium,
      ),
      padding: EdgeInsets.all(CrmDesignSystem.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.leaderboard_rounded,
                  color: CrmColors.brand, size: 24),
              SizedBox(width: CrmDesignSystem.sm),
              const Expanded(
                child: Text(
                  'Top Performers',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (onViewAll != null)
                TextButton(
                  onPressed: onViewAll,
                  child: const Text('View All'),
                ),
            ],
          ),
          SizedBox(height: CrmDesignSystem.md),
          if (isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            )
          else if (leaderboard.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('No data available'),
              ),
            )
          else
            ...leaderboard
                .take(10)
                .map((entry) => LeaderboardItemWidget(entry: entry)),
        ],
      ),
    );
  }
}

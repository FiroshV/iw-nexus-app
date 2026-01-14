import 'package:flutter/material.dart';
import '../../config/crm_colors.dart';
import '../../config/crm_design_system.dart';

/// Empty state widget for leaderboard
///
/// Displayed when no leaderboard data is available
class LeaderboardEmptyState extends StatelessWidget {
  const LeaderboardEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(CrmDesignSystem.xxxl),
      decoration: BoxDecoration(
        color: CrmColors.surface,
        borderRadius: BorderRadius.circular(CrmDesignSystem.radiusLarge),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.leaderboard_outlined,
              size: 64,
              color: CrmColors.textLight.withValues(alpha: 0.5),
            ),
            SizedBox(height: CrmDesignSystem.lg),
            const Text(
              'No leaderboard data',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: CrmColors.textDark,
              ),
            ),
            SizedBox(height: CrmDesignSystem.sm),
            Text(
              'Start tracking activities to appear on the leaderboard',
              style: TextStyle(
                fontSize: 14,
                color: CrmColors.textLight,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

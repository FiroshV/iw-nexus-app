import 'package:flutter/material.dart';
import '../../config/crm_colors.dart';
import '../../config/crm_design_system.dart';
import '../../models/gamification_profile.dart';
import '../../utils/currency_formatter.dart';
import 'stat_item.dart';

/// User stats card for gamification dashboard
///
/// Displays user's key metrics in a 2x2 grid:
/// - Sales count and revenue
/// - Calls and activities
/// - Current streak (if active)
class StatsCard extends StatelessWidget {
  final GamificationProfile? profile;

  const StatsCard({
    super.key,
    this.profile,
  });

  @override
  Widget build(BuildContext context) {
    final stats = profile?.stats;
    final streak = profile?.currentStreak;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [CrmColors.brand, CrmColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(CrmDesignSystem.radiusLarge),
        boxShadow: CrmDesignSystem.elevationMedium,
      ),
      padding: EdgeInsets.all(CrmDesignSystem.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Stats',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: CrmDesignSystem.lg),
          Row(
            children: [
              Expanded(
                child: StatItem(
                  label: 'Sales',
                  value: '${stats?.totalSalesCount ?? 0}',
                  icon: Icons.trending_up_rounded,
                ),
              ),
              Expanded(
                child: StatItem(
                  label: 'Revenue',
                  value: CurrencyFormatter.format(stats?.totalSalesAmount ?? 0),
                  icon: Icons.currency_rupee_rounded,
                ),
              ),
            ],
          ),
          SizedBox(height: CrmDesignSystem.md),
          Row(
            children: [
              Expanded(
                child: StatItem(
                  label: 'Calls',
                  value: '${stats?.totalCallsCount ?? 0}',
                  icon: Icons.phone_rounded,
                ),
              ),
              Expanded(
                child: StatItem(
                  label: 'Activities',
                  value: '${stats?.totalActivitiesCount ?? 0}',
                  icon: Icons.checklist_rounded,
                ),
              ),
            ],
          ),
          if (streak != null && streak.count > 0) ...[
            SizedBox(height: CrmDesignSystem.lg),
            Container(
              padding: EdgeInsets.all(CrmDesignSystem.md),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(CrmDesignSystem.radiusMedium),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.local_fire_department_rounded,
                    color: Colors.orange,
                    size: 24,
                  ),
                  SizedBox(width: CrmDesignSystem.sm),
                  Text(
                    '${streak.count} day ${streak.type} streak!',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

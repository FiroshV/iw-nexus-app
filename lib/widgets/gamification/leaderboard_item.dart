import 'package:flutter/material.dart';
import '../../config/crm_colors.dart';
import '../../config/crm_design_system.dart';
import '../../models/leaderboard_entry.dart';
import '../../utils/currency_formatter.dart';

/// Single leaderboard entry widget
///
/// Displays rank, user info, and stats for one leaderboard entry
/// Highlights top 3 with medal colors (gold, silver, bronze)
class LeaderboardItemWidget extends StatelessWidget {
  final LeaderboardEntry entry;
  final bool isCurrentUser;

  const LeaderboardItemWidget({
    super.key,
    required this.entry,
    this.isCurrentUser = false,
  });

  @override
  Widget build(BuildContext context) {
    final isTopThree = entry.rank <= 3;
    final medalColor = entry.rank == 1
        ? Colors.amber
        : entry.rank == 2
            ? Colors.grey.shade400
            : Colors.orange.shade300;

    return Container(
      margin: EdgeInsets.only(bottom: CrmDesignSystem.sm),
      padding: EdgeInsets.all(CrmDesignSystem.md),
      decoration: BoxDecoration(
        color: isCurrentUser
            ? CrmColors.primary.withValues(alpha: 0.05)
            : isTopThree
                ? medalColor.withValues(alpha: 0.1)
                : CrmColors.surface,
        borderRadius: BorderRadius.circular(CrmDesignSystem.radiusMedium),
        border: isCurrentUser
            ? Border.all(
                color: CrmColors.primary,
                width: 2,
              )
            : null,
      ),
      child: Row(
        children: [
          // Rank circle
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isTopThree ? medalColor : CrmColors.secondary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${entry.rank}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          SizedBox(width: CrmDesignSystem.md),
          // User info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.user.fullName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (isCurrentUser)
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
                if (entry.user.employeeId != null)
                  Text(
                    entry.user.employeeId!,
                    style: TextStyle(
                      fontSize: 12,
                      color: CrmColors.textLight,
                    ),
                  ),
              ],
            ),
          ),
          // Stats
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${entry.stats.totalSalesCount} sales',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                CurrencyFormatter.format(entry.stats.totalSalesAmount),
                style: TextStyle(
                  fontSize: 12,
                  color: CrmColors.textLight,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

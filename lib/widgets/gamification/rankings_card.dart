import 'package:flutter/material.dart';
import '../../config/crm_colors.dart';
import '../../config/crm_design_system.dart';
import '../../models/gamification_profile.dart';
import 'rank_item.dart';

/// User rankings card for gamification dashboard
///
/// Shows user's rank across different metrics:
/// - Sales Count
/// - Sales Amount
/// - Activities
class RankingsCard extends StatelessWidget {
  final Rankings? rankings;

  const RankingsCard({
    super.key,
    this.rankings,
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
              const Icon(Icons.emoji_events_rounded,
                  color: CrmColors.primary, size: 24),
              SizedBox(width: CrmDesignSystem.sm),
              const Text(
                'Your Rankings',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SizedBox(height: CrmDesignSystem.lg),
          RankItem(
            label: 'Sales Count',
            rank: rankings?.salesCount.rank,
            total: rankings?.salesCount.totalParticipants ?? 0,
            icon: Icons.shopping_cart_rounded,
          ),
          SizedBox(height: CrmDesignSystem.md),
          RankItem(
            label: 'Sales Amount',
            rank: rankings?.salesAmount.rank,
            total: rankings?.salesAmount.totalParticipants ?? 0,
            icon: Icons.currency_rupee_rounded,
          ),
          SizedBox(height: CrmDesignSystem.md),
          RankItem(
            label: 'Activities',
            rank: rankings?.activities.rank,
            total: rankings?.activities.totalParticipants ?? 0,
            icon: Icons.checklist_rounded,
          ),
        ],
      ),
    );
  }
}

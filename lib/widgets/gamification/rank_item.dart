import 'package:flutter/material.dart';
import '../../config/crm_colors.dart';
import '../../config/crm_design_system.dart';

/// Individual rank item widget for gamification rankings
///
/// Shows a metric label, icon, and rank badge
/// Highlights top 3 ranks with amber background
class RankItem extends StatelessWidget {
  final String label;
  final int? rank;
  final int total;
  final IconData icon;

  const RankItem({
    super.key,
    required this.label,
    required this.rank,
    required this.total,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: CrmColors.secondary, size: 20),
        SizedBox(width: CrmDesignSystem.sm),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: CrmDesignSystem.md,
            vertical: CrmDesignSystem.xs,
          ),
          decoration: BoxDecoration(
            color: rank != null && rank! <= 3
                ? Colors.amber.withValues(alpha: 0.2)
                : CrmColors.surface,
            borderRadius: BorderRadius.circular(CrmDesignSystem.radiusMedium),
          ),
          child: Text(
            rank != null ? '#$rank / $total' : '-- / $total',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: rank != null && rank! <= 3
                  ? Colors.amber.shade800
                  : CrmColors.textDark,
            ),
          ),
        ),
      ],
    );
  }
}

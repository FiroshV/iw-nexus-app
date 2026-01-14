import 'package:flutter/material.dart';
import '../../config/crm_colors.dart';
import '../../config/crm_design_system.dart';

/// Leaderboard filter bar widget
///
/// Provides metric filtering and optional branch filtering
/// Metrics: Sales Count, Sales Amount, Activities, Calls
class LeaderboardFilterBar extends StatelessWidget {
  final String selectedMetric;
  final ValueChanged<String> onMetricChanged;
  final String? userRole;

  const LeaderboardFilterBar({
    super.key,
    required this.selectedMetric,
    required this.onMetricChanged,
    this.userRole,
  });

  Widget _buildMetricButton({
    required String label,
    required String value,
    required IconData icon,
  }) {
    final isSelected = selectedMetric == value;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onMetricChanged(value),
        borderRadius: BorderRadius.circular(CrmDesignSystem.radiusMedium),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: CrmDesignSystem.lg,
            vertical: CrmDesignSystem.md,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? CrmColors.primary.withValues(alpha: 0.1)
                : Colors.transparent,
            border: Border.all(
              color: isSelected ? CrmColors.primary : CrmColors.borderColor,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(CrmDesignSystem.radiusMedium),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? CrmColors.primary : CrmColors.textLight,
              ),
              SizedBox(width: CrmDesignSystem.xs),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? CrmColors.primary : CrmColors.textDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(CrmDesignSystem.lg),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filter by Metric',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: CrmColors.textDark,
            ),
          ),
          SizedBox(height: CrmDesignSystem.md),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildMetricButton(
                  label: 'Sales Count',
                  value: 'sales_count',
                  icon: Icons.shopping_cart_rounded,
                ),
                SizedBox(width: CrmDesignSystem.sm),
                _buildMetricButton(
                  label: 'Revenue',
                  value: 'sales_amount',
                  icon: Icons.currency_rupee_rounded,
                ),
                SizedBox(width: CrmDesignSystem.sm),
                _buildMetricButton(
                  label: 'Activities',
                  value: 'activities_count',
                  icon: Icons.checklist_rounded,
                ),
                SizedBox(width: CrmDesignSystem.sm),
                _buildMetricButton(
                  label: 'Calls',
                  value: 'calls_count',
                  icon: Icons.phone_rounded,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

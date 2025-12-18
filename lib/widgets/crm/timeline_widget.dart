import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/crm_colors.dart';
import '../../config/crm_design_system.dart';
import '../../utils/date_utils.dart';
import 'timeline_item.dart';

class TimelineWidget extends StatelessWidget {
  final Map<String, dynamic> stats;
  final List<Map<String, dynamic>> activities;

  const TimelineWidget({
    super.key,
    required this.stats,
    required this.activities,
  });

  String _formatDate(dynamic date) {
    return DateTimeUtils.formatShortDate(date);
  }

  String _formatCurrency(dynamic amount) {
    if (amount == null) return '₹0';
    try {
      final number = amount is num ? amount : num.parse(amount.toString());
      return '₹${NumberFormat('#,##,###').format(number)}';
    } catch (e) {
      return '₹0';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Stats Bar
        Container(
          padding: const EdgeInsets.all(CrmDesignSystem.md),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                CrmColors.primary,
                CrmColors.secondary,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              // Row 1: Total Interactions & Last Contact
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      icon: Icons.chat_bubble_outline,
                      label: 'Total Interactions',
                      value: (stats['totalInteractions'] ?? 0).toString(),
                      valueColor: Colors.white,
                      labelColor: Colors.white.withValues(alpha: 0.9),
                      iconColor: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatItem(
                      icon: Icons.schedule,
                      label: 'Last Contact',
                      value: _formatDate(stats['lastContactDate']),
                      valueColor: Colors.white,
                      labelColor: Colors.white.withValues(alpha: 0.9),
                      iconColor: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Row 2: Sales & Pending
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      icon: Icons.trending_up,
                      label: 'Sales',
                      value:
                          '${stats['salesCount'] ?? 0} (${_formatCurrency(stats['totalSalesAmount'])})',
                      valueColor: Colors.white,
                      labelColor: Colors.white.withValues(alpha: 0.9),
                      iconColor: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatItem(
                      icon: Icons.pending_actions,
                      label: 'Pending',
                      value: (stats['pendingAppointments'] ?? 0).toString(),
                      valueColor: Colors.white,
                      labelColor: Colors.white.withValues(alpha: 0.9),
                      iconColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: CrmDesignSystem.lg),

        // Timeline Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: CrmDesignSystem.md),
          child: Row(
            children: [
              Text(
                'Timeline',
                style: CrmDesignSystem.titleLarge.copyWith(
                  color: CrmColors.brand,
                ),
              ),
              const Spacer(),
              Text(
                '${activities.length} items',
                style: CrmDesignSystem.bodySmall.copyWith(
                  color: CrmColors.textLight,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: CrmDesignSystem.md),

        // Timeline Items
        if (activities.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(
                    Icons.timeline,
                    size: 48,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No timeline items yet',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: CrmDesignSystem.md),
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: activities.length,
              itemBuilder: (context, index) {
                final activity = activities[index];
                return TimelineItem(
                  type: activity['type'],
                  data: activity,
                  isFirst: index == 0,
                  isLast: index == activities.length - 1,
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color valueColor,
    required Color labelColor,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: iconColor),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: valueColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: labelColor,
            ),
          ),
        ],
      ),
    );
  }
}

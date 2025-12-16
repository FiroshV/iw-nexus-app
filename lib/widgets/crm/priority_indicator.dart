import 'package:flutter/material.dart';
import '../../config/crm_design_system.dart';

class PriorityIndicator extends StatelessWidget {
  final String priority;
  final bool compact;

  const PriorityIndicator({
    super.key,
    required this.priority,
    this.compact = false,
  });

  Color _getPriorityColor() {
    switch (priority) {
      case 'hot':
        return Colors.red;
      case 'warm':
        return Colors.orange;
      case 'cold':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _getPriorityLabel() {
    return priority.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final color = _getPriorityColor();
    final label = _getPriorityLabel();

    if (compact) {
      return Tooltip(
        message: '$label Priority',
        child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.local_fire_department,
            color: Colors.white,
            size: 14,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: CrmDesignSystem.md,
        vertical: CrmDesignSystem.sm,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color, width: 1),
        borderRadius: BorderRadius.circular(CrmDesignSystem.radiusMedium),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.local_fire_department, color: color, size: 16),
          const SizedBox(width: CrmDesignSystem.sm),
          Text(
            label,
            style: CrmDesignSystem.bodySmall.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../config/crm_colors.dart';
import '../../config/crm_design_system.dart';

class LeadStatusBadge extends StatelessWidget {
  final String status;
  final bool compact;

  const LeadStatusBadge({
    super.key,
    required this.status,
    this.compact = false,
  });

  Color _getStatusColor() {
    switch (status) {
      case 'new_lead':
        return CrmColors.secondary; // #00b8d9
      case 'contacted':
        return CrmColors.primary; // #0071bf
      case 'qualified':
        return Colors.purple;
      case 'proposal_sent':
        return Colors.orange;
      case 'negotiation':
        return Colors.amber;
      case 'converted':
        return CrmColors.success; // #5cfbd8
      case 'lost':
        return Colors.red;
      case 'inactive':
        return Colors.grey;
      default:
        return CrmColors.primary;
    }
  }

  String _getStatusLabel() {
    return status.replaceAll('_', ' ').toUpperCase();
  }

  IconData _getStatusIcon() {
    switch (status) {
      case 'new_lead':
        return Icons.fiber_new;
      case 'contacted':
        return Icons.phone;
      case 'qualified':
        return Icons.check_circle;
      case 'proposal_sent':
        return Icons.description;
      case 'negotiation':
        return Icons.handshake;
      case 'converted':
        return Icons.done_all;
      case 'lost':
        return Icons.cancel;
      case 'inactive':
        return Icons.pause_circle;
      default:
        return Icons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getStatusColor();
    final label = _getStatusLabel();
    final icon = _getStatusIcon();

    if (compact) {
      return Chip(
        label: Text(
          label,
          style: CrmDesignSystem.bodySmall.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: color,
        avatar: Icon(icon, color: Colors.white, size: 16),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
          Icon(icon, color: color, size: 18),
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

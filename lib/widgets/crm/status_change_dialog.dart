import 'package:flutter/material.dart';
import '../../config/crm_colors.dart';
import '../../config/crm_design_system.dart';
import '../../models/customer.dart';

class StatusChangeDialog extends StatefulWidget {
  final Customer customer;
  final Function(String status, String? reason, String? notes) onStatusChange;

  const StatusChangeDialog({
    super.key,
    required this.customer,
    required this.onStatusChange,
  });

  @override
  State<StatusChangeDialog> createState() => _StatusChangeDialogState();
}

class _StatusChangeDialogState extends State<StatusChangeDialog> {
  late String selectedStatus;
  String? selectedReason;
  final reasonController = TextEditingController();
  final notesController = TextEditingController();
  bool isLoading = false;

  static const List<String> validStatuses = [
    'new_lead',
    'contacted',
    'qualified',
    'proposal_sent',
    'negotiation',
    'converted',
    'lost',
    'inactive',
  ];

  static const List<String> lostReasons = [
    'no_response',
    'price_too_high',
    'competitor',
    'not_interested',
    'timing_not_right',
    'other',
  ];

  Color _getStatusColor(String status) {
    switch (status) {
      case 'new_lead':
        return CrmColors.secondary;
      case 'contacted':
        return CrmColors.primary;
      case 'qualified':
        return Colors.purple;
      case 'proposal_sent':
        return Colors.orange;
      case 'negotiation':
        return Colors.amber;
      case 'converted':
        return CrmColors.success;
      case 'lost':
        return Colors.red;
      case 'inactive':
        return Colors.grey;
      default:
        return CrmColors.primary;
    }
  }

  String _formatStatusLabel(String status) {
    return status.replaceAll('_', ' ').split(' ').map((word) {
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
  }

  @override
  void initState() {
    super.initState();
    selectedStatus = widget.customer.leadStatus;
  }

  @override
  void dispose() {
    reasonController.dispose();
    notesController.dispose();
    super.dispose();
  }

  void _submit() {
    if (selectedStatus == 'lost' && selectedReason == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a reason for marking as lost')),
      );
      return;
    }

    widget.onStatusChange(
      selectedStatus,
      selectedStatus == 'lost' ? selectedReason : null,
      notesController.text.isNotEmpty ? notesController.text : null,
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(CrmDesignSystem.radiusLarge),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(CrmDesignSystem.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Update Lead Status',
                    style: CrmDesignSystem.titleLarge.copyWith(
                      color: CrmColors.textDark,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: CrmDesignSystem.md),

              // Current Status
              Container(
                padding: const EdgeInsets.all(CrmDesignSystem.md),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(CrmDesignSystem.radiusMedium),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Status',
                      style: CrmDesignSystem.bodySmall.copyWith(
                        color: CrmColors.textLight,
                      ),
                    ),
                    const SizedBox(height: CrmDesignSystem.xs),
                    Text(
                      _formatStatusLabel(widget.customer.leadStatus),
                      style: CrmDesignSystem.titleMedium.copyWith(
                        color: _getStatusColor(widget.customer.leadStatus),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: CrmDesignSystem.lg),

              // Status Dropdown
              Text(
                'New Status',
                style: CrmDesignSystem.bodyMedium.copyWith(
                  color: CrmColors.textDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: CrmDesignSystem.sm),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(CrmDesignSystem.radiusMedium),
                ),
                child: DropdownButton<String>(
                  value: selectedStatus,
                  isExpanded: true,
                  underline: const SizedBox(),
                  padding: const EdgeInsets.symmetric(horizontal: CrmDesignSystem.md),
                  items: validStatuses.map((status) {
                    return DropdownMenuItem(
                      value: status,
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: _getStatusColor(status),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: CrmDesignSystem.sm),
                          Text(_formatStatusLabel(status)),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        selectedStatus = value;
                        selectedReason = null;
                      });
                    }
                  },
                ),
              ),
              const SizedBox(height: CrmDesignSystem.lg),

              // Lost Reason (only if lost status selected)
              if (selectedStatus == 'lost') ...[
                Text(
                  'Reason for Lost',
                  style: CrmDesignSystem.bodyMedium.copyWith(
                    color: CrmColors.textDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: CrmDesignSystem.sm),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(CrmDesignSystem.radiusMedium),
                  ),
                  child: DropdownButton<String>(
                    value: selectedReason,
                    isExpanded: true,
                    underline: const SizedBox(),
                    padding: const EdgeInsets.symmetric(horizontal: CrmDesignSystem.md),
                    hint: const Text('Select reason...'),
                    items: lostReasons.map((reason) {
                      return DropdownMenuItem(
                        value: reason,
                        child: Text(_formatStatusLabel(reason)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedReason = value;
                      });
                    },
                  ),
                ),
                const SizedBox(height: CrmDesignSystem.lg),

                // Reason Notes (if lost reason selected)
                if (selectedReason != null) ...[
                  Text(
                    'Additional Notes (Optional)',
                    style: CrmDesignSystem.bodyMedium.copyWith(
                      color: CrmColors.textDark,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: CrmDesignSystem.sm),
                  TextField(
                    controller: reasonController,
                    decoration: InputDecoration(
                      hintText: 'Why did this lead get lost?',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(CrmDesignSystem.radiusMedium),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: CrmDesignSystem.md,
                        vertical: CrmDesignSystem.md,
                      ),
                    ),
                    maxLines: 3,
                    minLines: 2,
                  ),
                  const SizedBox(height: CrmDesignSystem.lg),
                ],
              ],

              // General Notes
              Text(
                'Status Change Notes (Optional)',
                style: CrmDesignSystem.bodyMedium.copyWith(
                  color: CrmColors.textDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: CrmDesignSystem.sm),
              TextField(
                controller: notesController,
                decoration: InputDecoration(
                  hintText: 'Add any notes about this status change...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(CrmDesignSystem.radiusMedium),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: CrmDesignSystem.md,
                    vertical: CrmDesignSystem.md,
                  ),
                ),
                maxLines: 2,
                minLines: 1,
              ),
              const SizedBox(height: CrmDesignSystem.lg),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Cancel',
                      style: CrmDesignSystem.bodyMedium.copyWith(
                        color: CrmColors.textLight,
                      ),
                    ),
                  ),
                  const SizedBox(width: CrmDesignSystem.md),
                  ElevatedButton(
                    onPressed: isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CrmColors.primary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: CrmDesignSystem.lg,
                        vertical: CrmDesignSystem.md,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(CrmDesignSystem.radiusMedium),
                      ),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : Text(
                            'Update Status',
                            style: CrmDesignSystem.bodyMedium.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../config/crm_colors.dart';
import '../../config/crm_design_system.dart';
import '../../models/activity.dart';
import '../../services/activity_service.dart';

class ActivityDetailsScreen extends StatefulWidget {
  final String activityId;
  final String userRole;
  final String userId;

  const ActivityDetailsScreen({
    super.key,
    required this.activityId,
    required this.userRole,
    required this.userId,
  });

  @override
  State<ActivityDetailsScreen> createState() => _ActivityDetailsScreenState();
}

class _ActivityDetailsScreenState extends State<ActivityDetailsScreen> {
  Activity? _activity;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadActivity();
  }

  Future<void> _loadActivity() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await ActivityService.getActivity(widget.activityId);
      if (response.success && response.data != null) {
        setState(() => _activity = response.data);
      } else {
        setState(() => _error = response.message ?? 'Failed to load activity');
      }
    } catch (e) {
      setState(() => _error = 'Error: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String? _getPrimaryEmployeeName() {
    // Use the populated createdByName from the backend
    if (_activity?.createdByName != null && _activity!.createdByName!.isNotEmpty) {
      return _activity!.createdByName;
    }

    // Fallback: Try to find in assignedEmployees if backend didn't populate
    if (_activity?.createdBy != null) {
      try {
        final employee = _activity!.assignedEmployees.firstWhere(
          (emp) => emp.userId == _activity!.createdBy,
        );
        return employee.userName;
      } catch (e) {
        // Not found in assigned employees
      }
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity Details'),
        backgroundColor: CrmColors.primary,
        elevation: 2,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(CrmColors.primary),
              ),
            )
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(_error!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadActivity,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: CrmColors.primary,
                        ),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _activity == null
                  ? const Center(child: Text('Activity not found'))
                  : SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(CrmDesignSystem.lg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Primary Employee Card
                            if (_getPrimaryEmployeeName() != null)
                              Container(
                                padding: const EdgeInsets.all(CrmDesignSystem.lg),
                                decoration: BoxDecoration(
                                  color: CrmColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(
                                    CrmDesignSystem.radiusLarge,
                                  ),
                                  border: Border.all(
                                    color: CrmColors.primary.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.person,
                                          size: 20,
                                          color: CrmColors.primary,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Primary Employee',
                                          style: CrmDesignSystem.labelMedium.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: CrmColors.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: CrmDesignSystem.sm),
                                    Text(
                                      _getPrimaryEmployeeName() ?? 'Unknown',
                                      style: CrmDesignSystem.bodyMedium.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            const SizedBox(height: CrmDesignSystem.lg),

                            // Customer Card
                            Container(
                              padding: const EdgeInsets.all(CrmDesignSystem.lg),
                              decoration: CrmDesignSystem.cardDecoration,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Customer',
                                    style: CrmDesignSystem.labelSmall.copyWith(
                                      color: CrmColors.textLight,
                                    ),
                                  ),
                                  const SizedBox(height: CrmDesignSystem.sm),
                                  Text(
                                    _activity!.customerName ?? 'Unknown',
                                    style: CrmDesignSystem.titleLarge,
                                  ),
                                  if (_activity!.customerMobile != null) ...[
                                    const SizedBox(height: CrmDesignSystem.sm),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.phone,
                                          size: 16,
                                          color: CrmColors.primary,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          _activity!.customerMobile!,
                                          style: CrmDesignSystem.bodyMedium,
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: CrmDesignSystem.lg),

                            // Activity Type
                            Container(
                              padding: const EdgeInsets.all(CrmDesignSystem.lg),
                              decoration: CrmDesignSystem.cardDecoration,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Type',
                                    style: CrmDesignSystem.labelSmall.copyWith(
                                      color: CrmColors.textLight,
                                    ),
                                  ),
                                  const SizedBox(height: CrmDesignSystem.sm),
                                  Text(
                                    _activity!.typeDisplayName,
                                    style: CrmDesignSystem.bodyMedium.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: CrmDesignSystem.lg),

                            // Outcome
                            Container(
                              padding: const EdgeInsets.all(CrmDesignSystem.lg),
                              decoration: CrmDesignSystem.cardDecoration,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Outcome',
                                    style: CrmDesignSystem.labelSmall.copyWith(
                                      color: CrmColors.textLight,
                                    ),
                                  ),
                                  const SizedBox(height: CrmDesignSystem.sm),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: CrmDesignSystem.md,
                                      vertical: CrmDesignSystem.sm,
                                    ),
                                    decoration: BoxDecoration(
                                      color: CrmColors.success.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(
                                        CrmDesignSystem.radiusSmall,
                                      ),
                                    ),
                                    child: Text(
                                      _activity!.outcomeDisplayName,
                                      style: CrmDesignSystem.bodyMedium.copyWith(
                                        color: CrmColors.success,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: CrmDesignSystem.lg),

                            // Date and Time
                            Container(
                              padding: const EdgeInsets.all(CrmDesignSystem.lg),
                              decoration: CrmDesignSystem.cardDecoration,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Activity Date & Time',
                                    style: CrmDesignSystem.labelSmall.copyWith(
                                      color: CrmColors.textLight,
                                    ),
                                  ),
                                  const SizedBox(height: CrmDesignSystem.sm),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.calendar_today,
                                        size: 16,
                                        color: CrmColors.primary,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        _activity!.formattedActivityDatetime,
                                        style: CrmDesignSystem.bodyMedium,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: CrmDesignSystem.lg),

                            // Duration (if applicable)
                            if (_activity!.durationMinutes != null) ...[
                              Container(
                                padding: const EdgeInsets.all(CrmDesignSystem.lg),
                                decoration: CrmDesignSystem.cardDecoration,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Duration',
                                      style: CrmDesignSystem.labelSmall.copyWith(
                                        color: CrmColors.textLight,
                                      ),
                                    ),
                                    const SizedBox(height: CrmDesignSystem.sm),
                                    Text(
                                      '${_activity!.durationMinutes} minutes',
                                      style: CrmDesignSystem.bodyMedium.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: CrmDesignSystem.lg),
                            ],

                            // Notes
                            if (_activity!.notes != null && _activity!.notes!.isNotEmpty) ...[
                              Container(
                                padding: const EdgeInsets.all(CrmDesignSystem.lg),
                                decoration: CrmDesignSystem.cardDecoration,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Notes',
                                      style: CrmDesignSystem.labelSmall.copyWith(
                                        color: CrmColors.textLight,
                                      ),
                                    ),
                                    const SizedBox(height: CrmDesignSystem.sm),
                                    Text(
                                      _activity!.notes!,
                                      style: CrmDesignSystem.bodyMedium,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: CrmDesignSystem.lg),
                            ],

                            // Follow-up Appointment
                            if (_activity!.hasFollowup) ...[
                              Container(
                                padding: const EdgeInsets.all(CrmDesignSystem.lg),
                                decoration: BoxDecoration(
                                  color: CrmColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(
                                    CrmDesignSystem.radiusLarge,
                                  ),
                                  border: Border.all(
                                    color: CrmColors.primary.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.event,
                                          size: 20,
                                          color: CrmColors.primary,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Follow-up Appointment',
                                          style: CrmDesignSystem.labelMedium.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: CrmColors.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: CrmDesignSystem.sm),
                                    Text(
                                      'ID: ${_activity!.followupAppointmentId}',
                                      style: CrmDesignSystem.bodySmall.copyWith(
                                        color: CrmColors.textLight,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: CrmDesignSystem.lg),
                            ],

                            // Assigned Employees
                            if (_activity!.assignedEmployees.isNotEmpty) ...[
                              Container(
                                padding: const EdgeInsets.all(CrmDesignSystem.lg),
                                decoration: CrmDesignSystem.cardDecoration,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Assigned Employees',
                                      style: CrmDesignSystem.labelSmall.copyWith(
                                        color: CrmColors.textLight,
                                      ),
                                    ),
                                    const SizedBox(height: CrmDesignSystem.md),
                                    ListView.separated(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      itemCount: _activity!.assignedEmployees.length,
                                      separatorBuilder: (_, __) => const Divider(),
                                      itemBuilder: (context, index) {
                                        final employee = _activity!.assignedEmployees[index];
                                        final isPrimary = employee.userId == _activity!.createdBy;
                                        return Container(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: CrmDesignSystem.sm,
                                          ),
                                          decoration: isPrimary
                                              ? BoxDecoration(
                                                  color: CrmColors.primary.withValues(alpha: 0.05),
                                                  borderRadius: BorderRadius.circular(
                                                    CrmDesignSystem.radiusSmall,
                                                  ),
                                                )
                                              : null,
                                          child: Padding(
                                            padding: isPrimary
                                                ? const EdgeInsets.all(CrmDesignSystem.sm)
                                                : EdgeInsets.zero,
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.person,
                                                  size: 16,
                                                  color: isPrimary
                                                      ? CrmColors.primary
                                                      : CrmColors.primary,
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment.start,
                                                    children: [
                                                      Row(
                                                        children: [
                                                          Text(
                                                            employee.userName ?? 'Unknown',
                                                            style: CrmDesignSystem
                                                                .bodyMedium
                                                                .copyWith(
                                                              fontWeight: isPrimary
                                                                  ? FontWeight.w600
                                                                  : FontWeight.w400,
                                                            ),
                                                          ),
                                                          if (isPrimary) ...[
                                                            const SizedBox(width: 8),
                                                            Container(
                                                              padding: const EdgeInsets
                                                                  .symmetric(
                                                                horizontal: 6,
                                                                vertical: 2,
                                                              ),
                                                              decoration: BoxDecoration(
                                                                color: CrmColors.primary,
                                                                borderRadius:
                                                                    BorderRadius.circular(4),
                                                              ),
                                                              child: Text(
                                                                'Primary',
                                                                style: CrmDesignSystem
                                                                    .bodySmall
                                                                    .copyWith(
                                                                  color: Colors.white,
                                                                  fontSize: 10,
                                                                  fontWeight: FontWeight.w600,
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ],
                                                      ),
                                                      const SizedBox(height: 2),
                                                      Text(
                                                        'Role: ${employee.role}',
                                                        style: CrmDesignSystem.bodySmall
                                                            .copyWith(
                                                          color: CrmColors.textLight,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: CrmDesignSystem.lg),
                            ],

                            const SizedBox(height: CrmDesignSystem.huge),
                          ],
                        ),
                      ),
                    ),
    );
  }

}

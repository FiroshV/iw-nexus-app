import 'package:flutter/material.dart';
import '../../config/crm_colors.dart';
import '../../config/crm_design_system.dart';
import '../../models/customer.dart';
import '../../services/pipeline_service.dart';
import '../../widgets/crm/lead_status_badge.dart';
import '../../widgets/crm/priority_indicator.dart';

class OverdueFollowupsScreen extends StatefulWidget {
  final String userId;
  final String userRole;
  final String view;

  const OverdueFollowupsScreen({
    super.key,
    required this.userId,
    required this.userRole,
    required this.view,
  });

  @override
  State<OverdueFollowupsScreen> createState() => _OverdueFollowupsScreenState();
}

class _OverdueFollowupsScreenState extends State<OverdueFollowupsScreen> {
  late Future<List<Customer>> _customersFuture;

  @override
  void initState() {
    super.initState();
    _customersFuture = _fetchOverdueFollowups();
  }

  Future<List<Customer>> _fetchOverdueFollowups() async {
    final response = await PipelineService.getOverdueFollowups(view: widget.view);

    if (response.success && response.data != null) {
      return response.data!;
    } else {
      throw Exception(response.message ?? 'Failed to load overdue followups');
    }
  }

  int _getDaysOverdue(DateTime nextFollowupDate) {
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final followupOnly = DateTime(nextFollowupDate.year, nextFollowupDate.month, nextFollowupDate.day);
    return todayOnly.difference(followupOnly).inDays;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Overdue Follow-ups',
          style: CrmDesignSystem.headlineSmall.copyWith(color: Colors.white),
        ),
        backgroundColor: Colors.red,
        elevation: 2,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _customersFuture = _fetchOverdueFollowups();
          });
        },
        color: CrmColors.primary,
        child: FutureBuilder<List<Customer>>(
          future: _customersFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: Colors.red.withValues(alpha: 0.5)),
                    const SizedBox(height: CrmDesignSystem.md),
                    Text('Error: ${snapshot.error}'),
                  ],
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, size: 48, color: CrmColors.success),
                    const SizedBox(height: CrmDesignSystem.md),
                    Text(
                      'No overdue follow-ups!',
                      style: CrmDesignSystem.titleMedium.copyWith(color: CrmColors.success),
                    ),
                    const SizedBox(height: CrmDesignSystem.sm),
                    Text(
                      'All your follow-ups are on schedule',
                      style: CrmDesignSystem.bodySmall.copyWith(color: CrmColors.textLight),
                    ),
                  ],
                ),
              );
            }

            final customers = snapshot.data!;

            return ListView.builder(
              padding: const EdgeInsets.all(CrmDesignSystem.md),
              itemCount: customers.length,
              itemBuilder: (context, index) {
                final customer = customers[index];
                final daysOverdue = _getDaysOverdue(customer.nextFollowupDate!);

                return _buildOverdueCard(customer, daysOverdue);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildOverdueCard(Customer customer, int daysOverdue) {
    final urgencyColor = daysOverdue > 7 ? Colors.red : daysOverdue > 3 ? Colors.orange : Colors.amber;

    return GestureDetector(
      onTap: () {
        Navigator.of(context).pushNamed(
          '/crm/customer-detail',
          arguments: {'customerId': customer.id, 'userId': widget.userId, 'userRole': widget.userRole},
        );
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: CrmDesignSystem.md),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(CrmDesignSystem.radiusMedium),
          side: BorderSide(color: urgencyColor.withValues(alpha: 0.3), width: 2),
        ),
        child: Padding(
          padding: const EdgeInsets.all(CrmDesignSystem.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with urgency badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customer.name,
                          style: CrmDesignSystem.titleMedium.copyWith(
                            color: CrmColors.textDark,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: CrmDesignSystem.xs),
                        Text(
                          customer.mobileNumber,
                          style: CrmDesignSystem.bodySmall.copyWith(
                            color: CrmColors.textLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Days Overdue Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: CrmDesignSystem.md,
                      vertical: CrmDesignSystem.sm,
                    ),
                    decoration: BoxDecoration(
                      color: urgencyColor.withValues(alpha: 0.2),
                      border: Border.all(color: urgencyColor, width: 2),
                      borderRadius: BorderRadius.circular(CrmDesignSystem.radiusMedium),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          '$daysOverdue',
                          style: CrmDesignSystem.headlineSmall.copyWith(
                            color: urgencyColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'days overdue',
                          style: CrmDesignSystem.bodySmall.copyWith(
                            color: urgencyColor,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: CrmDesignSystem.md),

              // Status and Priority
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  LeadStatusBadge(status: customer.leadStatus, compact: true),
                  PriorityIndicator(priority: customer.leadPriority, compact: true),
                ],
              ),

              if (customer.lastContactDate != null) ...[
                const SizedBox(height: CrmDesignSystem.sm),
                Text(
                  'Last Contact: ${_formatDate(customer.lastContactDate!)}',
                  style: CrmDesignSystem.bodySmall.copyWith(
                    color: CrmColors.textLight,
                  ),
                ),
              ],

              const SizedBox(height: CrmDesignSystem.sm),
              Text(
                'Due: ${_formatDate(customer.nextFollowupDate!)}',
                style: CrmDesignSystem.bodySmall.copyWith(
                  color: urgencyColor,
                  fontWeight: FontWeight.w600,
                ),
              ),

              if (customer.notes != null && customer.notes!.isNotEmpty) ...[
                const SizedBox(height: CrmDesignSystem.sm),
                Container(
                  padding: const EdgeInsets.all(CrmDesignSystem.sm),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(CrmDesignSystem.radiusSmall),
                  ),
                  child: Text(
                    customer.notes!,
                    style: CrmDesignSystem.bodySmall.copyWith(
                      color: CrmColors.textDark,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],

              const SizedBox(height: CrmDesignSystem.md),

              // Quick Action Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pushNamed(
                          '/crm/log-activity',
                          arguments: {
                            'customerId': customer.id,
                            'userId': widget.userId,
                            'userRole': widget.userRole,
                          },
                        );
                      },
                      icon: const Icon(Icons.phone),
                      label: const Text('Call'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: CrmColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: CrmDesignSystem.sm),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pushNamed(
                          '/crm/simplified-appointment',
                          arguments: {
                            'customerId': customer.id,
                            'userId': widget.userId,
                            'userRole': widget.userRole,
                          },
                        );
                      },
                      icon: const Icon(Icons.event_note),
                      label: const Text('Schedule'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: CrmColors.secondary,
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

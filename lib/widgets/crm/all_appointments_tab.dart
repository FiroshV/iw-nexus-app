import 'package:flutter/material.dart';
import '../../config/crm_colors.dart';
import '../../config/crm_design_system.dart';
import '../../models/appointment.dart';
import '../../services/appointment_service.dart';

/// All Appointments Tab - List view of all appointments
/// Shows appointment cards with status information
class AllAppointmentsTab extends StatefulWidget {
  final String userId;
  final String userRole;

  const AllAppointmentsTab({
    super.key,
    required this.userId,
    required this.userRole,
  });

  @override
  State<AllAppointmentsTab> createState() => _AllAppointmentsTabState();
}

class _AllAppointmentsTabState extends State<AllAppointmentsTab>
    with AutomaticKeepAliveClientMixin {
  // Data
  List<Appointment> _appointments = [];
  bool _isLoading = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    // Clear old data immediately to prevent showing stale data
    setState(() {
      _isLoading = true;
      _appointments = [];
    });

    try {
      // Determine view based on user role
      String view;
      if (widget.userRole == 'admin' || widget.userRole == 'director') {
        view = 'all';
      } else if (widget.userRole == 'manager') {
        view = 'branch';
      } else {
        // This shouldn't happen since tab is hidden for other roles
        view = 'assigned';
      }

      final response = await AppointmentService.getAppointments(
        limit: 100,
        view: view,
      );

      if (!mounted) return;

      if (response.success && response.data != null) {
        setState(() {
          _appointments = response.data!;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.message ?? 'Failed to load appointments')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load appointments: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    return Column(
      children: [
        // Appointments list
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _appointments.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: _loadAppointments,
                      child: ListView.builder(
                        itemCount: _appointments.length + 1,
                        padding: const EdgeInsets.all(CrmDesignSystem.md),
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: CrmDesignSystem.md),
                              child: Text(
                                _getViewLabel(),
                                style: CrmDesignSystem.bodySmall.copyWith(
                                  color: CrmColors.textLight,
                                ),
                              ),
                            );
                          }
                          final apt = _appointments[index - 1];
                          return _buildAppointmentCard(apt);
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_today_outlined,
            size: 64,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: CrmDesignSystem.lg),
          Text(
            'No appointments',
            style: CrmDesignSystem.titleMedium.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: CrmDesignSystem.sm),
          Text(
            'Appointments will appear here',
            style: CrmDesignSystem.bodySmall.copyWith(
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentCard(Appointment apt) {
    final isOverdue = apt.isOverdue;
    final isDueToday = apt.isDueToday;
    final isUpcoming = apt.isUpcoming;
    final isMissed = apt.status == 'scheduled' && isOverdue;
    final isCompleted = apt.status == 'completed';
    final isCancelled = apt.status == 'cancelled';

    // Determine tag info
    String? tagLabel;
    Color? tagBgColor;
    Color? tagTextColor;

    if (isCompleted) {
      tagLabel = 'Completed';
      tagBgColor = CrmColors.success.withValues(alpha: 0.1);
      tagTextColor = CrmColors.success;
    } else if (isCancelled) {
      tagLabel = 'Cancelled';
      tagBgColor = Colors.red.shade100;
      tagTextColor = Colors.red.shade700;
    } else if (isMissed) {
      tagLabel = 'Overdue';
      tagBgColor = Colors.red.shade100;
      tagTextColor = Colors.red.shade700;
    } else if (isDueToday) {
      tagLabel = 'Today';
      tagBgColor = Colors.orange.shade100;
      tagTextColor = Colors.orange.shade700;
    } else if (isUpcoming) {
      tagLabel = 'Upcoming';
      tagBgColor = Colors.blue.shade100;
      tagTextColor = Colors.blue.shade700;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: CrmDesignSystem.md),
      elevation: 1,
      child: ListTile(
        leading: _buildTypeIcon(apt.activityType),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              apt.customerName ?? 'Unknown Customer',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              apt.activityTypeDisplayName,
              style: CrmDesignSystem.bodySmall.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: CrmDesignSystem.sm),
          child: Row(
            children: [
              Icon(Icons.access_time, size: 14, color: Colors.grey.shade500),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  apt.formattedScheduledDatetime,
                  style: CrmDesignSystem.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (tagLabel != null) ...[
                const SizedBox(width: CrmDesignSystem.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: tagBgColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    tagLabel,
                    style: TextStyle(
                      fontSize: 11,
                      color: tagTextColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        trailing: apt.status == 'completed'
            ? Icon(Icons.check_circle, color: CrmColors.success, size: 20)
            : apt.status == 'cancelled'
                ? Icon(Icons.cancel, color: Colors.red.shade400, size: 20)
                : null,
        onTap: () {
          // CRITICAL FIX: Navigate to appointment details on tap
          Navigator.of(context)
              .pushNamed(
                '/crm/appointment-details',
                arguments: {
                  'appointmentId': apt.id ?? apt.appointmentId,
                  'userId': widget.userId,
                  'userRole': widget.userRole,
                },
              )
              .then((result) {
            // Refresh if appointment was modified
            if (result == true) {
              _loadAppointments();
            }
          });
        },
      ),
    );
  }

  Widget _buildTypeIcon(String type) {
    const iconMap = {
      'in_person_visit': Icons.location_on_outlined,
      'phone_call': Icons.phone_outlined,
      'email': Icons.email_outlined,
      'whatsapp_message': Icons.chat_outlined,
      'document_collection': Icons.description_outlined,
      'policy_renewal': Icons.refresh,
      'other': Icons.more_horiz,
    };

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: CrmColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(CrmDesignSystem.radiusLarge),
      ),
      child: Icon(
        iconMap[type] ?? Icons.event,
        color: CrmColors.primary,
        size: 20,
      ),
    );
  }

  String _getViewLabel() {
    if (widget.userRole == 'admin' || widget.userRole == 'director') {
      return 'All Appointments (Company-wide)';
    } else if (widget.userRole == 'manager') {
      return 'Branch Appointments';
    }
    return 'My Appointments';
  }
}

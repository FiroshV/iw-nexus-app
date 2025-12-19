import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/crm_colors.dart';
import '../../config/crm_design_system.dart';
import '../../models/appointment.dart';
import '../../providers/crm/appointment_provider.dart';

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
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // Load appointments using provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final view = _getViewLabel().contains('Company-wide') ? 'all' :
                   _getViewLabel().contains('Branch') ? 'branch' : 'assigned';
      context.read<AppointmentProvider>().fetchAppointments(view: view);
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    return Consumer<AppointmentProvider>(
      builder: (context, provider, child) {
        final view = widget.userRole == 'admin' || widget.userRole == 'director'
            ? 'all'
            : widget.userRole == 'manager'
                ? 'branch'
                : 'assigned';

        final cache = provider.getCache(view);
        final appointments = provider.getAppointments(view);

        return Column(
          children: [
            // Appointments list
            Expanded(
              child: Stack(
                children: [
                  // Show loading ONLY if no cached data
                  if (cache.isLoading && !cache.hasData)
                    const Center(child: CircularProgressIndicator())

                  // Show error ONLY if no cached data
                  else if (cache.error != null && !cache.hasData)
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline,
                              size: 48, color: Colors.red.shade400),
                          const SizedBox(height: 16),
                          Text(cache.error!),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => provider.fetchAppointments(
                                view: view, forceRefresh: true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: CrmColors.primary,
                            ),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )

                  // Show data (cached or fresh)
                  else if (appointments.isEmpty)
                    _buildEmptyState()
                  else
                    RefreshIndicator(
                      onRefresh: () =>
                          provider.fetchAppointments(view: view, forceRefresh: true),
                      child: ListView.builder(
                        itemCount: appointments.length + 1,
                        padding: const EdgeInsets.all(CrmDesignSystem.md),
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return Padding(
                              padding:
                                  const EdgeInsets.only(bottom: CrmDesignSystem.md),
                              child: Text(
                                _getViewLabel(),
                                style: CrmDesignSystem.bodySmall.copyWith(
                                  color: CrmColors.textLight,
                                ),
                              ),
                            );
                          }
                          final apt = appointments[index - 1];
                          return _buildAppointmentCard(apt);
                        },
                      ),
                    ),

                  // Show refresh indicator at top when refreshing
                  if (cache.isRefreshing)
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: LinearProgressIndicator(
                        minHeight: 2,
                        backgroundColor: Colors.transparent,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(CrmColors.primary),
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
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

  Widget _buildAppointmentCard(dynamic apt) {
    // Handle both Appointment objects and Map data
    final status = (apt is Appointment ? apt.status : apt['status']) as String?;
    final activityType = (apt is Appointment ? apt.activityType : apt['activityType']) as String?;
    final customerName = (apt is Appointment ? apt.customerName : apt['customerName']) as String?;
    final appointmentId = (apt is Appointment ? (apt.id ?? apt.appointmentId) : (apt['id'] ?? apt['appointmentId'])) as String?;

    // Get the formatted datetime
    String formattedDateTime = '';
    if (apt is Appointment) {
      formattedDateTime = apt.formattedScheduledDatetime;
    } else {
      final scheduledDate = apt['scheduledDate'];
      if (scheduledDate != null) {
        formattedDateTime = scheduledDate.toString();
      }
    }

    // Get activity type display name
    String activityTypeDisplay = '';
    if (apt is Appointment) {
      activityTypeDisplay = apt.activityTypeDisplayName;
    } else {
      activityTypeDisplay = apt['activityTypeDisplayName'] ?? 'Appointment';
    }

    // Determine status
    final isCompleted = status == 'completed';
    final isCancelled = status == 'cancelled';

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
    }

    return Card(
      margin: const EdgeInsets.only(bottom: CrmDesignSystem.md),
      elevation: 1,
      child: ListTile(
        leading: _buildTypeIcon(activityType ?? 'other'),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              customerName ?? 'Unknown Customer',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              activityTypeDisplay,
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
                  formattedDateTime,
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
        trailing: isCompleted
            ? Icon(Icons.check_circle, color: CrmColors.success, size: 20)
            : isCancelled
                ? Icon(Icons.cancel, color: Colors.red.shade400, size: 20)
                : null,
        onTap: () {
          // Navigate to appointment details on tap
          final view = widget.userRole == 'admin' || widget.userRole == 'director'
              ? 'all'
              : widget.userRole == 'manager'
                  ? 'branch'
                  : 'assigned';

          Navigator.of(context)
              .pushNamed(
                '/crm/appointment-details',
                arguments: {
                  'appointmentId': appointmentId,
                  'userId': widget.userId,
                  'userRole': widget.userRole,
                },
              )
              .then((result) {
            // Refresh if appointment was modified
            if (result == true && mounted) {
              context.read<AppointmentProvider>().fetchAppointments(
                    view: view,
                    forceRefresh: true,
                  );
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

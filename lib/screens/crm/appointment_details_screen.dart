import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/crm_colors.dart';
import '../../models/appointment.dart';
import '../../services/appointment_service.dart';

class AppointmentDetailsScreen extends StatefulWidget {
  final String appointmentId;
  final String userRole;
  final String userId;

  const AppointmentDetailsScreen({
    super.key,
    required this.appointmentId,
    required this.userRole,
    required this.userId,
  });

  @override
  State<AppointmentDetailsScreen> createState() => _AppointmentDetailsScreenState();
}

class _AppointmentDetailsScreenState extends State<AppointmentDetailsScreen> {
  Appointment? _appointment;
  bool _isLoading = true;
  String? _error;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadAppointment();
  }

  Future<void> _loadAppointment() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await AppointmentService.getAppointment(widget.appointmentId);
      if (response.success && response.data != null) {
        setState(() => _appointment = response.data);
      } else {
        setState(() => _error = response.message ?? 'Failed to load appointment');
      }
    } catch (e) {
      setState(() => _error = 'Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _completeAppointment() async {
    if (_appointment == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Complete Appointment'),
        content: Text(
          'Mark this ${_appointment!.activityTypeDisplayName} as completed?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5cfbd8)),
            child: const Text('Complete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      _submitComplete();
    }
  }

  Future<void> _submitComplete() async {
    if (_appointment == null) return;

    setState(() => _isSubmitting = true);

    try {
      final completionData = {
        'outcome': 'completed',
        'outcomeOther': '',
        'notes': '',
        if (_appointment!.activityType == 'in_person_visit') ...{
          'timeSpentMinutes': 60,
        },
      };

      final response =
          await AppointmentService.completeAppointment(_appointment!.id!, completionData);

      if (!mounted) return;

      if (response.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _appointment!.activityType == 'in_person_visit'
                  ? 'Visit recorded successfully'
                  : 'Appointment marked as completed',
            ),
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.message ?? 'Failed to complete appointment')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _cancelAppointment() async {
    if (_appointment == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Appointment'),
        content: const Text('Are you sure you want to cancel this appointment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Cancel Appointment', style: TextStyle(color: Colors.white),),
          ),
        ],
      ),
    );

    if (confirm == true) {
      _submitCancel();
    }
  }

  Future<void> _submitCancel() async {
    if (_appointment == null) return;

    setState(() => _isSubmitting = true);

    try {
      final response = await AppointmentService.cancelAppointment(
        _appointment!.id!,
      );

      if (!mounted) return;

      if (response.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Appointment cancelled')),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.message ?? 'Failed to cancel appointment')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointment Details'),
        backgroundColor: CrmColors.primary,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0071bf)),
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
                        onPressed: _loadAppointment,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0071bf),
                        ),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _appointment == null
                  ? const Center(child: Text('Appointment not found'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Status badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _getStatusColor(_appointment!.status).withValues(alpha: 0.1),
                              border: Border.all(color: _getStatusColor(_appointment!.status)),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _appointment!.statusDisplayName,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _getStatusColor(_appointment!.status),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Customer Info
                          _buildSection(
                            title: 'Customer',
                            icon: Icons.person_outline,
                            children: [
                              Text(
                                _appointment!.customerName ?? 'Unknown',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF272579),
                                ),
                              ),
                              if (_appointment!.customerMobile != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  _appointment!.customerMobile!,
                                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                ),
                              ],
                            ],
                          ),

                          // Activity Type
                          _buildSection(
                            title: 'Activity Type',
                            icon: Icons.event_note,
                            children: [
                              Text(
                                _appointment!.activityTypeDisplayName,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF272579),
                                ),
                              ),
                            ],
                          ),

                          // Date & Time
                          _buildSection(
                            title: 'Scheduled Date & Time',
                            icon: Icons.calendar_today,
                            children: [
                              Text(
                                DateFormat('EEEE, MMM d, yyyy').format(_appointment!.scheduledDate),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF272579),
                                ),
                              ),
                              if (_appointment!.scheduledTimeSlot != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  '${_appointment!.scheduledTimeSlot!.startTime} - ${_appointment!.scheduledTimeSlot!.endTime}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF0071bf),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ],
                          ),

                          // Assigned Employees
                          if (_appointment!.assignedEmployees.isNotEmpty)
                            _buildSection(
                              title: 'Assigned Employees',
                              icon: Icons.groups_outlined,
                              children: [
                                ..._appointment!.assignedEmployees.map((emp) {
                                  final isPrimary = emp.role == 'primary';
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Row(
                                      children: [
                                        Icon(
                                          isPrimary ? Icons.star : Icons.person,
                                          size: 16,
                                          color: const Color(0xFF0071bf),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          emp.userName ?? emp.userId,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF272579),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF5cfbd8)
                                                .withValues(alpha: 0.3),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            emp.role,
                                            style: const TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF272579),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                            ),

                          // Purpose
                          if (_appointment!.purpose != null)
                            _buildSection(
                              title: 'Purpose',
                              icon: Icons.info_outline,
                              children: [
                                Text(
                                  _appointment!.purpose!,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF272579),
                                  ),
                                ),
                              ],
                            ),

                          // Notes
                          if (_appointment!.notes != null)
                            _buildSection(
                              title: 'Notes',
                              icon: Icons.note_outlined,
                              children: [
                                Text(
                                  _appointment!.notes!,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF272579),
                                  ),
                                ),
                              ],
                            ),

                          // Completion Details (if completed and is in-person visit)
                          if (_appointment!.status == 'completed' &&
                              _appointment!.activityType == 'in_person_visit') ...[
                            _buildSection(
                              title: 'Completion Status',
                              icon: Icons.check_circle_outline,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF5cfbd8).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: const Color(0xFF5cfbd8).withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.check_circle,
                                        size: 16,
                                        color: Color(0xFF5cfbd8),
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Visit Recorded',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF5cfbd8),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],

                          const SizedBox(height: 24),

                          // Action Buttons
                          if (_appointment!.status == 'scheduled') ...[
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _isSubmitting ? null : _completeAppointment,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF5cfbd8),
                                  foregroundColor: const Color(0xFF272579),
                                ),
                                child: _isSubmitting
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : const Text('Mark as Completed'),
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed: _isSubmitting ? null : _cancelAppointment,
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Colors.red),
                                  foregroundColor: Colors.red,
                                ),
                                child: const Text('Cancel Appointment'),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF00b8d9).withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: const Color(0xFF0071bf)),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0071bf),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'scheduled':
        return const Color(0xFF0071bf);
      case 'completed':
        return const Color(0xFF5cfbd8);
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

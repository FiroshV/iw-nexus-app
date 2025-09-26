import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/access_control_service.dart';
import '../utils/timezone_util.dart';
import '../screens/approval_management_screen.dart';

class ApprovalCards extends StatefulWidget {
  final String userRole;

  const ApprovalCards({
    super.key,
    required this.userRole,
  });

  @override
  State<ApprovalCards> createState() => _ApprovalCardsState();
}

class _ApprovalCardsState extends State<ApprovalCards> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _pendingApprovals = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPendingApprovals();
  }

  Future<void> _loadPendingApprovals() async {
    final canView = _canViewApprovals();

    if (!canView) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      setState(() => _isLoading = true);

      final response = await ApiService.getPendingApprovals();

      if (response.success && response.data != null) {
        setState(() {
          // Handle both response formats:
          // 1. {success: true, data: [...], count: n} - object format
          // 2. [...] - direct list format
          final dynamic responseData = response.data;

          List<dynamic> approvals;

          if (responseData is List) {
            // Direct list format
            approvals = responseData;
          } else if (responseData is Map && responseData.containsKey('data')) {
            // Object format with 'data' field
            approvals = responseData['data'] ?? [];
          } else {
            // Unknown format, default to empty
            approvals = [];
          }

          _pendingApprovals = List<Map<String, dynamic>>.from(approvals);
          _error = null;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = response.message;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error loading approvals: $e';
        _isLoading = false;
      });
    }
  }

  bool _canViewApprovals() {
    return AccessControlService.hasAccess(
      widget.userRole,
      'attendance',
      'approve_attendance'
    );
  }

  String _formatTime(String? timeStr) {
    if (timeStr == null) return '--:--';
    try {
      final dateTime = DateTime.parse(timeStr);
      final istTime = TimezoneUtil.utcToIST(dateTime);
      return TimezoneUtil.timeOnlyIST(istTime);
    } catch (e) {
      return timeStr;
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '--';
    try {
      final dateTime = DateTime.parse(dateStr);
      final istTime = TimezoneUtil.utcToIST(dateTime);
      return TimezoneUtil.dateOnlyIST(istTime);
    } catch (e) {
      return dateStr;
    }
  }

  Color _getStatusColor(String? reason) {
    switch (reason?.toLowerCase()) {
      case 'late':
        return Colors.orange;
      case 'early_checkout':
        return Colors.blue;
      case 'missed_checkout':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getApprovalReason(Map<String, dynamic> approval) {
    if (approval['isLate'] == true) return 'late';
    if (approval['checkOut']?['time'] == null && approval['checkIn']?['time'] != null) return 'missed_checkout';
    // Add more conditions as needed
    return 'other';
  }

  String _getStatusText(String? reason) {
    switch (reason?.toLowerCase()) {
      case 'late':
        return 'Late Check-in';
      case 'early_checkout':
        return 'Early Checkout';
      case 'missed_checkout':
        return 'Missed Checkout';
      default:
        return reason?.replaceAll('_', ' ').toUpperCase() ?? 'Pending';
    }
  }

  Widget _buildInfoCard(String label, String value, IconData icon, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFfbf8ff),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF272579),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleApproval(String attendanceId, bool approve, {String? comments}) async {
    try {
      final response = approve
          ? await ApiService.approveAttendance(
              attendanceId,
              comments: comments,
            )
          : await ApiService.rejectAttendance(
              attendanceId,
              comments: comments ?? 'Rejected by manager',
            );

      if (response.success && mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(approve ? 'Attendance approved' : 'Attendance rejected'),
            backgroundColor: approve ? Colors.green : Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );

        // Refresh the list
        _loadPendingApprovals();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  void _showApprovalDialog(Map<String, dynamic> approval) {
    final TextEditingController commentsController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            children: [
              // Drag Handle
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Employee Name Header
                      Text(
                        '${approval['userId']?['firstName']} ${approval['userId']?['lastName']}'.trim(),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF272579),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Status Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getStatusColor(_getApprovalReason(approval)),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          _getStatusText(_getApprovalReason(approval)),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Clock In Time - Prominent
                      _buildInfoCard(
                        'Clock In',
                        _formatTime(approval['checkIn']?['time']),
                        Icons.login,
                        const Color(0xFF0071bf),
                      ),
                      const SizedBox(height: 16),

                      // Clock Out Time (if available)
                      if (approval['checkOut']?['time'] != null) ...[
                        _buildInfoCard(
                          'Clock Out',
                          _formatTime(approval['checkOut']?['time']),
                          Icons.logout,
                          const Color(0xFF00b8d9),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Date
                      _buildInfoCard(
                        'Date',
                        _formatDate(approval['date']),
                        Icons.calendar_today,
                        Colors.grey[600]!,
                      ),

                      // Late Reason (from check-in)
                      if (approval['checkIn']?['lateReason'] != null && approval['checkIn']['lateReason'].toString().trim().isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _buildInfoCard(
                          'Late Reason',
                          approval['checkIn']['lateReason'],
                          Icons.warning,
                          Colors.red,
                        ),
                      ],

                      // Employee Comments (general)
                      if (approval['employeeComments'] != null && approval['employeeComments'].toString().trim().isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _buildInfoCard(
                          'Employee Note',
                          approval['employeeComments'],
                          Icons.comment,
                          Colors.orange,
                        ),
                      ],

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),

              // Action Buttons - Fixed at bottom
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    top: BorderSide(color: Colors.grey[200]!),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          final comments = commentsController.text.trim();
                          if (comments.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Comments are required for rejection'),
                                backgroundColor: Colors.red,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                            return;
                          }
                          Navigator.pop(context);
                          _handleApproval(
                            approval['_id'],
                            false,
                            comments: comments,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Reject',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _handleApproval(
                            approval['_id'],
                            true,
                            comments: commentsController.text.trim().isEmpty
                              ? null
                              : commentsController.text.trim(),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5cfbd8),
                          foregroundColor: const Color(0xFF272579),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Approve',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
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
    final canView = _canViewApprovals();

    if (!canView) {
      return const SizedBox.shrink();
    }

    if (_isLoading) {
      return Container(
        margin: const EdgeInsets.only(bottom: 24),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 12),
                Text(
                  'Loading approvals...',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_error != null) {
      return Container(
        margin: const EdgeInsets.only(bottom: 24),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
                TextButton(
                  onPressed: _loadPendingApprovals,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_pendingApprovals.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Pending Approvals',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF272579),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _pendingApprovals.length.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Show first 3 approvals, with option to see more
          ..._pendingApprovals.take(3).map((approval) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: Card(
              child: InkWell(
                onTap: () => _showApprovalDialog(approval),
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: _getStatusColor(_getApprovalReason(approval)).withValues(alpha: 0.1),
                        child: Icon(
                          Icons.schedule,
                          color: _getStatusColor(_getApprovalReason(approval)),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${approval['userId']?['firstName']} ${approval['userId']?['lastName']}'.trim(),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF272579),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(_getApprovalReason(approval)).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    _getStatusText(_getApprovalReason(approval)),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: _getStatusColor(_getApprovalReason(approval)),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _formatDate(approval['date']),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Colors.grey[400],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )),

          // Show more button if there are more than 3 approvals
          if (_pendingApprovals.length > 3)
            TextButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => ApprovalManagementScreen(
                      userRole: widget.userRole,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.visibility),
              label: Text('View all ${_pendingApprovals.length} approvals'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF0071bf),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
        ],
      ),
    );
  }
}
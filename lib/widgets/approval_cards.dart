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

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
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
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF272579),
                    ),
                  ),
                  Text(
                    _getStatusText(_getApprovalReason(approval)),
                    style: TextStyle(
                      fontSize: 12,
                      color: _getStatusColor(_getApprovalReason(approval)),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Attendance details
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFfbf8ff),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Text(_formatDate(approval['date'])),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Text('${_formatTime(approval['checkIn']?['time'])} - ${_formatTime(approval['checkOut']?['time'])}'),
                    ],
                  ),
                  if (_getApprovalReason(approval).isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 8),
                        Expanded(child: Text(approval['employeeComments'] ?? 'No comments')),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Comments field
            TextField(
              controller: commentsController,
              decoration: InputDecoration(
                labelText: 'Comments (Optional)',
                hintText: 'Add comments for this approval...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF0071bf)),
                ),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
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
            child: const Text(
              'Reject',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
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
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Approve',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
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
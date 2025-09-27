import 'dart:async';
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

  // Smart refresh management
  Timer? _refreshTimer;
  DateTime? _lastRefreshTime;
  bool _isRefreshEnabled = true;
  static const Duration _businessHoursInterval = Duration(minutes: 2);
  static const Duration _offHoursInterval = Duration(minutes: 5);
  static const Duration _minRefreshGap = Duration(seconds: 30);

  // Exponential backoff for failed requests
  int _failedRefreshCount = 0;
  static const int _maxFailedRefreshCount = 5;
  static const Duration _baseBackoffDuration = Duration(minutes: 1);

  // Auto-refresh visual indicator
  bool _isAutoRefreshing = false;

  @override
  void initState() {
    super.initState();
    _loadPendingApprovals();
    _startSmartRefresh();

    // Register this widget with the coordinator for pause/resume functionality
    ApprovalScreenCoordinator.registerDashboardRefreshControls(
      pauseRefresh: pauseRefresh,
      resumeRefresh: resumeRefresh,
    );
  }

  @override
  void dispose() {
    _stopRefreshTimer();
    ApprovalScreenCoordinator.unregisterDashboardRefreshControls();
    super.dispose();
  }

  Future<void> _loadPendingApprovals({bool isAutoRefresh = false}) async {
    final canView = _canViewApprovals();

    if (!canView) {
      setState(() => _isLoading = false);
      return;
    }

    // Check minimum refresh gap for auto-refresh
    if (isAutoRefresh && _lastRefreshTime != null) {
      final timeSinceLastRefresh = DateTime.now().difference(_lastRefreshTime!);
      if (timeSinceLastRefresh < _minRefreshGap) {
        debugPrint('⏭️ Skipping auto-refresh - too soon since last refresh');
        return;
      }
    }

    try {
      if (!isAutoRefresh) {
        setState(() => _isLoading = true);
      } else {
        setState(() => _isAutoRefreshing = true);
      }

      final response = await ApiService.getPendingApprovals();
      _lastRefreshTime = DateTime.now();

      if (response.success && response.data != null) {
        // Reset failed count on successful refresh
        _failedRefreshCount = 0;

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

          final newCount = approvals.length;
          final oldCount = _pendingApprovals.length;

          _pendingApprovals = List<Map<String, dynamic>>.from(approvals);
          _error = null;
          _isLoading = false;
          _isAutoRefreshing = false;

          // Log approval count changes for debugging
          if (isAutoRefresh && newCount != oldCount) {
            debugPrint('🔄 Auto-refresh: Approvals count changed from $oldCount to $newCount');
          }
        });

        // Update refresh timer based on current approval count
        _updateRefreshTimer();
      } else {
        _handleRefreshFailure(isAutoRefresh, response.message);
      }
    } catch (e) {
      _handleRefreshFailure(isAutoRefresh, 'Error loading approvals: $e');
    }
  }

  bool _canViewApprovals() {
    return AccessControlService.hasAccess(
      widget.userRole,
      'attendance',
      'approve_attendance'
    );
  }

  /// Handle refresh failures with exponential backoff
  void _handleRefreshFailure(bool isAutoRefresh, String errorMessage) {
    _failedRefreshCount++;

    setState(() {
      _error = errorMessage;
      _isLoading = false;
      _isAutoRefreshing = false;
    });

    // Stop auto-refresh if too many failures
    if (isAutoRefresh && _failedRefreshCount >= _maxFailedRefreshCount) {
      debugPrint('❌ Auto-refresh disabled due to repeated failures');
      _stopRefreshTimer();
    } else if (isAutoRefresh) {
      // Apply exponential backoff for auto-refresh
      _updateRefreshTimerWithBackoff();
    }
  }

  /// Update refresh timer with exponential backoff
  void _updateRefreshTimerWithBackoff() {
    if (!_isRefreshEnabled || !mounted || _pendingApprovals.isEmpty) return;

    _stopRefreshTimer();

    // Calculate backoff delay: base * 2^(failed_count - 1)
    final backoffMultiplier = 1 << (_failedRefreshCount - 1);
    final backoffDelay = _baseBackoffDuration * backoffMultiplier;
    final normalInterval = _getRefreshInterval();
    final totalInterval = normalInterval + backoffDelay;

    debugPrint('🔄 Setting approval refresh with backoff: ${totalInterval.inMinutes} minutes ($_failedRefreshCount failures)');

    _refreshTimer = Timer.periodic(totalInterval, (timer) {
      if (!mounted || !_isRefreshEnabled) {
        timer.cancel();
        return;
      }

      debugPrint('🔄 Auto-refreshing approval data (with backoff)');
      _loadPendingApprovals(isAutoRefresh: true);
    });
  }

  /// Start the smart refresh system
  void _startSmartRefresh() {
    if (!_canViewApprovals() || !_isRefreshEnabled) return;

    debugPrint('🔄 Starting smart approval refresh system');
    _updateRefreshTimer();
  }

  /// Stop the refresh timer
  void _stopRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
    debugPrint('⏹️ Stopped approval refresh timer');
  }

  /// Update refresh timer based on current conditions
  void _updateRefreshTimer() {
    if (!_isRefreshEnabled || !mounted) return;

    _stopRefreshTimer();

    // Only start periodic refresh if there are pending approvals
    if (_pendingApprovals.isEmpty) {
      debugPrint('⏭️ No pending approvals - skipping periodic refresh');
      return;
    }

    // Use backoff timer if there have been failures
    if (_failedRefreshCount > 0) {
      _updateRefreshTimerWithBackoff();
      return;
    }

    final interval = _getRefreshInterval();
    debugPrint('🔄 Setting approval refresh interval: ${interval.inMinutes} minutes');

    _refreshTimer = Timer.periodic(interval, (timer) {
      if (!mounted || !_isRefreshEnabled) {
        timer.cancel();
        return;
      }

      debugPrint('🔄 Auto-refreshing approval data');
      _loadPendingApprovals(isAutoRefresh: true);
    });
  }

  /// Get refresh interval based on business hours
  Duration _getRefreshInterval() {
    final now = DateTime.now();
    final hour = now.hour;

    // Business hours: 9 AM to 6 PM
    final isBusinessHours = hour >= 9 && hour < 18;

    return isBusinessHours ? _businessHoursInterval : _offHoursInterval;
  }

  /// Pause refresh (called when approval management screen is active)
  void pauseRefresh() {
    _isRefreshEnabled = false;
    _stopRefreshTimer();
    debugPrint('⏸️ Paused approval refresh');
  }

  /// Resume refresh (called when returning from approval management screen)
  void resumeRefresh() {
    _isRefreshEnabled = true;
    _startSmartRefresh();
    debugPrint('▶️ Resumed approval refresh');
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
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF272579).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF272579),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pending Approvals',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF272579),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Loading approvals...',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
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

    if (_error != null) {
      return Container(
        margin: const EdgeInsets.only(bottom: 24),
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pending Approvals',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF272579),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Error loading approvals',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
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

    // Show the simple card even if there are no pending approvals
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => ApprovalManagementScreen(
                  userRole: widget.userRole,
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _pendingApprovals.isEmpty
                        ? const Color(0xFF5cfbd8).withValues(alpha: 0.2)
                        : Colors.orange.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _pendingApprovals.isEmpty ? Icons.check_circle : Icons.pending_actions,
                    color: _pendingApprovals.isEmpty
                        ? const Color(0xFF5cfbd8)
                        : Colors.orange,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pending Approvals',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF272579),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _pendingApprovals.isEmpty
                            ? 'All caught up!'
                            : '${_pendingApprovals.length} item${_pendingApprovals.length == 1 ? '' : 's'} need${_pendingApprovals.length == 1 ? 's' : ''} review',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    // Auto-refresh indicator
                    if (_isAutoRefreshing)
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        child: SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.5,
                            color: Colors.grey[400],
                          ),
                        ),
                      ),
                    if (_pendingApprovals.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _pendingApprovals.length.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    const SizedBox(width: 12),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 18,
                      color: Colors.grey[400],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
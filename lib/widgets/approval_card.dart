import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/access_control_service.dart';
import '../screens/approval_management_screen.dart';

class ApprovalCard extends StatefulWidget {
  final String userRole;

  const ApprovalCard({
    super.key,
    required this.userRole,
  });

  @override
  State<ApprovalCard> createState() => _ApprovalCardState();
}

class _ApprovalCardState extends State<ApprovalCard> {
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

    debugPrint('🔍 _loadPendingApprovals called - canView: $canView, isAutoRefresh: $isAutoRefresh');
    debugPrint('🔍 User role: ${widget.userRole}');

    if (!canView) {
      debugPrint('🚫 User cannot view approvals - hiding widget');
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

      // Debug logging
      debugPrint('🔍 API Response - Success: ${response.success}');
      debugPrint('🔍 API Response - Data: ${response.data}');
      debugPrint('🔍 API Response - Message: ${response.message}');

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
        debugPrint('❌ API Response failed - Success: ${response.success}, Message: ${response.message}');
        _handleRefreshFailure(isAutoRefresh, response.message);
      }
    } catch (e) {
      debugPrint('❌ Exception in _loadPendingApprovals: $e');
      debugPrint('❌ Exception stack trace: ${StackTrace.current}');
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

    debugPrint('⚠️ Handling refresh failure #$_failedRefreshCount');
    debugPrint('⚠️ Error message: $errorMessage');
    debugPrint('⚠️ Is auto refresh: $isAutoRefresh');

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



  @override
  Widget build(BuildContext context) {
    final canView = _canViewApprovals();

    if (!canView) {
      return const SizedBox.shrink();
    }

    if (_isLoading) {
      // Hide card during loading - only show when we know there are approvals
      debugPrint('🔄 Approval card loading - hiding until data is available');
      return const SizedBox.shrink();
    }

    if (_error != null) {
      // Hide card completely when there are errors
      debugPrint('🚫 Hiding approval card due to error: $_error');
      return const SizedBox.shrink();
    }

    // Hide card when there are no pending approvals
    if (_pendingApprovals.isEmpty) {
      return const SizedBox.shrink();
    }

    // Show the approval card when there are pending approvals
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
                    color: Colors.orange.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.pending_actions,
                    color: Colors.orange,
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
'${_pendingApprovals.length} item${_pendingApprovals.length == 1 ? '' : 's'} need${_pendingApprovals.length == 1 ? 's' : ''} review',
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
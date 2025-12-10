import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../services/access_control_service.dart';
import '../utils/timezone_util.dart';
import '../widgets/loading_widget.dart';

class UnifiedApprovalScreen extends StatefulWidget {
  final String userRole;

  const UnifiedApprovalScreen({
    super.key,
    required this.userRole,
  });

  @override
  State<UnifiedApprovalScreen> createState() => _UnifiedApprovalScreenState();
}

// Coordinator for dashboard refresh
class ApprovalScreenCoordinator {
  static void Function()? _pauseDashboardRefresh;
  static void Function()? _resumeDashboardRefresh;
  static void Function()? _refreshDashboard;

  static void registerDashboardRefreshControls({
    required void Function() pauseRefresh,
    required void Function() resumeRefresh,
    void Function()? refreshNow,
  }) {
    _pauseDashboardRefresh = pauseRefresh;
    _resumeDashboardRefresh = resumeRefresh;
    _refreshDashboard = refreshNow;
  }

  static void pauseDashboardRefresh() {
    _pauseDashboardRefresh?.call();
  }

  static void resumeDashboardRefresh() {
    _resumeDashboardRefresh?.call();
  }

  static void refreshDashboard() {
    _refreshDashboard?.call();
  }

  static void unregisterDashboardRefreshControls() {
    _pauseDashboardRefresh = null;
    _resumeDashboardRefresh = null;
    _refreshDashboard = null;
  }
}

class _UnifiedApprovalScreenState extends State<UnifiedApprovalScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  int _attendanceCount = 0;
  int _conveyanceCount = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    ApprovalScreenCoordinator.pauseDashboardRefresh();
  }

  @override
  void dispose() {
    _tabController.dispose();
    ApprovalScreenCoordinator.refreshDashboard();
    ApprovalScreenCoordinator.resumeDashboardRefresh();
    super.dispose();
  }

  void _updateAttendanceCount(int count) {
    setState(() => _attendanceCount = count);
  }

  void _updateConveyanceCount(int count) {
    setState(() => _conveyanceCount = count);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Approvals'),
            if (_attendanceCount + _conveyanceCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_attendanceCount + _conveyanceCount}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF272579), Color(0xFF0071bf)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Attendance'),
            Tab(text: 'Conveyance'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          AttendanceApprovalsTab(
            userRole: widget.userRole,
            onCountUpdate: _updateAttendanceCount,
          ),
          ConveyanceApprovalsTab(
            userRole: widget.userRole,
            onCountUpdate: _updateConveyanceCount,
          ),
        ],
      ),
    );
  }
}

// ============= ATTENDANCE APPROVALS TAB =============

class AttendanceApprovalsTab extends StatefulWidget {
  final String userRole;
  final Function(int) onCountUpdate;

  const AttendanceApprovalsTab({
    super.key,
    required this.userRole,
    required this.onCountUpdate,
  });

  @override
  State<AttendanceApprovalsTab> createState() => _AttendanceApprovalsTabState();
}

class _AttendanceApprovalsTabState extends State<AttendanceApprovalsTab> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _allApprovals = [];
  List<Map<String, dynamic>> _filteredApprovals = [];
  String? _error;
  final TextEditingController _searchController = TextEditingController();
  final String _selectedFilter = 'all';
  final String _selectedSort = 'date_desc';

  @override
  void initState() {
    super.initState();
    _loadApprovals();
    _searchController.addListener(_performSearch);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadApprovals() async {
    if (!_canViewApprovals()) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      setState(() => _isLoading = true);
      final response = await ApiService.getPendingApprovals();

      if (response.success && response.data != null) {
        final dynamic responseData = response.data;
        List<dynamic> approvals;

        if (responseData is List) {
          approvals = responseData;
        } else if (responseData is Map && responseData.containsKey('data')) {
          approvals = responseData['data'] ?? [];
        } else {
          approvals = [];
        }

        setState(() {
          _allApprovals = List<Map<String, dynamic>>.from(approvals);
          _error = null;
          _isLoading = false;
        });
        _performSearch();
        widget.onCountUpdate(_filteredApprovals.length);
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

  void _performSearch() {
    setState(() {
      _filteredApprovals = _allApprovals.where((approval) {
        final query = _searchController.text.toLowerCase();
        final employeeName = '${approval['userId']?['firstName']} ${approval['userId']?['lastName']}'.toLowerCase();
        final matchesSearch = query.isEmpty || employeeName.contains(query);

        bool matchesFilter = true;
        if (_selectedFilter != 'all') {
          matchesFilter = _getApprovalReason(approval).toLowerCase() == _selectedFilter;
        }

        return matchesSearch && matchesFilter;
      }).toList();

      _filteredApprovals.sort((a, b) {
        switch (_selectedSort) {
          case 'date_asc':
            return DateTime.parse(a['date'] ?? '').compareTo(DateTime.parse(b['date'] ?? ''));
          case 'name_asc':
            final nameA = '${a['userId']?['firstName']} ${a['userId']?['lastName']}';
            final nameB = '${b['userId']?['firstName']} ${b['userId']?['lastName']}';
            return nameA.compareTo(nameB);
          case 'name_desc':
            final nameA = '${a['userId']?['firstName']} ${a['userId']?['lastName']}';
            final nameB = '${b['userId']?['firstName']} ${b['userId']?['lastName']}';
            return nameB.compareTo(nameA);
          case 'date_desc':
          default:
            return DateTime.parse(b['date'] ?? '').compareTo(DateTime.parse(a['date'] ?? ''));
        }
      });
    });
    widget.onCountUpdate(_filteredApprovals.length);
  }

  String _getApprovalReason(Map<String, dynamic> approval) {
    if (approval['isLate'] == true) return 'late';
    if (approval['checkOut']?['time'] == null && approval['checkIn']?['time'] != null) return 'missed_checkout';
    return 'other';
  }

  String _getStatusText(String? reason) {
    switch (reason?.toLowerCase()) {
      case 'late':
        return 'Late Clock In';
      case 'early_checkout':
        return 'Early Checkout';
      case 'missed_checkout':
        return 'Missed Checkout';
      default:
        return reason?.replaceAll('_', ' ').toUpperCase() ?? 'Pending';
    }
  }

  Color _getStatusColor(String? reason) {
    switch (reason?.toLowerCase()) {
      case 'late':
        return const Color(0xFF00b8d9);
      case 'early_checkout':
        return const Color(0xFF00b8d9);
      case 'missed_checkout':
        return Colors.red;
      default:
        return const Color(0xFF272579);
    }
  }

  IconData _getStatusIcon(String? reason) {
    switch (reason?.toLowerCase()) {
      case 'late':
        return Icons.schedule;
      case 'early_checkout':
        return Icons.logout;
      case 'missed_checkout':
        return Icons.warning;
      default:
        return Icons.pending;
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

  Future<void> _handleSingleApproval(String attendanceId, bool approve) async {
    try {
      final response = approve
          ? await ApiService.approveAttendance(attendanceId)
          : await ApiService.rejectAttendance(attendanceId, comments: 'Rejected by manager');

      if (response.success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(approve ? 'Attendance approved' : 'Attendance rejected'),
            backgroundColor: approve ? Colors.green : Colors.red,
          ),
        );
        _loadApprovals();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildApprovalCard(Map<String, dynamic> approval) {
    final reason = _getApprovalReason(approval);
    final statusColor = _getStatusColor(reason);
    final lateReason = approval['checkIn']?['lateReason']?.toString().trim();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _getStatusText(reason),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      _getStatusIcon(reason),
                      color: statusColor,
                      size: 18,
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
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF272579),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDate(approval['date']),
                          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                        ),
                        if (approval['checkIn']?['time'] != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            'In: ${_formatTime(approval['checkIn']?['time'])}',
                            style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                          ),
                        ],
                        if (lateReason != null && lateReason.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Reason: $lateReason',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () => _handleSingleApproval(approval['_id'], false),
                        icon: const Icon(Icons.close, color: Colors.red),
                        iconSize: 20,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        padding: EdgeInsets.zero,
                      ),
                      IconButton(
                        onPressed: () => _handleSingleApproval(approval['_id'], true),
                        icon: const Icon(Icons.check, color: Color(0xFF5cfbd8)),
                        iconSize: 20,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_canViewApprovals()) {
      return const Center(
        child: Text('You do not have permission to view approvals.'),
      );
    }

    return _isLoading
        ? const LoadingWidget(message: 'Loading approvals...')
        : _error != null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: Colors.red[400]),
                    const SizedBox(height: 16),
                    Text(_error!, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadApprovals,
                      child: const Text('Try Again'),
                    ),
                  ],
                ),
              )
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search by employee name...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: _filteredApprovals.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_circle_outline, size: 48, color: Colors.grey[400]),
                                const SizedBox(height: 16),
                                const Text('No pending approvals'),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: () => _loadApprovals(),
                            child: ListView.builder(
                              itemCount: _filteredApprovals.length,
                              itemBuilder: (context, index) {
                                return _buildApprovalCard(_filteredApprovals[index]);
                              },
                            ),
                          ),
                  ),
                ],
              );
  }
}

// ============= CONVEYANCE APPROVALS TAB =============

class ConveyanceApprovalsTab extends StatefulWidget {
  final String userRole;
  final Function(int) onCountUpdate;

  const ConveyanceApprovalsTab({
    super.key,
    required this.userRole,
    required this.onCountUpdate,
  });

  @override
  State<ConveyanceApprovalsTab> createState() => _ConveyanceApprovalsTabState();
}

class _ConveyanceApprovalsTabState extends State<ConveyanceApprovalsTab> {
  bool _isLoading = true;
  List<dynamic> _pendingClaims = [];
  String? _searchQuery;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPendingClaims();
  }

  Future<void> _loadPendingClaims() async {
    try {
      setState(() => _isLoading = true);
      final response = await ApiService.getPendingConveyanceApprovals();

      if (!mounted) return;

      if (response.success) {
        setState(() {
          _pendingClaims = response.data as List<dynamic>? ?? [];
          _error = null;
          _isLoading = false;
        });
        widget.onCountUpdate(_pendingClaims.length);
      } else {
        setState(() {
          _error = response.message;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Error loading claims: $e';
        _isLoading = false;
      });
    }
  }

  List<dynamic> _getFilteredClaims() {
    if (_searchQuery == null || _searchQuery!.isEmpty) {
      return _pendingClaims;
    }

    return _pendingClaims
        .where((claim) {
          final firstName = (claim['userId']?['firstName'] as String? ?? '').toLowerCase();
          final lastName = (claim['userId']?['lastName'] as String? ?? '').toLowerCase();
          final searchLower = _searchQuery!.toLowerCase();
          return firstName.contains(searchLower) || lastName.contains(searchLower);
        })
        .toList();
  }

  Future<void> _approveClaim(String claimId) async {
    try {
      final response = await ApiService.approveConveyanceClaim(claimId: claimId);

      if (!mounted) return;

      if (response.success) {
        _loadPendingClaims();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.message), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _rejectClaim(String claimId, String comments) async {
    try {
      final response = await ApiService.rejectConveyanceClaim(
        claimId: claimId,
        comments: comments,
      );

      if (!mounted) return;

      if (response.success) {
        _loadPendingClaims();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.message), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error rejecting claim: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildClaimTile(dynamic claim) {
    final claimId = claim['_id'] as String?;
    final date = claim['date'] as String?;
    final amount = claim['amount'] as num?;
    final purpose = claim['purpose'] as String?;
    final firstName = (claim['userId']?['firstName'] as String? ?? 'Unknown');
    final lastName = (claim['userId']?['lastName'] as String? ?? '');

    DateTime? parsedDate;
    if (date != null) {
      parsedDate = DateTime.tryParse(date);
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$firstName $lastName',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                      if (parsedDate != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('dd MMM yyyy, hh:mm a').format(parsedDate),
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ],
                  ),
                ),
                if (amount != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00b8d9).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '₹${amount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF00b8d9),
                      ),
                    ),
                  ),
              ],
            ),
            if (purpose != null && purpose.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Purpose: $purpose',
                style: TextStyle(fontSize: 13, color: Colors.grey[800]),
              ),
            ],
            const SizedBox(height: 12),
            if (claimId != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _rejectClaim(claimId, ''),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Reject'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _approveClaim(claimId),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Approve'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5cfbd8),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredClaims = _getFilteredClaims();

    return _isLoading
        ? const LoadingWidget(message: 'Loading claims...')
        : _error != null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: Colors.red[400]),
                    const SizedBox(height: 16),
                    Text(_error!, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadPendingClaims,
                      child: const Text('Try Again'),
                    ),
                  ],
                ),
              )
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search by employee name',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onChanged: (value) {
                        setState(() => _searchQuery = value);
                      },
                    ),
                  ),
                  Expanded(
                    child: filteredClaims.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_circle_outline, size: 48, color: Colors.grey[400]),
                                const SizedBox(height: 16),
                                const Text('No pending claims'),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadPendingClaims,
                            child: ListView.builder(
                              itemCount: filteredClaims.length,
                              itemBuilder: (context, index) {
                                return _buildClaimTile(filteredClaims[index]);
                              },
                            ),
                          ),
                  ),
                ],
              );
  }
}

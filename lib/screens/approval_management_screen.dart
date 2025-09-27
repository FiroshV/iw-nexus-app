import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/access_control_service.dart';
import '../utils/timezone_util.dart';
import '../widgets/loading_widget.dart';

class ApprovalManagementScreen extends StatefulWidget {
  final String userRole;

  const ApprovalManagementScreen({
    super.key,
    required this.userRole,
  });

  @override
  State<ApprovalManagementScreen> createState() => _ApprovalManagementScreenState();
}

// Global reference to pause/resume dashboard refresh
// This is used to coordinate between the approval screen and dashboard widget
class ApprovalScreenCoordinator {
  static void Function()? _pauseDashboardRefresh;
  static void Function()? _resumeDashboardRefresh;

  static void registerDashboardRefreshControls({
    required void Function() pauseRefresh,
    required void Function() resumeRefresh,
  }) {
    _pauseDashboardRefresh = pauseRefresh;
    _resumeDashboardRefresh = resumeRefresh;
  }

  static void pauseDashboardRefresh() {
    _pauseDashboardRefresh?.call();
  }

  static void resumeDashboardRefresh() {
    _resumeDashboardRefresh?.call();
  }

  static void unregisterDashboardRefreshControls() {
    _pauseDashboardRefresh = null;
    _resumeDashboardRefresh = null;
  }
}

class _ApprovalManagementScreenState extends State<ApprovalManagementScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _allApprovals = [];
  List<Map<String, dynamic>> _filteredApprovals = [];
  final Set<String> _selectedApprovals = {};
  String? _error;

  // Search and filter state
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'all'; // all, late, early_checkout, missed_checkout
  String _selectedSort = 'date_desc'; // date_desc, date_asc, name_asc, name_desc

  @override
  void initState() {
    super.initState();

    // Pause dashboard refresh when this screen is active
    ApprovalScreenCoordinator.pauseDashboardRefresh();

    _loadApprovals();
    _searchController.addListener(_performSearch);
  }

  @override
  void dispose() {
    _searchController.dispose();

    // Resume dashboard refresh when leaving this screen
    ApprovalScreenCoordinator.resumeDashboardRefresh();

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

          _allApprovals = List<Map<String, dynamic>>.from(approvals);
          _error = null;
          _isLoading = false;
        });
        _performSearch();
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

  Future<void> _refreshApprovals() async {
    await _loadApprovals();
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
        // Search filter
        final query = _searchController.text.toLowerCase();
        final employeeName = '${approval['userId']?['firstName']} ${approval['userId']?['lastName']}'.toLowerCase();
        final matchesSearch = query.isEmpty || employeeName.contains(query);

        // Type filter
        bool matchesFilter = true;
        if (_selectedFilter != 'all') {
          matchesFilter = _getApprovalReason(approval).toLowerCase() == _selectedFilter;
        }

        return matchesSearch && matchesFilter;
      }).toList();

      // Apply sorting
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

  String _getApprovalReason(Map<String, dynamic> approval) {
    if (approval['isLate'] == true) return 'late';
    if (approval['checkOut']?['time'] == null && approval['checkIn']?['time'] != null) return 'missed_checkout';
    // Add more conditions as needed
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

  Future<void> _handleSingleApproval(String attendanceId, bool approve, {String? comments}) async {
    try {
      final response = approve
          ? await ApiService.approveAttendance(attendanceId, comments: comments)
          : await ApiService.rejectAttendance(attendanceId, comments: comments ?? 'Rejected by manager');

      if (response.success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(approve ? 'Attendance approved' : 'Attendance rejected'),
            backgroundColor: approve ? Colors.green : Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        _refreshApprovals();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  Future<void> _handleBulkApproval(bool approve) async {
    if (_selectedApprovals.isEmpty) return;

    final TextEditingController commentsController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(approve ? 'Bulk Approve' : 'Bulk Reject'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to ${approve ? 'approve' : 'reject'} ${_selectedApprovals.length} attendance records?'),
            if (!approve) ...[
              const SizedBox(height: 16),
              TextField(
                controller: commentsController,
                decoration: const InputDecoration(
                  labelText: 'Rejection Reason (Required)',
                  hintText: 'Enter reason for bulk rejection...',
                ),
                maxLines: 2,
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (!approve && commentsController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Rejection reason is required')),
                );
                return;
              }
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: approve ? const Color(0xFF5cfbd8) : Colors.red,
              foregroundColor: approve ? const Color(0xFF272579) : Colors.white,
            ),
            child: Text(approve ? 'Approve All' : 'Reject All'),
          ),
        ],
      ),
    ) ?? false;

    if (!confirmed) return;

    setState(() => _isLoading = true);

    int successCount = 0;
    int failCount = 0;

    for (final attendanceId in _selectedApprovals) {
      try {
        final response = approve
            ? await ApiService.approveAttendance(attendanceId)
            : await ApiService.rejectAttendance(attendanceId, comments: commentsController.text.trim());

        if (response.success) {
          successCount++;
        } else {
          failCount++;
        }
      } catch (e) {
        failCount++;
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$successCount ${approve ? 'approved' : 'rejected'}${failCount > 0 ? ', $failCount failed' : ''}',
          ),
          backgroundColor: failCount > 0 ? Colors.orange : Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }

    setState(() {
      _selectedApprovals.clear();
    });

    await _refreshApprovals();
  }




  Widget _buildApprovalCard(Map<String, dynamic> approval) {
    final isSelected = _selectedApprovals.contains(approval['_id']);
    final reason = _getApprovalReason(approval);
    final statusColor = _getStatusColor(reason);
    final lateReason = approval['checkIn']?['lateReason']?.toString()?.trim();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        elevation: isSelected ? 2 : 1,
        shadowColor: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onLongPress: () {
            setState(() {
              if (isSelected) {
                _selectedApprovals.remove(approval['_id']);
              } else {
                _selectedApprovals.add(approval['_id']);
              }
            });
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: isSelected
                  ? Border.all(color: const Color(0xFF0071bf), width: 2)
                  : Border.all(color: Colors.grey[200]!, width: 1),
              color: isSelected ? const Color(0xFF0071bf).withValues(alpha: 0.05) : Colors.white,
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Row(
                    children: [
                      if (_selectedApprovals.isNotEmpty) ...[
                        Checkbox(
                          value: isSelected,
                          onChanged: (checked) {
                            setState(() {
                              if (checked == true) {
                                _selectedApprovals.add(approval['_id']);
                              } else {
                                _selectedApprovals.remove(approval['_id']);
                              }
                            });
                          },
                          activeColor: const Color(0xFF0071bf),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        const SizedBox(width: 8),
                      ],

                      // Status icon
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
                            // Name and status row
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '${approval['userId']?['firstName']} ${approval['userId']?['lastName']}'.trim(),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF272579),
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: statusColor,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    _getStatusText(reason),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),

                            // Date and time info
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _formatDate(approval['date']),
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                if (approval['checkIn']?['time'] != null) ...[
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.access_time,
                                        size: 12,
                                        color: Colors.grey[600],
                                      ),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          'In: ${_formatTime(approval['checkIn']?['time'])}${approval['checkOut']?['time'] != null ? ' • Out: ${_formatTime(approval['checkOut']?['time'])}' : ''}',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey[700],
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),

                            // Late reason at the bottom with proper wrapping
                            if (lateReason != null && lateReason.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Reason: $lateReason',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                  fontStyle: FontStyle.italic,
                                ),
                                softWrap: true,
                              ),
                            ],
                          ],
                        ),
                      ),

                      if (_selectedApprovals.isEmpty) ...[
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(6),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.red.withValues(alpha: 0.25),
                                    blurRadius: 3,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: IconButton(
                                onPressed: () => _handleSingleApproval(
                                  approval['_id'],
                                  false,
                                  comments: 'Quick reject'
                                ),
                                icon: const Icon(Icons.close, color: Colors.white, size: 22),
                                constraints: const BoxConstraints(minWidth: 42, minHeight: 42),
                                padding: EdgeInsets.zero,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF5cfbd8),
                                borderRadius: BorderRadius.circular(6),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF5cfbd8).withValues(alpha: 0.25),
                                    blurRadius: 3,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: IconButton(
                                onPressed: () => _handleSingleApproval(approval['_id'], true),
                                icon: const Icon(Icons.check, color: Color(0xFF272579), size: 22),
                                constraints: const BoxConstraints(minWidth: 42, minHeight: 42),
                                padding: EdgeInsets.zero,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),

                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_canViewApprovals()) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Access Denied'),
          backgroundColor: const Color(0xFF272579),
        ),
        body: const Center(
          child: Text('You do not have permission to view approval requests.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Approvals'),
            if (_filteredApprovals.isNotEmpty) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _filteredApprovals.length.toString(),
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
      ),
      body: _isLoading
          ? const LoadingWidget(message: 'Loading approvals...')
          : _error != null
              ? Center(
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Colors.red[400],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Something went wrong',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _error!,
                          style: TextStyle(
                            color: Colors.red[600],
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _loadApprovals,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0071bf),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Try Again',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.all(16),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search by employee name...',
                          hintStyle: TextStyle(color: Colors.grey[500]),
                          prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: Icon(Icons.clear, color: Colors.grey[500]),
                                  onPressed: () {
                                    _searchController.clear();
                                    _performSearch();
                                  },
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Color(0xFF0071bf)),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                    ),

                    // Approvals list
                    Expanded(
                      child: _filteredApprovals.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(32),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      _searchController.text.isNotEmpty
                                          ? Icons.search_off
                                          : Icons.check_circle_outline,
                                      size: 48,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      _searchController.text.isNotEmpty || _selectedFilter != 'all'
                                          ? 'No matching approvals'
                                          : 'All caught up!',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _searchController.text.isNotEmpty || _selectedFilter != 'all'
                                          ? 'Try adjusting your search or filters'
                                          : 'No pending approval requests at the moment',
                                      style: TextStyle(
                                        color: Colors.grey[500],
                                        fontSize: 12,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    if (_searchController.text.isNotEmpty || _selectedFilter != 'all') ...[
                                      const SizedBox(height: 16),
                                      TextButton(
                                        onPressed: () {
                                          setState(() {
                                            _searchController.clear();
                                            _selectedFilter = 'all';
                                          });
                                          _performSearch();
                                        },
                                        child: const Text('Clear Filters'),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _refreshApprovals,
                              child: ListView.builder(
                                itemCount: _filteredApprovals.length,
                                itemBuilder: (context, index) {
                                  return _buildApprovalCard(_filteredApprovals[index]);
                                },
                              ),
                            ),
                    ),
                  ],
                ),
      floatingActionButton: _selectedApprovals.isNotEmpty
          ? Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FloatingActionButton.extended(
                  onPressed: () => _handleBulkApproval(false),
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  heroTag: 'reject',
                  label: Text('Reject ${_selectedApprovals.length}'),
                  icon: const Icon(Icons.close, size: 18),
                ),
                const SizedBox(width: 12),
                FloatingActionButton.extended(
                  onPressed: () => _handleBulkApproval(true),
                  backgroundColor: const Color(0xFF0071bf),
                  foregroundColor: Colors.white,
                  heroTag: 'approve',
                  label: Text('Approve ${_selectedApprovals.length}'),
                  icon: const Icon(Icons.check, size: 18),
                ),
              ],
            )
          : null,
    );
  }
}
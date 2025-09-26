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

class _ApprovalManagementScreenState extends State<ApprovalManagementScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _allApprovals = [];
  List<Map<String, dynamic>> _filteredApprovals = [];
  Set<String> _selectedApprovals = {};
  String? _error;

  // Search and filter state
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'all'; // all, late, early_checkout, missed_checkout
  String _selectedSort = 'date_desc'; // date_desc, date_asc, name_asc, name_desc

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

  void _showApprovalDialog(Map<String, dynamic> approval) {
    final TextEditingController commentsController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
            TextField(
              controller: commentsController,
              decoration: InputDecoration(
                labelText: 'Comments (Optional)',
                hintText: 'Add comments for this approval...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
            child: Text('Cancel', style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w600)),
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
              _handleSingleApproval(approval['_id'], false, comments: comments);
            },
            child: const Text('Reject', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _handleSingleApproval(
                approval['_id'],
                true,
                comments: commentsController.text.trim().isEmpty ? null : commentsController.text.trim(),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5cfbd8),
              foregroundColor: const Color(0xFF272579),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Approve', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = [
      {'key': 'all', 'label': 'All', 'color': Colors.grey},
      {'key': 'late', 'label': 'Late', 'color': Colors.orange},
      {'key': 'early_checkout', 'label': 'Early Checkout', 'color': Colors.blue},
      {'key': 'missed_checkout', 'label': 'Missed Checkout', 'color': Colors.red},
    ];

    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = _selectedFilter == filter['key'];

          return Container(
            margin: EdgeInsets.only(
              left: index == 0 ? 16 : 4,
              right: index == filters.length - 1 ? 16 : 4,
            ),
            child: FilterChip(
              selected: isSelected,
              label: Text(filter['label'] as String),
              onSelected: (selected) {
                setState(() {
                  _selectedFilter = selected ? (filter['key'] as String) : 'all';
                });
                _performSearch();
              },
              selectedColor: (filter['color'] as Color).withValues(alpha: 0.2),
              checkmarkColor: filter['color'] as Color,
              labelStyle: TextStyle(
                color: isSelected ? filter['color'] as Color : Colors.grey[600],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildApprovalCard(Map<String, dynamic> approval) {
    final isSelected = _selectedApprovals.contains(approval['_id']);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: () => _showApprovalDialog(approval),
          onLongPress: () {
            setState(() {
              if (isSelected) {
                _selectedApprovals.remove(approval['_id']);
              } else {
                _selectedApprovals.add(approval['_id']);
              }
            });
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: isSelected ? Border.all(color: const Color(0xFF0071bf), width: 2) : null,
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
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
                    ),
                    const SizedBox(width: 8),
                  ],
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
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
                              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                        if (approval['checkIn']?['time'] != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            '${_formatTime(approval['checkIn']?['time'])} - ${_formatTime(approval['checkOut']?['time'])}',
                            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (_selectedApprovals.isEmpty) ...[
                    IconButton(
                      onPressed: () => _handleSingleApproval(approval['_id'], false, comments: 'Quick reject'),
                      icon: const Icon(Icons.close, color: Colors.red, size: 20),
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    ),
                    IconButton(
                      onPressed: () => _handleSingleApproval(approval['_id'], true),
                      icon: const Icon(Icons.check, color: Colors.green, size: 20),
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    ),
                  ] else
                    Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
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
        backgroundColor: const Color(0xFF272579),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            onSelected: (value) {
              setState(() => _selectedSort = value);
              _performSearch();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'date_desc', child: Text('Newest First')),
              const PopupMenuItem(value: 'date_asc', child: Text('Oldest First')),
              const PopupMenuItem(value: 'name_asc', child: Text('Name A-Z')),
              const PopupMenuItem(value: 'name_desc', child: Text('Name Z-A')),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshApprovals,
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingWidget(message: 'Loading approvals...')
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadApprovals,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Search bar
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search by employee name...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF0071bf)),
                          ),
                        ),
                      ),
                    ),

                    // Filter chips
                    _buildFilterChips(),

                    const SizedBox(height: 16),

                    // Approvals list
                    Expanded(
                      child: _filteredApprovals.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check_circle_outline, size: 64, color: Colors.grey[400]),
                                  const SizedBox(height: 16),
                                  Text(
                                    _searchController.text.isNotEmpty || _selectedFilter != 'all'
                                        ? 'No approvals match your filters'
                                        : 'No pending approvals',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                  if (_searchController.text.isNotEmpty || _selectedFilter != 'all') ...[
                                    const SizedBox(height: 8),
                                    TextButton(
                                      onPressed: () {
                                        setState(() {
                                          _searchController.clear();
                                          _selectedFilter = 'all';
                                        });
                                        _performSearch();
                                      },
                                      child: const Text('Clear filters'),
                                    ),
                                  ],
                                ],
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
                  label: Text('Reject ${_selectedApprovals.length}'),
                  icon: const Icon(Icons.close),
                ),
                const SizedBox(width: 16),
                FloatingActionButton.extended(
                  onPressed: () => _handleBulkApproval(true),
                  backgroundColor: const Color(0xFF5cfbd8),
                  foregroundColor: const Color(0xFF272579),
                  label: Text('Approve ${_selectedApprovals.length}'),
                  icon: const Icon(Icons.check),
                ),
              ],
            )
          : null,
    );
  }
}
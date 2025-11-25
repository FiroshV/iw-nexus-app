import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../services/access_control_service.dart';
import 'submit_conveyance_screen.dart';

class ConveyanceScreen extends StatefulWidget {
  final String? userRole;
  final String? userId;

  const ConveyanceScreen({
    super.key,
    this.userRole,
    this.userId,
  });

  @override
  State<ConveyanceScreen> createState() => _ConveyanceScreenState();
}

class _ConveyanceScreenState extends State<ConveyanceScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  bool _showAnalyticsTab = false;
  final GlobalKey<_MyClaimsTabState> _myClaimsTabKey = GlobalKey<_MyClaimsTabState>();

  @override
  void initState() {
    super.initState();
    _showAnalyticsTab = widget.userRole != null &&
        AccessControlService.hasAccess(
          widget.userRole!,
          'conveyance_management',
          'view_all',
        );

    _tabController = TabController(
      length: _showAnalyticsTab ? 2 : 1,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Conveyance'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF272579), Color(0xFF0071bf)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        bottom: _showAnalyticsTab
            ? TabBar(
                controller: _tabController,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white,
                indicatorColor: Colors.white,
                tabs: const [
                  Tab(text: 'My Claims'),
                  Tab(text: 'Analytics'),
                ],
              )
            : null,
      ),
      body: _showAnalyticsTab
          ? TabBarView(
              controller: _tabController,
              children: [
                MyClaimsTab(key: _myClaimsTabKey, userRole: widget.userRole),
                AnalyticsTab(userRole: widget.userRole),
              ],
            )
          : MyClaimsTab(key: _myClaimsTabKey, userRole: widget.userRole),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const SubmitConveyanceScreen()),
          );

          // Refresh claims immediately after successful submission
          if (result == true && mounted) {
            _myClaimsTabKey.currentState?._loadClaims();
          }
        },
        backgroundColor: const Color(0xFF0071bf),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

// ============= MY CLAIMS TAB =============

class MyClaimsTab extends StatefulWidget {
  final String? userRole;

  const MyClaimsTab({super.key, this.userRole});

  @override
  State<MyClaimsTab> createState() => _MyClaimsTabState();
}

class _MyClaimsTabState extends State<MyClaimsTab> {
  bool _isLoading = true;
  List<dynamic> _claims = [];
  Map<String, dynamic>? _summary;
  String _selectedFilter = 'all';
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadClaims();
  }

  Future<void> _loadClaims() async {
    try {
      setState(() => _isLoading = true);
      final response = await ApiService.getMyConveyanceClaims();

      if (!mounted) return;

      if (response.success) {
        final dynamic data = response.data;
        List<dynamic> claims = [];
        Map<String, dynamic>? summary;

        if (data is Map) {
          claims = data['data'] ?? [];
          summary = data['summary'] as Map<String, dynamic>?;
        } else if (data is List) {
          claims = data;
        }

        setState(() {
          _claims = _applyFilter(claims);
          _summary = summary;
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
      if (!mounted) return;
      setState(() {
        _error = 'Error loading claims: $e';
        _isLoading = false;
      });
    }
  }

  List<dynamic> _applyFilter(List<dynamic> claims) {
    if (_selectedFilter == 'all') {
      return claims;
    }
    return claims.where((claim) => claim['status'] == _selectedFilter).toList();
  }

  void _updateFilter(String filter) {
    setState(() {
      _selectedFilter = filter;
      final allClaims = _claims.where((c) => true).toList();
      _claims = _applyFilter(allClaims);
    });
    _loadClaims();
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'approved':
        return const Color(0xFF5cfbd8);
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    return status[0].toUpperCase() + status.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _error != null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: Colors.red[400]),
                    const SizedBox(height: 16),
                    Text(_error!),
                    const SizedBox(height: 16),
                    ElevatedButton(onPressed: _loadClaims, child: const Text('Retry')),
                  ],
                ),
              )
            : RefreshIndicator(
                onRefresh: _loadClaims,
                child: ListView(
                  children: [
                    if (_summary != null) ...[
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            // Total Amount Card
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF00b8d9).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFF00b8d9).withValues(alpha: 0.2),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Total Claimed',
                                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '₹${_summary!['totalAmount']?.toStringAsFixed(2) ?? '0.00'}',
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF00b8d9),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Stats Row
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      children: [
                                        Text(
                                          '${_summary!['pendingCount'] ?? 0}',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.orange,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        const Text('Pending', style: TextStyle(fontSize: 11)),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF5cfbd8).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      children: [
                                        Text(
                                          '${_summary!['totalCount'] ?? 0}',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF5cfbd8),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        const Text('Total Claims', style: TextStyle(fontSize: 11)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                    // Filter Chips
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildFilterChip('all', 'All'),
                            const SizedBox(width: 8),
                            _buildFilterChip('pending', 'Pending'),
                            const SizedBox(width: 8),
                            _buildFilterChip('approved', 'Approved'),
                            const SizedBox(width: 8),
                            _buildFilterChip('rejected', 'Rejected'),
                          ],
                        ),
                      ),
                    ),
                    // Claims List
                    if (_claims.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(32),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.check_circle_outline, size: 48, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              const Text('No claims found'),
                            ],
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _claims.length,
                        itemBuilder: (context, index) {
                          return _buildClaimCard(_claims[index]);
                        },
                      ),
                  ],
                ),
              );
  }

  Widget _buildFilterChip(String status, String label) {
    final isSelected = _selectedFilter == status;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => _updateFilter(status),
      backgroundColor: Colors.white,
      selectedColor: const Color(0xFF0071bf).withValues(alpha: 0.1),
    );
  }

  Widget _buildClaimCard(dynamic claim) {
    final status = claim['status'] ?? 'unknown';
    final date = claim['date'] as String?;
    final amount = claim['amount'] as num?;
    final purpose = claim['purpose'] as String?;
    final statusColor = _getStatusColor(status);

    DateTime? parsedDate;
    if (date != null) {
      parsedDate = DateTime.tryParse(date);
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border(
            left: BorderSide(color: statusColor, width: 4),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (parsedDate != null)
                        Text(
                          DateFormat('dd MMM yyyy').format(parsedDate),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: status == 'approved' ? Colors.black : statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _getStatusText(status),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (amount != null)
                    Text(
                      '₹${amount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF00b8d9),
                      ),
                    ),
                ],
              ),
              if (purpose != null && purpose.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  purpose,
                  style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ============= ANALYTICS TAB =============

class AnalyticsTab extends StatefulWidget {
  final String? userRole;

  const AnalyticsTab({super.key, this.userRole});

  @override
  State<AnalyticsTab> createState() => _AnalyticsTabState();
}

class _AnalyticsTabState extends State<AnalyticsTab> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  Map<String, dynamic>? _analyticsData;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  late TabController _analyticsTabController;
  String? _error;
  String _selectedPreset = 'last30';
  late TextEditingController _startDateController;
  late TextEditingController _endDateController;
  String? _dateError;

  @override
  void initState() {
    super.initState();
    _analyticsTabController = TabController(length: 3, vsync: this);
    _startDateController = TextEditingController(
      text: DateFormat('dd/MM/yyyy').format(_startDate),
    );
    _endDateController = TextEditingController(
      text: DateFormat('dd/MM/yyyy').format(_endDate),
    );
    _loadAnalytics();
  }

  @override
  void dispose() {
    _analyticsTabController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    super.dispose();
  }

  Future<void> _loadAnalytics() async {
    try {
      setState(() => _isLoading = true);
      final response = await ApiService.getConveyanceAnalytics(
        startDate: _startDate,
        endDate: _endDate,
      );

      if (!mounted) return;

      if (response.success) {
        setState(() {
          _analyticsData = response.data as Map<String, dynamic>?;
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
      if (!mounted) return;
      setState(() {
        _error = 'Error loading analytics: $e';
        _isLoading = false;
      });
    }
  }

  DateTime? _parseDate(String dateString) {
    try {
      return DateFormat('dd/MM/yyyy').parse(dateString);
    } catch (e) {
      return null;
    }
  }

  bool _validateDates(DateTime startDate, DateTime endDate) {
    if (startDate.isAfter(endDate)) {
      setState(() => _dateError = 'Start date must be before end date');
      return false;
    }

    final maxDate = DateTime.now();
    final minDate = maxDate.subtract(const Duration(days: 365));

    if (startDate.isBefore(minDate) || startDate.isAfter(maxDate)) {
      setState(() => _dateError = 'Start date must be within the last 365 days');
      return false;
    }

    if (endDate.isAfter(maxDate)) {
      setState(() => _dateError = 'End date cannot be in the future');
      return false;
    }

    return true;
  }

  void _applyDatePreset(String preset) {
    final now = DateTime.now();
    DateTime start = now;
    DateTime end = now;

    switch (preset) {
      case 'last7':
        start = now.subtract(const Duration(days: 7));
        end = now;
        break;
      case 'last30':
        start = now.subtract(const Duration(days: 30));
        end = now;
        break;
      case 'thisMonth':
        start = DateTime(now.year, now.month, 1);
        end = DateTime(now.year, now.month, now.day); // Today or end of month, whichever is earlier
        break;
      case 'lastMonth':
        // Get first day of last month
        final firstDayOfThisMonth = DateTime(now.year, now.month, 1);
        start = DateTime(firstDayOfThisMonth.year, firstDayOfThisMonth.month - 1, 1);
        // Get last day of last month (day 0 of current month)
        end = DateTime(firstDayOfThisMonth.year, firstDayOfThisMonth.month, 0);
        break;
      default:
        return;
    }

    setState(() {
      _selectedPreset = preset;
      _startDate = start;
      _endDate = end;
    });
    _loadAnalytics();
  }

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _parseDate(_startDateController.text) ?? _startDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      final endDate = _parseDate(_endDateController.text) ?? _endDate;

      // If start date is after end date, set end date to start date
      if (picked.isAfter(endDate)) {
        setState(() {
          _startDateController.text = DateFormat('dd/MM/yyyy').format(picked);
          _endDateController.text = DateFormat('dd/MM/yyyy').format(picked);
        });
      } else {
        setState(() {
          _startDateController.text = DateFormat('dd/MM/yyyy').format(picked);
        });
      }
    }
  }

  Future<void> _selectEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _parseDate(_endDateController.text) ?? _endDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _endDateController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  void _showDatePicker() {
    _startDateController.text = DateFormat('dd/MM/yyyy').format(_startDate);
    _endDateController.text = DateFormat('dd/MM/yyyy').format(_endDate);
    setState(() => _dateError = null);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Date Range',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 20),
              // Start Date Input
              TextField(
                controller: _startDateController,
                decoration: InputDecoration(
                  labelText: 'Start Date',
                  hintText: 'dd/mm/yyyy',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: _selectStartDate,
                  ),
                ),
                keyboardType: TextInputType.datetime,
              ),
              const SizedBox(height: 16),
              // End Date Input
              TextField(
                controller: _endDateController,
                decoration: InputDecoration(
                  labelText: 'End Date',
                  hintText: 'dd/mm/yyyy',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: _selectEndDate,
                  ),
                ),
                keyboardType: TextInputType.datetime,
              ),
              // Error Message
              if (_dateError != null) ...{
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red[400], size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _dateError!,
                          style: TextStyle(
                            color: Colors.red[700],
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              },
              const SizedBox(height: 24),
              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        final startDate = _parseDate(_startDateController.text);
                        final endDate = _parseDate(_endDateController.text);

                        if (startDate == null || endDate == null) {
                          setState(() => _dateError = 'Invalid date format. Use dd/mm/yyyy');
                          return;
                        }

                        final now = DateTime.now();

                        // Check if dates are in valid range (not in future)
                        if (startDate.isAfter(now) || endDate.isAfter(now)) {
                          setState(() => _dateError = 'Dates cannot be in the future');
                          return;
                        }

                        // If start date is after end date, set end date to start date
                        var finalEndDate = endDate;
                        if (startDate.isAfter(endDate)) {
                          finalEndDate = startDate;
                          _endDateController.text = DateFormat('dd/MM/yyyy').format(startDate);
                        }

                        setState(() {
                          _selectedPreset = 'custom';
                          _startDate = startDate;
                          _endDate = finalEndDate;
                          _dateError = null;
                        });

                        Navigator.pop(context);
                        _loadAnalytics();
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: const Color(0xFF0071bf),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Apply',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _error != null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: Colors.red[400]),
                    const SizedBox(height: 16),
                    Text(_error!),
                    const SizedBox(height: 16),
                    ElevatedButton(onPressed: _loadAnalytics, child: const Text('Retry')),
                  ],
                ),
              )
            : SingleChildScrollView(
                child: Column(
                  children: [
                    // Date Range Selector
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Date Range Card
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF0071bf), Color(0xFF00b8d9)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF0071bf).withValues(alpha: 0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Analytics Period',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          DateFormat('dd MMM yyyy').format(_startDate),
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        const Text(
                                          'From',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.white60,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Icon(Icons.arrow_forward, color: Colors.white70),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          DateFormat('dd MMM yyyy').format(_endDate),
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        const Text(
                                          'To',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.white60,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: _showDatePicker,
                                    icon: const Icon(Icons.calendar_today, size: 18),
                                    label: const Text('Change Period'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: const Color(0xFF0071bf),
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Preset Filter Chips
                          const Text(
                            'Quick Filters',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 10),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _buildPresetChip('last7', 'Last 7 Days'),
                                const SizedBox(width: 8),
                                _buildPresetChip('last30', 'Last 30 Days'),
                                const SizedBox(width: 8),
                                _buildPresetChip('thisMonth', 'This Month'),
                                const SizedBox(width: 8),
                                _buildPresetChip('lastMonth', 'Last Month'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Summary Cards
                    if (_analyticsData != null) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF0071bf), Color(0xFF00b8d9)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Total Expenditure',
                                    style: TextStyle(color: Colors.white70, fontSize: 12),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '₹${_analyticsData!['summary']?['totalAmount']?.toStringAsFixed(2) ?? '0.00'}',
                                    style: const TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildStatCard(
                                    'Total Claims',
                                    '${_analyticsData!['summary']?['totalClaims'] ?? 0}',
                                    const Color(0xFF00b8d9),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildStatCard(
                                    'Approved',
                                    '${_analyticsData!['summary']?['approvedClaims'] ?? 0}',
                                    const Color(0xFF5cfbd8),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildStatCard(
                                    'Pending',
                                    '${_analyticsData!['summary']?['pendingCount'] ?? 0}',
                                    Colors.orange,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Tabs for different analytics views
                      Container(
                        color: Colors.white,
                        child: TabBar(
                          controller: _analyticsTabController,
                          labelColor: const Color(0xFF0071bf),
                          unselectedLabelColor: Colors.grey,
                          indicatorColor: const Color(0xFF0071bf),
                          tabs: const [
                            Tab(text: 'Daily'),
                            Tab(text: 'Top Claimants'),
                            Tab(text: 'By Branch'),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 400,
                        child: TabBarView(
                          controller: _analyticsTabController,
                          children: [
                            _buildDailyBreakdown(),
                            _buildTopClaimants(),
                            _buildByBranch(),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyBreakdown() {
    final dailyData = _analyticsData?['dailyBreakdown'] as List? ?? [];
    return ListView.builder(
      itemCount: dailyData.length,
      itemBuilder: (context, index) {
        final day = dailyData[index];
        return ListTile(
          title: Text(day['date'] ?? '--'),
          subtitle: Text('${day['count'] ?? 0} claims'),
          trailing: Text('₹${day['amount']?.toStringAsFixed(2) ?? '0.00'}'),
        );
      },
    );
  }

  Widget _buildTopClaimants() {
    final topClaimants = _analyticsData?['topClaimants'] as List? ?? [];
    return ListView.builder(
      itemCount: topClaimants.length,
      itemBuilder: (context, index) {
        final claimant = topClaimants[index];
        return ListTile(
          leading: CircleAvatar(
            child: Text('${index + 1}'),
          ),
          title: Text(claimant['userName'] ?? 'Unknown'),
          subtitle: Text('${claimant['claimCount'] ?? 0} claims'),
          trailing: Text('₹${claimant['totalAmount']?.toStringAsFixed(2) ?? '0.00'}'),
        );
      },
    );
  }

  Widget _buildPresetChip(String preset, String label) {
    final isSelected = _selectedPreset == preset;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => _applyDatePreset(preset),
      backgroundColor: Colors.white,
      selectedColor: const Color(0xFF0071bf).withValues(alpha: 0.15),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: isSelected ? const Color(0xFF0071bf) : Colors.grey[700],
      ),
      side: BorderSide(
        color: isSelected ? const Color(0xFF0071bf) : Colors.grey[300] ?? Colors.grey,
        width: isSelected ? 1.5 : 1,
      ),
    );
  }

  Widget _buildByBranch() {
    final byBranch = _analyticsData?['byBranch'] as List? ?? [];
    return ListView.builder(
      itemCount: byBranch.length,
      itemBuilder: (context, index) {
        final branch = byBranch[index];
        return ListTile(
          title: Text(branch['branchName'] ?? 'Unknown'),
          subtitle: Text('${branch['claimCount'] ?? 0} claims'),
          trailing: Text('₹${branch['totalAmount']?.toStringAsFixed(2) ?? '0.00'}'),
        );
      },
    );
  }
}

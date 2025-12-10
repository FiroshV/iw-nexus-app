import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class ConveyanceManagementScreen extends StatefulWidget {
  const ConveyanceManagementScreen({super.key});

  @override
  State<ConveyanceManagementScreen> createState() =>
      _ConveyanceManagementScreenState();
}

class _ConveyanceManagementScreenState extends State<ConveyanceManagementScreen>
    with TickerProviderStateMixin {
  bool _isLoading = true;
  Map<String, dynamic>? _analyticsData;
  late TabController _tabController;

  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _setDefaultDateRange();
    _loadAnalytics();
  }

  void _setDefaultDateRange() {
    final now = DateTime.now();
    _endDate = now;
    _startDate = DateTime(now.year, now.month, 1);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);

    try {
      final response = await ApiService.getConveyanceAnalytics(
        startDate: _startDate,
        endDate: _endDate,
      );

      if (!mounted) return;

      if (response.success) {
        setState(() {
          _analyticsData = response.data as Map<String, dynamic>?;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load analytics: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _selectDateRange() async {
    final currentContext = context;
    final startDate = await showDatePicker(
      context: currentContext,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (startDate == null) return;

    if (!mounted) return;

    final endDate = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
      firstDate: startDate,
      lastDate: DateTime.now(),
    );

    if (endDate == null) return;

    if (mounted) {
      setState(() {
        _startDate = startDate;
        _endDate = endDate;
      });

      _loadAnalytics();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF272579), Color(0xFF0071bf)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: const Text('Conveyance Analytics'),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Center(
              child: GestureDetector(
                onTap: _selectDateRange,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.calendar_today,
                          color: Colors.white, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Date Range',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Top Claimants'),
            Tab(text: 'By Branch'),
          ],
        ),
      ),
      backgroundColor: const Color(0xFFf8f9fa),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0071bf)),
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildTopClaimantsTab(),
                _buildByBranchTab(),
              ],
            ),
    );
  }

  Widget _buildOverviewTab() {
    if (_analyticsData == null) {
      return const Center(child: Text('No data available'));
    }

    final summary = _analyticsData!['summary'] as Map<String, dynamic>? ?? {};
    final totalAmount = summary['totalAmount'] as num? ?? 0;
    final totalClaims = summary['totalClaims'] as num? ?? 0;
    final approvedAmount = summary['approvedAmount'] as num? ?? 0;
    final approvedClaims = summary['approvedClaims'] as num? ?? 0;
    final pendingAmount = summary['pendingAmount'] as num? ?? 0;
    final pendingClaims = summary['pendingClaims'] as num? ?? 0;
    final rejectedAmount = summary['rejectedAmount'] as num? ?? 0;
    final rejectedClaims = summary['rejectedClaims'] as num? ?? 0;

    final dailyTotals = _analyticsData!['dailyTotals'] as List<dynamic>? ?? [];

    return RefreshIndicator(
      onRefresh: _loadAnalytics,
      color: const Color(0xFF0071bf),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary cards
            _buildSummaryCard(
              'Total Conveyance',
              '₹${totalAmount.toStringAsFixed(2)}',
              '${totalClaims.toInt()} claims',
              Icons.receipt_long,
              const Color(0xFF0071bf),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildSmallSummaryCard(
                    'Approved',
                    '₹${approvedAmount.toStringAsFixed(2)}',
                    '${approvedClaims.toInt()}',
                    const Color(0xFF5cfbd8),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSmallSummaryCard(
                    'Pending',
                    '₹${pendingAmount.toStringAsFixed(2)}',
                    '${pendingClaims.toInt()}',
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSmallSummaryCard(
                    'Rejected',
                    '₹${rejectedAmount.toStringAsFixed(2)}',
                    '${rejectedClaims.toInt()}',
                    Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Daily totals
            if (dailyTotals.isNotEmpty) ...[
              Text(
                'Daily Breakdown',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF272579),
                    ),
              ),
              const SizedBox(height: 12),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: dailyTotals.length,
                itemBuilder: (context, index) {
                  final daily = dailyTotals[index];
                  final date = daily['_id'] as String? ?? '';
                  final amount = daily['totalAmount'] as num? ?? 0;
                  final count = daily['count'] as num? ?? 0;

                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        left: BorderSide(
                          color: const Color(0xFF00b8d9).withValues(alpha: 0.6),
                          width: 3,
                        ),
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              date,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF272579),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${count.toInt()} claims',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '₹${amount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0071bf),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTopClaimantsTab() {
    if (_analyticsData == null) {
      return const Center(child: Text('No data available'));
    }

    final topClaimants =
        _analyticsData!['topClaimants'] as List<dynamic>? ?? [];

    if (topClaimants.isEmpty) {
      return const Center(child: Text('No claimants found'));
    }

    return RefreshIndicator(
      onRefresh: _loadAnalytics,
      color: const Color(0xFF0071bf),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: topClaimants.length,
        itemBuilder: (context, index) {
          final claimant = topClaimants[index];
          final firstName = claimant['firstName'] as String? ?? 'Unknown';
          final lastName = claimant['lastName'] as String? ?? '';
          final totalAmount = claimant['totalAmount'] as num? ?? 0;
          final count = claimant['count'] as num? ?? 0;

          return Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Rank circle
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0071bf), Color(0xFF00b8d9)],
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Name and claims
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$firstName $lastName',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF272579),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${count.toInt()} claims',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Amount
                  Text(
                    '₹${totalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0071bf),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildByBranchTab() {
    if (_analyticsData == null) {
      return const Center(child: Text('No data available'));
    }

    final branchWiseStats =
        _analyticsData!['branchWiseStats'] as List<dynamic>? ?? [];

    if (branchWiseStats.isEmpty) {
      return const Center(child: Text('No branch data available'));
    }

    return RefreshIndicator(
      onRefresh: _loadAnalytics,
      color: const Color(0xFF0071bf),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: branchWiseStats.length,
        itemBuilder: (context, index) {
          final branch = branchWiseStats[index];
          final branchName = branch['branchName'] as String? ?? 'Unknown Branch';
          final totalAmount = branch['totalAmount'] as num? ?? 0;
          final count = branch['count'] as num? ?? 0;

          return Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        branchName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF272579),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00b8d9).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${count.toInt()} claims',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF00b8d9),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Amount',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                        ),
                      ),
                      Text(
                        '₹${totalAmount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0071bf),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 40),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallSummaryCard(
    String label,
    String amount,
    String count,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            amount,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF272579),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            count,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

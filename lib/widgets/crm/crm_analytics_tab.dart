import 'package:flutter/material.dart';
import '../../config/crm_colors.dart';
import '../../services/api_service.dart';

class CrmAnalyticsTab extends StatefulWidget {
  final String userRole;
  final String selectedPeriod;
  final DateTime selectedDate;

  const CrmAnalyticsTab({
    super.key,
    required this.userRole,
    required this.selectedPeriod,
    required this.selectedDate,
  });

  @override
  State<CrmAnalyticsTab> createState() => _CrmAnalyticsTabState();
}

class _CrmAnalyticsTabState extends State<CrmAnalyticsTab> {
  bool _isLoading = true;
  Map<String, dynamic>? _salesByProductData;
  Map<String, dynamic>? _employeePerformanceData;
  Map<String, dynamic>? _visitEffectivenessData;
  Map<String, dynamic>? _branchSalesData;

  @override
  void initState() {
    super.initState();
    _loadAnalyticsData();
  }

  @override
  void didUpdateWidget(CrmAnalyticsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedPeriod != widget.selectedPeriod ||
        oldWidget.selectedDate != widget.selectedDate) {
      _loadAnalyticsData();
    }
  }

  Future<void> _loadAnalyticsData() async {
    setState(() => _isLoading = true);

    try {
      final dateRange = _getDateRange();

      // Load all analytics in parallel
      final results = await Future.wait([
        ApiService.getSalesByProductReport(
          startDate: dateRange['start'],
          endDate: dateRange['end'],
        ),
        ApiService.getEmployeePerformanceReport(
          startDate: dateRange['start'],
          endDate: dateRange['end'],
        ),
        ApiService.getVisitEffectivenessReport(
          startDate: dateRange['start'],
          endDate: dateRange['end'],
        ),
        ApiService.getBranchSalesReport(
          startDate: dateRange['start'],
          endDate: dateRange['end'],
        ),
      ]);

      if (mounted) {
        setState(() {
          _salesByProductData =
              results[0].success ? results[0].data as Map<String, dynamic> : null;
          _employeePerformanceData =
              results[1].success ? results[1].data as Map<String, dynamic> : null;
          _visitEffectivenessData =
              results[2].success ? results[2].data as Map<String, dynamic> : null;
          _branchSalesData =
              results[3].success ? results[3].data as Map<String, dynamic> : null;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load analytics: $e'),
            backgroundColor: CrmColors.errorColor,
          ),
        );
      }
    }
  }

  Map<String, DateTime> _getDateRange() {
    final now = widget.selectedDate;
    DateTime start, end;

    switch (widget.selectedPeriod) {
      case 'week':
        start = now.subtract(Duration(days: now.weekday - 1));
        end = start.add(const Duration(days: 6));
        break;
      case 'month':
        start = DateTime(now.year, now.month, 1);
        end = DateTime(now.year, now.month + 1, 0);
        break;
      case 'quarter':
        final quarter = ((now.month - 1) / 3).floor();
        start = DateTime(now.year, quarter * 3 + 1, 1);
        end = DateTime(now.year, quarter * 3 + 4, 0);
        break;
      default:
        start = DateTime(now.year, now.month, 1);
        end = DateTime(now.year, now.month + 1, 0);
    }

    return {'start': start, 'end': end};
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: CrmColors.primary),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sales by Product
          if (_salesByProductData != null) ...
            [
              _buildSectionTitle('Sales by Product'),
              _buildSalesbyProductCard(),
              const SizedBox(height: 24),
            ],

          // Employee Performance
          if (_employeePerformanceData != null) ...
            [
              _buildSectionTitle('Top Performers'),
              _buildEmployeePerformanceCard(),
              const SizedBox(height: 24),
            ],

          // Visit Effectiveness
          if (_visitEffectivenessData != null) ...
            [
              _buildSectionTitle('Visit Effectiveness'),
              _buildVisitEffectivenessCard(),
              const SizedBox(height: 24),
            ],

          // Branch Sales (for admins/directors)
          if (_branchSalesData != null) ...
            [
              _buildSectionTitle('Branch-wise Sales'),
              _buildBranchSalesCard(),
              const SizedBox(height: 24),
            ],
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: CrmColors.textDark,
            ),
      ),
    );
  }

  Widget _buildSalesbyProductCard() {
    final data = _salesByProductData?['byProductType'] as List? ?? [];

    if (data.isEmpty) {
      return _buildEmptyStateCard('No sales data available');
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: data.map<Widget>((item) {
            final productType = item['_id'] ?? 'Unknown';
            final count = item['count'] ?? 0;
            final totalAmount = (item['totalAmount'] ?? 0).toDouble();

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: CrmColors.getProductTypeColor(productType)
                              .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          CrmColors.getProductTypeName(productType),
                          style: Theme.of(context)
                              .textTheme
                              .labelMedium
                              ?.copyWith(
                                color: CrmColors.getProductTypeColor(
                                    productType),
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                      Text(
                        '₹${totalAmount.toStringAsFixed(0)}',
                        style: Theme.of(context)
                            .textTheme
                            .labelMedium
                            ?.copyWith(
                              color: CrmColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.trending_up,
                        size: 16,
                        color: CrmColors.textLight,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '$count sale${count != 1 ? 's' : ''}',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: CrmColors.textLight,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildEmployeePerformanceCard() {
    final data = _employeePerformanceData?['topPerformers'] as List? ?? [];

    if (data.isEmpty) {
      return _buildEmptyStateCard('No employee data available');
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: data.asMap().entries.map<Widget>((entry) {
            final index = entry.key + 1;
            final item = entry.value as Map<String, dynamic>;
            final employeeName = item['employeeName'] ?? 'Unknown';
            final salesCount = item['salesCount'] ?? 0;
            final totalAmount = (item['totalAmount'] ?? 0).toDouble();
            final averageValue = (item['averageValue'] ?? 0).toDouble();

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: CrmColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '#$index',
                        style: Theme.of(context)
                            .textTheme
                            .labelSmall
                            ?.copyWith(
                              color: CrmColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          employeeName,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: CrmColors.textDark,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              '$salesCount sales',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: CrmColors.textLight,
                                  ),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              'Avg: ₹${averageValue.toStringAsFixed(0)}',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: CrmColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '₹${totalAmount.toStringAsFixed(0)}',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: CrmColors.successColor,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildVisitEffectivenessCard() {
    final data = _visitEffectivenessData;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMetricRow(
              'Total Visits',
              '${data?['totalVisits'] ?? 0}',
            ),
            const SizedBox(height: 12),
            _buildMetricRow(
              'Successful Sales',
              '${data?['successfulSales'] ?? 0}',
              color: CrmColors.successColor,
            ),
            const SizedBox(height: 12),
            _buildMetricRow(
              'Conversion Rate',
              '${((data?['conversionRate'] ?? 0) * 100).toStringAsFixed(1)}%',
              color: CrmColors.primary,
            ),
            const SizedBox(height: 12),
            _buildMetricRow(
              'Average Outcome',
              data?['mostCommonOutcome'] ?? 'N/A',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBranchSalesCard() {
    final data = _branchSalesData?['branchData'] as List? ?? [];

    if (data.isEmpty) {
      return _buildEmptyStateCard('No branch data available');
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: data.map<Widget>((item) {
            final branchName = item['branchName'] ?? 'Unknown';
            final salesCount = item['salesCount'] ?? 0;
            final totalAmount = (item['totalAmount'] ?? 0).toDouble();

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        branchName,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: CrmColors.textDark,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$salesCount sale${salesCount != 1 ? 's' : ''}',
                        style: Theme.of(context)
                            .textTheme
                            .labelSmall
                            ?.copyWith(
                              color: CrmColors.textLight,
                            ),
                      ),
                    ],
                  ),
                  Text(
                    '₹${totalAmount.toStringAsFixed(0)}',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: CrmColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildMetricRow(String label, String value, {Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: CrmColors.textDark,
              ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: color ?? CrmColors.primary,
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }

  Widget _buildEmptyStateCard(String message) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.analytics_outlined,
                size: 48,
                color: CrmColors.textLight.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: CrmColors.textLight,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

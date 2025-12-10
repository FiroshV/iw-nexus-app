import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/crm_colors.dart';
import '../../services/reports_service.dart';

class PerformanceAnalyticsScreen extends StatefulWidget {
  final String? branchId;
  final String? userId;

  const PerformanceAnalyticsScreen({
    super.key,
    this.branchId,
    this.userId,
  });

  @override
  State<PerformanceAnalyticsScreen> createState() => _PerformanceAnalyticsScreenState();
}

class _PerformanceAnalyticsScreenState extends State<PerformanceAnalyticsScreen> {
  bool _isLoading = false;
  DateTime? _startDate;
  DateTime? _endDate;

  List<Map<String, dynamic>> _employeePerformance = [];
  Map<String, dynamic> _visitEffectiveness = {};

  @override
  void initState() {
    super.initState();
    _setDefaultDateRange();
    _loadAnalytics();
  }

  void _setDefaultDateRange() {
    final now = DateTime.now();
    _endDate = now;
    _startDate = now.subtract(const Duration(days: 30));
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);

    try {
      final performanceResponse = await ReportsService.getEmployeePerformance(
        startDate: _startDate?.toIso8601String(),
        endDate: _endDate?.toIso8601String(),
        branchId: widget.branchId,
        sortBy: 'salesCount',
      );

      final visitResponse = await ReportsService.getVisitEffectiveness(
        startDate: _startDate?.toIso8601String(),
        endDate: _endDate?.toIso8601String(),
        branchId: widget.branchId,
      );

      if (performanceResponse.success && visitResponse.success) {
        setState(() {
          _employeePerformance = performanceResponse.data ?? [];
          _visitEffectiveness = visitResponse.data ?? {};
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load analytics: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: _startDate ?? DateTime.now().subtract(const Duration(days: 30)),
        end: _endDate ?? DateTime.now(),
      ),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadAnalytics();
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Performance Analytics'),
        backgroundColor: CrmColors.primary,
        elevation: 2,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAnalytics,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Date Range Selector
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: GestureDetector(
                        onTap: _selectDateRange,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: CrmColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: CrmColors.borderColor),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Date Range',
                                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                          color: CrmColors.textLight,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${DateFormat('dd MMM').format(_startDate!)} - ${DateFormat('dd MMM').format(_endDate!)}',
                                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                ],
                              ),
                              const Icon(Icons.date_range, color: CrmColors.primary),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Visit Effectiveness Summary
                    if (_visitEffectiveness.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Visit Effectiveness',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            const SizedBox(height: 12),
                            _buildEffectivenessCards(),
                          ],
                        ),
                      ),
                    const SizedBox(height: 24),

                    // Employee Rankings
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Employee Rankings',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: 12),
                          if (_employeePerformance.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: CrmColors.surface,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  'No performance data available',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: CrmColors.textLight,
                                      ),
                                ),
                              ),
                            )
                          else
                            ..._buildEmployeeRankings(currencyFormat),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildEffectivenessCards() {
    final totalVisits = _visitEffectiveness['totalVisits'] ?? 0;
    final salesFromVisits = _visitEffectiveness['salesFromVisits'] ?? 0;
    final conversionRate = _visitEffectiveness['conversionRate'] ?? 0.0;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Total Visits',
                totalVisits.toString(),
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                'Sales Converted',
                salesFromVisits.toString(),
                CrmColors.success,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildMetricCard(
          'Conversion Rate',
          '${(conversionRate * 100).toStringAsFixed(1)}%',
          CrmColors.primary,
        ),
      ],
    );
  }

  Widget _buildMetricCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: CrmColors.textLight,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildEmployeeRankings(NumberFormat currencyFormat) {
    return _employeePerformance.asMap().entries.map((entry) {
      final index = entry.key;
      final employee = entry.value;
      final name = '${employee['employee']?['firstName'] ?? ''} ${employee['employee']?['lastName'] ?? ''}'.trim();
      final salesCount = employee['salesCount'] ?? 0;
      final totalAmount = employee['totalAmount'] ?? 0;
      final avgSaleValue = salesCount > 0 ? (totalAmount / salesCount).toInt() : 0;

      // Assign medal colors for top 3
      Color? medalColor;
      String? medal;
      if (index == 0) {
        medalColor = Colors.amber;
        medal = '🥇';
      } else if (index == 1) {
        medalColor = Colors.grey;
        medal = '🥈';
      } else if (index == 2) {
        medalColor = Colors.orange;
        medal = '🥉';
      }

      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: medalColor?.withValues(alpha: 0.3) ?? CrmColors.borderColor,
            width: medalColor != null ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            if (medal != null)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Text(medal, style: const TextStyle(fontSize: 24)),
              )
            else
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: CrmColors.primary.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '#${index + 1}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: CrmColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.shopping_cart, size: 14, color: CrmColors.textLight),
                      const SizedBox(width: 4),
                      Text(
                        '$salesCount sales',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: CrmColors.textLight,
                            ),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.trending_up, size: 14, color: CrmColors.textLight),
                      const SizedBox(width: 4),
                      Text(
                        'Avg: ${currencyFormat.format(avgSaleValue)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: CrmColors.textLight,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  currencyFormat.format(totalAmount),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: medalColor ?? CrmColors.primary,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Total',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: CrmColors.textLight,
                      ),
                ),
              ],
            ),
          ],
        ),
      );
    }).toList();
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/crm_colors.dart';
import '../../config/crm_design_system.dart';
import '../../services/reports_service.dart';

class SalesAnalyticsScreen extends StatefulWidget {
  final String? branchId;
  final String? userId;

  const SalesAnalyticsScreen({
    super.key,
    this.branchId,
    this.userId,
  });

  @override
  State<SalesAnalyticsScreen> createState() => _SalesAnalyticsScreenState();
}

class _SalesAnalyticsScreenState extends State<SalesAnalyticsScreen> {
  bool _isLoading = false;
  DateTime? _startDate;
  DateTime? _endDate;

  Map<String, dynamic> _salesByProduct = {};
  List<Map<String, dynamic>> _employeePerformance = [];

  @override
  void initState() {
    super.initState();
    _setDefaultDateRange();
    _loadAnalytics();
  }

  void _setDefaultDateRange() {
    final now = DateTime.now();
    _endDate = now;
    _startDate = now.subtract(const Duration(days: 30)); // Last 30 days
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);

    try {
      final salesResponse = await ReportsService.getSalesByProduct(
        startDate: _startDate?.toIso8601String(),
        endDate: _endDate?.toIso8601String(),
        branchId: widget.branchId,
        userId: widget.userId,
      );

      final performanceResponse = await ReportsService.getEmployeePerformance(
        startDate: _startDate?.toIso8601String(),
        endDate: _endDate?.toIso8601String(),
        branchId: widget.branchId,
      );

      if (salesResponse.success && performanceResponse.success) {
        setState(() {
          _salesByProduct = salesResponse.data ?? {};
          _employeePerformance = performanceResponse.data ?? [];
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
    final totalSalesAmount = _getTotalSalesAmount();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Sales Analytics',
          style: CrmDesignSystem.headlineSmall.copyWith(color: Colors.white),
        ),
        backgroundColor: CrmColors.primary,
        elevation: 2,
        shadowColor: CrmColors.primary.withValues(alpha: 0.3),
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(CrmColors.primary),
                  ),
                  const SizedBox(height: CrmDesignSystem.lg),
                  Text(
                    'Loading analytics...',
                    style: CrmDesignSystem.bodyMedium
                        .copyWith(color: CrmColors.textLight),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadAnalytics,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Date Range Selector
                    Padding(
                      padding: const EdgeInsets.all(CrmDesignSystem.lg),
                      child: GestureDetector(
                        onTap: _selectDateRange,
                        child: Container(
                          padding: const EdgeInsets.all(CrmDesignSystem.lg),
                          decoration: CrmDesignSystem.highlightedCardDecoration,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Date Range',
                                    style: CrmDesignSystem.labelSmall,
                                  ),
                                  const SizedBox(height: CrmDesignSystem.md),
                                  Text(
                                    '${DateFormat('dd MMM').format(_startDate!)} - ${DateFormat('dd MMM').format(_endDate!)}',
                                    style: CrmDesignSystem.titleLarge,
                                  ),
                                ],
                              ),
                              Icon(
                                Icons.date_range,
                                color: CrmColors.primary,
                                size: 28,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Key Metrics
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: CrmDesignSystem.lg,
                        vertical: CrmDesignSystem.md,
                      ),
                      child: Column(
                        children: [
                          _buildMetricCard(
                            'Total Sales Value',
                            currencyFormat.format(totalSalesAmount),
                            Colors.green,
                            Icons.trending_up,
                          ),
                          const SizedBox(height: CrmDesignSystem.lg),
                          _buildMetricCard(
                            'Total Transactions',
                            _getTotalTransactions().toString(),
                            CrmColors.primary,
                            Icons.shopping_cart,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: CrmDesignSystem.xxxl),

                    // Sales by Product Type
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: CrmDesignSystem.lg,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sales by Product Type',
                            style: CrmDesignSystem.headlineSmall,
                          ),
                          const SizedBox(height: CrmDesignSystem.lg),
                          if (_salesByProduct.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(CrmDesignSystem.xxl),
                              decoration: BoxDecoration(
                                color: CrmColors.surface,
                                borderRadius: BorderRadius.circular(
                                  CrmDesignSystem.radiusLarge,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  'No sales data available',
                                  style: CrmDesignSystem.bodyMedium
                                      .copyWith(color: CrmColors.textLight),
                                ),
                              ),
                            )
                          else
                            ..._buildProductCharts(),
                        ],
                      ),
                    ),
                    const SizedBox(height: CrmDesignSystem.xxxl),

                    // Top Performers
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: CrmDesignSystem.lg,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Top Performers',
                            style: CrmDesignSystem.headlineSmall,
                          ),
                          const SizedBox(height: CrmDesignSystem.lg),
                          if (_employeePerformance.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(CrmDesignSystem.xxl),
                              decoration: BoxDecoration(
                                color: CrmColors.surface,
                                borderRadius: BorderRadius.circular(
                                  CrmDesignSystem.radiusLarge,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  'No performance data available',
                                  style: CrmDesignSystem.bodyMedium
                                      .copyWith(color: CrmColors.textLight),
                                ),
                              ),
                            )
                          else
                            ..._buildPerformanceList(currencyFormat),
                        ],
                      ),
                    ),
                    const SizedBox(height: CrmDesignSystem.huge),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildMetricCard(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(CrmDesignSystem.lg),
      decoration: CrmDesignSystem.metricCardDecoration(color: color),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(CrmDesignSystem.md),
            decoration: CrmDesignSystem.statusIndicator(color: color),
            child: Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: CrmDesignSystem.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: CrmDesignSystem.labelSmall,
                ),
                const SizedBox(height: CrmDesignSystem.md),
                Text(
                  value,
                  style: CrmDesignSystem.headlineSmall.copyWith(
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildProductCharts() {
    final data = _salesByProduct;
    if (data['data'] == null) return [];

    final products = (data['data'] as Map<String, dynamic>).entries.toList();
    return products.map((entry) {
      final productType = entry.key;
      final stats = entry.value as Map<String, dynamic>;
      final count = stats['count'] ?? 0;
      final amount = stats['totalAmount'] ?? 0;
      final productColor = _getProductColor(productType);

      return Padding(
        padding: const EdgeInsets.only(bottom: CrmDesignSystem.md),
        child: Container(
          padding: const EdgeInsets.all(CrmDesignSystem.lg),
          decoration: CrmDesignSystem.cardDecoration,
          child: Row(
            children: [
              Container(
                width: 5,
                height: 80,
                decoration: BoxDecoration(
                  color: productColor,
                  borderRadius: BorderRadius.circular(
                    CrmDesignSystem.radiusSmall,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: productColor.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: CrmDesignSystem.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatProductType(productType),
                      style: CrmDesignSystem.titleLarge,
                    ),
                    const SizedBox(height: CrmDesignSystem.md),
                    Row(
                      children: [
                        Icon(
                          Icons.shopping_cart,
                          size: 14,
                          color: CrmColors.textLight,
                        ),
                        const SizedBox(width: CrmDesignSystem.sm),
                        Text(
                          '$count sales',
                          style: CrmDesignSystem.bodySmall,
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
                    '₹${(amount / 100000).toStringAsFixed(2)}L',
                    style: CrmDesignSystem.titleLarge.copyWith(
                      color: productColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: CrmDesignSystem.xs),
                  Text(
                    'Total value',
                    style: CrmDesignSystem.labelSmall,
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  List<Widget> _buildPerformanceList(NumberFormat currencyFormat) {
    return _employeePerformance.asMap().entries.map((entry) {
      final index = entry.key;
      final employee = entry.value;
      final name = employee['employee']?['firstName'] ?? 'Unknown';
      final salesCount = employee['salesCount'] ?? 0;
      final totalAmount = employee['totalAmount'] ?? 0;

      return Padding(
        padding: const EdgeInsets.only(bottom: CrmDesignSystem.md),
        child: Container(
          padding: const EdgeInsets.all(CrmDesignSystem.lg),
          decoration: CrmDesignSystem.cardDecoration,
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: CrmColors.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '#${index + 1}',
                    style: CrmDesignSystem.labelMedium.copyWith(
                      color: CrmColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: CrmDesignSystem.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: CrmDesignSystem.titleLarge,
                    ),
                    const SizedBox(height: CrmDesignSystem.md),
                    Row(
                      children: [
                        Icon(
                          Icons.trending_up,
                          size: 14,
                          color: CrmColors.textLight,
                        ),
                        const SizedBox(width: CrmDesignSystem.sm),
                        Text(
                          '$salesCount sales',
                          style: CrmDesignSystem.bodySmall,
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
                    style: CrmDesignSystem.titleLarge.copyWith(
                      color: CrmColors.success,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: CrmDesignSystem.xs),
                  Text(
                    'Total sales',
                    style: CrmDesignSystem.labelSmall,
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  Color _getProductColor(String productType) {
    switch (productType) {
      case 'life_insurance':
        return Colors.blue;
      case 'general_insurance':
        return Colors.orange;
      case 'mutual_funds':
        return Colors.green;
      default:
        return CrmColors.primary;
    }
  }

  String _formatProductType(String type) {
    switch (type) {
      case 'life_insurance':
        return 'Life Insurance';
      case 'general_insurance':
        return 'General Insurance';
      case 'mutual_funds':
        return 'Mutual Funds';
      default:
        return type;
    }
  }

  double _getTotalSalesAmount() {
    final data = _salesByProduct['data'] as Map<String, dynamic>?;
    if (data == null) return 0;

    double total = 0;
    data.forEach((key, value) {
      total += (value['totalAmount'] ?? 0).toDouble();
    });
    return total;
  }

  int _getTotalTransactions() {
    final data = _salesByProduct['data'] as Map<String, dynamic>?;
    if (data == null) return 0;

    int total = 0;
    data.forEach((key, value) {
      total += (value['count'] ?? 0) as int;
    });
    return total;
  }
}

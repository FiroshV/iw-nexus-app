import 'package:flutter/material.dart';

/// Widget to help employees understand how their incentive is calculated
class IncentiveCalculationHelper extends StatefulWidget {
  final Map<String, dynamic> incentiveStructure;
  final double? performanceMultiplier;

  const IncentiveCalculationHelper({
    Key? key,
    required this.incentiveStructure,
    this.performanceMultiplier = 1.0,
  }) : super(key: key);

  @override
  State<IncentiveCalculationHelper> createState() =>
      _IncentiveCalculationHelperState();
}

class _IncentiveCalculationHelperState
    extends State<IncentiveCalculationHelper> {
  late TextEditingController _salaryController;
  double _exampleSalary = 300000; // Default example: 3 lakh

  @override
  void initState() {
    super.initState();
    _salaryController = TextEditingController(text: '300000');
  }

  @override
  void dispose() {
    _salaryController.dispose();
    super.dispose();
  }

  double _calculateIncentive(double sales) {
    final structureType = widget.incentiveStructure['structureType'] as String?;

    if (structureType == 'tiered') {
      return _calculateTieredIncentive(sales);
    } else if (structureType == 'flat_percentage') {
      final percentage = widget.incentiveStructure['flatPercentage'] as num? ?? 0;
      return sales * (percentage / 100);
    } else if (structureType == 'fixed') {
      return (widget.incentiveStructure['fixedAmount'] as num? ?? 0).toDouble();
    }

    return 0;
  }

  double _calculateTieredIncentive(double sales) {
    final tiers = widget.incentiveStructure['tiers'] as List? ?? [];
    double totalIncentive = 0;

    for (final tierData in tiers) {
      final tier = tierData as Map<String, dynamic>;
      final minAmount = (tier['minAmount'] as num?)?.toDouble() ?? 0;
      final maxAmount = (tier['maxAmount'] as num?)?.toDouble() ?? 0;
      final percentage = (tier['percentage'] as num?)?.toDouble() ?? 0;

      if (sales >= minAmount && sales <= maxAmount) {
        // Sales fall in this tier
        totalIncentive = sales * (percentage / 100);
        break;
      } else if (sales > maxAmount) {
        // Sales exceed this tier, continue to next
        continue;
      } else {
        // Sales are below this tier and all subsequent tiers
        break;
      }
    }

    return totalIncentive;
  }

  @override
  Widget build(BuildContext context) {
    final baseIncentive = _calculateIncentive(_exampleSalary);
    final multiplier = widget.performanceMultiplier ?? 1.0;
    final finalIncentive = baseIncentive * multiplier;

    return Card(
      elevation: 0,
      color: const Color(0xFFfbf8ff),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0071bf).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.calculate,
                    color: Color(0xFF0071bf),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Incentive Calculator',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Input section
            Text(
              'Try an example',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),

            TextField(
              controller: _salaryController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Enter sales amount (₹)',
                prefixIcon: const Icon(Icons.currency_rupee),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _exampleSalary = double.tryParse(value) ?? 300000;
                });
              },
            ),

            const SizedBox(height: 16),

            // Calculation breakdown
            _buildCalculationBreakdown(context, baseIncentive, finalIncentive),

            const SizedBox(height: 16),

            // Info message
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF00b8d9).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF00b8d9).withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: Color(0xFF00b8d9),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This is an example. Your actual incentive will be based on your verified sales.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF00b8d9),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalculationBreakdown(
    BuildContext context,
    double baseIncentive,
    double finalIncentive,
  ) {
    final multiplier = widget.performanceMultiplier ?? 1.0;
    final structureType =
        widget.incentiveStructure['structureType'] as String? ?? 'unknown';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Base calculation
        _buildCalculationRow(
          context,
          label: 'Sales Amount',
          value: _formatCurrency(_exampleSalary),
          valueColor: Colors.grey[700],
        ),

        const SizedBox(height: 8),

        if (structureType == 'tiered')
          _buildTieredBreakdown(context)
        else if (structureType == 'flat_percentage')
          _buildFlatPercentageBreakdown(context)
        else if (structureType == 'fixed')
          _buildFixedAmountBreakdown(context),

        const SizedBox(height: 8),

        Divider(color: Colors.grey[300]),

        const SizedBox(height: 8),

        _buildCalculationRow(
          context,
          label: 'Base Incentive',
          value: _formatCurrency(baseIncentive),
          isBold: true,
        ),

        if (multiplier != 1.0) ...[
          const SizedBox(height: 8),
          _buildCalculationRow(
            context,
            label: 'Performance Bonus',
            value: '${(multiplier * 100).toStringAsFixed(0)}%',
            valueColor: const Color(0xFF5cfbd8),
            showMultiplication: true,
            multiplicand: _formatCurrency(baseIncentive),
          ),
          const SizedBox(height: 8),
          Divider(color: Colors.grey[300]),
          const SizedBox(height: 8),
          _buildCalculationRow(
            context,
            label: 'Final Incentive',
            value: _formatCurrency(finalIncentive),
            isBold: true,
            isHighlight: true,
          ),
        ],
      ],
    );
  }

  Widget _buildTieredBreakdown(BuildContext context) {
    final tiers = widget.incentiveStructure['tiers'] as List? ?? [];
    final matchingTier = _findMatchingTier(_exampleSalary, tiers);

    if (matchingTier == null) {
      return Text(
        'Sales amount does not match any tier',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Colors.grey[600],
        ),
      );
    }

    final percentage = (matchingTier['percentage'] as num?)?.toDouble() ?? 0;
    final tierName = matchingTier['name'] as String? ?? 'Applicable Tier';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tierName,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 8),
        _buildCalculationRow(
          context,
          label: '${percentage.toStringAsFixed(1)}% of sales',
          value:
              '${_formatCurrency(_exampleSalary)} × ${percentage.toStringAsFixed(1)}%',
          valueColor: const Color(0xFF0071bf),
        ),
      ],
    );
  }

  Widget _buildFlatPercentageBreakdown(BuildContext context) {
    final percentage = widget.incentiveStructure['flatPercentage'] as num? ?? 0;

    return _buildCalculationRow(
      context,
      label: '${percentage}% of sales',
      value:
          '${_formatCurrency(_exampleSalary)} × ${percentage.toStringAsFixed(1)}%',
      valueColor: const Color(0xFF0071bf),
    );
  }

  Widget _buildFixedAmountBreakdown(BuildContext context) {
    final amount = widget.incentiveStructure['fixedAmount'] as num? ?? 0;

    return _buildCalculationRow(
      context,
      label: 'Fixed Incentive',
      value: _formatCurrency(amount.toDouble()),
      valueColor: const Color(0xFF0071bf),
    );
  }

  Widget _buildCalculationRow(
    BuildContext context, {
    required String label,
    required String value,
    Color? valueColor,
    bool isBold = false,
    bool isHighlight = false,
    bool showMultiplication = false,
    String? multiplicand,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: isHighlight ? const Color(0xFF5cfbd8).withValues(alpha: 0.1) : null,
            border: isHighlight
                ? Border.all(color: const Color(0xFF5cfbd8).withValues(alpha: 0.3))
                : null,
            borderRadius: isHighlight ? BorderRadius.circular(8) : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
                    color: valueColor ?? (isBold ? Colors.black : null),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Map<String, dynamic>? _findMatchingTier(
    double sales,
    List<dynamic> tiers,
  ) {
    for (final tierData in tiers) {
      final tier = tierData as Map<String, dynamic>;
      final minAmount = (tier['minAmount'] as num?)?.toDouble() ?? 0;
      final maxAmount = (tier['maxAmount'] as num?)?.toDouble() ?? 0;

      if (sales >= minAmount && sales <= maxAmount) {
        return tier;
      }
    }
    return null;
  }

  String _formatCurrency(double amount) {
    if (amount >= 10000000) {
      return '₹${(amount / 10000000).toStringAsFixed(2)}Cr';
    } else if (amount >= 100000) {
      return '₹${(amount / 100000).toStringAsFixed(2)}L';
    } else if (amount >= 1000) {
      return '₹${(amount / 1000).toStringAsFixed(2)}K';
    }
    return '₹${amount.toStringAsFixed(0)}';
  }
}

import 'package:flutter/material.dart';

/// Widget to visualize incentive tier structures
class IncentiveTierVisualizer extends StatelessWidget {
  final List<Map<String, dynamic>> tiers;
  final double? totalWidth;
  final double? barHeight;

  const IncentiveTierVisualizer({
    Key? key,
    required this.tiers,
    this.totalWidth,
    this.barHeight = 60,
  }) : super(key: key);

  /// Format currency in Indian format
  static String formatCurrency(num amount) {
    if (amount >= 10000000) {
      return '₹${(amount / 10000000).toStringAsFixed(1)}Cr';
    } else if (amount >= 100000) {
      return '₹${(amount / 100000).toStringAsFixed(1)}L';
    } else if (amount >= 1000) {
      return '₹${(amount / 1000).toStringAsFixed(1)}K';
    }
    return '₹${amount.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    if (tiers.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'No tier information available',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ),
      );
    }

    final screenWidth = totalWidth ?? MediaQuery.of(context).size.width - 32;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: screenWidth,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              ...tiers.asMap().entries.map((entry) {
                final index = entry.key;
                final tier = entry.value;

                return _buildTierRow(
                  context,
                  tier,
                  index,
                );
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTierRow(
    BuildContext context,
    Map<String, dynamic> tier,
    int index,
  ) {
    final tierName = tier['name'] as String? ?? 'Tier ${index + 1}';
    final minAmount = (tier['minAmount'] as num?)?.toInt() ?? 0;
    final maxAmount = (tier['maxAmount'] as num?)?.toInt() ?? 0;
    final percentage = (tier['percentage'] as num?)?.toDouble() ?? 0;

    final colors = [
      const Color(0xFF272579), // Brand primary
      const Color(0xFF0071bf), // Primary blue
      const Color(0xFF00b8d9), // Secondary blue
      const Color(0xFF5cfbd8), // Success green
    ];

    final color = colors[index % colors.length];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tier header with name and percentage
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tierName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                    SizedBox(
                      width: 200,
                      child: Text(
                        '${formatCurrency(minAmount)} - ${formatCurrency(maxAmount)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withValues(alpha: 0.3)),
                ),
                child: Text(
                  '$percentage%',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          // Visual bar
          const SizedBox(height: 8),
          Container(
            height: barHeight ?? 40,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: color.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: CustomPaint(
                painter: _TierBarPainter(
                  color: color,
                  percentage: percentage,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for tier bar visualization
class _TierBarPainter extends CustomPainter {
  final Color color;
  final double percentage;

  _TierBarPainter({
    required this.color,
    required this.percentage,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = color.withValues(alpha: 0.05),
    );

    // Filled portion based on percentage
    final filledWidth = (size.width * (percentage / 100)).clamp(0, size.width) as double;

    // Gradient fill
    final gradient = LinearGradient(
      colors: [
        color.withValues(alpha: 0.8),
        color.withValues(alpha: 0.4),
      ],
    ).createShader(
      Rect.fromLTWH(0, 0, filledWidth, size.height),
    );

    canvas.drawRect(
      Rect.fromLTWH(0, 0, filledWidth, size.height),
      Paint()..shader = gradient,
    );

    // Percentage text
    final textPainter = TextPainter(
      text: TextSpan(
        text: '$percentage%',
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout(minWidth: 0, maxWidth: size.width);

    final xCenter = (size.width - textPainter.width) / 2;
    final yCenter = (size.height - textPainter.height) / 2;

    textPainter.paint(canvas, Offset(xCenter, yCenter));
  }

  @override
  bool shouldRepaint(_TierBarPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.percentage != percentage;
  }
}

/// Widget to display tier information in table format
class IncentiveTierTable extends StatelessWidget {
  final List<Map<String, dynamic>> tiers;

  const IncentiveTierTable({
    Key? key,
    required this.tiers,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (tiers.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'No tier information available',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Tier')),
          DataColumn(label: Text('Min Amount'), numeric: true),
          DataColumn(label: Text('Max Amount'), numeric: true),
          DataColumn(label: Text('Percentage'), numeric: true),
        ],
        rows: tiers
            .asMap()
            .entries
            .map(
              (entry) => DataRow(
                cells: [
                  DataCell(Text(entry.value['name'] ?? 'Tier ${entry.key + 1}')),
                  DataCell(
                    Text(
                      IncentiveTierVisualizer.formatCurrency(
                        entry.value['minAmount'] ?? 0,
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      IncentiveTierVisualizer.formatCurrency(
                        entry.value['maxAmount'] ?? 0,
                      ),
                    ),
                  ),
                  DataCell(
                    Text('${entry.value['percentage'] ?? 0}%'),
                  ),
                ],
              ),
            )
            .toList(),
      ),
    );
  }
}

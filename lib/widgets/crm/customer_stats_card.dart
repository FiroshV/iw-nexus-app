import 'package:flutter/material.dart';

class CustomerStatsCard extends StatelessWidget {
  final int totalVisits;
  final int totalSales;
  final int totalAppointments;
  final double conversionRate; // percentage (0-100)
  final double averageOrderValue; // for sales
  final int pendingFollowUps;

  const CustomerStatsCard({
    super.key,
    required this.totalVisits,
    required this.totalSales,
    required this.totalAppointments,
    this.conversionRate = 0,
    this.averageOrderValue = 0,
    this.pendingFollowUps = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF00b8d9).withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Customer Statistics',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF272579),
                ),
          ),
          const SizedBox(height: 16),
          // Stats grid - 2x2
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            children: [
              _buildStatBox(
                label: 'Total Visits',
                value: totalVisits.toString(),
                icon: Icons.location_on_outlined,
                color: const Color(0xFF5cfbd8),
              ),
              _buildStatBox(
                label: 'Total Sales',
                value: totalSales.toString(),
                icon: Icons.trending_up,
                color: const Color(0xFFffc107),
              ),
              _buildStatBox(
                label: 'Appointments',
                value: totalAppointments.toString(),
                icon: Icons.event_note,
                color: const Color(0xFF0071bf),
              ),
              _buildStatBox(
                label: 'Pending',
                value: pendingFollowUps.toString(),
                icon: Icons.schedule,
                color: Colors.orange,
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Key insights
          if (pendingFollowUps > 0 || totalSales > 0)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF5cfbd8).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF5cfbd8).withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Key Insights',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF272579),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (pendingFollowUps > 0)
                    Text(
                      '! $pendingFollowUps pending follow-up${pendingFollowUps > 1 ? "s" : ""} - prioritize these',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.orange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  if (totalSales > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '✓ $totalSales successful sale${totalSales > 1 ? "s" : ""} recorded',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatBox({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
              overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

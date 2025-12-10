import 'package:flutter/material.dart';
import '../../models/customer.dart';

class CustomerCard extends StatelessWidget {
  final Customer customer;
  final int? appointmentCount;
  final int? visitCount;
  final int? saleCount;
  final VoidCallback onTap;
  final List<Widget>? actions;

  const CustomerCard({
    super.key,
    required this.customer,
    this.appointmentCount,
    this.visitCount,
    this.saleCount,
    required this.onTap,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF00b8d9).withValues(alpha: 0.2),
            width: 1,
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
            // Header with customer name and actions
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customer.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF272579),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          customer.mobileNumber,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (actions != null && actions!.isNotEmpty)
                    PopupMenuButton(
                      itemBuilder: (context) => actions!
                          .asMap()
                          .entries
                          .map(
                            (entry) => PopupMenuItem(
                              child: entry.value,
                            ),
                          )
                          .toList(),
                      icon: const Icon(Icons.more_vert, size: 16),
                    ),
                ],
              ),
            ),
            Divider(height: 1, color: Colors.grey[200]),
            // Stats row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    label: 'Appointments',
                    value: (appointmentCount ?? 0).toString(),
                    icon: Icons.event_note,
                  ),
                  _buildStatItem(
                    label: 'Visits',
                    value: (visitCount ?? 0).toString(),
                    icon: Icons.location_on_outlined,
                  ),
                  _buildStatItem(
                    label: 'Sales',
                    value: (saleCount ?? 0).toString(),
                    icon: Icons.trending_up,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          size: 16,
          color: const Color(0xFF0071bf),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFF272579),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[500],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

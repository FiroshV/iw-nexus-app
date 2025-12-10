import 'package:flutter/material.dart';
import '../../models/customer.dart';

class CustomerCard extends StatelessWidget {
  final Customer customer;
  final VoidCallback onTap;
  final List<Widget>? actions;

  const CustomerCard({
    super.key,
    required this.customer,
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
          ],
        ),
      ),
    );
  }
}

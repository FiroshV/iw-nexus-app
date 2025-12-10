import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/crm_colors.dart';
import '../../models/sale.dart';

class SaleCard extends StatelessWidget {
  final Sale sale;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;

  const SaleCard({
    super.key,
    required this.sale,
    required this.onTap,
    this.onDelete,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final productColor = CrmColors.getProductTypeColor(sale.productType);
    final productName = CrmColors.getProductTypeName(sale.productType);
    final dateFormatter = DateFormat('dd MMM yyyy');
    final amountFormatter = NumberFormat('#,##0.00', 'en_US');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, CrmColors.surface],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Section: Customer info + Product Type Tag
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              sale.customerName,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: CrmColors.textDark,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              sale.mobileNumber,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: CrmColors.textLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Product type tag
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: productColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: productColor.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          productName,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: productColor,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Divider
                  Container(
                    height: 1,
                    color: CrmColors.borderColor,
                  ),
                  const SizedBox(height: 16),

                  // Middle Section: Product details
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow(
                        context,
                        'Company',
                        sale.companyName,
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        context,
                        sale.productType == 'mutual_funds' ? 'Scheme' : 'Product',
                        sale.productPlanName,
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        context,
                        sale.amountLabel,
                        '₹${amountFormatter.format(sale.displayAmount)}',
                        valueColor: CrmColors.primary,
                      ),
                      if (sale.paymentFrequency != null) ...[
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          context,
                          'Frequency',
                          _formatFrequency(sale.paymentFrequency!),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Divider
                  Container(
                    height: 1,
                    color: CrmColors.borderColor,
                  ),
                  const SizedBox(height: 16),

                  // Bottom Section: Date and visit status
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Date of Sale',
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: CrmColors.textLight,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              dateFormatter.format(sale.dateOfSale),
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: CrmColors.textDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Visit status badge if available
                      if (sale.visitStatus != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: CrmColors.success.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: CrmColors.success.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            'Visited',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: CrmColors.success,
                                  fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),

                  // Action buttons (if needed, can show on tap)
                  if (onEdit != null || onDelete != null) ...[
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (onEdit != null)
                          Expanded(
                            child: TextButton.icon(
                              onPressed: onEdit,
                              icon: const Icon(Icons.edit, size: 18),
                              label: const Text('Edit'),
                              style: TextButton.styleFrom(
                                foregroundColor: CrmColors.primary,
                                padding: const EdgeInsets.symmetric(vertical: 8),
                              ),
                            ),
                          ),
                        if (onEdit != null && onDelete != null) const SizedBox(width: 4),
                        if (onDelete != null)
                          Expanded(
                            child: TextButton.icon(
                              onPressed: () {
                                _showDeleteConfirmation(context, onDelete!);
                              },
                              icon: const Icon(Icons.delete, size: 18),
                              label: const Text('Delete'),
                              style: TextButton.styleFrom(
                                foregroundColor: CrmColors.errorColor,
                                padding: const EdgeInsets.symmetric(vertical: 8),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: CrmColors.textLight,
                fontWeight: FontWeight.w500,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: valueColor ?? CrmColors.textDark,
                fontWeight: FontWeight.w600,
              ),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  String _formatFrequency(String frequency) {
    switch (frequency) {
      case 'daily':
        return 'Daily';
      case 'monthly':
        return 'Monthly';
      case 'quarterly':
        return 'Quarterly';
      case 'half_yearly':
        return 'Half-Yearly';
      case 'yearly':
        return 'Yearly';
      case 'single':
        return 'Single';
      default:
        return frequency;
    }
  }

  void _showDeleteConfirmation(BuildContext context, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Sale?'),
          content: Text('Are you sure you want to delete the sale for ${sale.customerName}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onConfirm();
              },
              style: TextButton.styleFrom(
                foregroundColor: CrmColors.errorColor,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}

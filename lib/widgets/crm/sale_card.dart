import 'package:flutter/material.dart';
import '../../config/crm_colors.dart';
import '../../models/sale.dart';

class SaleCard extends StatefulWidget {
  final Sale sale;
  final VoidCallback? onTap;

  const SaleCard({
    super.key,
    required this.sale,
    this.onTap,
  });

  @override
  State<SaleCard> createState() => _SaleCardState();
}

class _SaleCardState extends State<SaleCard> {
  @override
  Widget build(BuildContext context) {
    final productColor = CrmColors.getProductTypeColor(widget.sale.productType);
    final productName = CrmColors.getProductTypeName(widget.sale.productType);

    return Container(
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
            onTap: widget.onTap,
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
                              widget.sale.customerName,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: CrmColors.textDark,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.sale.mobileNumber,
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
                ],
              ),
            ),
          ),
        ),
      );
  }
}

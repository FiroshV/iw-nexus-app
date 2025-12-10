import 'package:flutter/material.dart';
import '../../config/crm_colors.dart';

class ProductTypeSelector extends StatefulWidget {
  final String? selectedType;
  final ValueChanged<String> onChanged;

  const ProductTypeSelector({
    super.key,
    this.selectedType,
    required this.onChanged,
  });

  @override
  State<ProductTypeSelector> createState() => _ProductTypeSelectorState();
}

class _ProductTypeSelectorState extends State<ProductTypeSelector> {
  late String? _selectedType;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.selectedType;
  }

  @override
  void didUpdateWidget(ProductTypeSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedType != oldWidget.selectedType) {
      _selectedType = widget.selectedType;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Product Type *',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: CrmColors.textDark,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildProductTypeButton(
                context,
                'Life Insurance',
                'life_insurance',
                Icons.favorite,
                CrmColors.lifeInsuranceColor,
              ),
              const SizedBox(width: 12),
              _buildProductTypeButton(
                context,
                'General Insurance',
                'general_insurance',
                Icons.shield,
                CrmColors.generalInsuranceColor,
              ),
              const SizedBox(width: 12),
              _buildProductTypeButton(
                context,
                'Mutual Funds',
                'mutual_funds',
                Icons.trending_up,
                CrmColors.mutualFundsColor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProductTypeButton(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    final isSelected = _selectedType == value;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedType = value;
          });
          widget.onChanged(value);
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: isSelected ? color.withValues(alpha: 0.15) : CrmColors.surface,
            border: Border.all(
              color: isSelected ? color : CrmColors.borderColor,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? color : CrmColors.textLight,
                size: 28,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: isSelected ? color : CrmColors.textDark,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

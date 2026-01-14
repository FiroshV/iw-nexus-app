import 'package:flutter/material.dart';
import '../constants/document_categories.dart';

/// Bottom sheet widget for selecting document category during upload
class DocumentCategoryBottomSheet extends StatelessWidget {
  /// Set of categories that have already been uploaded
  final Set<String> uploadedCategories;

  /// Callback when a category is selected
  final ValueChanged<String> onCategorySelected;

  const DocumentCategoryBottomSheet({
    super.key,
    required this.uploadedCategories,
    required this.onCategorySelected,
  });

  /// Shows the bottom sheet and returns the selected category
  static Future<String?> show({
    required BuildContext context,
    required Set<String> uploadedCategories,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DocumentCategoryBottomSheet(
        uploadedCategories: uploadedCategories,
        onCategorySelected: (category) {
          Navigator.of(context).pop(category);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Title
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF272579).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.folder_outlined,
                    color: Color(0xFF272579),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select Document Type',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Choose the category for your document',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Category list
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: DocumentCategories.allCategories.length,
              itemBuilder: (context, index) {
                final category = DocumentCategories.allCategories[index];
                return _buildCategoryItem(context, category);
              },
            ),
          ),
          // Safe area padding at bottom
          SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
        ],
      ),
    );
  }

  Widget _buildCategoryItem(BuildContext context, String category) {
    final isUploaded = uploadedCategories.contains(category);
    final isMandatory = DocumentCategories.isMandatory(category);
    final label = DocumentCategories.getLabel(category);
    final description = DocumentCategories.getDescription(category);

    // "Other" category can always be selected for additional uploads
    final isOther = category == DocumentCategories.other;
    final canSelect = isOther || !isUploaded;

    return InkWell(
      onTap: canSelect
          ? () => onCategorySelected(category)
          : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Status icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isUploaded
                    ? const Color(0xFF10B981).withValues(alpha: 0.1)
                    : isMandatory
                        ? const Color(0xFF272579).withValues(alpha: 0.1)
                        : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isUploaded
                    ? Icons.check_circle
                    : _getCategoryIcon(category),
                color: isUploaded
                    ? const Color(0xFF10B981)
                    : isMandatory
                        ? const Color(0xFF272579)
                        : Colors.grey[600],
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            // Category info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: canSelect
                                ? const Color(0xFF1E293B)
                                : Colors.grey[500],
                          ),
                        ),
                      ),
                      if (isMandatory && !isOther)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isUploaded
                                ? const Color(0xFF10B981).withValues(alpha: 0.1)
                                : const Color(0xFFEF4444).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            isUploaded ? 'Uploaded' : 'Required',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isUploaded
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFEF4444),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: canSelect ? Colors.grey[600] : Colors.grey[400],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Arrow indicator for selectable items
            if (canSelect)
              Icon(
                Icons.chevron_right,
                color: Colors.grey[400],
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case DocumentCategories.educationalCertificate:
        return Icons.school_outlined;
      case DocumentCategories.experienceCertificate:
        return Icons.work_outline;
      case DocumentCategories.salarySlips:
        return Icons.receipt_long_outlined;
      case DocumentCategories.identityProof:
        return Icons.badge_outlined;
      case DocumentCategories.addressProof:
        return Icons.home_outlined;
      case DocumentCategories.bankStatement:
        return Icons.account_balance_outlined;
      case DocumentCategories.panCard:
        return Icons.credit_card_outlined;
      case DocumentCategories.other:
        return Icons.description_outlined;
      default:
        return Icons.folder_outlined;
    }
  }
}

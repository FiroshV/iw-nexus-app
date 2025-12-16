import 'package:flutter/material.dart';
import '../../config/crm_colors.dart';
import '../../config/crm_design_system.dart';

class PipelineStageCard extends StatelessWidget {
  final String stageName;
  final int count;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;
  final String? subtitle;

  const PipelineStageCard({
    super.key,
    required this.stageName,
    required this.count,
    required this.color,
    required this.icon,
    required this.onTap,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(CrmDesignSystem.radiusLarge),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(CrmDesignSystem.radiusLarge),
            child: Padding(
              padding: const EdgeInsets.all(CrmDesignSystem.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(CrmDesignSystem.radiusMedium),
                        ),
                        child: Icon(
                          icon,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        color: CrmColors.textLight,
                        size: 16,
                      ),
                    ],
                  ),
                  const SizedBox(height: CrmDesignSystem.sm),
                  Text(
                    stageName,
                    style: CrmDesignSystem.bodyMedium.copyWith(
                      color: CrmColors.textDark,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: CrmDesignSystem.xs),
                  Text(
                    '$count',
                    style: CrmDesignSystem.headlineSmall.copyWith(
                      color: color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: CrmDesignSystem.xs),
                    Text(
                      subtitle!,
                      style: CrmDesignSystem.bodySmall.copyWith(
                        color: CrmColors.textLight,
                      ),
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
}

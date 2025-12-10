import 'package:flutter/material.dart';
import 'crm_colors.dart';

/// Comprehensive CRM Design System
/// Provides consistent styling, spacing, typography, and animations
class CrmDesignSystem {
  // ============================================================================
  // SPACING SYSTEM (8px base unit)
  // ============================================================================
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double huge = 40;

  // ============================================================================
  // BORDER RADIUS
  // ============================================================================
  static const double radiusSmall = 4;
  static const double radiusMedium = 8;
  static const double radiusLarge = 12;
  static const double radiusXL = 16;
  static const double radiusMax = 20;

  // ============================================================================
  // ELEVATION & SHADOWS
  // ============================================================================
  static BoxShadow shadowSmall = BoxShadow(
    color: Colors.black.withValues(alpha: 0.04),
    blurRadius: 2,
    offset: const Offset(0, 1),
  );

  static BoxShadow shadowMedium = BoxShadow(
    color: Colors.black.withValues(alpha: 0.08),
    blurRadius: 8,
    offset: const Offset(0, 2),
  );

  static BoxShadow shadowLarge = BoxShadow(
    color: Colors.black.withValues(alpha: 0.12),
    blurRadius: 16,
    offset: const Offset(0, 4),
  );

  static List<BoxShadow> elevationSmall = [shadowSmall];
  static List<BoxShadow> elevationMedium = [shadowMedium];
  static List<BoxShadow> elevationLarge = [shadowLarge];

  // ============================================================================
  // ANIMATION DURATIONS
  // ============================================================================
  static const Duration durationFast = Duration(milliseconds: 200);
  static const Duration durationNormal = Duration(milliseconds: 300);
  static const Duration durationSlow = Duration(milliseconds: 500);

  // ============================================================================
  // TEXT THEMES
  // ============================================================================
  static TextStyle get headlineLarge => TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.2,
    color: CrmColors.textDark,
  );

  static TextStyle get headlineMedium => TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.3,
    color: CrmColors.textDark,
  );

  static TextStyle get headlineSmall => TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    height: 1.3,
    color: CrmColors.textDark,
  );

  static TextStyle get titleLarge => TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.4,
    color: CrmColors.textDark,
  );

  static TextStyle get titleMedium => TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.4,
    color: CrmColors.textDark,
  );

  static TextStyle get titleSmall => TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 1.4,
    color: CrmColors.textDark,
  );

  static TextStyle get bodyLarge => TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: CrmColors.textDark,
  );

  static TextStyle get bodyMedium => TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: CrmColors.textDark,
  );

  static TextStyle get bodySmall => TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: CrmColors.textLight,
  );

  static TextStyle get labelLarge => TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.3,
    color: CrmColors.textDark,
  );

  static TextStyle get labelMedium => TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.3,
    color: CrmColors.textDark,
  );

  static TextStyle get labelSmall => TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    height: 1.3,
    color: CrmColors.textLight,
  );

  static TextStyle get captionSmall => TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w400,
    height: 1.3,
    color: CrmColors.textLight,
  );

  // ============================================================================
  // CARD STYLES
  // ============================================================================
  static BoxDecoration get cardDecoration => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(radiusLarge),
    boxShadow: elevationSmall,
    border: Border.all(
      color: CrmColors.borderColor,
      width: 0.5,
    ),
  );

  static BoxDecoration cardDecorationWithBorder(Color borderColor) => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(radiusLarge),
    boxShadow: elevationSmall,
    border: Border.all(
      color: borderColor,
      width: 1.5,
    ),
  );

  static BoxDecoration get highlightedCardDecoration => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(radiusLarge),
    boxShadow: elevationMedium,
    border: Border.all(
      color: CrmColors.primary.withValues(alpha: 0.2),
      width: 1.5,
    ),
  );

  // ============================================================================
  // BUTTON STYLES
  // ============================================================================
  static ButtonStyle get primaryButtonStyle => ElevatedButton.styleFrom(
    backgroundColor: CrmColors.primary,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(
      horizontal: lg,
      vertical: md,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radiusLarge),
    ),
    elevation: 2,
    shadowColor: CrmColors.primary.withValues(alpha: 0.3),
  );

  static ButtonStyle get secondaryButtonStyle => ElevatedButton.styleFrom(
    backgroundColor: CrmColors.secondary.withValues(alpha: 0.1),
    foregroundColor: CrmColors.secondary,
    padding: const EdgeInsets.symmetric(
      horizontal: lg,
      vertical: md,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radiusLarge),
    ),
    elevation: 0,
  );

  static ButtonStyle get successButtonStyle => ElevatedButton.styleFrom(
    backgroundColor: CrmColors.success,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(
      horizontal: lg,
      vertical: md,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radiusLarge),
    ),
    elevation: 2,
    shadowColor: CrmColors.success.withValues(alpha: 0.3),
  );

  static ButtonStyle get outlinedButtonStyle => OutlinedButton.styleFrom(
    foregroundColor: CrmColors.primary,
    side: const BorderSide(
      color: CrmColors.primary,
      width: 1.5,
    ),
    padding: const EdgeInsets.symmetric(
      horizontal: lg,
      vertical: md,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radiusLarge),
    ),
  );

  // ============================================================================
  // INPUT FIELD STYLES
  // ============================================================================
  static InputDecoration inputDecoration({
    String? hintText,
    String? labelText,
    IconData? prefixIcon,
    IconData? suffixIcon,
    Color borderColor = const Color(0xFFECF0F1),
    Color focusedBorderColor = CrmColors.primary,
  }) => InputDecoration(
    hintText: hintText,
    labelText: labelText,
    prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 20) : null,
    suffixIcon: suffixIcon != null ? Icon(suffixIcon, size: 20) : null,
    filled: true,
    fillColor: CrmColors.surface,
    contentPadding: const EdgeInsets.symmetric(
      horizontal: lg,
      vertical: md,
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(radiusLarge),
      borderSide: BorderSide(
        color: borderColor,
        width: 1,
      ),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(radiusLarge),
      borderSide: BorderSide(
        color: borderColor,
        width: 1,
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(radiusLarge),
      borderSide: BorderSide(
        color: focusedBorderColor,
        width: 1.5,
      ),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(radiusLarge),
      borderSide: const BorderSide(
        color: Color(0xFFE74C3C),
        width: 1,
      ),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(radiusLarge),
      borderSide: const BorderSide(
        color: Color(0xFFE74C3C),
        width: 1.5,
      ),
    ),
    hintStyle: bodyMedium.copyWith(color: CrmColors.textLight),
    labelStyle: labelMedium.copyWith(color: CrmColors.textLight),
  );

  // ============================================================================
  // BADGE STYLES
  // ============================================================================
  static BoxDecoration badgeDecoration({
    required Color color,
    Color? borderColor,
  }) => BoxDecoration(
    color: color.withValues(alpha: 0.15),
    border: Border.all(
      color: borderColor ?? color.withValues(alpha: 0.3),
      width: 1,
    ),
    borderRadius: BorderRadius.circular(radiusSmall),
  );

  // ============================================================================
  // METRIC CARD STYLES
  // ============================================================================
  static BoxDecoration metricCardDecoration({required Color color}) => BoxDecoration(
    color: color.withValues(alpha: 0.08),
    border: Border.all(
      color: color.withValues(alpha: 0.3),
      width: 1,
    ),
    borderRadius: BorderRadius.circular(radiusLarge),
  );

  // ============================================================================
  // HELPER METHODS FOR COMMON UI PATTERNS
  // ============================================================================

  /// Create a gradient background for cards
  static LinearGradient gradientBackground({
    required Color startColor,
    Color? endColor,
  }) => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      startColor.withValues(alpha: 0.05),
      (endColor ?? startColor).withValues(alpha: 0.02),
    ],
  );

  /// Create a status indicator circle
  static BoxDecoration statusIndicator({required Color color}) => BoxDecoration(
    color: color,
    shape: BoxShape.circle,
    boxShadow: [
      BoxShadow(
        color: color.withValues(alpha: 0.3),
        blurRadius: 8,
        spreadRadius: 2,
      ),
    ],
  );

  /// Create a glass morphism effect (subtle blur background)
  static BoxDecoration glassEffect({
    required Color backgroundColor,
    double opacity = 0.8,
  }) => BoxDecoration(
    color: backgroundColor.withValues(alpha: opacity),
    borderRadius: BorderRadius.circular(radiusLarge),
    border: Border.all(
      color: Colors.white.withValues(alpha: 0.2),
      width: 1,
    ),
    boxShadow: elevationMedium,
  );
}

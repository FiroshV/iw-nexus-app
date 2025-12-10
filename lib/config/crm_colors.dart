import 'package:flutter/material.dart';

class CrmColors {
  // Brand and primary colors
  static const Color brand = Color(0xFF272579);
  static const Color primary = Color(0xFF0071bf);
  static const Color secondary = Color(0xFF00b8d9);
  static const Color success = Color(0xFF5cfbd8);
  static const Color surface = Color(0xFFfbf8ff);

  // Product type colors
  static const Color lifeInsuranceColor = Color(0xFF0071bf);
  static const Color generalInsuranceColor = Color(0xFF00b8d9);
  static const Color mutualFundsColor = Color(0xFF5cfbd8);

  // Outcome colors
  static const Color saleClosed = Color(0xFF5cfbd8); // Success green
  static const Color interestedFollowup = Color(0xFF00b8d9); // Info blue
  static const Color notInterested = Color(0xFFFF6B6B); // Error red
  static const Color pendingDocuments = Color(0xFFFFA500); // Warning orange
  static const Color reschedule = Color(0xFF9B59B6); // Purple

  // Get color for product type
  static Color getProductTypeColor(String productType) {
    switch (productType) {
      case 'life_insurance':
        return lifeInsuranceColor;
      case 'general_insurance':
        return generalInsuranceColor;
      case 'mutual_funds':
        return mutualFundsColor;
      default:
        return primary;
    }
  }

  // Get display name for product type
  static String getProductTypeName(String productType) {
    switch (productType) {
      case 'life_insurance':
        return 'Life Insurance';
      case 'general_insurance':
        return 'General Insurance';
      case 'mutual_funds':
        return 'Mutual Funds';
      default:
        return productType;
    }
  }

  // Get color for outcome
  static Color getOutcomeColor(String outcome) {
    switch (outcome) {
      case 'sale_closed':
        return saleClosed;
      case 'interested_followup_needed':
        return interestedFollowup;
      case 'not_interested':
        return notInterested;
      case 'pending_documents':
        return pendingDocuments;
      case 'reschedule':
        return reschedule;
      default:
        return primary;
    }
  }

  // Get icon name for purpose
  static IconData getPurposeIcon(String purpose) {
    switch (purpose) {
      case 'new_sale_discussion':
        return Icons.handshake;
      case 'document_collection':
        return Icons.description;
      case 'policy_renewal':
        return Icons.refresh;
      case 'kyc_verification':
        return Icons.verified_user;
      case 'claim_assistance':
        return Icons.help;
      case 'follow_up_conversation':
        return Icons.phone;
      case 'other':
        return Icons.more_horiz;
      default:
        return Icons.info;
    }
  }

  // Neutral colors
  static const Color textDark = Color(0xFF2C3E50);
  static const Color textLight = Color(0xFF7F8C8D);
  static const Color borderColor = Color(0xFFECF0F1);
  static const Color errorColor = Color(0xFFE74C3C);
  static const Color warningColor = Color(0xFFF39C12);
  static const Color successColor = Color(0xFF27AE60);
}

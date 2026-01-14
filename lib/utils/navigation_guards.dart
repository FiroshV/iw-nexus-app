import 'package:flutter/material.dart';
import '../services/profile_service.dart';
import '../screens/profile_screen.dart';
import '../constants/document_categories.dart';

/// Centralized navigation guards for gating access to features
class NavigationGuards {
  /// Attempts to navigate to a protected screen.
  /// Returns true if navigation succeeded, false if blocked.
  ///
  /// For non-exempt roles with incomplete profiles or missing documents,
  /// shows a dialog prompting them to complete their profile first.
  static Future<bool> navigateWithProfileCheck({
    required BuildContext context,
    required Map<String, dynamic>? userData,
    required Widget destination,
    String featureName = 'this feature',
  }) async {
    // Check if role is exempt first (quick sync check)
    final role = userData?['role'] as String?;
    if (ProfileService.isRoleExempt(role)) {
      // Exempt role - allow navigation immediately
      if (context.mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => destination),
        );
      }
      return true;
    }

    // For non-exempt roles, check profile and documents
    final profileComplete = ProfileService.isProfileComplete(userData);
    final documentsComplete = await ProfileService.areDocumentsComplete();

    if (profileComplete && documentsComplete) {
      // Everything complete - allow navigation
      if (context.mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => destination),
        );
      }
      return true;
    } else {
      // Something incomplete - show dialog
      if (context.mounted) {
        await _showCompletionRequiredDialog(
          context,
          featureName,
          profileComplete,
          documentsComplete,
        );
      }
      return false;
    }
  }

  static Future<void> _showCompletionRequiredDialog(
    BuildContext context,
    String featureName,
    bool profileComplete,
    bool documentsComplete,
  ) async {
    // Determine what's missing for the message
    String message;
    String title;
    IconData icon;

    if (!profileComplete && !documentsComplete) {
      title = 'Complete Your Profile';
      icon = Icons.person_outline;
      message =
          'Please complete your profile and upload all required documents to access $featureName.';
    } else if (!profileComplete) {
      title = 'Profile Incomplete';
      icon = Icons.person_outline;
      message =
          'Please complete your personal details and profile photo to access $featureName.';
    } else {
      title = 'Documents Required';
      icon = Icons.folder_outlined;
      // Get missing categories for more specific message
      final details = await ProfileService.getDocumentCompletionDetails();
      final missingCategories = details['missingCategories'] as List? ?? [];
      final missingCount = missingCategories.length;

      if (missingCount > 0 && missingCount <= 3) {
        final missingLabels = missingCategories
            .map((cat) => DocumentCategories.getLabel(cat.toString()))
            .join(', ');
        message = 'Please upload the following documents to access $featureName: $missingLabels.';
      } else {
        message =
            'Please upload all required documents ($missingCount remaining) to access $featureName.';
      }
    }

    if (!context.mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          icon: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFF272579).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 30,
              color: const Color(0xFF272579),
            ),
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(0xFF272579),
              fontSize: 20,
            ),
            textAlign: TextAlign.center,
          ),
          content: Text(
            message,
            style: const TextStyle(
              fontSize: 16,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text(
                'Later',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                // Navigate to profile screen with Documents tab pre-selected if only documents are missing
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => ProfileScreen(
                      showCompletionDialog: false,
                      initialTab: profileComplete ? 1 : 0, // Go to Documents tab if profile is complete
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF272579),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                profileComplete ? 'Upload Documents' : 'Complete Profile',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }
}

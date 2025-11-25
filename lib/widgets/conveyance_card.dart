import 'dart:async';
import 'package:flutter/material.dart';
import '../services/access_control_service.dart';
import '../screens/conveyance/conveyance_screen.dart';

class ConveyanceCard extends StatefulWidget {
  final String userRole;

  const ConveyanceCard({
    super.key,
    required this.userRole,
  });

  @override
  State<ConveyanceCard> createState() => _ConveyanceCardState();
}

class _ConveyanceCardState extends State<ConveyanceCard> {
  late Timer _refreshTimer;

  @override
  void initState() {
    super.initState();
    // Conveyance card no longer shows pending count - handled by Pending Approvals card
  }

  @override
  void dispose() {
    _refreshTimer.cancel();
    super.dispose();
  }

  void _handleCardTap() {
    // All roles navigate to the unified Conveyance screen
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ConveyanceScreen(userRole: widget.userRole),
      ),
    );
  }

  // Don't show card if no pending items and user can't approve
  bool get _shouldShowCard {
    final canViewOwn = AccessControlService.hasAccess(
      widget.userRole,
      'conveyance_management',
      'view_own',
    );
    return canViewOwn; // Show if user can at least view their own claims
  }

  @override
  Widget build(BuildContext context) {
    if (!_shouldShowCard) {
      return const SizedBox.shrink();
    }

    const String title = 'Conveyance';
    const String subtitle = 'Submit & track claims';

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, const Color(0xFFfbf8ff)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: const Color(0xFF272579).withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
        border: Border.all(
          color: const Color(0xFF272579).withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _handleCardTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon and title
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00b8d9).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: const Color(0xFF00b8d9).withValues(alpha: 0.2),
                              width: 1,
                            ),
                          ),
                          child: const Icon(
                            Icons.commute,
                            size: 24,
                            color: Color(0xFF00b8d9),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF272579),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                subtitle,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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

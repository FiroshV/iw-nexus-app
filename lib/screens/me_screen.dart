import 'package:flutter/material.dart';
import '../services/access_control_service.dart';
import '../config/crm_colors.dart';
import 'admin/payroll/payroll_management_screen.dart';
import 'conveyance/conveyance_screen.dart';
import 'incentive/incentive_module_screen.dart';
import 'feedback/feedback_list_screen.dart';

class MeScreen extends StatelessWidget {
  final String userRole;

  const MeScreen({super.key, required this.userRole});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'My Services',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF272579),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Quick access to your HR services',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),

          // Payslip
          if (AccessControlService.hasAccess(userRole, 'payroll', 'view_own'))
            _buildServiceCard(
              context,
              title: 'Payslip',
              subtitle: 'View and manage your payslips',
              icon: Icons.receipt_long,
              color: CrmColors.primary,
              onTap: () {
                final initialTab =
                    (userRole == 'admin' || userRole == 'director') ? 1 : 0;
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        PayrollManagementScreen(initialTab: initialTab),
                  ),
                );
              },
            ),

          // Conveyance
          if (AccessControlService.hasAccess(
              userRole, 'conveyance_management', 'view_own'))
            _buildServiceCard(
              context,
              title: 'Conveyance',
              subtitle: 'Submit and track travel claims',
              icon: Icons.commute,
              color: CrmColors.secondary,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ConveyanceScreen(userRole: userRole),
                  ),
                );
              },
            ),

          // Incentives
          if (AccessControlService.hasAccess(
              userRole, 'incentive_management', 'view_own_incentive'))
            _buildServiceCard(
              context,
              title: 'Incentives',
              subtitle: 'Commission tracking and targets',
              icon: Icons.workspace_premium_rounded,
              color: const Color(0xFF5cfbd8),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const IncentiveModuleScreen(),
                  ),
                );
              },
            ),

          // Feedback
          _buildServiceCard(
            context,
            title: 'Feedback & Support',
            subtitle: 'Share feedback or report issues',
            icon: Icons.feedback_outlined,
            color: CrmColors.primary,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const FeedbackListScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.white, Color(0xFFfbf8ff)],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(
                color: const Color(0xFF272579).withValues(alpha: 0.08),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: color.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Icon(icon, size: 24, color: color),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF272579),
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

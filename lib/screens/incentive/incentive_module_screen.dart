import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/incentive_provider.dart';
import '../../services/access_control_service.dart';
import 'my_incentive_screen.dart';
import '../admin/incentive/incentive_templates_screen.dart';
import '../admin/incentive/incentive_assignments_screen.dart';
import '../admin/incentive/pending_promotions_screen.dart';

class IncentiveModuleScreen extends StatefulWidget {
  const IncentiveModuleScreen({super.key});

  @override
  State<IncentiveModuleScreen> createState() => _IncentiveModuleScreenState();
}

class _IncentiveModuleScreenState extends State<IncentiveModuleScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  Future<void> _loadInitialData() async {
    final provider = context.read<IncentiveProvider>();
    final authProvider = context.read<AuthProvider>();
    final userRole = authProvider.user?['role']?.toString();

    // Load my incentive for all users
    provider.fetchMyIncentive();

    // Load admin data if user has access
    if (AccessControlService.hasAccess(
        userRole, 'incentive_management', 'view_templates')) {
      provider.fetchTemplates();
      provider.fetchPendingPromotions();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final userRole = authProvider.user?['role']?.toString();

    final canViewTemplates = AccessControlService.hasAccess(
      userRole,
      'incentive_management',
      'view_templates',
    );
    final canApprovePromotions = AccessControlService.hasAccess(
      userRole,
      'incentive_management',
      'approve_promotion',
    );

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF272579), Color(0xFF0071bf)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.trending_up_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Incentives',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                  Text(
                    'Commission & Targets',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        foregroundColor: Colors.white,
      ),
      backgroundColor: const Color(0xFFf8f9fa),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // My Incentive Card (always visible)
            _buildModuleCard(
              title: 'My Incentive',
              subtitle: 'View your current bracket and progress',
              icon: Icons.account_circle_rounded,
              color: const Color(0xFF0071bf),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const MyIncentiveScreen(),
                  ),
                );
              },
            ),

            // Admin Section
            if (canViewTemplates) ...[
              const SizedBox(height: 24),
              Text(
                'Administration',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),

              // Templates Card
              _buildModuleCard(
                title: 'Incentive Templates',
                subtitle: 'Create and manage commission brackets',
                icon: Icons.workspace_premium_rounded,
                color: const Color(0xFF272579),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const IncentiveTemplatesScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 12),

              // Assignments Card
              _buildModuleCard(
                title: 'Employee Assignments',
                subtitle: 'Assign templates to employees',
                icon: Icons.assignment_ind_rounded,
                color: const Color(0xFF00b8d9),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const IncentiveAssignmentsScreen(),
                    ),
                  );
                },
              ),

              // Pending Promotions Card
              if (canApprovePromotions) ...[
                const SizedBox(height: 12),
                Consumer<IncentiveProvider>(
                  builder: (context, provider, child) {
                    final pendingCount = provider.pendingPromotionsCount;
                    return _buildModuleCard(
                      title: 'Pending Promotions',
                      subtitle: pendingCount > 0
                          ? '$pendingCount awaiting approval'
                          : 'Review and approve bracket promotions',
                      icon: Icons.approval_rounded,
                      color: Colors.orange,
                      badge: pendingCount > 0 ? pendingCount.toString() : null,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) =>
                                const PendingPromotionsScreen(),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ],

            const SizedBox(height: 24),

            // Quick Info Card
            _buildInfoCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildModuleCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    String? badge,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: const Color(0xFF272579).withValues(alpha: 0.06),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF272579),
                          ),
                        ),
                        if (badge != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              badge,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.grey[400],
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF272579).withValues(alpha: 0.05),
            const Color(0xFF0071bf).withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF272579).withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 18,
                color: const Color(0xFF272579).withValues(alpha: 0.6),
              ),
              const SizedBox(width: 8),
              const Text(
                'How Incentives Work',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF272579),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoItem(
            icon: Icons.workspace_premium_rounded,
            text: 'Each bracket has different commission rates',
          ),
          _buildInfoItem(
            icon: Icons.track_changes_rounded,
            text: 'Meet monthly targets to progress',
          ),
          _buildInfoItem(
            icon: Icons.approval_rounded,
            text: 'Promotions require admin approval',
          ),
          _buildInfoItem(
            icon: Icons.calculate_rounded,
            text: 'Commission calculated on each sale',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({required IconData icon, required String text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 14,
            color: Colors.grey[400],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

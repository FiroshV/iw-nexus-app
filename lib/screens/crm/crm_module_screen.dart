import 'package:flutter/material.dart';
import '../../config/crm_colors.dart';
import '../../config/crm_design_system.dart';

class CrmModuleScreen extends StatefulWidget {
  final String userId;
  final String userRole;

  const CrmModuleScreen({
    super.key,
    required this.userId,
    required this.userRole,
  });

  @override
  State<CrmModuleScreen> createState() => _CrmModuleScreenState();
}

class _CrmModuleScreenState extends State<CrmModuleScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'CRM Dashboard',
          style: CrmDesignSystem.headlineSmall.copyWith(color: Colors.white),
        ),
        centerTitle: true,
        elevation: 2,
        backgroundColor: CrmColors.primary,
        shadowColor: CrmColors.primary.withValues(alpha: 0.3),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Simplified Dashboard Grid
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: CrmDesignSystem.lg,
                vertical: CrmDesignSystem.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row 1: Customers and Appointments
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: CrmDesignSystem.lg,
                    crossAxisSpacing: CrmDesignSystem.lg,
                    childAspectRatio: 1.05,
                    children: [
                      _buildDashboardCard(
                        context,
                        title: 'Customers',
                        subtitle: 'Manage & track',
                        icon: Icons.people_outline,
                        color: CrmColors.primary,
                        onTap: () => Navigator.of(context).pushNamed(
                          '/crm/customer-list',
                          arguments: {'userId': widget.userId, 'userRole': widget.userRole},
                        ),
                      ),
                      _buildDashboardCard(
                        context,
                        title: 'Appointments',
                        subtitle: 'Schedule & manage',
                        icon: Icons.event_note,
                        color: CrmColors.primary,
                        onTap: () => Navigator.of(context).pushNamed(
                          '/crm/appointments',
                          arguments: {'userId': widget.userId, 'userRole': widget.userRole},
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: CrmDesignSystem.lg),

                  // Row 2: Pipeline and Sales
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: CrmDesignSystem.lg,
                    crossAxisSpacing: CrmDesignSystem.lg,
                    childAspectRatio: 1.05,
                    children: [
                      _buildDashboardCard(
                        context,
                        title: 'Pipeline',
                        subtitle: 'Sales funnel',
                        icon: Icons.trending_up,
                        color: CrmColors.brand,
                        onTap: () => Navigator.of(context).pushNamed(
                          '/crm/pipeline',
                          arguments: {'userId': widget.userId, 'userRole': widget.userRole},
                        ),
                      ),
                      _buildDashboardCard(
                        context,
                        title: 'Sales',
                        subtitle: 'Record & track',
                        icon: Icons.trending_up,
                        color: CrmColors.success,
                        onTap: () => Navigator.of(context).pushNamed(
                          '/crm/sales-list',
                          arguments: {'userId': widget.userId, 'userRole': widget.userRole},
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: CrmDesignSystem.lg),

                  // Row 3: Activity Log
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: CrmDesignSystem.lg,
                    crossAxisSpacing: CrmDesignSystem.lg,
                    childAspectRatio: 1.05,
                    children: [
                      _buildDashboardCard(
                        context,
                        title: 'Activity Log',
                        subtitle: 'View interactions',
                        icon: Icons.history,
                        color: CrmColors.secondary,
                        onTap: () => Navigator.of(context).pushNamed(
                          '/crm/activity-list',
                          arguments: {'userId': widget.userId, 'userRole': widget.userRole},
                        ),
                      ),
                      _buildDashboardCard(
                        context,
                        title: 'Overdue',
                        subtitle: 'Urgent follow-ups',
                        icon: Icons.warning,
                        color: Colors.red,
                        onTap: () => Navigator.of(context).pushNamed(
                          '/crm/pipeline/overdue',
                          arguments: {'userId': widget.userId, 'userRole': widget.userRole},
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: CrmDesignSystem.huge),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: CrmColors.primary,
        elevation: 4,
        child: const Icon(Icons.add, color: Colors.white,),
        onPressed: () => _showQuickAddMenu(context),
      ),
    );
  }

  Widget _buildDashboardCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: CrmDesignSystem.durationNormal,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(CrmDesignSystem.radiusXL),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(CrmDesignSystem.radiusXL),
            splashColor: color.withValues(alpha: 0.05),
            highlightColor: color.withValues(alpha: 0.03),
            child: Padding(
              padding: const EdgeInsets.all(CrmDesignSystem.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(
                        CrmDesignSystem.radiusLarge,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      icon,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: CrmDesignSystem.titleLarge.copyWith(
                          color: CrmColors.textDark,
                        ),
                      ),
                      const SizedBox(height: CrmDesignSystem.sm),
                      Text(
                        subtitle,
                        style: CrmDesignSystem.bodySmall.copyWith(
                          color: CrmColors.textLight,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showQuickAddMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                'Quick Add',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: CrmColors.brand,
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.event_note, color: CrmColors.primary),
              title: const Text('Schedule Appointment'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).pushNamed(
                  '/crm/simplified-appointment',
                  arguments: {'userId': widget.userId, 'userRole': widget.userRole},
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.phone_outlined, color: CrmColors.secondary),
              title: const Text('Activity Log'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).pushNamed(
                  '/crm/log-activity',
                  arguments: {'userId': widget.userId, 'userRole': widget.userRole},
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.trending_up, color: CrmColors.success),
              title: const Text('Record Sale'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).pushNamed(
                  '/crm/add-edit-sale',
                  arguments: {'userId': widget.userId, 'userRole': widget.userRole},
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.people_outline, color: CrmColors.primary),
              title: const Text('Add Customer'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).pushNamed(
                  '/crm/add-customer',
                  arguments: {'userId': widget.userId, 'userRole': widget.userRole},
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

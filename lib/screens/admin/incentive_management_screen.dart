import 'package:flutter/material.dart';
import '../../services/incentive_api_service.dart';
import 'incentive_templates_screen.dart';
import 'assign_incentive_screen.dart';

/// Main dashboard for incentive management
class IncentiveManagementScreen extends StatefulWidget {
  const IncentiveManagementScreen({Key? key}) : super(key: key);

  @override
  State<IncentiveManagementScreen> createState() =>
      _IncentiveManagementScreenState();
}

class _IncentiveManagementScreenState extends State<IncentiveManagementScreen> with TickerProviderStateMixin {
  int _selectedTabIndex = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Incentive Management'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Tab bar
          Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey[200]!),
              ),
            ),
            child: TabBar(
              controller: TabController(
                length: 3,
                initialIndex: _selectedTabIndex,
                vsync: this,
              ),
              onTap: (index) {
                setState(() => _selectedTabIndex = index);
                _pageController.animateToPage(
                  index,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              tabs: const [
                Tab(
                  icon: Icon(Icons.dashboard),
                  text: 'Overview',
                ),
                Tab(
                  icon: Icon(Icons.dashboard_customize),
                  text: 'Templates',
                ),
                Tab(
                  icon: Icon(Icons.people),
                  text: 'Assignments',
                ),
              ],
            ),
          ),

          // Tab content
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() => _selectedTabIndex = index);
              },
              children: [
                _buildOverviewTab(),
                const IncentiveTemplatesScreen(),
                _buildAssignmentsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick stats
          _buildStatsGrid(),

          const SizedBox(height: 24),

          // Quick actions
          Text(
            'Quick Actions',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          _buildQuickActionsGrid(),

          const SizedBox(height: 24),

          // Info cards
          _buildInfoCards(),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildStatCard(
          icon: Icons.dashboard_customize_rounded,
          label: 'Templates',
          value: '0',
          color: Colors.blue,
        ),
        _buildStatCard(
          icon: Icons.people_rounded,
          label: 'Employees Assigned',
          value: '0',
          color: Colors.green,
        ),
        _buildStatCard(
          icon: Icons.trending_up,
          label: 'Avg Multiplier',
          value: '1.0x',
          color: Colors.purple,
        ),
        _buildStatCard(
          icon: Icons.info_rounded,
          label: 'Unassigned',
          value: '0',
          color: Colors.orange,
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildQuickActionCard(
          icon: Icons.add,
          label: 'Create Template',
          onTap: () {
            _pageController.animateToPage(
              1,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          },
          color: Colors.blue,
        ),
        _buildQuickActionCard(
          icon: Icons.person_add_alt,
          label: 'Assign Incentive',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const AssignIncentiveScreen(),
              ),
            );
          },
          color: Colors.green,
        ),
        _buildQuickActionCard(
          icon: Icons.list,
          label: 'View Templates',
          onTap: () {
            _pageController.animateToPage(
              1,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          },
          color: Colors.purple,
        ),
        _buildQuickActionCard(
          icon: Icons.person_search,
          label: 'View Assignments',
          onTap: () {
            _pageController.animateToPage(
              2,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          },
          color: Colors.orange,
        ),
      ],
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Getting Started',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        _buildInfoCard(
          icon: Icons.lightbulb_outline,
          title: 'How it works',
          description:
              'Create templates with tier structures or percentages, then assign them to employees or entire roles.',
        ),
        _buildInfoCard(
          icon: Icons.visibility_outlined,
          title: 'Transparency',
          description:
              'Employees can view their incentive structure and calculate expected earnings.',
        ),
        _buildInfoCard(
          icon: Icons.trending_up_outlined,
          title: 'Performance Bonuses',
          description:
              'Adjust performance multipliers individually to reward top performers.',
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.grey[600], size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssignmentsTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: IncentiveApiService.getAllEmployeesWithIncentives(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text('Failed to load assignments'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final employees = snapshot.data ?? [];
        final withIncentives =
            employees.where((e) => e['incentive'] != null).length;
        final withoutIncentives = employees.length - withIncentives;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryCard(
                      label: 'With Incentives',
                      value: withIncentives.toString(),
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSummaryCard(
                      label: 'Without Incentives',
                      value: withoutIncentives.toString(),
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Employee list
              Text(
                'All Employees',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: employees.length,
                itemBuilder: (context, index) {
                  final employee = employees[index];
                  final incentive = employee['incentive'] as Map?;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: Colors.grey[200]!),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.grey[300],
                            child: const Icon(Icons.person, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${employee['firstName'] ?? ''} ${employee['lastName'] ?? ''}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  incentive != null
                                      ? (incentive['templateId'] is Map
                                          ? incentive['templateId']
                                              ['templateName']
                                          : 'Custom')
                                      : 'No incentive',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: incentive != null
                                            ? Colors.green[600]
                                            : Colors.orange[600],
                                      ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            incentive != null
                                ? Icons.check_circle
                                : Icons.info,
                            color: incentive != null
                                ? Colors.green[600]
                                : Colors.orange[600],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryCard({
    required String label,
    required String value,
    required Color color,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

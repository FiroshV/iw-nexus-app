import 'package:flutter/material.dart';
import '../../config/crm_colors.dart';
import '../../config/crm_design_system.dart';
import '../../models/pipeline_stats.dart';
import '../../services/pipeline_service.dart';
import '../../widgets/crm/pipeline_stage_card.dart';

class PipelineDashboardScreen extends StatefulWidget {
  final String userId;
  final String userRole;

  const PipelineDashboardScreen({
    super.key,
    required this.userId,
    required this.userRole,
  });

  @override
  State<PipelineDashboardScreen> createState() => _PipelineDashboardScreenState();
}

class _PipelineDashboardScreenState extends State<PipelineDashboardScreen> {
  late Future<PipelineStatsData> _dashboardFuture;
  String _selectedView = 'assigned';
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _dashboardFuture = _fetchDashboard();
  }

  Future<PipelineStatsData> _fetchDashboard() async {
    final response = await PipelineService.getPipelineDashboard(view: _selectedView);
    if (response.success && response.data != null) {
      return response.data!;
    } else {
      throw Exception(response.message ?? 'Failed to load pipeline dashboard');
    }
  }

  Future<void> _refreshDashboard() async {
    setState(() {
      _isRefreshing = true;
    });
    try {
      setState(() {
        _dashboardFuture = _fetchDashboard();
      });
      await _dashboardFuture;
    } finally {
      setState(() {
        _isRefreshing = false;
      });
    }
  }

  void _navigateToStage(String stage) {
    Navigator.of(context).pushNamed(
      '/crm/pipeline/stage',
      arguments: {
        'stage': stage,
        'userId': widget.userId,
        'userRole': widget.userRole,
        'view': _selectedView,
      },
    );
  }

  void _navigateToOverdue() {
    Navigator.of(context).pushNamed(
      '/crm/pipeline/overdue',
      arguments: {
        'userId': widget.userId,
        'userRole': widget.userRole,
        'view': _selectedView,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Pipeline Dashboard',
          style: CrmDesignSystem.headlineSmall.copyWith(color: Colors.white),
        ),
        centerTitle: true,
        elevation: 2,
        backgroundColor: CrmColors.primary,
        shadowColor: CrmColors.primary.withValues(alpha: 0.3),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isRefreshing ? null : _refreshDashboard,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshDashboard,
        color: CrmColors.primary,
        child: FutureBuilder<PipelineStatsData>(
          future: _dashboardFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: CrmDesignSystem.lg),
                    Text(
                      'Failed to load pipeline',
                      style: CrmDesignSystem.titleMedium.copyWith(
                        color: CrmColors.textDark,
                      ),
                    ),
                    const SizedBox(height: CrmDesignSystem.sm),
                    Text(
                      snapshot.error.toString(),
                      style: CrmDesignSystem.bodySmall.copyWith(
                        color: CrmColors.textLight,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: CrmDesignSystem.lg),
                    ElevatedButton.icon(
                      onPressed: _refreshDashboard,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            if (!snapshot.hasData) {
              return const Center(
                child: Text('No data available'),
              );
            }

            final stats = snapshot.data!;

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // View Tabs
                  Padding(
                    padding: const EdgeInsets.all(CrmDesignSystem.md),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(CrmDesignSystem.radiusMedium),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildViewTab('My Leads', 'assigned'),
                          ),
                          Expanded(
                            child: _buildViewTab('Team', 'branch'),
                          ),
                          Expanded(
                            child: _buildViewTab('All', 'all'),
                          ),
                        ],
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: CrmDesignSystem.lg,
                      vertical: CrmDesignSystem.md,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Stage Summary Cards
                        Text(
                          'Pipeline Overview',
                          style: CrmDesignSystem.titleMedium.copyWith(
                            color: CrmColors.textDark,
                          ),
                        ),
                        const SizedBox(height: CrmDesignSystem.md),

                        // 4-Column Grid
                        GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: CrmDesignSystem.md,
                          crossAxisSpacing: CrmDesignSystem.md,
                          childAspectRatio: 1.1,
                          children: [
                            PipelineStageCard(
                              stageName: 'New Leads',
                              count: stats.newLeads,
                              color: CrmColors.secondary,
                              icon: Icons.fiber_new,
                              onTap: () => _navigateToStage('new_leads'),
                            ),
                            PipelineStageCard(
                              stageName: 'Active',
                              count: stats.active.total,
                              color: CrmColors.primary,
                              icon: Icons.trending_up,
                              onTap: () => _navigateToStage('active'),
                            ),
                            PipelineStageCard(
                              stageName: 'Closed Won',
                              count: stats.closedWon.count,
                              color: CrmColors.success,
                              icon: Icons.done_all,
                              onTap: () => _navigateToStage('closed_won'),
                            ),
                            PipelineStageCard(
                              stageName: 'Closed Lost',
                              count: stats.closedLost,
                              color: Colors.red,
                              icon: Icons.cancel,
                              onTap: () => _navigateToStage('closed_lost'),
                            ),
                          ],
                        ),

                        const SizedBox(height: CrmDesignSystem.lg),

                        // Overdue Follow-ups Alert
                        if (stats.overdueFollowups > 0)
                          GestureDetector(
                            onTap: _navigateToOverdue,
                            child: Container(
                              padding: const EdgeInsets.all(CrmDesignSystem.md),
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.1),
                                border: Border.all(
                                  color: Colors.red.withValues(alpha: 0.3),
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(CrmDesignSystem.radiusMedium),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '⚠️ Overdue Follow-ups',
                                          style: CrmDesignSystem.bodyMedium.copyWith(
                                            color: Colors.red,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: CrmDesignSystem.xs),
                                        Text(
                                          '${stats.overdueFollowups} lead${stats.overdueFollowups != 1 ? 's' : ''} need immediate follow-up',
                                          style: CrmDesignSystem.bodySmall.copyWith(
                                            color: Colors.red.withValues(alpha: 0.7),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.arrow_forward_ios,
                                    color: Colors.red.withValues(alpha: 0.5),
                                    size: 18,
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.all(CrmDesignSystem.md),
                            decoration: BoxDecoration(
                              color: CrmColors.success.withValues(alpha: 0.1),
                              border: Border.all(
                                color: CrmColors.success.withValues(alpha: 0.3),
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(CrmDesignSystem.radiusMedium),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  color: CrmColors.success,
                                  size: 24,
                                ),
                                const SizedBox(width: CrmDesignSystem.md),
                                Text(
                                  'All follow-ups are on schedule! 🎉',
                                  style: CrmDesignSystem.bodyMedium.copyWith(
                                    color: CrmColors.success,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),

                        const SizedBox(height: CrmDesignSystem.lg),

                        // Active Pipeline Breakdown
                        Text(
                          'Active Pipeline Breakdown',
                          style: CrmDesignSystem.titleMedium.copyWith(
                            color: CrmColors.textDark,
                          ),
                        ),
                        const SizedBox(height: CrmDesignSystem.md),

                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.grey[200]!),
                            borderRadius: BorderRadius.circular(CrmDesignSystem.radiusMedium),
                          ),
                          child: Column(
                            children: _buildActiveBreakdown(stats.active),
                          ),
                        ),

                        const SizedBox(height: CrmDesignSystem.lg),

                        // Revenue Card
                        if (stats.closedWon.totalRevenue > 0)
                          Container(
                            padding: const EdgeInsets.all(CrmDesignSystem.md),
                            decoration: BoxDecoration(
                              color: CrmColors.success.withValues(alpha: 0.1),
                              border: Border.all(
                                color: CrmColors.success.withValues(alpha: 0.3),
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(CrmDesignSystem.radiusMedium),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Total Revenue (Closed Won)',
                                  style: CrmDesignSystem.bodySmall.copyWith(
                                    color: CrmColors.textLight,
                                  ),
                                ),
                                const SizedBox(height: CrmDesignSystem.sm),
                                Text(
                                  '₹${stats.closedWon.totalRevenue.toStringAsFixed(2)}',
                                  style: CrmDesignSystem.headlineSmall.copyWith(
                                    color: CrmColors.success,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),

                        const SizedBox(height: CrmDesignSystem.lg),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildViewTab(String label, String view) {
    final isSelected = _selectedView == view;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedView = view;
          _dashboardFuture = _fetchDashboard();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: CrmDesignSystem.sm),
        decoration: BoxDecoration(
          color: isSelected ? CrmColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(CrmDesignSystem.radiusMedium),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: CrmDesignSystem.bodyMedium.copyWith(
            color: isSelected ? Colors.white : CrmColors.textLight,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  List<Widget> _buildActiveBreakdown(ActiveStats active) {
    final statuses = [
      ('Contacted', 'contacted', Colors.blue),
      ('Qualified', 'qualified', Colors.purple),
      ('Proposal Sent', 'proposal_sent', Colors.orange),
      ('Negotiation', 'negotiation', Colors.amber),
    ];

    return statuses.asMap().entries.map((entry) {
      final index = entry.key;
      final status = entry.value.$1;
      final statusKey = entry.value.$2;
      final color = entry.value.$3;
      final count = active.getCount(statusKey);

      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: CrmDesignSystem.md,
              vertical: CrmDesignSystem.sm,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  status,
                  style: CrmDesignSystem.bodyMedium.copyWith(
                    color: CrmColors.textDark,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: CrmDesignSystem.md,
                    vertical: CrmDesignSystem.xs,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(CrmDesignSystem.radiusMedium),
                  ),
                  child: Text(
                    '$count',
                    style: CrmDesignSystem.bodySmall.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (index < statuses.length - 1)
            Divider(
              height: 1,
              color: Colors.grey[200],
              indent: CrmDesignSystem.md,
              endIndent: CrmDesignSystem.md,
            ),
        ],
      );
    }).toList();
  }
}

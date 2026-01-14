library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/crm_colors.dart';
import '../../config/crm_design_system.dart';
import '../../providers/gamification_provider.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/gamification/stats_card.dart';
import '../../widgets/gamification/rankings_card.dart';
import '../../widgets/gamification/leaderboard_card.dart';

/// Gamification dashboard screen (SIMPLIFIED - Leaderboards only)
///
/// Shows:
/// - User's stats (sales, calls, activities)
/// - User's rankings for each metric
/// - Current streak
/// - Mini leaderboard (top performers)
class GamificationDashboardScreen extends StatefulWidget {
  const GamificationDashboardScreen({super.key});

  @override
  State<GamificationDashboardScreen> createState() =>
      _GamificationDashboardScreenState();
}

class _GamificationDashboardScreenState
    extends State<GamificationDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GamificationProvider>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CrmColors.surface,
      appBar: _buildAppBar(),
      body: Consumer<GamificationProvider>(
        builder: (context, provider, child) {
          if (provider.isSummaryLoading && !provider.hasSummary) {
            return const LoadingWidget(message: 'Loading stats...');
          }

          return RefreshIndicator(
            onRefresh: () => provider.refreshAll(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.all(CrmDesignSystem.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  StatsCard(profile: provider.quickProfile),
                  SizedBox(height: CrmDesignSystem.lg),
                  RankingsCard(rankings: provider.myRankings),
                  SizedBox(height: CrmDesignSystem.lg),
                  LeaderboardCard(
                    leaderboard: provider.leaderboard,
                    isLoading: provider.isLeaderboardLoading,
                    onViewAll: () => Navigator.pushNamed(
                      context,
                      '/gamification/leaderboard',
                    ),
                  ),
                  SizedBox(height: CrmDesignSystem.xxl),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [CrmColors.brand, CrmColors.primary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      title: const Row(
        children: [
          Icon(Icons.leaderboard_rounded, color: Colors.white, size: 24),
          SizedBox(width: 12),
          Text(
            'Leaderboards',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
      foregroundColor: Colors.white,
    );
  }
}

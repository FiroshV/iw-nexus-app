import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/crm_colors.dart';
import '../../config/crm_design_system.dart';
import '../../providers/gamification_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/gamification/leaderboard_filter_bar.dart';
import '../../widgets/gamification/podium_widget.dart';
import '../../widgets/gamification/my_rank_card.dart';
import '../../widgets/gamification/leaderboard_item.dart';
import '../../widgets/gamification/leaderboard_empty_state.dart';

/// Full leaderboard screen
///
/// Features:
/// - Metric filtering (sales count, sales amount, activities, calls)
/// - Podium display (top 3)
/// - My rank card (if user not in top 10)
/// - Full scrollable leaderboard
/// - Pull-to-refresh
class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  String _selectedMetric = 'sales_count';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<GamificationProvider>();
      provider.setLeaderboardFilters(metric: _selectedMetric);
    });
  }

  void _onMetricChanged(String metric) {
    setState(() {
      _selectedMetric = metric;
    });
    context.read<GamificationProvider>().setLeaderboardFilters(metric: metric);
  }

  bool _shouldShowMyRankCard(GamificationProvider provider, AuthProvider authProvider) {
    if (provider.leaderboard.isEmpty) return false;

    final currentUserId = authProvider.user?['_id'];
    if (currentUserId == null) return false;

    // Check if user is in top 10
    final userInTop10 = provider.leaderboard.take(10).any(
          (entry) => entry.user.id == currentUserId,
        );

    // Show card if user is not in top 10
    return !userInTop10;
  }

  bool _isCurrentUser(String entryUserId, AuthProvider authProvider) {
    final currentUserId = authProvider.user?['_id'];
    return currentUserId != null && currentUserId == entryUserId;
  }

  int? _getMyRankForMetric(GamificationProvider provider) {
    final rankings = provider.myRankings;
    if (rankings == null) return null;

    switch (_selectedMetric) {
      case 'sales_count':
        return rankings.salesCount.rank;
      case 'sales_amount':
        return rankings.salesAmount.rank;
      case 'activities_count':
        return rankings.activities.rank;
      case 'calls_count':
        // Note: calls_count ranking not available in current Rankings model
        // Would need to be added to backend if needed
        return null;
      default:
        return null;
    }
  }

  int _getTotalParticipants(GamificationProvider provider) {
    final rankings = provider.myRankings;
    if (rankings == null) return 0;

    // Use any ranking to get total participants (they should all be the same)
    return rankings.salesCount.totalParticipants;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CrmColors.surface,
      appBar: _buildAppBar(),
      body: Consumer2<GamificationProvider, AuthProvider>(
        builder: (context, gamificationProvider, authProvider, child) {
          if (gamificationProvider.isLeaderboardLoading &&
              gamificationProvider.leaderboard.isEmpty) {
            return const LoadingWidget(message: 'Loading leaderboard...');
          }

          return Column(
            children: [
              // Filter bar
              LeaderboardFilterBar(
                selectedMetric: _selectedMetric,
                onMetricChanged: _onMetricChanged,
                userRole: authProvider.user?['role'],
              ),

              // Content
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => gamificationProvider.refreshAll(),
                  child: gamificationProvider.leaderboard.isEmpty
                      ? const SingleChildScrollView(
                          physics: AlwaysScrollableScrollPhysics(),
                          child: LeaderboardEmptyState(),
                        )
                      : CustomScrollView(
                          slivers: [
                            // Podium (top 3)
                            if (gamificationProvider.leaderboard.length >= 3)
                              SliverToBoxAdapter(
                                child: PodiumWidget(
                                  first: gamificationProvider.leaderboard[0],
                                  second: gamificationProvider.leaderboard[1],
                                  third: gamificationProvider.leaderboard[2],
                                  metric: _selectedMetric,
                                ),
                              ),

                            // My rank card (if not in top 10)
                            if (_shouldShowMyRankCard(
                                gamificationProvider, authProvider))
                              SliverToBoxAdapter(
                                child: MyRankCard(
                                  rank: _getMyRankForMetric(gamificationProvider),
                                  total: _getTotalParticipants(gamificationProvider),
                                  profile: gamificationProvider.quickProfile,
                                  metric: _selectedMetric,
                                ),
                              ),

                            // Full list
                            SliverPadding(
                              padding: EdgeInsets.all(CrmDesignSystem.lg),
                              sliver: SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) {
                                    final entry =
                                        gamificationProvider.leaderboard[index];
                                    return LeaderboardItemWidget(
                                      entry: entry,
                                      isCurrentUser: _isCurrentUser(
                                        entry.user.id,
                                        authProvider,
                                      ),
                                    );
                                  },
                                  childCount:
                                      gamificationProvider.leaderboard.length,
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
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
      title: const Text(
        'Full Leaderboard',
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      foregroundColor: Colors.white,
      iconTheme: const IconThemeData(color: Colors.white),
    );
  }
}

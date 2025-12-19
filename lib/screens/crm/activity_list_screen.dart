import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/crm_colors.dart';
import '../../config/crm_design_system.dart';
import '../../models/activity.dart';
import '../../services/access_control_service.dart';
import '../../widgets/crm/activity_card.dart';
import '../../widgets/crm/scope_tab_selector.dart';
import '../../providers/crm/activity_provider.dart';

class ActivityListScreen extends StatefulWidget {
  final String userId;
  final String userRole;

  const ActivityListScreen({
    super.key,
    required this.userId,
    required this.userRole,
  });

  @override
  State<ActivityListScreen> createState() => _ActivityListScreenState();
}

class _ActivityListScreenState extends State<ActivityListScreen>
    with SingleTickerProviderStateMixin {
  String _searchQuery = '';
  TabController? _tabController;
  bool _hasViewTeamPermission = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();

    _hasViewTeamPermission = AccessControlService.hasAccess(
      widget.userRole,
      'crm_management',
      'view_team',
    );

    if (_hasViewTeamPermission) {
      _tabController = TabController(length: 2, vsync: this);
      _tabController!.addListener(_onTabChanged);
    }

    // Load activities using provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final view = _getCurrentView();
      context.read<ActivityProvider>().fetchActivities(view: view);
    });
  }

  void _onTabChanged() {
    // Prevent listener from firing multiple times during tab animation
    if (!_tabController!.indexIsChanging) {
      final view = _getCurrentView();
      context.read<ActivityProvider>().fetchActivities(view: view);
    }
  }

  String _getCurrentView() {
    if (!_hasViewTeamPermission) return 'assigned';
    if (_tabController == null || _tabController!.index == 0) return 'assigned';

    if (widget.userRole == 'admin' || widget.userRole == 'director') {
      return 'all';
    }
    return 'branch';
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController?.dispose();
    super.dispose();
  }

  void _navigateToActivityDetails(Activity activity) {
    Navigator.of(context).pushNamed(
      '/crm/activity-details',
      arguments: {
        'activityId': activity.id ?? activity.activityId,
        'userId': widget.userId,
        'userRole': widget.userRole,
      },
    ).then((result) {
      if (mounted) {
        // Invalidate cache when returning from activity details
        final view = _getCurrentView();
        try {
          context.read<ActivityProvider>().fetchActivities(
                view: view,
                forceRefresh: true,
              );
        } catch (e) {
          // Provider might not be available
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ActivityProvider>(
      builder: (context, provider, child) {
        final view = _getCurrentView();
        final cache = provider.getCache(view);
        final activities = provider.getActivities(view, searchQuery: _searchQuery);

        return Scaffold(
          appBar: AppBar(
            title: Text(
              'Activity Log',
              style: CrmDesignSystem.headlineSmall.copyWith(color: Colors.white),
            ),
            centerTitle: true,
            backgroundColor: CrmColors.primary,
            elevation: 2,
            bottom: _hasViewTeamPermission
                ? ScopeTabSelector(
                    controller: _tabController!,
                    userRole: widget.userRole,
                  )
                : null,
          ),
          body: Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.all(CrmDesignSystem.md),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by customer name...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: CrmDesignSystem.md,
                      vertical: CrmDesignSystem.sm,
                    ),
                  ),
                  onSubmitted: (value) {
                    setState(() => _searchQuery = value);
                  },
                ),
              ),

              // Activities list
              Expanded(
                child: Stack(
                  children: [
                    // Show loading ONLY if no cached data
                    if (cache.isLoading && !cache.hasData)
                      const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(CrmColors.primary),
                        ),
                      )

                    // Show error ONLY if no cached data
                    else if (cache.error != null && !cache.hasData)
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline,
                                size: 48, color: Colors.red.shade400),
                            const SizedBox(height: 16),
                            Text(cache.error!),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => provider.fetchActivities(
                                  view: view, forceRefresh: true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: CrmColors.primary,
                              ),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )

                    // Show data (cached or fresh)
                    else if (activities.isEmpty)
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.history,
                              size: 64,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isEmpty
                                  ? 'No activities found'
                                  : 'No match found',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _searchQuery.isEmpty
                                  ? 'Try logging new activities'
                                  : 'Try adjusting your search',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      RefreshIndicator(
                        onRefresh: () =>
                            provider.fetchActivities(view: view, forceRefresh: true),
                        child: ListView.builder(
                          padding: const EdgeInsets.all(CrmDesignSystem.md),
                          itemCount: activities.length,
                          itemBuilder: (context, index) {
                            final activity = activities[index];
                            return ActivityCard(
                              activity: activity,
                              onTap: () => _navigateToActivityDetails(activity),
                            );
                          },
                        ),
                      ),

                    // Show refresh indicator at top when refreshing
                    if (cache.isRefreshing)
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: LinearProgressIndicator(
                          minHeight: 2,
                          backgroundColor: Colors.transparent,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(CrmColors.primary),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            backgroundColor: CrmColors.primary,
            onPressed: () {
              Navigator.of(context).pushNamed(
                '/crm/log-activity',
                arguments: {
                  'userId': widget.userId,
                  'userRole': widget.userRole,
                },
              ).then((_) {
                // Invalidate cache when returning from log activity
                try {
                  provider.invalidateAll();
                } catch (e) {
                  // Provider might not be available
                }
              });
            },
            child: const Icon(Icons.add, color: Colors.white),
          ),
        );
      },
    );
  }
}

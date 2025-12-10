import 'package:flutter/material.dart';
import '../../config/crm_colors.dart';
import '../../config/crm_design_system.dart';
import '../../models/activity.dart';
import '../../services/activity_service.dart';
import '../../services/access_control_service.dart';
import '../../widgets/crm/activity_card.dart';
import '../../widgets/crm/scope_tab_selector.dart';

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
  List<Activity> _activities = [];
  bool _isLoading = true;
  String? _error;

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

    _loadActivities();
  }

  void _onTabChanged() {
    // Prevent listener from firing multiple times during tab animation
    if (!_tabController!.indexIsChanging) {
      _loadActivities();
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

  Future<void> _loadActivities() async {
    // Clear old data immediately to prevent showing stale data
    setState(() {
      _isLoading = true;
      _error = null;
      _activities = [];
    });

    try {
      final view = _getCurrentView();
      final response = await ActivityService.getUserActivities(
        userId: widget.userId,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        limit: 100,
        view: view,
      );

      if (!mounted) return;

      if (response.success && response.data != null) {
        setState(() {
          _activities = response.data!;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = response.error?.toString() ?? 'Failed to load activities';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _navigateToActivityDetails(Activity activity) {
    Navigator.of(context).pushNamed(
      '/crm/activity-details',
      arguments: {
        'activityId': activity.id ?? activity.activityId,
        'userId': widget.userId,
        'userRole': widget.userRole,
      },
    ).then((_) {
      // Refresh activities after returning from details page
      _loadActivities();
    });
  }

  @override
  Widget build(BuildContext context) {
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
                          _loadActivities();
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
                _loadActivities();
              },
            ),
          ),

          // Activities list
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(CrmColors.primary),
                    ),
                  )
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, size: 48, color: Colors.red),
                            const SizedBox(height: 16),
                            Text(_error!),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadActivities,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: CrmColors.primary,
                              ),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _activities.isEmpty
                        ? Center(
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
                                  'No activities found',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Try searching or check back later',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadActivities,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(CrmDesignSystem.md),
                              itemCount: _activities.length,
                              itemBuilder: (context, index) {
                                final activity = _activities[index];
                                return ActivityCard(
                                  activity: activity,
                                  onTap: () => _navigateToActivityDetails(activity),
                                );
                              },
                            ),
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
          ).then((_) => _loadActivities());
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

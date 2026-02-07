import 'package:flutter/material.dart';
import '../../config/crm_colors.dart';
import '../../widgets/crm/my_schedule_tab.dart';
import '../../widgets/crm/all_appointments_tab.dart';

/// Unified Appointments Screen with Tabbed Interface
/// Combines "My Schedule" (grid view) and "All Appointments" (list view)
/// Reduces user confusion by consolidating appointment functionality
class UnifiedAppointmentsScreen extends StatefulWidget {
  final String userId;
  final String userRole;
  final int initialTab; // 0 = My Schedule, 1 = All Appointments

  const UnifiedAppointmentsScreen({
    super.key,
    required this.userId,
    required this.userRole,
    this.initialTab = 0,
  });

  @override
  State<UnifiedAppointmentsScreen> createState() =>
      _UnifiedAppointmentsScreenState();
}

class _UnifiedAppointmentsScreenState extends State<UnifiedAppointmentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late bool _showAllAppointmentsTab;
  late int _tabCount;

  bool _canViewAllAppointments() {
    final role = widget.userRole;
    return role == 'admin' || role == 'director' || role == 'manager';
  }

  @override
  void initState() {
    super.initState();

    // Determine if user can see All Appointments tab
    _showAllAppointmentsTab = _canViewAllAppointments();
    _tabCount = _showAllAppointmentsTab ? 2 : 1;

    _tabController = TabController(
      length: _tabCount,
      vsync: this,
      initialIndex: widget.initialTab < _tabCount ? widget.initialTab : 0,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointments'),
        backgroundColor: CrmColors.primary,
        elevation: 2,
        shadowColor: CrmColors.primary.withValues(alpha: 0.3),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          tabs: [
            const Tab(
              icon: Icon(Icons.calendar_today),
              text: 'My Schedule',
            ),
            if (_showAllAppointmentsTab)
              const Tab(
                icon: Icon(Icons.list),
                text: 'All Appointments',
              ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          MyScheduleTab(
            userId: widget.userId,
            userRole: widget.userRole,
          ),
          if (_showAllAppointmentsTab)
            AllAppointmentsTab(
              userId: widget.userId,
              userRole: widget.userRole,
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: null,
        backgroundColor: CrmColors.primary,
        elevation: 4,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () => _createNewAppointment(),
      ),
    );
  }

  Future<void> _createNewAppointment() async {
    final result = await Navigator.of(context).pushNamed(
      '/crm/simplified-appointment',
      arguments: {
        'userId': widget.userId,
        'userRole': widget.userRole,
      },
    );

    // Refresh both tabs if appointment created
    if (result == true && mounted) {
      // Tab state is preserved with AutomaticKeepAliveClientMixin,
      // so refreshing happens automatically when appointments are created
    }
  }
}

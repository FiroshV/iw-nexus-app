import 'dart:convert';
import 'package:flutter/material.dart';
import '../../config/crm_colors.dart';
import '../../config/crm_design_system.dart';
import '../../models/customer.dart';
import '../../services/api_service.dart';
import '../../services/access_control_service.dart';
import '../../widgets/crm/customer_card.dart';
import '../../widgets/crm/scope_tab_selector.dart';

class CustomerListScreen extends StatefulWidget {
  final String userId;
  final String userRole;

  const CustomerListScreen({
    super.key,
    required this.userId,
    required this.userRole,
  });

  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  List<Customer> _customers = [];
  List<Customer> _filteredCustomers = [];
  bool _isLoading = false;
  String? _error;
  String _selectedFilter = 'all'; // all, recent, hot_leads, inactive

  TabController? _tabController;
  bool _hasViewTeamPermission = false;

  final List<Map<String, String>> _filters = [
    {'label': 'All', 'value': 'all'},
    {'label': 'Recent', 'value': 'recent'},
    {'label': 'Hot Leads', 'value': 'hot_leads'},
    {'label': 'Inactive', 'value': 'inactive'},
  ];

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

    _loadCustomers();
  }

  void _onTabChanged() {
    // Prevent listener from firing multiple times during tab animation
    if (!_tabController!.indexIsChanging) {
      _loadCustomers();
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

  Future<void> _loadCustomers() async {
    // Clear old data immediately to prevent showing stale data
    setState(() {
      _isLoading = true;
      _error = null;
      _customers = [];
      _filteredCustomers = [];
    });

    try {
      final view = _getCurrentView();
      final response = await ApiService.get('/crm/customers?limit=500&view=$view');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final customers = (data['data'] as List)
            .map((c) => Customer.fromJson(c as Map<String, dynamic>))
            .toList();

        setState(() {
          _customers = customers;
          _applyFilter();
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = _getErrorMessage(response.statusCode);
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = _getErrorMessage(null, error: e);
        _isLoading = false;
      });
    }
  }

  String _getErrorMessage(int? statusCode, {dynamic error}) {
    if (error != null) {
      final errorStr = error.toString().toLowerCase();
      if (errorStr.contains('socket') || errorStr.contains('connection')) {
        return 'No internet connection. Please check your network.';
      }
      return 'Error loading customers. Please try again.';
    }

    switch (statusCode) {
      case 404:
        return 'Customer service not available';
      case 401:
      case 403:
        return 'Access denied. You don\'t have permission to view customers.';
      case 500:
      case 502:
      case 503:
        return 'Server error. Please try again later.';
      default:
        return 'Failed to load customers. Please try again.';
    }
  }

  void _applyFilter() {
    List<Customer> filtered = _customers;

    // Apply text search
    final query = _searchController.text.toLowerCase();
    if (query.isNotEmpty) {
      filtered = filtered
          .where((c) =>
              c.name.toLowerCase().contains(query) ||
              c.mobileNumber.contains(query) ||
              c.customerId.toLowerCase().contains(query))
          .toList();
    }

    // Apply filter chips
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));

    switch (_selectedFilter) {
      case 'recent':
        filtered = filtered
            .where((c) => c.updatedAt.isAfter(thirtyDaysAgo))
            .toList();
        break;
      case 'hot_leads':
        // Hot leads: recently created (last 7 days) customers with no activity
        final sevenDaysAgo = now.subtract(const Duration(days: 7));
        filtered = filtered
            .where((c) =>
                c.createdAt.isAfter(sevenDaysAgo) &&
                c.updatedAt.isBefore(sevenDaysAgo))
            .toList();
        break;
      case 'inactive':
        // Inactive: no activity in last 60 days
        final sixtyDaysAgo = now.subtract(const Duration(days: 60));
        filtered = filtered
            .where((c) => c.updatedAt.isBefore(sixtyDaysAgo))
            .toList();
        break;
      case 'all':
      default:
        // No additional filter
        break;
    }

    // Sort by recent first
    filtered.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    setState(() {
      _filteredCustomers = filtered;
    });
  }

  void _onSearchChanged(String query) {
    _applyFilter();
  }

  void _onFilterChanged(String filterValue) {
    setState(() {
      _selectedFilter = filterValue;
    });
    _applyFilter();
  }

  void _openCustomerDetail(Customer customer) {
    Navigator.of(context).pushNamed(
      '/crm/customer-detail',
      arguments: {'customerId': customer.id},
    ).then((_) {
      // Refresh list when returning
      _loadCustomers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Customers',
          style: CrmDesignSystem.headlineSmall.copyWith(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: CrmColors.primary,
        elevation: 2,
        shadowColor: CrmColors.primary.withValues(alpha: 0.3),
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
            padding: const EdgeInsets.all(CrmDesignSystem.lg),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: CrmDesignSystem.inputDecoration(
                hintText: 'Search by name, mobile, or ID...',
                prefixIcon: Icons.search,
              ),
            ),
          ),

          // Filter chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: CrmDesignSystem.lg),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _filters.map((filter) {
                  final isSelected = _selectedFilter == filter['value'];
                  return Padding(
                    padding: const EdgeInsets.only(right: CrmDesignSystem.sm),
                    child: AnimatedContainer(
                      duration: CrmDesignSystem.durationNormal,
                      child: FilterChip(
                        label: Text(filter['label']!),
                        selected: isSelected,
                        onSelected: (_) => _onFilterChanged(filter['value']!),
                        backgroundColor: CrmColors.surface,
                        selectedColor: CrmColors.primary.withValues(alpha: 0.15),
                        labelStyle: TextStyle(
                          color: isSelected ? CrmColors.primary : CrmColors.textLight,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w400,
                        ),
                        side: BorderSide(
                          color: isSelected
                              ? CrmColors.primary
                              : CrmColors.borderColor,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          const SizedBox(height: CrmDesignSystem.md),

          // Results count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: CrmDesignSystem.lg),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${_filteredCustomers.length} customer${_filteredCustomers.length != 1 ? "s" : ""} found',
                style: CrmDesignSystem.labelSmall,
              ),
            ),
          ),

          const SizedBox(height: CrmDesignSystem.md),

          // Customer list
          Expanded(
            child: _isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(CrmColors.primary),
                        ),
                        const SizedBox(height: CrmDesignSystem.lg),
                        Text(
                          'Loading customers...',
                          style: CrmDesignSystem.bodyMedium
                              .copyWith(color: CrmColors.textLight),
                        ),
                      ],
                    ),
                  )
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.error_outline,
                                size: 32,
                                color: Colors.red,
                              ),
                            ),
                            const SizedBox(height: CrmDesignSystem.lg),
                            Text(
                              'Oops!',
                              style: CrmDesignSystem.headlineSmall,
                            ),
                            const SizedBox(height: CrmDesignSystem.sm),
                            Text(
                              _error!,
                              style: CrmDesignSystem.bodyMedium
                                  .copyWith(color: CrmColors.textLight),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: CrmDesignSystem.xl),
                            ElevatedButton.icon(
                              onPressed: _loadCustomers,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Retry'),
                              style: CrmDesignSystem.primaryButtonStyle,
                            ),
                          ],
                        ),
                      )
                    : _filteredCustomers.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color: CrmColors.secondary
                                        .withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.person_outline,
                                    size: 40,
                                    color: CrmColors.secondary,
                                  ),
                                ),
                                const SizedBox(height: CrmDesignSystem.lg),
                                Text(
                                  _searchController.text.isEmpty
                                      ? 'No customers yet'
                                      : 'No match found',
                                  style: CrmDesignSystem.headlineSmall,
                                ),
                                const SizedBox(height: CrmDesignSystem.sm),
                                Text(
                                  _searchController.text.isEmpty
                                      ? 'Add your first customer to get started'
                                      : 'Try adjusting your search',
                                  style: CrmDesignSystem.bodyMedium
                                      .copyWith(color: CrmColors.textLight),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(
                              horizontal: CrmDesignSystem.lg,
                              vertical: CrmDesignSystem.sm,
                            ),
                            itemCount: _filteredCustomers.length,
                            itemBuilder: (context, index) {
                              final customer = _filteredCustomers[index];
                              return Padding(
                                padding: const EdgeInsets.only(
                                  bottom: CrmDesignSystem.md,
                                ),
                                child: AnimatedOpacity(
                                  opacity: 1.0,
                                  duration: CrmDesignSystem.durationFast,
                                  child: CustomerCard(
                                    customer: customer,
                                    onTap: () => _openCustomerDetail(customer),
                                    appointmentCount: 0,
                                    visitCount: 0,
                                    saleCount: 0,
                                  ),
                                ),
                            );
                          },
                        ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: CrmColors.primary,
        elevation: 4,
        onPressed: () {
          Navigator.of(context).pushNamed('/crm/add-customer').then((_) {
            // Refresh list when returning from add customer
            _loadCustomers();
          });
        },
        child: const Icon(Icons.add, color: Colors.white,),
      ),
    );
  }
}

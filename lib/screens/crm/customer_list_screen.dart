import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/crm_colors.dart';
import '../../config/crm_design_system.dart';
import '../../models/customer.dart';
import '../../providers/crm/customer_provider.dart';
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
  TabController? _tabController;

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 2, vsync: this);
    _tabController!.addListener(_onTabChanged);

    // Trigger initial fetch from provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CustomerProvider>().fetchCustomers(view: _getCurrentView());
    });
  }

  void _onTabChanged() {
    // Prevent listener from firing multiple times during tab animation
    if (!_tabController!.indexIsChanging) {
      final view = _getCurrentView();
      context.read<CustomerProvider>().fetchCustomers(view: view);
    }
  }

  String _getCurrentView() {
    if (_tabController == null) return 'assigned';
    if (_tabController!.index == 0) return 'assigned';

    if (widget.userRole == 'admin' || widget.userRole == 'director') {
      return 'all';
    }
    return 'branch';
  }




  void _openCustomerDetail(Customer customer) {
    Navigator.of(context).pushNamed(
      '/crm/customer-detail',
      arguments: {'customerId': customer.id},
    ).then((_) {
      // Refresh list when returning
      if (mounted) {
        final view = _getCurrentView();
        context.read<CustomerProvider>().fetchCustomers(
          view: view,
          forceRefresh: true,
        );
      }
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
    return Consumer<CustomerProvider>(
      builder: (context, provider, child) {
        final view = _getCurrentView();
        final cache = provider.getCache(view);
        final customers = provider.getCustomers(view, searchQuery: _searchController.text);

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
            bottom: _tabController != null ? ScopeTabSelector(
              controller: _tabController!,
              userRole: widget.userRole,
            ) : null,
          ),
          body: Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.all(CrmDesignSystem.lg),
                child: TextField(
                  controller: _searchController,
                  onChanged: (query) {
                    // Trigger rebuild to filter results locally
                    setState(() {});
                  },
                  decoration: CrmDesignSystem.inputDecoration(
                    hintText: 'Search by name, mobile, or ID...',
                    prefixIcon: Icons.search,
                  ),
                ),
              ),

              // Results count
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: CrmDesignSystem.lg),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${customers.length} customer${customers.length != 1 ? "s" : ""} found',
                    style: CrmDesignSystem.labelSmall,
                  ),
                ),
              ),

              const SizedBox(height: CrmDesignSystem.md),

              // Customer list
              Expanded(
                child: Stack(
                  children: [
                    // Show loading ONLY if no cached data
                    if (cache.isLoading && !cache.hasData)
                      Center(
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
                    // Show error ONLY if no cached data
                    else if (cache.error != null && !cache.hasData)
                      Center(
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
                              cache.error!,
                              style: CrmDesignSystem.bodyMedium
                                  .copyWith(color: CrmColors.textLight),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: CrmDesignSystem.xl),
                            ElevatedButton.icon(
                              onPressed: () => provider.fetchCustomers(
                                view: view,
                                forceRefresh: true,
                              ),
                              icon: const Icon(Icons.refresh),
                              label: const Text('Retry'),
                              style: CrmDesignSystem.primaryButtonStyle,
                            ),
                          ],
                        ),
                      )
                    // Show empty state
                    else if (customers.isEmpty)
                      Center(
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
                    // Show customer list
                    else
                      RefreshIndicator(
                        onRefresh: () => provider.fetchCustomers(
                          view: view,
                          forceRefresh: true,
                        ),
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: CrmDesignSystem.lg,
                            vertical: CrmDesignSystem.sm,
                          ),
                          itemCount: customers.length,
                          itemBuilder: (context, index) {
                            final customer = customers[index];
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
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                    // Show refresh indicator at top when refreshing in background
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
            heroTag: null,
            backgroundColor: CrmColors.primary,
            elevation: 4,
            onPressed: () {
              Navigator.of(context).pushNamed('/crm/add-customer').then((_) {
                // Refresh list when returning from add customer
                provider.fetchCustomers(view: view, forceRefresh: true);
              });
            },
            child: const Icon(Icons.add, color: Colors.white),
          ),
        );
      },
    );
  }
}

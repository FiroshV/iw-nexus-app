import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/crm_colors.dart';
import '../../config/crm_design_system.dart';
import '../../models/sale.dart';
import '../../services/api_service.dart';
import '../../services/access_control_service.dart';
import '../../widgets/crm/sale_card.dart';
import '../../widgets/crm/scope_tab_selector.dart';
import 'add_edit_sale_screen.dart';

class SalesListScreen extends StatefulWidget {
  final String userId;
  final String userRole;

  const SalesListScreen({super.key, required this.userId, required this.userRole});

  @override
  State<SalesListScreen> createState() => _SalesListScreenState();
}

class _SalesListScreenState extends State<SalesListScreen>
    with SingleTickerProviderStateMixin {
  late ScrollController _scrollController;
  List<Sale> _sales = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  int _currentSkip = 0;
  int _totalSales = 0;
  bool _hasMoreData = true;

  String? _searchQuery;
  String? _selectedProductType;
  DateTimeRange? _selectedDateRange;

  TabController? _tabController;
  bool _hasViewTeamPermission = false;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);

    _hasViewTeamPermission = AccessControlService.hasAccess(
      widget.userRole,
      'crm_management',
      'view_team',
    );

    if (_hasViewTeamPermission) {
      _tabController = TabController(length: 2, vsync: this);
      _tabController!.addListener(_onTabChanged);
    }

    _loadSales();
  }

  void _onTabChanged() {
    // Prevent listener from firing multiple times during tab animation
    if (!_tabController!.indexIsChanging) {
      _currentSkip = 0;
      _sales.clear();
      _hasMoreData = true;
      _loadSales();
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
    _scrollController.dispose();
    _searchController.dispose();
    _tabController?.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.9) {
      if (_hasMoreData && !_isLoadingMore) {
        _loadMore();
      }
    }
  }

  Future<void> _loadSales() async {
    setState(() => _isLoading = true);

    try {
      final view = _getCurrentView();
      final response = await ApiService.getSales(
        skip: 0,
        limit: 20,
        productType: _selectedProductType,
        startDate: _selectedDateRange?.start,
        endDate: _selectedDateRange?.end,
        search: _searchQuery,
        view: view,
      );

      if (response.success) {
        List<Sale> salesList = [];
        int totalSales = 0;
        int totalPages = 1;

        // Handle both Map and List response formats
        if (response.data is Map<String, dynamic>) {
          final data = response.data as Map<String, dynamic>;
          salesList = (data['data'] as List)
              .map((s) => Sale.fromJson(s as Map<String, dynamic>))
              .toList();
          totalSales = data['total'] ?? 0;
          totalPages = data['totalPages'] ?? 1;
        } else if (response.data is List) {
          salesList = (response.data as List)
              .map((s) => Sale.fromJson(s as Map<String, dynamic>))
              .toList();
          totalSales = salesList.length;
          totalPages = 1;
        }

        setState(() {
          _sales = salesList;
          _totalSales = totalSales;
          _currentSkip = 0;
          _hasMoreData = totalPages > 1;
        });
      } else {
        _showError(response.message);
      }
    } catch (e) {
      _showError('Failed to load sales: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore) return;

    setState(() => _isLoadingMore = true);

    try {
      final newSkip = _currentSkip + 20;
      final view = _getCurrentView();
      final response = await ApiService.getSales(
        skip: newSkip,
        limit: 20,
        productType: _selectedProductType,
        startDate: _selectedDateRange?.start,
        endDate: _selectedDateRange?.end,
        search: _searchQuery,
        view: view,
      );

      if (response.success) {
        List<Sale> newSales = [];
        int currentPage = 1;
        int totalPages = 1;

        // Handle both Map and List response formats
        if (response.data is Map<String, dynamic>) {
          final data = response.data as Map<String, dynamic>;
          newSales = (data['data'] as List)
              .map((s) => Sale.fromJson(s as Map<String, dynamic>))
              .toList();
          currentPage = data['page'] ?? 1;
          totalPages = data['totalPages'] ?? 1;
        } else if (response.data is List) {
          newSales = (response.data as List)
              .map((s) => Sale.fromJson(s as Map<String, dynamic>))
              .toList();
          currentPage = 1;
          totalPages = 1;
        }

        setState(() {
          _sales.addAll(newSales);
          _currentSkip = newSkip;
          _hasMoreData = currentPage < totalPages;
        });
      }
    } catch (e) {
      _showError('Failed to load more sales: $e');
    } finally {
      setState(() => _isLoadingMore = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: CrmColors.errorColor),
    );
  }

  void _addNewSale() {
    Navigator.of(context)
        .push(
          MaterialPageRoute(builder: (context) => const AddEditSaleScreen()),
        )
        .then((refreshNeeded) {
          if (refreshNeeded == true) {
            _loadSales();
          }
        });
  }

  void _deleteSale(Sale sale) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Sale?'),
        content: Text(
          'Are you sure you want to delete the sale for ${sale.customerName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _performDeleteSale(sale.id);
            },
            style: TextButton.styleFrom(foregroundColor: CrmColors.errorColor),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _performDeleteSale(String saleId) async {
    try {
      final response = await ApiService.deleteSale(saleId);
      if (response.success) {
        _loadSales();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sale deleted successfully'),
              backgroundColor: CrmColors.successColor,
            ),
          );
        }
      } else {
        _showError(response.message);
      }
    } catch (e) {
      _showError('Failed to delete sale: $e');
    }
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (context) => _buildFilterSheet(),
    );
  }

  Widget _buildFilterSheet() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filters',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: CrmColors.textDark,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Product Type Filter
            Text(
              'Product Type',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: CrmColors.textDark,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: [
                _buildFilterChip(
                  label: 'All',
                  selected: _selectedProductType == null,
                  onSelected: () {
                    setState(() => _selectedProductType = null);
                    Navigator.pop(context);
                    _loadSales();
                  },
                ),
                _buildFilterChip(
                  label: 'Life Insurance',
                  selected: _selectedProductType == 'life_insurance',
                  onSelected: () {
                    setState(() => _selectedProductType = 'life_insurance');
                    Navigator.pop(context);
                    _loadSales();
                  },
                ),
                _buildFilterChip(
                  label: 'General Insurance',
                  selected: _selectedProductType == 'general_insurance',
                  onSelected: () {
                    setState(() => _selectedProductType = 'general_insurance');
                    Navigator.pop(context);
                    _loadSales();
                  },
                ),
                _buildFilterChip(
                  label: 'Mutual Funds',
                  selected: _selectedProductType == 'mutual_funds',
                  onSelected: () {
                    setState(() => _selectedProductType = 'mutual_funds');
                    Navigator.pop(context);
                    _loadSales();
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Date Range Filter
            Text(
              'Date Range',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: CrmColors.textDark,
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: () async {
                final range = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (range != null && mounted) {
                  setState(() => _selectedDateRange = range);
                  if (mounted) {
                    Navigator.pop(context);
                  }
                  _loadSales();
                }
              },
              icon: const Icon(Icons.calendar_today, color: Colors.white),
              label: Text(
                _selectedDateRange == null
                    ? 'Select Date Range'
                    : '${DateFormat('dd MMM').format(_selectedDateRange!.start)} - ${DateFormat('dd MMM').format(_selectedDateRange!.end)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: CrmColors.primary,
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
            if (_selectedDateRange != null) ...[
              const SizedBox(height: 10),
              TextButton.icon(
                onPressed: () {
                  setState(() => _selectedDateRange = null);
                  Navigator.pop(context);
                  _loadSales();
                },
                icon: const Icon(Icons.clear),
                label: const Text('Clear Date Range'),
                style: TextButton.styleFrom(
                  foregroundColor: CrmColors.errorColor,
                ),
              ),
            ],
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool selected,
    required VoidCallback onSelected,
  }) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      backgroundColor: CrmColors.surface,
      selectedColor: CrmColors.primary.withValues(alpha: 0.2),
      side: BorderSide(
        color: selected ? CrmColors.primary : CrmColors.borderColor,
        width: selected ? 2 : 1,
      ),
      labelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
        color: selected ? CrmColors.primary : CrmColors.textDark,
        fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Sales',
          style: CrmDesignSystem.headlineSmall.copyWith(color: Colors.white),
        ),
        centerTitle: true,
        elevation: 2,
        backgroundColor: CrmColors.primary,
        shadowColor: CrmColors.primary.withValues(alpha: 0.3),
        bottom: _hasViewTeamPermission
            ? ScopeTabSelector(
                controller: _tabController!,
                userRole: widget.userRole,
              )
            : null,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewSale,
        backgroundColor: const Color(0xFF0071bf),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          // Search bar and Filter button on same line
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() => _searchQuery = value);
                      _loadSales();
                    },
                    style: const TextStyle(fontSize: 16),
                    decoration: InputDecoration(
                      hintText: 'Search by name or mobile',
                      hintStyle: const TextStyle(
                        fontSize: 16,
                        color: CrmColors.textLight,
                      ),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: CrmColors.textLight,
                      ),
                      suffixIcon:
                          _searchQuery != null && _searchQuery!.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = null);
                                _loadSales();
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: CrmColors.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: CrmColors.borderColor,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: CrmColors.borderColor,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.filter_list),
                  onPressed: _showFilterSheet,
                  color: CrmColors.primary,
                  tooltip: 'Filters',
                ),
              ],
            ),
          ),

          // Active filter chips row
          if (_selectedProductType != null || _selectedDateRange != null)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    if (_selectedProductType != null) ...[
                      Chip(
                        label: Text(
                          CrmColors.getProductTypeName(_selectedProductType!),
                        ),
                        onDeleted: () {
                          setState(() => _selectedProductType = null);
                          _loadSales();
                        },
                        backgroundColor: CrmColors.getProductTypeColor(
                          _selectedProductType!,
                        ).withValues(alpha: 0.2),
                      ),
                    ],
                    if (_selectedDateRange != null) ...[
                      const SizedBox(width: 8),
                      Chip(
                        label: Text(
                          '${DateFormat('dd MMM').format(_selectedDateRange!.start)} - ${DateFormat('dd MMM').format(_selectedDateRange!.end)}',
                        ),
                        onDeleted: () {
                          setState(() => _selectedDateRange = null);
                          _loadSales();
                        },
                        backgroundColor: CrmColors.secondary.withValues(
                          alpha: 0.2,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

          const SizedBox(height: 8),

          // Sales list or empty state
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: CrmColors.primary),
                  )
                : _sales.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox,
                          size: 64,
                          color: CrmColors.textLight.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No sales found',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(color: CrmColors.textLight),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add your first sale to get started',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: CrmColors.textLight),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    itemCount: _sales.length + (_isLoadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _sales.length) {
                        return Padding(
                          padding: const EdgeInsets.all(16),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: CrmColors.primary,
                            ),
                          ),
                        );
                      }

                      final sale = _sales[index];
                      return SaleCard(
                        sale: sale,
                        onDelete: () => _deleteSale(sale),
                        onEdit: () {
                          Navigator.of(context)
                              .push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      AddEditSaleScreen(sale: sale),
                                ),
                              )
                              .then((refreshNeeded) {
                                if (refreshNeeded == true) {
                                  _loadSales();
                                }
                              });
                        },
                      );
                    },
                  ),
          ),

          // Total sales count
          if (_sales.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Showing ${_sales.length} of $_totalSales sales',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: CrmColors.textLight),
              ),
            ),
        ],
      ),
    );
  }
}

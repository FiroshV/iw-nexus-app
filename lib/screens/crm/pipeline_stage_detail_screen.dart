import 'package:flutter/material.dart';
import '../../config/crm_colors.dart';
import '../../config/crm_design_system.dart';
import '../../models/customer.dart';
import '../../services/pipeline_service.dart';
import '../../utils/timezone_util.dart';
import '../../widgets/crm/lead_status_badge.dart';
import '../../widgets/crm/priority_indicator.dart';

class PipelineStageDetailScreen extends StatefulWidget {
  final String stage;
  final String userId;
  final String userRole;
  final String view;

  const PipelineStageDetailScreen({
    super.key,
    required this.stage,
    required this.userId,
    required this.userRole,
    required this.view,
  });

  @override
  State<PipelineStageDetailScreen> createState() => _PipelineStageDetailScreenState();
}

class _PipelineStageDetailScreenState extends State<PipelineStageDetailScreen> {
  late Future<List<Customer>> _customersFuture;
  String? _selectedPriority;
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _customersFuture = _fetchCustomers();
  }

  Future<List<Customer>> _fetchCustomers() async {
    final response = await PipelineService.getCustomersByStage(
      widget.stage,
      view: widget.view,
      priority: _selectedPriority,
      search: _searchQuery.isNotEmpty ? _searchQuery : null,
    );

    if (response.success && response.data != null) {
      return response.data!;
    } else {
      throw Exception(response.message ?? 'Failed to load customers');
    }
  }

  String _getStageTitle() {
    switch (widget.stage) {
      case 'new_leads':
        return 'New Leads';
      case 'active':
        return 'Active Pipeline';
      case 'closed_won':
        return 'Closed Won';
      case 'closed_lost':
        return 'Closed Lost';
      default:
        return widget.stage;
    }
  }

  Color _getStageColor() {
    switch (widget.stage) {
      case 'new_leads':
        return CrmColors.secondary;
      case 'active':
        return CrmColors.primary;
      case 'closed_won':
        return CrmColors.success;
      case 'closed_lost':
        return Colors.red;
      default:
        return CrmColors.primary;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _getStageTitle(),
          style: CrmDesignSystem.headlineSmall.copyWith(color: Colors.white),
        ),
        backgroundColor: _getStageColor(),
        elevation: 2,
      ),
      body: Column(
        children: [
          // Filters
          Padding(
            padding: const EdgeInsets.all(CrmDesignSystem.md),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search customer name or phone...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(CrmDesignSystem.radiusMedium),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: CrmDesignSystem.md,
                      vertical: CrmDesignSystem.md,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                      _customersFuture = _fetchCustomers();
                    });
                  },
                ),
                const SizedBox(height: CrmDesignSystem.md),
                // Priority Filter (only for active stages)
                if (widget.stage == 'active' || widget.stage == 'new_leads')
                  Wrap(
                    spacing: CrmDesignSystem.sm,
                    children: [
                      FilterChip(
                        label: const Text('All'),
                        selected: _selectedPriority == null,
                        onSelected: (selected) {
                          setState(() {
                            _selectedPriority = null;
                            _customersFuture = _fetchCustomers();
                          });
                        },
                      ),
                      FilterChip(
                        label: const Text('Hot'),
                        selected: _selectedPriority == 'hot',
                        avatar: Icon(
                          Icons.local_fire_department,
                          color: _selectedPriority == 'hot' ? Colors.white : Colors.red,
                          size: 18,
                        ),
                        onSelected: (selected) {
                          setState(() {
                            _selectedPriority = selected ? 'hot' : null;
                            _customersFuture = _fetchCustomers();
                          });
                        },
                      ),
                      FilterChip(
                        label: const Text('Warm'),
                        selected: _selectedPriority == 'warm',
                        avatar: Icon(
                          Icons.local_fire_department,
                          color: _selectedPriority == 'warm' ? Colors.white : Colors.orange,
                          size: 18,
                        ),
                        onSelected: (selected) {
                          setState(() {
                            _selectedPriority = selected ? 'warm' : null;
                            _customersFuture = _fetchCustomers();
                          });
                        },
                      ),
                      FilterChip(
                        label: const Text('Cold'),
                        selected: _selectedPriority == 'cold',
                        avatar: Icon(
                          Icons.local_fire_department,
                          color: _selectedPriority == 'cold' ? Colors.white : Colors.blue,
                          size: 18,
                        ),
                        onSelected: (selected) {
                          setState(() {
                            _selectedPriority = selected ? 'cold' : null;
                            _customersFuture = _fetchCustomers();
                          });
                        },
                      ),
                    ],
                  ),
              ],
            ),
          ),
          // Customers List
          Expanded(
            child: FutureBuilder<List<Customer>>(
              future: _customersFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 48, color: Colors.red.withValues(alpha: 0.5)),
                        const SizedBox(height: CrmDesignSystem.md),
                        Text('Error: ${snapshot.error}'),
                      ],
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox, size: 48, color: Colors.grey.withValues(alpha: 0.5)),
                        const SizedBox(height: CrmDesignSystem.md),
                        Text(
                          'No customers in this stage',
                          style: CrmDesignSystem.titleMedium.copyWith(color: CrmColors.textLight),
                        ),
                      ],
                    ),
                  );
                }

                final customers = snapshot.data!;

                return ListView.builder(
                  padding: const EdgeInsets.all(CrmDesignSystem.md),
                  itemCount: customers.length,
                  itemBuilder: (context, index) {
                    final customer = customers[index];
                    return _buildCustomerCard(customer);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerCard(Customer customer) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).pushNamed(
          '/crm/customer-detail',
          arguments: {'customerId': customer.id, 'userId': widget.userId, 'userRole': widget.userRole},
        );
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: CrmDesignSystem.md),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(CrmDesignSystem.radiusMedium),
        ),
        child: Padding(
          padding: const EdgeInsets.all(CrmDesignSystem.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customer.name,
                          style: CrmDesignSystem.titleMedium.copyWith(
                            color: CrmColors.textDark,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: CrmDesignSystem.xs),
                        Text(
                          customer.mobileNumber,
                          style: CrmDesignSystem.bodySmall.copyWith(
                            color: CrmColors.textLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PriorityIndicator(priority: customer.leadPriority, compact: true),
                ],
              ),
              const SizedBox(height: CrmDesignSystem.md),
              // Status and Contact Info
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  LeadStatusBadge(status: customer.leadStatus, compact: true),
                  if (customer.lastContactDate != null)
                    Text(
                      'Last: ${_formatDate(customer.lastContactDate!)}',
                      style: CrmDesignSystem.bodySmall.copyWith(
                        color: CrmColors.textLight,
                      ),
                    ),
                ],
              ),
              if (customer.nextFollowupDate != null) ...[
                const SizedBox(height: CrmDesignSystem.sm),
                Text(
                  'Next Follow-up: ${_formatDate(customer.nextFollowupDate!)}',
                  style: CrmDesignSystem.bodySmall.copyWith(
                    color: Colors.blue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              if (customer.notes != null && customer.notes!.isNotEmpty) ...[
                const SizedBox(height: CrmDesignSystem.sm),
                Text(
                  customer.notes!,
                  style: CrmDesignSystem.bodySmall.copyWith(
                    color: CrmColors.textLight,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return 'Today';
    } else if (dateOnly == today.add(const Duration(days: 1))) {
      return 'Tomorrow';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

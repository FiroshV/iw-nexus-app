import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../providers/incentive_provider.dart';
import '../../../models/employee_incentive.dart';
import '../../../models/incentive_template.dart';
import '../../../services/incentive_service.dart';
import '../../../services/api_service.dart';
import '../../../widgets/loading_widget.dart';

class IncentiveAssignmentsScreen extends StatefulWidget {
  const IncentiveAssignmentsScreen({super.key});

  @override
  State<IncentiveAssignmentsScreen> createState() =>
      _IncentiveAssignmentsScreenState();
}

class _IncentiveAssignmentsScreenState
    extends State<IncentiveAssignmentsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedTemplateFilter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final provider = context.read<IncentiveProvider>();
    await Future.wait([
      provider.fetchAssignments(forceRefresh: true),
      provider.fetchTemplates(forceRefresh: true),
    ]);
  }

  Future<void> _refreshAssignments() async {
    await context.read<IncentiveProvider>().fetchAssignments(
          forceRefresh: true,
          search: _searchController.text.isEmpty ? null : _searchController.text,
          templateId: _selectedTemplateFilter,
        );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _getCurrentMonth() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  MonthlyProgress? _getCurrentMonthProgress(EmployeeIncentive assignment) {
    final currentMonth = _getCurrentMonth();
    try {
      return assignment.monthlyProgress.firstWhere(
        (p) => p.month == currentMonth,
      );
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF272579), Color(0xFF0071bf)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.assignment_ind_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Incentive Assignments',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                  Text(
                    'Assign brackets to employees',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        foregroundColor: Colors.white,
      ),
      backgroundColor: const Color(0xFFf8f9fa),
      body: Consumer<IncentiveProvider>(
        builder: (context, provider, child) {
          return Column(
            children: [
              // Search and Filter Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Search bar
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: const Color(0xFFf8f9fa),
                        border: Border.all(
                          color:
                              const Color(0xFF272579).withValues(alpha: 0.1),
                        ),
                      ),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search employees...',
                          hintStyle: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 14,
                          ),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            color: const Color(0xFF272579).withValues(alpha: 0.6),
                          ),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: Icon(
                                    Icons.clear_rounded,
                                    color: Colors.grey[600],
                                  ),
                                  onPressed: () {
                                    _searchController.clear();
                                    _refreshAssignments();
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                        onChanged: (value) {
                          Future.delayed(
                            const Duration(milliseconds: 500),
                            () {
                              if (_searchController.text == value) {
                                _refreshAssignments();
                              }
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Template filter - tappable to open bottom sheet
                    GestureDetector(
                      onTap: () => _showTemplateFilterBottomSheet(provider.templates),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: const Color(0xFFf8f9fa),
                          border: Border.all(
                            color:
                                const Color(0xFF272579).withValues(alpha: 0.1),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _getSelectedTemplateName(provider.templates),
                                style: TextStyle(
                                  color: _selectedTemplateFilter == null
                                      ? Colors.grey[500]
                                      : const Color(0xFF272579),
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.arrow_drop_down_rounded,
                              color: Colors.grey[600],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Assignments list
              Expanded(
                child: provider.isAssignmentsLoading && !provider.hasAssignments
                    ? const LoadingWidget(message: 'Loading assignments...')
                    : provider.assignments.isEmpty
                        ? _buildEmptyState()
                        : RefreshIndicator(
                            onRefresh: _refreshAssignments,
                            color: const Color(0xFF272579),
                            child: ListView.builder(
                              padding: const EdgeInsets.all(20),
                              itemCount: provider.assignments.length,
                              itemBuilder: (context, index) {
                                final assignment = provider.assignments[index];
                                return _buildAssignmentCard(assignment);
                              },
                            ),
                          ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            colors: [Color(0xFF272579), Color(0xFF0071bf)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF272579).withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 8),
              spreadRadius: 0,
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: _showAssignDialog,
          backgroundColor: Colors.transparent,
          elevation: 0,
          icon: const Icon(
            Icons.person_add_rounded,
            color: Colors.white,
            size: 20,
          ),
          label: const Text(
            'Assign',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF272579).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.assignment_ind_outlined,
                size: 48,
                color: const Color(0xFF272579).withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Assignments Yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Start assigning incentive templates to employees to track their commissions.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssignmentCard(EmployeeIncentive assignment) {
    final template = assignment.currentTemplate;
    final currentMonthProgress = _getCurrentMonthProgress(assignment);
    final hasPendingPromotion = assignment.pendingPromotion.status == 'pending';
    final dateFormat = DateFormat('dd MMM yyyy');

    // Determine validity badge
    Widget? validityBadge;
    if (assignment.validityStatus == 'expired') {
      validityBadge = Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.access_time_rounded, size: 12, color: Colors.red[700]),
            const SizedBox(width: 4),
            Text(
              'Expired',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.red[700]),
            ),
          ],
        ),
      );
    } else if (assignment.validityStatus == 'future' && assignment.startDate != null) {
      validityBadge = Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.blue.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.schedule_rounded, size: 12, color: Colors.blue[700]),
            const SizedBox(width: 4),
            Text(
              'Starts ${dateFormat.format(assignment.startDate!)}',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.blue[700]),
            ),
          ],
        ),
      );
    } else if (assignment.isCurrentlyActive) {
      validityBadge = Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF5cfbd8).withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline_rounded, size: 12, color: Colors.teal[700]),
            const SizedBox(width: 4),
            Text(
              'Active',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.teal[700]),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: hasPendingPromotion
              ? Colors.orange.withValues(alpha: 0.5)
              : assignment.validityStatus == 'expired'
                  ? Colors.red.withValues(alpha: 0.3)
                  : const Color(0xFF272579).withValues(alpha: 0.06),
          width: hasPendingPromotion || assignment.validityStatus == 'expired' ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with user info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF272579).withValues(alpha: 0.05),
                  const Color(0xFF0071bf).withValues(alpha: 0.03),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                // User Avatar
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF272579), Color(0xFF0071bf)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      assignment.user != null && assignment.user!.firstName.isNotEmpty
                          ? assignment.user!.firstName[0].toUpperCase()
                          : 'U',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        assignment.user?.fullName ?? 'Unknown User',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF272579),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        assignment.user?.employeeId ?? '',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
                // Badges row
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (hasPendingPromotion)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.arrow_upward_rounded,
                              size: 12,
                              color: Colors.orange[700],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Pending',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.orange[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (hasPendingPromotion && validityBadge != null)
                      const SizedBox(height: 4),
                    if (validityBadge != null) validityBadge,
                  ],
                ),
                IconButton(
                  icon: Icon(
                    Icons.more_vert_rounded,
                    color: Colors.grey[600],
                    size: 20,
                  ),
                  onPressed: () => _showAssignmentActionsBottomSheet(assignment),
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Current Template
                Row(
                  children: [
                    Icon(
                      Icons.workspace_premium_rounded,
                      size: 16,
                      color: const Color(0xFF272579).withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Current Bracket:',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0071bf).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        template == null ? 'None' : template.name,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0071bf),
                        ),
                      ),
                    ),
                  ],
                ),

                // Validity Period Row
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFf8f9fa),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.date_range_rounded,
                        size: 14,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Validity: ',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                      Expanded(
                        child: Text(
                          assignment.validityPeriodString,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Current Month Progress
                if (currentMonthProgress != null) ...[
                  _buildProgressBar(currentMonthProgress, template),
                  const SizedBox(height: 12),
                  _buildEarningsRow(currentMonthProgress),
                ] else
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFf8f9fa),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: 16,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'No sales recorded this month',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[500],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(
    MonthlyProgress progress,
    IncentiveTemplate? template,
  ) {
    final targetAmount = template == null ? 0.0 : template.overallTarget.amount.toDouble();
    final achievedAmount = progress.overallSalesAmount;
    final progressPercent =
        targetAmount > 0 ? (achievedAmount / targetAmount).clamp(0.0, 1.0) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'This Month',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${(progressPercent * 100).toStringAsFixed(0)}%',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF272579),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: progressPercent,
            minHeight: 8,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(
              progress.targetAchieved
                  ? const Color(0xFF5cfbd8)
                  : const Color(0xFF0071bf),
            ),
          ),
        ),
        if (targetAmount > 0) ...[
          const SizedBox(height: 4),
          Text(
            'Rs ${_formatAmount(achievedAmount)} / Rs ${_formatAmount(targetAmount)}',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[500],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildEarningsRow(MonthlyProgress progress) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF5cfbd8).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                Icons.monetization_on_rounded,
                size: 18,
                color: const Color(0xFF0071bf),
              ),
              const SizedBox(width: 8),
              const Text(
                'Commission',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF272579),
                ),
              ),
            ],
          ),
          Text(
            'Rs ${_formatAmount(progress.totalCommission)}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF272579),
            ),
          ),
        ],
      ),
    );
  }

  String _formatAmount(double amount) {
    if (amount >= 100000) {
      return '${(amount / 100000).toStringAsFixed(1)}L';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    }
    return amount.toStringAsFixed(0);
  }

  String _getSelectedTemplateName(List<IncentiveTemplate> templates) {
    if (_selectedTemplateFilter == null) {
      return 'All Templates';
    }
    try {
      return templates.firstWhere((t) => t.id == _selectedTemplateFilter).name;
    } catch (e) {
      return 'All Templates';
    }
  }

  void _showTemplateFilterBottomSheet(List<IncentiveTemplate> templates) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.7,
        expand: false,
        builder: (context, scrollController) {
          return Column(
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Filter by Template',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF272579),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(),
              // Options
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    // All Templates option
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0071bf).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.all_inclusive_rounded,
                          color: Color(0xFF0071bf),
                          size: 20,
                        ),
                      ),
                      title: const Text(
                        'All Templates',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF272579),
                        ),
                      ),
                      trailing: _selectedTemplateFilter == null
                          ? const Icon(Icons.check_circle,
                              color: Color(0xFF0071bf))
                          : null,
                      onTap: () {
                        Navigator.pop(context);
                        setState(() => _selectedTemplateFilter = null);
                        _refreshAssignments();
                      },
                    ),
                    const Divider(height: 1),
                    // Template options
                    ...templates.map((template) => ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color:
                                  const Color(0xFF272579).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.workspace_premium_rounded,
                              color: Color(0xFF272579),
                              size: 20,
                            ),
                          ),
                          title: Text(
                            template.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF272579),
                            ),
                          ),
                          trailing: _selectedTemplateFilter == template.id
                              ? const Icon(Icons.check_circle,
                                  color: Color(0xFF0071bf))
                              : null,
                          onTap: () {
                            Navigator.pop(context);
                            setState(() => _selectedTemplateFilter = template.id);
                            _refreshAssignments();
                          },
                        )),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAssignmentActionsBottomSheet(EmployeeIncentive assignment) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // User info header
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF272579), Color(0xFF0071bf)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      assignment.user?.firstName.isNotEmpty == true
                          ? assignment.user!.firstName[0].toUpperCase()
                          : 'U',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        assignment.user?.fullName ?? 'Unknown User',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF272579),
                        ),
                      ),
                      Text(
                        assignment.currentTemplate?.name ?? 'No template',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            // Actions
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0071bf).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.swap_horiz_rounded,
                  color: Color(0xFF0071bf),
                  size: 20,
                ),
              ),
              title: const Text(
                'Change Template',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF272579),
                ),
              ),
              subtitle: Text(
                'Assign a different bracket',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _showChangeTemplateBottomSheet(assignment);
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF272579).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.date_range_rounded,
                  color: Color(0xFF272579),
                  size: 20,
                ),
              ),
              title: const Text(
                'Edit Validity Period',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF272579),
                ),
              ),
              subtitle: Text(
                'Change start and end dates',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _showEditValidityDialog(assignment);
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.refresh_rounded,
                  color: Colors.orange,
                  size: 20,
                ),
              ),
              title: const Text(
                'Recalculate Incentive',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF272579),
                ),
              ),
              subtitle: Text(
                'Refresh commission calculations',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _recalculateIncentive(assignment);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _showAssignDialog() async {
    String? selectedUserId;
    String? selectedTemplateId;
    String? selectedUserName;
    String? selectedTemplateName;
    DateTime startDate = DateTime.now();
    DateTime? endDate;
    bool isOngoing = true;
    List<Map<String, dynamic>> users = [];
    bool isLoadingUsers = true;

    // Load users
    try {
      final response = await ApiService.getAllUsers(limit: 100);
      if (response.success && response.data != null) {
        if (response.data is List) {
          users = List<Map<String, dynamic>>.from(response.data as List);
        } else if (response.data is Map) {
          users = List<Map<String, dynamic>>.from(
              (response.data as Map)['data'] ?? []);
        }
        // Filter out admin users
        users = users
            .where((u) => u['role'] != 'admin' && u['status'] == 'active')
            .toList();
      }
    } catch (e) {
      debugPrint('Error loading users: $e');
    }
    isLoadingUsers = false;

    if (!mounted) return;

    final provider = context.read<IncentiveProvider>();
    final dateFormat = DateFormat('dd MMM yyyy');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Assign Incentive',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF272579),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Employee Selection
                  Text(
                    'Select Employee',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () {
                      _showEmployeeSelectionBottomSheet(
                        users: users,
                        isLoading: isLoadingUsers,
                        selectedUserId: selectedUserId,
                        onSelect: (id, name) {
                          setModalState(() {
                            selectedUserId = id;
                            selectedUserName = name;
                          });
                        },
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF272579).withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              selectedUserName ?? 'Choose employee',
                              style: TextStyle(
                                color: selectedUserName != null
                                    ? const Color(0xFF272579)
                                    : Colors.grey[500],
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.arrow_drop_down_rounded,
                            color: Colors.grey[600],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Template Selection
                  Text(
                    'Select Template',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () {
                      _showTemplateSelectionBottomSheet(
                        templates: provider.templates,
                        selectedTemplateId: selectedTemplateId,
                        onSelect: (id, name) {
                          setModalState(() {
                            selectedTemplateId = id;
                            selectedTemplateName = name;
                          });
                        },
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF272579).withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              selectedTemplateName ?? 'Choose template',
                              style: TextStyle(
                                color: selectedTemplateName != null
                                    ? const Color(0xFF272579)
                                    : Colors.grey[500],
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.arrow_drop_down_rounded,
                            color: Colors.grey[600],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Validity Period Section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF272579).withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF272579).withValues(alpha: 0.1),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.date_range_rounded,
                              size: 18,
                              color: const Color(0xFF272579).withValues(alpha: 0.7),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Validity Period',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[800],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Start Date
                        Text(
                          'Start Date',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 6),
                        GestureDetector(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: startDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2100),
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: const ColorScheme.light(
                                      primary: Color(0xFF272579),
                                      onPrimary: Colors.white,
                                      surface: Colors.white,
                                      onSurface: Colors.black,
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (picked != null) {
                              setModalState(() {
                                startDate = picked;
                                // If end date is before start date, adjust it
                                if (endDate != null && endDate!.isBefore(startDate)) {
                                  endDate = startDate.add(const Duration(days: 30));
                                }
                              });
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.calendar_today_rounded, size: 16, color: Colors.grey[600]),
                                const SizedBox(width: 8),
                                Text(
                                  dateFormat.format(startDate),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF272579),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Ongoing toggle
                        Row(
                          children: [
                            Checkbox(
                              value: isOngoing,
                              onChanged: (value) {
                                setModalState(() {
                                  isOngoing = value ?? true;
                                  if (!isOngoing && endDate == null) {
                                    endDate = startDate.add(const Duration(days: 365));
                                  }
                                });
                              },
                              activeColor: const Color(0xFF272579),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            Text(
                              'Ongoing (no end date)',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),

                        // End Date (only show if not ongoing)
                        if (!isOngoing) ...[
                          const SizedBox(height: 8),
                          Text(
                            'End Date',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 6),
                          GestureDetector(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: endDate ?? startDate.add(const Duration(days: 30)),
                                firstDate: startDate,
                                lastDate: DateTime(2100),
                                builder: (context, child) {
                                  return Theme(
                                    data: Theme.of(context).copyWith(
                                      colorScheme: const ColorScheme.light(
                                        primary: Color(0xFF272579),
                                        onPrimary: Colors.white,
                                        surface: Colors.white,
                                        onSurface: Colors.black,
                                      ),
                                    ),
                                    child: child!,
                                  );
                                },
                              );
                              if (picked != null) {
                                setModalState(() => endDate = picked);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.calendar_today_rounded, size: 16, color: Colors.grey[600]),
                                  const SizedBox(width: 8),
                                  Text(
                                    endDate != null ? dateFormat.format(endDate!) : 'Select end date',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: endDate != null ? const Color(0xFF272579) : Colors.grey[500],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(
                                color: Colors.grey[300]!),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed:
                              selectedUserId != null && selectedTemplateId != null
                                  ? () async {
                                      Navigator.pop(context);
                                      await _assignIncentive(
                                        selectedUserId!,
                                        selectedTemplateId!,
                                        startDate: startDate,
                                        endDate: isOngoing ? null : endDate,
                                      );
                                    }
                                  : null,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor: const Color(0xFF272579),
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: Colors.grey[300],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Assign',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showEmployeeSelectionBottomSheet({
    required List<Map<String, dynamic>> users,
    required bool isLoading,
    required String? selectedUserId,
    required Function(String id, String name) onSelect,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
      builder: (context) {
        String searchQuery = '';
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filteredUsers = users.where((user) {
              final fullName =
                  '${user['firstName']} ${user['lastName']}'.toLowerCase();
              final empId = (user['employeeId'] ?? '').toString().toLowerCase();
              return fullName.contains(searchQuery.toLowerCase()) ||
                  empId.contains(searchQuery.toLowerCase());
            }).toList();

            return DraggableScrollableSheet(
              initialChildSize: 0.7,
              minChildSize: 0.4,
              maxChildSize: 0.9,
              expand: false,
              builder: (context, scrollController) {
                return Column(
                  children: [
                    // Handle bar
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    // Header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Select Employee',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF272579),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ),
                    // Search
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search employees...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                        ),
                        onChanged: (value) {
                          setModalState(() => searchQuery = value);
                        },
                      ),
                    ),
                    const Divider(height: 1),
                    // User list
                    Expanded(
                      child: isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : filteredUsers.isEmpty
                              ? Center(
                                  child: Text(
                                    'No employees found',
                                    style: TextStyle(color: Colors.grey[500]),
                                  ),
                                )
                              : ListView.builder(
                                  controller: scrollController,
                                  itemCount: filteredUsers.length,
                                  itemBuilder: (context, index) {
                                    final user = filteredUsers[index];
                                    final fullName =
                                        '${user['firstName']} ${user['lastName']}';
                                    final isSelected =
                                        user['_id'] == selectedUserId;

                                    return ListTile(
                                      leading: Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF272579)
                                              .withValues(alpha: 0.1),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Center(
                                          child: Text(
                                            (user['firstName'] ?? 'U')[0]
                                                .toUpperCase(),
                                            style: const TextStyle(
                                              color: Color(0xFF272579),
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ),
                                      title: Text(
                                        fullName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF272579),
                                        ),
                                      ),
                                      subtitle: Text(
                                        user['employeeId'] ?? '',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[500],
                                        ),
                                      ),
                                      trailing: isSelected
                                          ? const Icon(Icons.check_circle,
                                              color: Color(0xFF0071bf))
                                          : null,
                                      onTap: () {
                                        Navigator.pop(context);
                                        onSelect(user['_id'], fullName);
                                      },
                                    );
                                  },
                                ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  void _showTemplateSelectionBottomSheet({
    required List<IncentiveTemplate> templates,
    required String? selectedTemplateId,
    required Function(String id, String name) onSelect,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.7,
        expand: false,
        builder: (context, scrollController) {
          return Column(
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Select Template',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF272579),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(),
              // Template list
              Expanded(
                child: templates.isEmpty
                    ? Center(
                        child: Text(
                          'No templates available',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        itemCount: templates.length,
                        itemBuilder: (context, index) {
                          final template = templates[index];
                          final isSelected = template.id == selectedTemplateId;

                          return ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF272579)
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.workspace_premium_rounded,
                                color: Color(0xFF272579),
                                size: 20,
                              ),
                            ),
                            title: Text(
                              template.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF272579),
                              ),
                            ),
                            trailing: isSelected
                                ? const Icon(Icons.check_circle,
                                    color: Color(0xFF0071bf))
                                : null,
                            onTap: () {
                              Navigator.pop(context);
                              onSelect(template.id, template.name);
                            },
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _assignIncentive(
    String userId,
    String templateId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final response = await IncentiveService.assignIncentive(
        userId: userId,
        templateId: templateId,
        startDate: startDate,
        endDate: endDate,
      );

      if (!mounted) return;

      if (response.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Incentive assigned successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _refreshAssignments();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message ?? 'Failed to assign incentive'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showChangeTemplateBottomSheet(EmployeeIncentive assignment) {
    final provider = context.read<IncentiveProvider>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.8,
        expand: false,
        builder: (context, scrollController) {
          return Column(
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Change Template',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF272579),
                            ),
                          ),
                          Text(
                            assignment.user?.fullName ?? 'User',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              // Current template info
              if (assignment.currentTemplate != null)
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0071bf).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        color: Color(0xFF0071bf),
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Current: ${assignment.currentTemplate!.name}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF0071bf),
                        ),
                      ),
                    ],
                  ),
                ),
              const Divider(height: 1),
              // Template list
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: provider.templates.length,
                  itemBuilder: (context, index) {
                    final template = provider.templates[index];
                    final isCurrentTemplate =
                        template.id == assignment.currentTemplateId;

                    return ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isCurrentTemplate
                              ? const Color(0xFF0071bf).withValues(alpha: 0.1)
                              : const Color(0xFF272579).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.workspace_premium_rounded,
                          color: isCurrentTemplate
                              ? const Color(0xFF0071bf)
                              : const Color(0xFF272579),
                          size: 20,
                        ),
                      ),
                      title: Text(
                        template.name,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isCurrentTemplate
                              ? const Color(0xFF0071bf)
                              : const Color(0xFF272579),
                        ),
                      ),
                      trailing: isCurrentTemplate
                          ? Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color:
                                    const Color(0xFF0071bf).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'Current',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF0071bf),
                                ),
                              ),
                            )
                          : const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 16,
                              color: Colors.grey,
                            ),
                      onTap: isCurrentTemplate
                          ? null
                          : () async {
                              Navigator.pop(context);
                              await _assignIncentive(
                                assignment.userId,
                                template.id,
                              );
                            },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEditValidityDialog(EmployeeIncentive assignment) {
    DateTime startDate = assignment.startDate ?? DateTime.now();
    DateTime? endDate = assignment.endDate;
    bool isOngoing = endDate == null;
    final dateFormat = DateFormat('dd MMM yyyy');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Edit Validity Period',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF272579),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              assignment.user?.fullName ?? 'Unknown User',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Validity Period Section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF272579).withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF272579).withValues(alpha: 0.1),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Start Date
                        Text(
                          'Start Date',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 6),
                        GestureDetector(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: startDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2100),
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: const ColorScheme.light(
                                      primary: Color(0xFF272579),
                                      onPrimary: Colors.white,
                                      surface: Colors.white,
                                      onSurface: Colors.black,
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (picked != null) {
                              setModalState(() {
                                startDate = picked;
                                if (endDate != null && endDate!.isBefore(startDate)) {
                                  endDate = startDate.add(const Duration(days: 30));
                                }
                              });
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.calendar_today_rounded, size: 16, color: Colors.grey[600]),
                                const SizedBox(width: 8),
                                Text(
                                  dateFormat.format(startDate),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF272579),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Ongoing toggle
                        Row(
                          children: [
                            Checkbox(
                              value: isOngoing,
                              onChanged: (value) {
                                setModalState(() {
                                  isOngoing = value ?? true;
                                  if (!isOngoing && endDate == null) {
                                    endDate = startDate.add(const Duration(days: 365));
                                  }
                                });
                              },
                              activeColor: const Color(0xFF272579),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            Text(
                              'Ongoing (no end date)',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),

                        // End Date (only show if not ongoing)
                        if (!isOngoing) ...[
                          const SizedBox(height: 8),
                          Text(
                            'End Date',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 6),
                          GestureDetector(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: endDate ?? startDate.add(const Duration(days: 30)),
                                firstDate: startDate,
                                lastDate: DateTime(2100),
                                builder: (context, child) {
                                  return Theme(
                                    data: Theme.of(context).copyWith(
                                      colorScheme: const ColorScheme.light(
                                        primary: Color(0xFF272579),
                                        onPrimary: Colors.white,
                                        surface: Colors.white,
                                        onSurface: Colors.black,
                                      ),
                                    ),
                                    child: child!,
                                  );
                                },
                              );
                              if (picked != null) {
                                setModalState(() => endDate = picked);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.calendar_today_rounded, size: 16, color: Colors.grey[600]),
                                  const SizedBox(width: 8),
                                  Text(
                                    endDate != null ? dateFormat.format(endDate!) : 'Select end date',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: endDate != null ? const Color(0xFF272579) : Colors.grey[500],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(color: Colors.grey[300]!),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            Navigator.pop(context);
                            await _updateAssignmentDates(
                              assignment.userId,
                              startDate,
                              isOngoing ? null : endDate,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor: const Color(0xFF272579),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Save Changes',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _updateAssignmentDates(
    String userId,
    DateTime startDate,
    DateTime? endDate,
  ) async {
    try {
      final response = await IncentiveService.updateAssignmentDates(
        userId: userId,
        startDate: startDate,
        endDate: endDate,
      );

      if (!mounted) return;

      if (response.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Validity period updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _refreshAssignments();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message ?? 'Failed to update validity period'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _recalculateIncentive(EmployeeIncentive assignment) async {
    try {
      final response =
          await IncentiveService.recalculateIncentive(userId: assignment.userId);

      if (!mounted) return;

      if (response.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Incentive recalculated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _refreshAssignments();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message ?? 'Failed to recalculate'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

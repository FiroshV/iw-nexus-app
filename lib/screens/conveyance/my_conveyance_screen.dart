import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import 'submit_conveyance_screen.dart';

class MyConveyanceScreen extends StatefulWidget {
  const MyConveyanceScreen({super.key});

  @override
  State<MyConveyanceScreen> createState() => _MyConveyanceScreenState();
}

class _MyConveyanceScreenState extends State<MyConveyanceScreen> {
  bool _isLoading = true;
  List<dynamic> _claims = [];
  String? _selectedFilter = 'all'; // all, thisMonth, lastMonth, pending, approved, rejected
  double _totalAmount = 0;
  int _pendingCount = 0;

  @override
  void initState() {
    super.initState();
    _loadClaims();
  }

  Future<void> _loadClaims() async {
    setState(() => _isLoading = true);

    try {
      final response = await ApiService.getMyConveyanceClaims();

      if (!mounted) return;

      if (response.success) {
        final data = response.data as Map<String, dynamic>;
        final claims = data['data'] as List<dynamic>? ?? [];
        final summary = data['summary'] as Map<String, dynamic>? ?? {};

        setState(() {
          _claims = claims;
          _totalAmount = (summary['totalAmount'] as num?)?.toDouble() ?? 0.0;
          _pendingCount = claims.where((c) => c['status'] == 'pending').length;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load claims: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<dynamic> _getFilteredClaims() {
    if (_selectedFilter == 'all') {
      return _claims;
    } else if (_selectedFilter == 'pending') {
      return _claims.where((c) => c['status'] == 'pending').toList();
    } else if (_selectedFilter == 'approved') {
      return _claims.where((c) => c['status'] == 'approved').toList();
    } else if (_selectedFilter == 'rejected') {
      return _claims.where((c) => c['status'] == 'rejected').toList();
    }
    return _claims;
  }

  String _getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Pending';
      case 'approved':
        return 'Approved';
      case 'rejected':
        return 'Rejected';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return const Color(0xFF5cfbd8);
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredClaims = _getFilteredClaims();

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
        title: const Text('My Conveyance Claims'),
        centerTitle: false,
      ),
      backgroundColor: const Color(0xFFf8f9fa),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const SubmitConveyanceScreen(),
            ),
          );
          if (result == true) {
            _loadClaims();
          }
        },
        backgroundColor: const Color(0xFF0071bf),
        icon: const Icon(Icons.add),
        label: const Text('New Claim'),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0071bf)),
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadClaims,
              color: const Color(0xFF0071bf),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Summary cards
                    _buildSummaryCard(),
                    const SizedBox(height: 20),

                    // Filter chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip('All', 'all'),
                          const SizedBox(width: 8),
                          _buildFilterChip('Pending', 'pending'),
                          const SizedBox(width: 8),
                          _buildFilterChip('Approved', 'approved'),
                          const SizedBox(width: 8),
                          _buildFilterChip('Rejected', 'rejected'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Claims list
                    if (filteredClaims.isEmpty)
                      _buildEmptyState()
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filteredClaims.length,
                        itemBuilder: (context, index) {
                          final claim = filteredClaims[index];
                          return _buildClaimCard(claim);
                        },
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0071bf), Color(0xFF00b8d9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0071bf).withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem(
            'Total Claimed',
            '₹${_totalAmount.toStringAsFixed(2)}',
            Icons.receipt_long,
          ),
          _buildSummaryItem(
            'Pending',
            _pendingCount.toString(),
            Icons.schedule,
          ),
          _buildSummaryItem(
            'Total Claims',
            _claims.length.toString(),
            Icons.list_alt,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _selectedFilter = value);
      },
      backgroundColor: Colors.white,
      selectedColor: const Color(0xFF0071bf).withValues(alpha: 0.2),
      labelStyle: TextStyle(
        color: isSelected ? const Color(0xFF0071bf) : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
      ),
      side: BorderSide(
        color: isSelected
            ? const Color(0xFF0071bf)
            : Colors.grey[300] ?? Colors.grey,
        width: isSelected ? 2 : 1,
      ),
    );
  }

  Widget _buildClaimCard(dynamic claim) {
    final status = claim['status'] as String? ?? 'pending';
    final date = claim['date'] as String?;
    final amount = claim['amount'] as num?;
    final purpose = claim['purpose'] as String?;
    final approvedAt = claim['approvedAt'] as String?;

    DateTime? parsedDate;
    if (date != null) {
      parsedDate = DateTime.tryParse(date);
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: _getStatusColor(status),
              width: 4,
            ),
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (parsedDate != null)
                          Text(
                            DateFormat('dd MMM yyyy').format(parsedDate),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF272579),
                            ),
                          ),
                        const SizedBox(height: 4),
                        if (amount != null)
                          Text(
                            '₹${amount.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0071bf),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _getStatusColor(status).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      _getStatusLabel(status),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _getStatusColor(status),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Purpose
              if (purpose != null && purpose.isNotEmpty) ...[
                Text(
                  'Purpose',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  purpose,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[800],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
              ],

              // Approval info
              if (status == 'approved' && approvedAt != null) ...[
                Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 16,
                      color: _getStatusColor(status),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Approved on ${DateFormat('dd MMM yyyy').format(DateTime.parse(approvedAt))}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(
              Icons.assignment_outlined,
              size: 80,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              'No claims yet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.grey[700],
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Submit your first conveyance claim',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

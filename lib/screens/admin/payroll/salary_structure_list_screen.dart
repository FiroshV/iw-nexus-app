import 'package:flutter/material.dart';
import '../../../services/payroll_api_service.dart';
import 'salary_structure_form_screen.dart';

/// Admin screen for viewing and managing employee salary structures
class SalaryStructureListScreen extends StatefulWidget {
  const SalaryStructureListScreen({super.key});

  @override
  State<SalaryStructureListScreen> createState() =>
      _SalaryStructureListScreenState();
}

class _SalaryStructureListScreenState extends State<SalaryStructureListScreen> {
  List<Map<String, dynamic>> _salaryStructures = [];
  List<Map<String, dynamic>> _filteredStructures = [];
  bool _isLoading = true;
  String? _error;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSalaryStructures();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSalaryStructures() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final structures = await PayrollApiService.getSalaryStructures();
      setState(() {
        _salaryStructures = structures;
        _filteredStructures = structures;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _filterStructures(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredStructures = _salaryStructures;
      } else {
        _filteredStructures = _salaryStructures.where((structure) {
          final employee = structure['employee'] as Map<String, dynamic>?;
          final name = (employee?['fullName'] ?? '').toLowerCase();
          final empId = (employee?['employeeId'] ?? '').toLowerCase();
          final designation = (employee?['designation'] ?? '').toLowerCase();
          final searchLower = query.toLowerCase();

          return name.contains(searchLower) ||
              empId.contains(searchLower) ||
              designation.contains(searchLower);
        }).toList();
      }
    });
  }

  Future<void> _navigateToForm({Map<String, dynamic>? structure}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SalaryStructureFormScreen(
          salaryStructure: structure,
        ),
      ),
    );

    if (result == true) {
      _loadSalaryStructures();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFf8f9fa),
      appBar: AppBar(
        title: const Text(
          'Salary Structures',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF272579), Color(0xFF0071bf)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSalaryStructures,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF0071bf)),
            )
          : _error != null
              ? _buildErrorState()
              : _salaryStructures.isEmpty
                  ? _buildEmptyState()
                  : Column(
                      children: [
                        _buildSearchBar(),
                        _buildSummaryCard(),
                        Expanded(
                          child: RefreshIndicator(
                            onRefresh: _loadSalaryStructures,
                            color: const Color(0xFF0071bf),
                            child: _filteredStructures.isEmpty
                                ? _buildNoResultsState()
                                : ListView.builder(
                                    padding: const EdgeInsets.all(16),
                                    itemCount: _filteredStructures.length,
                                    itemBuilder: (context, index) {
                                      return _buildSalaryStructureCard(
                                        _filteredStructures[index],
                                      );
                                    },
                                  ),
                          ),
                        ),
                      ],
                    ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToForm(),
        backgroundColor: const Color(0xFF0071bf),
        icon: const Icon(Icons.add),
        label: const Text(
          'Add Salary Structure',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: TextField(
        controller: _searchController,
        onChanged: _filterStructures,
        decoration: InputDecoration(
          hintText: 'Search by name, ID, or designation...',
          prefixIcon: const Icon(Icons.search, color: Color(0xFF0071bf)),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _filterStructures('');
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF0071bf), width: 2),
          ),
          filled: true,
          fillColor: Colors.grey[50],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    final totalEmployees = _salaryStructures.length;
    final totalCtc = _salaryStructures.fold<double>(
      0.0,
      (sum, structure) => sum + (structure['ctc'] as num? ?? 0).toDouble(),
    );
    final avgCtc = totalEmployees > 0 ? totalCtc / totalEmployees : 0.0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0071bf), Color(0xFF00b8d9)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryItem(
              icon: Icons.people,
              label: 'Total Employees',
              value: totalEmployees.toString(),
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.white.withValues(alpha: 0.3),
          ),
          Expanded(
            child: _buildSummaryItem(
              icon: Icons.account_balance_wallet,
              label: 'Avg CTC',
              value: PayrollApiService.formatCurrency(avgCtc),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildSalaryStructureCard(Map<String, dynamic> structure) {
    final employee = structure['employee'] as Map<String, dynamic>?;
    final ctc = (structure['ctc'] as num? ?? 0).toDouble();
    final monthlySalary = ctc / 12;
    final employeeName = employee?['fullName'] ?? 'Unknown';
    final employeeId = employee?['employeeId'] ?? 'N/A';
    final designation = employee?['designation'] ?? 'N/A';
    final effectiveFrom = structure['effectiveFrom'] as String?;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _navigateToForm(structure: structure),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0071bf).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.person,
                      color: Color(0xFF0071bf),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          employeeName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF272579),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$employeeId • $designation',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        PayrollApiService.formatCurrency(ctc),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF5cfbd8),
                        ),
                      ),
                      const Text(
                        'Annual CTC',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildInfoChip(
                      icon: Icons.calendar_month,
                      label: 'Monthly',
                      value: PayrollApiService.formatCurrency(monthlySalary),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildInfoChip(
                      icon: Icons.date_range,
                      label: 'Effective From',
                      value: effectiveFrom ?? 'N/A',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF0071bf)),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF272579),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF0071bf).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.account_balance_wallet_outlined,
                size: 64,
                color: Color(0xFF0071bf),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Salary Structures',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF272579),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start by adding salary structures for your employees',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _navigateToForm(),
              icon: const Icon(Icons.add),
              label: const Text('Add Salary Structure'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0071bf),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No results found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search criteria',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            const Text(
              'Error loading salary structures',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadSalaryStructures,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0071bf),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

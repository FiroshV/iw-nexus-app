import 'package:flutter/material.dart';
import '../../../services/payroll_api_service.dart';
import '../../../services/api_service.dart';
import 'payslip_preview_page.dart';

/// Admin screen for generating payslips for employees
class PayslipGenerationScreen extends StatefulWidget {
  const PayslipGenerationScreen({super.key});

  @override
  State<PayslipGenerationScreen> createState() =>
      _PayslipGenerationScreenState();
}

class _PayslipGenerationScreenState extends State<PayslipGenerationScreen> {
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  bool _isGenerating = false;
  bool _isLoadingPayslips = false;
  List<Map<String, dynamic>> _generatedPayslips = [];
  Map<String, dynamic>? _generationSummary;

  final List<String> _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec'
  ];

  @override
  void initState() {
    super.initState();
    _loadExistingPayslips();
  }

  Future<void> _loadExistingPayslips() async {
    setState(() => _isLoadingPayslips = true);
    try {
      setState(() {
        _generatedPayslips = [];
        _isLoadingPayslips = false;
      });
    } catch (e) {
      setState(() => _isLoadingPayslips = false);
      _showMessage('Error loading payslips: $e', isError: true);
    }
  }

  Future<void> _generatePayslips() async {
    final confirmed = await _showConfirmationDialog();
    if (confirmed != true) return;

    setState(() {
      _isGenerating = true;
      _generationSummary = null;
    });

    try {
      final data = {
        'year': _selectedYear,
        'month': _selectedMonth,
      };

      final result = await PayrollApiService.generatePayslips(data);

      setState(() {
        _generationSummary = result;
        _generatedPayslips = (result['payslips'] as List?)
                ?.map((e) => e as Map<String, dynamic>)
                .toList() ??
            [];
        _isGenerating = false;
      });

      _showMessage(
        'Successfully generated ${result['generated']} payslips!',
      );
    } catch (e) {
      setState(() => _isGenerating = false);
      _showMessage('Failed to generate payslips: $e', isError: true);
    }
  }

  Future<bool?> _showConfirmationDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Payslip Generation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This will generate payslips for:',
              style: TextStyle(color: Colors.grey[700]),
            ),
            const SizedBox(height: 12),
            Text(
              '• Month: ${_months[_selectedMonth - 1]} $_selectedYear',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This action cannot be undone.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0071bf),
              foregroundColor: Colors.white,
            ),
            child: const Text('Generate'),
          ),
        ],
      ),
    );
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : const Color(0xFF5cfbd8),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFf8f9fa),
      appBar: AppBar(
        title: const Text(
          'Generate Payslips',
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
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildPeriodSelector(),
          const SizedBox(height: 16),
          if (_generationSummary != null) _buildSummaryCard(),
          if (_generationSummary != null) const SizedBox(height: 16),
          _buildGenerateButton(),
          const SizedBox(height: 24),
          if (_isLoadingPayslips)
            const Center(
              child: CircularProgressIndicator(color: Color(0xFF0071bf)),
            )
          else if (_generatedPayslips.isNotEmpty) ...[
            _buildPayslipsHeader(),
            const SizedBox(height: 12),
            ..._generatedPayslips.map((payslip) => _buildPayslipCard(payslip)),
          ] else
            _buildEmptyState(),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Period',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF272579),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    isExpanded: true,
                    initialValue: _selectedMonth,
                    decoration: InputDecoration(
                      labelText: 'Month',
                      prefixIcon:
                          const Icon(Icons.calendar_month, color: Color(0xFF0071bf)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide:
                            const BorderSide(color: Color(0xFF0071bf), width: 2),
                      ),
                    ),
                    items: List.generate(12, (index) {
                      return DropdownMenuItem(
                        value: index + 1,
                        child: Text(_months[index]),
                      );
                    }),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedMonth = value);
                        _loadExistingPayslips();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    isExpanded: true,
                    initialValue: _selectedYear,
                    decoration: InputDecoration(
                      labelText: 'Year',
                      prefixIcon:
                          const Icon(Icons.calendar_today, color: Color(0xFF0071bf)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide:
                            const BorderSide(color: Color(0xFF0071bf), width: 2),
                      ),
                    ),
                    items: List.generate(5, (index) {
                      final year = DateTime.now().year - 2 + index;
                      return DropdownMenuItem(
                        value: year,
                        child: Text(year.toString()),
                      );
                    }),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedYear = value);
                        _loadExistingPayslips();
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    final generated = _generationSummary!['generated'] as int? ?? 0;
    final failed = _generationSummary!['failed'] as int? ?? 0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0071bf), Color(0xFF00b8d9)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 28),
                SizedBox(width: 12),
                Text(
                  'Generation Complete',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    icon: Icons.done_all,
                    label: 'Generated',
                    value: generated.toString(),
                  ),
                ),
                if (failed > 0) ...[
                  Container(
                    width: 1,
                    height: 40,
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                  Expanded(
                    child: _buildSummaryItem(
                      icon: Icons.error_outline,
                      label: 'Failed',
                      value: failed.toString(),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
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
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _buildGenerateButton() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.5)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.orange),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'This will generate payslips based on attendance data and salary structures. This action cannot be undone.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isGenerating ? null : _generatePayslips,
                icon: _isGenerating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.play_arrow),
                label: Text(
                  _isGenerating ? 'Generating...' : 'Generate All Payslips',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0071bf),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  disabledBackgroundColor: Colors.grey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPayslipsHeader() {
    return Row(
      children: [
        const Text(
          'Generated Payslips',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF272579),
          ),
        ),
        const Spacer(),
        TextButton.icon(
          onPressed: () {
            _showMessage('Email feature coming soon!');
          },
          icon: const Icon(Icons.email),
          label: const Text('Email All'),
        ),
      ],
    );
  }

  Widget _buildPayslipCard(Map<String, dynamic> payslip) {
    final employeeName = payslip['employeeName'] as String? ?? 'Unknown';
    final netSalary = (payslip['netSalary'] as num?)?.toDouble() ?? 0.0;
    final pdfUrl = payslip['pdfUrl'] as String?;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF0071bf).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.receipt_long,
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
                    PayrollApiService.formatCurrency(netSalary),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF5cfbd8),
                    ),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.visibility, color: Color(0xFF0071bf)),
                  onPressed: () {
                    _showMessage('View feature coming soon!');
                  },
                  tooltip: 'View',
                ),
                IconButton(
                  icon: const Icon(Icons.download, color: Color(0xFF00b8d9)),
                  onPressed: pdfUrl != null
                      ? () {
                          _showMessage('Download feature coming soon!');
                        }
                      : null,
                  tooltip: 'Download',
                ),
                IconButton(
                  icon: const Icon(Icons.email, color: Color(0xFF5cfbd8)),
                  onPressed: () {
                    _showMessage('Email feature coming soon!');
                  },
                  tooltip: 'Email',
                ),
              ],
            ),
          ],
        ),
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
                Icons.receipt_long_outlined,
                size: 64,
                color: Color(0xFF0071bf),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Payslips Generated',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF272579),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Generate payslips for ${_months[_selectedMonth - 1]} $_selectedYear',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Content widget for payslip generation (used in tabbed interface)
class PayslipGenerationContent extends StatefulWidget {
  const PayslipGenerationContent({super.key});

  @override
  State<PayslipGenerationContent> createState() =>
      _PayslipGenerationContentState();
}

class _PayslipGenerationContentState extends State<PayslipGenerationContent> {
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  bool _isLoadingEmployees = false;
  bool _isLoadingPayslips = false;
  String? _loadError;
  List<Map<String, dynamic>> _allEmployees = [];
  List<Map<String, dynamic>> _filteredEmployees = [];
  Set<String> _selectedEmployeeIds = {};
  Set<String> _generatedPayslipIds = {};
  String _searchQuery = '';

  final List<String> _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec'
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await _loadEmployees();
    await _loadGeneratedPayslips();
  }

  Future<void> _loadEmployees() async {
    debugPrint('🔄 Starting to load employees...');
    setState(() {
      _isLoadingEmployees = true;
      _loadError = null;
    });
    try {
      final response = await ApiService.getAllUsers();
      debugPrint('📡 API Response - Success: ${response.success}, Data type: ${response.data.runtimeType}');

      if (response.success && response.data != null) {
        List<Map<String, dynamic>> users = [];
        if (response.data is List) {
          users = List<Map<String, dynamic>>.from(response.data as List);
          debugPrint('✅ Data is List format: ${users.length} users');
        } else if (response.data is Map<String, dynamic>) {
          final responseMap = response.data as Map<String, dynamic>;
          users = List<Map<String, dynamic>>.from(responseMap['data'] ?? []);
          debugPrint('✅ Data is Map format: ${users.length} users');
        }

        // Filter out admin users
        final filtered = users.where((user) => user['role'] != 'admin').toList();
        debugPrint('✅ After filtering admins: ${filtered.length} employees');

        if (mounted) {
          setState(() {
            _allEmployees = filtered;
            _filteredEmployees = List.from(_allEmployees); // Ensure filteredEmployees is set
            _isLoadingEmployees = false;
            _loadError = null;
            debugPrint('✅ State updated - _allEmployees: ${_allEmployees.length}, _filteredEmployees: ${_filteredEmployees.length}');
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoadingEmployees = false;
            _loadError = response.message;
          });
        }
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error loading employees: $e');
      debugPrint('Stack: $stackTrace');
      if (mounted) {
        setState(() {
          _isLoadingEmployees = false;
          _loadError = 'Error: $e';
        });
      }
    }
  }

  Future<void> _loadGeneratedPayslips() async {
    setState(() {
      _isLoadingPayslips = true;
      _generatedPayslipIds.clear(); // Clear stale data immediately
    });
    try {
      final payslips = await PayrollApiService.getPayslipsForMonth(
        month: _selectedMonth,
        year: _selectedYear,
      );

      if (mounted) {
        setState(() {
          _generatedPayslipIds = {
            for (final p in payslips) p['employeeId']['_id'].toString()
          };
          _isLoadingPayslips = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingPayslips = false);
        debugPrint('Error loading payslips: $e');
      }
    }
  }

  void _filterEmployees(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
      if (_searchQuery.isEmpty) {
        _filteredEmployees = List.from(_allEmployees);
      } else {
        _filteredEmployees = _allEmployees.where((employee) {
          final firstName = (employee['firstName'] ?? '').toLowerCase();
          final lastName = (employee['lastName'] ?? '').toLowerCase();
          final employeeId = (employee['employeeId'] ?? '').toLowerCase();
          final designation = (employee['designation'] ?? '').toLowerCase();

          return firstName.contains(_searchQuery) ||
              lastName.contains(_searchQuery) ||
              employeeId.contains(_searchQuery) ||
              designation.contains(_searchQuery);
        }).toList();
      }
    });
  }

  void _toggleSelection(String employeeId) {
    setState(() {
      if (_selectedEmployeeIds.contains(employeeId)) {
        _selectedEmployeeIds.remove(employeeId);
      } else {
        _selectedEmployeeIds.add(employeeId);
      }
    });
  }

  void _selectAll() {
    setState(() {
      _selectedEmployeeIds = {
        for (final emp in _filteredEmployees) emp['_id'].toString()
      };
    });
  }

  void _deselectAll() {
    setState(() => _selectedEmployeeIds.clear());
  }

  Future<void> _viewPayslipDetails(Map<String, dynamic> employee) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => PayslipPreviewPage(
          employee: employee,
          month: _selectedMonth,
          year: _selectedYear,
          onGenerateSuccess: () {
            _loadGeneratedPayslips();
          },
        ),
      ),
    );

    if (result == true && mounted) {
      await _loadGeneratedPayslips();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = _isLoadingEmployees || _isLoadingPayslips;
    final hasError = _loadError != null;
    final hasEmployees = _allEmployees.isNotEmpty;
    final configuredCount = _allEmployees.where((e) => _generatedPayslipIds.contains(e['_id'])).length;
    final pendingCount = _allEmployees.length - configuredCount;

    return Column(
      children: [
        // Compact Period & Refresh Bar
        _buildPeriodBar(),

        // Main Content
        Expanded(
          child: hasError
              ? _buildErrorState()
              : isLoading
                  ? _buildLoadingState()
                  : !hasEmployees
                      ? _buildEmptyDataState()
                      : _buildEmployeesList(configuredCount, pendingCount),
        ),
      ],
    );
  }

  Widget _buildPeriodBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step indicator and title
          const Text(
            'Step 1: Select Payroll Period',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF272579),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              // Month dropdown
              Expanded(
                flex: 1,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFe0e0e0)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButton<int>(
                    isExpanded: true,
                    value: _selectedMonth,
                    underline: const SizedBox(),
                    items: List.generate(12, (index) {
                      return DropdownMenuItem(
                        value: index + 1,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(_months[index]),
                        ),
                      );
                    }),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedMonth = value);
                        _loadGeneratedPayslips();
                        _selectedEmployeeIds.clear();
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Year dropdown
              Expanded(
                flex: 1,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFe0e0e0)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButton<int>(
                    isExpanded: true,
                    value: _selectedYear,
                    underline: const SizedBox(),
                    items: List.generate(5, (index) {
                      final year = DateTime.now().year - 2 + index;
                      return DropdownMenuItem(
                        value: year,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(year.toString()),
                        ),
                      );
                    }),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedYear = value);
                        _loadGeneratedPayslips();
                        _selectedEmployeeIds.clear();
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Refresh button
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFe0e0e0)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  icon: const Icon(Icons.refresh, color: Color(0xFF0071bf)),
                  onPressed: _loadData,
                  tooltip: 'Refresh',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 40),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            Icons.error_outline,
            size: 48,
            color: Colors.red[400],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Failed to Load Employees',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: const Color(0xFF272579),
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _loadError!,
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey[600]),
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: _loadData,
          icon: const Icon(Icons.refresh),
          label: const Text('Try Again'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0071bf),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Color(0xFF0071bf)),
          const SizedBox(height: 16),
          Text(
            'Loading employees...',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyDataState() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 40),
        Icon(
          Icons.people_outline,
          size: 64,
          color: Colors.grey[300],
        ),
        const SizedBox(height: 16),
        Text(
          'No Employees Found',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: const Color(0xFF272579),
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'There are no employees to generate payslips for.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildEmployeesList(int configuredCount, int pendingCount) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Search bar
        _buildSearchBar(),
        const SizedBox(height: 12),

        // Summary card
        _buildSummaryCard(configuredCount, pendingCount),
        const SizedBox(height: 12),

        // Action buttons (only show when employees are loaded)
        _buildActionBar(),
        const SizedBox(height: 12),

        // Selection badge (only show when something is selected)
        if (_selectedEmployeeIds.isNotEmpty)
          _buildSelectedBadge(),

        if (_selectedEmployeeIds.isNotEmpty)
          const SizedBox(height: 12),

        // Employee list
        if (_filteredEmployees.isEmpty)
          _buildNoResultsState()
        else
          ..._filteredEmployees.map((employee) => _buildEmployeeCard(employee)),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Search Employees',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF272579),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          onChanged: _filterEmployees,
          decoration: InputDecoration(
            hintText: 'Search by name, ID, or designation...',
            hintStyle: TextStyle(color: Colors.grey[500]),
            prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear, color: Colors.grey[600]),
                    onPressed: () {
                      _filterEmployees('');
                    },
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFe0e0e0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFe0e0e0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFF0071bf),
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(int configuredCount, int pendingCount) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0071bf), Color(0xFF00b8d9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem(
            icon: Icons.people,
            label: 'Total',
            value: _allEmployees.length.toString(),
            color: Colors.white,
          ),
          Container(width: 1, height: 40, color: Colors.white.withValues(alpha: 0.3)),
          _buildSummaryItem(
            icon: Icons.check_circle,
            label: 'Generated',
            value: configuredCount.toString(),
            color: Colors.white,
          ),
          Container(width: 1, height: 40, color: Colors.white.withValues(alpha: 0.3)),
          _buildSummaryItem(
            icon: Icons.pending,
            label: 'Pending',
            value: pendingCount.toString(),
            color: Colors.white,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: color.withValues(alpha: 0.8),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildActionBar() {
    final allProcessed = _allEmployees.every((e) => _generatedPayslipIds.contains(e['_id']));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Step indicator
        const Text(
          'Step 2: Select Employees',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF272579),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),

        // Select/Deselect buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _filteredEmployees.length == _selectedEmployeeIds.length
                    ? _deselectAll
                    : _selectAll,
                icon: Icon(
                  _filteredEmployees.length == _selectedEmployeeIds.length
                      ? Icons.deselect
                      : Icons.done_all,
                ),
                label: Text(
                  _filteredEmployees.length == _selectedEmployeeIds.length
                      ? 'Deselect All'
                      : 'Select All',
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF0071bf),
                  side: const BorderSide(color: Color(0xFF0071bf)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Action buttons
        Row(
          children: [
            // Generate Selected button
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _selectedEmployeeIds.isEmpty ? null : _generateSelectedPayslips,
                icon: const Icon(Icons.check_circle),
                label: const Text('Generate Selected'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _selectedEmployeeIds.isEmpty ? Colors.grey : const Color(0xFF0071bf),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Generate All button
            Expanded(
              child: ElevatedButton.icon(
                onPressed: allProcessed ? null : _generateAllPayslips,
                icon: const Icon(Icons.done_all),
                label: const Text('Generate All'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: allProcessed ? Colors.grey : const Color(0xFF00b8d9),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _generateSelectedPayslips() async {
    if (_selectedEmployeeIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one employee'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final confirmed = await _showBulkGenerationDialog('Selected', _selectedEmployeeIds.length);
    if (confirmed != true) return;

    _generatePayslipsForEmployees(_selectedEmployeeIds.toList());
  }

  Future<void> _generateAllPayslips() async {
    final pendingEmployees = _allEmployees
        .where((e) => !_generatedPayslipIds.contains(e['_id']))
        .map((e) => e['_id'] as String)
        .toList();

    if (pendingEmployees.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All payslips have already been generated'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final confirmed = await _showBulkGenerationDialog('All Pending', pendingEmployees.length);
    if (confirmed != true) return;

    _generatePayslipsForEmployees(pendingEmployees);
  }

  Future<bool?> _showBulkGenerationDialog(String type, int count) {
    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildGenerationBottomSheet(type, count),
    );
  }

  Widget _buildGenerationBottomSheet(String type, int count) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Header with icon
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0071bf).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.receipt_long,
                      color: Color(0xFF0071bf),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Generate Payslips',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF272579),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Generate $type Payslips',
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
              const SizedBox(height: 24),

              // Details section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0071bf).withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF0071bf).withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow('Employees', count.toString()),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      'Month',
                      '${_months[_selectedMonth - 1]} $_selectedYear',
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      'Type',
                      type == 'Selected' ? 'Selected Employees' : 'All Pending Employees',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Info message
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.orange.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.only(top: 2),
                      child: Icon(
                        Icons.info_outline,
                        color: Colors.orange[700],
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'This process may take a few minutes depending on the number of payslips being generated.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange[700],
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF0071bf),
                        side: const BorderSide(color: Color(0xFF0071bf)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
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
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context, true),
                      icon: const Icon(Icons.check_circle),
                      label: const Text('Generate'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0071bf),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
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
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Color(0xFF272579),
          ),
        ),
      ],
    );
  }

  Future<void> _generatePayslipsForEmployees(List<String> employeeIds) async {
    setState(() {
      // Show loading indicator
    });

    try {
      int successCount = 0;
      int failedCount = 0;

      for (final employeeId in employeeIds) {
        try {
          await PayrollApiService.generatePayslip({
            'employeeId': employeeId,
            'month': _selectedMonth,
            'year': _selectedYear,
          });
          successCount++;
        } catch (e) {
          failedCount++;
          debugPrint('Error generating payslip for $employeeId: $e');
        }
      }

      if (mounted) {
        final currentContext = context;
        await _loadGeneratedPayslips();
        _selectedEmployeeIds.clear();

        if (!mounted) return;
        ScaffoldMessenger.of(currentContext).showSnackBar(
          SnackBar(
            content: Text(
              failedCount == 0
                  ? 'Successfully generated $successCount payslips!'
                  : 'Generated $successCount payslips. Failed: $failedCount',
            ),
            backgroundColor: failedCount == 0 ? const Color(0xFF5cfbd8) : Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      final currentContextError = context;
      ScaffoldMessenger.of(currentContextError).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildSelectedBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0071bf).withValues(alpha: 0.1),
        border: Border.all(color: const Color(0xFF0071bf), width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            color: const Color(0xFF0071bf),
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${_selectedEmployeeIds.length} employee${_selectedEmployeeIds.length > 1 ? 's' : ''} selected',
              style: const TextStyle(
                color: Color(0xFF0071bf),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.search_off,
              size: 48,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 12),
            Text(
              'No results for "$_searchQuery"',
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

  Widget _buildEmployeeCard(Map<String, dynamic> employee) {
    final isGenerated = _generatedPayslipIds.contains(employee['_id']);
    final isSelected = _selectedEmployeeIds.contains(employee['_id']);
    final firstName = employee['firstName'] ?? '';
    final lastName = employee['lastName'] ?? '';
    final initial = firstName.isNotEmpty ? firstName[0].toUpperCase() : 'E';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF0071bf)
                : const Color(0xFFe0e0e0),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Checkbox
              Checkbox(
                value: isSelected,
                onChanged: (_) => _toggleSelection(employee['_id']),
                activeColor: const Color(0xFF0071bf),
              ),
              const SizedBox(width: 8),

              // Avatar
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: employee['avatar'] != null
                      ? null
                      : const LinearGradient(
                          colors: [Color(0xFF272579), Color(0xFF0071bf)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: employee['avatar'] != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          employee['avatar'],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Center(
                              child: Text(
                                initial,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            );
                          },
                        ),
                      )
                    : Center(
                        child: Text(
                          initial,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 12),

              // Employee Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$firstName $lastName',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${employee['employeeId']} • ${employee['designation'] ?? 'N/A'}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: isGenerated
                            ? const Color(0xFF5cfbd8).withValues(alpha: 0.2)
                            : Colors.orange.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        isGenerated ? '✓ Generated' : '⏳ Pending',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isGenerated
                              ? const Color(0xFF272579)
                              : Colors.orange[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Action Button
              IconButton(
                icon: const Icon(Icons.visibility, color: Color(0xFF0071bf)),
                onPressed: () => _viewPayslipDetails(employee),
                tooltip: 'View Details',
              ),
            ],
          ),
        ),
      ),
    );
  }

}

import 'package:flutter/material.dart';
import '../../../services/payroll_api_service.dart';

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
  String? _selectedBranchId;

  bool _isGenerating = false;
  bool _isLoadingPayslips = false;
  List<Map<String, dynamic>> _generatedPayslips = [];
  Map<String, dynamic>? _generationSummary;

  final List<String> _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December'
  ];

  @override
  void initState() {
    super.initState();
    _loadExistingPayslips();
  }

  Future<void> _loadExistingPayslips() async {
    setState(() => _isLoadingPayslips = true);
    try {
      // TODO: Load existing payslips for the selected month/year
      // For now, just set to empty
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
        if (_selectedBranchId != null) 'branchId': _selectedBranchId,
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
            Text(
              '• Branch: ${_selectedBranchId ?? 'All Branches'}',
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
            const SizedBox(height: 16),
            DropdownButtonFormField<String?>(
              initialValue: _selectedBranchId,
              decoration: InputDecoration(
                labelText: 'Branch (Optional)',
                prefixIcon: const Icon(Icons.business, color: Color(0xFF0071bf)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF0071bf), width: 2),
                ),
              ),
              items: const [
                DropdownMenuItem(value: null, child: Text('All Branches')),
                // TODO: Load actual branches
              ],
              onChanged: (value) {
                setState(() => _selectedBranchId = value);
                _loadExistingPayslips();
              },
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
            // TODO: Implement email all
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
                    // TODO: Navigate to payslip detail
                    _showMessage('View feature coming soon!');
                  },
                  tooltip: 'View',
                ),
                IconButton(
                  icon: const Icon(Icons.download, color: Color(0xFF00b8d9)),
                  onPressed: pdfUrl != null
                      ? () {
                          // TODO: Download PDF
                          _showMessage('Download feature coming soon!');
                        }
                      : null,
                  tooltip: 'Download',
                ),
                IconButton(
                  icon: const Icon(Icons.email, color: Color(0xFF5cfbd8)),
                  onPressed: () {
                    // TODO: Send email
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

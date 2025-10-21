import 'package:flutter/material.dart';
import '../../../services/payroll_api_service.dart';
import '../../../services/api_service.dart';

/// Admin screen for creating/editing employee salary structure
class SalaryStructureFormScreen extends StatefulWidget {
  final Map<String, dynamic>? salaryStructure;

  const SalaryStructureFormScreen({super.key, this.salaryStructure});

  @override
  State<SalaryStructureFormScreen> createState() =>
      _SalaryStructureFormScreenState();
}

class _SalaryStructureFormScreenState extends State<SalaryStructureFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isSaving = false;

  // Employee selection
  Map<String, dynamic>? _selectedEmployee;
  List<Map<String, dynamic>> _employees = [];

  // Form controllers
  final _ctcController = TextEditingController();
  final _effectiveFromController = TextEditingController();
  final _basicController = TextEditingController();
  final _hraController = TextEditingController();
  final _daController = TextEditingController();
  final _conveyanceController = TextEditingController();
  final _specialAllowanceController = TextEditingController();
  final _otherAllowancesController = TextEditingController();
  final _tdsController = TextEditingController();
  final _loanDeductionController = TextEditingController();

  bool _pfApplicable = true;
  bool _esiApplicable = false;
  bool _ptApplicable = true;
  final bool _usePercentages = true;

  @override
  void initState() {
    super.initState();
    _loadEmployees();
    _initializeForm();
  }

  void _initializeForm() {
    if (widget.salaryStructure != null) {
      final structure = widget.salaryStructure!;
      _selectedEmployee = structure['employee'] as Map<String, dynamic>?;

      _ctcController.text = (structure['ctc'] as num?)?.toString() ?? '';
      _effectiveFromController.text = structure['effectiveFrom'] as String? ?? '';

      final earnings = structure['earnings'] as Map<String, dynamic>? ?? {};
      _basicController.text = (earnings['basic'] as num?)?.toString() ?? '';
      _hraController.text = (earnings['hra'] as num?)?.toString() ?? '';
      _daController.text = (earnings['da'] as num?)?.toString() ?? '';
      _conveyanceController.text =
          (earnings['conveyance'] as num?)?.toString() ?? '';
      _specialAllowanceController.text =
          (earnings['specialAllowance'] as num?)?.toString() ?? '';
      _otherAllowancesController.text =
          (earnings['otherAllowances'] as num?)?.toString() ?? '';

      final deductions = structure['deductions'] as Map<String, dynamic>? ?? {};
      _pfApplicable = deductions['pfApplicable'] as bool? ?? true;
      _esiApplicable = deductions['esiApplicable'] as bool? ?? false;
      _ptApplicable = deductions['professionalTax'] as bool? ?? true;
      _tdsController.text = (deductions['tdsMonthly'] as num?)?.toString() ?? '0';
      _loanDeductionController.text =
          (deductions['loanDeduction'] as num?)?.toString() ?? '0';
    } else {
      _tdsController.text = '0';
      _loanDeductionController.text = '0';
    }
  }

  Future<void> _loadEmployees() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.getAllUsers();
      final users = response.data as List<dynamic>;
      setState(() {
        _employees = users.map((e) => e as Map<String, dynamic>).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showMessage('Error loading employees: $e', isError: true);
    }
  }

  @override
  void dispose() {
    _ctcController.dispose();
    _effectiveFromController.dispose();
    _basicController.dispose();
    _hraController.dispose();
    _daController.dispose();
    _conveyanceController.dispose();
    _specialAllowanceController.dispose();
    _otherAllowancesController.dispose();
    _tdsController.dispose();
    _loanDeductionController.dispose();
    super.dispose();
  }

  void _calculateFromCTC() {
    if (_ctcController.text.isEmpty) return;

    final ctc = double.tryParse(_ctcController.text);
    if (ctc == null) return;

    if (_usePercentages) {
      // Use default percentages: Basic 40%, HRA 30%, DA 10%, Conveyance 5%, Special 15%
      setState(() {
        _basicController.text = (ctc * 0.40).toStringAsFixed(2);
        _hraController.text = (ctc * 0.30).toStringAsFixed(2);
        _daController.text = (ctc * 0.10).toStringAsFixed(2);
        _conveyanceController.text = (ctc * 0.05).toStringAsFixed(2);
        _specialAllowanceController.text = (ctc * 0.15).toStringAsFixed(2);
        _otherAllowancesController.text = '0';
      });
    }
  }

  double _calculateTotal() {
    final basic = double.tryParse(_basicController.text) ?? 0;
    final hra = double.tryParse(_hraController.text) ?? 0;
    final da = double.tryParse(_daController.text) ?? 0;
    final conveyance = double.tryParse(_conveyanceController.text) ?? 0;
    final special = double.tryParse(_specialAllowanceController.text) ?? 0;
    final other = double.tryParse(_otherAllowancesController.text) ?? 0;
    return basic + hra + da + conveyance + special + other;
  }

  double _calculatePF() {
    final basic = double.tryParse(_basicController.text) ?? 0;
    final da = double.tryParse(_daController.text) ?? 0;
    return (basic + da) * 0.12;
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF0071bf),
              onPrimary: Colors.white,
              onSurface: Color(0xFF272579),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _effectiveFromController.text =
            '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _saveSalaryStructure() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedEmployee == null) {
      _showMessage('Please select an employee', isError: true);
      return;
    }

    setState(() => _isSaving = true);

    try {
      final data = {
        'employeeId': _selectedEmployee!['_id'],
        'ctc': double.parse(_ctcController.text),
        'effectiveFrom': _effectiveFromController.text,
        'earnings': {
          'basic': double.parse(_basicController.text),
          'hra': double.parse(_hraController.text),
          'da': double.parse(_daController.text),
          'conveyance': double.parse(_conveyanceController.text),
          'specialAllowance': double.parse(_specialAllowanceController.text),
          'otherAllowances': double.parse(_otherAllowancesController.text),
        },
        'deductions': {
          'pfApplicable': _pfApplicable,
          'pfEmployee': 12,
          'pfEmployer': 12,
          'esiApplicable': _esiApplicable,
          'professionalTax': _ptApplicable,
          'tdsMonthly': double.parse(_tdsController.text),
          'loanDeduction': double.parse(_loanDeductionController.text),
        },
      };

      await PayrollApiService.updateSalaryStructure(
        _selectedEmployee!['_id'] as String,
        data,
      );

      if (mounted) {
        _showMessage('Salary structure saved successfully!');
        Navigator.pop(context, true);
      }
    } catch (e) {
      _showMessage('Failed to save: $e', isError: true);
    } finally {
      setState(() => _isSaving = false);
    }
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
    final isEdit = widget.salaryStructure != null;

    return Scaffold(
      backgroundColor: const Color(0xFFf8f9fa),
      appBar: AppBar(
        title: Text(
          isEdit ? 'Edit Salary Structure' : 'Add Salary Structure',
          style: const TextStyle(fontWeight: FontWeight.w700),
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
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF0071bf)),
            )
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildEmployeeSelection(),
                  const SizedBox(height: 16),
                  _buildCTCSection(),
                  const SizedBox(height: 16),
                  _buildEarningsSection(),
                  const SizedBox(height: 16),
                  _buildDeductionsSection(),
                  const SizedBox(height: 24),
                  _buildSaveButton(),
                ],
              ),
            ),
    );
  }

  Widget _buildEmployeeSelection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Employee Selection',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF272579),
              ),
            ),
            const SizedBox(height: 16),
            if (_selectedEmployee != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0071bf).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF0071bf).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.person, color: Color(0xFF0071bf)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedEmployee!['fullName'] ?? 'Unknown',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF272579),
                            ),
                          ),
                          Text(
                            '${_selectedEmployee!['employeeId'] ?? 'N/A'} • ${_selectedEmployee!['designation'] ?? 'N/A'}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (widget.salaryStructure == null)
                      IconButton(
                        icon: const Icon(Icons.edit, color: Color(0xFF0071bf)),
                        onPressed: () => _showEmployeeSelector(),
                      ),
                  ],
                ),
              )
            else
              ElevatedButton.icon(
                onPressed: _showEmployeeSelector,
                icon: const Icon(Icons.person_add),
                label: const Text('Select Employee'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0071bf),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showEmployeeSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          maxChildSize: 0.9,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Color(0xFF0071bf),
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Row(
                    children: [
                      const Text(
                        'Select Employee',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: _employees.length,
                    itemBuilder: (context, index) {
                      final employee = _employees[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              const Color(0xFF0071bf).withValues(alpha: 0.1),
                          child: Text(
                            (employee['fullName'] as String?)
                                    ?.substring(0, 1)
                                    .toUpperCase() ??
                                'U',
                            style: const TextStyle(
                              color: Color(0xFF0071bf),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        title: Text(employee['fullName'] ?? 'Unknown'),
                        subtitle: Text(
                          '${employee['employeeId'] ?? 'N/A'} • ${employee['designation'] ?? 'N/A'}',
                        ),
                        onTap: () {
                          setState(() => _selectedEmployee = employee);
                          Navigator.pop(context);
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
  }

  Widget _buildCTCSection() {
    final total = _calculateTotal();
    final ctc = double.tryParse(_ctcController.text) ?? 0;
    final isValid = (total - ctc).abs() < 0.01;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'CTC & Effective Date',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF272579),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _ctcController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Annual CTC (₹)',
                prefixIcon: const Icon(Icons.currency_rupee, color: Color(0xFF0071bf)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF0071bf), width: 2),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Required';
                }
                if (double.tryParse(value) == null) {
                  return 'Invalid amount';
                }
                return null;
              },
              onChanged: (_) => _calculateFromCTC(),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _effectiveFromController,
              readOnly: true,
              decoration: InputDecoration(
                labelText: 'Effective From',
                prefixIcon: const Icon(Icons.calendar_today, color: Color(0xFF0071bf)),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.edit_calendar),
                  onPressed: _selectDate,
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF0071bf), width: 2),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Required';
                }
                return null;
              },
              onTap: _selectDate,
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _calculateFromCTC,
              icon: const Icon(Icons.calculate),
              label: const Text('Auto-Calculate Components'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00b8d9),
                foregroundColor: Colors.white,
              ),
            ),
            if (ctc > 0) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isValid
                      ? const Color(0xFF5cfbd8).withValues(alpha: 0.1)
                      : Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isValid ? const Color(0xFF5cfbd8) : Colors.red,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isValid ? Icons.check_circle : Icons.error,
                      color: isValid ? const Color(0xFF5cfbd8) : Colors.red,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Total Components',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            PayrollApiService.formatCurrency(total),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: isValid ? const Color(0xFF5cfbd8) : Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!isValid)
                      Text(
                        'Mismatch!',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEarningsSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Earnings Breakdown (Annual)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF272579),
              ),
            ),
            const SizedBox(height: 16),
            _buildAmountField(_basicController, 'Basic Salary', Icons.account_balance_wallet),
            const SizedBox(height: 12),
            _buildAmountField(_hraController, 'HRA', Icons.home),
            const SizedBox(height: 12),
            _buildAmountField(_daController, 'DA', Icons.payments),
            const SizedBox(height: 12),
            _buildAmountField(_conveyanceController, 'Conveyance', Icons.directions_car),
            const SizedBox(height: 12),
            _buildAmountField(
                _specialAllowanceController, 'Special Allowance', Icons.star),
            const SizedBox(height: 12),
            _buildAmountField(
                _otherAllowancesController, 'Other Allowances', Icons.add_circle),
          ],
        ),
      ),
    );
  }

  Widget _buildDeductionsSection() {
    final pfAmount = _calculatePF();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Deductions',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF272579),
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('PF Applicable'),
              subtitle: Text(
                'Employee: ${PayrollApiService.formatCurrency(pfAmount)} | Employer: ${PayrollApiService.formatCurrency(pfAmount)}',
                style: const TextStyle(fontSize: 12),
              ),
              value: _pfApplicable,
              activeTrackColor: const Color(0xFF0071bf),
              onChanged: (value) => setState(() => _pfApplicable = value),
            ),
            SwitchListTile(
              title: const Text('ESI Applicable'),
              subtitle: const Text('For salary ≤ ₹21,000/month'),
              value: _esiApplicable,
              activeTrackColor: const Color(0xFF0071bf),
              onChanged: (value) => setState(() => _esiApplicable = value),
            ),
            SwitchListTile(
              title: const Text('Professional Tax'),
              subtitle: const Text('State-based taxation'),
              value: _ptApplicable,
              activeTrackColor: const Color(0xFF0071bf),
              onChanged: (value) => setState(() => _ptApplicable = value),
            ),
            const SizedBox(height: 12),
            _buildAmountField(_tdsController, 'Monthly TDS', Icons.receipt),
            const SizedBox(height: 12),
            _buildAmountField(
                _loanDeductionController, 'Loan Deduction', Icons.money_off),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountField(
      TextEditingController controller, String label, IconData icon) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF0071bf)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF0071bf), width: 2),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Required';
        }
        if (double.tryParse(value) == null) {
          return 'Invalid amount';
        }
        return null;
      },
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveSalaryStructure,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0071bf),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          disabledBackgroundColor: Colors.grey,
        ),
        child: _isSaving
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Text(
                'Save Salary Structure',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}

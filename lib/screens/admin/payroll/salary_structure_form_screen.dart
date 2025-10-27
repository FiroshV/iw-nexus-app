import 'package:flutter/material.dart';
import '../../../services/payroll_api_service.dart';
import '../../../services/api_service.dart';
import '../edit_user_screen.dart';

/// Admin screen for creating/editing employee salary structure
class SalaryStructureFormScreen extends StatefulWidget {
  final Map<String, dynamic>? salaryStructure;
  final String? userId;
  final String? userName;

  const SalaryStructureFormScreen({
    super.key,
    this.salaryStructure,
    this.userId,
    this.userName,
  });

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
    _loadEmployeesAndInitialize();
  }

  Future<void> _loadEmployeesAndInitialize() async {
    // Load employees first
    await _loadEmployees();

    // If userId is provided but no salaryStructure, fetch from backend
    if (widget.userId != null && widget.salaryStructure == null) {
      await _loadSalaryStructureFromBackend(widget.userId!);
    }

    // Then initialize the form after employees are loaded
    if (mounted) {
      setState(() {
        _initializeForm();
      });
    }
  }

  /// Load salary structure from backend API and pre-fill form
  Future<void> _loadSalaryStructureFromBackend(String userId) async {
    try {
      debugPrint('🔄 Fetching salary structure from backend for user: $userId');
      final structure = await PayrollApiService.getSalaryStructure(userId);

      if (structure != null) {
        debugPrint('✅ Salary structure fetched from backend');
        // Pre-populate the form with loaded structure
        _ctcController.text = (structure['ctc'] as num?)?.toString() ?? '';

        // Parse and format effective from date as DD-MM-YYYY
        final effectiveFromStr = structure['effectiveFrom'] as String?;
        if (effectiveFromStr != null && effectiveFromStr.isNotEmpty) {
          try {
            final effectiveDate = DateTime.parse(effectiveFromStr);
            _effectiveFromController.text =
                '${effectiveDate.day.toString().padLeft(2, '0')}-${effectiveDate.month.toString().padLeft(2, '0')}-${effectiveDate.year}';
          } catch (e) {
            _effectiveFromController.text = effectiveFromStr;
          }
        }

        final earnings = structure['earnings'] as Map<String, dynamic>? ?? {};
        _basicController.text = (earnings['basic'] as num?)?.toString() ?? '';
        _hraController.text = (earnings['hra'] as num?)?.toString() ?? '';
        _daController.text = (earnings['da'] as num?)?.toString() ?? '';
        _conveyanceController.text = (earnings['conveyance'] as num?)?.toString() ?? '';
        _specialAllowanceController.text = (earnings['specialAllowance'] as num?)?.toString() ?? '';
        _otherAllowancesController.text = (earnings['otherAllowances'] as num?)?.toString() ?? '';

        final deductions = structure['deductions'] as Map<String, dynamic>? ?? {};
        _pfApplicable = deductions['pfApplicable'] as bool? ?? true;
        _esiApplicable = deductions['esiApplicable'] as bool? ?? false;
        _ptApplicable = deductions['professionalTax'] as bool? ?? true;
        _tdsController.text = (deductions['tdsMonthly'] as num?)?.toString() ?? '0';
        _loanDeductionController.text = (deductions['loanDeduction'] as num?)?.toString() ?? '0';
        debugPrint('✅ Form pre-filled with salary structure from backend');
      } else {
        debugPrint('📝 No salary structure found for user (new structure)');
      }
    } catch (e) {
      debugPrint('⚠️ Error loading salary structure from backend: $e');
      // Continue without the structure - user can create new one
    }
  }

  void _initializeForm() {
    debugPrint('🔧 Initializing form...');
    debugPrint('📍 Widget userId: ${widget.userId}');
    debugPrint('📊 Employees available: ${_employees.length}');

    // If userId is provided (editing mode), find and select that employee from the loaded list
    if (widget.userId != null && _employees.isNotEmpty) {
      try {
        _selectedEmployee = _employees.firstWhere(
          (emp) => emp['_id'] == widget.userId,
        );
        debugPrint('✅ Employee selected: ${_selectedEmployee?['firstName']} ${_selectedEmployee?['lastName']}');

        // Auto-fill effective from with employee's joining date if not already set
        if (_effectiveFromController.text.isEmpty && _selectedEmployee?['dateOfJoining'] != null) {
          _autoFillEffectiveFromDate(_selectedEmployee!);
        }
      } catch (e) {
        debugPrint('❌ Employee not found with ID: ${widget.userId}');
      }
    }

    if (widget.salaryStructure != null) {
      debugPrint('📋 Loading existing salary structure...');
      final structure = widget.salaryStructure!;
      // Use the structure's employee if available, otherwise use the found employee
      _selectedEmployee = structure['employee'] as Map<String, dynamic>? ?? _selectedEmployee;

      _ctcController.text = (structure['ctc'] as num?)?.toString() ?? '';

      // Parse and format effective from date as DD-MM-YYYY
      final effectiveFromStr = structure['effectiveFrom'] as String?;
      if (effectiveFromStr != null && effectiveFromStr.isNotEmpty) {
        try {
          final effectiveDate = DateTime.parse(effectiveFromStr);
          _effectiveFromController.text =
              '${effectiveDate.day.toString().padLeft(2, '0')}-${effectiveDate.month.toString().padLeft(2, '0')}-${effectiveDate.year}';
        } catch (e) {
          _effectiveFromController.text = effectiveFromStr;
        }
      }

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
      debugPrint('✅ Salary structure loaded with CTC: ${_ctcController.text}');
    } else {
      debugPrint('📝 Creating new salary structure (no existing data)');
      _tdsController.text = '0';
      _loanDeductionController.text = '0';
    }
  }

  /// Check if employee has complete statutory information
  bool _hasAllRequiredStatutoryInfo(Map<String, dynamic> employee) {
    final hasPAN = (employee['panNumber'] as String?)?.isNotEmpty ?? false;
    final hasPFAccount = (employee['pfAccountNumber'] as String?)?.isNotEmpty ?? false;
    final hasUAN = (employee['uanNumber'] as String?)?.isNotEmpty ?? false;
    return hasPAN && hasPFAccount && hasUAN;
  }

  /// Get list of missing statutory fields
  List<String> _getMissingStatutoryFields(Map<String, dynamic> employee) {
    final missing = <String>[];
    if ((employee['panNumber'] as String?)?.isEmpty ?? true) missing.add('PAN');
    if ((employee['pfAccountNumber'] as String?)?.isEmpty ?? true) missing.add('PF Account Number');
    if ((employee['uanNumber'] as String?)?.isEmpty ?? true) missing.add('UAN');
    return missing;
  }

  /// Auto-fill effective from date with employee's joining date
  void _autoFillEffectiveFromDate(Map<String, dynamic> employee) {
    try {
      final joiningDateStr = employee['dateOfJoining'] as String?;
      if (joiningDateStr != null && joiningDateStr.isNotEmpty) {
        // Parse the date and format it as DD-MM-YYYY
        final joiningDate = DateTime.parse(joiningDateStr);
        _effectiveFromController.text =
            '${joiningDate.day.toString().padLeft(2, '0')}-${joiningDate.month.toString().padLeft(2, '0')}-${joiningDate.year}';
        debugPrint('📅 Auto-filled effective from with joining date: ${_effectiveFromController.text}');
      }
    } catch (e) {
      debugPrint('⚠️ Error parsing joining date: $e');
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
            '${picked.day.toString().padLeft(2, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.year}';
      });
    }
  }

  Future<void> _saveSalaryStructure() async {
    debugPrint('💾 Starting salary structure save...');
    debugPrint('📋 Form is valid: ${_formKey.currentState?.validate()}');
    debugPrint('👤 Selected employee: ${_selectedEmployee?['firstName']} ${_selectedEmployee?['lastName']}');

    if (!_formKey.currentState!.validate()) {
      debugPrint('❌ Form validation failed');
      _showMessage('Please fill all required fields correctly', isError: true);
      return;
    }

    if (_selectedEmployee == null) {
      debugPrint('❌ No employee selected');
      _showMessage('Please select an employee', isError: true);
      return;
    }

    setState(() => _isSaving = true);
    debugPrint('⏳ Saving salary structure...');

    try {
      final data = {
        'ctc': double.parse(_ctcController.text),
        'effectiveFrom': _effectiveFromController.text,
        // Earnings (flattened for backend)
        'basic': double.parse(_basicController.text),
        'hra': double.parse(_hraController.text),
        'da': double.parse(_daController.text),
        'conveyance': double.parse(_conveyanceController.text),
        'specialAllowance': double.parse(_specialAllowanceController.text),
        'otherAllowances': double.parse(_otherAllowancesController.text),
        // Deductions (flattened for backend)
        'pfApplicable': _pfApplicable,
        'pfEmployee': 12,
        'pfEmployer': 12,
        'esiApplicable': _esiApplicable,
        'professionalTax': _ptApplicable,
        'tdsMonthly': double.parse(_tdsController.text),
        'loanDeduction': double.parse(_loanDeductionController.text),
      };

      debugPrint('📤 Sending data to API: ${data.toString()}');
      await PayrollApiService.updateSalaryStructure(
        _selectedEmployee!['_id'] as String,
        data,
      );

      debugPrint('✅ Salary structure saved successfully');
      if (mounted) {
        _showMessage('Salary structure saved successfully!');
        Navigator.pop(context, true);
      }
    } catch (e, stack) {
      debugPrint('❌ Error saving salary structure: $e');
      debugPrint('📍 Stack trace: $stack');
      if (mounted) {
        _showMessage('Failed to save: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(
            color: isError ? Colors.white : const Color(0xFF272579),
            fontWeight: FontWeight.w600,
          ),
        ),
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
                  if (_selectedEmployee != null) _buildStatutoryInfoSection(),
                  if (_selectedEmployee != null) const SizedBox(height: 16),
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
                            '${_selectedEmployee!['firstName'] ?? ''} ${_selectedEmployee!['lastName'] ?? ''}'.trim(),
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
                      final firstName = employee['firstName'] ?? '';
                      final lastName = employee['lastName'] ?? '';
                      final fullName = '$firstName $lastName'.trim();
                      final initial = fullName.isNotEmpty ? fullName[0].toUpperCase() : 'E';

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              const Color(0xFF0071bf).withValues(alpha: 0.1),
                          child: Text(
                            initial,
                            style: const TextStyle(
                              color: Color(0xFF0071bf),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        title: Text(fullName.isNotEmpty ? fullName : 'Unknown'),
                        subtitle: Text(
                          '${employee['employeeId'] ?? 'N/A'} • ${employee['designation'] ?? 'N/A'}',
                        ),
                        onTap: () {
                          setState(() {
                            _selectedEmployee = employee;
                            // Auto-fill effective from with employee's joining date
                            if (_effectiveFromController.text.isEmpty) {
                              _autoFillEffectiveFromDate(employee);
                            }
                          });
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

  Widget _buildStatutoryInfoSection() {
    if (_selectedEmployee == null) {
      return const SizedBox.shrink();
    }

    final hasAllInfo = _hasAllRequiredStatutoryInfo(_selectedEmployee!);
    final missingFields = _getMissingStatutoryFields(_selectedEmployee!);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Statutory Information',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF272579),
              ),
            ),
            const SizedBox(height: 16),

            // Warning banner if information is incomplete
            if (!hasAllInfo)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.red.withOpacity(0.5),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.warning_rounded, color: Colors.red, size: 20),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Missing Required Information',
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Required for payslip generation: ${missingFields.join(', ')}',
                      style: TextStyle(
                        color: Colors.red[700],
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final result = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditUserScreen(user: _selectedEmployee!),
                            ),
                          );

                          if (result == true && mounted) {
                            // Reload employees to get updated statutory info
                            await _loadEmployees();
                            if (_selectedEmployee != null && mounted) {
                              // Find and re-select the employee
                              try {
                                _selectedEmployee = _employees.firstWhere(
                                  (emp) => emp['_id'] == _selectedEmployee!['_id'],
                                );
                                setState(() {});
                              } catch (e) {
                                debugPrint('❌ Error reloading employee: $e');
                              }
                            }
                          }
                        },
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text('Edit User Profile'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF5cfbd8).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF5cfbd8).withOpacity(0.5),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Color(0xFF272579), size: 20),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'All required information present',
                        style: TextStyle(
                          color: Color(0xFF272579),
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Statutory details display
            const SizedBox(height: 16),
            _buildStatutoryField('PAN Number', _selectedEmployee!['panNumber']),
            const SizedBox(height: 12),
            _buildStatutoryField('PF Account Number', _selectedEmployee!['pfAccountNumber']),
            const SizedBox(height: 12),
            _buildStatutoryField('UAN Number', _selectedEmployee!['uanNumber']),
            const SizedBox(height: 12),
            _buildStatutoryField('ESI Number', _selectedEmployee!['esiNumber']),
          ],
        ),
      ),
    );
  }

  Widget _buildStatutoryField(String label, dynamic value) {
    final displayValue = value != null && value.toString().isNotEmpty
        ? value.toString()
        : 'Not provided';
    final hasValue = value != null && value.toString().isNotEmpty;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                displayValue,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: hasValue ? Colors.black87 : Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCTCSection() {
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

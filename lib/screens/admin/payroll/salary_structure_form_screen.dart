import 'package:flutter/material.dart';
import '../../../services/payroll_api_service.dart';
import '../../../services/api_service.dart';
import '../../../services/salary_template_api_service.dart';
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

  // Template management
  List<Map<String, dynamic>> _templates = [];
  Map<String, dynamic>? _selectedTemplate;
  bool _useCustomPercentages = false;

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

  // Percentage controllers for custom mode
  final _basicPercentageController = TextEditingController();
  final _hraPercentageController = TextEditingController();
  final _daPercentageController = TextEditingController();
  final _conveyancePercentageController = TextEditingController();
  final _specialAllowancePercentageController = TextEditingController();
  final _otherAllowancesPercentageController = TextEditingController();

  // Deduction amount controllers (monthly amounts in ₹)
  final _pfEmployeeController = TextEditingController();
  final _pfEmployerController = TextEditingController();
  final _esiEmployeeController = TextEditingController();
  final _esiEmployerController = TextEditingController();
  final _ptController = TextEditingController();

  final bool _usePercentages = true;

  @override
  void initState() {
    super.initState();
    _loadEmployeesTemplatesAndInitialize();
  }

  Future<void> _loadEmployeesTemplatesAndInitialize() async {
    // Load employees and templates first
    await _loadEmployees();
    await _loadTemplates();

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
      _pfEmployeeController.text = (deductions['pfEmployee'] as num?)?.toString() ?? '0';
      _pfEmployerController.text = (deductions['pfEmployer'] as num?)?.toString() ?? '0';
      _esiEmployeeController.text = (deductions['esiEmployee'] as num?)?.toString() ?? '0';
      _esiEmployerController.text = (deductions['esiEmployer'] as num?)?.toString() ?? '0';
      _ptController.text = (deductions['professionalTax'] as num?)?.toString() ?? '0';
      _tdsController.text = (deductions['tdsMonthly'] as num?)?.toString() ?? '0';
      _loanDeductionController.text =
          (deductions['loanDeduction'] as num?)?.toString() ?? '0';
      debugPrint('✅ Salary structure loaded with CTC: ${_ctcController.text}');
    } else {
      debugPrint('📝 Creating new salary structure (no existing data)');
      _pfEmployeeController.text = '0';
      _pfEmployerController.text = '0';
      _esiEmployeeController.text = '0';
      _esiEmployerController.text = '0';
      _ptController.text = '0';
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

  Future<void> _loadTemplates() async {
    try {
      debugPrint('📥 Loading salary templates...');
      final templates = await SalaryTemplateApiService.getAllTemplates();
      if (mounted) {
        setState(() {
          _templates = templates;
          // Do NOT auto-select first template - let user manually select
          _selectedTemplate = null;
          debugPrint('✅ Loaded ${_templates.length} templates');
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading templates: $e');
      _showMessage('Error loading salary templates: $e', isError: true);
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
    _basicPercentageController.dispose();
    _hraPercentageController.dispose();
    _daPercentageController.dispose();
    _conveyancePercentageController.dispose();
    _specialAllowancePercentageController.dispose();
    _otherAllowancesPercentageController.dispose();

    // Dispose deduction controllers
    _pfEmployeeController.dispose();
    _pfEmployerController.dispose();
    _esiEmployeeController.dispose();
    _esiEmployerController.dispose();
    _ptController.dispose();
    super.dispose();
  }

  void _calculateFromCTC() {
    if (_ctcController.text.isEmpty) return;

    final annualCtc = double.tryParse(_ctcController.text);
    if (annualCtc == null) return;

    // Convert annual CTC to monthly for component breakdown
    final monthlyCTC = annualCtc / 12;
    debugPrint('📊 Calculating from Annual CTC: ₹$annualCtc → Monthly CTC: ₹${monthlyCTC.toStringAsFixed(2)}');

    if (_usePercentages) {
      setState(() {
        if (_useCustomPercentages) {
          // Use custom percentages to calculate MONTHLY components
          final basic = double.tryParse(_basicPercentageController.text) ?? 0;
          final hra = double.tryParse(_hraPercentageController.text) ?? 0;
          final da = double.tryParse(_daPercentageController.text) ?? 0;
          final conveyance = double.tryParse(_conveyancePercentageController.text) ?? 0;
          final special = double.tryParse(_specialAllowancePercentageController.text) ?? 0;
          final other = double.tryParse(_otherAllowancesPercentageController.text) ?? 0;

          _basicController.text = (monthlyCTC * basic / 100).toStringAsFixed(2);
          _hraController.text = (monthlyCTC * hra / 100).toStringAsFixed(2);
          _daController.text = (monthlyCTC * da / 100).toStringAsFixed(2);
          _conveyanceController.text = (monthlyCTC * conveyance / 100).toStringAsFixed(2);
          _specialAllowanceController.text = (monthlyCTC * special / 100).toStringAsFixed(2);
          _otherAllowancesController.text = (monthlyCTC * other / 100).toStringAsFixed(2);
        } else if (_selectedTemplate != null) {
          // Use template percentages to calculate MONTHLY components
          final percentages = _selectedTemplate!['percentages'] as Map<String, dynamic>? ?? {};
          _basicController.text = (monthlyCTC * (percentages['basic'] as num? ?? 40) / 100).toStringAsFixed(2);
          _hraController.text = (monthlyCTC * (percentages['hra'] as num? ?? 30) / 100).toStringAsFixed(2);
          _daController.text = (monthlyCTC * (percentages['da'] as num? ?? 10) / 100).toStringAsFixed(2);
          _conveyanceController.text = (monthlyCTC * (percentages['conveyance'] as num? ?? 5) / 100).toStringAsFixed(2);
          _specialAllowanceController.text = (monthlyCTC * (percentages['specialAllowance'] as num? ?? 15) / 100).toStringAsFixed(2);
          _otherAllowancesController.text = (monthlyCTC * (percentages['otherAllowances'] as num? ?? 0) / 100).toStringAsFixed(2);
        } else {
          // Use default percentages: Basic 40%, HRA 30%, DA 10%, Conveyance 5%, Special 15%
          _basicController.text = (monthlyCTC * 0.40).toStringAsFixed(2);
          _hraController.text = (monthlyCTC * 0.30).toStringAsFixed(2);
          _daController.text = (monthlyCTC * 0.10).toStringAsFixed(2);
          _conveyanceController.text = (monthlyCTC * 0.05).toStringAsFixed(2);
          _specialAllowanceController.text = (monthlyCTC * 0.15).toStringAsFixed(2);
          _otherAllowancesController.text = '0';
        }
      });
    }
  }

  double _getTotalPercentage() {
    if (_useCustomPercentages) {
      final basic = double.tryParse(_basicPercentageController.text) ?? 0;
      final hra = double.tryParse(_hraPercentageController.text) ?? 0;
      final da = double.tryParse(_daPercentageController.text) ?? 0;
      final conveyance = double.tryParse(_conveyancePercentageController.text) ?? 0;
      final special = double.tryParse(_specialAllowancePercentageController.text) ?? 0;
      final other = double.tryParse(_otherAllowancesPercentageController.text) ?? 0;
      return basic + hra + da + conveyance + special + other;
    }
    return 0;
  }

  void _onCustomPercentageChanged() {
    setState(() {
      // Update calculations when custom percentages change
      _calculateFromCTC();
    });
  }

  void _toggleCustomPercentages() {
    setState(() {
      _useCustomPercentages = !_useCustomPercentages;

      if (_useCustomPercentages) {
        // Initialize custom percentage controllers with template or default values
        if (_selectedTemplate != null) {
          final percentages = _selectedTemplate!['percentages'] as Map<String, dynamic>? ?? {};
          _basicPercentageController.text = (percentages['basic'] ?? 40).toString();
          _hraPercentageController.text = (percentages['hra'] ?? 30).toString();
          _daPercentageController.text = (percentages['da'] ?? 10).toString();
          _conveyancePercentageController.text = (percentages['conveyance'] ?? 5).toString();
          _specialAllowancePercentageController.text = (percentages['specialAllowance'] ?? 15).toString();
          _otherAllowancesPercentageController.text = (percentages['otherAllowances'] ?? 0).toString();
        } else {
          _basicPercentageController.text = '40';
          _hraPercentageController.text = '30';
          _daPercentageController.text = '10';
          _conveyancePercentageController.text = '5';
          _specialAllowancePercentageController.text = '15';
          _otherAllowancesPercentageController.text = '0';
        }
      }
      _calculateFromCTC();
    });
  }

  void _onTemplateSelected(Map<String, dynamic> template) {
    setState(() {
      _selectedTemplate = template;
      if (!_useCustomPercentages) {
        _calculateFromCTC();
      }
    });
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

    // Validate custom percentages if in custom mode
    if (_useCustomPercentages) {
      final totalPercentage = _getTotalPercentage();
      if ((totalPercentage - 100).abs() > 0.01) {
        debugPrint('❌ Custom percentages total to $totalPercentage, must be 100');
        _showMessage('Percentages must total 100% (current: ${totalPercentage.toStringAsFixed(2)}%)', isError: true);
        return;
      }
    }

    setState(() => _isSaving = true);
    debugPrint('⏳ Saving salary structure...');

    try {
      // Parse effective from date from DD-MM-YYYY to ISO format
      String effectiveFromDate = '';
      if (_effectiveFromController.text.isNotEmpty) {
        try {
          final parts = _effectiveFromController.text.split('-');
          if (parts.length == 3) {
            final day = parts[0];
            final month = parts[1];
            final year = parts[2];
            // Convert to YYYY-MM-DD format
            effectiveFromDate = '$year-${month.padLeft(2, '0')}-${day.padLeft(2, '0')}';
            debugPrint('📅 Converted date from ${_effectiveFromController.text} to $effectiveFromDate');
          }
        } catch (e) {
          debugPrint('❌ Error parsing date: $e');
          throw Exception('Invalid date format. Use DD-MM-YYYY');
        }
      }

      final data = {
        'ctc': double.parse(_ctcController.text),
        'effectiveFrom': effectiveFromDate,
        // Earnings (flattened for backend)
        'basic': double.parse(_basicController.text),
        'hra': double.parse(_hraController.text),
        'da': double.parse(_daController.text),
        'conveyance': double.parse(_conveyanceController.text),
        'specialAllowance': double.parse(_specialAllowanceController.text),
        'otherAllowances': double.parse(_otherAllowancesController.text),
        // Deductions (monthly amounts in ₹)
        'pfEmployee': double.parse(_pfEmployeeController.text),
        'pfEmployer': double.parse(_pfEmployerController.text),
        'esiEmployee': double.parse(_esiEmployeeController.text),
        'esiEmployer': double.parse(_esiEmployerController.text),
        'professionalTax': double.parse(_ptController.text),
        'tdsMonthly': double.parse(_tdsController.text),
        'loanDeduction': double.parse(_loanDeductionController.text),
      };

      // Add template information
      if (_useCustomPercentages) {
        data['customPercentages'] = {
          'basic': double.tryParse(_basicPercentageController.text) ?? 40,
          'hra': double.tryParse(_hraPercentageController.text) ?? 30,
          'da': double.tryParse(_daPercentageController.text) ?? 10,
          'conveyance': double.tryParse(_conveyancePercentageController.text) ?? 5,
          'specialAllowance': double.tryParse(_specialAllowancePercentageController.text) ?? 15,
          'otherAllowances': double.tryParse(_otherAllowancesPercentageController.text) ?? 0,
        };
        data['percentageSource'] = 'custom';
      } else if (_selectedTemplate != null) {
        data['templateId'] = _selectedTemplate!['_id'];
        data['percentageSource'] = 'template';
      } else {
        data['percentageSource'] = 'none';
      }

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
                  _buildTemplateSection(),
                  const SizedBox(height: 16),
                  _buildPercentageToggleSection(),
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
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.red.withValues(alpha: 0.5),
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
                  color: const Color(0xFF5cfbd8).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF5cfbd8).withValues(alpha: 0.5),
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
    final hasCTC = _ctcController.text.isNotEmpty;

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
            const SizedBox(height: 8),
            Text(
              'Enter your annual CTC and select a salary template to auto-calculate earnings breakdown',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
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
            if (hasCTC && _selectedTemplate != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF5cfbd8).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: const Color(0xFF5cfbd8),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: Color(0xFF5cfbd8),
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Earnings breakdown will be calculated using ${_selectedTemplate?['templateName'] ?? 'selected template'}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF272579),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplateSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Salary Template',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF272579),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Select a template to auto-populate earnings breakdown based on your CTC',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            if (_templates.isEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.amber.withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_rounded, color: Colors.amber, size: 20),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'No templates available',
                        style: TextStyle(
                          color: Colors.amber,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              DropdownButtonFormField<Map<String, dynamic>>(
                initialValue: _selectedTemplate,
                decoration: InputDecoration(
                  labelText: 'Select Template',
                  prefixIcon: const Icon(Icons.assignment_rounded, color: Color(0xFF0071bf)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF0071bf), width: 2),
                  ),
                  helperText: 'Choose a salary structure template',
                ),
                items: [
                  DropdownMenuItem(
                    value: null,
                    child: Text(
                      'Choose a template...',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                  ..._templates.map((template) {
                    final isDefault = template['isDefault'] ?? false;
                    final templateName = template['templateName'] ?? 'Unknown';
                    return DropdownMenuItem(
                      value: template,
                      child: Text(
                        isDefault ? '$templateName (Default)' : templateName,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }),
                ],
                onChanged: (template) {
                  if (template != null) {
                    _onTemplateSelected(template);
                  } else {
                    setState(() => _selectedTemplate = null);
                  }
                },
              ),
            if (_selectedTemplate != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTemplatePercentagesPreview(),
                    const SizedBox(height: 12),
                    if (_ctcController.text.isNotEmpty)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _calculateFromCTC,
                          icon: const Icon(Icons.calculate),
                          label: const Text('Recalculate Earnings'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0071bf),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: Colors.orange.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.warning_rounded,
                              color: Colors.orange[700],
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Please enter CTC above to calculate earnings',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.orange[700],
                                  fontWeight: FontWeight.w500,
                                ),
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
      ),
    );
  }

  Widget _buildTemplatePercentagesPreview() {
    if (_selectedTemplate == null) return const SizedBox.shrink();

    final percentages = _selectedTemplate!['percentages'] as Map<String, dynamic>? ?? {};

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0071bf).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF0071bf).withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Template Breakdown',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0071bf),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildPercentageBadge('Basic', (percentages['basic'] as num? ?? 40).toDouble()),
              _buildPercentageBadge('HRA', (percentages['hra'] as num? ?? 30).toDouble()),
              _buildPercentageBadge('DA', (percentages['da'] as num? ?? 10).toDouble()),
              _buildPercentageBadge('Conveyance', (percentages['conveyance'] as num? ?? 5).toDouble()),
              _buildPercentageBadge('Special', (percentages['specialAllowance'] as num? ?? 15).toDouble()),
              _buildPercentageBadge('Other', (percentages['otherAllowances'] as num? ?? 0).toDouble()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPercentageBadge(String label, double percentage) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF0071bf).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$label: ${percentage.toStringAsFixed(0)}%',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(0xFF0071bf),
        ),
      ),
    );
  }

  Widget _buildPercentageToggleSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Use Custom Percentages',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF272579),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Override template with custom percentages',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _useCustomPercentages,
                  activeTrackColor: const Color(0xFF0071bf),
                  onChanged: (_) => _toggleCustomPercentages(),
                ),
              ],
            ),
            if (_useCustomPercentages)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: _buildCustomPercentagesInputs(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomPercentagesInputs() {
    final totalPercentage = _getTotalPercentage();
    final isValid = (totalPercentage - 100).abs() <= 0.01;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPercentageInputField(_basicPercentageController, 'Basic %', 'basic'),
        const SizedBox(height: 12),
        _buildPercentageInputField(_hraPercentageController, 'HRA %', 'hra'),
        const SizedBox(height: 12),
        _buildPercentageInputField(_daPercentageController, 'DA %', 'da'),
        const SizedBox(height: 12),
        _buildPercentageInputField(_conveyancePercentageController, 'Conveyance %', 'conveyance'),
        const SizedBox(height: 12),
        _buildPercentageInputField(_specialAllowancePercentageController, 'Special Allowance %', 'special'),
        const SizedBox(height: 12),
        _buildPercentageInputField(_otherAllowancesPercentageController, 'Other Allowances %', 'other'),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isValid ? const Color(0xFF5cfbd8).withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isValid ? const Color(0xFF5cfbd8).withValues(alpha: 0.5) : Colors.red.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            children: [
              Icon(
                isValid ? Icons.check_circle : Icons.error_rounded,
                color: isValid ? const Color(0xFF5cfbd8) : Colors.red,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Total: ${totalPercentage.toStringAsFixed(2)}% ${isValid ? '✓' : '(Must be 100%)'}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isValid ? const Color(0xFF5cfbd8) : Colors.red,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPercentageInputField(TextEditingController controller, String label, String fieldName) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.percent, color: Color(0xFF0071bf)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF0071bf), width: 2),
        ),
      ),
      onChanged: (_) => _onCustomPercentageChanged(),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Required';
        }
        final percentage = double.tryParse(value);
        if (percentage == null || percentage < 0 || percentage > 100) {
          return 'Must be 0-100';
        }
        return null;
      },
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
              'Earnings Breakdown (Monthly)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF272579),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Components are calculated from annual CTC and converted to monthly amounts (CTC ÷ 12)',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
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
            const SizedBox(height: 8),
            const Text(
              'Enter monthly deduction amounts in ₹. Leave as 0 to skip.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            _buildAmountField(_pfEmployeeController, 'PF Employee (₹)', Icons.account_balance_wallet),
            const SizedBox(height: 12),
            _buildAmountField(_pfEmployerController, 'PF Employer (₹)', Icons.business),
            const SizedBox(height: 12),
            _buildAmountField(_esiEmployeeController, 'ESI Employee (₹)', Icons.shield),
            const SizedBox(height: 12),
            _buildAmountField(_esiEmployerController, 'ESI Employer (₹)', Icons.domain),
            const SizedBox(height: 12),
            _buildAmountField(_ptController, 'Professional Tax (₹)', Icons.description),
            const SizedBox(height: 12),
            _buildAmountField(_tdsController, 'Monthly TDS (₹)', Icons.receipt),
            const SizedBox(height: 12),
            _buildAmountField(_loanDeductionController, 'Loan Deduction (₹)', Icons.money_off),
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

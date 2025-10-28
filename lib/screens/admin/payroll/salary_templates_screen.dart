import 'package:flutter/material.dart';
import '../../../services/salary_template_api_service.dart';

/// Admin screen for managing salary templates
class SalaryTemplatesScreen extends StatefulWidget {
  const SalaryTemplatesScreen({super.key});

  @override
  State<SalaryTemplatesScreen> createState() => _SalaryTemplatesScreenState();
}

class _SalaryTemplatesScreenState extends State<SalaryTemplatesScreen> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _templates = [];

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    setState(() => _isLoading = true);
    try {
      debugPrint('📥 Loading salary templates...');
      final templates = await SalaryTemplateApiService.getAllTemplates();
      if (mounted) {
        setState(() {
          _templates = templates;
          _isLoading = false;
          debugPrint('✅ Loaded ${_templates.length} templates');
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading templates: $e');
      if (mounted) {
        _showMessage('Error loading templates: $e', isError: true);
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteTemplate(String templateId, String templateName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Template'),
        content: Text('Are you sure you want to delete "$templateName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final success = await SalaryTemplateApiService.deleteTemplate(templateId);
        if (success && mounted) {
          _showMessage('Template deleted successfully');
          await _loadTemplates();
        } else if (mounted) {
          _showMessage('Failed to delete template', isError: true);
        }
      } catch (e) {
        if (mounted) {
          _showMessage('Error: $e', isError: true);
        }
      }
    }
  }

  Future<void> _setAsDefault(String templateId, String templateName) async {
    try {
      debugPrint('📤 Setting $templateName as default...');
      final success = await SalaryTemplateApiService.setAsDefault(templateId);
      if (success && mounted) {
        _showMessage('$templateName set as default');
        await _loadTemplates();
      } else if (mounted) {
        _showMessage('Failed to set as default', isError: true);
      }
    } catch (e) {
      if (mounted) {
        _showMessage('Error: $e', isError: true);
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
    return Scaffold(
      backgroundColor: const Color(0xFFf8f9fa),
      appBar: AppBar(
        title: const Text(
          'Salary Templates',
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
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF0071bf),
        onPressed: () async {
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (context) => const SalaryTemplateFormScreen(),
            ),
          );
          if (result == true) {
            await _loadTemplates();
          }
        },
        child: const Icon(Icons.add, color: Colors.white,),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF0071bf)),
            )
          : _templates.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.assignment_rounded,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No templates yet',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Create your first salary template',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _templates.length,
                  itemBuilder: (context, index) {
                    final template = _templates[index];
                    final isDefault = template['isDefault'] as bool? ?? false;
                    final percentages = template['percentages'] as Map<String, dynamic>? ?? {};

                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        template['templateName'] ?? 'Unknown',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF272579),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isDefault)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF5cfbd8).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: const Color(0xFF5cfbd8).withValues(alpha: 0.5),
                                      ),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.check_circle, size: 14, color: Color(0xFF5cfbd8)),
                                        SizedBox(width: 4),
                                        Text(
                                          'Default',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF5cfbd8),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 16),
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
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (!isDefault)
                                  TextButton.icon(
                                    onPressed: () => _setAsDefault(template['_id'], template['templateName']),
                                    icon: const Icon(Icons.star_outline, size: 18),
                                    label: const Text('Set Default'),
                                    style: TextButton.styleFrom(
                                      foregroundColor: const Color(0xFF0071bf),
                                    ),
                                  ),
                                TextButton.icon(
                                  onPressed: () async {
                                    final result = await Navigator.push<bool>(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => SalaryTemplateFormScreen(template: template),
                                      ),
                                    );
                                    if (result == true) {
                                      await _loadTemplates();
                                    }
                                  },
                                  icon: const Icon(Icons.edit, size: 18),
                                  label: const Text('Edit'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: const Color(0xFF0071bf),
                                  ),
                                ),
                                TextButton.icon(
                                  onPressed: () => _deleteTemplate(template['_id'], template['templateName']),
                                  icon: const Icon(Icons.delete, size: 18),
                                  label: const Text('Delete'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
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
}

/// Form screen for creating/editing salary templates
class SalaryTemplateFormScreen extends StatefulWidget {
  final Map<String, dynamic>? template;

  const SalaryTemplateFormScreen({
    super.key,
    this.template,
  });

  @override
  State<SalaryTemplateFormScreen> createState() => _SalaryTemplateFormScreenState();
}

class _SalaryTemplateFormScreenState extends State<SalaryTemplateFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  final _nameController = TextEditingController();
  final _basicController = TextEditingController();
  final _hraController = TextEditingController();
  final _daController = TextEditingController();
  final _conveyanceController = TextEditingController();
  final _specialAllowanceController = TextEditingController();
  final _otherAllowancesController = TextEditingController();

  // Deduction Controllers
  final _pfEmployeeController = TextEditingController();
  final _pfEmployerController = TextEditingController();
  final _esiEmployeeController = TextEditingController();
  final _esiEmployerController = TextEditingController();
  final _ptController = TextEditingController();
  final _tdsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    if (widget.template != null) {
      final template = widget.template!;
      _nameController.text = template['templateName'] ?? '';

      final percentages = template['percentages'] as Map<String, dynamic>? ?? {};
      _basicController.text = (percentages['basic'] ?? 40).toString();
      _hraController.text = (percentages['hra'] ?? 30).toString();
      _daController.text = (percentages['da'] ?? 10).toString();
      _conveyanceController.text = (percentages['conveyance'] ?? 5).toString();
      _specialAllowanceController.text = (percentages['specialAllowance'] ?? 15).toString();
      _otherAllowancesController.text = (percentages['otherAllowances'] ?? 0).toString();

      // Load deduction values
      final deductions = template['deductions'] as Map<String, dynamic>? ?? {};
      _pfEmployeeController.text = (deductions['pfEmployee'] ?? 0).toString();
      _pfEmployerController.text = (deductions['pfEmployer'] ?? 0).toString();
      _esiEmployeeController.text = (deductions['esiEmployee'] ?? 0).toString();
      _esiEmployerController.text = (deductions['esiEmployer'] ?? 0).toString();
      _ptController.text = (deductions['professionalTax'] ?? 0).toString();
      _tdsController.text = (deductions['tds'] ?? 0).toString();
    } else {
      // Default values for new template
      _basicController.text = '40';
      _hraController.text = '30';
      _daController.text = '10';
      _conveyanceController.text = '5';
      _specialAllowanceController.text = '15';
      _otherAllowancesController.text = '0';

      // Default deduction values
      _pfEmployeeController.text = '0';
      _pfEmployerController.text = '0';
      _esiEmployeeController.text = '0';
      _esiEmployerController.text = '0';
      _ptController.text = '0';
      _tdsController.text = '0';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _basicController.dispose();
    _hraController.dispose();
    _daController.dispose();
    _conveyanceController.dispose();
    _specialAllowanceController.dispose();
    _otherAllowancesController.dispose();

    // Dispose deduction controllers
    _pfEmployeeController.dispose();
    _pfEmployerController.dispose();
    _esiEmployeeController.dispose();
    _esiEmployerController.dispose();
    _ptController.dispose();
    _tdsController.dispose();
    super.dispose();
  }

  double _getTotalPercentage() {
    final basic = double.tryParse(_basicController.text) ?? 0;
    final hra = double.tryParse(_hraController.text) ?? 0;
    final da = double.tryParse(_daController.text) ?? 0;
    final conveyance = double.tryParse(_conveyanceController.text) ?? 0;
    final special = double.tryParse(_specialAllowanceController.text) ?? 0;
    final other = double.tryParse(_otherAllowancesController.text) ?? 0;
    return basic + hra + da + conveyance + special + other;
  }

  Future<void> _saveTemplate() async {
    if (!_formKey.currentState!.validate()) {
      _showMessage('Please fill all required fields', isError: true);
      return;
    }

    final totalPercentage = _getTotalPercentage();
    if ((totalPercentage - 100).abs() > 0.01) {
      _showMessage('Percentages must total 100% (current: ${totalPercentage.toStringAsFixed(2)}%)', isError: true);
      return;
    }

    setState(() => _isSaving = true);

    try {
      final percentages = {
        'basic': double.parse(_basicController.text),
        'hra': double.parse(_hraController.text),
        'da': double.parse(_daController.text),
        'conveyance': double.parse(_conveyanceController.text),
        'specialAllowance': double.parse(_specialAllowanceController.text),
        'otherAllowances': double.parse(_otherAllowancesController.text),
      };

      final deductions = {
        'pfEmployee': double.parse(_pfEmployeeController.text),
        'pfEmployer': double.parse(_pfEmployerController.text),
        'esiEmployee': double.parse(_esiEmployeeController.text),
        'esiEmployer': double.parse(_esiEmployerController.text),
        'professionalTax': double.parse(_ptController.text),
        'tds': double.parse(_tdsController.text),
      };

      // Validate deduction percentages
      final deductionErrors = <String>[];
      if (deductions['pfEmployee']! > 20) {
        deductionErrors.add('PF Employee % exceeds 20%');
      }
      if (deductions['pfEmployer']! > 20) {
        deductionErrors.add('PF Employer % exceeds 20%');
      }
      if (deductions['esiEmployee']! > 5) {
        deductionErrors.add('ESI Employee % exceeds 5%');
      }
      if (deductions['esiEmployer']! > 10) {
        deductionErrors.add('ESI Employer % exceeds 10%');
      }
      if (deductions['professionalTax']! > 10) {
        deductionErrors.add('Professional Tax % exceeds 10%');
      }
      if (deductions['tds']! > 50) {
        deductionErrors.add('TDS % exceeds 50%');
      }

      if (deductionErrors.isNotEmpty) {
        _showMessage(deductionErrors.join(', '), isError: true);
        return;
      }

      if (widget.template != null) {
        // Update existing template
        debugPrint('📤 Updating template...');
        final result = await SalaryTemplateApiService.updateTemplate(
          templateId: widget.template!['_id'],
          templateName: _nameController.text,
          percentages: percentages,
          deductions: deductions,
        );

        if (result != null && mounted) {
          _showMessage('Template updated successfully');
          Navigator.pop(context, true);
        } else if (mounted) {
          _showMessage('Failed to update template', isError: true);
        }
      } else {
        // Create new template
        debugPrint('📤 Creating new template...');
        final result = await SalaryTemplateApiService.createTemplate(
          templateName: _nameController.text,
          percentages: percentages,
          deductions: deductions,
        );

        if (result != null && mounted) {
          _showMessage('Template created successfully');
          Navigator.pop(context, true);
        } else if (mounted) {
          _showMessage('Failed to create template', isError: true);
        }
      }
    } catch (e) {
      if (mounted) {
        String userMessage = 'Error: $e';
        final errorString = e.toString();

        // Parse error code and provide user-friendly message
        if (errorString.contains('DUPLICATE_NAME')) {
          userMessage = 'A template with this name already exists. Please choose a different name.';
        } else if (errorString.contains('INVALID_PERCENTAGE_TOTAL')) {
          userMessage = 'Percentages must add up to exactly 100%';
        } else if (errorString.contains('INVALID_DEDUCTIONS')) {
          userMessage = 'One or more deduction percentages exceed reasonable limits. Please review and adjust.';
        } else if (errorString.contains('Authentication')) {
          userMessage = 'Your session has expired. Please login again.';
        } else if (errorString.contains('TimeoutException')) {
          userMessage = 'Request timed out. Please check your connection and try again.';
        } else if (errorString.contains('Connection refused')) {
          userMessage = 'Cannot reach the server. Please check your connection.';
        }

        _showMessage(userMessage, isError: true);
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
    final isEdit = widget.template != null;

    return Scaffold(
      backgroundColor: const Color(0xFFf8f9fa),
      appBar: AppBar(
        title: Text(
          isEdit ? 'Edit Salary Template' : 'Create Salary Template',
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
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Template Information',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF272579),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Template Name',
                        prefixIcon: const Icon(Icons.label, color: Color(0xFF0071bf)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFF0071bf), width: 2),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Template name is required';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Percentage Breakdown',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF272579),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildPercentageField(_basicController, 'Basic %'),
                    const SizedBox(height: 12),
                    _buildPercentageField(_hraController, 'HRA %'),
                    const SizedBox(height: 12),
                    _buildPercentageField(_daController, 'DA %'),
                    const SizedBox(height: 12),
                    _buildPercentageField(_conveyanceController, 'Conveyance %'),
                    const SizedBox(height: 12),
                    _buildPercentageField(_specialAllowanceController, 'Special Allowance %'),
                    const SizedBox(height: 12),
                    _buildPercentageField(_otherAllowancesController, 'Other Allowances %'),
                    const SizedBox(height: 16),
                    _buildTotalValidation(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Deduction Percentages (Optional)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF272579),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Based on Basic Salary for PF, Gross Salary for others. Leave at 0 to skip.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildDeductionField(_pfEmployeeController, 'PF Employee %', 'Percentage'),
                    const SizedBox(height: 12),
                    _buildDeductionField(_pfEmployerController, 'PF Employer %', 'Percentage'),
                    const SizedBox(height: 12),
                    _buildDeductionField(_esiEmployeeController, 'ESI Employee %', 'Percentage'),
                    const SizedBox(height: 12),
                    _buildDeductionField(_esiEmployerController, 'ESI Employer %', 'Percentage'),
                    const SizedBox(height: 12),
                    _buildDeductionField(_ptController, 'Professional Tax %', 'Percentage'),
                    const SizedBox(height: 12),
                    _buildDeductionField(_tdsController, 'TDS %', 'Percentage'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveTemplate,
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
                    : Text(
                        isEdit ? 'Update Template' : 'Create Template',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPercentageField(TextEditingController controller, String label) {
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
      onChanged: (_) {
        setState(() {});
      },
    );
  }

  Widget _buildTotalValidation() {
    final total = _getTotalPercentage();
    final isValid = (total - 100).abs() <= 0.01;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isValid ? const Color(0xFF5cfbd8).withValues(alpha: 0.3) : Colors.red.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isValid ? const Color(0xFF0071bf) : Colors.red[700]!,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isValid ? Icons.check_circle : Icons.error_rounded,
            color: isValid ? const Color(0xFF0071bf) : Colors.red[700]!,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isValid
                  ? 'Total: ${total.toStringAsFixed(2)}% ✓'
                  : 'Total: ${total.toStringAsFixed(2)}% (Must be 100%)',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: isValid ? const Color(0xFF0071bf) : Colors.red[700]!,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeductionField(TextEditingController controller, String label, String hint) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: const Icon(Icons.percent, color: Color(0xFF0071bf)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF0071bf), width: 2),
        ),
      ),
      validator: (value) {
        if (value != null && value.isNotEmpty) {
          final parsed = double.tryParse(value);
          if (parsed == null) {
            return 'Enter a valid number';
          }
          if (parsed < 0 || parsed > 100) {
            return 'Must be between 0 and 100';
          }
        }
        return null;
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../models/incentive_template.dart';
import '../../../services/incentive_service.dart';
import '../../../providers/incentive_provider.dart';

class AddEditTemplateScreen extends StatefulWidget {
  final IncentiveTemplate? template;

  const AddEditTemplateScreen({super.key, this.template});

  @override
  State<AddEditTemplateScreen> createState() => _AddEditTemplateScreenState();
}

class _AddEditTemplateScreenState extends State<AddEditTemplateScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Basic Info
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  // Commission Rates
  final _lifeRateController = TextEditingController();
  final _generalRateController = TextEditingController();
  final _mutualFundsRateController = TextEditingController();

  // Target Type
  String _targetType = 'overall_amount';

  // Overall Target
  final _overallAmountController = TextEditingController();

  // Product Targets
  final _lifeCountController = TextEditingController();
  final _lifeAmountController = TextEditingController();
  final _generalCountController = TextEditingController();
  final _generalAmountController = TextEditingController();
  final _mfCountController = TextEditingController();
  final _mfAmountController = TextEditingController();

  // Next Template
  String? _selectedNextTemplateId;
  List<IncentiveTemplate> _availableTemplates = [];

  bool get isEditing => widget.template != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTemplates();
    });
    if (isEditing) {
      _populateForm();
    }
  }

  Future<void> _loadTemplates() async {
    final provider = context.read<IncentiveProvider>();
    await provider.fetchTemplates();
    if (mounted) {
      setState(() {
        _availableTemplates = provider.templates
            .where((t) => t.id != widget.template?.id)
            .toList();
      });
    }
  }

  void _populateForm() {
    final t = widget.template!;
    _nameController.text = t.name;
    _descriptionController.text = t.description ?? '';

    // Commission Rates
    _lifeRateController.text =
        t.commissionRates.lifeInsurance.toString();
    _generalRateController.text =
        t.commissionRates.generalInsurance.toString();
    _mutualFundsRateController.text =
        t.commissionRates.mutualFunds.toString();

    // Target Type
    _targetType = t.targetType;

    // Overall Target
    _overallAmountController.text =
        t.overallTarget.amount.toString();

    // Product Targets
    _lifeCountController.text =
        t.productTargets.lifeInsurance.count.toString();
    _lifeAmountController.text =
        t.productTargets.lifeInsurance.amount.toString();
    _generalCountController.text =
        t.productTargets.generalInsurance.count.toString();
    _generalAmountController.text =
        t.productTargets.generalInsurance.amount.toString();
    _mfCountController.text =
        t.productTargets.mutualFunds.count.toString();
    _mfAmountController.text =
        t.productTargets.mutualFunds.amount.toString();

    // Next Template
    _selectedNextTemplateId = t.nextTemplateId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _lifeRateController.dispose();
    _generalRateController.dispose();
    _mutualFundsRateController.dispose();
    _overallAmountController.dispose();
    _lifeCountController.dispose();
    _lifeAmountController.dispose();
    _generalCountController.dispose();
    _generalAmountController.dispose();
    _mfCountController.dispose();
    _mfAmountController.dispose();
    super.dispose();
  }

  Future<void> _saveTemplate() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Extract values from controllers
      final name = _nameController.text.trim();
      final description = _descriptionController.text.trim();
      final lifeInsuranceRate = double.tryParse(_lifeRateController.text) ?? 0;
      final generalInsuranceRate = double.tryParse(_generalRateController.text) ?? 0;
      final mutualFundsRate = double.tryParse(_mutualFundsRateController.text) ?? 0;
      final overallTargetAmount = double.tryParse(_overallAmountController.text);
      final lifeInsuranceCountTarget = int.tryParse(_lifeCountController.text);
      final lifeInsuranceAmountTarget = double.tryParse(_lifeAmountController.text);
      final generalInsuranceCountTarget = int.tryParse(_generalCountController.text);
      final generalInsuranceAmountTarget = double.tryParse(_generalAmountController.text);
      final mutualFundsCountTarget = int.tryParse(_mfCountController.text);
      final mutualFundsAmountTarget = double.tryParse(_mfAmountController.text);

      final response = isEditing
          ? await IncentiveService.updateTemplate(
              templateId: widget.template!.id,
              name: name,
              description: description.isNotEmpty ? description : null,
              lifeInsuranceRate: lifeInsuranceRate,
              generalInsuranceRate: generalInsuranceRate,
              mutualFundsRate: mutualFundsRate,
              targetType: _targetType,
              overallTargetAmount: overallTargetAmount,
              lifeInsuranceCountTarget: lifeInsuranceCountTarget,
              lifeInsuranceAmountTarget: lifeInsuranceAmountTarget,
              generalInsuranceCountTarget: generalInsuranceCountTarget,
              generalInsuranceAmountTarget: generalInsuranceAmountTarget,
              mutualFundsCountTarget: mutualFundsCountTarget,
              mutualFundsAmountTarget: mutualFundsAmountTarget,
              nextTemplateId: _selectedNextTemplateId,
            )
          : await IncentiveService.createTemplate(
              name: name,
              description: description.isNotEmpty ? description : null,
              lifeInsuranceRate: lifeInsuranceRate,
              generalInsuranceRate: generalInsuranceRate,
              mutualFundsRate: mutualFundsRate,
              targetType: _targetType,
              overallTargetAmount: overallTargetAmount,
              lifeInsuranceCountTarget: lifeInsuranceCountTarget,
              lifeInsuranceAmountTarget: lifeInsuranceAmountTarget,
              generalInsuranceCountTarget: generalInsuranceCountTarget,
              generalInsuranceAmountTarget: generalInsuranceAmountTarget,
              mutualFundsCountTarget: mutualFundsCountTarget,
              mutualFundsAmountTarget: mutualFundsAmountTarget,
              nextTemplateId: _selectedNextTemplateId,
            );

      if (!mounted) return;

      if (response.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEditing
                  ? 'Template updated successfully'
                  : 'Template created successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message ?? 'Failed to save template'),
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
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
        title: Text(
          isEditing ? 'Edit Template' : 'Create Template',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        foregroundColor: Colors.white,
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ),
            )
          else
            TextButton(
              onPressed: _saveTemplate,
              child: const Text(
                'Save',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
        ],
      ),
      backgroundColor: const Color(0xFFf8f9fa),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Basic Information Section
              _buildSection(
                title: 'Basic Information',
                icon: Icons.info_outline_rounded,
                children: [
                  _buildTextField(
                    controller: _nameController,
                    label: 'Template Name',
                    hint: 'e.g., Silver Bracket',
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a template name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _descriptionController,
                    label: 'Description',
                    hint: 'Brief description of this bracket',
                    maxLines: 3,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Commission Rates Section
              _buildSection(
                title: 'Commission Rates (%)',
                icon: Icons.percent_rounded,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _lifeRateController,
                          label: 'Life Insurance',
                          hint: '8.5',
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'^\d+\.?\d{0,2}')),
                          ],
                          suffixText: '%',
                          validator: _validateRate,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTextField(
                          controller: _generalRateController,
                          label: 'General',
                          hint: '6.0',
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'^\d+\.?\d{0,2}')),
                          ],
                          suffixText: '%',
                          validator: _validateRate,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTextField(
                          controller: _mutualFundsRateController,
                          label: 'Mutual Funds',
                          hint: '4.5',
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'^\d+\.?\d{0,2}')),
                          ],
                          suffixText: '%',
                          validator: _validateRate,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Target Configuration Section
              _buildSection(
                title: 'Target Configuration',
                icon: Icons.track_changes_rounded,
                children: [
                  _buildTargetTypeSelector(),
                  const SizedBox(height: 16),

                  // Overall Target
                  if (_targetType == 'overall_amount' ||
                      _targetType == 'combined') ...[
                    _buildTextField(
                      controller: _overallAmountController,
                      label: 'Overall Target Amount (Rs)',
                      hint: '500000',
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+\.?\d{0,2}')),
                      ],
                      prefixText: 'Rs ',
                      validator: (value) {
                        if ((_targetType == 'overall_amount' ||
                                _targetType == 'combined') &&
                            (value == null || value.isEmpty)) {
                          return 'Required for this target type';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Product Targets
                  if (_targetType == 'product_wise' ||
                      _targetType == 'combined') ...[
                    _buildProductTargetSection(
                      'Life Insurance',
                      _lifeCountController,
                      _lifeAmountController,
                      const Color(0xFF0071bf),
                    ),
                    const SizedBox(height: 12),
                    _buildProductTargetSection(
                      'General Insurance',
                      _generalCountController,
                      _generalAmountController,
                      const Color(0xFF00b8d9),
                    ),
                    const SizedBox(height: 12),
                    _buildProductTargetSection(
                      'Mutual Funds',
                      _mfCountController,
                      _mfAmountController,
                      const Color(0xFF5cfbd8),
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 24),

              // Next Bracket Section
              _buildSection(
                title: 'Bracket Progression',
                icon: Icons.arrow_upward_rounded,
                children: [
                  _buildNextTemplateDropdown(),
                  const SizedBox(height: 8),
                  Text(
                    'Select the next bracket employees will progress to after achieving targets.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 100), // Space for FAB
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF272579).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    size: 18,
                    color: const Color(0xFF272579),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF272579),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey.withValues(alpha: 0.1)),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    String? prefixText,
    String? suffixText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400]),
            prefixText: prefixText,
            suffixText: suffixText,
            filled: true,
            fillColor: const Color(0xFFf8f9fa),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: const Color(0xFF272579).withValues(alpha: 0.1),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: const Color(0xFF272579).withValues(alpha: 0.1),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFF0071bf),
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTargetTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Target Type',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildTargetTypeOption(
                'overall_amount',
                'Overall',
                Icons.attach_money_rounded,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildTargetTypeOption(
                'product_wise',
                'Product-wise',
                Icons.category_rounded,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildTargetTypeOption(
                'combined',
                'Combined',
                Icons.merge_rounded,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTargetTypeOption(String value, String label, IconData icon) {
    final isSelected = _targetType == value;
    return GestureDetector(
      onTap: () => setState(() => _targetType = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF0071bf).withValues(alpha: 0.1)
              : const Color(0xFFf8f9fa),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF0071bf)
                : const Color(0xFF272579).withValues(alpha: 0.1),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? const Color(0xFF0071bf) : Colors.grey[500],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? const Color(0xFF0071bf) : Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductTargetSection(
    String title,
    TextEditingController countController,
    TextEditingController amountController,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: countController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: 'Count',
                    labelStyle: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: color.withValues(alpha: 0.3)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: color.withValues(alpha: 0.3)),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: amountController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'^\d+\.?\d{0,2}')),
                  ],
                  decoration: InputDecoration(
                    labelText: 'Amount (Rs)',
                    labelStyle: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    prefixText: 'Rs ',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: color.withValues(alpha: 0.3)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: color.withValues(alpha: 0.3)),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNextTemplateDropdown() {
    String displayText = 'Select next bracket';
    if (_selectedNextTemplateId == null) {
      // Could be explicitly set to "None" or just not selected yet
      displayText = 'None (Top bracket)';
    } else {
      try {
        final template = _availableTemplates.firstWhere(
          (t) => t.id == _selectedNextTemplateId,
        );
        displayText = template.name;
      } catch (e) {
        displayText = 'Select next bracket';
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Next Bracket (Optional)',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: _showNextTemplateBottomSheet,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFf8f9fa),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF272579).withValues(alpha: 0.1),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    displayText,
                    style: TextStyle(
                      color: _selectedNextTemplateId != null
                          ? const Color(0xFF272579)
                          : Colors.grey[600],
                      fontWeight: _selectedNextTemplateId != null
                          ? FontWeight.w500
                          : FontWeight.normal,
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
    );
  }

  void _showNextTemplateBottomSheet() {
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
                      'Select Next Bracket',
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
                    // None option
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.remove_circle_outline_rounded,
                          color: Colors.grey[600],
                          size: 20,
                        ),
                      ),
                      title: Text(
                        'None (Top bracket)',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                      subtitle: Text(
                        'This is the highest level',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                      trailing: _selectedNextTemplateId == null
                          ? const Icon(Icons.check_circle,
                              color: Color(0xFF0071bf))
                          : null,
                      onTap: () {
                        Navigator.pop(context);
                        setState(() => _selectedNextTemplateId = null);
                      },
                    ),
                    const Divider(height: 1),
                    // Template options
                    ..._availableTemplates.map((template) => ListTile(
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
                          trailing: _selectedNextTemplateId == template.id
                              ? const Icon(Icons.check_circle,
                                  color: Color(0xFF0071bf))
                              : null,
                          onTap: () {
                            Navigator.pop(context);
                            setState(() => _selectedNextTemplateId = template.id);
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

  String? _validateRate(String? value) {
    if (value == null || value.isEmpty) {
      return 'Required';
    }
    final rate = double.tryParse(value);
    if (rate == null) {
      return 'Invalid';
    }
    if (rate < 0 || rate > 100) {
      return '0-100';
    }
    return null;
  }
}

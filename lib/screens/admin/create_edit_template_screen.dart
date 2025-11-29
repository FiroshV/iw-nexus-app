import 'package:flutter/material.dart';
import '../../services/incentive_api_service.dart';

/// Screen to create or edit incentive templates
class CreateEditTemplateScreen extends StatefulWidget {
  final Map<String, dynamic>? template;

  const CreateEditTemplateScreen({
    Key? key,
    this.template,
  }) : super(key: key);

  @override
  State<CreateEditTemplateScreen> createState() =>
      _CreateEditTemplateScreenState();
}

class _CreateEditTemplateScreenState extends State<CreateEditTemplateScreen> {
  late final TextEditingController _templateNameController;
  late final TextEditingController _descriptionController;

  late String _selectedStructureType;
  final List<Map<String, dynamic>> _tiers = [];
  late final TextEditingController _flatPercentageController;
  late final TextEditingController _fixedAmountController;

  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();

    _templateNameController = TextEditingController();
    _descriptionController = TextEditingController();
    _flatPercentageController = TextEditingController();
    _fixedAmountController = TextEditingController();

    if (widget.template != null) {
      _loadTemplate(widget.template!);
    } else {
      _selectedStructureType = 'tiered';
    }
  }

  void _loadTemplate(Map<String, dynamic> template) {
    _templateNameController.text = template['templateName'] as String? ?? '';
    _descriptionController.text = template['description'] as String? ?? '';
    _selectedStructureType = template['structureType'] as String? ?? 'tiered';

    if (_selectedStructureType == 'tiered') {
      final tiers = template['tiers'] as List? ?? [];
      _tiers.addAll(tiers.map((t) => Map<String, dynamic>.from(t as Map)));
    } else if (_selectedStructureType == 'flat_percentage') {
      _flatPercentageController.text =
          (template['flatPercentage'] as num? ?? 0).toString();
    } else if (_selectedStructureType == 'fixed') {
      _fixedAmountController.text =
          (template['fixedAmount'] as num? ?? 0).toString();
    }
  }

  @override
  void dispose() {
    _templateNameController.dispose();
    _descriptionController.dispose();
    _flatPercentageController.dispose();
    _fixedAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.template == null
            ? 'Create Template'
            : 'Edit Template'),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Basic Information
              _buildBasicInfoSection(),

              const SizedBox(height: 24),

              // Structure Type Selection
              _buildStructureTypeSection(),

              const SizedBox(height: 24),

              // Structure Configuration
              _buildStructureConfigSection(),

              const SizedBox(height: 32),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSubmitting
                          ? null
                          : () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed:
                          _isSubmitting ? null : _submitForm,
                      child: _isSubmitting
                          ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                          : const Text('Save Template'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Basic Information',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _templateNameController,
          decoration: InputDecoration(
            labelText: 'Template Name',
            hintText: 'e.g., Sales Tier 1, Manager Incentive',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Template name is required';
            }
            if (value.length < 3) {
              return 'Template name must be at least 3 characters';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _descriptionController,
          decoration: InputDecoration(
            labelText: 'Description (Optional)',
            hintText: 'Describe this template...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          maxLines: 3,
          minLines: 1,
        ),
      ],
    );
  }

  Widget _buildStructureTypeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Structure Type',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(
              value: 'tiered',
              label: Text('Tiered'),
              icon: Icon(Icons.layers),
            ),
            ButtonSegment(
              value: 'flat_percentage',
              label: Text('Percentage'),
              icon: Icon(Icons.percent),
            ),
            ButtonSegment(
              value: 'fixed',
              label: Text('Fixed'),
              icon: Icon(Icons.money),
            ),
          ],
          selected: {_selectedStructureType},
          onSelectionChanged: (value) {
            setState(() {
              _selectedStructureType = value.first;
              _tiers.clear();
            });
          },
        ),
      ],
    );
  }

  Widget _buildStructureConfigSection() {
    if (_selectedStructureType == 'tiered') {
      return _buildTieredConfigSection();
    } else if (_selectedStructureType == 'flat_percentage') {
      return _buildFlatPercentageConfigSection();
    } else {
      return _buildFixedAmountConfigSection();
    }
  }

  Widget _buildTieredConfigSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Define Tiers',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Sales Range → Incentive Percentage',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 16),
        if (_tiers.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                children: [
                  Icon(Icons.layers_outlined, size: 48, color: Colors.grey[300]),
                  const SizedBox(height: 8),
                  Text(
                    'No tiers added yet',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _tiers.length,
            itemBuilder: (context, index) {
              return _buildTierItem(index);
            },
          ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: _addTier,
          icon: const Icon(Icons.add),
          label: const Text('Add Tier'),
        ),
      ],
    );
  }

  Widget _buildTierItem(int index) {
    final tier = _tiers[index];
    final nameController = TextEditingController(text: tier['name'] ?? '');
    final minController = TextEditingController(
      text: (tier['minAmount'] ?? 0).toString(),
    );
    final maxController = TextEditingController(
      text: (tier['maxAmount'] ?? 0).toString(),
    );
    final percentageController = TextEditingController(
      text: (tier['percentage'] ?? 0).toString(),
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Tier Name',
                      hintText: 'e.g., Bronze',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Name required';
                      }
                      return null;
                    },
                    onChanged: (value) => _tiers[index]['name'] = value,
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => setState(() => _tiers.removeAt(index)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: minController,
                    decoration: InputDecoration(
                      labelText: 'Min (₹)',
                      hintText: '100000',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Required';
                      if (double.tryParse(value) == null) return 'Invalid';
                      return null;
                    },
                    onChanged: (value) =>
                        _tiers[index]['minAmount'] =
                            double.tryParse(value) ?? 0,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: maxController,
                    decoration: InputDecoration(
                      labelText: 'Max (₹)',
                      hintText: '200000',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Required';
                      if (double.tryParse(value) == null) return 'Invalid';
                      return null;
                    },
                    onChanged: (value) =>
                        _tiers[index]['maxAmount'] =
                            double.tryParse(value) ?? 0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: percentageController,
              decoration: InputDecoration(
                labelText: 'Percentage (%)',
                hintText: '5',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) return 'Required';
                final num = double.tryParse(value);
                if (num == null || num < 0 || num > 100) {
                  return 'Must be 0-100';
                }
                return null;
              },
              onChanged: (value) =>
                  _tiers[index]['percentage'] =
                      double.tryParse(value) ?? 0,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFlatPercentageConfigSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Incentive Percentage',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _flatPercentageController,
          decoration: InputDecoration(
            labelText: 'Percentage (%)',
            hintText: '5',
            suffixText: '%',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Percentage is required';
            }
            final num = double.tryParse(value);
            if (num == null || num < 0 || num > 100) {
              return 'Percentage must be between 0 and 100';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'Employees will earn this percentage of their sales as incentive.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.blue[700],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFixedAmountConfigSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Fixed Incentive Amount',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _fixedAmountController,
          decoration: InputDecoration(
            labelText: 'Amount (₹)',
            hintText: '5000',
            prefixText: '₹',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Amount is required';
            }
            if (double.tryParse(value) == null) {
              return 'Please enter a valid amount';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'Employees will earn a fixed amount as incentive.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.green[700],
            ),
          ),
        ),
      ],
    );
  }

  void _addTier() {
    setState(() {
      _tiers.add({
        'name': 'Tier ${_tiers.length + 1}',
        'minAmount': 0.0,
        'maxAmount': 0.0,
        'percentage': 0.0,
      });
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedStructureType == 'tiered' && _tiers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one tier')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final templateName = _templateNameController.text.trim();
      final description = _descriptionController.text.trim();

      if (widget.template == null) {
        // Create new template
        await IncentiveApiService.createTemplate(
          templateName: templateName,
          description: description.isEmpty ? null : description,
          structureType: _selectedStructureType,
          tiers: _selectedStructureType == 'tiered' ? _tiers : null,
          flatPercentage: _selectedStructureType == 'flat_percentage'
              ? double.tryParse(_flatPercentageController.text)
              : null,
          fixedAmount: _selectedStructureType == 'fixed'
              ? double.tryParse(_fixedAmountController.text)
              : null,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Template created successfully')),
          );
          Navigator.pop(context);
        }
      } else {
        // Update existing template
        await IncentiveApiService.updateTemplate(
          templateId: widget.template!['_id'],
          templateName: templateName,
          description: description.isEmpty ? null : description,
          structureType: _selectedStructureType,
          tiers: _selectedStructureType == 'tiered' ? _tiers : null,
          flatPercentage: _selectedStructureType == 'flat_percentage'
              ? double.tryParse(_flatPercentageController.text)
              : null,
          fixedAmount: _selectedStructureType == 'fixed'
              ? double.tryParse(_fixedAmountController.text)
              : null,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Template updated successfully')),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}

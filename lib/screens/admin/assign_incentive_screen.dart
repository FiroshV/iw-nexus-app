import 'package:flutter/material.dart';
import '../../services/incentive_api_service.dart';

/// Screen to assign incentive templates to employees
class AssignIncentiveScreen extends StatefulWidget {
  final String? employeeId;
  final Map<String, dynamic>? employeeData;

  const AssignIncentiveScreen({
    Key? key,
    this.employeeId,
    this.employeeData,
  }) : super(key: key);

  @override
  State<AssignIncentiveScreen> createState() => _AssignIncentiveScreenState();
}

class _AssignIncentiveScreenState extends State<AssignIncentiveScreen> {
  String _assignmentMode = 'single'; // single, by_role
  String? _selectedTemplateId;
  String? _selectedRole;
  double _performanceMultiplier = 1.0;
  final TextEditingController _notesController = TextEditingController();

  List<Map<String, dynamic>> _templates = [];
  final List<String> _roles = [
    'admin',
    'director',
    'manager',
    'field_staff',
    'telecaller',
    'employee'
  ];

  bool _isLoading = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.employeeId != null) {
      _assignmentMode = 'single';
    }
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    setState(() => _isLoading = true);

    try {
      final templates = await IncentiveApiService.getAllTemplates();
      setState(() {
        _templates = templates;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading templates: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assign Incentive'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.employeeId == null)
                  _buildAssignmentModeSelector(),
                const SizedBox(height: 24),
                _buildTemplateSelector(),
                const SizedBox(height: 24),
                if (_assignmentMode == 'single' || widget.employeeId != null)
                  _buildSingleAssignmentSection()
                else
                  _buildBulkAssignmentSection(),
                const SizedBox(height: 24),
                _buildPerformanceMultiplierSection(),
                const SizedBox(height: 24),
                _buildNotesSection(),
                const SizedBox(height: 32),
                _buildActionButtons(),
                const SizedBox(height: 16),
              ],
            ),
          ),
    );
  }

  Widget _buildAssignmentModeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Assignment Mode',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(
              value: 'single',
              label: Text('Single Employee'),
              icon: Icon(Icons.person),
            ),
            ButtonSegment(
              value: 'by_role',
              label: Text('By Role'),
              icon: Icon(Icons.group),
            ),
          ],
          selected: {_assignmentMode},
          onSelectionChanged: (value) {
            setState(() => _assignmentMode = value.first);
          },
        ),
      ],
    );
  }

  Widget _buildTemplateSelector() {
    if (_templates.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            children: [
              Icon(Icons.dashboard_customize_rounded,
                  size: 48, color: Colors.grey[300]),
              const SizedBox(height: 8),
              Text(
                'No templates available',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Template',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _selectedTemplateId,
          decoration: InputDecoration(
            labelText: 'Incentive Template',
            hintText: 'Choose a template...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          items: _templates
              .map(
                (template) => DropdownMenuItem(
              value: template['_id'] as String,
              child: Text(template['templateName'] as String? ?? 'Unnamed'),
            ),
              )
              .toList(),
          onChanged: (value) => setState(() => _selectedTemplateId = value),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select a template';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildSingleAssignmentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Employee',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        if (widget.employeeData != null)
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: Colors.grey[200]!),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.grey[300],
                    child: const Icon(Icons.person),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${widget.employeeData!['firstName'] ?? ''} ${widget.employeeData!['lastName'] ?? ''}',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          widget.employeeData!['email'] as String? ?? '',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Single employee assignment mode',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBulkAssignmentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Employees',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _selectedRole,
          decoration: InputDecoration(
            labelText: 'Assign to all employees with role',
            hintText: 'Choose a role...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          items: _roles
              .map(
                (role) => DropdownMenuItem(
              value: role,
              child: Text(
                role[0].toUpperCase() + role.substring(1).replaceAll('_', ' '),
              ),
            ),
              )
              .toList(),
          onChanged: (value) => setState(() => _selectedRole = value),
          validator: (value) {
            if (_assignmentMode == 'by_role' &&
                (value == null || value.isEmpty)) {
              return 'Please select a role';
            }
            return null;
          },
        ),
        if (_selectedRole != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'This template will be assigned to all active employees with the selected role',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.blue[700],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPerformanceMultiplierSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Performance Multiplier',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF0071bf).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${(_performanceMultiplier * 100).toStringAsFixed(0)}%',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: const Color(0xFF0071bf),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Slider(
          value: _performanceMultiplier,
          min: 0.5,
          max: 2.0,
          divisions: 30,
          label: '${(_performanceMultiplier * 100).toStringAsFixed(0)}%',
          onChanged: (value) => setState(() => _performanceMultiplier = value),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Wrap(
              spacing: 8,
              children: [
                _buildMultiplierQuickButton('50%', 0.5),
                _buildMultiplierQuickButton('100%', 1.0),
                _buildMultiplierQuickButton('120%', 1.2),
                _buildMultiplierQuickButton('150%', 1.5),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.amber[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'Higher multiplier increases the incentive percentage. Default is 100% (1.0x)',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.amber[900],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMultiplierQuickButton(String label, double value) {
    return ChoiceChip(
      label: Text(label),
      selected: _performanceMultiplier == value,
      onSelected: (selected) {
        if (selected) {
          setState(() => _performanceMultiplier = value);
        }
      },
    );
  }

  Widget _buildNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Notes (Optional)',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _notesController,
          decoration: InputDecoration(
            hintText: 'Add notes about this assignment...',
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

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _isSubmitting ? null : () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _submitAssignment,
            child: _isSubmitting
                ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : const Text('Assign'),
          ),
        ),
      ],
    );
  }

  Future<void> _submitAssignment() async {
    if (_selectedTemplateId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a template')),
      );
      return;
    }

    if (_assignmentMode == 'single' && widget.employeeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No employee selected')),
      );
      return;
    }

    if (_assignmentMode == 'by_role' && _selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a role')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      if (_assignmentMode == 'single' && widget.employeeId != null) {
        // Single assignment
        await IncentiveApiService.assignTemplate(
          employeeId: widget.employeeId!,
          templateId: _selectedTemplateId!,
          performanceMultiplier: _performanceMultiplier,
          notes: _notesController.text.isEmpty ? null : _notesController.text,
        );
      } else {
        // Bulk assignment by role
        await IncentiveApiService.bulkAssignTemplate(
          templateId: _selectedTemplateId!,
          role: _selectedRole,
          performanceMultiplier: _performanceMultiplier,
          notes: _notesController.text.isEmpty ? null : _notesController.text,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Incentive assigned successfully')),
        );
        Navigator.pop(context, true);
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

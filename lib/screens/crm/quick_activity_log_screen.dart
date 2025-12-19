import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/crm_colors.dart';
import '../../config/crm_design_system.dart';
import '../../models/customer.dart';
import '../../services/activity_service.dart';
import '../../services/api_service.dart';
import '../../widgets/crm/employee_selection_section.dart';

class QuickActivityLogScreen extends StatefulWidget {
  final String userId;
  final String userRole;
  final String? initialCustomerId;
  final String? initialActivityType;
  final String? initialPhoneNumber;
  final int? initialDurationSeconds;

  const QuickActivityLogScreen({
    super.key,
    required this.userId,
    required this.userRole,
    this.initialCustomerId,
    this.initialActivityType,
    this.initialPhoneNumber,
    this.initialDurationSeconds,
  });

  @override
  State<QuickActivityLogScreen> createState() => _QuickActivityLogScreenState();
}

class _QuickActivityLogScreenState extends State<QuickActivityLogScreen> {
  // Form state
  Customer? _selectedCustomer;
  String _selectedActivityType = 'quick_call';
  String _selectedOutcome = 'connected';
  DateTime _activityDate = DateTime.now();
  int? _durationSeconds;
  String? _phoneNumber;

  // UI state
  List<Customer> _customers = [];
  List<dynamic> _employees = [];
  List<String> _selectedEmployees = [];
  bool _isLoading = false;
  bool _isSaving = false;

  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _durationSecondsController = TextEditingController();

  final List<String> _activityTypes = [
    'walkin_visit',
    'quick_call',
    'email',
    'whatsapp',
    'sms',
    'other',
  ];

  /// Get available outcomes based on activity type.
  /// Phone calls can include 'busy' and 'failed' outcomes.
  /// Other activity types exclude these call-specific outcomes.
  List<String> get _outcomes {
    if (_selectedActivityType == 'quick_call') {
      return [
        'connected',
        'no_answer',
        'voicemail',
        'busy',
        'failed',
        'interested',
        'not_interested',
        'callback_requested',
        'other',
      ];
    }

    // For non-call activities, exclude call-specific outcomes
    return [
      'connected',
      'no_answer',
      'voicemail',
      'interested',
      'not_interested',
      'callback_requested',
      'other',
    ];
  }

  @override
  void initState() {
    super.initState();
    _loadCustomers();
    _loadEmployees();

    // Handle pre-population parameters (for post-call logging)
    if (widget.initialActivityType != null) {
      _selectedActivityType = widget.initialActivityType!;
    }

    if (widget.initialPhoneNumber != null) {
      _phoneNumber = widget.initialPhoneNumber;
    }

    if (widget.initialDurationSeconds != null) {
      _durationSeconds = widget.initialDurationSeconds;
      _durationSecondsController.text = widget.initialDurationSeconds.toString();
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    _durationSecondsController.dispose();
    super.dispose();
  }

  Future<void> _loadEmployees() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.get('/crm/employees?limit=100');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _employees = (data['data'] as List).toList();
          });
        }
      }
    } catch (e) {
      // Silent fail - employees are optional
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadCustomers() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.getCustomers(limit: 500);
      if (response.success && response.data != null) {
        List<dynamic> customersList = [];
        if (response.data is List) {
          customersList = response.data as List;
        } else if (response.data is Map<String, dynamic>) {
          customersList = (response.data as Map)['data'] ?? [];
        }

        final customers = customersList
            .map((c) => Customer.fromJson(c as Map<String, dynamic>))
            .toList();

        if (mounted) {
          setState(() => _customers = customers);

          // Select initial customer if provided
          if (widget.initialCustomerId != null) {
            _selectedCustomer = customers.firstWhere(
              (c) => c.id == widget.initialCustomerId,
              orElse: () => customers.first,
            );
          }
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load customers: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getActivityTypeLabel(String type) {
    const labels = {
      'walkin_visit': 'In-Person Visit',
      'quick_call': 'Phone Call',
      'email': 'Email',
      'whatsapp': 'WhatsApp',
      'sms': 'SMS',
      'other': 'Other',
    };
    return labels[type] ?? type;
  }

  String _getOutcomeLabel(String outcome) {
    const labels = {
      'connected': 'Connected',
      'no_answer': 'No Answer',
      'voicemail': 'Voicemail',
      'busy': 'Busy',
      'failed': 'Failed',
      'interested': 'Interested',
      'not_interested': 'Not Interested',
      'callback_requested': 'Callback Requested',
      'other': 'Other',
    };
    return labels[outcome] ?? outcome;
  }

  void _showCustomerBottomSheet() {
    List<Customer> filteredCustomers = _customers;
    final TextEditingController searchController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: CrmDesignSystem.lg,
                    vertical: CrmDesignSystem.md,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Select Customer',
                        style: CrmDesignSystem.titleMedium,
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
                // Search field
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: CrmDesignSystem.lg,
                    vertical: CrmDesignSystem.md,
                  ),
                  child: TextField(
                    controller: searchController,
                    onChanged: (query) {
                      setModalState(() {
                        if (query.isEmpty) {
                          filteredCustomers = _customers;
                        } else {
                          final lowerQuery = query.toLowerCase();
                          filteredCustomers = _customers.where((customer) {
                            final name = customer.name.toLowerCase();
                            final mobile = customer.mobileNumber.toLowerCase();
                            return name.contains(lowerQuery) || mobile.contains(lowerQuery);
                          }).toList();
                        }
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search by name or phone...',
                      prefixIcon: const Icon(Icons.search, color: CrmColors.primary),
                      suffixIcon: searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                searchController.clear();
                                setModalState(() {
                                  filteredCustomers = _customers;
                                });
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(CrmDesignSystem.radiusMedium),
                      ),
                      filled: true,
                      fillColor: CrmColors.surface,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: CrmDesignSystem.md,
                        vertical: CrmDesignSystem.md,
                      ),
                    ),
                  ),
                ),
                // Customer list
                Expanded(
                  child: filteredCustomers.isEmpty
                      ? Center(
                          child: Text(
                            'No customers found',
                            style: CrmDesignSystem.bodySmall.copyWith(
                              color: CrmColors.textLight,
                            ),
                          ),
                        )
                      : ListView.separated(
                          controller: scrollController,
                          itemCount: filteredCustomers.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final customer = filteredCustomers[index];
                            final isSelected = _selectedCustomer?.id == customer.id;
                            return ListTile(
                              onTap: () {
                                setState(() => _selectedCustomer = customer);
                                Navigator.pop(context);
                              },
                              title: Text(customer.name),
                              subtitle: Text(customer.mobileNumber),
                              trailing: isSelected
                                  ? Icon(Icons.check_circle, color: CrmColors.primary)
                                  : null,
                              selected: isSelected,
                              selectedTileColor: CrmColors.primary.withValues(alpha: 0.1),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showActivityTypeBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.all(CrmDesignSystem.lg),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Select Activity Type',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: CrmColors.textDark,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: CrmColors.textLight),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              SizedBox(height: CrmDesignSystem.md),

              // Activity type options
              ..._activityTypes.map((type) {
                final isSelected = _selectedActivityType == type;
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedActivityType = type);
                    Navigator.pop(context);
                  },
                  child: Container(
                    margin: EdgeInsets.only(bottom: CrmDesignSystem.md),
                    padding: EdgeInsets.all(CrmDesignSystem.md),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? CrmColors.primary.withValues(alpha: 0.1)
                          : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(CrmDesignSystem.radiusMedium),
                      border: Border.all(
                        color: isSelected ? CrmColors.primary : Colors.grey.shade200,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            _getActivityTypeLabel(type),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                              color: CrmColors.textDark,
                            ),
                          ),
                        ),
                        if (isSelected)
                          Icon(
                            Icons.check_circle,
                            color: CrmColors.primary,
                            size: 24,
                          ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  void _showOutcomeBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.all(CrmDesignSystem.lg),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Select Outcome',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: CrmColors.textDark,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: CrmColors.textLight),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              SizedBox(height: CrmDesignSystem.md),

              // Outcome options
              ..._outcomes.map((outcome) {
                final isSelected = _selectedOutcome == outcome;
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedOutcome = outcome);
                    Navigator.pop(context);
                  },
                  child: Container(
                    margin: EdgeInsets.only(bottom: CrmDesignSystem.md),
                    padding: EdgeInsets.all(CrmDesignSystem.md),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? CrmColors.primary.withValues(alpha: 0.1)
                          : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(CrmDesignSystem.radiusMedium),
                      border: Border.all(
                        color: isSelected ? CrmColors.primary : Colors.grey.shade200,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            _getOutcomeLabel(outcome),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                              color: CrmColors.textDark,
                            ),
                          ),
                        ),
                        if (isSelected)
                          Icon(
                            Icons.check_circle,
                            color: CrmColors.primary,
                            size: 24,
                          ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectActivityDate() async {
    final DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: _activityDate,
      firstDate: DateTime.now().subtract(Duration(days: 365)),
      lastDate: DateTime.now().add(Duration(days: 30)),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: CrmColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: CrmColors.textDark,
            ),
          ),
          child: child ?? const SizedBox(),
        );
      },
    );

    if (selectedDate != null) {
      setState(() => _activityDate = selectedDate);
    }
  }

  Future<void> _saveActivity() async {
    // Validate
    if (_selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a customer')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Prepare assigned employees data
      final assignedEmployees = _selectedEmployees.map((empId) {
        final employee = _employees.firstWhere(
          (e) => e['_id'] == empId || e['id'] == empId,
          orElse: () => {'_id': empId, 'firstName': 'Unknown', 'lastName': ''},
        );
        final firstName = employee['firstName'] as String? ?? '';
        final lastName = employee['lastName'] as String? ?? '';
        final userName = '$firstName $lastName'.trim();

        return {
          'userId': empId,
          'userName': userName,
          'role': 'secondary',
        };
      }).toList();

      // Create activity
      final activityResponse = await ActivityService.createActivity(
        customerId: _selectedCustomer!.id,
        type: _selectedActivityType,
        outcome: _selectedOutcome,
        activityDate: _activityDate,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        durationMinutes: _durationSeconds != null ? (_durationSeconds! / 60).round() : null,
        assignedEmployees: assignedEmployees.isNotEmpty ? assignedEmployees : null,
      );

      if (!mounted) return;

      if (!activityResponse.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to log activity: ${activityResponse.error}')),
        );
        setState(() => _isSaving = false);
        return;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Activity logged successfully')),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity Log'),
        backgroundColor: CrmColors.primary,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(CrmDesignSystem.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Call context banner (shown when logging a call)
                  if (_phoneNumber != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(CrmDesignSystem.md),
                      decoration: BoxDecoration(
                        color: CrmColors.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(CrmDesignSystem.radiusMedium),
                        border: Border.all(color: CrmColors.success.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.call_made,
                            color: CrmColors.success,
                            size: 20,
                          ),
                          const SizedBox(width: CrmDesignSystem.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Log call to $_phoneNumber',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: CrmColors.success,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Duration: ${_formatDuration(_durationSeconds)}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: CrmColors.success.withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: CrmDesignSystem.lg),
                  ],

                  // Customer Selection
                  _buildSectionTitle('Customer'),
                  const SizedBox(height: CrmDesignSystem.sm),
                  GestureDetector(
                    onTap: _showCustomerBottomSheet,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: CrmDesignSystem.md,
                        vertical: CrmDesignSystem.md,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: CrmColors.borderColor),
                        borderRadius: BorderRadius.circular(CrmDesignSystem.radiusMedium),
                        color: Colors.white,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _selectedCustomer?.name ?? 'Select customer...',
                            style: TextStyle(
                              fontSize: 14,
                              color: _selectedCustomer != null
                                  ? CrmColors.textDark
                                  : CrmColors.textLight,
                            ),
                          ),
                          Icon(Icons.expand_more, color: CrmColors.primary),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: CrmDesignSystem.lg),

                  // Activity Type
                  _buildSectionTitle('Activity Type'),
                  const SizedBox(height: CrmDesignSystem.sm),
                  GestureDetector(
                    onTap: _showActivityTypeBottomSheet,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: CrmDesignSystem.md,
                        vertical: CrmDesignSystem.md,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: CrmColors.borderColor),
                        borderRadius: BorderRadius.circular(CrmDesignSystem.radiusMedium),
                        color: Colors.white,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _getActivityTypeLabel(_selectedActivityType),
                            style: TextStyle(
                              fontSize: 14,
                              color: CrmColors.textDark,
                            ),
                          ),
                          Icon(Icons.expand_more, color: CrmColors.primary),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: CrmDesignSystem.lg),

                  // Outcome
                  _buildSectionTitle('Outcome'),
                  const SizedBox(height: CrmDesignSystem.sm),
                  GestureDetector(
                    onTap: _showOutcomeBottomSheet,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: CrmDesignSystem.md,
                        vertical: CrmDesignSystem.md,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: CrmColors.borderColor),
                        borderRadius: BorderRadius.circular(CrmDesignSystem.radiusMedium),
                        color: Colors.white,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _getOutcomeLabel(_selectedOutcome),
                            style: TextStyle(
                              fontSize: 14,
                              color: CrmColors.textDark,
                            ),
                          ),
                          Icon(Icons.expand_more, color: CrmColors.primary),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: CrmDesignSystem.lg),

                  // Duration (only for quick calls)
                  if (_selectedActivityType == 'quick_call') ...[
                    _buildSectionTitle('Call Duration'),
                    const SizedBox(height: CrmDesignSystem.sm),
                    // Quick duration options
                    Wrap(
                      spacing: CrmDesignSystem.sm,
                      children: [
                        _buildDurationChip('< 1 min', 30),
                        _buildDurationChip('1-3 min', 120),
                        _buildDurationChip('3-5 min', 240),
                        _buildDurationChip('> 5 min', 600),
                      ],
                    ),
                    const SizedBox(height: CrmDesignSystem.md),
                    // Manual duration input
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _durationSecondsController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              hintText: 'Seconds',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(CrmDesignSystem.radiusMedium),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: CrmDesignSystem.md,
                                vertical: CrmDesignSystem.sm,
                              ),
                            ),
                            onChanged: (value) {
                              setState(() {
                                _durationSeconds = int.tryParse(value);
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: CrmDesignSystem.md),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: CrmDesignSystem.md,
                            vertical: CrmDesignSystem.sm,
                          ),
                          decoration: BoxDecoration(
                            color: CrmColors.surface,
                            borderRadius: BorderRadius.circular(CrmDesignSystem.radiusMedium),
                            border: Border.all(color: CrmColors.borderColor),
                          ),
                          child: Text(
                            _formatDuration(_durationSeconds),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: CrmColors.textDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: CrmDesignSystem.lg),
                  ],

                  // Activity Date
                  _buildSectionTitle('Activity Date'),
                  const SizedBox(height: CrmDesignSystem.sm),
                  GestureDetector(
                    onTap: _selectActivityDate,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: CrmDesignSystem.md,
                        vertical: CrmDesignSystem.md,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: CrmColors.borderColor),
                        borderRadius: BorderRadius.circular(CrmDesignSystem.radiusMedium),
                        color: Colors.white,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            DateFormat('MMM dd, yyyy').format(_activityDate),
                            style: TextStyle(
                              fontSize: 14,
                              color: CrmColors.textDark,
                            ),
                          ),
                          Icon(Icons.calendar_today, color: CrmColors.primary),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: CrmDesignSystem.lg),

                  // Notes
                  _buildSectionTitle('Notes'),
                  const SizedBox(height: CrmDesignSystem.sm),
                  TextField(
                    controller: _notesController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'What was discussed?',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(CrmDesignSystem.radiusLarge),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: CrmDesignSystem.md,
                        vertical: CrmDesignSystem.md,
                      ),
                    ),
                  ),
                  const SizedBox(height: CrmDesignSystem.lg),

                  // Assign Employees Section (only for in-person visits)
                  if (_selectedActivityType == 'walkin_visit') ...[
                    _buildSectionTitle('Assign Employees (Optional)'),
                    const SizedBox(height: CrmDesignSystem.sm),
                    EmployeeSelectionSection(
                      allEmployees: _employees,
                      selectedEmployeeIds: _selectedEmployees,
                      currentUserId: widget.userId,
                      onEmployeesChanged: (ids) => setState(() => _selectedEmployees = ids),
                      maxEmployees: 5,
                    ),
                    const SizedBox(height: CrmDesignSystem.xl),
                  ] else ...[
                    const SizedBox(height: CrmDesignSystem.xl),
                  ],

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveActivity,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: CrmColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: CrmDesignSystem.md),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(CrmDesignSystem.radiusLarge),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Submit',
                              style: TextStyle(fontSize: 16, color: Colors.white),
                            ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: CrmDesignSystem.titleMedium.copyWith(
        color: CrmColors.textDark,
      ),
    );
  }

  Widget _buildDurationChip(String label, int seconds) {
    final isSelected = _durationSeconds == seconds;
    return GestureDetector(
      onTap: () {
        setState(() {
          _durationSeconds = seconds;
          _durationSecondsController.text = seconds.toString();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: CrmDesignSystem.md,
          vertical: CrmDesignSystem.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected ? CrmColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(CrmDesignSystem.radiusMedium),
          border: Border.all(
            color: isSelected ? CrmColors.primary : CrmColors.borderColor,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : CrmColors.textDark,
          ),
        ),
      ),
    );
  }

  String _formatDuration(int? seconds) {
    if (seconds == null || seconds <= 0) {
      return '00:00';
    }
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}

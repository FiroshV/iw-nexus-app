import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/crm_colors.dart';
import '../../config/crm_design_system.dart';
import '../../models/appointment.dart';
import '../../models/customer.dart';
import '../../models/slot_availability_info.dart';
import '../../services/appointment_service.dart';
import '../../services/api_service.dart';
import '../../widgets/crm/employee_selection_section.dart';
import '../../widgets/crm/time_slot_availability_grid.dart';

class SimplifiedAppointmentScreen extends StatefulWidget {
  final String userId;
  final String userRole;
  final String? initialCustomerId;

  const SimplifiedAppointmentScreen({
    super.key,
    required this.userId,
    required this.userRole,
    this.initialCustomerId,
  });

  @override
  State<SimplifiedAppointmentScreen> createState() => _SimplifiedAppointmentScreenState();
}

class _SimplifiedAppointmentScreenState extends State<SimplifiedAppointmentScreen> {
  // Form state
  Customer? _selectedCustomer;
  String _selectedActivityType = 'in_person_visit';
  DateTime _selectedDate = DateTime.now();
  String? _selectedStartTime = '09:00';
  List<EmployeeAssignment> _selectedEmployees = [];
  String? _selectedPurpose; // Enum value from dropdown

  // Availability state
  bool _isLoadingAvailability = false;
  final Map<String, Map<String, dynamic>> _employeeSchedules = {}; // employeeId -> {busySlots, availableSlots, employeeName, employeeRole}
  List<SlotAvailabilityInfo> _slotAvailabilityData = []; // Complete slot info with busy employee tracking

  // UI state
  List<Customer> _customers = [];
  List<dynamic> _employees = [];
  bool _isLoading = false;
  bool _isSaving = false;

  final TextEditingController _purposeOtherController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  final List<String> _activityTypes = [
    'in_person_visit',
    'phone_call',
    'email',
    'whatsapp_message',
    'document_collection',
    'policy_renewal',
    'other',
  ];

  // Purpose enum values mapped to display labels
  final Map<String, String> _purposeOptions = {
    'new_sale_discussion': 'New Sale Discussion',
    'document_collection': 'Document Collection',
    'policy_renewal': 'Policy Renewal',
    'kyc_verification': 'KYC Verification',
    'claim_assistance': 'Claim Assistance',
    'follow_up_conversation': 'Follow Up Conversation',
    'other': 'Other',
  };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      await Future.wait([_loadCustomers(), _loadEmployees()]);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadCustomers() async {
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
    }
  }

  Future<void> _loadEmployees() async {
    try {
      final response = await ApiService.get('/crm/employees?limit=100');
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        final employeesList = (jsonData['data'] ?? []) as List;

        if (mounted) {
          // Add current user as default employee
          _selectedEmployees = [
            EmployeeAssignment(
              userId: widget.userId,
              role: 'primary',
            )
          ];

          setState(() => _employees = employeesList);

          // Load schedules for the current user with today's date
          _loadEmployeeSchedules();
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load employees: $e')),
      );
    }
  }

  String _getActivityTypeLabel(String type) {
    const labels = {
      'in_person_visit': 'In-Person Visit',
      'phone_call': 'Phone Call',
      'email': 'Email',
      'whatsapp_message': 'WhatsApp',
      'document_collection': 'Document Collection',
      'policy_renewal': 'Policy Renewal',
      'other': 'Other',
    };
    return labels[type] ?? type;
  }

  // Load employee schedules for selected employees and date
  Future<void> _loadEmployeeSchedules() async {
    if (_selectedEmployees.isEmpty || _selectedActivityType != 'in_person_visit') {
      return;
    }

    setState(() => _isLoadingAvailability = true);

    try {
      // Clear previous data
      _employeeSchedules.clear();

      debugPrint('Loading schedules for ${_selectedEmployees.length} employees on $_selectedDate');

      // Fetch schedule for each selected employee
      for (var emp in _selectedEmployees) {
        final response = await AppointmentService.getEmployeeSchedule(emp.userId, _selectedDate);

        debugPrint('API Response for ${emp.userId}: success=${response.success}, data=${response.data}');

        if (response.success && response.data != null) {
          final scheduleData = response.data as Map<String, dynamic>;

          // Extract BOTH busySlots and availableSlots from API response
          final busyList = (scheduleData['busySlots'] as List?) ?? [];
          final availableList = (scheduleData['availableSlots'] as List?) ?? [];

          debugPrint('Employee ${emp.userId}: busySlots=${busyList.length}, availableSlots=${availableList.length}');

          _employeeSchedules[emp.userId] = {
            'busySlots': busyList
                .map((slot) => {
                  'appointmentId': slot['appointmentId'],
                  'customer': slot['customer'],
                  'startTime': slot['startTime'],
                  'endTime': slot['endTime'],
                })
                .toList(),
            'availableSlots': availableList
                .map((slot) => TimeSlot.fromJson(slot as Map<String, dynamic>))
                .toList(),
            'employeeName': emp.userName ?? 'Unknown',
            'employeeRole': emp.role,
          };
        } else {
          debugPrint('API call failed for ${emp.userId}: ${response.message}');
        }
      }

      debugPrint('Total employees with schedules: ${_employeeSchedules.length}');

      // Compute complete slot availability with busy employee tracking
      _computeSlotAvailabilityData();

      debugPrint('Computed slots: ${_slotAvailabilityData.length}');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: CrmDesignSystem.sm),
                Expanded(
                  child: Text('Error loading schedules: Unable to fetch availability data'),
                ),
              ],
            ),
            backgroundColor: CrmColors.errorColor,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _loadEmployeeSchedules,
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingAvailability = false);
      }
    }
  }

  // Compute complete slot availability with busy employee tracking
  void _computeSlotAvailabilityData() {
    try {
      if (_employeeSchedules.isEmpty) {
        setState(() => _slotAvailabilityData = []);
        return;
      }

      // Generate all possible time slots (09:00-18:00)
      final allTimeSlots = <String>[
        '09:00',
        '10:00',
        '11:00',
        '12:00',
        '13:00',
        '14:00',
        '15:00',
        '16:00',
        '17:00',
      ];

      final List<SlotAvailabilityInfo> slotData = [];

      for (final startTime in allTimeSlots) {
        final endTime = _getEndTime(startTime);
        final timeSlot = TimeSlot(startTime: startTime, endTime: endTime);

        // Track which employees are busy at this slot
        final List<EmployeeSlotInfo> busyEmployees = [];
        bool allAvailable = true;

        for (final entry in _employeeSchedules.entries) {
          final employeeId = entry.key;
          final scheduleData = entry.value;
          final busySlots = (scheduleData['busySlots'] as List?) ?? [];

          // Check if employee is busy at this slot
          Map<String, dynamic>? busySlot;
          try {
            busySlot = busySlots.firstWhere(
              (slot) => slot['startTime'] == startTime,
            ) as Map<String, dynamic>?;
          } catch (_) {
            busySlot = null;
          }

          if (busySlot != null) {
            allAvailable = false;

            final customer = busySlot['customer'];
            busyEmployees.add(EmployeeSlotInfo(
              userId: employeeId,
              userName: scheduleData['employeeName'] ?? 'Unknown',
              role: scheduleData['employeeRole'],
              conflictingAppointment: AppointmentInfo(
                appointmentId: busySlot['appointmentId'] ?? '',
                customerName: customer?['name'],
                customerPhone: customer?['mobileNumber'],
                startTime: busySlot['startTime'] ?? '',
                endTime: busySlot['endTime'] ?? '',
              ),
            ));
          }
        }

        slotData.add(SlotAvailabilityInfo(
          timeSlot: timeSlot,
          isAvailable: allAvailable,
          busyEmployees: busyEmployees,
        ));
      }

      setState(() => _slotAvailabilityData = slotData);

      debugPrint('Computed slots: ${_slotAvailabilityData.length}');

      // Reset selected time if it's no longer available
      if (_selectedStartTime != null &&
          !slotData.any((s) => s.isAvailable && s.timeSlot.startTime == _selectedStartTime)) {
        setState(() => _selectedStartTime = null);
      }
    } catch (e) {
      debugPrint('Error in _computeSlotAvailabilityData: $e');
      rethrow;
    }
  }

  // Helper method to get end time from start time
  String _getEndTime(String startTime) {
    final parts = startTime.split(':');
    int hour = int.parse(parts[0]);
    final minute = parts[1];
    hour = (hour + 1) % 24;
    return '${hour.toString().padLeft(2, '0')}:$minute';
  }

  // Show customer selection bottom sheet
  void _showCustomerBottomSheet() {
    List<Customer> _filteredCustomers = _customers;
    final TextEditingController _searchController = TextEditingController();

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
                    controller: _searchController,
                    onChanged: (query) {
                      setModalState(() {
                        if (query.isEmpty) {
                          _filteredCustomers = _customers;
                        } else {
                          final lowerQuery = query.toLowerCase();
                          _filteredCustomers = _customers.where((customer) {
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
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setModalState(() {
                                  _filteredCustomers = _customers;
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
                  child: _filteredCustomers.isEmpty
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
                          itemCount: _filteredCustomers.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final customer = _filteredCustomers[index];
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

  // Show activity type selection bottom sheet
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
                    'Select Appointment Type',
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
                    setState(() {
                      _selectedActivityType = type;
                      _selectedStartTime = null; // Reset time selection
                      _employeeSchedules.clear();
                      _slotAvailabilityData.clear();
                    });
                    // Load schedules if switching to in-person visit
                    if (type == 'in_person_visit') {
                      _loadEmployeeSchedules();
                    }
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

  // Show purpose selection bottom sheet
  void _showPurposeBottomSheet() {
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
                    'Select Purpose',
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

              // Purpose options
              ..._purposeOptions.entries.map((entry) {
                final isSelected = _selectedPurpose == entry.key;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedPurpose = entry.key;
                      if (entry.key != 'other') {
                        _purposeOtherController.clear();
                      }
                    });
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
                            entry.value,
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

  // Check availability before submission
  Future<bool> _checkAvailabilityBeforeSubmit() async {
    if (_selectedActivityType != 'in_person_visit' || _selectedStartTime == null) {
      return true;
    }

    final endTime = _getEndTime(_selectedStartTime!);
    final employeeIds = _selectedEmployees.map((e) => e.userId).toList();

    final response = await AppointmentService.checkAvailability(
      employeeIds: employeeIds,
      scheduledDate: _selectedDate,
      timeSlot: TimeSlot(
        startTime: _selectedStartTime!,
        endTime: endTime,
      ),
    );

    if (response.success && response.data != null) {
      final available = response.data!['available'] as bool?;

      if (available == false) {
        final conflicts = response.data!['conflicts'] as List?;
        final suggestions = response.data!['suggestions'] as List?;
        if (mounted) {
          _showConflictDialog(conflicts, suggestions);
        }
        return false;
      }
    }

    return true;
  }

  // Show conflict dialog with suggestions
  void _showConflictDialog(List? conflicts, List? suggestions) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Scheduling Conflict'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('One or more employees are not available at this time.'),
              if (conflicts != null && conflicts.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Conflicting Employees:',
                  style: CrmDesignSystem.titleSmall,
                ),
                const SizedBox(height: 8),
                ...conflicts.map((c) {
                  final empName = c['employeeName'] ?? c['employeeId'] ?? 'Unknown';
                  return Text('• $empName');
                }),
              ],
              if (suggestions != null && suggestions.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Suggested Alternative Times:',
                  style: CrmDesignSystem.titleSmall,
                ),
                const SizedBox(height: 8),
                ...suggestions.map((s) {
                  final startTime = s['startTime'] ?? s['start_time'] ?? '';
                  final endTime = s['endTime'] ?? s['end_time'] ?? '';
                  return TextButton(
                    onPressed: () {
                      setState(() => _selectedStartTime = startTime);
                      Navigator.pop(context);
                    },
                    child: Text('$startTime - $endTime'),
                  );
                }),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveAppointment() async {
    // Validate
    if (_selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a customer')),
      );
      return;
    }

    if (_selectedEmployees.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one employee')),
      );
      return;
    }

    // Validate purpose is selected
    if (_selectedPurpose == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a purpose')),
      );
      return;
    }

    // Validate purposeOther if purpose is 'other'
    if (_selectedPurpose == 'other' && _purposeOtherController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please specify the purpose')),
      );
      return;
    }

    // Additional validation for in-person visits
    if (_selectedActivityType == 'in_person_visit') {
      if (_selectedStartTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a time slot')),
        );
        return;
      }

      // Check availability before submission
      final isAvailable = await _checkAvailabilityBeforeSubmit();
      if (!isAvailable) {
        return; // Conflict dialog already shown
      }
    }

    setState(() => _isSaving = true);

    try {
      // Prepare appointment data
      // Send only the date part (YYYY-MM-DD) to avoid timezone issues
      // The time comes from scheduledTimeSlot
      final dateString = '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';

      final appointmentData = {
        'customerId': _selectedCustomer!.id,
        'activityType': _selectedActivityType,
        'scheduledDate': dateString,
        'assignedEmployees': _selectedEmployees.map((e) => e.toJson()).toList(),
        'purpose': _selectedPurpose,
        'notes': _notesController.text.isNotEmpty ? _notesController.text : null,
      };

      // Add purposeOther if purpose is 'other'
      if (_selectedPurpose == 'other') {
        appointmentData['purposeOther'] = _purposeOtherController.text.isNotEmpty ? _purposeOtherController.text : null;
      }

      // Add time slot if in-person visit
      if (_selectedActivityType == 'in_person_visit' && _selectedStartTime != null) {
        final endTime = _getEndTime(_selectedStartTime!);
        appointmentData['scheduledTimeSlot'] = {
          'startTime': _selectedStartTime,
          'endTime': endTime,
        };
      }

      debugPrint('📤 APPOINTMENT REQUEST:');
      debugPrint('  Customer ID: ${appointmentData['customerId']}');
      debugPrint('  Activity Type: ${appointmentData['activityType']}');
      debugPrint('  Scheduled Date: ${appointmentData['scheduledDate']}');
      debugPrint('  Assigned Employees: ${appointmentData['assignedEmployees']}');
      debugPrint('  Purpose: ${appointmentData['purpose']}');
      debugPrint('  Notes: ${appointmentData['notes']}');
      if (appointmentData.containsKey('scheduledTimeSlot')) {
        debugPrint('  Time Slot: ${appointmentData['scheduledTimeSlot']}');
      }
      debugPrint('  Full Payload: $appointmentData');

      // Call API
      final response = await AppointmentService.createAppointment(appointmentData);

      debugPrint('📥 APPOINTMENT RESPONSE:');
      debugPrint('  Success: ${response.success}');
      debugPrint('  Message: ${response.message}');
      debugPrint('  Error: ${response.error}');
      debugPrint('  Data: ${response.data}');

      if (!mounted) return;

      if (response.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Appointment scheduled successfully')),
        );
        Navigator.of(context).pop(true);
      } else {
        final errorMsg = response.message ?? response.error?.toString() ?? 'Failed to create appointment';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg)),
        );
      }
    } catch (e) {
      if (!mounted) return;
      debugPrint('❌ APPOINTMENT ERROR: $e');
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
  void dispose() {
    _purposeOtherController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule Appointment'),
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
                  _buildSectionTitle('Type'),
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

                  // Employee Selection & Time Slot (only for in-person visits)
                  if (_selectedActivityType == 'in_person_visit') ...[
                    // Employee Selection Section
                    _buildSectionTitle('Assign'),
                    const SizedBox(height: CrmDesignSystem.sm),
                    EmployeeSelectionSection(
                      allEmployees: _employees,
                      selectedEmployeeIds: _selectedEmployees.map((e) => e.userId).toList(),
                      currentUserId: widget.userId,
                      onEmployeesChanged: (selectedIds) {
                        // Update selected employees
                        final newEmployees = <EmployeeAssignment>[];
                        for (var id in selectedIds) {
                          final role = id == widget.userId ? 'primary' : 'secondary';
                          newEmployees.add(EmployeeAssignment(
                            userId: id,
                            role: role,
                          ));
                        }
                        setState(() => _selectedEmployees = newEmployees);
                        // Load schedules for new employees
                        _loadEmployeeSchedules();
                      },
                    ),
                    const SizedBox(height: CrmDesignSystem.lg),

                    // Date Selection
                    _buildSectionTitle('Date'),
                    const SizedBox(height: CrmDesignSystem.sm),
                    GestureDetector(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 90)),
                        );
                        if (picked != null) {
                          setState(() => _selectedDate = picked);
                          // Reload schedules for new date if in-person visit
                          if (_selectedActivityType == 'in_person_visit') {
                            _loadEmployeeSchedules();
                          }
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: CrmDesignSystem.md,
                          vertical: CrmDesignSystem.md,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(CrmDesignSystem.radiusLarge),
                        ),
                        child: Text(
                          DateFormat('dd MMM yyyy').format(_selectedDate),
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: CrmDesignSystem.lg),

                    // Time Slot Grid
                    _buildSectionTitle('Available Time Slots'),
                    const SizedBox(height: CrmDesignSystem.sm),
                    if (_isLoadingAvailability)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(CrmDesignSystem.lg),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (_selectedEmployees.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(CrmDesignSystem.lg),
                        child: Text(
                          'Please select at least one employee to see available time slots',
                          style: CrmDesignSystem.bodySmall.copyWith(
                            color: CrmColors.textLight,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      )
                    else
                      Column(
                        children: [
                          TimeSlotAvailabilityGrid(
                            availableSlots: _slotAvailabilityData,
                            selectedSlot: _selectedStartTime,
                            onSlotSelected: (time) => setState(() => _selectedStartTime = time),
                          ),
                          // All slots busy warning
                          if (_slotAvailabilityData.isNotEmpty &&
                              _slotAvailabilityData.every((slot) => !slot.isAvailable)) ...[
                            SizedBox(height: CrmDesignSystem.lg),
                            Container(
                              padding: EdgeInsets.all(CrmDesignSystem.md),
                              decoration: BoxDecoration(
                                color: Colors.orange.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(CrmDesignSystem.radiusMedium),
                                border: Border.all(
                                  color: Colors.orange.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.warning_amber, color: Colors.orange),
                                  SizedBox(width: CrmDesignSystem.sm),
                                  Expanded(
                                    child: Text(
                                      'All time slots are busy. Tap any slot to see who\'s unavailable.',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: CrmColors.textDark,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    const SizedBox(height: CrmDesignSystem.lg),
                  ],

                  // Purpose
                  _buildSectionTitle('Purpose'),
                  const SizedBox(height: CrmDesignSystem.sm),
                  GestureDetector(
                    onTap: _showPurposeBottomSheet,
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _selectedPurpose == null ? CrmColors.borderColor : CrmColors.primary,
                        ),
                        borderRadius: BorderRadius.circular(CrmDesignSystem.radiusLarge),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: CrmDesignSystem.md,
                        vertical: CrmDesignSystem.md,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _selectedPurpose != null
                                ? _purposeOptions[_selectedPurpose] ?? 'Select purpose'
                                : 'Select purpose',
                            style: TextStyle(
                              fontSize: 16,
                              color: _selectedPurpose != null ? CrmColors.textDark : CrmColors.textLight,
                            ),
                          ),
                          Icon(
                            Icons.arrow_drop_down,
                            color: CrmColors.textLight,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: CrmDesignSystem.lg),

                  // Purpose Other (shown when purpose is 'other')
                  if (_selectedPurpose == 'other') ...[
                    _buildSectionTitle('Please specify'),
                    const SizedBox(height: CrmDesignSystem.sm),
                    TextField(
                      controller: _purposeOtherController,
                      decoration: InputDecoration(
                        hintText: 'Enter purpose details...',
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
                  ],

                  // Notes
                  _buildSectionTitle('Notes (Optional)'),
                  const SizedBox(height: CrmDesignSystem.sm),
                  TextField(
                    controller: _notesController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Additional details...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(CrmDesignSystem.radiusLarge),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: CrmDesignSystem.md,
                        vertical: CrmDesignSystem.md,
                      ),
                    ),
                  ),
                  const SizedBox(height: CrmDesignSystem.xl),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveAppointment,
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
                              'Schedule Appointment',
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
}

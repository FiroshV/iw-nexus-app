import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import '../../config/crm_colors.dart';
import '../../models/appointment.dart';
import '../../services/appointment_service.dart';
import '../../services/api_service.dart';

class Employee {
  final String id;
  final String firstName;
  final String lastName;
  final String? email;
  final String? phone;
  final String? role;
  final String? branch;

  Employee({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.email,
    this.phone,
    this.role,
    this.branch,
  });

  String get fullName => '$firstName $lastName';
}

class TeamScheduleScreen extends StatefulWidget {
  final String branchId;
  final String userRole;

  const TeamScheduleScreen({
    super.key,
    required this.branchId,
    required this.userRole,
  });

  @override
  State<TeamScheduleScreen> createState() => _TeamScheduleScreenState();
}

class _TeamScheduleScreenState extends State<TeamScheduleScreen> {
  DateTime _selectedDate = DateTime.now();
  List<Employee> _availableEmployees = [];
  List<String> _selectedEmployeeIds = [];
  bool _loadingEmployees = false;
  bool _loadingSchedules = false;

  Map<String, List<TimeSlot>> _employeeSchedules = {};

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  Future<void> _loadEmployees() async {
    setState(() => _loadingEmployees = true);
    try {
      final response = await ApiService.get('/api/users?role=employee,field_staff,telecaller&branchId=${widget.branchId}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final employees = (data['data'] as List)
            .map((e) => Employee(
                  id: e['_id'] ?? '',
                  firstName: e['firstName'] ?? '',
                  lastName: e['lastName'] ?? '',
                  email: e['email'],
                  phone: e['phone'],
                  role: e['role'],
                  branch: e['branch'],
                ))
            .toList();

        setState(() {
          _availableEmployees = employees;
          // Select all employees by default
          _selectedEmployeeIds = employees.map((e) => e.id).toList();
        });

        _loadSchedules();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load employees: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _loadingEmployees = false);
      }
    }
  }

  Future<void> _loadSchedules() async {
    if (_selectedEmployeeIds.isEmpty) {
      setState(() => _employeeSchedules = {});
      return;
    }

    setState(() => _loadingSchedules = true);
    try {
      final schedules = <String, List<TimeSlot>>{};

      for (final employeeId in _selectedEmployeeIds) {
        final response = await AppointmentService.getEmployeeSchedule(employeeId, _selectedDate);

        if (response.success && response.data != null) {
          final schedule = response.data!;
          final busySlots = (schedule['busySlots'] as List? ?? [])
              .map((s) => TimeSlot(
                    startTime: s['startTime'] ?? '',
                    endTime: s['endTime'] ?? '',
                  ))
              .toList();

          // Generate all slots from 9 AM to 6 PM
          final allSlots = <TimeSlot>[];
          for (int hour = 9; hour < 18; hour++) {
            final startTime = '${hour.toString().padLeft(2, '0')}:00';
            final endTime = '${(hour + 1).toString().padLeft(2, '0')}:00';

            final isBusy = busySlots.any((busy) => busy.startTime == startTime && busy.endTime == endTime);

            allSlots.add(TimeSlot(
              startTime: startTime,
              endTime: endTime,
              isAvailable: !isBusy,
            ));
          }

          schedules[employeeId] = allSlots;
        }
      }

      setState(() => _employeeSchedules = schedules);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load schedules: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _loadingSchedules = false);
      }
    }
  }

  Future<void> _selectDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );

    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() => _selectedDate = pickedDate);
      _loadSchedules();
    }
  }

  void _toggleEmployee(String employeeId) {
    setState(() {
      if (_selectedEmployeeIds.contains(employeeId)) {
        _selectedEmployeeIds.remove(employeeId);
      } else {
        _selectedEmployeeIds.add(employeeId);
      }
    });
    _loadSchedules();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Team Schedule'),
        backgroundColor: CrmColors.primary,
        elevation: 2,
      ),
      body: _loadingEmployees
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date Selection
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.chevron_left),
                              onPressed: () {
                                setState(() => _selectedDate = _selectedDate.subtract(const Duration(days: 1)));
                                _loadSchedules();
                              },
                            ),
                            GestureDetector(
                              onTap: _selectDate,
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_today, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    DateFormat('EEEE, dd MMM').format(_selectedDate),
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.chevron_right),
                              onPressed: () {
                                setState(() => _selectedDate = _selectedDate.add(const Duration(days: 1)));
                                _loadSchedules();
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Select Team Members',
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                color: CrmColors.textDark,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _availableEmployees.map((employee) {
                            final isSelected = _selectedEmployeeIds.contains(employee.id);
                            return FilterChip(
                              label: Text(employee.fullName),
                              selected: isSelected,
                              onSelected: (selected) {
                                _toggleEmployee(employee.id);
                              },
                              backgroundColor: CrmColors.surface,
                              selectedColor: CrmColors.primary.withValues(alpha: 0.2),
                              checkmarkColor: CrmColors.primary,
                              side: BorderSide(
                                color: isSelected ? CrmColors.primary : CrmColors.borderColor,
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),

                  // Schedules
                  if (_loadingSchedules)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_selectedEmployeeIds.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Center(
                        child: Text(
                          'Select at least one team member',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: CrmColors.textLight,
                              ),
                        ),
                      ),
                    )
                  else
                    ..._selectedEmployeeIds.map((employeeId) {
                      final employee = _availableEmployees.firstWhere((e) => e.id == employeeId);
                      final timeSlots = _employeeSchedules[employeeId] ?? [];

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              employee.fullName,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 4,
                                childAspectRatio: 1.2,
                                mainAxisSpacing: 8,
                                crossAxisSpacing: 8,
                              ),
                              itemCount: timeSlots.length,
                              itemBuilder: (context, index) {
                                final slot = timeSlots[index];
                                return Container(
                                  decoration: BoxDecoration(
                                    color: slot.isAvailable ? CrmColors.surface : Colors.red.withValues(alpha: 0.2),
                                    border: Border.all(
                                      color: slot.isAvailable ? CrmColors.borderColor : Colors.red,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: Text(
                                      slot.startTime,
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: slot.isAvailable ? CrmColors.textDark : Colors.red,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      );
                    }),
                  const SizedBox(height: 16),
                ],
              ),
            ),
    );
  }
}

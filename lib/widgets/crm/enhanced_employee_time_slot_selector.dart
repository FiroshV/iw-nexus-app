import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/crm_colors.dart';
import '../../models/appointment.dart';

class EmployeeWithSlots {
  final String userId;
  final String userName;
  final String role;

  EmployeeWithSlots({
    required this.userId,
    required this.userName,
    required this.role,
  });
}

class EnhancedEmployeeTimeSlotselector extends StatefulWidget {
  final List<EmployeeWithSlots> availableEmployees;
  final DateTime selectedDate;
  final Function(List<EmployeeWithSlots>, TimeSlot?) onSelectionChanged;
  final List<EmployeeWithSlots>? initialSelectedEmployees;
  final TimeSlot? initialSelectedTimeSlot;

  const EnhancedEmployeeTimeSlotselector({
    super.key,
    required this.availableEmployees,
    required this.selectedDate,
    required this.onSelectionChanged,
    this.initialSelectedEmployees,
    this.initialSelectedTimeSlot,
  });

  @override
  State<EnhancedEmployeeTimeSlotselector> createState() => _EnhancedEmployeeTimeSlotselectorState();
}

class _EnhancedEmployeeTimeSlotselectorState extends State<EnhancedEmployeeTimeSlotselector> {
  late List<EmployeeWithSlots> _selectedEmployees;
  TimeSlot? _selectedTimeSlot;
  final List<String> _availableTimeSlots = [];

  @override
  void initState() {
    super.initState();
    _selectedEmployees = widget.initialSelectedEmployees ?? [];
    _selectedTimeSlot = widget.initialSelectedTimeSlot;
    _generateTimeSlots();
  }

  void _generateTimeSlots() {
    _availableTimeSlots.clear();
    // Generate 30-minute slots from 9:00 AM to 6:00 PM
    for (int hour = 9; hour < 18; hour++) {
      _availableTimeSlots.add('${hour.toString().padLeft(2, '0')}:00');
      _availableTimeSlots.add('${hour.toString().padLeft(2, '0')}:30');
    }
  }

  void _toggleEmployee(EmployeeWithSlots employee) {
    setState(() {
      if (_selectedEmployees.any((e) => e.userId == employee.userId)) {
        _selectedEmployees.removeWhere((e) => e.userId == employee.userId);
      } else {
        _selectedEmployees.add(employee);
      }
      _updateSelection();
    });
  }

  void _selectTimeSlot(String timeSlot) {
    setState(() {
      final nextHour = int.parse(timeSlot.split(':')[0]);
      final nextMinute = int.parse(timeSlot.split(':')[1]);
      int endHour = nextHour;
      int endMinute = nextMinute + 30;

      if (endMinute >= 60) {
        endHour += 1;
        endMinute = 0;
      }

      _selectedTimeSlot = TimeSlot(
        startTime: timeSlot,
        endTime: '${endHour.toString().padLeft(2, '0')}:${endMinute.toString().padLeft(2, '0')}',
      );
      _updateSelection();
    });
  }

  void _updateSelection() {
    widget.onSelectionChanged(_selectedEmployees, _selectedTimeSlot);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Date Display
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: CrmColors.surface,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(Icons.calendar_today, size: 18, color: CrmColors.primary),
              const SizedBox(width: 8),
              Text(
                DateFormat('EEEE, dd MMM yyyy').format(widget.selectedDate),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Employee Category/Role Selection
        Text(
          'Select Team Members',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: CrmColors.textDark,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),

        // Employee List with Checkboxes (Like ground selection in reference image)
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border.all(color: CrmColors.borderColor),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: widget.availableEmployees.map((employee) {
              final isSelected = _selectedEmployees.any((e) => e.userId == employee.userId);
              return CheckboxListTile(
                value: isSelected,
                onChanged: (selected) {
                  _toggleEmployee(employee);
                },
                title: Text(employee.userName),
                subtitle: Text('Role: ${employee.role}'),
                dense: true,
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: CrmColors.primary,
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),

        // Time Slot Grid (Like reference image)
        Text(
          'Available Time Slots',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: CrmColors.textDark,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4, // 4 columns like reference image
            childAspectRatio: 1.1,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
          ),
          itemCount: _availableTimeSlots.length,
          itemBuilder: (context, index) {
            final timeSlot = _availableTimeSlots[index];
            final isSelected = _selectedTimeSlot?.startTime == timeSlot;

            return GestureDetector(
              onTap: _selectedEmployees.isEmpty
                  ? null
                  : () {
                      _selectTimeSlot(timeSlot);
                    },
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected
                      ? CrmColors.primary
                      : CrmColors.surface,
                  border: Border.all(
                    color: isSelected ? CrmColors.primary : CrmColors.borderColor,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        timeSlot,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: isSelected ? Colors.white : CrmColors.textDark,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      if (isSelected)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Icon(
                            Icons.check_circle,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),

        // Selected Summary
        if (_selectedEmployees.isNotEmpty || _selectedTimeSlot != null)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: CrmColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: CrmColors.success.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Summary',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: CrmColors.success,
                      ),
                ),
                const SizedBox(height: 4),
                if (_selectedEmployees.isNotEmpty)
                  Text(
                    'Team Members: ${_selectedEmployees.map((e) => e.userName).join(', ')}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                if (_selectedTimeSlot != null)
                  Text(
                    'Time: ${_selectedTimeSlot!.startTime} - ${_selectedTimeSlot!.endTime}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

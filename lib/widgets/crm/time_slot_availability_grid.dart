import 'package:flutter/material.dart';
import '../../config/crm_colors.dart';
import '../../config/crm_design_system.dart';
import '../../models/slot_availability_info.dart';

class TimeSlotAvailabilityGrid extends StatelessWidget {
  final List<SlotAvailabilityInfo> availableSlots;
  final String? selectedSlot; // Selected start time (e.g., "09:00")
  final ValueChanged<String> onSlotSelected;

  const TimeSlotAvailabilityGrid({
    super.key,
    required this.availableSlots,
    required this.selectedSlot,
    required this.onSlotSelected,
  });

  void _showBusyEmployeesBottomSheet(
    BuildContext context,
    List<EmployeeSlotInfo> busyEmployees,
    String timeSlot,
  ) {
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
                    'Busy at $timeSlot',
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

              // Info banner
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
                    Icon(Icons.info_outline, color: Colors.orange, size: 20),
                    SizedBox(width: CrmDesignSystem.sm),
                    Expanded(
                      child: Text(
                        'The following team members are already booked:',
                        style: TextStyle(
                          fontSize: 14,
                          color: CrmColors.textDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: CrmDesignSystem.lg),

              // Busy employees list
              ...busyEmployees.map((employee) => _buildEmployeeCard(employee)),

              SizedBox(height: CrmDesignSystem.md),

              // Action button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CrmColors.primary,
                    padding: EdgeInsets.symmetric(vertical: CrmDesignSystem.md),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(CrmDesignSystem.radiusMedium),
                    ),
                  ),
                  child: Text(
                    'Got it',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmployeeCard(EmployeeSlotInfo employee) {
    return Container(
      margin: EdgeInsets.only(bottom: CrmDesignSystem.md),
      padding: EdgeInsets.all(CrmDesignSystem.md),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(CrmDesignSystem.radiusMedium),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Employee info
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: CrmColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    employee.userName.isNotEmpty ? employee.userName[0].toUpperCase() : '?',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: CrmColors.primary,
                    ),
                  ),
                ),
              ),
              SizedBox(width: CrmDesignSystem.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      employee.userName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: CrmColors.textDark,
                      ),
                    ),
                    if (employee.role != null)
                      Text(
                        employee.role!,
                        style: TextStyle(
                          fontSize: 14,
                          color: CrmColors.textLight,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),

          // Appointment details
          if (employee.conflictingAppointment != null) ...[
            SizedBox(height: CrmDesignSystem.sm),
            Divider(color: Colors.grey.shade300),
            SizedBox(height: CrmDesignSystem.sm),
            Row(
              children: [
                Icon(Icons.event, size: 16, color: CrmColors.textLight),
                SizedBox(width: CrmDesignSystem.xs),
                Expanded(
                  child: Text(
                    'Appointment: ${employee.conflictingAppointment!.appointmentId}',
                    style: TextStyle(
                      fontSize: 13,
                      color: CrmColors.textLight,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
            if (employee.conflictingAppointment!.customerName != null) ...[
              SizedBox(height: CrmDesignSystem.xs),
              Row(
                children: [
                  Icon(Icons.person, size: 16, color: CrmColors.textLight),
                  SizedBox(width: CrmDesignSystem.xs),
                  Expanded(
                    child: Text(
                      employee.conflictingAppointment!.customerName!,
                      style: TextStyle(
                        fontSize: 13,
                        color: CrmColors.textLight,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (employee.conflictingAppointment!.customerPhone != null) ...[
              SizedBox(height: CrmDesignSystem.xs),
              Row(
                children: [
                  Icon(Icons.phone, size: 16, color: CrmColors.textLight),
                  SizedBox(width: CrmDesignSystem.xs),
                  Expanded(
                    child: Text(
                      employee.conflictingAppointment!.customerPhone!,
                      style: TextStyle(
                        fontSize: 13,
                        color: CrmColors.textLight,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (availableSlots.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(CrmDesignSystem.lg),
          child: Text(
            'No time slots available',
            style: TextStyle(
              fontSize: 14,
              color: CrmColors.textLight,
            ),
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: CrmDesignSystem.md,
        crossAxisSpacing: CrmDesignSystem.md,
        childAspectRatio: 1.2,
      ),
      itemCount: availableSlots.length,
      itemBuilder: (context, index) {
        final slotInfo = availableSlots[index];
        final startTime = slotInfo.timeSlot.startTime;
        final endTime = slotInfo.timeSlot.endTime;
        final isAvailable = slotInfo.isAvailable;
        final isSelected = selectedSlot == startTime;
        final hasBusyEmployees = slotInfo.busyEmployees.isNotEmpty;

        return GestureDetector(
          onTap: () {
            if (isAvailable) {
              onSlotSelected(startTime);
            } else if (hasBusyEmployees) {
              _showBusyEmployeesBottomSheet(context, slotInfo.busyEmployees, startTime);
            }
          },
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: isSelected
                    ? CrmColors.primary
                    : isAvailable
                        ? CrmColors.borderColor
                        : CrmColors.errorColor.withValues(alpha: 0.3),
                width: isSelected ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(CrmDesignSystem.radiusMedium),
              color: isSelected
                  ? CrmColors.primary.withValues(alpha: 0.1)
                  : isAvailable
                      ? Colors.white
                      : CrmColors.errorColor.withValues(alpha: 0.05),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  if (isAvailable) {
                    onSlotSelected(startTime);
                  } else if (hasBusyEmployees) {
                    _showBusyEmployeesBottomSheet(context, slotInfo.busyEmployees, startTime);
                  }
                },
                borderRadius: BorderRadius.circular(CrmDesignSystem.radiusMedium),
                splashColor: isAvailable
                    ? CrmColors.primary.withValues(alpha: 0.1)
                    : CrmColors.errorColor.withValues(alpha: 0.1),
                child: Padding(
                  padding: const EdgeInsets.all(CrmDesignSystem.md),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Status icon
                      if (isAvailable)
                        Icon(
                          Icons.check_circle,
                          color: CrmColors.success,
                          size: 24,
                        )
                      else
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Icon(
                              Icons.cancel,
                              color: CrmColors.errorColor,
                              size: 24,
                            ),
                            if (hasBusyEmployees)
                              Positioned(
                                bottom: -2,
                                right: -2,
                                child: Container(
                                  padding: EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.info,
                                    size: 12,
                                    color: CrmColors.primary,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      const SizedBox(height: CrmDesignSystem.sm),

                      // Time display
                      Text(
                        startTime,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: isAvailable && !isSelected
                              ? CrmColors.textDark
                              : isSelected
                                  ? CrmColors.primary
                                  : CrmColors.errorColor,
                        ),
                      ),
                      const SizedBox(height: CrmDesignSystem.xs),
                      Text(
                        endTime,
                        style: TextStyle(
                          fontSize: 12,
                          color: isAvailable && !isSelected
                              ? CrmColors.textLight
                              : isSelected
                                  ? CrmColors.primary
                                  : CrmColors.errorColor.withValues(alpha: 0.7),
                        ),
                      ),

                      // Busy indicator
                      if (!isAvailable && hasBusyEmployees) ...[
                        const SizedBox(height: CrmDesignSystem.xs),
                        Text(
                          'Tap for details',
                          style: TextStyle(
                            fontSize: 10,
                            color: CrmColors.primary,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

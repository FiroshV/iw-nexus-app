import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/crm_colors.dart';
import '../../config/crm_design_system.dart';
import '../../models/appointment.dart';
import '../../services/appointment_service.dart';
import '../../providers/crm/appointment_provider.dart';

/// My Schedule Tab - Grid view of time slots
/// Shows availability status for the selected date
class MyScheduleTab extends StatefulWidget {
  final String userId;
  final String userRole;
  final String? initialEmployeeId;

  const MyScheduleTab({
    super.key,
    required this.userId,
    required this.userRole,
    this.initialEmployeeId,
  });

  @override
  State<MyScheduleTab> createState() => _MyScheduleTabState();
}

class _MyScheduleTabState extends State<MyScheduleTab>
    with AutomaticKeepAliveClientMixin {
  late DateTime _selectedDate;
  late String _displayedEmployeeId;
  Map<String, dynamic>? _scheduleData;
  final List<TimeSlot> _timeSlots = [];
  bool _isLoading = true;
  String? _error;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _displayedEmployeeId = widget.initialEmployeeId ?? widget.userId;

    _loadSchedule();
  }

  Future<void> _loadSchedule() async {
    // Clear old data immediately
    setState(() {
      _isLoading = true;
      _error = null;
      _timeSlots.clear();
    });

    try {
      // Fetch employee schedule for the selected date
      final response = await AppointmentService.getEmployeeSchedule(
        _displayedEmployeeId,
        _selectedDate,
      );

      if (response.success && response.data != null) {
        _scheduleData = response.data;
        _buildTimeSlots();
        // _buildTimeSlots will call setState, so no need to call it again here
      } else {
        // Only show error if the API call actually failed
        setState(() {
          _error = _getErrorMessage(response.message);
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = _getErrorMessage(null, error: e);
        _isLoading = false;
      });
    }
  }

  void _buildTimeSlots() {
    _timeSlots.clear();

    if (_scheduleData == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    // Get pre-calculated slots from API response
    final busySlots = _scheduleData!['busySlots'] as List? ?? [];
    final availableSlots = _scheduleData!['availableSlots'] as List? ?? [];

    // Convert busy slots
    for (var slot in busySlots) {
      final customer = slot['customer']['name'] ?? 'Unknown';
      final activityType = slot['activityType'] ?? 'in_person_visit';
      _timeSlots.add(TimeSlot(
        startTime: slot['startTime'] as String,
        endTime: slot['endTime'] as String,
        isAvailable: false,
        reason: '$customer\n$activityType',
        appointmentId: slot['appointmentId'] as String,
      ));
    }

    // Convert available slots
    for (var slot in availableSlots) {
      _timeSlots.add(TimeSlot(
        startTime: slot['startTime'] as String,
        endTime: slot['endTime'] as String,
        isAvailable: true,
      ));
    }

    // Sort by start time to maintain order
    _timeSlots.sort((a, b) => a.startTime.compareTo(b.startTime));

    // Single setState after building all time slots
    setState(() {
      _isLoading = false;
    });
  }

  String _getErrorMessage(String? message, {dynamic error}) {
    if (error != null) {
      final errorStr = error.toString().toLowerCase();
      if (errorStr.contains('socket') || errorStr.contains('connection')) {
        return 'No internet connection. Please check your network.';
      }
      return 'Error loading schedule. Please try again.';
    }

    if (message != null) {
      if (message.contains('not found') || message.contains('404')) {
        return 'Schedule service not available. Please try again later.';
      }
      if (message.contains('permission') || message.contains('403')) {
        return 'Access denied. You don\'t have permission to view this schedule.';
      }
      if (message.contains('server') || message.contains('500')) {
        return 'Server error. Please try again later.';
      }
    }

    return 'Failed to load schedule. Please try again.';
  }

  void _handleSlotSelected(TimeSlot slot) {
    if (!slot.isAvailable) {
      // Show appointment details using appointmentId from slot
      if (slot.appointmentId != null) {
        _showAppointmentDetails(slot.appointmentId!);
      }
    } else {
      // Schedule new appointment
      _navigateToScheduling(slot);
    }
  }

  void _navigateToScheduling(TimeSlot timeSlot) {
    Navigator.of(context).pushNamed(
      '/crm/simplified-appointment',
      arguments: {
        'userId': widget.userId,
        'userRole': widget.userRole,
      },
    );
  }

  void _showAppointmentDetails(String appointmentId) {
    Navigator.of(context).pushNamed(
      '/crm/appointment-details',
      arguments: {'appointmentId': appointmentId},
    ).then((result) {
      if (mounted) {
        // Invalidate appointment cache when returning
        try {
          context.read<AppointmentProvider>().invalidateAll();
        } catch (e) {
          // Provider might not be available
        }
        // Refresh schedule after returning
        _loadSchedule();
      }
    });
  }

  void _goToToday() {
    setState(() {
      _selectedDate = DateTime.now();
    });
    _invalidateCacheAndRefresh();
  }

  void _goToTomorrow() {
    setState(() {
      _selectedDate = DateTime.now().add(const Duration(days: 1));
    });
    _invalidateCacheAndRefresh();
  }

  void _goToNextWeek() {
    setState(() {
      _selectedDate = DateTime.now().add(const Duration(days: 7));
    });
    _invalidateCacheAndRefresh();
  }

  void _previousDay() {
    setState(() {
      _selectedDate = _selectedDate.subtract(const Duration(days: 1));
    });
    _invalidateCacheAndRefresh();
  }

  void _nextDay() {
    setState(() {
      _selectedDate = _selectedDate.add(const Duration(days: 1));
    });
    _invalidateCacheAndRefresh();
  }

  void _invalidateCacheAndRefresh() {
    // Invalidate appointment cache since schedule date changed
    try {
      context.read<AppointmentProvider>().invalidateAll();
    } catch (e) {
      // Provider might not be available
    }
    _loadSchedule();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    return _isLoading
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(CrmColors.primary),
                ),
                const SizedBox(height: CrmDesignSystem.lg),
                Text(
                  'Loading schedule...',
                  style: CrmDesignSystem.bodyMedium
                      .copyWith(color: CrmColors.textLight),
                ),
              ],
            ),
          )
        : _error != null
            ? SingleChildScrollView(
                child: Column(
                  children: [
                    // Date Navigation Card (even on error)
                    Padding(
                      padding: const EdgeInsets.all(CrmDesignSystem.lg),
                      child: Container(
                        padding: const EdgeInsets.all(CrmDesignSystem.lg),
                        decoration: CrmDesignSystem.highlightedCardDecoration,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Selected Date',
                                    style: CrmDesignSystem.labelSmall,
                                  ),
                                  const SizedBox(height: CrmDesignSystem.md),
                                  Text(
                                    DateFormat('EEEE, MMM d, yyyy')
                                        .format(_selectedDate),
                                    style: CrmDesignSystem.headlineSmall,
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.chevron_left),
                                  onPressed: _previousDay,
                                  color: CrmColors.primary,
                                ),
                                IconButton(
                                  icon: const Icon(Icons.chevron_right),
                                  onPressed: _nextDay,
                                  color: CrmColors.primary,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Error message
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(CrmDesignSystem.lg),
                        child: Column(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: CrmColors.errorColor.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.error_outline,
                                size: 40,
                                color: CrmColors.errorColor,
                              ),
                            ),
                            const SizedBox(height: CrmDesignSystem.lg),
                            Text(
                              'Unable to load schedule',
                              style: CrmDesignSystem.headlineSmall,
                            ),
                            const SizedBox(height: CrmDesignSystem.sm),
                            Text(
                              _error ?? 'An error occurred',
                              style: CrmDesignSystem.bodyMedium
                                  .copyWith(color: CrmColors.textLight),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: CrmDesignSystem.xl),
                            ElevatedButton.icon(
                              onPressed: _loadSchedule,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Retry'),
                              style: CrmDesignSystem.primaryButtonStyle,
                            ),
                            const SizedBox(height: CrmDesignSystem.lg),
                            Padding(
                              padding: const EdgeInsets.all(CrmDesignSystem.lg),
                              child: Container(
                                padding: const EdgeInsets.all(CrmDesignSystem.lg),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withValues(alpha: 0.05),
                                  border: Border.all(
                                    color: CrmColors.primary.withValues(alpha: 0.3),
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    CrmDesignSystem.radiusLarge,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Troubleshooting',
                                      style: CrmDesignSystem.labelMedium.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: CrmDesignSystem.sm),
                                    Text(
                                      '• Check your internet connection\n'
                                      '• Try selecting a different date\n'
                                      '• Restart the app if issue persists',
                                      style: CrmDesignSystem.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date Navigation Card
                    Padding(
                      padding: const EdgeInsets.all(CrmDesignSystem.lg),
                      child: Container(
                        padding: const EdgeInsets.all(CrmDesignSystem.lg),
                        decoration: CrmDesignSystem.highlightedCardDecoration,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Selected Date',
                                        style:
                                            CrmDesignSystem.labelSmall,
                                      ),
                                      const SizedBox(
                                        height: CrmDesignSystem.md,
                                      ),
                                      Text(
                                        DateFormat('EEEE, MMM d, yyyy')
                                            .format(_selectedDate),
                                        style:
                                            CrmDesignSystem.headlineSmall,
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.chevron_left,
                                      ),
                                      onPressed: _previousDay,
                                      color: CrmColors.primary,
                                      iconSize: 28,
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.chevron_right,
                                      ),
                                      onPressed: _nextDay,
                                      color: CrmColors.primary,
                                      iconSize: 28,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(
                              height: CrmDesignSystem.lg,
                            ),
                            // Quick jump buttons
                            Wrap(
                              spacing: CrmDesignSystem.sm,
                              runSpacing: CrmDesignSystem.sm,
                              children: [
                                _buildQuickJumpButton('Today', _goToToday),
                                _buildQuickJumpButton(
                                    'Tomorrow', _goToTomorrow),
                                _buildQuickJumpButton(
                                    'Next Week', _goToNextWeek),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Employee selector (for managers/admins)
                    if (widget.initialEmployeeId != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: CrmDesignSystem.lg,
                          vertical: CrmDesignSystem.md,
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(
                            CrmDesignSystem.lg,
                          ),
                          decoration: CrmDesignSystem.cardDecoration,
                          child: Row(
                            children: [
                              Icon(
                                Icons.person_outline,
                                color: CrmColors.primary,
                                size: 20,
                              ),
                              const SizedBox(
                                width: CrmDesignSystem.lg,
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Viewing',
                                      style:
                                          CrmDesignSystem.labelSmall,
                                    ),
                                    const SizedBox(
                                      height: CrmDesignSystem.xs,
                                    ),
                                    Text(
                                      _displayedEmployeeId ==
                                              widget.userId
                                          ? 'My Schedule'
                                          : _displayedEmployeeId,
                                      style: CrmDesignSystem.titleMedium,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Time Slot Grid
                    if (_timeSlots.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          CrmDesignSystem.lg,
                          CrmDesignSystem.lg,
                          CrmDesignSystem.lg,
                          CrmDesignSystem.md,
                        ),
                        child: Text(
                          'Available Time Slots (9 AM - 6 PM)',
                          style: CrmDesignSystem.headlineSmall,
                        ),
                      ),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(
                          horizontal: CrmDesignSystem.lg,
                        ),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: CrmDesignSystem.md,
                          crossAxisSpacing: CrmDesignSystem.md,
                          childAspectRatio: 1.0,
                        ),
                        itemCount: _timeSlots.length,
                        itemBuilder: (context, index) {
                          final slot = _timeSlots[index];
                          return _buildTimeSlotCard(slot);
                        },
                      ),
                    ] else
                      Padding(
                        padding: const EdgeInsets.all(CrmDesignSystem.lg),
                        child: Center(
                          child: Column(
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: CrmColors.primary.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.calendar_today_outlined,
                                  size: 40,
                                  color: CrmColors.primary,
                                ),
                              ),
                              const SizedBox(height: CrmDesignSystem.lg),
                              Text(
                                'No Schedule',
                                style: CrmDesignSystem.headlineSmall,
                              ),
                              const SizedBox(height: CrmDesignSystem.sm),
                              Text(
                                'No appointments scheduled for this date',
                                style: CrmDesignSystem.bodyMedium
                                    .copyWith(color: CrmColors.textLight),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),

                    const SizedBox(height: CrmDesignSystem.huge),
                  ],
                ),
              );
  }

  Widget _buildQuickJumpButton(String label, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: CrmDesignSystem.secondaryButtonStyle,
      child: Text(
        label,
        style: CrmDesignSystem.labelSmall,
      ),
    );
  }

  Widget _buildTimeSlotCard(TimeSlot slot) {
    final isAvailable = slot.isAvailable;
    final accentColor = isAvailable ? CrmColors.primary : Colors.grey[400]!;

    return GestureDetector(
      onTap: () => _handleSlotSelected(slot),
      child: AnimatedContainer(
        duration: CrmDesignSystem.durationNormal,
        decoration: BoxDecoration(
          color: isAvailable
              ? CrmColors.surface
              : Colors.grey[200]!,
          borderRadius: BorderRadius.circular(
            CrmDesignSystem.radiusLarge,
          ),
          border: Border.all(
            color: isAvailable
                ? accentColor.withValues(alpha: 0.3)
                : Colors.grey[300]!,
            width: isAvailable ? 1.5 : 1,
          ),
          boxShadow: isAvailable
              ? CrmDesignSystem.elevationSmall
              : [],
        ),
        child: InkWell(
          onTap: isAvailable ? () => _handleSlotSelected(slot) : null,
          borderRadius: BorderRadius.circular(
            CrmDesignSystem.radiusLarge,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!isAvailable)
                Padding(
                  padding: const EdgeInsets.only(
                    bottom: CrmDesignSystem.sm,
                  ),
                  child: Icon(
                    Icons.lock_outline,
                    color: Colors.grey[500],
                    size: 20,
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(
                    bottom: CrmDesignSystem.sm,
                  ),
                  child: Icon(
                    Icons.check_circle_outline,
                    color: CrmColors.success,
                    size: 20,
                  ),
                ),
              Text(
                slot.startTime,
                style: CrmDesignSystem.titleLarge.copyWith(
                  color: isAvailable ? CrmColors.textDark : Colors.grey[600],
                ),
              ),
              const SizedBox(height: CrmDesignSystem.xs),
              Text(
                slot.endTime,
                style: CrmDesignSystem.labelSmall.copyWith(
                  color: isAvailable ? CrmColors.textLight : Colors.grey[500],
                ),
              ),
              if (!isAvailable && slot.reason != null)
                Padding(
                  padding: const EdgeInsets.only(
                    top: CrmDesignSystem.sm,
                  ),
                  child: Text(
                    slot.reason!,
                    textAlign: TextAlign.center,
                    style: CrmDesignSystem.captionSmall.copyWith(
                      color: Colors.grey[600],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

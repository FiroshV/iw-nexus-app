import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/attendance_action_service.dart';
import '../services/location_service.dart';
import '../config/crm_colors.dart';
import '../utils/timezone_util.dart';

class DashboardAttendanceStrip extends StatefulWidget {
  final VoidCallback onNavigateToAttendance;
  final VoidCallback? onStatusChanged;

  const DashboardAttendanceStrip({
    super.key,
    required this.onNavigateToAttendance,
    this.onStatusChanged,
  });

  @override
  State<DashboardAttendanceStrip> createState() =>
      _DashboardAttendanceStripState();
}

class _DashboardAttendanceStripState extends State<DashboardAttendanceStrip> {
  final AttendanceActionService _attendanceService = AttendanceActionService();
  Map<String, dynamic>? _todayAttendance;
  bool _isLoading = true;
  bool _isActionLoading = false;
  Timer? _liveTimer;

  @override
  void initState() {
    super.initState();
    _loadAttendance();
    _attendanceService.preFetchLocation();
    _startLiveTimer();
  }

  @override
  void dispose() {
    _liveTimer?.cancel();
    super.dispose();
  }

  void _startLiveTimer() {
    _liveTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted && _isCheckedIn && !_isCheckedOut) {
        setState(() {});
      }
    });
  }

  Future<void> _loadAttendance() async {
    final data = await _attendanceService.getTodayAttendance();
    if (mounted) {
      setState(() {
        _todayAttendance = data;
        _isLoading = false;
      });
    }
  }

  bool get _isCheckedIn {
    final checkIn = _todayAttendance?['checkIn'];
    return checkIn != null && checkIn['time'] != null;
  }

  bool get _isCheckedOut {
    final checkOut = _todayAttendance?['checkOut'];
    return checkOut != null && checkOut['time'] != null;
  }

  String get _clockInTime {
    final checkIn = _todayAttendance?['checkIn'];
    if (checkIn != null && checkIn['time'] != null) {
      final istTime = TimezoneUtil.parseToIST(checkIn['time']);
      return TimezoneUtil.timeOnlyIST(istTime);
    }
    return '--:--';
  }

  String get _elapsedTime {
    if (!_isCheckedIn) return '0h 0m';

    if (_todayAttendance?['totalWorkingHours'] != null && _isCheckedOut) {
      final hours = _todayAttendance!['totalWorkingHours'] as num;
      final h = hours.floor();
      final m = ((hours - h) * 60).round();
      return '${h}h ${m}m';
    }

    if (_todayAttendance?['checkIn']?['time'] != null) {
      final checkInTime =
          TimezoneUtil.parseToIST(_todayAttendance!['checkIn']['time']);
      final now = TimezoneUtil.nowIST();
      final duration = now.difference(checkInTime);
      final h = duration.inHours;
      final m = duration.inMinutes % 60;
      return '${h}h ${m}m';
    }
    return '0h 0m';
  }

  Color get _statusColor {
    if (_isCheckedOut) return CrmColors.secondary;
    if (_isCheckedIn) return CrmColors.successColor;
    return CrmColors.textLight;
  }

  String get _statusText {
    if (_isCheckedOut) return 'Completed';
    if (_isCheckedIn) return 'Working';
    return 'Not clocked in';
  }

  Color get _buttonColor {
    if (_isCheckedOut) return CrmColors.primary;
    if (_isCheckedIn) return CrmColors.errorColor;
    return const Color(0xFF5cfbd8);
  }

  String get _buttonText {
    if (_isActionLoading) {
      return _isCheckedIn && !_isCheckedOut ? 'Clocking Out...' : 'Clocking In...';
    }
    if (_isCheckedOut) return 'Clock In';
    if (_isCheckedIn) return 'Clock Out';
    return 'Clock In';
  }

  Color get _buttonTextColor {
    if (!_isCheckedIn || _isCheckedOut) return const Color(0xFF272579);
    return Colors.white;
  }

  Future<void> _handleAction() async {
    HapticFeedback.lightImpact();
    setState(() => _isActionLoading = true);

    AttendanceActionResult result;
    if (_isCheckedIn && !_isCheckedOut) {
      result = await _attendanceService.clockOut();
    } else {
      result = await _attendanceService.clockIn();
    }

    if (!mounted) return;

    if (result.requiresLateReason) {
      setState(() => _isActionLoading = false);
      final lateReason = await _showLateReasonDialog(result.lateByMinutes);
      if (lateReason == null) return;

      setState(() => _isActionLoading = true);
      result = await _attendanceService.clockIn(lateReason: lateReason);
      if (!mounted) return;
    }

    setState(() => _isActionLoading = false);

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(result.message),
            ],
          ),
          backgroundColor: CrmColors.successColor,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 2),
        ),
      );
      await _loadAttendance();
      widget.onStatusChanged?.call();
    } else if (!result.requiresLateReason) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: CrmColors.errorColor,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );

      if (result.canOpenSettings) {
        _showLocationSettingsDialog(result.message);
      }
    }
  }

  Future<String?> _showLateReasonDialog(int lateByMinutes) async {
    final controller = TextEditingController();
    return await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Late Arrival Reason',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Color(0xFF272579),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (lateByMinutes > 0)
              Container(
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: CrmColors.warningColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'You are $lateByMinutes minutes late',
                  style: TextStyle(
                    color: CrmColors.warningColor,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
            const Text('Please provide a reason for your late clock in:'),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 3,
              maxLength: 200,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                counterText: '',
                hintText: 'Enter reason...',
              ),
              textCapitalization: TextCapitalization.sentences,
              autofocus: true,
            ),
            const SizedBox(height: 8),
            Text(
              'Minimum 10 characters required',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(null),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF272579),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Submit'),
            onPressed: () {
              final reason = controller.text.trim();
              if (reason.length >= 10) {
                Navigator.of(context).pop(reason);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content:
                        Text('Please provide at least 10 characters'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  void _showLocationSettingsDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Access Required'),
        content: Text(message),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF272579),
              foregroundColor: Colors.white,
            ),
            child: const Text('Open Settings'),
            onPressed: () {
              Navigator.of(context).pop();
              LocationService().openLocationSettings();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        height: 80,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFF0071bf),
            ),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: widget.onNavigateToAttendance,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
          border: Border.all(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Info section
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _statusText,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _statusColor,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          if (_isCheckedIn) ...[
                            Text(
                              'In: $_clockInTime',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF7F8C8D),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 3,
                              height: 3,
                              decoration: BoxDecoration(
                                color: Colors.grey[400],
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Expanded(
                            child: Text(
                              _isCheckedOut
                                  ? _elapsedTime
                                  : _isCheckedIn
                                      ? _elapsedTime
                                      : 'Ready to start your day',
                              style: TextStyle(
                                fontSize: 12,
                                color: _isCheckedIn
                                    ? const Color(0xFF272579)
                                    : const Color(0xFF7F8C8D),
                                fontWeight:
                                    _isCheckedIn ? FontWeight.w700 : FontWeight.w400,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Action button
                SizedBox(
                  height: 40,
                  child: ElevatedButton(
                    onPressed: _isActionLoading ? null : _handleAction,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _buttonColor,
                      foregroundColor: _buttonTextColor,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isActionLoading
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: _buttonTextColor,
                            ),
                          )
                        : Text(
                            _buttonText,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import '../utils/timezone_util.dart';

class AttendanceTodayTab extends StatefulWidget {
  final bool isLoading;
  final Map<String, dynamic>? todayAttendance;
  final VoidCallback onClockIn;
  final VoidCallback onClockOut;
  final Future<void> Function() onRefresh;

  const AttendanceTodayTab({
    super.key,
    required this.isLoading,
    required this.todayAttendance,
    required this.onClockIn,
    required this.onClockOut,
    required this.onRefresh,
  });

  @override
  State<AttendanceTodayTab> createState() => _AttendanceTodayTabState();
}

class _AttendanceTodayTabState extends State<AttendanceTodayTab> {
  Timer? _liveTimer;

  @override
  void initState() {
    super.initState();
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

  bool get _isCheckedIn {
    final checkIn = widget.todayAttendance?['checkIn'];
    return checkIn != null && checkIn['time'] != null;
  }

  bool get _isCheckedOut {
    final checkOut = widget.todayAttendance?['checkOut'];
    return checkOut != null && checkOut['time'] != null;
  }

  String _getHoursWorked() {
    if (widget.todayAttendance?['totalWorkingHours'] != null && _isCheckedOut) {
      final hours = widget.todayAttendance!['totalWorkingHours'] as num;
      final h = hours.floor();
      final m = ((hours - h) * 60).round();
      return '${h}h ${m}m';
    } else if (widget.todayAttendance?['checkIn']?['time'] != null) {
      final checkInTime = TimezoneUtil.parseToIST(
        widget.todayAttendance!['checkIn']['time'],
      );
      final now = TimezoneUtil.nowIST();
      final duration = now.difference(checkInTime);
      final h = duration.inHours;
      final m = duration.inMinutes % 60;
      return '${h}h ${m}m';
    } else {
      return '0h 0m';
    }
  }

  String _getClockInTimeDisplay() {
    final checkIn = widget.todayAttendance?['checkIn'];
    if (checkIn != null && checkIn['time'] != null) {
      final istTime = TimezoneUtil.parseToIST(checkIn['time']);
      return TimezoneUtil.timeOnlyIST(istTime);
    }
    return '--:--';
  }

  String _getClockOutTimeDisplay() {
    final checkOut = widget.todayAttendance?['checkOut'];
    if (checkOut != null && checkOut['time'] != null) {
      final istTime = TimezoneUtil.parseToIST(checkOut['time']);
      return TimezoneUtil.timeOnlyIST(istTime);
    }
    return '--:--';
  }

  Color _getButtonColor() {
    if (_isCheckedOut) {
      return const Color(0xFF0071bf);
    } else if (_isCheckedIn) {
      return Colors.red;
    } else {
      return const Color(0xFF5cfbd8);
    }
  }

  String _getButtonText() {
    if (widget.isLoading) {
      return _isCheckedIn && !_isCheckedOut
          ? 'Clocking Out...'
          : 'Clocking In...';
    } else if (_isCheckedOut) {
      return 'Clock In Again';
    } else if (_isCheckedIn) {
      return 'Clock Out';
    } else {
      return 'Clock In';
    }
  }

  VoidCallback? _getButtonAction() {
    if (_isCheckedOut) {
      return widget.onClockIn;
    } else if (_isCheckedIn) {
      return widget.onClockOut;
    } else {
      return widget.onClockIn;
    }
  }

  String get _statusLabel {
    if (_isCheckedOut) return 'Day Complete';
    if (_isCheckedIn) return 'Working';
    return 'Not Clocked In';
  }

  Color get _statusColor {
    if (_isCheckedOut) return const Color(0xFF00b8d9);
    if (_isCheckedIn) return const Color(0xFF5cfbd8);
    return Colors.grey;
  }

  Widget _buildCompactTimeRow() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
      child: Column(
        children: [
          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: _statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _statusColor.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  _statusLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _statusColor,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Compact 3-column time display
          Row(
            children: [
              Expanded(
                child: _buildTimeTile(
                  label: 'Clock In',
                  value: _getClockInTimeDisplay(),
                  color: const Color(0xFF272579),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTimeTile(
                  label: 'Hours',
                  value: _getHoursWorked(),
                  color: const Color(0xFF0071bf),
                  isLive: _isCheckedIn && !_isCheckedOut,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTimeTile(
                  label: 'Clock Out',
                  value: _getClockOutTimeDisplay(),
                  color: _isCheckedOut
                      ? const Color(0xFF5cfbd8)
                      : Colors.grey,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Action button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: widget.isLoading ? null : (_getButtonAction()),
              style: ElevatedButton.styleFrom(
                backgroundColor: _getButtonColor(),
                foregroundColor: Colors.white,
                elevation: 0,
                shadowColor: _getButtonColor().withValues(alpha: 0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: widget.isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.white,
                        ),
                      ),
                    )
                  : Text(
                      _getButtonText(),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                        color: _getButtonText() == 'Clock In'
                            ? const Color(0xFF272579)
                            : Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeTile({
    required String label,
    required String value,
    required Color color,
    bool isLive = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.12),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.1,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: color,
                    letterSpacing: -0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isLive) ...[
                const SizedBox(width: 4),
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: const Color(0xFF5cfbd8),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF5cfbd8).withValues(alpha: 0.4),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLocationInfo() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0071bf).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.location_on_rounded,
                    color: Color(0xFF0071bf),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Location Tracking',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF272579),
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Your location is automatically captured when clocking in/out for accurate attendance tracking.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF5cfbd8).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF5cfbd8).withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.security_rounded,
                    color: Color(0xFF5cfbd8),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Your location data is securely stored and only used for attendance purposes.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      color: const Color(0xFF272579),
      child: widget.isLoading && widget.todayAttendance == null
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF272579)),
            )
          : SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildCompactTimeRow(),
                  const SizedBox(height: 20),
                  _buildLocationInfo(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }
}

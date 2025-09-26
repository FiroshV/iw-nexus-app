import 'package:flutter/material.dart';
import '../utils/timezone_util.dart';

class AttendanceTodayTab extends StatelessWidget {
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

  String _getHoursWorked() {
    if (todayAttendance?['totalWorkingHours'] != null) {
      // Final hours when clocked out
      return '${todayAttendance!['totalWorkingHours'].toStringAsFixed(1)}h';
    } else if (todayAttendance?['checkIn']?['time'] != null) {
      // Live calculation when clocked in
      final checkInTime = TimezoneUtil.parseToIST(
        todayAttendance!['checkIn']['time'],
      );
      final now = TimezoneUtil.nowIST();
      final duration = now.difference(checkInTime);
      final hours = duration.inMinutes / 60.0;
      return '${hours.toStringAsFixed(1)}h';
    } else {
      return '0.0h';
    }
  }

  String _getClockInTimeDisplay() {
    final checkIn = todayAttendance?['checkIn'];
    if (checkIn != null && checkIn['time'] != null) {
      final istTime = TimezoneUtil.parseToIST(checkIn['time']);
      return TimezoneUtil.timeOnlyIST(istTime);
    }
    return '--:--';
  }

  String _getClockOutTimeDisplay() {
    final checkOut = todayAttendance?['checkOut'];
    if (checkOut != null && checkOut['time'] != null) {
      final istTime = TimezoneUtil.parseToIST(checkOut['time']);
      return TimezoneUtil.timeOnlyIST(istTime);
    }
    return '--:--';
  }

  Color _getButtonColor() {
    final checkIn = todayAttendance?['checkIn'];
    final checkOut = todayAttendance?['checkOut'];
    final isCheckedIn = checkIn != null && checkIn['time'] != null;
    final isCheckedOut = checkOut != null && checkOut['time'] != null;

    if (isCheckedOut) {
      return const Color(0xFF0071bf); // Blue for clock in again
    } else if (isCheckedIn) {
      return Colors.red; // Red for clock out
    } else {
      return const Color(0xFF5cfbd8); // Green for first clock in
    }
  }

  String _getButtonText() {
    final checkIn = todayAttendance?['checkIn'];
    final checkOut = todayAttendance?['checkOut'];
    final isCheckedIn = checkIn != null && checkIn['time'] != null;
    final isCheckedOut = checkOut != null && checkOut['time'] != null;

    if (isLoading) {
      return isCheckedIn && !isCheckedOut
          ? 'Clocking Out...'
          : 'Clocking In...';
    } else if (isCheckedOut) {
      return 'Clock In Again';
    } else if (isCheckedIn) {
      return 'Clock Out';
    } else {
      return 'Clock In';
    }
  }

  VoidCallback? _getButtonAction() {
    final checkIn = todayAttendance?['checkIn'];
    final checkOut = todayAttendance?['checkOut'];
    final isCheckedIn = checkIn != null && checkIn['time'] != null;
    final isCheckedOut = checkOut != null && checkOut['time'] != null;

    if (isCheckedOut) {
      return onClockIn; // Allow clock in again after clocking out
    } else if (isCheckedIn) {
      return onClockOut;
    } else {
      return onClockIn;
    }
  }

  Widget _buildAttendanceCard() {
    final checkOut = todayAttendance?['checkOut'];
    final isCheckedOut = checkOut != null && checkOut['time'] != null;

    return Container(
      margin: EdgeInsets.zero,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, const Color(0xFFfbf8ff)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: const Color(0xFF272579).withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
        border: Border.all(
          color: const Color(0xFF272579).withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
            // Time information cards
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Clock in time card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF272579).withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF272579).withValues(alpha: 0.1),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Clock In',
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.1,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _getClockInTimeDisplay(),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF272579),
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Hours worked card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0071bf).withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF0071bf).withValues(alpha: 0.1),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.timer_rounded,
                        color: const Color(0xFF0071bf),
                        size: 24,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Hours',
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.1,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _getHoursWorked(),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0071bf),
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            if (isCheckedOut) ...[
              const SizedBox(height: 16),
              // Clock out time card when checked out
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF5cfbd8).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF5cfbd8).withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Clocked Out',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _getClockOutTimeDisplay(),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0071bf),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 32),

            // Action button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: isLoading ? null : (_getButtonAction()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _getButtonColor(),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shadowColor: _getButtonColor().withValues(alpha: 0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: isLoading
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
                          color: _getButtonText() == 'Clock In'? Color(0xFF272579) :Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationInfo() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, const Color(0xFFfbf8ff)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
            spreadRadius: 0,
          ),
        ],
        border: Border.all(
          color: const Color(0xFF272579).withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
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
                  child: Icon(
                    Icons.location_on_rounded,
                    color: const Color(0xFF0071bf),
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
                  Icon(
                    Icons.security_rounded,
                    color: const Color(0xFF5cfbd8),
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
      onRefresh: onRefresh,
      color: const Color(0xFF272579),
      child: isLoading && todayAttendance == null
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF272579)),
            )
          : SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildAttendanceCard(),
                  const SizedBox(height: 24),
                  _buildLocationInfo(),
                  const SizedBox(height: 32), // Bottom spacing
                ],
              ),
            ),
    );
  }
}
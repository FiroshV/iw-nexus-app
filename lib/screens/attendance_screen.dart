import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;
import '../services/api_service.dart';
import '../services/location_service.dart';
import '../utils/timezone_util.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final LocationService _locationService = LocationService();
  
  bool _isLoading = false;
  Map<String, dynamic>? _todayAttendance;

  @override
  void initState() {
    super.initState();
    _loadTodayAttendance();
  }

  Future<void> _loadTodayAttendance() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await ApiService.getTodayAttendance();
      if (response.success && mounted) {
        setState(() {
          _todayAttendance = response.data;
          _isLoading = false;
        });
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showError('Failed to load today\'s attendance: $e');
      }
    }
  }

  void _showLocationSettingsDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Location Access Required'),
          content: Text(message),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF272579),
                foregroundColor: Colors.white,
              ),
              child: const Text('Open Settings'),
              onPressed: () {
                Navigator.of(context).pop();
                _locationService.openLocationSettings();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _clockIn() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get current location first
      final locationResult = await _locationService.getCurrentPosition();
      
      if (!locationResult.success) {
        setState(() {
          _isLoading = false;
        });
        
        if (locationResult.canOpenSettings) {
          _showLocationSettingsDialog(locationResult.message);
        } else {
          _showError(locationResult.message);
        }
        return;
      }

      final position = locationResult.position!;
      
      // Check accuracy and warn user if needed
      if (!_locationService.hasGoodAccuracy(position)) {
        setState(() {
          _isLoading = false;
        });
        
        final shouldContinue = await _showAccuracyWarning(position.accuracy);
        if (!shouldContinue) return;
        
        setState(() {
          _isLoading = true;
        });
      }

      // First attempt - check-in without late reason
      var response = await ApiService.checkIn(
        location: _locationService.positionToMap(position),
        notes: 'Clock-in from mobile app',
      );

      // Debug logging for late clock-in detection
      debugPrint('🔍 Clock-in response: Success=${response.success}');
      debugPrint('🔍 Response message: ${response.message}');
      debugPrint('🔍 Response data: ${response.data}');
      debugPrint('🔍 Response data type: ${response.data.runtimeType}');
      if (response.data is Map) {
        debugPrint('🔍 RequiresReason: ${response.data?['requiresReason']}');
        debugPrint('🔍 ReasonType: ${response.data?['reasonType']}');
        debugPrint('🔍 LateBy: ${response.data?['lateBy']}');
      }

      // Enhanced late detection with multiple checks
      bool requiresLateReason = false;
      int lateByMinutes = 0;
      
      // Primary check: Backend indicates late reason required
      if (!response.success && response.data?['requiresReason'] == true) {
        requiresLateReason = true;
        lateByMinutes = response.data?['lateBy'] ?? 0;
        debugPrint('🔍 Backend detected late arrival: $lateByMinutes minutes');
      }
      // Secondary check: Error message contains late reason requirement
      else if (!response.success && response.message.toLowerCase().contains('late reason is required')) {
        requiresLateReason = true;
        // Try to extract late minutes from message or use client-side calculation
        lateByMinutes = _calculateClientSideLateMinutes();
        debugPrint('🔍 Error message indicates late arrival, client-side calculated: $lateByMinutes minutes');
      }
      // Tertiary check: 400 status with specific message pattern
      else if (!response.success && response.statusCode == 400 && 
               (response.message.contains('work hours') || response.message.contains('late'))) {
        requiresLateReason = true;
        lateByMinutes = _calculateClientSideLateMinutes();
        debugPrint('🔍 Status 400 with work hours message, client-side calculated: $lateByMinutes minutes');
      }

      if (requiresLateReason) {
        setState(() {
          _isLoading = false;
        });
        
        debugPrint('🔍 Showing late reason dialog for $lateByMinutes minutes late');
        final lateReason = await _showLateReasonDialog(lateByMinutes: lateByMinutes);
        
        if (lateReason == null) {
          // User cancelled
          debugPrint('🔍 User cancelled late reason dialog');
          return;
        }
        
        debugPrint('🔍 User provided late reason: $lateReason');
        setState(() {
          _isLoading = true;
        });

        // Retry check-in with late reason
        debugPrint('🔍 Retrying check-in with late reason');
        response = await ApiService.checkIn(
          location: _locationService.positionToMap(position),
          notes: 'Clock-in from mobile app',
          lateReason: lateReason,
        );
        
        debugPrint('🔍 Retry response: Success=${response.success}, Message=${response.message}');
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (response.success) {
          final lateBy = response.data?['lateBy'] ?? 0;
          final lateReason = response.data?['lateReason'];
          
          String successMessage = 'Clocked in successfully!';
          if (lateBy > 0) {
            successMessage = 'Clocked in successfully ($lateBy minutes late)';
            if (lateReason != null) {
              debugPrint('🔍 Late reason recorded: $lateReason');
            }
          }
          
          _showSuccess(successMessage);
          await _loadTodayAttendance();
        } else {
          // Enhanced error reporting
          String errorMessage = response.message;
          if (response.data is Map && response.data?['requiresReason'] == true) {
            errorMessage = 'Failed to process late clock-in. Please check your connection and try again.';
          }
          _showError(errorMessage);
          debugPrint('🔍 Final clock-in failed: ${response.message}');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showError('Clock in failed: $e');
      }
    }
  }

  Future<void> _clockOut() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get current location first
      final locationResult = await _locationService.getCurrentPosition();
      
      if (!locationResult.success) {
        setState(() {
          _isLoading = false;
        });
        
        if (locationResult.canOpenSettings) {
          _showLocationSettingsDialog(locationResult.message);
        } else {
          _showError(locationResult.message);
        }
        return;
      }

      final position = locationResult.position!;
      
      // Check accuracy and warn user if needed
      if (!_locationService.hasGoodAccuracy(position)) {
        setState(() {
          _isLoading = false;
        });
        
        final shouldContinue = await _showAccuracyWarning(position.accuracy);
        if (!shouldContinue) return;
        
        setState(() {
          _isLoading = true;
        });
      }

      final response = await ApiService.checkOut(
        location: _locationService.positionToMap(position),
        notes: 'Clock-out from mobile app',
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (response.success) {
          _showSuccess('Clocked out successfully!');
          await _loadTodayAttendance();
        } else {
          _showError(response.message);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showError('Clock out failed: $e');
      }
    }
  }

  Future<bool> _showAccuracyWarning(double accuracy) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Location Accuracy Warning'),
          content: Text(
            'Your current location accuracy is ${_locationService.getAccuracyDescription(accuracy)}. '
            'This may affect the accuracy of your attendance record. Do you want to continue?',
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF272579),
                foregroundColor: Colors.white,
              ),
              child: const Text('Continue'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );
    
    return result ?? false;
  }

  /// Calculate how late the user is based on client-side time
  /// This is a fallback when backend doesn't provide late minutes
  int _calculateClientSideLateMinutes() {
    try {
      final now = TimezoneUtil.nowIST();
      // Assume standard work start time is 9:00 AM
      final workStartTime = tz.TZDateTime(
        now.location,
        now.year,
        now.month,
        now.day,
        9, // 9 AM
        0, // 0 minutes
      );
      
      if (now.isAfter(workStartTime)) {
        final difference = now.difference(workStartTime);
        return difference.inMinutes;
      }
    } catch (e) {
      debugPrint('Error calculating client-side late minutes: $e');
    }
    return 0; // Default to 0 if calculation fails
  }

  Future<String?> _showLateReasonDialog({
    required int lateByMinutes,
  }) async {
    return await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return _LateReasonDialog(lateByMinutes: lateByMinutes);
      },
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Widget _buildAttendanceCard() {
    final checkIn = _todayAttendance?['checkIn'];
    final checkOut = _todayAttendance?['checkOut'];
    final isCheckedIn = checkIn != null && checkIn['time'] != null;
    final isCheckedOut = checkOut != null && checkOut['time'] != null;

    return Container(
      margin: EdgeInsets.zero,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            const Color(0xFFfbf8ff),
          ],
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
            // Status indicator
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isCheckedOut 
                      ? [const Color(0xFF5cfbd8).withValues(alpha: 0.15), Colors.green.withValues(alpha: 0.1)]
                      : isCheckedIn 
                          ? [const Color(0xFF0071bf).withValues(alpha: 0.15), const Color(0xFF272579).withValues(alpha: 0.1)]
                          : [Colors.orange.withValues(alpha: 0.15), Colors.amber.withValues(alpha: 0.1)],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isCheckedOut 
                      ? const Color(0xFF5cfbd8).withValues(alpha: 0.3)
                      : isCheckedIn 
                          ? const Color(0xFF0071bf).withValues(alpha: 0.3)
                          : Colors.orange.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: (isCheckedOut ? const Color(0xFF5cfbd8) : 
                             isCheckedIn ? const Color(0xFF0071bf) : Colors.orange).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isCheckedOut ? Icons.check_circle_rounded : 
                      isCheckedIn ? Icons.work_rounded : Icons.schedule_rounded,
                      color: isCheckedOut ? const Color(0xFF5cfbd8) : 
                             isCheckedIn ? const Color(0xFF0071bf) : Colors.orange,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _getStatusText(),
                    style: TextStyle(
                      color: isCheckedOut ? const Color(0xFF5cfbd8) : 
                             isCheckedIn ? const Color(0xFF0071bf) : Colors.orange,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 36),
            
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
                      Icon(
                        Icons.login_rounded,
                        color: const Color(0xFF272579),
                        size: 24,
                      ),
                      const SizedBox(height: 8),
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
                child: Row(
                  children: [
                    Icon(
                      Icons.logout_rounded,
                      color: const Color(0xFF5cfbd8),
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                            color: Color(0xFF5cfbd8),
                          ),
                        ),
                      ],
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
                onPressed: _isLoading ? null : (_getButtonAction()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _getButtonColor(),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shadowColor: _getButtonColor().withValues(alpha: 0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                      _getButtonText(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                        color: Color(0xFF272579)
                      ),
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getHoursWorked() {
    if (_todayAttendance?['totalWorkingHours'] != null) {
      // Final hours when clocked out
      return '${_todayAttendance!['totalWorkingHours'].toStringAsFixed(1)}h';
    } else if (_todayAttendance?['checkIn']?['time'] != null) {
      // Live calculation when clocked in
      final checkInTime = TimezoneUtil.parseToIST(_todayAttendance!['checkIn']['time']);
      final now = TimezoneUtil.nowIST();
      final duration = now.difference(checkInTime);
      final hours = duration.inMinutes / 60.0;
      return '${hours.toStringAsFixed(1)}h';
    } else {
      return '0.0h';
    }
  }

  String _getClockInTimeDisplay() {
    final checkIn = _todayAttendance?['checkIn'];
    if (checkIn != null && checkIn['time'] != null) {
      final istTime = TimezoneUtil.parseToIST(checkIn['time']);
      return TimezoneUtil.timeOnlyIST(istTime);
    }
    return '--:--';
  }

  String _getClockOutTimeDisplay() {
    final checkOut = _todayAttendance?['checkOut'];
    if (checkOut != null && checkOut['time'] != null) {
      final istTime = TimezoneUtil.parseToIST(checkOut['time']);
      return TimezoneUtil.timeOnlyIST(istTime);
    }
    return '--:--';
  }

  String _getStatusText() {
    final checkIn = _todayAttendance?['checkIn'];
    final checkOut = _todayAttendance?['checkOut'];
    final isCheckedIn = checkIn != null && checkIn['time'] != null;
    final isCheckedOut = checkOut != null && checkOut['time'] != null;
    
    if (isCheckedOut) {
      return 'Work Complete';
    } else if (isCheckedIn) {
      return 'Currently Working';
    } else {
      return 'Not Clocked In';
    }
  }

  Color _getButtonColor() {
    final checkIn = _todayAttendance?['checkIn'];
    final checkOut = _todayAttendance?['checkOut'];
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
    final checkIn = _todayAttendance?['checkIn'];
    final checkOut = _todayAttendance?['checkOut'];
    final isCheckedIn = checkIn != null && checkIn['time'] != null;
    final isCheckedOut = checkOut != null && checkOut['time'] != null;

    if (_isLoading) {
      return isCheckedIn && !isCheckedOut ? 'Clocking Out...' : 'Clocking In...';
    } else if (isCheckedOut) {
      return 'Clock In Again';
    } else if (isCheckedIn) {
      return 'Clock Out';
    } else {
      return 'Clock In';
    }
  }

  VoidCallback? _getButtonAction() {
    final checkIn = _todayAttendance?['checkIn'];
    final checkOut = _todayAttendance?['checkOut'];
    final isCheckedIn = checkIn != null && checkIn['time'] != null;
    final isCheckedOut = checkOut != null && checkOut['time'] != null;

    if (isCheckedOut) {
      return _clockIn; // Allow clock in again after clocking out
    } else if (isCheckedIn) {
      return _clockOut;
    } else {
      return _clockIn;
    }
  }

  Widget _buildLocationInfo() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            const Color(0xFFfbf8ff),
          ],
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
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF272579), Color(0xFF0071bf)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.schedule,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Attendance',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                  Text(
                    'Track your work hours',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        foregroundColor: Colors.white,
      ),
      backgroundColor: const Color(0xFFf8f9fa),
      body: RefreshIndicator(
        onRefresh: _loadTodayAttendance,
        color: const Color(0xFF272579),
        child: _isLoading && _todayAttendance == null
            ? const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF272579),
                ),
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
      ),
    );
  }
}

class _LateReasonDialog extends StatefulWidget {
  final int lateByMinutes;
  
  const _LateReasonDialog({required this.lateByMinutes});

  @override
  State<_LateReasonDialog> createState() => _LateReasonDialogState();
}

class _LateReasonDialogState extends State<_LateReasonDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Late Arrival Reason'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Please provide a reason for your late clock in:'),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            maxLines: 3,
            maxLength: 200,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              counterText: '',
            ),
            textCapitalization: TextCapitalization.sentences,
            autofocus: true,
          ),
          const SizedBox(height: 8),
          Text(
            'Minimum 10 characters required',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
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
          ),
          child: const Text('Submit'),
          onPressed: () {
            final reason = _controller.text.trim();
            if (reason.length >= 10) {
              Navigator.of(context).pop(reason);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please provide at least 10 characters for the reason'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
        ),
      ],
    );
  }
}
import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;
import '../services/api_service.dart';
import '../services/location_service.dart';
import '../utils/timezone_util.dart';
import '../widgets/attendance_today_tab.dart';
import '../widgets/attendance_week_tab.dart';
import '../widgets/attendance_month_tab.dart';

class EnhancedAttendanceScreen extends StatefulWidget {
  const EnhancedAttendanceScreen({super.key});

  @override
  State<EnhancedAttendanceScreen> createState() => _EnhancedAttendanceScreenState();
}

class _EnhancedAttendanceScreenState extends State<EnhancedAttendanceScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final LocationService _locationService = LocationService();

  bool _isLoading = false;
  Map<String, dynamic>? _todayAttendance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadTodayAttendance();
    // Pre-fetch location aggressively for ultra-fast performance
    _locationService.preFetchLocation();
    // Pre-fetch again after a short delay to ensure we have fresh location
    Future.delayed(const Duration(seconds: 2), () {
      _locationService.preFetchLocation();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
      // Start location fetch immediately in parallel with UI update
      final locationFuture = _locationService.getCurrentPosition();

      // Get location result (should be very fast with our optimizations)
      final locationResult = await locationFuture;

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

      // Location obtained - continue with ultra-fast processing

      // First attempt - check-in without late reason
      var response = await ApiService.checkIn(
        location: _locationService.positionToMap(position),
        notes: 'Clock-in from phone app',
      );

      // Process response quickly

      // Enhanced late detection with multiple checks
      bool requiresLateReason = false;
      int lateByMinutes = 0;

      // Quick late detection checks
      if (!response.success && response.data?['requiresReason'] == true) {
        requiresLateReason = true;
        lateByMinutes = response.data?['lateBy'] ?? 0;
      } else if (!response.success &&
          response.message.toLowerCase().contains('late reason is required')) {
        requiresLateReason = true;
        lateByMinutes = _calculateClientSideLateMinutes();
      } else if (!response.success &&
          response.statusCode == 400 &&
          (response.message.contains('work hours') ||
              response.message.contains('late'))) {
        requiresLateReason = true;
        lateByMinutes = _calculateClientSideLateMinutes();
      }

      if (requiresLateReason) {
        setState(() {
          _isLoading = false;
        });

        final lateReason = await _showLateReasonDialog(
          lateByMinutes: lateByMinutes,
        );

        if (lateReason == null) {
          return;
        }
        setState(() {
          _isLoading = true;
        });

        // Retry check-in with late reason
        response = await ApiService.checkIn(
          location: _locationService.positionToMap(position),
          notes: 'Clock-in from phone app',
          lateReason: lateReason,
        );
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (response.success) {
          final lateBy = response.data?['lateBy'] ?? 0;

          String successMessage = 'Clocked in successfully!';
          if (lateBy > 0) {
            successMessage = 'Clocked in successfully';
          }

          _showSuccess(successMessage);
          await _loadTodayAttendance();
        } else {
          // Enhanced error reporting
          String errorMessage = response.message;
          if (response.data is Map &&
              response.data?['requiresReason'] == true) {
            errorMessage =
                'Failed to process late clock-in. Please check your connection and try again.';
          }
          _showError(errorMessage);
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
      // Start location fetch immediately in parallel with UI update
      final locationFuture = _locationService.getCurrentPosition();

      // Get location result (should be very fast with our optimizations)
      final locationResult = await locationFuture;

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

      // Location obtained - continue with ultra-fast processing

      final response = await ApiService.checkOut(
        location: _locationService.positionToMap(position),
        notes: 'Clock-out from phone app',
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

  Future<String?> _showLateReasonDialog({required int lateByMinutes}) async {
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
              child: const Icon(Icons.schedule, color: Colors.white, size: 20),
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
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF5cfbd8),
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w400,
            fontSize: 14,
          ),
          tabs: const [
            Tab(
              icon: Icon(Icons.today, size: 20),
              text: 'Today',
            ),
            Tab(
              icon: Icon(Icons.view_week, size: 20),
              text: 'Week',
            ),
            Tab(
              icon: Icon(Icons.calendar_month, size: 20),
              text: 'Month',
            ),
          ],
        ),
      ),
      backgroundColor: const Color(0xFFf8f9fa),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Today Tab
          AttendanceTodayTab(
            isLoading: _isLoading,
            todayAttendance: _todayAttendance,
            onClockIn: _clockIn,
            onClockOut: _clockOut,
            onRefresh: _loadTodayAttendance,
          ),
          // Week Tab
          AttendanceWeekTab(
            onRefresh: () async {
              // Refresh callback for week tab
            },
          ),
          // Month Tab
          AttendanceMonthTab(
            onRefresh: () async {
              // Refresh callback for month tab
            },
          ),
        ],
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
          ),
          child: const Text('Submit'),
          onPressed: () {
            final reason = _controller.text.trim();
            if (reason.length >= 10) {
              Navigator.of(context).pop(reason);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Please provide at least 10 characters for the reason',
                  ),
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
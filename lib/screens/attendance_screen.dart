import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';

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

      // Call check-in API with location
      final response = await ApiService.checkIn(
        location: _locationService.positionToMap(position),
        notes: 'Clock-in from mobile app',
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (response.success) {
          _showSuccess('Clocked in successfully!');
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

    return Card(
      margin: const EdgeInsets.all(20),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Status indicator
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              decoration: BoxDecoration(
                color: isCheckedOut 
                    ? Colors.green.withValues(alpha: 0.1)
                    : isCheckedIn 
                        ? const Color(0xFF0071bf).withValues(alpha: 0.1)
                        : Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isCheckedOut 
                      ? Colors.green
                      : isCheckedIn 
                          ? const Color(0xFF0071bf)
                          : Colors.orange,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isCheckedOut ? Icons.check_circle : 
                    isCheckedIn ? Icons.work : Icons.schedule,
                    color: isCheckedOut ? Colors.green : 
                           isCheckedIn ? const Color(0xFF0071bf) : Colors.orange,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _getStatusText(),
                    style: TextStyle(
                      color: isCheckedOut ? Colors.green : 
                             isCheckedIn ? const Color(0xFF0071bf) : Colors.orange,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Time information
            Row(
              children: [
                // Clock in time
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        'Clocked In',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _getClockInTimeDisplay(),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF272579),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Divider
                Container(
                  height: 40,
                  width: 1,
                  color: Colors.grey[300],
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                ),
                
                // Hours worked
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        'Hours Worked',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _getHoursWorked(),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0071bf),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Action button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : (_getButtonAction()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _getButtonColor(),
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(_getButtonText()),
              ),
            ),
            
            if (!isCheckedOut) ...[
              const SizedBox(height: 12),
              Text(
                'Location will be automatically captured',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ],
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
      final checkInTime = DateTime.parse(_todayAttendance!['checkIn']['time']);
      final now = DateTime.now();
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
      return DateFormat('h:mm a').format(DateTime.parse(checkIn['time']));
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance'),
        backgroundColor: const Color(0xFF272579),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTodayAttendance,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading && _todayAttendance == null
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF272579),
              ),
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  _buildAttendanceCard(),
                  const SizedBox(height: 32), // Bottom spacing
                ],
              ),
            ),
    );
  }
}
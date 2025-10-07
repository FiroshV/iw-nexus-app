import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../utils/timezone_util.dart';

class StaffAttendanceWidget extends StatefulWidget {
  final String userId;
  final String userName;

  const StaffAttendanceWidget({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<StaffAttendanceWidget> createState() => _StaffAttendanceWidgetState();
}

class _StaffAttendanceWidgetState extends State<StaffAttendanceWidget> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _attendanceRecords = [];
  String? _errorMessage;

  // Month/Year selection
  late int _selectedMonth;
  late int _selectedYear;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = now.month;
    _selectedYear = now.year;
    _loadAttendanceData();
  }

  void _previousMonth() {
    setState(() {
      if (_selectedMonth == 1) {
        _selectedMonth = 12;
        _selectedYear--;
      } else {
        _selectedMonth--;
      }
      _loadAttendanceData();
    });
  }

  void _nextMonth() {
    final now = DateTime.now();
    // Don't allow going beyond current month
    if (_selectedYear == now.year && _selectedMonth == now.month) {
      return;
    }

    setState(() {
      if (_selectedMonth == 12) {
        _selectedMonth = 1;
        _selectedYear++;
      } else {
        _selectedMonth++;
      }
      _loadAttendanceData();
    });
  }

  Future<void> _loadAttendanceData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      debugPrint('🔍 Loading attendance for userId: ${widget.userId}');

      // Get selected month's date range
      final startDate = DateTime(_selectedYear, _selectedMonth, 1);
      final endDate = DateTime(_selectedYear, _selectedMonth + 1, 0, 23, 59, 59);

      debugPrint('🔍 Month: $_selectedMonth/$_selectedYear');
      debugPrint('🔍 Date range: ${startDate.toIso8601String()} to ${endDate.toIso8601String()}');

      final response = await ApiService.getStaffAttendance(
        userId: widget.userId,
        startDate: startDate.toIso8601String(),
        endDate: endDate.toIso8601String(),
        limit: 100,
      );

      debugPrint('🔍 API Response - Success: ${response.success}');
      debugPrint('🔍 API Response - Data: ${response.data}');

      if (response.success && response.data != null) {
        debugPrint('🔍 Full response data: ${response.data}');

        // response.data is already the array of attendance records
        final records = response.data;
        debugPrint('🔍 Records type: ${records.runtimeType}');
        debugPrint('🔍 Records value: $records');

        List<Map<String, dynamic>> parsedRecords = [];

        if (records != null && records is List) {
          parsedRecords = records.map((record) {
            if (record is Map) {
              final mapped = Map<String, dynamic>.from(record);
              // Debug clock in/out times
              debugPrint('📍 Record date: ${mapped['date']}');
              debugPrint('📍 Clock In Time: ${mapped['clockInTime']} (type: ${mapped['clockInTime'].runtimeType})');
              debugPrint('📍 Clock Out Time: ${mapped['clockOutTime']} (type: ${mapped['clockOutTime'].runtimeType})');
              return mapped;
            }
            debugPrint('⚠️ Unexpected record type: ${record.runtimeType}');
            return <String, dynamic>{};
          }).toList();
        }

        debugPrint('🔍 Parsed records count: ${parsedRecords.length}');

        if (mounted) {
          setState(() {
            _attendanceRecords = parsedRecords;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = response.message;
            _isLoading = false;
          });
        }
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error loading staff attendance: $e');
      debugPrint('Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _errorMessage = 'Error: $e';
          _isLoading = false;
        });
      }
    }
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'present':
        return const Color(0xFF10B981); // Green
      case 'late':
        return const Color(0xFFF59E0B); // Amber
      case 'absent':
        return const Color(0xFFEF4444); // Red
      case 'half_day':
        return const Color(0xFF8B5CF6); // Purple
      case 'on_leave':
        return const Color(0xFF3B82F6); // Blue
      default:
        return Colors.grey;
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('EEE, MMM dd').format(date); // "Mon, Dec 04"
    } catch (e) {
      return dateStr;
    }
  }

  String _formatTime(String? timeStr) {
    if (timeStr == null) return '--';
    try {
      return TimezoneUtil.formatIST(
        TimezoneUtil.parseToIST(timeStr),
        'h:mm a',
      );
    } catch (e) {
      return '--';
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isCurrentMonth = _selectedYear == now.year && _selectedMonth == now.month;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        toolbarHeight: 0,
      ),
      body: Column(
        children: [
          // Month Picker
          _buildMonthPicker(isCurrentMonth),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF0071bf),
                    ),
                  )
                : _errorMessage != null
                    ? _buildErrorState()
                    : _attendanceRecords.isEmpty
                        ? _buildEmptyState()
                        : _buildAttendanceList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthPicker(bool isCurrentMonth) {
    final monthName = DateFormat('MMMM yyyy').format(DateTime(_selectedYear, _selectedMonth));

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 2),
            spreadRadius: -2,
          ),
        ],
      ),
      child: Row(
        children: [
          // Previous Month Button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _previousMonth,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(12),
                child: const Icon(
                  Icons.chevron_left_rounded,
                  color: Color(0xFF0071bf),
                  size: 24,
                ),
              ),
            ),
          ),

          // Month/Year Display
          Expanded(
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF0071bf).withValues(alpha: 0.1),
                      const Color(0xFF00b8d9).withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.calendar_month_rounded,
                      color: Color(0xFF0071bf),
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      monthName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0071bf),
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Next Month Button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isCurrentMonth ? null : _nextMonth,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(12),
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: isCurrentMonth ? Colors.grey[300] : const Color(0xFF0071bf),
                  size: 24,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Color(0xFFEF4444),
            ),
            const SizedBox(height: 16),
            Text(
              'Unable to Load Attendance',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Something went wrong',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadAttendanceData,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0071bf),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            const Text(
              'No Attendance Records',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No attendance data found for the last 30 days',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextButton.icon(
              onPressed: _loadAttendanceData,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF0071bf),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceList() {
    // Calculate summary statistics
    final totalDays = _attendanceRecords.length;
    final totalHours = _attendanceRecords.fold<double>(
      0.0,
      (sum, record) => sum + ((record['totalHours'] as num?) ?? 0).toDouble(),
    );

    return RefreshIndicator(
      onRefresh: _loadAttendanceData,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _attendanceRecords.length + 1, // +1 for summary card
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          // First item is the summary card
          if (index == 0) {
            return _buildSummaryCard(totalDays, totalHours);
          }

          // Adjust index for actual records
          final recordIndex = index - 1;
          final record = _attendanceRecords[recordIndex];
          final isAlternate = recordIndex % 2 == 1;
          return _buildAttendanceCard(record, isAlternate);
        },
      ),
    );
  }

  Widget _buildSummaryCard(int totalDays, double totalHours) {
    final avgHours = totalDays > 0 ? totalHours / totalDays : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0071bf), Color(0xFF00b8d9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0071bf).withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.analytics_outlined,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Monthly Overview',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Stats Row
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.calendar_today,
                    label: 'Days Worked',
                    value: totalDays.toString(),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.access_time,
                    label: 'Total Hours',
                    value: totalHours.toStringAsFixed(1),
                  ),
                ),
              ],
            ),

            // Average hours per day
            if (totalDays > 0) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.trending_up,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Avg ${avgHours.toStringAsFixed(1)} hrs/day',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceCard(Map<String, dynamic> record, bool isAlternate) {
    final status = record['status'] as String?;
    final date = record['date'] as String?;
    final clockInTime = record['clockInTime'] as String?;
    final clockOutTime = record['clockOutTime'] as String?;
    final totalHours = record['totalHours'] as num?;
    final isLate = record['isLate'] as bool? ?? false;
    final lateBy = record['lateBy'] as num? ?? 0;

    // Only show meaningful status badges (absent, on_leave)
    final showStatusBadge = status == 'absent' || status == 'on_leave';
    final statusColor = _getStatusColor(status);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border(
          left: BorderSide(
            color: isAlternate ? const Color(0xFF0071bf) : const Color(0xFF00b8d9),
            width: 4,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 2),
            spreadRadius: -2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF0071bf).withValues(alpha: 0.15),
                        const Color(0xFF00b8d9).withValues(alpha: 0.15),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.calendar_today_rounded,
                    color: Color(0xFF0071bf),
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatDate(date),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B),
                          letterSpacing: -0.2,
                        ),
                      ),
                      if (isLate && lateBy > 0) ...[
                        const SizedBox(height: 3),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.schedule,
                                size: 10,
                                color: Color(0xFFEF4444),
                              ),
                              const SizedBox(width: 3),
                              Text(
                                'Late by ${lateBy.toInt()} min',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFFEF4444),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (showStatusBadge)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: statusColor.withValues(alpha: 0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      status?.toUpperCase() ?? '',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Divider
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  const Color(0xFFE2E8F0).withValues(alpha: 0.5),
                  Colors.transparent,
                ],
              ),
            ),
          ),

          // Clock Times Section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Clock In
                _buildVerticalTimeSection(
                  icon: Icons.login_rounded,
                  label: 'Clock In',
                  time: _formatTime(clockInTime),
                  color: const Color(0xFF10B981),
                ),

                // Arrow Divider
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Icon(
                    Icons.arrow_downward_rounded,
                    color: Colors.grey[300],
                    size: 16,
                  ),
                ),

                // Clock Out
                _buildVerticalTimeSection(
                  icon: Icons.logout_rounded,
                  label: 'Clock Out',
                  time: _formatTime(clockOutTime),
                  color: const Color(0xFFEF4444),
                ),

                // Total Hours Badge
                if (totalHours != null && totalHours > 0) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF0071bf).withValues(alpha: 0.1),
                          const Color(0xFF00b8d9).withValues(alpha: 0.08),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFF0071bf).withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0071bf).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            Icons.timer_outlined,
                            size: 14,
                            color: Color(0xFF0071bf),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${totalHours.toStringAsFixed(1)} hours worked',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0071bf),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalTimeSection({
    required IconData icon,
    required String label,
    required String time,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.08),
            color.withValues(alpha: 0.03),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),

          // Label and Time
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  time,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                    letterSpacing: -0.3,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

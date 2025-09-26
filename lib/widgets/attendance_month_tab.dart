// ignore_for_file: unused_element

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/api_service.dart';

class AttendanceMonthTab extends StatefulWidget {
  final Future<void> Function() onRefresh;

  const AttendanceMonthTab({
    super.key,
    required this.onRefresh,
  });

  @override
  State<AttendanceMonthTab> createState() => _AttendanceMonthTabState();
}

class _AttendanceMonthTabState extends State<AttendanceMonthTab> {
  bool _isLoading = true;
  Map<String, dynamic>? _monthlyData;
  String _error = '';
  DateTime _selectedMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadMonthlyData();
  }

  Future<void> _loadMonthlyData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final year = _selectedMonth.year;
      final month = _selectedMonth.month;

      final response = await ApiService.getMonthlyAttendance(year: year, month: month);

      if (response.success && mounted) {
        setState(() {
          _monthlyData = response.data;
          _isLoading = false;
        });
      } else {
        if (mounted) {
          setState(() {
            _error = response.message;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load monthly data: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _navigateMonth(int direction) {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + direction,
        1,
      );
    });
    _loadMonthlyData();
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'present':
        return const Color(0xFF5cfbd8);
      case 'late':
        return const Color(0xFFffa726);
      case 'absent':
        return Colors.red;
      case 'half_day':
        return const Color(0xFF42a5f5);
      default:
        return Colors.grey[300]!;
    }
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  Widget _buildMonthNavigator() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: const Color(0xFF272579).withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => _navigateMonth(-1),
            icon: const Icon(Icons.arrow_back_ios),
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFF0071bf).withValues(alpha: 0.1),
              foregroundColor: const Color(0xFF0071bf),
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  _getMonthName(_selectedMonth.month),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF272579),
                  ),
                ),
                Text(
                  '${_selectedMonth.year}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _navigateMonth(1),
            icon: const Icon(Icons.arrow_forward_ios),
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFF0071bf).withValues(alpha: 0.1),
              foregroundColor: const Color(0xFF0071bf),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlySummary() {
    if (_monthlyData == null) return const SizedBox.shrink();

    final summary = _monthlyData!['summary'] as Map<String, dynamic>;
    final totalDays = summary['totalDays'] ?? 0;
    final presentDays = summary['presentDays'] ?? 0;
    final absentDays = summary['absentDays'] ?? 0;
    final lateDays = summary['lateDays'] ?? 0;
    final totalHours = (summary['totalWorkingHours'] ?? 0.0).toDouble();
    final avgHours = (summary['averageWorkingHours'] ?? 0.0).toDouble();

    final attendanceRate = totalDays > 0 ? (presentDays / totalDays * 100) : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, const Color(0xFFfbf8ff)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: const Color(0xFF272579).withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.calendar_month,
                color: Color(0xFF272579),
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text(
                'Monthly Summary',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF272579),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Attendance',
                  '${attendanceRate.toStringAsFixed(1)}%',
                  const Color(0xFF5cfbd8),
                  Icons.check_circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  'Present',
                  '$presentDays/$totalDays',
                  const Color(0xFF0071bf),
                  Icons.today,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Late Days',
                  '$lateDays',
                  const Color(0xFFffa726),
                  Icons.schedule,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  'Absent',
                  '$absentDays',
                  Colors.red,
                  Icons.cancel,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Total Hours',
                  '${totalHours.toStringAsFixed(1)}h',
                  const Color(0xFF00b8d9),
                  Icons.timer,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  'Avg/Day',
                  '${avgHours.toStringAsFixed(1)}h',
                  const Color(0xFF272579),
                  Icons.trending_up,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceChart() {
    if (_monthlyData == null) return const SizedBox.shrink();

    final summary = _monthlyData!['summary'] as Map<String, dynamic>;
    final presentDays = (summary['presentDays'] ?? 0).toDouble();
    final absentDays = (summary['absentDays'] ?? 0).toDouble();
    final lateDays = (summary['lateDays'] ?? 0).toDouble();
    final halfDays = (summary['halfDays'] ?? 0).toDouble();

    final totalDays = presentDays + absentDays + lateDays + halfDays;

    if (totalDays == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: const Color(0xFF272579).withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Attendance Breakdown',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF272579),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sections: [
                  if (presentDays > 0)
                    PieChartSectionData(
                      color: const Color(0xFF5cfbd8),
                      value: presentDays,
                      title: '${(presentDays / totalDays * 100).toStringAsFixed(1)}%',
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  if (lateDays > 0)
                    PieChartSectionData(
                      color: const Color(0xFFffa726),
                      value: lateDays,
                      title: '${(lateDays / totalDays * 100).toStringAsFixed(1)}%',
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  if (absentDays > 0)
                    PieChartSectionData(
                      color: Colors.red,
                      value: absentDays,
                      title: '${(absentDays / totalDays * 100).toStringAsFixed(1)}%',
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  if (halfDays > 0)
                    PieChartSectionData(
                      color: const Color(0xFF42a5f5),
                      value: halfDays,
                      title: '${(halfDays / totalDays * 100).toStringAsFixed(1)}%',
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                ],
                sectionsSpace: 2,
                centerSpaceRadius: 40,
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildLegend(),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        _buildLegendItem('Present', const Color(0xFF5cfbd8)),
        _buildLegendItem('Late', const Color(0xFFffa726)),
        _buildLegendItem('Absent', Colors.red),
        _buildLegendItem('Half Day', const Color(0xFF42a5f5)),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildCalendarView() {
    if (_monthlyData == null) return const SizedBox.shrink();

    final attendanceList = _monthlyData!['attendance'] as List<dynamic>;
    final Map<int, Map<String, dynamic>> attendanceMap = {};

    // Create a map of day -> attendance data
    for (var attendance in attendanceList) {
      final dateStr = attendance['date'] as String;
      final date = DateTime.parse(dateStr);
      attendanceMap[date.day] = attendance;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: const Color(0xFF272579).withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              'Calendar View',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF272579),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _buildCalendarGrid(attendanceMap),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid(Map<int, Map<String, dynamic>> attendanceMap) {
    final firstDay = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final lastDay = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);
    final firstWeekday = firstDay.weekday % 7; // 0 = Monday, 6 = Sunday

    // Week day headers
    const weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate responsive cell size based on available width
        final availableWidth = constraints.maxWidth;
        final cellSize = (availableWidth - 28) / 7; // 28 = 7 cells * 4px margin
        final maxCellSize = 44.0; // Maximum size for larger screens
        final finalCellSize = cellSize.clamp(32.0, maxCellSize);

        return Column(
          children: [
            // Week day headers
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: weekDays.map((day) => SizedBox(
                width: finalCellSize,
                height: 32,
                child: Center(
                  child: Text(
                    day,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              )).toList(),
            ),
            const SizedBox(height: 8),
            // Calendar grid
            ...List.generate((lastDay.day + firstWeekday + 6) ~/ 7, (weekIndex) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(7, (dayIndex) {
                    final dayNumber = weekIndex * 7 + dayIndex - firstWeekday + 1;

                    if (dayNumber < 1 || dayNumber > lastDay.day) {
                      return SizedBox(width: finalCellSize, height: finalCellSize);
                    }

                    final attendance = attendanceMap[dayNumber];
                    final status = attendance?['status'] ?? 'absent';
                    final isToday = dayNumber == DateTime.now().day &&
                                   _selectedMonth.month == DateTime.now().month &&
                                   _selectedMonth.year == DateTime.now().year;

                    return Container(
                      width: finalCellSize,
                      height: finalCellSize,
                      margin: const EdgeInsets.all(1),
                      decoration: BoxDecoration(
                        color: _getStatusColor(status),
                        shape: BoxShape.circle,
                        border: isToday ? Border.all(
                          color: const Color(0xFF272579),
                          width: 2,
                        ) : null,
                      ),
                      child: Center(
                        child: Text(
                          '$dayNumber',
                          style: TextStyle(
                            fontSize: (finalCellSize * 0.28).clamp(10.0, 14.0),
                            fontWeight: FontWeight.w600,
                            color: status == 'absent' ? Colors.black : Color(0xFF272579),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              );
            }),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadMonthlyData,
      color: const Color(0xFF272579),
      child: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF272579)),
            )
          : _error.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _error,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadMonthlyData,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF272579),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildMonthNavigator(),
                      _buildMonthlySummary(),
                      // _buildAttendanceChart(),
                      _buildCalendarView(),
                    ],
                  ),
                ),
    );
  }
}
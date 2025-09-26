import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/api_service.dart';
import '../utils/timezone_util.dart';

class AttendanceWeekTab extends StatefulWidget {
  final Future<void> Function() onRefresh;

  const AttendanceWeekTab({
    super.key,
    required this.onRefresh,
  });

  @override
  State<AttendanceWeekTab> createState() => _AttendanceWeekTabState();
}

class _AttendanceWeekTabState extends State<AttendanceWeekTab> {
  bool _isLoading = true;
  Map<String, dynamic>? _weeklyData;
  String _error = '';
  DateTime _selectedWeek = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadWeeklyData();
  }

  Future<void> _loadWeeklyData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final year = _selectedWeek.year;
      final week = _getWeekNumber(_selectedWeek);

      final response = await ApiService.getWeeklyAttendance(year: year, week: week);

      if (response.success && mounted) {
        setState(() {
          _weeklyData = response.data;
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
          _error = 'Failed to load weekly data: $e';
          _isLoading = false;
        });
      }
    }
  }

  int _getWeekNumber(DateTime date) {
    final startOfYear = DateTime(date.year, 1, 1);
    final days = date.difference(startOfYear).inDays;
    return ((days + startOfYear.weekday - 1) / 7).floor() + 1;
  }

  void _navigateWeek(int direction) {
    setState(() {
      _selectedWeek = _selectedWeek.add(Duration(days: 7 * direction));
    });
    _loadWeeklyData();
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
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'present':
        return Icons.check_circle;
      case 'late':
        return Icons.schedule;
      case 'absent':
        return Icons.cancel;
      case 'half_day':
        return Icons.circle_outlined;
      default:
        return Icons.help_outline;
    }
  }

  Widget _buildWeekNavigator() {
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
            onPressed: () => _navigateWeek(-1),
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
                  'Week ${_getWeekNumber(_selectedWeek)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF272579),
                  ),
                ),
                Text(
                  '${_selectedWeek.year}',
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
            onPressed: () => _navigateWeek(1),
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

  Widget _buildWeeklySummary() {
    if (_weeklyData == null) return const SizedBox.shrink();

    final totalDays = _weeklyData!['totalDays'] ?? 0;
    final presentDays = _weeklyData!['presentDays'] ?? 0;
    final lateDays = _weeklyData!['lateDays'] ?? 0;
    final totalHours = (_weeklyData!['totalHours'] ?? 0.0).toDouble();

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
          const Text(
            'Weekly Summary',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF272579),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Present',
                  '$presentDays/$totalDays',
                  const Color(0xFF5cfbd8),
                  Icons.check_circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  'Late',
                  '$lateDays',
                  const Color(0xFFffa726),
                  Icons.schedule,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Hours',
                  '${totalHours.toStringAsFixed(1)}h',
                  const Color(0xFF0071bf),
                  Icons.timer,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  'Avg/Day',
                  totalDays > 0 ? '${(totalHours / totalDays).toStringAsFixed(1)}h' : '0.0h',
                  const Color(0xFF00b8d9),
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
              fontSize: 12,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyChart() {
    if (_weeklyData == null) return const SizedBox.shrink();

    final weeklyData = _weeklyData!['weeklyData'] as List<dynamic>;

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
            'Daily Hours',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF272579),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 10,
                barTouchData: BarTouchData(enabled: true),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                        return Text(
                          days[value.toInt()],
                          style: const TextStyle(fontSize: 12),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}h',
                          style: const TextStyle(fontSize: 10),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                barGroups: weeklyData.asMap().entries.map((entry) {
                  final index = entry.key;
                  final dayData = entry.value;
                  final hours = (dayData['attendance']?['totalWorkingHours'] ?? 0.0).toDouble();
                  final status = dayData['status'] as String;

                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: hours,
                        color: _getStatusColor(status),
                        width: 20,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDaysList() {
    if (_weeklyData == null) return const SizedBox.shrink();

    final weeklyData = _weeklyData!['weeklyData'] as List<dynamic>;

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
              'Daily Breakdown',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF272579),
              ),
            ),
          ),
          ...weeklyData.map((dayData) => _buildDayItem(dayData)),
        ],
      ),
    );
  }

  Widget _buildDayItem(Map<String, dynamic> dayData) {
    final dateStr = dayData['date'] as String;
    final date = DateTime.parse(dateStr);
    final dayName = dayData['dayName'] as String;
    final status = dayData['status'] as String;
    final attendance = dayData['attendance'] as Map<String, dynamic>?;

    final checkInTime = attendance?['checkIn']?['time'];
    final checkOutTime = attendance?['checkOut']?['time'];
    final totalHours = attendance?['totalWorkingHours'] ?? 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _getStatusColor(status).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getStatusIcon(status),
              color: _getStatusColor(status),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      dayName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF272579),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${date.day}/${date.month}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                if (checkInTime != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        'In: ${TimezoneUtil.timeOnlyIST(TimezoneUtil.parseToIST(checkInTime))}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      if (checkOutTime != null) ...[
                        const SizedBox(width: 16),
                        Text(
                          'Out: ${TimezoneUtil.timeOnlyIST(TimezoneUtil.parseToIST(checkOutTime))}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (totalHours > 0)
            Text(
              '${totalHours.toStringAsFixed(1)}h',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _getStatusColor(status),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadWeeklyData,
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
                        onPressed: _loadWeeklyData,
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
                      _buildWeekNavigator(),
                      _buildWeeklySummary(),
                      _buildWeeklyChart(),
                      _buildDaysList(),
                    ],
                  ),
                ),
    );
  }
}
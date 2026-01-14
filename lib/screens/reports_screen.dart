import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/access_control_service.dart';
import '../providers/gamification_provider.dart';
import '../widgets/gamification/leaderboard_filter_bar.dart';
import '../widgets/gamification/podium_widget.dart';
import '../widgets/gamification/my_rank_card.dart';
import '../widgets/gamification/leaderboard_item.dart';
import '../widgets/gamification/leaderboard_empty_state.dart';
import '../config/crm_design_system.dart';

class ReportsScreen extends StatefulWidget {
  final String? userRole;
  final String? userId;

  const ReportsScreen({
    super.key,
    required this.userRole,
    this.userId,
  });

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  bool _isLoading = true;
  String _error = '';
  Map<String, dynamic>? _summaryData;
  Map<String, dynamic>? _branchData;

  String _selectedPeriod = 'month';
  DateTime _selectedDate = DateTime.now();

  // Leaderboard state
  String _selectedMetric = 'sales_count';

  // Helper method to format DateTime to date-only string
  String _formatDateOnly(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
    _initializeTabs();
    _loadInitialData();
  }

  void _initializeTabs() {
    // Determine number of tabs based on user role
    int tabCount = 1; // Always have summary tab

    if (AccessControlService.hasAccess(widget.userRole, 'reports', 'attendance_reports')) {
      tabCount++;
    }

    if (AccessControlService.hasAccess(widget.userRole, 'attendance', 'view_all')) {
      tabCount++; // Branch comparison tab for admin/director
    }

    if (AccessControlService.hasAccess(widget.userRole, 'reports', 'leaderboard_reports')) {
      tabCount++; // Leaderboards tab
    }

    _tabController = TabController(length: tabCount, vsync: this);

    // Listen to tab changes to load leaderboard data
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        final leaderboardsTabIndex = _getLeaderboardsTabIndex();
        if (leaderboardsTabIndex != null && _tabController.index == leaderboardsTabIndex) {
          _loadLeaderboardData();
        }
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      await Future.wait([
        _loadSummaryData(),
        if (AccessControlService.hasAccess(widget.userRole, 'attendance', 'view_all'))
          _loadBranchData(),
      ]);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load reports: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadSummaryData() async {
    try {
      String? startDate;
      String? endDate;

      switch (_selectedPeriod) {
        case 'week':
          final startOfWeek = _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));
          final endOfWeek = startOfWeek.add(const Duration(days: 6));
          startDate = _formatDateOnly(startOfWeek);
          endDate = _formatDateOnly(endOfWeek);
          break;
        case 'month':
          final startOfMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);
          final endOfMonth = DateTime(_selectedDate.year, _selectedDate.month + 1, 0);
          startDate = _formatDateOnly(startOfMonth);
          endDate = _formatDateOnly(endOfMonth);
          break;
        case 'quarter':
          final quarter = ((_selectedDate.month - 1) / 3).floor();
          final startOfQuarter = DateTime(_selectedDate.year, quarter * 3 + 1, 1);
          final endOfQuarter = DateTime(_selectedDate.year, quarter * 3 + 4, 0);
          startDate = _formatDateOnly(startOfQuarter);
          endDate = _formatDateOnly(endOfQuarter);
          break;
      }

      final response = await ApiService.getAttendanceSummaryReport(
        startDate: startDate,
        endDate: endDate,
        period: _selectedPeriod,
      );

      if (response.success && mounted) {
        setState(() {
          _summaryData = response.data;
          _isLoading = false;
        });
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      throw Exception('Failed to load summary data: $e');
    }
  }

  Future<void> _loadBranchData() async {
    try {
      String? startDate;
      String? endDate;

      switch (_selectedPeriod) {
        case 'week':
          final startOfWeek = _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));
          final endOfWeek = startOfWeek.add(const Duration(days: 6));
          startDate = _formatDateOnly(startOfWeek);
          endDate = _formatDateOnly(endOfWeek);
          break;
        case 'month':
          final startOfMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);
          final endOfMonth = DateTime(_selectedDate.year, _selectedDate.month + 1, 0);
          startDate = _formatDateOnly(startOfMonth);
          endDate = _formatDateOnly(endOfMonth);
          break;
        case 'quarter':
          final quarter = ((_selectedDate.month - 1) / 3).floor();
          final startOfQuarter = DateTime(_selectedDate.year, quarter * 3 + 1, 1);
          final endOfQuarter = DateTime(_selectedDate.year, quarter * 3 + 4, 0);
          startDate = _formatDateOnly(startOfQuarter);
          endDate = _formatDateOnly(endOfQuarter);
          break;
      }

      final response = await ApiService.getBranchComparisonReport(
        startDate: startDate,
        endDate: endDate,
        period: _selectedPeriod,
      );

      if (response.success && mounted) {
        setState(() {
          _branchData = response.data;
        });
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      throw Exception('Failed to load branch data: $e');
    }
  }

  void _changePeriod(String period) {
    setState(() {
      _selectedPeriod = period;
    });
    _loadInitialData();
  }

  void _changeDate(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
    _loadInitialData();
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF272579).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: IntrinsicWidth(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(child: _buildPeriodButton('Week', 'week')),
            Flexible(child: _buildPeriodButton('Month', 'month')),
            Flexible(child: _buildPeriodButton('Quarter', 'quarter')),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodButton(String title, String value) {
    final isSelected = _selectedPeriod == value;

    return GestureDetector(
      onTap: () => _changePeriod(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF272579) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF272579),
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildDateNavigator() {
    String displayText;

    switch (_selectedPeriod) {
      case 'week':
        final startOfWeek = _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));
        final endOfWeek = startOfWeek.add(const Duration(days: 6));
        displayText = '${_getShortMonth(startOfWeek.month)} ${startOfWeek.day} - ${_getShortMonth(endOfWeek.month)} ${endOfWeek.day}, ${_selectedDate.year}';
        break;
      case 'month':
        displayText = '${_getFullMonth(_selectedDate.month)} ${_selectedDate.year}';
        break;
      case 'quarter':
        final quarter = ((_selectedDate.month - 1) / 3).floor() + 1;
        displayText = 'Q$quarter ${_selectedDate.year}';
        break;
      default:
        displayText = '${_selectedDate.year}';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF272579).withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: () {
              DateTime newDate;
              switch (_selectedPeriod) {
                case 'week':
                  newDate = _selectedDate.subtract(const Duration(days: 7));
                  break;
                case 'month':
                  newDate = DateTime(_selectedDate.year, _selectedDate.month - 1, 1);
                  break;
                case 'quarter':
                  newDate = DateTime(_selectedDate.year, _selectedDate.month - 3, 1);
                  break;
                default:
                  newDate = _selectedDate;
              }
              _changeDate(newDate);
            },
            icon: const Icon(Icons.chevron_left),
            iconSize: 20,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
          Expanded(
            child: Text(
              displayText,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF272579),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            onPressed: () {
              DateTime newDate;
              switch (_selectedPeriod) {
                case 'week':
                  newDate = _selectedDate.add(const Duration(days: 7));
                  break;
                case 'month':
                  newDate = DateTime(_selectedDate.year, _selectedDate.month + 1, 1);
                  break;
                case 'quarter':
                  newDate = DateTime(_selectedDate.year, _selectedDate.month + 3, 1);
                  break;
                default:
                  newDate = _selectedDate;
              }
              _changeDate(newDate);
            },
            icon: const Icon(Icons.chevron_right),
            iconSize: 20,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }

  String _getFullMonth(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  String _getShortMonth(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }

  Widget _buildSummaryTab() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF272579)),
      );
    }

    if (_error.isNotEmpty) {
      return _buildErrorWidget();
    }

    if (_summaryData == null) {
      return const Center(child: Text('No data available'));
    }

    final summary = _summaryData!['summary'] as Map<String, dynamic>;

    return SingleChildScrollView(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final padding = constraints.maxWidth < 400 ? 16.0 : 20.0;

          return Padding(
            padding: EdgeInsets.all(padding),
            child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Controls
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 400;

              if (isNarrow) {
                return Column(
                  children: [
                    _buildPeriodSelector(),
                    const SizedBox(height: 16),
                    _buildDateNavigator(),
                  ],
                );
              }

              return Row(
                children: [
                  Flexible(child: _buildPeriodSelector()),
                  const SizedBox(width: 16),
                  Flexible(child: _buildDateNavigator()),
                ],
              );
            },
          ),

          const SizedBox(height: 24),

          // Summary Cards
          _buildSummaryCards(summary),

          const SizedBox(height: 24),

          // Attendance Rate Chart
          _buildAttendanceRateChart(summary),

          const SizedBox(height: 24),

          // Top Performers
          if (_summaryData!['topPerformers'] != null)
            _buildTopPerformers(_summaryData!['topPerformers'] as List<dynamic>),
        ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
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
            onPressed: _loadInitialData,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF272579),
              foregroundColor: Colors.white,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(Map<String, dynamic> summary) {
    final totalDays = summary['totalDays'] ?? 0;
    final presentDays = summary['presentDays'] ?? 0;
    final absentDays = summary['absentDays'] ?? 0;
    final lateDays = summary['lateDays'] ?? 0;
    final totalHours = (summary['totalHours'] ?? 0.0).toDouble();
    final avgHours = (summary['avgHours'] ?? 0.0).toDouble();
    final attendanceRate = (summary['attendanceRate'] ?? 0.0).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Overview',
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
                'Attendance Rate',
                '${attendanceRate.toStringAsFixed(1)}%',
                const Color(0xFF5cfbd8),
                Icons.check_circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                'Present Days',
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
                'Absent Days',
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
                'Avg Hours/Day',
                '${avgHours.toStringAsFixed(1)}h',
                const Color(0xFF272579),
                Icons.trending_up,
              ),
            ),
          ],
        ),
      ],
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

  Widget _buildAttendanceRateChart(Map<String, dynamic> summary) {
    final presentDays = (summary['presentDays'] ?? 0).toDouble();
    final absentDays = (summary['absentDays'] ?? 0).toDouble();
    final lateDays = (summary['lateDays'] ?? 0).toDouble();
    final halfDays = (summary['halfDays'] ?? 0).toDouble();

    final totalDays = presentDays + absentDays + lateDays + halfDays;

    if (totalDays == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
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
          LayoutBuilder(
            builder: (context, constraints) {
              final chartHeight = constraints.maxWidth < 400 ? 180.0 : 200.0;
              final centerRadius = constraints.maxWidth < 400 ? 35.0 : 40.0;

              return SizedBox(
                height: chartHeight,
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
                centerSpaceRadius: centerRadius,
              ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          _buildChartLegend(),
        ],
      ),
    );
  }

  Widget _buildChartLegend() {
    return Wrap(
      spacing: 12,
      runSpacing: 6,
      alignment: WrapAlignment.center,
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

  Widget _buildTopPerformers(List<dynamic> topPerformers) {
    if (topPerformers.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
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
            'Top Performers',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF272579),
            ),
          ),
          const SizedBox(height: 16),
          ...topPerformers.take(5).map((performer) => _buildPerformerItem(performer)),
        ],
      ),
    );
  }

  Widget _buildPerformerItem(Map<String, dynamic> performer) {
    final name = performer['employeeName'] ?? 'Unknown';
    final employeeId = performer['employeeId'] ?? '';
    final attendanceRate = (performer['attendanceRate'] ?? 0.0).toDouble();
    final avgHours = (performer['avgHours'] ?? 0.0).toDouble();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
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
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF5cfbd8).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.person,
              color: const Color(0xFF5cfbd8),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF272579),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (employeeId.isNotEmpty)
                  Text(
                    employeeId,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${attendanceRate.toStringAsFixed(1)}%',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF5cfbd8),
                ),
              ),
              Text(
                '${avgHours.toStringAsFixed(1)}h avg',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBranchComparisonTab() {
    if (!AccessControlService.hasAccess(widget.userRole, 'attendance', 'view_all')) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock_outline,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'Access Denied',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'You don\'t have permission to view branch comparison reports.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF272579)),
      );
    }

    if (_error.isNotEmpty) {
      return _buildErrorWidget();
    }

    if (_branchData == null) {
      return const Center(child: Text('No branch data available'));
    }

    final branchComparison = _branchData!['branchComparison'] as List<dynamic>;

    return SingleChildScrollView(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final padding = constraints.maxWidth < 400 ? 16.0 : 20.0;

          return Padding(
            padding: EdgeInsets.all(padding),
            child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Controls
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 400;

              if (isNarrow) {
                return Column(
                  children: [
                    _buildPeriodSelector(),
                    const SizedBox(height: 16),
                    _buildDateNavigator(),
                  ],
                );
              }

              return Row(
                children: [
                  Flexible(child: _buildPeriodSelector()),
                  const SizedBox(width: 16),
                  Flexible(child: _buildDateNavigator()),
                ],
              );
            },
          ),

          const SizedBox(height: 24),

          // Branch Comparison Chart
          if (branchComparison.isNotEmpty)
            _buildBranchComparisonChart(branchComparison),

          const SizedBox(height: 24),

          // Branch Details
          if (branchComparison.isNotEmpty)
            _buildBranchDetailsList(branchComparison),
        ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBranchComparisonChart(List<dynamic> branchComparison) {
    return Container(
      padding: const EdgeInsets.all(20),
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
            'Branch Attendance Comparison',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF272579),
            ),
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final chartHeight = constraints.maxWidth < 400 ? 250.0 : 300.0;

              return SizedBox(
                height: chartHeight,
                child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 100,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    tooltipPadding: const EdgeInsets.all(8),
                    tooltipMargin: 8,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final branch = branchComparison[groupIndex];
                      return BarTooltipItem(
                        '${branch['branchName'] ?? 'Unknown'}\n${rod.toY.toStringAsFixed(1)}%',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() < branchComparison.length) {
                          final branch = branchComparison[value.toInt()];
                          final branchName = branch['branchName'] ?? 'Unknown';
                          String displayName = branchName;

                          // Better truncation logic for small screens
                          if (branchName.length > 10) {
                            displayName = '${branchName.substring(0, 8)}...';
                          }

                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              displayName,
                              style: const TextStyle(fontSize: 9),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}%',
                          style: const TextStyle(fontSize: 10),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                barGroups: branchComparison.asMap().entries.map((entry) {
                  final index = entry.key;
                  final branch = entry.value;
                  final attendanceRate = (branch['attendanceRate'] ?? 0.0).toDouble();

                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: attendanceRate,
                        color: const Color(0xFF0071bf),
                        width: 20,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                    ],
                  );
                }).toList(),
              ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBranchDetailsList(List<dynamic> branchComparison) {
    return Container(
      padding: const EdgeInsets.all(20),
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
            'Branch Details',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF272579),
            ),
          ),
          const SizedBox(height: 16),
          ...branchComparison.map((branch) => _buildBranchDetailItem(branch)),
        ],
      ),
    );
  }

  Widget _buildBranchDetailItem(Map<String, dynamic> branch) {
    final branchName = branch['branchName'] ?? 'Unknown Branch';
    final attendanceRate = (branch['attendanceRate'] ?? 0.0).toDouble();
    final totalDays = branch['totalDays'] ?? 0;
    final presentDays = branch['presentDays'] ?? 0;
    final employeeCount = branch['employeeCount'] ?? 0;
    final avgHours = (branch['avgHours'] ?? 0.0).toDouble();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
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
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFF0071bf).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.business,
              color: Color(0xFF0071bf),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  branchName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF272579),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '$employeeCount employees • $presentDays/$totalDays days',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${attendanceRate.toStringAsFixed(1)}%',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0071bf),
                ),
              ),
              Text(
                '${avgHours.toStringAsFixed(1)}h avg',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Tab> tabs = [
      const Tab(
        icon: Icon(Icons.dashboard, size: 20),
        text: 'Overview',
      ),
    ];

    if (AccessControlService.hasAccess(widget.userRole, 'reports', 'attendance_reports')) {
      tabs.add(
        const Tab(
          icon: Icon(Icons.analytics, size: 20),
          text: 'Analytics',
        ),
      );
    }

    if (AccessControlService.hasAccess(widget.userRole, 'attendance', 'view_all')) {
      tabs.add(
        const Tab(
          icon: Icon(Icons.compare, size: 20),
          text: 'Branches',
        ),
      );
    }

    if (AccessControlService.hasAccess(widget.userRole, 'reports', 'leaderboard_reports')) {
      tabs.add(
        const Tab(
          icon: Icon(Icons.leaderboard, size: 20),
          text: 'Leaderboards',
        ),
      );
    }

    List<Widget> tabViews = [
      _buildSummaryTab(),
    ];

    if (AccessControlService.hasAccess(widget.userRole, 'reports', 'attendance_reports')) {
      tabViews.add(_buildSummaryTab()); // For now, same content
    }

    if (AccessControlService.hasAccess(widget.userRole, 'attendance', 'view_all')) {
      tabViews.add(_buildBranchComparisonTab());
    }

    if (AccessControlService.hasAccess(widget.userRole, 'reports', 'leaderboard_reports')) {
      tabViews.add(_buildLeaderboardsTab());
    }

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
              child: const Icon(Icons.bar_chart, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Reports',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                  Text(
                    'Analytics & insights',
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
          tabs: tabs,
        ),
      ),
      backgroundColor: const Color(0xFFf8f9fa),
      body: TabBarView(
        controller: _tabController,
        children: tabViews,
      ),
    );
  }

  // Leaderboard tab builder
  Widget _buildLeaderboardsTab() {
    return Consumer<GamificationProvider>(
      builder: (context, gamificationProvider, child) {
        if (gamificationProvider.isLeaderboardLoading &&
            gamificationProvider.leaderboard.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0071bf)),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => gamificationProvider.refreshAll(),
          color: const Color(0xFF0071bf),
          child: gamificationProvider.leaderboard.isEmpty
              ? const SingleChildScrollView(
                  physics: AlwaysScrollableScrollPhysics(),
                  child: LeaderboardEmptyState(),
                )
              : CustomScrollView(
                  slivers: [
                    // Filter bar
                    SliverToBoxAdapter(
                      child: LeaderboardFilterBar(
                        selectedMetric: _selectedMetric,
                        onMetricChanged: (metric) {
                          setState(() => _selectedMetric = metric);
                          gamificationProvider.setLeaderboardFilters(metric: metric);
                        },
                        userRole: widget.userRole,
                      ),
                    ),

                    // Podium (top 3)
                    if (gamificationProvider.leaderboard.length >= 3)
                      SliverToBoxAdapter(
                        child: PodiumWidget(
                          first: gamificationProvider.leaderboard[0],
                          second: gamificationProvider.leaderboard[1],
                          third: gamificationProvider.leaderboard[2],
                          metric: _selectedMetric,
                        ),
                      ),

                    // My rank card (if user not in top 10)
                    if (_shouldShowMyRankCard(gamificationProvider))
                      SliverToBoxAdapter(
                        child: MyRankCard(
                          rank: _getMyRankForMetric(gamificationProvider),
                          total: _getTotalParticipants(gamificationProvider),
                          profile: gamificationProvider.quickProfile,
                          metric: _selectedMetric,
                        ),
                      ),

                    // Full leaderboard list
                    SliverPadding(
                      padding: EdgeInsets.all(CrmDesignSystem.lg),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final entry = gamificationProvider.leaderboard[index];
                            return LeaderboardItemWidget(
                              entry: entry,
                              isCurrentUser: widget.userId != null && entry.user.id == widget.userId,
                            );
                          },
                          childCount: gamificationProvider.leaderboard.length,
                        ),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  // Leaderboard helper methods
  void _loadLeaderboardData() {
    final provider = context.read<GamificationProvider>();
    provider.setLeaderboardFilters(metric: _selectedMetric);
  }

  int? _getLeaderboardsTabIndex() {
    if (!AccessControlService.hasAccess(widget.userRole, 'reports', 'leaderboard_reports')) {
      return null;
    }

    int index = 1; // After Overview

    if (AccessControlService.hasAccess(widget.userRole, 'reports', 'attendance_reports')) {
      index++;
    }

    if (AccessControlService.hasAccess(widget.userRole, 'attendance', 'view_all')) {
      index++;
    }

    return index;
  }

  bool _shouldShowMyRankCard(GamificationProvider provider) {
    if (provider.leaderboard.isEmpty || widget.userId == null) {
      return false;
    }

    // Check if user is in top 10
    final userInTop10 = provider.leaderboard.take(10).any(
      (entry) => entry.user.id == widget.userId,
    );

    // Show card if user is not in top 10
    return !userInTop10;
  }

  int? _getMyRankForMetric(GamificationProvider provider) {
    final rankings = provider.myRankings;
    if (rankings == null) return null;

    switch (_selectedMetric) {
      case 'sales_count':
        return rankings.salesCount.rank;
      case 'sales_amount':
        return rankings.salesAmount.rank;
      case 'activities_count':
        return rankings.activities.rank;
      case 'calls_count':
        // Note: calls_count ranking not available in current Rankings model
        // Would need to be added to backend if needed
        return null;
      default:
        return null;
    }
  }

  int _getTotalParticipants(GamificationProvider provider) {
    final rankings = provider.myRankings;
    if (rankings == null) return 0;

    // Use any ranking to get total participants (they should all be the same)
    return rankings.salesCount.totalParticipants;
  }
}
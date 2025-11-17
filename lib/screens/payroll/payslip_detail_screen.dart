import 'package:flutter/material.dart';
import '../../services/payroll_api_service.dart';

/// Screen to display detailed payslip information with breakdown
class PayslipDetailScreen extends StatefulWidget {
  final Map<String, dynamic> payslip;

  const PayslipDetailScreen({super.key, required this.payslip});

  @override
  State<PayslipDetailScreen> createState() => _PayslipDetailScreenState();
}

class _PayslipDetailScreenState extends State<PayslipDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _getMonthYearLabel() {
    final month = (widget.payslip['month'] as int?) ?? DateTime.now().month;
    final year = (widget.payslip['year'] as int?) ?? DateTime.now().year;
    return '${PayrollApiService.getMonthName(month)} $year';
  }

  @override
  Widget build(BuildContext context) {
    final monthYear = _getMonthYearLabel();
    // Handle both int and double types from API
    final netSalaryValue = widget.payslip['netSalary'];
    final netSalary = (netSalaryValue is int ? netSalaryValue.toDouble() : netSalaryValue as double?) ?? 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFFf8f9fa),
      appBar: AppBar(
        title: Text(
          'Payslip - $monthYear',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF272579), Color(0xFF0071bf)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF5cfbd8),
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          tabs: const [
            Tab(text: 'Earnings'),
            Tab(text: 'Deductions'),
            Tab(text: 'Summary'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Net salary header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0071bf), Color(0xFF00b8d9)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
            child: Column(
              children: [
                const Text(
                  'Net Salary',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  PayrollApiService.formatCurrency(netSalary),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildEarningsTab(),
                _buildDeductionsTab(),
                _buildSummaryTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEarningsTab() {
    final earnings = widget.payslip['earnings'] as Map<String, dynamic>? ?? {};

    // Get current (prorated) earnings - the actual amounts paid this month
    final currentEarnings = earnings['current'] as Map<String, dynamic>? ?? {};

    // Handle both int and double types from API
    final grossEarningsValue = widget.payslip['earnings']?['grossEarnings'];
    final grossEarnings = (grossEarningsValue is int ? grossEarningsValue.toDouble() : grossEarningsValue as double?) ?? 0.0;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionCard(
          title: 'Earnings Breakdown',
          icon: Icons.trending_up,
          children: [
            _buildAmountRow('Basic Salary', currentEarnings['basic']),
            _buildAmountRow('HRA', currentEarnings['hra']),
            _buildAmountRow('Dearness Allowance', currentEarnings['da']),
            _buildAmountRow('Conveyance', currentEarnings['conveyance']),
            _buildAmountRow('Special Allowance', currentEarnings['specialAllowance']),
            _buildAmountRow('Other Allowances', currentEarnings['otherAllowances']),
            if (earnings['bonus'] != null && earnings['bonus'] != 0)
              _buildAmountRow('Bonus', earnings['bonus']),
            if (earnings['incentive'] != null && earnings['incentive'] != 0)
              _buildAmountRow('Incentive', earnings['incentive']),
            if (earnings['overtimePay'] != null && earnings['overtimePay'] != 0)
              _buildAmountRow('Overtime Pay', earnings['overtimePay']),
            if (earnings['arrears'] != null && earnings['arrears'] != 0)
              _buildAmountRow('Arrears', earnings['arrears']),
            if (earnings['leaveEncashment'] != null && earnings['leaveEncashment'] != 0)
              _buildAmountRow('Leave Encashment', earnings['leaveEncashment']),
            const Divider(height: 24, thickness: 1),
            _buildAmountRow(
              'Gross Earnings',
              grossEarnings,
              isBold: true,
              color: const Color(0xFF0071bf),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildAttendanceCard(),
      ],
    );
  }

  Widget _buildDeductionsTab() {
    final deductions = widget.payslip['deductions'] as Map<String, dynamic>? ?? {};

    // Handle both int and double types from API
    final totalDeductionsValue = deductions['totalDeductions'] ?? widget.payslip['totalDeductions'];
    final totalDeductions = (totalDeductionsValue is int ? totalDeductionsValue.toDouble() : totalDeductionsValue as double?) ?? 0.0;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionCard(
          title: 'Deductions Breakdown',
          icon: Icons.trending_down,
          children: [
            _buildAmountRow('Provident Fund (PF)', deductions['pfEmployee']),
            _buildAmountRow('ESI (Employee)', deductions['esiEmployee']),
            _buildAmountRow('Professional Tax', deductions['professionalTax']),
            _buildAmountRow('Income Tax (TDS)', deductions['tds']),
            if (deductions['loanDeduction'] != null &&
                ((deductions['loanDeduction'] is int ? (deductions['loanDeduction'] as int).toDouble() : deductions['loanDeduction'] as double) > 0))
              _buildAmountRow('Loan Deduction', deductions['loanDeduction']),
            if (deductions['otherDeductions'] != null &&
                ((deductions['otherDeductions'] is int ? (deductions['otherDeductions'] as int).toDouble() : deductions['otherDeductions'] as double) > 0))
              _buildAmountRow('Other Deductions', deductions['otherDeductions']),
            const Divider(height: 24, thickness: 1),
            _buildAmountRow(
              'Total Deductions',
              totalDeductions,
              isBold: true,
              color: Colors.red,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryTab() {
    // Get earnings and deductions data from the payslip
    final earnings = widget.payslip['earnings'] as Map<String, dynamic>? ?? {};
    final deductions = widget.payslip['deductions'] as Map<String, dynamic>? ?? {};

    // Handle both int and double types from API
    final grossSalaryValue = earnings['grossEarnings'] ?? widget.payslip['grossSalary'];
    final grossSalary = (grossSalaryValue is int ? grossSalaryValue.toDouble() : grossSalaryValue as double?) ?? 0.0;

    final totalDeductionsValue = deductions['totalDeductions'] ?? widget.payslip['totalDeductions'];
    final totalDeductions = (totalDeductionsValue is int ? totalDeductionsValue.toDouble() : totalDeductionsValue as double?) ?? 0.0;

    final netSalaryValue = widget.payslip['netSalary'];
    final netSalary = (netSalaryValue is int ? netSalaryValue.toDouble() : netSalaryValue as double?) ?? 0.0;

    final workingDaysValue = widget.payslip['workingDaysInMonth'];
    final workingDays = workingDaysValue is int ? workingDaysValue : int.tryParse(workingDaysValue.toString()) ?? 0;

    final daysPresentValue = widget.payslip['daysPresent'];
    final daysPresent = (daysPresentValue is int ? daysPresentValue.toDouble() : daysPresentValue as double?) ?? 0.0;

    final daysAbsentValue = widget.payslip['daysAbsent'];
    final daysAbsent = (daysAbsentValue is int ? daysAbsentValue.toDouble() : daysAbsentValue as double?) ?? 0.0;

    final lopDaysValue = widget.payslip['lopDays'];
    final lopDays = (lopDaysValue is int ? lopDaysValue.toDouble() : lopDaysValue as double?) ?? 0.0;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionCard(
          title: 'Pay Summary',
          icon: Icons.account_balance_wallet,
          children: [
            _buildAmountRow('Gross Earnings', grossSalary),
            _buildAmountRow('Total Deductions', totalDeductions, isDeduction: true),
            const Divider(height: 24, thickness: 2),
            _buildAmountRow(
              'Net Payable',
              netSalary,
              isBold: true,
              fontSize: 18,
              color: const Color(0xFF0071bf),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildSectionCard(
          title: 'Attendance Summary',
          icon: Icons.calendar_today,
          children: [
            _buildInfoRow('Working Days', workingDays.toString()),
            _buildInfoRow('Days Present', daysPresent.toStringAsFixed(1)),
            _buildInfoRow('Days Absent', daysAbsent.toStringAsFixed(1)),
            if (lopDays > 0)
              _buildInfoRow(
                'LOP Days',
                lopDays.toStringAsFixed(1),
                valueColor: Colors.red,
              ),
          ],
        ),
        const SizedBox(height: 16),
        _buildEmployeeInfoCard(),
      ],
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
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
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: const Color(0xFF0071bf),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF272579),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildAmountRow(
    String label,
    dynamic amount, {
    bool isBold = false,
    bool isDeduction = false,
    Color? color,
    double fontSize = 14,
  }) {
    // Handle both int and double types from API, default to 0.0 if null or invalid
    final amountValue = (amount is int ? amount.toDouble() : (amount is double ? amount : 0.0));

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
              color: color ?? Colors.grey[800],
            ),
          ),
          Text(
            '${isDeduction ? '- ' : ''}${PayrollApiService.formatCurrency(amountValue)}',
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
              color: color ?? (isDeduction ? Colors.red : const Color(0xFF272579)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey[800],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: valueColor ?? const Color(0xFF272579),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceCard() {
    // Handle both int and double types from API
    final workingDaysValue = widget.payslip['workingDaysInMonth'];
    final workingDays = workingDaysValue is int ? workingDaysValue : int.tryParse(workingDaysValue.toString()) ?? 0;

    final daysPresentValue = widget.payslip['daysPresent'];
    final daysPresent = (daysPresentValue is int ? daysPresentValue.toDouble() : daysPresentValue as double?) ?? 0.0;

    final daysAbsentValue = widget.payslip['daysAbsent'];
    final daysAbsent = (daysAbsentValue is int ? daysAbsentValue.toDouble() : daysAbsentValue as double?) ?? 0.0;

    final lopDaysValue = widget.payslip['lopDays'];
    final lopDays = (lopDaysValue is int ? lopDaysValue.toDouble() : lopDaysValue as double?) ?? 0.0;

    if (lopDays == 0 && daysAbsent == 0) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 2,
      color: Colors.blue[50],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: const Color(0xFF0071bf).withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(
              Icons.info_outline,
              color: Color(0xFF0071bf),
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Attendance Adjustment',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF272579),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Salary adjusted for ${daysAbsent.toStringAsFixed(1)} days of absence\n(${daysPresent.toStringAsFixed(1)} days worked out of $workingDays working days)',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                    ),
                  ),
                  if (lopDays > 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      'LOP: ${lopDays.toStringAsFixed(1)} days',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmployeeInfoCard() {
    final employee = widget.payslip['employee'] as Map<String, dynamic>?;
    if (employee == null) return const SizedBox.shrink();

    return _buildSectionCard(
      title: 'Employee Details',
      icon: Icons.person,
      children: [
        _buildInfoRow('Name', employee['fullName'] ?? 'N/A'),
        _buildInfoRow('Employee ID', employee['employeeId'] ?? 'N/A'),
        _buildInfoRow('Designation', employee['designation'] ?? 'N/A'),
        _buildInfoRow('Department', employee['department'] ?? 'N/A'),
      ],
    );
  }
}

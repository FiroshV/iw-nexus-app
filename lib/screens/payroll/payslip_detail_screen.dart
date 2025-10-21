import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
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
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _getMonthYearLabel() {
    final month = widget.payslip['month'] as int;
    final year = widget.payslip['year'] as int;
    return '${PayrollApiService.getMonthName(month)} $year';
  }

  Future<void> _downloadPdf() async {
    final pdfUrl = widget.payslip['pdfUrl'] as String?;
    if (pdfUrl == null) {
      _showMessage('PDF not available', isError: true);
      return;
    }

    try {
      final url = Uri.parse(pdfUrl);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        _showMessage('Cannot open PDF URL', isError: true);
      }
    } catch (e) {
      _showMessage('Failed to download PDF: $e', isError: true);
    }
  }

  Future<void> _sharePdf() async {
    // TODO: Implement share functionality using share_plus package
    _showMessage('Share feature coming soon!');
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : const Color(0xFF0071bf),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final monthYear = _getMonthYearLabel();
    final netSalary = widget.payslip['netSalary'] as double? ?? 0.0;

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
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _sharePdf,
            tooltip: 'Share',
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _downloadPdf,
            tooltip: 'Download PDF',
          ),
        ],
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
            Tab(text: 'PDF'),
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
                _buildPdfTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEarningsTab() {
    final earnings = widget.payslip['earnings'] as Map<String, dynamic>? ?? {};
    final grossEarnings = widget.payslip['grossSalary'] as double? ?? 0.0;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionCard(
          title: 'Earnings Breakdown',
          icon: Icons.trending_up,
          children: [
            _buildAmountRow('Basic Salary', earnings['basic']),
            _buildAmountRow('HRA', earnings['hra']),
            _buildAmountRow('Dearness Allowance', earnings['da']),
            _buildAmountRow('Conveyance', earnings['conveyance']),
            _buildAmountRow('Special Allowance', earnings['specialAllowance']),
            _buildAmountRow('Other Allowances', earnings['otherAllowances']),
            if (earnings['bonus'] != null)
              _buildAmountRow('Bonus', earnings['bonus']),
            if (earnings['overtime'] != null)
              _buildAmountRow('Overtime', earnings['overtime']),
            const Divider(height: 24, thickness: 1),
            _buildAmountRow(
              'Gross Earnings',
              grossEarnings,
              isBold: true,
              color: const Color(0xFF5cfbd8),
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
    final totalDeductions = widget.payslip['totalDeductions'] as double? ?? 0.0;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionCard(
          title: 'Deductions Breakdown',
          icon: Icons.trending_down,
          children: [
            _buildAmountRow('Provident Fund (PF)', deductions['pfEmployee']),
            _buildAmountRow('ESI', deductions['esi']),
            _buildAmountRow('Professional Tax', deductions['professionalTax']),
            _buildAmountRow('Income Tax (TDS)', deductions['tds']),
            if (deductions['loanDeduction'] != null &&
                (deductions['loanDeduction'] as double) > 0)
              _buildAmountRow('Loan Deduction', deductions['loanDeduction']),
            if (deductions['otherDeductions'] != null &&
                (deductions['otherDeductions'] as double) > 0)
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
    final grossSalary = widget.payslip['grossSalary'] as double? ?? 0.0;
    final totalDeductions = widget.payslip['totalDeductions'] as double? ?? 0.0;
    final netSalary = widget.payslip['netSalary'] as double? ?? 0.0;
    final workingDays = widget.payslip['workingDaysInMonth'] as int? ?? 0;
    final daysPresent = widget.payslip['daysPresent'] as double? ?? 0.0;
    final daysAbsent = widget.payslip['daysAbsent'] as double? ?? 0.0;
    final lopDays = widget.payslip['lopDays'] as double? ?? 0.0;

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
              color: const Color(0xFF5cfbd8),
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

  Widget _buildPdfTab() {
    final pdfUrl = widget.payslip['pdfUrl'] as String?;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF0071bf).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.picture_as_pdf,
              size: 64,
              color: Color(0xFF0071bf),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Payslip PDF',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF272579),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              pdfUrl != null
                  ? 'Download or view your payslip PDF'
                  : 'PDF not yet generated',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
          const SizedBox(height: 24),
          if (pdfUrl != null) ...[
            ElevatedButton.icon(
              onPressed: _downloadPdf,
              icon: const Icon(Icons.download),
              label: const Text('Download PDF'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0071bf),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _sharePdf,
              icon: const Icon(Icons.share),
              label: const Text('Share PDF'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF0071bf),
                side: const BorderSide(color: Color(0xFF0071bf), width: 2),
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
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
    final amountValue = (amount is double) ? amount : 0.0;

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
    final workingDays = widget.payslip['workingDaysInMonth'] as int? ?? 0;
    final daysPresent = widget.payslip['daysPresent'] as double? ?? 0.0;
    final daysAbsent = widget.payslip['daysAbsent'] as double? ?? 0.0;
    final lopDays = widget.payslip['lopDays'] as double? ?? 0.0;

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

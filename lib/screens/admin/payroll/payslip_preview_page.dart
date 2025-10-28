import 'package:flutter/material.dart';
import '../../../services/payroll_api_service.dart';

/// Dedicated page for previewing payslip calculations before generation
/// Allows editing one-time earnings and working days adjustments
class PayslipPreviewPage extends StatefulWidget {
  final Map<String, dynamic> employee;
  final int month;
  final int year;
  final VoidCallback? onGenerateSuccess;

  const PayslipPreviewPage({
    Key? key,
    required this.employee,
    required this.month,
    required this.year,
    this.onGenerateSuccess,
  }) : super(key: key);

  @override
  State<PayslipPreviewPage> createState() => _PayslipPreviewPageState();
}

class _PayslipPreviewPageState extends State<PayslipPreviewPage> {
  late Map<String, dynamic> _preview;
  bool _isLoading = true;
  bool _isGenerating = false;
  String? _error;
  bool _isSalaryStructureMissing = false;

  // Override controllers
  late TextEditingController _bonusCtrl;
  late TextEditingController _incentiveCtrl;
  late TextEditingController _overtimeCtrl;
  late TextEditingController _arrearsCtrl;
  late TextEditingController _leaveEncashmentCtrl;
  late TextEditingController _daysWorkedCtrl;
  late TextEditingController _lopDaysCtrl;

  final List<String> _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadPreview();
  }

  void _initializeControllers() {
    _bonusCtrl = TextEditingController(text: '0');
    _incentiveCtrl = TextEditingController(text: '0');
    _overtimeCtrl = TextEditingController(text: '0');
    _arrearsCtrl = TextEditingController(text: '0');
    _leaveEncashmentCtrl = TextEditingController(text: '0');
    _daysWorkedCtrl = TextEditingController();
    _lopDaysCtrl = TextEditingController();
  }

  Future<void> _loadPreview() async {
    try {
      final preview = await PayrollApiService.calculatePayslipPreview(
        userId: widget.employee['_id'],
        month: widget.month,
        year: widget.year,
      );

      if (mounted) {
        setState(() {
          _preview = preview;
          _daysWorkedCtrl.text = _preview['payslipData']['daysPresent'].toString();
          _lopDaysCtrl.text = _preview['payslipData']['lopDays'].toString();
          _isLoading = false;
          _isSalaryStructureMissing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        final errorMessage = e.toString();
        final isMissingSalaryStructure = errorMessage.contains('404') ||
                                        errorMessage.contains('Salary structure not found');

        setState(() {
          _error = errorMessage;
          _isLoading = false;
          _isSalaryStructureMissing = isMissingSalaryStructure;
        });

        debugPrint('📌 Payslip preview error: $errorMessage');
        debugPrint('📌 Is salary structure missing: $isMissingSalaryStructure');
      }
    }
  }

  void _recalculatePreview() {
    if (mounted) {
      setState(() {
        _updateNetSalary();
      });
    }
  }

  void _updateNetSalary() {
    final payslipData = _preview['payslipData'] as Map<String, dynamic>;
    final earnings = payslipData['earnings'] as Map<String, dynamic>;
    final deductions = payslipData['deductions'] as Map<String, dynamic>;

    // Get working days in month and days worked
    final workingDaysInMonth = (payslipData['workingDaysInMonth'] as num?)?.toDouble() ?? 26;
    final daysWorked = double.tryParse(_daysWorkedCtrl.text) ?? workingDaysInMonth;

    // Calculate new proration factor based on days worked
    final prorationFactor = daysWorked / workingDaysInMonth;
    debugPrint('📊 Recalculating proration: $daysWorked / $workingDaysInMonth = ${prorationFactor.toStringAsFixed(4)}');

    // Update current earnings with new proration factor
    final masterEarnings = earnings['master'] as Map<String, dynamic>;
    final currentEarnings = earnings['current'] as Map<String, dynamic>;

    currentEarnings['basic'] = roundToTwoDecimals((masterEarnings['basic'] ?? 0) * prorationFactor);
    currentEarnings['hra'] = roundToTwoDecimals((masterEarnings['hra'] ?? 0) * prorationFactor);
    currentEarnings['da'] = roundToTwoDecimals((masterEarnings['da'] ?? 0) * prorationFactor);
    currentEarnings['conveyance'] = roundToTwoDecimals((masterEarnings['conveyance'] ?? 0) * prorationFactor);
    currentEarnings['specialAllowance'] = roundToTwoDecimals((masterEarnings['specialAllowance'] ?? 0) * prorationFactor);
    currentEarnings['otherAllowances'] = roundToTwoDecimals((masterEarnings['otherAllowances'] ?? 0) * prorationFactor);

    // Update one-time earnings
    earnings['bonus'] = double.tryParse(_bonusCtrl.text) ?? 0;
    earnings['incentive'] = double.tryParse(_incentiveCtrl.text) ?? 0;
    earnings['overtimePay'] = double.tryParse(_overtimeCtrl.text) ?? 0;
    earnings['arrears'] = double.tryParse(_arrearsCtrl.text) ?? 0;
    earnings['leaveEncashment'] = double.tryParse(_leaveEncashmentCtrl.text) ?? 0;

    // Recalculate gross with prorated earnings
    earnings['grossEarnings'] = roundToTwoDecimals(
      (currentEarnings['basic'] ?? 0) +
      (currentEarnings['hra'] ?? 0) +
      (currentEarnings['da'] ?? 0) +
      (currentEarnings['conveyance'] ?? 0) +
      (currentEarnings['specialAllowance'] ?? 0) +
      (currentEarnings['otherAllowances'] ?? 0) +
      (earnings['bonus'] ?? 0) +
      (earnings['incentive'] ?? 0) +
      (earnings['overtimePay'] ?? 0) +
      (earnings['arrears'] ?? 0) +
      (earnings['leaveEncashment'] ?? 0),
    );

    // Recalculate net
    final netSalary = roundToTwoDecimals(earnings['grossEarnings'] - (deductions['totalDeductions'] ?? 0));
    _preview['payslipData']['netSalary'] = netSalary;

    debugPrint('✅ Updated net salary: ₹${netSalary.toStringAsFixed(2)}');
  }

  /// Round to 2 decimal places for currency calculations
  double roundToTwoDecimals(num value) {
    return (value.toDouble() * 100).roundToDouble() / 100;
  }

  Future<void> _generatePayslip() async {
    _updateNetSalary();

    final overrides = {
      'bonus': double.tryParse(_bonusCtrl.text) ?? 0,
      'incentive': double.tryParse(_incentiveCtrl.text) ?? 0,
      'overtimePay': double.tryParse(_overtimeCtrl.text) ?? 0,
      'arrears': double.tryParse(_arrearsCtrl.text) ?? 0,
      'leaveEncashment': double.tryParse(_leaveEncashmentCtrl.text) ?? 0,
      'daysPresent': double.tryParse(_daysWorkedCtrl.text) ?? 0,
      'lopDays': double.tryParse(_lopDaysCtrl.text) ?? 0,
    };

    setState(() => _isGenerating = true);

    try {
      await PayrollApiService.generatePayslip({
        'userId': widget.employee['_id'],
        'month': widget.month,
        'year': widget.year,
        'overrides': overrides,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Payslip generated successfully!',
              style: TextStyle(color: Color(0xFF272579)),
            ),
            backgroundColor: Color(0xFF5cfbd8),
          ),
        );
        widget.onGenerateSuccess?.call();
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isGenerating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _bonusCtrl.dispose();
    _incentiveCtrl.dispose();
    _overtimeCtrl.dispose();
    _arrearsCtrl.dispose();
    _leaveEncashmentCtrl.dispose();
    _daysWorkedCtrl.dispose();
    _lopDaysCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFf8f9fa),
      appBar: AppBar(
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
        title: const Text(
          'Payslip Preview',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF0071bf)),
            )
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _isSalaryStructureMissing
                              ? const Color(0xFFFF9800).withOpacity(0.1)
                              : Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: Icon(
                            _isSalaryStructureMissing
                              ? Icons.person_add_outlined
                              : Icons.error_outline,
                            size: 48,
                            color: _isSalaryStructureMissing
                              ? const Color(0xFFFF9800)
                              : Colors.red[400],
                          ),
                        ),
                        const SizedBox(height: 24),
                        if (_isSalaryStructureMissing) ...[
                          const Text(
                            'Salary Structure Not Set Up',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF272579),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'To generate payslips, you need to set up a salary structure for this employee.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 24),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0071bf).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFF0071bf).withOpacity(0.3),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.info_outline,
                                      size: 20,
                                      color: Color(0xFF0071bf),
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'How to set up',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF0071bf),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  '1. Go to the Employees tab\n2. Search for "${widget.employee['firstName']} ${widget.employee['lastName']}"\n3. Click on the employee and select "Setup Salary"\n4. Enter the salary details and save',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[700],
                                    height: 1.6,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          const Text(
                            'Error Loading Payslip',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF272579),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(context),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF0071bf),
                                  side: const BorderSide(
                                    color: Color(0xFF0071bf),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                child: const Text('Go Back'),
                              ),
                            ),
                            if (_isSalaryStructureMissing) ...[
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    // Navigate to user management tab
                                    // This will be handled by parent widget
                                  },
                                  icon: const Icon(Icons.person_add_outlined),
                                  label: const Text('Set Up Salary'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF0071bf),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                )
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    final employee = _preview['employee'] as Map<String, dynamic>;
    final payslipData = _preview['payslipData'] as Map<String, dynamic>;
    final earnings = payslipData['earnings'] as Map<String, dynamic>;
    final deductions = payslipData['deductions'] as Map<String, dynamic>;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Employee Header Card
        _buildEmployeeHeaderCard(employee),
        const SizedBox(height: 20),

        // Working Days Section
        _buildSection(
          title: 'Working Days & Attendance',
          icon: Icons.calendar_today,
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildEditableField(
                    label: 'Working Days in Month',
                    value: (payslipData['workingDaysInMonth'] ?? 26).toString(),
                    readOnly: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildEditableField(
                    label: 'Days Worked',
                    controller: _daysWorkedCtrl,
                    onChanged: (_) => _recalculatePreview(),
                    prefix: '',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Attendance Breakdown',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF272579),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildAttendanceItem(
                          'Full Days',
                          (payslipData['fullDays'] ?? 0).toString(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildAttendanceItem(
                          'Half Days',
                          (payslipData['halfDays'] ?? 0).toString(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _buildEditableField(
              label: 'LOP (Loss of Pay) Days',
              controller: _lopDaysCtrl,
              onChanged: (_) => _recalculatePreview(),
              prefix: '',
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Earnings Section
        _buildSection(
          title: 'Earnings Breakdown (Monthly)',
          icon: Icons.trending_up,
          children: [
            _buildEarningsTable(earnings),
          ],
        ),
        const SizedBox(height: 20),

        // One-time Earnings Section
        _buildSection(
          title: 'One-time Earnings (Editable)',
          icon: Icons.card_giftcard,
          children: [
            _buildEditableField(
              label: 'Bonus',
              controller: _bonusCtrl,
              onChanged: (_) => _recalculatePreview(),
              prefix: '₹',
            ),
            const SizedBox(height: 12),
            _buildEditableField(
              label: 'Incentive',
              controller: _incentiveCtrl,
              onChanged: (_) => _recalculatePreview(),
              prefix: '₹',
            ),
            const SizedBox(height: 12),
            _buildEditableField(
              label: 'Overtime Pay',
              controller: _overtimeCtrl,
              onChanged: (_) => _recalculatePreview(),
              prefix: '₹',
            ),
            const SizedBox(height: 12),
            _buildEditableField(
              label: 'Arrears',
              controller: _arrearsCtrl,
              onChanged: (_) => _recalculatePreview(),
              prefix: '₹',
            ),
            const SizedBox(height: 12),
            _buildEditableField(
              label: 'Leave Encashment',
              controller: _leaveEncashmentCtrl,
              onChanged: (_) => _recalculatePreview(),
              prefix: '₹',
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Deductions Section
        _buildSection(
          title: 'Deductions',
          icon: Icons.trending_down,
          children: [
            _buildDeductionsTable(deductions),
          ],
        ),
        const SizedBox(height: 20),

        // Net Salary Summary
        _buildSection(
          title: 'Net Salary Summary',
          icon: Icons.account_balance_wallet,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0071bf), Color(0xFF00b8d9)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'NET SALARY PAYABLE',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    PayrollApiService.formatCurrency(
                      (payslipData['netSalary'] as num).toDouble(),
                    ),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Action Buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF0071bf),
                  side: const BorderSide(color: Color(0xFF0071bf)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isGenerating ? null : _generatePayslip,
                icon: _isGenerating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.check_circle),
                label: Text(_isGenerating ? 'Generating...' : 'Generate Payslip'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0071bf),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildEmployeeHeaderCard(Map<String, dynamic> employee) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF0071bf).withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            employee['fullName'] ?? 'Unknown',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF272579),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildEmployeeInfo('Employee ID', employee['employeeId'] ?? 'N/A'),
              ),
              Expanded(
                child: _buildEmployeeInfo('Designation', employee['designation'] ?? 'N/A'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildEmployeeInfo('PAN', employee['panNumber'] ?? 'N/A'),
              ),
              Expanded(
                child: _buildEmployeeInfo('PF A/C', employee['pfAccountNumber'] ?? 'N/A'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeeInfo(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF272579),
          ),
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF0071bf).withOpacity(0.2)),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF0071bf), size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF272579),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildEditableField({
    required String label,
    String? value,
    TextEditingController? controller,
    bool readOnly = false,
    String? prefix,
    Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Color(0xFF272579),
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          readOnly: readOnly,
          onChanged: onChanged,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            prefixText: prefix != null ? '$prefix ' : null,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFe0e0e0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF0071bf), width: 2),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFe0e0e0)),
            ),
            filled: readOnly,
            fillColor: readOnly ? Colors.grey[100] : null,
            hintText: value,
          ),
        ),
      ],
    );
  }

  Widget _buildEarningsTable(Map<String, dynamic> earnings) {
    return Column(
      children: [
        _buildTableHeader('Component', 'Monthly', 'After Proration'),
        _buildTableRow('Basic Salary', earnings['master']['basic'], earnings['current']['basic']),
        _buildTableRow('House Rent Allowance', earnings['master']['hra'], earnings['current']['hra']),
        _buildTableRow('Dearness Allowance', earnings['master']['da'], earnings['current']['da']),
        _buildTableRow('Conveyance', earnings['master']['conveyance'], earnings['current']['conveyance']),
        _buildTableRow('Special Allowance', earnings['master']['specialAllowance'], earnings['current']['specialAllowance']),
        _buildTableRow('Other Allowances', earnings['master']['otherAllowances'], earnings['current']['otherAllowances']),
        const Divider(height: 12),
        _buildTableRowBold('Gross Earnings', null, earnings['grossEarnings']),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF0071bf).withOpacity(0.05),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: const Color(0xFF0071bf).withOpacity(0.2),
            ),
          ),
          child: Text(
            '💡 Monthly: Base monthly salary. After Proration: Adjusted for actual days worked this month.',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[700],
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDeductionsTable(Map<String, dynamic> deductions) {
    // Helper function to safely convert to num
    num _toNum(dynamic value) {
      if (value == null) return 0;
      if (value is num) return value;
      if (value is String) return num.tryParse(value) ?? 0;
      return 0;
    }

    return Column(
      children: [
        _buildTableHeader('Component', null, 'Amount'),
        _buildTableRow('PF (Employee)', null, _toNum(deductions['pfEmployee'])),
        _buildTableRow('ESI (Employee)', null, _toNum(deductions['esiEmployee'])),
        _buildTableRow('Professional Tax', null, _toNum(deductions['professionalTax'])),
        _buildTableRow('Income Tax (TDS)', null, _toNum(deductions['tds'])),
        _buildTableRow('Loan Deduction', null, _toNum(deductions['loanDeduction'])),
        _buildTableRow('Other Deductions', null, _toNum(deductions['otherDeductions'])),
        const Divider(height: 12),
        _buildTableRowBold('Total Deductions', null, _toNum(deductions['totalDeductions'])),
      ],
    );
  }

  Widget _buildTableHeader(String col1, String? col2, String col3) {
    return Row(
      children: [
        Expanded(flex: 2, child: Text(col1, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
        if (col2 != null)
          Expanded(flex: 1, child: Text(col2, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.right)),
        Expanded(flex: 1, child: Text(col3, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.right)),
      ],
    );
  }

  Widget _buildTableRow(String label, dynamic value1, dynamic value2) {
    // Helper function to safely convert to num
    num _toNum(dynamic value) {
      if (value == null) return 0;
      if (value is num) return value;
      if (value is String) return num.tryParse(value) ?? 0;
      return 0;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(label, style: const TextStyle(fontSize: 12))),
          if (value1 != null)
            Expanded(
              flex: 1,
              child: Text(
                PayrollApiService.formatCurrency(_toNum(value1).toDouble()),
                style: const TextStyle(fontSize: 12),
                textAlign: TextAlign.right,
              ),
            ),
          Expanded(
            flex: 1,
            child: Text(
              PayrollApiService.formatCurrency(_toNum(value2).toDouble()),
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableRowBold(String label, dynamic value1, dynamic value2) {
    // Helper function to safely convert to num
    num _toNum(dynamic value) {
      if (value == null) return 0;
      if (value is num) return value;
      if (value is String) return num.tryParse(value) ?? 0;
      return 0;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF272579)),
            ),
          ),
          if (value1 != null)
            Expanded(
              flex: 1,
              child: Text(
                PayrollApiService.formatCurrency(_toNum(value1).toDouble()),
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                textAlign: TextAlign.right,
              ),
            ),
          Expanded(
            flex: 1,
            child: Text(
              PayrollApiService.formatCurrency(_toNum(value2).toDouble()),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0071bf)),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF0071bf).withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0071bf),
            ),
          ),
        ),
      ],
    );
  }
}

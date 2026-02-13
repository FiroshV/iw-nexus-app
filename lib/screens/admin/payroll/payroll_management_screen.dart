import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../services/payroll_api_service.dart';
import '../../../services/api_service.dart';
import '../../../services/access_control_service.dart';
import '../../../providers/auth_provider.dart';
import 'salary_structure_form_screen.dart';
import 'company_settings_screen.dart';
import 'payslip_generation_screen.dart';
import 'salary_templates_screen.dart';
import '../edit_user_screen.dart';
import '../../payroll/payslip_detail_screen.dart';

/// Unified Payroll Management Screen for Admin/Director
///
/// Provides tabbed interface for:
/// 1. Employee Salary Structure Management
/// 2. Payslip Generation
/// 3. Company Settings
class PayrollManagementScreen extends StatefulWidget {
  final int initialTab;

  const PayrollManagementScreen({
    super.key,
    this.initialTab = 0,
  });

  @override
  State<PayrollManagementScreen> createState() => _PayrollManagementScreenState();
}

class _PayrollManagementScreenState extends State<PayrollManagementScreen>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;
  List<Map<String, dynamic>> _employees = [];
  List<Map<String, dynamic>> _filteredEmployees = [];
  List<Map<String, dynamic>> _payslips = [];
  bool _isLoading = true;
  bool _payslipsLoading = true;
  String _searchQuery = '';
  String? _error;
  String? _payslipsError;
  late int _selectedViewMonth;
  late int _selectedViewYear;
  String _selectedViewEmployeeId = '';
  String _currentUserId = '';
  // ignore: unused_field
  String _currentUserRole = '';
  String _selectedViewEmployeeName = '';
  bool _hasInitializedUser = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedViewMonth = now.month;
    _selectedViewYear = now.year;
    _loadEmployees();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasInitializedUser) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      _currentUserId = authProvider.user?['_id'] as String? ?? '';
      _currentUserRole = authProvider.user?['role'] as String? ?? '';
      _hasInitializedUser = true;

      // Only pre-select self for non-admin/director users (they only see their own payslips)
      // Admin/director users see the employee selector and should start with all payslips
      final isPayrollManager = _currentUserRole == 'admin' || _currentUserRole == 'director';
      if (!isPayrollManager) {
        _selectedViewEmployeeId = _currentUserId;
        final firstName = authProvider.user?['firstName'] ?? '';
        final lastName = authProvider.user?['lastName'] ?? '';
        _selectedViewEmployeeName = '$firstName $lastName'.trim();
      }

      // Load payslips with the correct employee filter
      _loadPayslips();
    }
  }

  Future<void> _loadPayslips({String? employeeIdFilter}) async {
    try {
      setState(() {
        _payslipsLoading = true;
        _payslipsError = null;
      });

      final idToFilter = employeeIdFilter ?? _selectedViewEmployeeId;

      List<Map<String, dynamic>> payslips = [];

      if (idToFilter.isNotEmpty) {
        // Get payslips for specific employee by filtering the month/year results
        final allPayslips = await PayrollApiService.getPayslipsForMonth(
          month: _selectedViewMonth,
          year: _selectedViewYear,
        );
        // Filter by employeeId match
        payslips = allPayslips.where((p) {
          final empId = p['employeeId'];
          // Handle both object and string formats
          if (empId is Map) {
            return empId['_id'].toString() == idToFilter;
          } else {
            return empId.toString() == idToFilter;
          }
        }).toList();
      } else {
        // Get all payslips for the month/year
        payslips = await PayrollApiService.getPayslipsForMonth(
          month: _selectedViewMonth,
          year: _selectedViewYear,
        );
      }

      setState(() {
        _payslips = payslips;
        _payslipsLoading = false;
      });
    } catch (e) {
      setState(() {
        _payslipsError = e.toString();
        _payslipsLoading = false;
      });
      debugPrint('Error loading payslips: $e');
    }
  }

  void _initializeTabController(int tabCount) {
    // Dispose old controller if it exists
    _tabController?.dispose();

    _tabController = TabController(
      length: tabCount,
      vsync: this,
      initialIndex: widget.initialTab >= tabCount ? 0 : widget.initialTab,
    );
  }

  /// Load all salary structures from the dedicated collection
  /// Returns the list of structures instead of setting state directly
  Future<List<Map<String, dynamic>>> _loadSalaryStructures() async {
    try {
      final structures = await PayrollApiService.getSalaryStructures();
      debugPrint('📊 Loaded ${structures.length} salary structures');
      return structures;
    } catch (e) {
      debugPrint('❌ Error loading salary structures: $e');
      // Return empty list on error
      return [];
    }
  }

  Future<void> _loadEmployees() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Use the same API pattern as UserManagementScreen
      final response = await ApiService.getAllUsers();

      List<Map<String, dynamic>> users = [];

      // Handle different response formats
      if (response.success && response.data != null) {
        if (response.data is List) {
          users = List<Map<String, dynamic>>.from(response.data as List);
        } else if (response.data is Map<String, dynamic>) {
          final responseMap = response.data as Map<String, dynamic>;
          users = List<Map<String, dynamic>>.from(responseMap['data'] ?? []);
        }
      }

      debugPrint('📋 Loaded ${users.length} employees');

      // Load salary structures from dedicated collection
      final salaryStructures = await _loadSalaryStructures();
      debugPrint('💾 Retrieved ${salaryStructures.length} salary structures for matching');

      setState(() {
        // Filter out admin users
        final filteredUsers = users.where((user) => user['role'] != 'admin').toList();

        _employees = filteredUsers.map((user) {
          // Find matching salary structure from dedicated collection
          final matchingStructure = salaryStructures.firstWhere(
            (structure) {
              final structureUserId = structure['userId'] as String?;
              final userId = user['_id'] as String?;
              debugPrint('🔍 Checking: userId=$userId vs structure.userId=$structureUserId');
              return structureUserId == userId;
            },
            orElse: () => {},
          );

          final hasStructure = matchingStructure.isNotEmpty;
          if (hasStructure) {
            debugPrint('✅ Found structure for ${user['firstName']} ${user['lastName']}: CTC=${matchingStructure['ctc']}');
          } else {
            debugPrint('⚠️ No structure found for ${user['firstName']} ${user['lastName']}');
          }

          return {
            ...user,
            'salaryStructure': matchingStructure.isNotEmpty ? matchingStructure : null,
            'hasStructure': hasStructure,
          };
        }).toList();

        _filteredEmployees = _employees;

        final configuredCount = _employees.where((e) => e['hasStructure'] == true).length;
        final pendingCount = _employees.length - configuredCount;

        debugPrint(
          '👥 Summary: ${_employees.length} total employees | '
          '✅ Configured: $configuredCount | '
          '⏳ Pending: $pendingCount'
        );
        _isLoading = false;
      });
    } catch (e, stack) {
      debugPrint('❌ Error loading employees: $e');
      debugPrint('Stack trace: $stack');
      setState(() {
        _error = 'Failed to load employees: $e';
        _isLoading = false;
      });
    }
  }

  void _filterEmployees(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
      _filteredEmployees = _employees.where((employee) {
        final firstName = (employee['firstName'] ?? '').toLowerCase();
        final lastName = (employee['lastName'] ?? '').toLowerCase();
        final employeeId = (employee['employeeId'] ?? '').toLowerCase();
        final designation = (employee['designation'] ?? '').toLowerCase();

        return firstName.contains(_searchQuery) ||
            lastName.contains(_searchQuery) ||
            employeeId.contains(_searchQuery) ||
            designation.contains(_searchQuery);
      }).toList();
    });
  }

  /// Check if employee has complete statutory information for payslip generation
  Map<String, bool> _getStatutoryInfoStatus(Map<String, dynamic> employee) {
    return {
      'hasPAN': (employee['panNumber'] as String?)?.isNotEmpty ?? false,
      'hasPFAccount': (employee['pfAccountNumber'] as String?)?.isNotEmpty ?? false,
      'hasUAN': (employee['uanNumber'] as String?)?.isNotEmpty ?? false,
    };
  }

  /// Check if all required statutory fields are present
  bool _hasAllRequiredStatutoryInfo(Map<String, dynamic> employee) {
    final status = _getStatutoryInfoStatus(employee);
    return status['hasPAN']! && status['hasPFAccount']! && status['hasUAN']!;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        final userRole = authProvider.user?['role'] as String?;

        // Determine which tabs to show based on access control
        final canManagePayroll = AccessControlService.hasAccess(userRole, 'payroll', 'manage');
        final canViewOwn = AccessControlService.hasAccess(userRole, 'payroll', 'view_own');

        // If user doesn't have any payroll access, deny access
        if (!canViewOwn && !canManagePayroll) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Access Denied'),
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
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.lock_outline,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Access Denied',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You do not have access to Payroll Management',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0071bf),
                    ),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            ),
          );
        }

        // Build list of tabs based on user role
        final tabs = <Tab>[];
        final tabContents = <Widget>[];

        // Always add View Payslip tab for users with view_own access
        tabs.add(
          const Tab(
            icon: Icon(Icons.receipt_long, color: Colors.white),
            text: 'View',
          ),
        );
        tabContents.add(_buildViewPayslipTab(
          authProvider: authProvider,
          canManagePayroll: canManagePayroll,
        ));

        // Add management tabs only for users with manage access
        if (canManagePayroll) {
          tabs.addAll([
            const Tab(
              icon: Icon(Icons.people, color: Colors.white),
              text: 'Employees',
            ),
            const Tab(
              icon: Icon(Icons.receipt_long, color: Colors.white),
              text: 'Generate',
            ),
            const Tab(
              icon: Icon(Icons.settings, color: Colors.white),
              text: 'Settings',
            ),
          ]);
          tabContents.addAll([
            _buildEmployeeListTab(),
            const PayslipGenerationContent(),
            _buildSettingsTab(),
          ]);
        }

        // Initialize tab controller if not already done or if tab count changed
        if (_tabController == null || _tabController!.length != tabs.length) {
          _initializeTabController(tabs.length);
        }

        return Scaffold(
          backgroundColor: const Color(0xFFf8f9fa),
          appBar: AppBar(
            title: const Text(
              'Payslip',
              style: TextStyle(fontWeight: FontWeight.w700),
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
            bottom: _tabController != null
                ? TabBar(
                    controller: _tabController!,
                    indicatorColor: Colors.white,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white,
                    tabs: tabs,
                  )
                : null,
          ),
          body: _tabController != null
              ? TabBarView(
                  controller: _tabController!,
                  children: tabContents,
                )
              : const SizedBox.shrink(),
        );
      },
    );
  }

  /// Safely parse a value to int, handling int, double, num, and String types
  int? _parseIntSafe(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  String _getMonthYearLabel(Map<String, dynamic> payslip) {
    final month = _parseIntSafe(payslip['month']) ?? _selectedViewMonth;
    final year = _parseIntSafe(payslip['year']) ?? _selectedViewYear;
    return '${PayrollApiService.getMonthName(month)} $year';
  }

  Widget _buildPayslipCard(Map<String, dynamic> payslip) {
    final monthYear = _getMonthYearLabel(payslip);
    // Handle both int and double types from API
    final netSalaryValue = payslip['netSalary'];
    final netSalary = (netSalaryValue is int ? netSalaryValue.toDouble() : netSalaryValue as double?) ?? 0.0;
    final status = (payslip['paymentStatus'] as String?) ?? (payslip['status'] as String?) ?? 'pending';
    final daysPresentValue = payslip['daysPresent'];
    final daysPresent = (daysPresentValue is int ? daysPresentValue.toDouble() : daysPresentValue as double?) ?? 0.0;
    final workingDaysValue = payslip['workingDaysInMonth'];
    final workingDays = workingDaysValue is int ? workingDaysValue : int.tryParse(workingDaysValue.toString()) ?? 0;
    // Extract employee name from populated employeeId object
    final empData = payslip['employeeId'];
    final employeeName = empData is Map
        ? '${empData['firstName'] ?? ''} ${empData['lastName'] ?? ''}'.trim()
        : '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PayslipDetailScreen(payslip: payslip),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0071bf).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.receipt_long,
                      color: Color(0xFF0071bf),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          monthYear,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF272579),
                          ),
                        ),
                        if (employeeName.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            employeeName,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusColor(status).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: _getStatusColor(status).withValues(alpha: 0.3),
                                ),
                              ),
                              child: Text(
                                status.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: _getStatusColor(status),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        PayrollApiService.formatCurrency(netSalary),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0071bf),
                        ),
                      ),
                      const Text(
                        'Net Salary',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem(
                      icon: Icons.calendar_today,
                      label: 'Days Present',
                      value: '${daysPresent.toStringAsFixed(1)}/$workingDays',
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 30,
                    color: Colors.grey[300],
                  ),
                  Expanded(
                    child: _buildInfoItem(
                      icon: Icons.download,
                      label: 'Download',
                      value: 'PDF',
                      isAction: true,
                      onTap: () => _downloadPayslip(payslip),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
    bool isAction = false,
    VoidCallback? onTap,
  }) {
    final content = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: 14,
          color: isAction ? const Color(0xFF0071bf) : Colors.grey[600],
        ),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isAction ? const Color(0xFF0071bf) : const Color(0xFF272579),
              ),
            ),
          ],
        ),
      ],
    );

    if (isAction && onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: content,
        ),
      );
    }

    return content;
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return const Color(0xFF5cfbd8);
      case 'generated':
        return const Color(0xFF00b8d9);
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Future<void> _downloadPayslip(Map<String, dynamic> payslip) async {
    try {
      final pdfUrl = payslip['pdfUrl'] as String?;
      if (pdfUrl == null) {
        _showMessage('PDF not available for this payslip', isError: true);
        return;
      }

      final url = Uri.parse(pdfUrl);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
        _showMessage('Opening payslip PDF...');
      } else {
        _showMessage('Cannot open PDF URL', isError: true);
      }
    } catch (e) {
      _showMessage('Failed to download payslip: $e', isError: true);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : const Color(0xFF0071bf),
        duration: Duration(seconds: isError ? 3 : 2),
      ),
    );
  }

  /// Build employee list for payslip selection (current user at top, then others)
  List<Map<String, dynamic>> _buildAllEmpList(AuthProvider authProvider) {
    final currentUserRole = authProvider.user?['role'] as String?;
    return [
      if (currentUserRole != 'admin')
        {
          '_id': _currentUserId,
          'firstName': authProvider.user?['firstName'] ?? '',
          'lastName': authProvider.user?['lastName'] ?? '',
          'isCurrentUser': true,
        },
      ..._employees.where((e) => e['_id'] != _currentUserId),
    ];
  }

  void _showEmployeeBottomSheet(AuthProvider authProvider) {
    final allEmployees = _buildAllEmpList(authProvider);
    List<Map<String, dynamic>> filteredEmployees = List.from(allEmployees);
    final searchController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Select Employee',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF272579),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
                // Search field
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: TextField(
                    controller: searchController,
                    onChanged: (query) {
                      setModalState(() {
                        if (query.isEmpty) {
                          filteredEmployees = List.from(allEmployees);
                        } else {
                          final lowerQuery = query.toLowerCase();
                          filteredEmployees = allEmployees.where((emp) {
                            final name =
                                '${emp['firstName']} ${emp['lastName']}'
                                    .toLowerCase();
                            return name.contains(lowerQuery);
                          }).toList();
                        }
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search by name...',
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Color(0xFF0071bf),
                      ),
                      suffixIcon: searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                searchController.clear();
                                setModalState(() {
                                  filteredEmployees = List.from(allEmployees);
                                });
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFfbf8ff),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                // Employee list
                Expanded(
                  child: ListView.separated(
                    controller: scrollController,
                    itemCount: filteredEmployees.length + 1, // +1 for "All Employees"
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      // First item: "All Employees" option
                      if (index == 0) {
                        final isSelected = _selectedViewEmployeeId.isEmpty;
                        return ListTile(
                          onTap: () {
                            setState(() {
                              _selectedViewEmployeeId = '';
                              _selectedViewEmployeeName = '';
                            });
                            Navigator.pop(context);
                            _loadPayslips();
                          },
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color(0xFF0071bf)
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(
                              Icons.people,
                              color: Color(0xFF0071bf),
                              size: 20,
                            ),
                          ),
                          title: const Text(
                            'All Employees',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          trailing: isSelected
                              ? const Icon(
                                  Icons.check_circle,
                                  color: Color(0xFF0071bf),
                                )
                              : null,
                          selected: isSelected,
                          selectedTileColor:
                              const Color(0xFF0071bf).withValues(alpha: 0.1),
                        );
                      }

                      final emp = filteredEmployees[index - 1];
                      final empId = emp['_id'] as String;
                      final displayName =
                          '${emp['firstName']} ${emp['lastName']}';
                      final isCurrent = empId == _currentUserId;
                      final isSelected = _selectedViewEmployeeId == empId;

                      return ListTile(
                        onTap: () {
                          setState(() {
                            _selectedViewEmployeeId = empId;
                            _selectedViewEmployeeName = displayName;
                          });
                          Navigator.pop(context);
                          _loadPayslips();
                        },
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFF0071bf)
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Center(
                            child: Text(
                              (emp['firstName'] as String? ?? '')
                                  .isNotEmpty
                                  ? (emp['firstName'] as String)
                                      .substring(0, 1)
                                      .toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                color: Color(0xFF0071bf),
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                        title: Text(
                          isCurrent ? '$displayName (You)' : displayName,
                          style: TextStyle(
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.normal,
                            color: isSelected
                                ? const Color(0xFF0071bf)
                                : Colors.grey[800],
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(
                                Icons.check_circle,
                                color: Color(0xFF0071bf),
                              )
                            : null,
                        selected: isSelected,
                        selectedTileColor:
                            const Color(0xFF0071bf).withValues(alpha: 0.1),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showMonthBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Select Month',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF272579),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: 12,
              itemBuilder: (context, index) {
                final month = index + 1;
                final isSelected = _selectedViewMonth == month;
                return ListTile(
                  onTap: () {
                    setState(() => _selectedViewMonth = month);
                    Navigator.pop(context);
                    _loadPayslips();
                  },
                  title: Text(
                    PayrollApiService.getMonthName(month),
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected
                          ? const Color(0xFF0071bf)
                          : Colors.grey[800],
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(
                          Icons.check_circle,
                          color: Color(0xFF0071bf),
                        )
                      : null,
                  selected: isSelected,
                  selectedTileColor:
                      const Color(0xFF0071bf).withValues(alpha: 0.1),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showYearBottomSheet() {
    final currentYear = DateTime.now().year;
    final years = List.generate(5, (index) => currentYear - 2 + index);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Select Year',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF272579),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...years.map((year) {
            final isSelected = _selectedViewYear == year;
            return ListTile(
              onTap: () {
                setState(() => _selectedViewYear = year);
                Navigator.pop(context);
                _loadPayslips();
              },
              title: Text(
                year.toString(),
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected
                      ? const Color(0xFF0071bf)
                      : Colors.grey[800],
                ),
              ),
              trailing: isSelected
                  ? const Icon(
                      Icons.check_circle,
                      color: Color(0xFF0071bf),
                    )
                  : null,
              selected: isSelected,
              selectedTileColor:
                  const Color(0xFF0071bf).withValues(alpha: 0.1),
            );
          }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildViewPayslipTab({
    required AuthProvider authProvider,
    required bool canManagePayroll,
  }) {
    // Compute latest payslip label from actual data
    String latestPayslipLabel = '';
    if (_payslips.isNotEmpty) {
      int latestYear = 0;
      int latestMonth = 0;
      for (final p in _payslips) {
        final pYear = _parseIntSafe(p['year']) ?? 0;
        final pMonth = _parseIntSafe(p['month']) ?? 0;
        if (pYear > latestYear || (pYear == latestYear && pMonth > latestMonth)) {
          latestYear = pYear;
          latestMonth = pMonth;
        }
      }
      if (latestMonth > 0 && latestYear > 0) {
        latestPayslipLabel =
            '${PayrollApiService.getMonthShortName(latestMonth)} $latestYear';
      }
    }

    // Build employee selector widget (only for admin/director)
    final employeeSelector = canManagePayroll
        ? GestureDetector(
            onTap: () => _showEmployeeBottomSheet(authProvider),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFe0e0e0)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _selectedViewEmployeeName.isNotEmpty
                          ? _selectedViewEmployeeName
                          : 'All Employees',
                      style: TextStyle(
                        fontSize: 14,
                        color: _selectedViewEmployeeName.isNotEmpty
                            ? Colors.grey[800]
                            : Colors.grey[600],
                      ),
                    ),
                  ),
                  const Icon(Icons.search, color: Color(0xFF0071bf)),
                ],
              ),
            ),
          )
        : const SizedBox.shrink();

    // Build period selector widget
    final periodSelector = Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: _showMonthBottomSheet,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFe0e0e0)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Month',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          PayrollApiService.getMonthName(_selectedViewMonth),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_drop_down,
                    color: Colors.grey[600],
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: _showYearBottomSheet,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFe0e0e0)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Year',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _selectedViewYear.toString(),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_drop_down,
                    color: Colors.grey[600],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );

    if (_payslipsLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              color: Color(0xFF0071bf),
            ),
          ],
        ),
      );
    }

    if (_payslipsError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading payslips',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _payslipsError!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadPayslips,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0071bf),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Always show period selector in a list view
    return RefreshIndicator(
      onRefresh: _loadPayslips,
      color: const Color(0xFF0071bf),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Employee selector - Only visible for admin/director
          if (canManagePayroll) ...[
            employeeSelector,
            const SizedBox(height: 16),
          ],
          // Period filter - Always visible
          periodSelector,
          const SizedBox(height: 16),

          // Show info banner and payslips only if payslips exist
          if (_payslips.isNotEmpty) ...[
            // Info banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0071bf), Color(0xFF00b8d9)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Latest Payslip',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          latestPayslipLabel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Payslips list
            ..._payslips.map((payslip) => _buildPayslipCard(payslip)),
          ] else ...[
            // Show empty state with period selector still visible
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 48),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0071bf).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.receipt_long_outlined,
                      size: 64,
                      color: Color(0xFF0071bf),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'No Payslips Yet',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF272579),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Payslips for ${PayrollApiService.getMonthName(_selectedViewMonth)} $_selectedViewYear will appear here once generated',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Manage Salary Templates Card
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF0071bf).withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0071bf).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.assignment_rounded,
                          color: Color(0xFF0071bf),
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Salary Templates',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF272579),
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Create and manage salary percentage templates',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SalaryTemplatesScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.arrow_forward, size: 18),
                      label: const Text('Manage Templates'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0071bf),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Company Settings Card
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF0071bf).withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0071bf).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.settings_rounded,
                          color: Color(0xFF0071bf),
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Company Settings',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF272579),
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Configure company details and statutory information',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CompanySettingsScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.arrow_forward, size: 18),
                      label: const Text('Configure Settings'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0071bf),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeeListTab() {
    return RefreshIndicator(
      onRefresh: _loadEmployees,
      color: const Color(0xFF0071bf),
      child: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF0071bf)),
            )
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red[300],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Error Loading Employees',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _loadEmployees,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0071bf),
                          ),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Search bar
                    TextField(
                      onChanged: _filterEmployees,
                      decoration: InputDecoration(
                        hintText: 'Search by name, ID, or designation...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              const BorderSide(color: Color(0xFFe0e0e0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              const BorderSide(color: Color(0xFFe0e0e0)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFF0071bf),
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Summary card
                    _buildSummaryCard(),
                    const SizedBox(height: 16),

                    // Employee list
                    if (_filteredEmployees.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            children: [
                              Icon(
                                Icons.person_search,
                                size: 64,
                                color: Colors.grey[300],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _searchQuery.isEmpty
                                    ? 'No employees found'
                                    : 'No results for "$_searchQuery"',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ..._filteredEmployees
                          .map((employee) => _buildEmployeeCard(employee)),
                  ],
                ),
    );
  }

  Widget _buildSummaryCard() {
    final total = _employees.length;
    final configured =
        _employees.where((e) => e['hasStructure'] == true).length;
    final pending = total - configured;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF272579), Color(0xFF0071bf)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem('Total', total.toString(), Icons.people),
            _buildStatItem('Configured', configured.toString(),
                Icons.check_circle),
            _buildStatItem('Pending', pending.toString(), Icons.warning),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildEmployeeCard(Map<String, dynamic> employee) {
    final hasStructure = employee['hasStructure'] ?? false;
    final structure = employee['salaryStructure'];
    final firstName = employee['firstName'] ?? '';
    final lastName = employee['lastName'] ?? '';
    final initial = firstName.isNotEmpty ? firstName[0].toUpperCase() : 'E';
    final hasAllStatutoryInfo = _hasAllRequiredStatutoryInfo(employee);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Avatar with user profile image
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: employee['avatar'] != null
                        ? null
                        : const LinearGradient(
                            colors: [Color(0xFF272579), Color(0xFF0071bf)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: employee['avatar'] != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            employee['avatar'],
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Color(0xFF272579), Color(0xFF0071bf)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    initial,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        )
                      : Center(
                          child: Text(
                            initial,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                ),
                const SizedBox(width: 12),

                // Employee Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$firstName $lastName',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${employee['employeeId']} • ${employee['designation'] ?? 'N/A'}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (hasStructure)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF5cfbd8).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'CTC: ${PayrollApiService.formatCurrency(structure['ctc'] / 12)}/mo',
                            style: const TextStyle(
                              color: Color(0xFF272579),
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Action Menu Button
                PopupMenuButton(
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0071bf).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.more_vert_rounded,
                      color: Color(0xFF0071bf),
                      size: 18,
                    ),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  itemBuilder: (context) {
                    final menuItems = <PopupMenuEntry<String>>[];

                    // Salary Structure action
                    menuItems.add(
                      PopupMenuItem(
                        value: 'salary',
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              hasStructure ? Icons.edit_rounded : Icons.add_circle_rounded,
                              size: 16,
                              color: const Color(0xFF0071bf),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              hasStructure ? 'Edit Salary Structure' : 'Add Salary Structure',
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    );

                    // Edit Profile action (only if statutory info is missing)
                    if (!hasAllStatutoryInfo) {
                      menuItems.add(
                        PopupMenuItem(
                          value: 'profile',
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.person_outline_rounded,
                                size: 16,
                                color: Colors.orange[700],
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Edit Profile Info',
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return menuItems;
                  },
                  onSelected: (value) async {
                    switch (value) {
                      case 'salary':
                        final result = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SalaryStructureFormScreen(
                              salaryStructure: structure,
                              userId: employee['_id'],
                              userName: '$firstName $lastName',
                            ),
                          ),
                        );
                        if (result == true) {
                          _loadEmployees();
                        }
                        break;
                      case 'profile':
                        final result = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditUserScreen(user: employee),
                          ),
                        );
                        if (result == true) {
                          _loadEmployees();
                        }
                        break;
                    }
                  },
                ),
              ],
            ),

            // Warning Count (Only show if there are issues)
            Builder(
              builder: (context) {
                // Calculate total issues
                int issueCount = 0;
                if (!hasStructure) issueCount++;
                if (!hasAllStatutoryInfo) issueCount++;

                if (issueCount == 0) {
                  return const SizedBox.shrink();
                }

                return Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_rounded,
                        size: 16,
                        color: Colors.orange[600],
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '$issueCount issue${issueCount > 1 ? 's' : ''} to resolve',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.orange[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }
}

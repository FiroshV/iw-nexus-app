import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/payroll_api_service.dart';
import '../../../services/api_service.dart';
import '../../../providers/auth_provider.dart';
import 'salary_structure_form_screen.dart';
import 'company_settings_screen.dart';
import 'payslip_generation_screen.dart';
import '../edit_user_screen.dart';

/// Unified Payroll Management Screen for Admin/Director
///
/// Provides tabbed interface for:
/// 1. Employee Salary Structure Management
/// 2. Payslip Generation
/// 3. Company Settings
class PayrollManagementScreen extends StatefulWidget {
  final int initialTab;

  const PayrollManagementScreen({
    Key? key,
    this.initialTab = 0,
  }) : super(key: key);

  @override
  State<PayrollManagementScreen> createState() => _PayrollManagementScreenState();
}

class _PayrollManagementScreenState extends State<PayrollManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _employees = [];
  List<Map<String, dynamic>> _filteredEmployees = [];
  List<Map<String, dynamic>> _salaryStructures = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String? _error;
  bool _isCompanySettingsConfigured = false;
  bool _checkingSettings = false;
  Map<String, dynamic>? _companySettings;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTab,
    );
    _loadEmployees();
    _checkCompanySettings();
  }

  Future<void> _checkCompanySettings() async {
    try {
      setState(() => _checkingSettings = true);
      final settings = await PayrollApiService.getCompanySettings();

      debugPrint('🔍 Company Settings Response: $settings');

      // Check if all required settings are present
      final isConfigured = settings['companyName'] != null &&
          settings['companyName'].toString().isNotEmpty &&
          settings['companyAddress'] != null &&
          settings['pan'] != null &&
          settings['pan'].toString().isNotEmpty &&
          settings['tan'] != null &&
          settings['tan'].toString().isNotEmpty;

      debugPrint('✅ Company Settings Configured: $isConfigured');

      if (mounted) {
        setState(() {
          _companySettings = settings;
          _isCompanySettingsConfigured = isConfigured;
          _checkingSettings = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error checking company settings: $e');
      if (mounted) {
        setState(() => _checkingSettings = false);
      }
    }
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
        // Store salary structures for later use (e.g., in refresh)
        _salaryStructures = salaryStructures;

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

        // Check access control - only admin and director can access this screen
        if (userRole != 'admin' && userRole != 'director') {
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
                    'Only Admin and Director can access Payroll Management',
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

        return Scaffold(
          backgroundColor: const Color(0xFFf8f9fa),
          appBar: AppBar(
            title: const Text(
              'Payroll Management',
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
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white,
              tabs: const [
                Tab(
                  icon: Icon(Icons.people, color: Colors.white),
                  text: 'Employees',
                ),
                Tab(
                  icon: Icon(Icons.receipt_long, color: Colors.white),
                  text: 'Generate',
                ),
                Tab(
                  icon: Icon(Icons.settings, color: Colors.white),
                  text: 'Settings',
                ),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildEmployeeListTab(),
              const PayslipGenerationContent(),
              CompanySettingsContent(
                initialSettings: _companySettings,
                onSuccess: () {
                  // Refresh settings and switch to Employees tab (index 0)
                  _checkCompanySettings();
                  _tabController.animateTo(0);
                },
              ),
            ],
          ),
        );
      },
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

                    // Company Settings Status Card
                    _buildCompanySettingsStatusCard(),
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

  Widget _buildCompanySettingsStatusCard() {
    if (_checkingSettings) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            height: 60,
            child: Center(
              child: CircularProgressIndicator(
                color: Colors.grey[400],
              ),
            ),
          ),
        ),
      );
    }

    // Hide success card when settings are configured
    if (_isCompanySettingsConfigured) {
      return SizedBox.shrink();
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          color: _isCompanySettingsConfigured
              ? const Color(0xFF5cfbd8).withValues(alpha: 0.15)
              : Colors.orange.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isCompanySettingsConfigured
                ? const Color(0xFF5cfbd8)
                : Colors.orange,
            width: 2,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            if (_isCompanySettingsConfigured)
              const Icon(
                Icons.check_circle,
                color: Color(0xFF5cfbd8),
                size: 40,
              )
            else
              Icon(
                Icons.warning_rounded,
                color: Colors.orange[700],
                size: 40,
              ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isCompanySettingsConfigured
                        ? 'Company Settings Live'
                        : 'Company Settings Required',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF272579),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _isCompanySettingsConfigured
                        ? 'All settings are configured'
                        : 'Configure company details to generate payslips',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            if (!_isCompanySettingsConfigured)
              ElevatedButton.icon(
                onPressed: () {
                  _tabController.animateTo(2); // Settings tab is index 2
                },
                icon: const Icon(Icons.arrow_forward, size: 18),
                label: const Text('Setup'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
              ),
          ],
        ),
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
                            color: const Color(0xFF5cfbd8).withOpacity(0.2),
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
    _tabController.dispose();
    super.dispose();
  }
}

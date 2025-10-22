import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../widgets/loading_widget.dart';

class SendAppointmentLetterScreen extends StatefulWidget {
  const SendAppointmentLetterScreen({super.key});

  @override
  State<SendAppointmentLetterScreen> createState() =>
      _SendAppointmentLetterScreenState();
}

class _SendAppointmentLetterScreenState
    extends State<SendAppointmentLetterScreen>
    with SingleTickerProviderStateMixin {
  // Employee data
  List<Map<String, dynamic>> allEmployees = [];

  // Mode toggle
  bool isRegisteredMode = false; // Manual entry is now the default

  // Registered mode
  Map<String, dynamic>? selectedEmployee;
  final TextEditingController _registeredSearchController =
      TextEditingController();

  // Manual entry mode
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _designationController = TextEditingController();
  final TextEditingController _employeeIdController = TextEditingController();
  final TextEditingController _dateOfJoiningController =
      TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _branchNameController = TextEditingController();
  final TextEditingController _salaryController = TextEditingController();

  // State
  bool isLoadingEmployees = true;
  bool isSending = false;
  String? error;
  bool isLoadingBranches = false;
  List<Map<String, dynamic>> branches = [];
  String? selectedBranchId;

  // Animation
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _loadAllEmployees();
    _loadBranches();

    // Setup fade animation
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _registeredSearchController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _designationController.dispose();
    _employeeIdController.dispose();
    _dateOfJoiningController.dispose();
    _addressController.dispose();
    _phoneNumberController.dispose();
    _branchNameController.dispose();
    _salaryController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadAllEmployees() async {
    try {
      final response = await ApiService.getAllUsers(
        page: 1,
        limit: 100,
      );

      if (response.success && response.data != null) {
        List<Map<String, dynamic>> allEmployeesTemp;

        if (response.data is List) {
          allEmployeesTemp = List<Map<String, dynamic>>.from(response.data as List);
        } else if (response.data is Map<String, dynamic>) {
          final responseMap = response.data as Map<String, dynamic>;
          allEmployeesTemp = List<Map<String, dynamic>>.from(
            responseMap['data'] ?? [],
          );
        } else {
          allEmployeesTemp = [];
        }

        allEmployeesTemp = allEmployeesTemp
            .where(
              (emp) =>
                  emp['role'] != 'admin' &&
                  emp['email'] != null &&
                  emp['email'].toString().isNotEmpty,
            )
            .toList();

        if (mounted) {
          setState(() {
            allEmployees = allEmployeesTemp;
            isLoadingEmployees = false;
            error = null;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            isLoadingEmployees = false;
            error = response.message;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoadingEmployees = false;
          error = 'Failed to load employees: $e';
        });
      }
    }
  }

  Future<void> _loadBranches() async {
    setState(() {
      isLoadingBranches = true;
    });

    try {
      final response = await ApiService.getBranches(
        page: 1,
        limit: 100,
      );

      if (response.success && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final branchList = data['branches'] as List<dynamic>? ?? [];

        branches = branchList
            .map((json) => json as Map<String, dynamic>)
            .toList();

        if (mounted) {
          setState(() {
            isLoadingBranches = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            isLoadingBranches = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoadingBranches = false;
        });
      }
    }
  }

  String _getEmployeeDisplayName(Map<String, dynamic> emp) {
    final firstName = emp['firstName']?.toString() ?? '';
    final lastName = emp['lastName']?.toString() ?? '';
    final email = emp['email']?.toString() ?? '';
    final fullName = '$firstName $lastName'.trim();
    return '$fullName - $email';
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (!mounted) return;

    if (picked != null) {
      setState(() {
        _dateOfJoiningController.text =
            '${picked.day.toString().padLeft(2, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.year}';
      });
    }
  }

  Future<void> _sendAppointmentLetter() async {
    String? userId;
    String? employeeEmail;
    String? employeeName;

    if (isRegisteredMode) {
      if (selectedEmployee == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Please select an employee'),
            backgroundColor: Colors.orange[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        return;
      }

      userId = selectedEmployee!['_id'] ?? '';
      employeeEmail = selectedEmployee!['email'] ?? '';
      employeeName =
          '${selectedEmployee!['firstName'] ?? ''} ${selectedEmployee!['lastName'] ?? ''}'
              .trim();
    } else {
      if (!_formKey.currentState!.validate()) {
        return;
      }

      employeeName = '${_firstNameController.text} ${_lastNameController.text}'.trim();
      employeeEmail = _emailController.text.trim();

      // For manual entry, we'll set userId to null and handle separately
      userId = null;
    }

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: 24 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0071bf).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.mail_outline_rounded,
                  color: Color(0xFF0071bf),
                  size: 32,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Confirm Send',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF272579),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Send appointment letter to $employeeName?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0071bf).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF0071bf).withValues(alpha: 0.15),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.email_outlined,
                      size: 16,
                      color: Color(0xFF0071bf),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        employeeEmail ?? '',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF0071bf),
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(color: Colors.grey[300]!),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0071bf),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Send',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed != true) return;

    setState(() {
      isSending = true;
    });

    try {
      late ApiResponse<Map<String, dynamic>> response;

      if (userId != null) {
        // Registered employee mode
        response = await ApiService.sendAppointmentLetter(userId);
      } else {
        // Manual entry mode
        response = await ApiService.sendManualAppointmentLetter(
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          email: _emailController.text.trim(),
          phoneNumber: _phoneNumberController.text.trim(),
          address: _addressController.text.trim(),
          designation: _designationController.text.trim(),
          dateOfJoining: _dateOfJoiningController.text.trim(),
          branchName: _branchNameController.text.trim(),
          netSalary: _salaryController.text.trim(),
        );
      }

      if (!mounted) return;

      if (response.success) {
        if (!mounted) return;

        // Show success snackbar and pop navigation
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('Appointment letter sent to $employeeName'),
                ),
              ],
            ),
            backgroundColor: Colors.green[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 2),
          ),
        );

        // Pop navigation after a brief delay to show the snackbar
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            Navigator.of(context).pop();
          }
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message),
            backgroundColor: Colors.red[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        setState(() {
          isSending = false;
        });
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send appointment letter: $e'),
          backgroundColor: Colors.red[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      setState(() {
        isSending = false;
      });
    }
  }

  Widget _buildModeSegmentedButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
            child: _buildSegmentButton(
              label: 'Registered',
              icon: Icons.person_search_rounded,
              isActive: isRegisteredMode,
              onTap: () {
                setState(() {
                  isRegisteredMode = true;
                  _formKey.currentState?.reset();
                });
              },
            ),
          ),
          Expanded(
            child: _buildSegmentButton(
              label: 'Manual Entry',
              icon: Icons.edit_document,
              isActive: !isRegisteredMode,
              onTap: () {
                setState(() {
                  isRegisteredMode = false;
                  selectedEmployee = null;
                  _registeredSearchController.clear();
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentButton({
    required String label,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive
                ? const Color(0xFF0071bf).withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: isActive
                ? Border.all(
                    color: const Color(0xFF0071bf).withValues(alpha: 0.3),
                    width: 1.5,
                  )
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isActive ? const Color(0xFF0071bf) : Colors.grey[500],
                size: 22,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                  color: isActive ? const Color(0xFF0071bf) : Colors.grey[500],
                  letterSpacing: 0.2,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRegisteredEmployeeMode() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Find Employee',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF272579),
                  letterSpacing: -0.3,
                ),
              ),
            ),
            if (selectedEmployee != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF5cfbd8).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, size: 14, color: Color(0xFF5cfbd8)),
                    SizedBox(width: 4),
                    Text(
                      'Selected',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF5cfbd8),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Autocomplete<Map<String, dynamic>>(
          optionsBuilder: (TextEditingValue textEditingValue) {
            if (textEditingValue.text.isEmpty) {
              return const Iterable<Map<String, dynamic>>.empty();
            }

            final query = textEditingValue.text.toLowerCase();
            return allEmployees.where((emp) {
              final firstName = emp['firstName']?.toString().toLowerCase() ?? '';
              final lastName = emp['lastName']?.toString().toLowerCase() ?? '';
              final email = emp['email']?.toString().toLowerCase() ?? '';
              final employeeId = emp['employeeId']?.toString().toLowerCase() ?? '';

              return firstName.contains(query) ||
                  lastName.contains(query) ||
                  email.contains(query) ||
                  employeeId.contains(query) ||
                  '$firstName $lastName'.contains(query);
            });
          },
          onSelected: (Map<String, dynamic> selection) {
            setState(() {
              selectedEmployee = selection;
              _registeredSearchController.text =
                  _getEmployeeDisplayName(selection);
            });
          },
          fieldViewBuilder: (BuildContext context,
              TextEditingController textEditingController,
              FocusNode focusNode,
              VoidCallback onFieldSubmitted) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFF272579).withValues(alpha: 0.12),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: TextField(
                controller: textEditingController,
                focusNode: focusNode,
                decoration: InputDecoration(
                  hintText: 'Type name, email, or ID...',
                  hintStyle: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: const Color(0xFF272579).withValues(alpha: 0.5),
                    size: 22,
                  ),
                  suffixIcon: textEditingController.text.isNotEmpty
                      ? IconButton(
                          onPressed: () {
                            textEditingController.clear();
                            setState(() {
                              selectedEmployee = null;
                            });
                          },
                          icon: Icon(
                            Icons.close_rounded,
                            color: Colors.grey[400],
                            size: 20,
                          ),
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF272579),
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          },
          optionsViewBuilder: (BuildContext context,
              AutocompleteOnSelected<Map<String, dynamic>> onSelected,
              Iterable<Map<String, dynamic>> options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 6,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: 320,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: Colors.white,
                  ),
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (BuildContext context, int index) {
                      final emp = options.elementAt(index);
                      final fullName =
                          '${emp['firstName'] ?? ''} ${emp['lastName'] ?? ''}'
                              .trim();
                      final designation = emp['designation'] ?? '';
                      final email = emp['email'] ?? '';

                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => onSelected(emp),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF272579),
                                        Color(0xFF0071bf),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Center(
                                    child: Text(
                                      fullName.isNotEmpty
                                          ? fullName[0].toUpperCase()
                                          : 'E',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        fullName,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF272579),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '$designation • $email',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey[500],
                                          fontWeight: FontWeight.w500,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 28),
        if (selectedEmployee != null) ...[
          _buildSelectedEmployeeCard(),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.grey[200]!,
                width: 1.5,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0071bf).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.person_search_rounded,
                    size: 56,
                    color: Color(0xFF0071bf),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Search for an Employee',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF272579),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Start typing a name, email, or employee ID to find and select an employee.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSelectedEmployeeCard() {
    if (selectedEmployee == null) return const SizedBox.shrink();

    final fullName =
        '${selectedEmployee!['firstName'] ?? ''} ${selectedEmployee!['lastName'] ?? ''}'
            .trim();
    final designation = selectedEmployee!['designation'] ?? '';
    final email = selectedEmployee!['email'] ?? '';
    final employeeId = selectedEmployee!['employeeId'] ?? '';
    final dateOfJoining = selectedEmployee!['dateOfJoining'] ?? '';

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF272579), Color(0xFF0071bf)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0071bf).withValues(alpha: 0.2),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      fullName.isNotEmpty ? fullName[0].toUpperCase() : 'E',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fullName,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.3,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        designation,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.white70,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.1,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedEmployee = null;
                      _registeredSearchController.clear();
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Details',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Colors.grey[700],
              letterSpacing: 0.5,
              textBaseline: TextBaseline.alphabetic,
            ),
          ),
          const SizedBox(height: 12),
          _buildDetailFieldModern(
            label: 'Email',
            value: email,
            icon: Icons.email_outlined,
          ),
          const SizedBox(height: 10),
          _buildDetailFieldModern(
            label: 'Employee ID',
            value: employeeId,
            icon: Icons.badge_outlined,
          ),
          const SizedBox(height: 10),
          _buildDetailFieldModern(
            label: 'Joined',
            value: dateOfJoining.isNotEmpty ? dateOfJoining : 'Not provided',
            icon: Icons.calendar_today_outlined,
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isSending ? null : _sendAppointmentLetter,
              icon: isSending
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    )
                  : const Icon(Icons.mail_outline_rounded, size: 20),
              label: Text(
                isSending ? 'Sending...' : 'Send Appointment Letter',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0071bf),
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFF0071bf)
                    .withValues(alpha: 0.5),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailFieldModern({
    required String label,
    required String? value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0071bf).withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF0071bf).withValues(alpha: 0.12),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: const Color(0xFF0071bf),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value ?? 'Not provided',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF272579),
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManualEntryMode() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Employee Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF272579),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 20),
          _buildModernTextField(
            controller: _firstNameController,
            label: 'First Name',
            icon: Icons.person_outline,
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return 'Required';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),
          _buildModernTextField(
            controller: _lastNameController,
            label: 'Last Name',
            icon: Icons.person_outline,
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return 'Required';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),
          _buildModernTextField(
            controller: _emailController,
            label: 'Email Address',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return 'Email is required';
              }
              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value!)) {
                return 'Invalid email';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),
          _buildModernTextField(
            controller: _designationController,
            label: 'Designation',
            icon: Icons.badge_outlined,
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return 'Required';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),
          _buildModernTextField(
            controller: _dateOfJoiningController,
            label: 'Date of Joining',
            icon: Icons.calendar_today_outlined,
            readOnly: true,
            onTap: _selectDate,
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return 'Date of joining is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),
          _buildModernTextField(
            controller: _addressController,
            label: 'Address',
            icon: Icons.location_on_outlined,
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return 'Address is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),
          _buildModernTextField(
            controller: _phoneNumberController,
            label: 'Phone Number',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return 'Phone number is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),
          _buildBranchDropdown(),
          const SizedBox(height: 14),
          _buildModernTextField(
            controller: _salaryController,
            label: 'Monthly Salary',
            icon: Icons.currency_rupee_outlined,
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return 'Monthly salary is required';
              }
              if (int.tryParse(value!) == null) {
                return 'Please enter a valid number';
              }
              return null;
            },
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isSending ? null : _sendAppointmentLetter,
              icon: isSending
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    )
                  : const Icon(Icons.mail_outline_rounded, size: 20),
              label: Text(
                isSending ? 'Sending...' : 'Send Appointment Letter',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0071bf),
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFF0071bf)
                    .withValues(alpha: 0.5),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: Color(0xFF272579),
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
        prefixIcon: Icon(
          icon,
          color: const Color(0xFF0071bf),
          size: 20,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.transparent),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.grey[200]!,
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFF0071bf),
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Colors.red,
            width: 1.5,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        filled: true,
        fillColor: Colors.white,
        errorStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
      keyboardType: keyboardType,
      readOnly: readOnly,
      onTap: onTap,
      validator: validator,
      style: const TextStyle(
        fontSize: 16,
        color: Color(0xFF272579),
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildBranchDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: selectedBranchId,
      decoration: InputDecoration(
        labelText: 'Branch',
        prefixIcon: isLoadingBranches
            ? const SizedBox(
                width: 20,
                height: 20,
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0071bf)),
                  ),
                ),
              )
            : const Icon(Icons.business_outlined, color: Color(0xFF0071bf)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF0071bf), width: 2),
        ),
        filled: true,
        fillColor: const Color(0xFFfbf8ff),
        labelStyle: TextStyle(
          color: Colors.grey[700],
          fontWeight: FontWeight.w500,
        ),
      ),
      items: [
        const DropdownMenuItem<String>(value: null, child: Text('No Branch')),
        ...branches.map((branch) {
          return DropdownMenuItem<String>(
            value: branch['_id'] ?? branch['id'],
            child: Text(
              branch['branchName'] ?? '',
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          );
        }),
      ],
      onChanged: (value) {
        setState(() {
          selectedBranchId = value;
          // Update the branch name controller with selected branch name
          if (value != null) {
            final selectedBranch = branches.firstWhere(
              (b) => (b['_id'] ?? b['id']) == value,
              orElse: () => <String, dynamic>{},
            );
            _branchNameController.text =
                selectedBranch['branchName']?.toString() ?? '';
          }
        });
      },
      validator: (value) => value == null ? 'Branch is required' : null,
    );
  }

  @override
  Widget build(BuildContext context) {
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
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.mail_outline_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Appointment Letter',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                  Text(
                    'Send to employee',
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
      ),
      backgroundColor: const Color(0xFFFAFAFC),
      body: isLoadingEmployees
          ? const LoadingWidget(message: 'Loading employees...')
          : error != null
              ? Center(
                  child: Container(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                            Icons.error_outline_rounded,
                            size: 56,
                            color: Colors.red[400],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Unable to Load',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          error!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 28),
                        ElevatedButton.icon(
                          onPressed: _loadAllEmployees,
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Try Again'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF272579),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 28,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Mode toggle - Commented out: Manual entry is now the default
                      // _buildModeSegmentedButton(),

                      const SizedBox(height: 28),

                      // Mode-specific content - Manual entry is now always shown
                      // if (isRegisteredMode)
                      //   _buildRegisteredEmployeeMode()
                      // else
                      _buildManualEntryMode(),
                    ],
                  ),
                ),
    );
  }
}

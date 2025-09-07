import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/api_service.dart';

class AddUserScreen extends StatefulWidget {
  const AddUserScreen({super.key});

  @override
  State<AddUserScreen> createState() => _AddUserScreenState();
}

class _AddUserScreenState extends State<AddUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _designationController = TextEditingController();
  
  String? selectedRole;
  String? selectedManagerId;
  DateTime? selectedJoiningDate;
  
  List<Map<String, dynamic>> managers = [];
  bool isLoadingManagers = false;
  bool isSubmitting = false;

  // Company colors
  static const Color brandPrimary = Color(0xFF272579);
  static const Color primaryBlue = Color(0xFF0071bf);
  static const Color successGreen = Color(0xFF5cfbd8);
  static const Color surfaceLight = Color(0xFFfbf8ff);
  static const Color backgroundColor = Color(0xFFf8f9fa);

  final List<String> roles = [
    'manager',
    'field_staff',
    'telecaller',
    'director',
    'admin'
  ];

  @override
  void initState() {
    super.initState();
    selectedJoiningDate = null;
    _loadManagers();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _designationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String _formatRoleDisplay(String role) {
    switch (role) {
      case 'field_staff':
        return 'Field Staff';
      default:
        return role[0].toUpperCase() + role.substring(1).toLowerCase();
    }
  }

  Future<void> _loadManagers() async {
    setState(() {
      isLoadingManagers = true;
    });

    try {
      final response = await ApiService.getManagers();
      if (response.success && response.data != null) {
        setState(() {
          if (response.data is List) {
            managers = List<Map<String, dynamic>>.from(response.data as List);
          } else if (response.data is Map<String, dynamic>) {
            final responseMap = response.data as Map<String, dynamic>;
            managers = List<Map<String, dynamic>>.from(responseMap['data'] ?? []);
          } else {
            managers = [];
          }
          isLoadingManagers = false;
        });
      } else {
        setState(() {
          isLoadingManagers = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoadingManagers = false;
      });
    }
  }

  Future<void> _selectJoiningDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedJoiningDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: brandPrimary,
              onPrimary: Colors.white,
              surface: surfaceLight,
              onSurface: Colors.black87,
            ),
            dialogTheme: const DialogThemeData(
              backgroundColor: surfaceLight,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != selectedJoiningDate) {
      setState(() {
        selectedJoiningDate = picked;
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      _scrollToFirstError();
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    try {
      final response = await ApiService.createUser(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim().toLowerCase(),
        phoneNumber: _phoneController.text.trim(),
        role: selectedRole!,
        designation: _designationController.text.trim(),
        dateOfJoining: selectedJoiningDate?.toIso8601String(),
        managerId: selectedManagerId,
      );

      if (mounted) {
        if (response.success) {
          _showSnackBar('User created successfully!', successGreen);
          Navigator.of(context).pop();
        } else {
          _showSnackBar(response.message, Colors.red);
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Failed to create user: $e', Colors.red);
      }
    } finally {
      setState(() {
        isSubmitting = false;
      });
    }
  }

  void _scrollToFirstError() {
    _scrollController.animateTo(
      0.0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _showSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            color: brandPrimary,
          ),
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [brandPrimary, primaryBlue],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: const Text(
          'Add New User',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),
              _buildPersonalInfoSection(),
              _buildWorkInfoSection(),
              const SizedBox(height: 32),
              _buildSaveButton(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPersonalInfoSection() {
    return _buildSectionCard(
      title: 'Personal Information',
      icon: Icons.person_outlined,
      children: [
        _buildTextField(
          controller: _firstNameController,
          label: 'First Name',
          icon: Icons.person_outline,
          isRequired: true,
          validator: UserValidation.validateFirstName,
        ),
        _buildTextField(
          controller: _lastNameController,
          label: 'Last Name',
          icon: Icons.person_outline,
          isRequired: true,
          validator: UserValidation.validateLastName,
        ),
        _buildTextField(
          controller: _emailController,
          label: 'Email Address',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          isRequired: true,
          validator: UserValidation.validateEmail,
          hintText: 'user@company.com',
        ),
        _buildTextField(
          controller: _phoneController,
          label: 'Phone Number',
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          isRequired: true,
          validator: UserValidation.validatePhone,
          hintText: '+91 XXXXX XXXXX',
        ),
      ],
    );
  }

  Widget _buildWorkInfoSection() {
    return _buildSectionCard(
      title: 'Work Information',
      icon: Icons.work_outlined,
      children: [
        _buildRoleDropdown(),
        _buildTextField(
          controller: _designationController,
          label: 'Designation',
          icon: Icons.badge_outlined,
          isRequired: true,
          validator: UserValidation.validateDesignation,
        ),
        _buildDateField(),
        _buildManagerDropdown(),
      ],
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: primaryBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: primaryBlue, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: brandPrimary,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: children.map((child) {
                final index = children.indexOf(child);
                return Column(
                  children: [
                    child,
                    if (index < children.length - 1) const SizedBox(height: 20),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isRequired = false,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    bool readOnly = false,
    String? hintText,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: isRequired ? '$label *' : label,
        hintText: hintText,
        prefixIcon: Icon(icon, color: primaryBlue),
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
          borderSide: const BorderSide(color: primaryBlue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        filled: true,
        fillColor: readOnly ? Colors.grey.withValues(alpha: 0.1) : surfaceLight,
        labelStyle: TextStyle(
          color: Colors.grey[700],
          fontWeight: FontWeight.w500,
        ),
        hintStyle: TextStyle(color: Colors.grey[500]),
      ),
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      readOnly: readOnly,
      inputFormatters: inputFormatters,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildRoleDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: selectedRole,
      decoration: InputDecoration(
        labelText: 'Role *',
        prefixIcon: const Icon(Icons.work_outline, color: primaryBlue),
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
          borderSide: const BorderSide(color: primaryBlue, width: 2),
        ),
        filled: true,
        fillColor: surfaceLight,
        labelStyle: TextStyle(
          color: Colors.grey[700],
          fontWeight: FontWeight.w500,
        ),
      ),
      items: roles.map((role) => DropdownMenuItem(
        value: role,
        child: Text(
          _formatRoleDisplay(role),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
      )).toList(),
      onChanged: (value) => setState(() => selectedRole = value),
      validator: (value) => value == null ? 'Please select a role' : null,
    );
  }

  Widget _buildManagerDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: selectedManagerId,
      decoration: InputDecoration(
        labelText: 'Manager',
        prefixIcon: isLoadingManagers
            ? const SizedBox(
                width: 20,
                height: 20,
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(primaryBlue),
                  ),
                ),
              )
            : const Icon(Icons.supervisor_account_outlined, color: primaryBlue),
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
          borderSide: const BorderSide(color: primaryBlue, width: 2),
        ),
        filled: true,
        fillColor: surfaceLight,
        labelStyle: TextStyle(
          color: Colors.grey[700],
          fontWeight: FontWeight.w500,
        ),
      ),
      items: [
        const DropdownMenuItem<String>(value: null, child: Text('No Manager')),
        ...managers.map((manager) {
          final firstName = manager['firstName'] ?? '';
          final lastName = manager['lastName'] ?? '';
          final employeeId = manager['employeeId'] ?? '';
          final fullName = '$firstName $lastName'.trim();
          final displayText = employeeId.isNotEmpty
              ? '$fullName ($employeeId)'
              : fullName;

          return DropdownMenuItem<String>(
            value: manager['_id'] ?? manager['id'],
            child: Text(
              displayText,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          );
        }),
      ],
      onChanged: (value) => setState(() => selectedManagerId = value),
    );
  }

  Widget _buildDateField() {
    return InkWell(
      onTap: _selectJoiningDate,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(12),
          color: surfaceLight,
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined, color: primaryBlue),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Date of Joining',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    selectedJoiningDate != null
                        ? '${selectedJoiningDate!.day}/${selectedJoiningDate!.month}/${selectedJoiningDate!.year}'
                        : 'Select date (optional)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: selectedJoiningDate != null
                          ? Colors.black87
                          : Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isSubmitting ? null : _submitForm,
        style: ElevatedButton.styleFrom(
          backgroundColor: brandPrimary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey[300],
          disabledForegroundColor: Colors.grey[600],
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
          shadowColor: brandPrimary.withValues(alpha: 0.3),
        ),
        child: isSubmitting
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(width: 16),
                  Text(
                    'Creating...',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Create User',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class UserValidation {
  static String? validateFirstName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'First name is required';
    }
    if (value.trim().length > 50) {
      return 'First name must not exceed 50 characters';
    }
    return null;
  }

  static String? validateLastName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Last name is required';
    }
    if (value.trim().length > 50) {
      return 'Last name must not exceed 50 characters';
    }
    return null;
  }

  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    if (value.trim().length < 10) {
      return 'Please enter a valid phone number';
    }
    return null;
  }

  static String? validateDesignation(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Designation is required';
    }
    if (value.trim().length > 100) {
      return 'Designation must not exceed 100 characters';
    }
    return null;
  }
}
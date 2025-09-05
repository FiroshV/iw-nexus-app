import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/api_service.dart';
import '../../models/branch_model.dart';

class AddEditBranchScreen extends StatefulWidget {
  final Branch? branch;

  const AddEditBranchScreen({super.key, this.branch});

  bool get isEditing => branch != null;

  @override
  State<AddEditBranchScreen> createState() => _AddEditBranchScreenState();
}

class _AddEditBranchScreenState extends State<AddEditBranchScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Controllers
  final _branchNameController = TextEditingController();
  final _streetController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _countryController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  // State variables
  bool isLoading = false;
  bool isSaving = false;
  String? selectedStatus;
  String? selectedManagerId;
  DateTime? selectedEstablishedDate;
  List<Map<String, dynamic>> availableManagers = [];
  bool loadingManagers = false;

  // Constants
  static const List<String> branchStatuses = [
    'active',
    'inactive',
    'temporarily_closed',
  ];
  static const List<String> indianStates = [
    'Andhra Pradesh',
    'Arunachal Pradesh',
    'Assam',
    'Bihar',
    'Chhattisgarh',
    'Goa',
    'Gujarat',
    'Haryana',
    'Himachal Pradesh',
    'Jharkhand',
    'Karnataka',
    'Kerala',
    'Madhya Pradesh',
    'Maharashtra',
    'Manipur',
    'Meghalaya',
    'Mizoram',
    'Nagaland',
    'Odisha',
    'Punjab',
    'Rajasthan',
    'Sikkim',
    'Tamil Nadu',
    'Telangana',
    'Tripura',
    'Uttar Pradesh',
    'Uttarakhand',
    'West Bengal',
    'Delhi',
    'Puducherry',
    'Chandigarh',
    'Dadra and Nagar Haveli',
    'Daman and Diu',
    'Lakshadweep',
    'Andaman and Nicobar Islands',
  ];

  // Company colors
  static const Color brandPrimary = Color(0xFF272579);
  static const Color primaryBlue = Color(0xFF0071bf);
  static const Color successGreen = Color(0xFF5cfbd8);
  static const Color surfaceLight = Color(0xFFfbf8ff);
  static const Color backgroundColor = Color(0xFFf8f9fa);

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeForm();
    _loadAvailableManagers();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0.0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _branchNameController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _countryController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _initializeForm() {
    if (widget.isEditing) {
      final branch = widget.branch!;
      _branchNameController.text = branch.branchName;
      _streetController.text = branch.branchAddress.street;
      _cityController.text = branch.branchAddress.city;
      _stateController.text = branch.branchAddress.state;
      _pincodeController.text = branch.branchAddress.pincode;
      _countryController.text = branch.branchAddress.country;
      _phoneController.text = branch.contactInfo.phone ?? '';
      _emailController.text = branch.contactInfo.email ?? '';
      selectedStatus = branch.status.toJson();
      selectedManagerId = branch.branchManager?.id;
      selectedEstablishedDate = branch.establishedDate;
    } else {
      selectedStatus = 'active';
      _countryController.text = 'India';
    }
  }

  Future<void> _loadAvailableManagers() async {
    setState(() {
      loadingManagers = true;
    });

    try {
      final response = await ApiService.getAllUsers(
        limit: 100,
        role: 'manager',
        status: 'active',
      );

      if (response.success && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final users = data['users'] as List<dynamic>? ?? [];

        if (mounted) {
          setState(() {
            availableManagers = users.cast<Map<String, dynamic>>();
            loadingManagers = false;
          });
        }
      } else {
        final directorResponse = await ApiService.getAllUsers(
          limit: 100,
          role: 'director',
          status: 'active',
        );

        if (directorResponse.success && directorResponse.data != null) {
          final data = directorResponse.data as Map<String, dynamic>;
          final users = data['users'] as List<dynamic>? ?? [];

          if (mounted) {
            setState(() {
              availableManagers = users.cast<Map<String, dynamic>>();
              loadingManagers = false;
            });
          }
        } else {
          if (mounted) {
            setState(() {
              loadingManagers = false;
            });
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          loadingManagers = false;
        });
      }
    }
  }

  Future<void> _selectEstablishedDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedEstablishedDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
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
              backgroundColor: Color(0xFFfbf8ff),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != selectedEstablishedDate) {
      setState(() {
        selectedEstablishedDate = picked;
      });
    }
  }

  Future<void> _saveBranch() async {
    debugPrint('🔄 Saving branch...');
    if (!_formKey.currentState!.validate()) {
      _scrollToFirstError();
      return;
    }
    debugPrint('🔄 Saving branch... 2');

    if (selectedStatus == null) {
      _showSnackBar('Please select a branch status', Colors.red);
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      final branchData = {
        'branchName': _branchNameController.text.trim(),
        'branchAddress': {
          'street': _streetController.text.trim(),
          'city': _cityController.text.trim(),
          'state': _stateController.text.trim(),
          'pincode': _pincodeController.text.trim(),
          'country': _countryController.text.trim(),
        },
        'contactInfo': {
          'phone': _phoneController.text.trim().isNotEmpty
              ? _phoneController.text.trim()
              : null,
          'email': _emailController.text.trim().isNotEmpty
              ? _emailController.text.trim()
              : null,
        },
        'status': selectedStatus,
        'establishedDate': selectedEstablishedDate?.toIso8601String(),
      };

      // Add only if not null
      if (selectedManagerId != null) {
        branchData['branchManager'] = selectedManagerId;
      }

      debugPrint('Branch Data to Save: $branchData');

      final response = widget.isEditing
          ? await ApiService.updateBranch(widget.branch!.id, branchData)
          : await ApiService.createBranch(branchData);

      if (mounted) {
        setState(() {
          isSaving = false;
        });

        if (response.success) {
          _showSnackBar(
            widget.isEditing
                ? 'Branch updated successfully'
                : 'Branch created successfully',
            successGreen,
          );
          Navigator.of(context).pop(true);
        } else {
          _showSnackBar(response.message, Colors.red);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
        _showSnackBar('Failed to save branch: $e', Colors.red);
      }
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
            color: Colors.white,
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
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildSliverAppBar(),
              SliverToBoxAdapter(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.isEditing) _buildBranchIdCard(),
                      _buildBranchInfoSection(),
                      _buildAddressSection(),
                      _buildContactSection(),
                      const SizedBox(height: 32),
                      _buildSaveButton(),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      floating: false,
      pinned: true,
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
        child: FlexibleSpaceBar(
          title: Text(
            widget.isEditing ? 'Edit Branch' : 'Add Branch',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          background: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 80, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _buildAnimatedIcon(),
                      const SizedBox(width: 16),
                      Text(
                        widget.isEditing
                            ? 'Update Branch Details'
                            : 'Create New Branch',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      actions: [
        if (isSaving)
          const Padding(
            padding: EdgeInsets.all(16),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          )
        else
          TextButton.icon(
            onPressed: _saveBranch,
            icon: const Icon(Icons.check, color: Colors.white, size: 18),
            label: const Text(
              'Save',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAnimatedIcon() {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 1000),
      tween: Tween<double>(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Icon(
              widget.isEditing
                  ? Icons.edit_location_outlined
                  : Icons.add_business_outlined,
              color: Colors.white,
              size: 32,
            ),
          ),
        );
      },
    );
  }

  Widget _buildBranchIdCard() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            successGreen.withValues(alpha: 0.1),
            primaryBlue.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: successGreen.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: successGreen.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: successGreen.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.business_outlined,
              color: primaryBlue,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'BRANCH ID',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.branch!.branchId,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: brandPrimary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: primaryBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'EDITING',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: primaryBlue,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBranchInfoSection() {
    return _buildSectionCard(
      title: 'Branch Information',
      icon: Icons.business_outlined,
      children: [
        _buildTextField(
          controller: _branchNameController,
          label: 'Branch Name',
          icon: Icons.store_outlined,
          isRequired: true,
          validator: BranchValidation.validateBranchName,
        ),
        _buildStatusDropdown(),
        _buildManagerDropdown(),
        _buildDateField(),
      ],
    );
  }

  Widget _buildAddressSection() {
    return _buildSectionCard(
      title: 'Branch Address',
      icon: Icons.location_on_outlined,
      children: [
        _buildTextField(
          controller: _streetController,
          label: 'Street Address',
          icon: Icons.home_outlined,
          maxLines: 2,
          isRequired: true,
          validator: BranchValidation.validateStreet,
        ),
        _buildTextField(
          controller: _cityController,
          label: 'City',
          icon: Icons.location_city_outlined,
          isRequired: true,
          validator: BranchValidation.validateCity,
        ),
        _buildStateDropdown(),
        _buildTextField(
          controller: _pincodeController,
          label: 'Pincode',
          icon: Icons.pin_drop_outlined,
          keyboardType: TextInputType.number,
          isRequired: true,
          validator: BranchValidation.validatePincode,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(6),
          ],
        ),
        _buildTextField(
          controller: _countryController,
          label: 'Country',
          icon: Icons.public_outlined,
          readOnly: true,
        ),
      ],
    );
  }

  Widget _buildContactSection() {
    return _buildSectionCard(
      title: 'Contact Information',
      icon: Icons.contact_phone_outlined,
      children: [
        _buildTextField(
          controller: _phoneController,
          label: 'Phone Number',
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          validator: BranchValidation.validatePhone,
          hintText: '+91 XXXXX XXXXX',
        ),
        _buildTextField(
          controller: _emailController,
          label: 'Email Address',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          validator: BranchValidation.validateEmail,
          hintText: 'branch@company.com',
        ),
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
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
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

  Widget _buildStatusDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: selectedStatus,
      decoration: InputDecoration(
        labelText: 'Status *',
        prefixIcon: const Icon(Icons.info_outline, color: primaryBlue),
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
      items: branchStatuses.map((status) {
        return DropdownMenuItem<String>(
          value: status,
          child: Text(
            _getStatusDisplayName(status),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        );
      }).toList(),
      onChanged: (value) => setState(() => selectedStatus = value),
      validator: (value) =>
          value == null || value.isEmpty ? 'Please select a status' : null,
    );
  }

  Widget _buildStateDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: indianStates.contains(_stateController.text)
          ? _stateController.text
          : null,
      decoration: InputDecoration(
        labelText: 'State *',
        prefixIcon: const Icon(Icons.map_outlined, color: primaryBlue),
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
      isExpanded: true,
      items: indianStates.map((state) {
        return DropdownMenuItem<String>(
          value: state,
          child: Text(
            state,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        );
      }).toList(),
      onChanged: (value) => setState(() => _stateController.text = value ?? ''),
      validator: (value) =>
          value == null || value.isEmpty ? 'Please select a state' : null,
    );
  }

  Widget _buildManagerDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: selectedManagerId,
      decoration: InputDecoration(
        labelText: 'Branch Manager',
        prefixIcon: loadingManagers
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
            : const Icon(Icons.person_outline, color: primaryBlue),
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
      items: availableManagers.map((manager) {
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
      }).toList(),
      onChanged: (value) => setState(() => selectedManagerId = value),
    );
  }

  Widget _buildDateField() {
    return InkWell(
      onTap: _selectEstablishedDate,
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
                    'Established Date',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    selectedEstablishedDate != null
                        ? '${selectedEstablishedDate!.day}/${selectedEstablishedDate!.month}/${selectedEstablishedDate!.year}'
                        : 'Select date',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: selectedEstablishedDate != null
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
        onPressed: isSaving ? null : _saveBranch,
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
        child: isSaving
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    widget.isEditing ? 'Updating...' : 'Creating...',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(widget.isEditing ? Icons.update : Icons.add, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    widget.isEditing ? 'Update Branch' : 'Create Branch',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  String _getStatusDisplayName(String status) {
    switch (status) {
      case 'active':
        return 'Active';
      case 'inactive':
        return 'Inactive';
      case 'temporarily_closed':
        return 'Temporarily Closed';
      default:
        return status.replaceAll('_', ' ').toUpperCase();
    }
  }
}

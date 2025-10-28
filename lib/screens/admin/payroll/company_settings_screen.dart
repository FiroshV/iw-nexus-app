import 'package:flutter/material.dart';
import '../../../services/payroll_api_service.dart';
import 'payroll_management_screen.dart';

/// Admin screen for managing company payroll settings with wizard-style form
class CompanySettingsScreen extends StatefulWidget {
  const CompanySettingsScreen({super.key});

  @override
  State<CompanySettingsScreen> createState() => _CompanySettingsScreenState();
}

class _CompanySettingsScreenState extends State<CompanySettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();
  int _currentStep = 0;
  bool _isLoading = false;
  bool _isSaving = false;


  // Text controllers
  final _companyNameController = TextEditingController();
  final _streetController = TextEditingController();
  final _cityController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _panController = TextEditingController();
  final _tanController = TextEditingController();

  String _selectedState = 'Maharashtra';

  final List<String> _indianStates = [
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
  ];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    try {
      final settings = await PayrollApiService.getCompanySettings();
      setState(() {
        _companyNameController.text = settings['companyName'] ?? '';
        _streetController.text = settings['companyAddress']?['street'] ?? '';
        _cityController.text = settings['companyAddress']?['city'] ?? '';
        _selectedState = settings['companyAddress']?['state'] ?? settings['state'] ?? 'Maharashtra';
        _pincodeController.text = settings['companyAddress']?['pincode'] ?? '';
        _panController.text = settings['pan'] ?? '';
        _tanController.text = settings['tan'] ?? '';
      });
    } catch (e) {
      _showMessage('Error loading settings: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _companyNameController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _pincodeController.dispose();
    _panController.dispose();
    _tanController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep++);
    } else {
      _saveSettings();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep--);
    }
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      final settings = {
        'companyName': _companyNameController.text,
        'companyAddress': {
          'street': _streetController.text,
          'city': _cityController.text,
          'state': _selectedState,
          'pincode': _pincodeController.text,
          'country': 'India',
        },
        'state': _selectedState,
        'pan': _panController.text,
        'tan': _tanController.text,
      };

      await PayrollApiService.updateCompanySettings(settings);
      if (mounted) {
        _showMessage('Company settings saved successfully!');
        // Navigate to PayrollManagementScreen with Employees tab selected
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const PayrollManagementScreen(initialTab: 0),
          ),
        );
      }
    } catch (e) {
      _showMessage('Failed to save settings: $e', isError: true);
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(
            color: isError ? Colors.white : const Color(0xFF0071bf),
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: isError ? Colors.red : const Color(0xFF5cfbd8),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFf8f9fa),
      appBar: AppBar(
        title: const Text(
          'Company Settings',
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
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF0071bf)),
            )
          : Column(
              children: [
                _buildStepIndicator(),
                Expanded(
                  child: Form(
                    key: _formKey,
                    child: PageView(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _buildBasicInfoStep(),
                        _buildTaxInfoStep(),
                      ],
                    ),
                  ),
                ),
                _buildNavigationButtons(),
              ],
            ),
    );
  }

  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Step ${_currentStep + 1} of 2: ${_getStepTitle()}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF272579),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(2, (index) {
              return Expanded(
                child: Container(
                  height: 4,
                  margin: EdgeInsets.only(right: index < 1 ? 8 : 0),
                  decoration: BoxDecoration(
                    color: index <= _currentStep
                        ? const Color(0xFF0071bf)
                        : Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case 0:
        return 'Basic Information';
      case 1:
        return 'Statutory Details';
      default:
        return '';
    }
  }

  Widget _buildBasicInfoStep() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionCard(
          title: 'Company Details',
          children: [
            _buildTextField(
              controller: _companyNameController,
              label: 'Company Name',
              hint: 'IW Nexus Pvt Ltd',
              isRequired: true,
              icon: Icons.business,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _streetController,
              label: 'Street Address',
              hint: '123 Business Park',
              isRequired: true,
              icon: Icons.location_on,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _cityController,
                    label: 'City',
                    hint: 'Mumbai',
                    isRequired: true,
                    icon: Icons.location_city,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDropdownField(
                    value: _selectedState,
                    label: 'State',
                    items: _indianStates,
                    onChanged: (value) {
                      setState(() => _selectedState = value!);
                    },
                    icon: Icons.map,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _pincodeController,
              label: 'Pincode',
              hint: '400001',
              isRequired: true,
              icon: Icons.pin_drop,
              keyboardType: TextInputType.number,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTaxInfoStep() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionCard(
          title: 'Statutory Details',
          children: [
            _buildTextField(
              controller: _panController,
              label: 'PAN Number',
              hint: 'ABCDE1234F',
              isRequired: true,
              icon: Icons.badge,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _tanController,
              label: 'TAN Number',
              hint: 'MUMB12345E',
              isRequired: true,
              icon: Icons.badge_outlined,
            ),
          ],
        ),
      ],
    );
  }



  Widget _buildSectionCard({
    required String title,
    String? subtitle,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF272579),
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
            const SizedBox(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    bool isRequired = false,
    IconData? icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: '$label${isRequired ? ' *' : ''}',
        hintText: hint,
        prefixIcon: icon != null ? Icon(icon, color: const Color(0xFF0071bf)) : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF0071bf), width: 2),
        ),
      ),
      validator: isRequired
          ? (value) {
              if (value == null || value.isEmpty) {
                return 'This field is required';
              }
              return null;
            }
          : null,
    );
  }

  Widget _buildDropdownField({
    required String value,
    required String label,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    IconData? icon,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon != null ? Icon(icon, color: const Color(0xFF0071bf)) : null,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF0071bf), width: 2),
        ),
      ),
      items: items.map((item) {
        return DropdownMenuItem(
          value: item,
          child: Text(
            item,
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }


  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _previousStep,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF0071bf),
                  side: const BorderSide(color: Color(0xFF0071bf), width: 2),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Previous',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0071bf),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                disabledBackgroundColor: Colors.grey,
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      _currentStep == 1 ? 'Save Settings' : 'Next',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Content widget for company settings (used in tabbed interface)
class CompanySettingsContent extends StatefulWidget {
  final VoidCallback? onSuccess;
  final Map<String, dynamic>? initialSettings;

  const CompanySettingsContent({
    super.key,
    this.onSuccess,
    this.initialSettings,
  });

  @override
  State<CompanySettingsContent> createState() => _CompanySettingsContentState();
}

class _CompanySettingsContentState extends State<CompanySettingsContent> {
  int _currentStep = 0;
  bool _isSaving = false;
  bool _isLoading = true;

  final _formKey = GlobalKey<FormState>();
  final _companyNameController = TextEditingController();
  final _streetController = TextEditingController();
  final _cityController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _panController = TextEditingController();
  final _tanController = TextEditingController();

  String _selectedState = 'Maharashtra';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      // Use provided initial settings or fetch from API
      final settings = widget.initialSettings ??
          await PayrollApiService.getCompanySettings();

      if (mounted) {
        setState(() {
          _companyNameController.text = settings['companyName'] ?? '';
          _streetController.text = settings['companyAddress']?['street'] ?? '';
          _cityController.text = settings['companyAddress']?['city'] ?? '';
          _selectedState = settings['companyAddress']?['state'] ??
              settings['state'] ?? 'Maharashtra';
          _pincodeController.text = settings['companyAddress']?['pincode'] ?? '';
          _panController.text = settings['pan'] ?? '';
          _tanController.text = settings['tan'] ?? '';
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading settings: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  final List<String> _indianStates = [
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
  ];

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      final settings = {
        'companyName': _companyNameController.text,
        'companyAddress': {
          'street': _streetController.text,
          'city': _cityController.text,
          'state': _selectedState,
          'pincode': _pincodeController.text,
          'country': 'India',
        },
        'state': _selectedState,
        'pan': _panController.text,
        'tan': _tanController.text,
      };

      await PayrollApiService.updateCompanySettings(settings);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Company settings saved successfully!',
              style: TextStyle(
                color: Color(0xFF0071bf),
                fontWeight: FontWeight.w500,
              ),
            ),
            backgroundColor: Color(0xFF5cfbd8),
          ),
        );
        // Call success callback if provided (switch to Employees tab)
        widget.onSuccess?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error: $e',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _nextStep() {
    if (_currentStep < 1) {
      setState(() => _currentStep++);
    } else {
      _saveSettings();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              CircularProgressIndicator(color: Color(0xFF0071bf)),
              SizedBox(height: 16),
              Text('Loading company settings...'),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildProgressIndicator(),
        const SizedBox(height: 32),
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_currentStep == 0) _buildStep1(),
              if (_currentStep == 1) _buildStep2(),
            ],
          ),
        ),
        const SizedBox(height: 32),
        _buildNavigationButtons(),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildProgressIndicator() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Step ${_currentStep + 1} of 2: ${['Basic Information', 'Statutory Details'][_currentStep]}',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF272579),
          ),
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: (_currentStep + 1) / 2,
            minHeight: 8,
            backgroundColor: Colors.grey[300],
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0071bf)),
          ),
        ),
      ],
    );
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Company Details',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF272579),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _companyNameController,
          decoration: InputDecoration(
            labelText: 'Company Name *',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          validator: (value) =>
              value?.isEmpty ?? true ? 'Company name is required' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _streetController,
          decoration: InputDecoration(
            labelText: 'Street Address *',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          validator: (value) =>
              value?.isEmpty ?? true ? 'Address is required' : null,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _cityController,
                decoration: InputDecoration(
                  labelText: 'City *',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'City is required' : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _selectedState,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'State *',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                items: _indianStates
                    .map((state) => DropdownMenuItem(
                          value: state,
                          child: Text(
                            state,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() => _selectedState = value ?? 'Maharashtra');
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _pincodeController,
          decoration: InputDecoration(
            labelText: 'Pincode *',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          validator: (value) =>
              value?.isEmpty ?? true ? 'Pincode is required' : null,
        ),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Statutory Details',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF272579),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _panController,
          decoration: InputDecoration(
            labelText: 'PAN Number *',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          validator: (value) => value?.isEmpty ?? true ? 'PAN is required' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _tanController,
          decoration: InputDecoration(
            labelText: 'TAN Number *',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          validator: (value) => value?.isEmpty ?? true ? 'TAN is required' : null,
        ),
      ],
    );
  }


  Widget _buildNavigationButtons() {
    return Row(
      children: [
        if (_currentStep > 0)
          Expanded(
            child: OutlinedButton(
              onPressed: _previousStep,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF0071bf),
                side: const BorderSide(color: Color(0xFF0071bf), width: 2),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'Previous',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        if (_currentStep > 0) const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: _isSaving ? null : _nextStep,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0071bf),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              disabledBackgroundColor: Colors.grey,
            ),
            child: _isSaving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    _currentStep == 1 ? 'Save Settings' : 'Next',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _pincodeController.dispose();
    _panController.dispose();
    _tanController.dispose();
    super.dispose();
  }
}

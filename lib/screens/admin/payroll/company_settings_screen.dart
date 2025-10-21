import 'package:flutter/material.dart';
import '../../../services/payroll_api_service.dart';

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
  final _epfController = TextEditingController();
  final _esiController = TextEditingController();
  final _ptController = TextEditingController();
  final _signatoryNameController = TextEditingController();
  final _signatoryDesignationController = TextEditingController();
  final _basicPercentController = TextEditingController();
  final _hraPercentController = TextEditingController();
  final _daPercentController = TextEditingController();
  final _conveyancePercentController = TextEditingController();
  final _specialAllowancePercentController = TextEditingController();

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
    _initializeControllers();
  }

  void _initializeControllers() {
    _basicPercentController.text = '40';
    _hraPercentController.text = '30';
    _daPercentController.text = '10';
    _conveyancePercentController.text = '5';
    _specialAllowancePercentController.text = '15';
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    try {
      final settings = await PayrollApiService.getCompanySettings();
      setState(() {
        _companyNameController.text = settings['companyName'] ?? '';
        _streetController.text = settings['address']?['street'] ?? '';
        _cityController.text = settings['address']?['city'] ?? '';
        _selectedState = settings['address']?['state'] ?? 'Maharashtra';
        _pincodeController.text = settings['address']?['pincode'] ?? '';
        _panController.text = settings['pan'] ?? '';
        _tanController.text = settings['tan'] ?? '';
        _epfController.text = settings['epfNumber'] ?? '';
        _esiController.text = settings['esiNumber'] ?? '';
        _ptController.text = settings['ptRegistrationNumber'] ?? '';
        _signatoryNameController.text = settings['authorizedSignatory']?['name'] ?? '';
        _signatoryDesignationController.text =
            settings['authorizedSignatory']?['designation'] ?? '';

        final defaults = settings['defaultSalaryComponents'] ?? {};
        _basicPercentController.text = defaults['basicPercent']?.toString() ?? '40';
        _hraPercentController.text = defaults['hraPercent']?.toString() ?? '30';
        _daPercentController.text = defaults['daPercent']?.toString() ?? '10';
        _conveyancePercentController.text =
            defaults['conveyancePercent']?.toString() ?? '5';
        _specialAllowancePercentController.text =
            defaults['specialAllowancePercent']?.toString() ?? '15';
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
    _epfController.dispose();
    _esiController.dispose();
    _ptController.dispose();
    _signatoryNameController.dispose();
    _signatoryDesignationController.dispose();
    _basicPercentController.dispose();
    _hraPercentController.dispose();
    _daPercentController.dispose();
    _conveyancePercentController.dispose();
    _specialAllowancePercentController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 3) {
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
        'address': {
          'street': _streetController.text,
          'city': _cityController.text,
          'state': _selectedState,
          'pincode': _pincodeController.text,
          'country': 'India',
        },
        'pan': _panController.text,
        'tan': _tanController.text,
        'epfNumber': _epfController.text,
        'esiNumber': _esiController.text,
        'ptRegistrationNumber': _ptController.text,
        'authorizedSignatory': {
          'name': _signatoryNameController.text,
          'designation': _signatoryDesignationController.text,
        },
        'defaultSalaryComponents': {
          'basicPercent': int.parse(_basicPercentController.text),
          'hraPercent': int.parse(_hraPercentController.text),
          'daPercent': int.parse(_daPercentController.text),
          'conveyancePercent': int.parse(_conveyancePercentController.text),
          'specialAllowancePercent':
              int.parse(_specialAllowancePercentController.text),
        },
      };

      await PayrollApiService.updateCompanySettings(settings);
      if (mounted) {
        _showMessage('Company settings saved successfully!');
        Navigator.pop(context, true);
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
        content: Text(message),
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
                        _buildSignatoryStep(),
                        _buildSalaryDefaultsStep(),
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
            'Step ${_currentStep + 1} of 4: ${_getStepTitle()}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF272579),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(4, (index) {
              return Expanded(
                child: Container(
                  height: 4,
                  margin: EdgeInsets.only(right: index < 3 ? 8 : 0),
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
        return 'Tax Information';
      case 2:
        return 'Authorized Signatory';
      case 3:
        return 'Salary Defaults';
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
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _panController,
                    label: 'PAN Number',
                    hint: 'ABCDE1234F',
                    isRequired: true,
                    icon: Icons.badge,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(
                    controller: _tanController,
                    label: 'TAN Number',
                    hint: 'MUMB12345E',
                    isRequired: true,
                    icon: Icons.badge_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _epfController,
                    label: 'EPF Number',
                    hint: 'MH/MUM/1234567',
                    icon: Icons.account_balance,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(
                    controller: _esiController,
                    label: 'ESI Number',
                    hint: '12-34-567890',
                    icon: Icons.medical_services,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _ptController,
              label: 'PT Registration Number',
              hint: 'PT-1234567890',
              icon: Icons.receipt_long,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0071bf).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF0071bf).withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: Color(0xFF0071bf),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Professional Tax will be calculated based on state: $_selectedState',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF272579),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSignatoryStep() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionCard(
          title: 'Authorized Signatory',
          children: [
            _buildTextField(
              controller: _signatoryNameController,
              label: 'Signatory Name',
              hint: 'John Doe',
              isRequired: true,
              icon: Icons.person,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _signatoryDesignationController,
              label: 'Designation',
              hint: 'Director',
              isRequired: true,
              icon: Icons.work,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.cloud_upload, color: Color(0xFF0071bf)),
                      SizedBox(width: 8),
                      Text(
                        'Digital Signature Upload',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF272579),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Upload feature coming soon. Digital signature will be added to payslips.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSalaryDefaultsStep() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionCard(
          title: 'Default Salary Component Percentages',
          subtitle: 'These percentages will be used as default when creating salary structures',
          children: [
            _buildPercentField(
              controller: _basicPercentController,
              label: 'Basic Salary',
              icon: Icons.account_balance_wallet,
            ),
            const SizedBox(height: 16),
            _buildPercentField(
              controller: _hraPercentController,
              label: 'HRA (House Rent Allowance)',
              icon: Icons.home,
            ),
            const SizedBox(height: 16),
            _buildPercentField(
              controller: _daPercentController,
              label: 'DA (Dearness Allowance)',
              icon: Icons.payments,
            ),
            const SizedBox(height: 16),
            _buildPercentField(
              controller: _conveyancePercentController,
              label: 'Conveyance Allowance',
              icon: Icons.directions_car,
            ),
            const SizedBox(height: 16),
            _buildPercentField(
              controller: _specialAllowancePercentController,
              label: 'Special Allowance',
              icon: Icons.star,
            ),
            const SizedBox(height: 16),
            _buildTotalPercentage(),
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
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon != null ? Icon(icon, color: const Color(0xFF0071bf)) : null,
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
          child: Text(item),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildPercentField({
    required TextEditingController controller,
    required String label,
    IconData? icon,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        suffixText: '%',
        prefixIcon: icon != null ? Icon(icon, color: const Color(0xFF0071bf)) : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF0071bf), width: 2),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Required';
        }
        final percent = int.tryParse(value);
        if (percent == null || percent < 0 || percent > 100) {
          return 'Invalid percentage';
        }
        return null;
      },
    );
  }

  Widget _buildTotalPercentage() {
    final total = int.parse(_basicPercentController.text.isEmpty ? '0' : _basicPercentController.text) +
        int.parse(_hraPercentController.text.isEmpty ? '0' : _hraPercentController.text) +
        int.parse(_daPercentController.text.isEmpty ? '0' : _daPercentController.text) +
        int.parse(_conveyancePercentController.text.isEmpty ? '0' : _conveyancePercentController.text) +
        int.parse(_specialAllowancePercentController.text.isEmpty
            ? '0'
            : _specialAllowancePercentController.text);

    final isValid = total == 100;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isValid ? const Color(0xFF5cfbd8).withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isValid ? const Color(0xFF5cfbd8) : Colors.red,
          width: 2,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                isValid ? Icons.check_circle : Icons.error,
                color: isValid ? const Color(0xFF5cfbd8) : Colors.red,
              ),
              const SizedBox(width: 12),
              const Text(
                'Total Percentage',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF272579),
                ),
              ),
            ],
          ),
          Text(
            '$total%',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: isValid ? const Color(0xFF5cfbd8) : Colors.red,
            ),
          ),
        ],
      ),
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
                      _currentStep == 3 ? 'Save Settings' : 'Next',
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

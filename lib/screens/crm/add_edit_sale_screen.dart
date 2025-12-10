import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/crm_colors.dart';
import '../../models/customer.dart';
import '../../models/sale.dart';
import '../../services/api_service.dart';
import '../../widgets/crm/product_type_selector.dart';
import '../../utils/timezone_util.dart';

class AddEditSaleScreen extends StatefulWidget {
  final Sale? sale;

  const AddEditSaleScreen({
    super.key,
    this.sale,
  });

  @override
  State<AddEditSaleScreen> createState() => _AddEditSaleScreenState();
}

class _AddEditSaleScreenState extends State<AddEditSaleScreen> {
  late GlobalKey<FormState> _formKey;
  bool _isLoading = false;
  bool _isLoadingCustomers = false;

  // Customer selection
  Customer? _selectedCustomer;
  List<Customer> _customers = [];

  // Common fields
  late TextEditingController _customerNameController;
  late TextEditingController _mobileController;
  String? _selectedProductType;
  DateTime? _selectedDateOfSale;

  // Product-specific fields
  late TextEditingController _companyNameController;
  late TextEditingController _productPlanNameController;
  late TextEditingController _premiumAmountController;
  late TextEditingController _investmentAmountController;
  late TextEditingController _sipAmountController;
  String? _selectedPaymentFrequency;
  String? _selectedInvestmentType;

  // Notes
  late TextEditingController _notesController;

  // Employee selection
  // ignore: unused_field
  List<Employee> _availableEmployees = [];
  // ignore: unused_field
  List<String> _selectedEmployeeIds = [];
  // ignore: unused_field
  bool _loadingEmployees = false;

  @override
  void initState() {
    super.initState();
    _formKey = GlobalKey<FormState>();
    _initializeControllers();
    _loadEmployees();
    if (widget.sale != null) {
      _populateFormWithSaleData(widget.sale!);
    }
    _loadCustomers();
  }

  void _initializeControllers() {
    _customerNameController = TextEditingController();
    _mobileController = TextEditingController();
    _companyNameController = TextEditingController();
    _productPlanNameController = TextEditingController();
    _premiumAmountController = TextEditingController();
    _investmentAmountController = TextEditingController();
    _sipAmountController = TextEditingController();
    _notesController = TextEditingController();
  }

  void _populateFormWithSaleData(Sale sale) {
    final now = TimezoneUtil.nowIST();
    _selectedCustomer = Customer(
      id: sale.customerId,
      customerId: '',
      name: sale.customerName,
      mobileNumber: sale.mobileNumber,
      createdBy: '',
      createdAt: now,
      updatedAt: now,
    );
    _customerNameController.text = sale.customerName;
    _mobileController.text = sale.mobileNumber;
    _selectedProductType = sale.productType;
    _selectedDateOfSale = sale.dateOfSale;
    _companyNameController.text = sale.companyName;
    _productPlanNameController.text = sale.productPlanName;
    _selectedPaymentFrequency = sale.paymentFrequency;
    _selectedInvestmentType = sale.investmentType;
    _notesController.text = sale.notes ?? '';

    if (sale.premiumAmount != null) {
      _premiumAmountController.text = sale.premiumAmount.toString();
    }
    if (sale.investmentAmount != null) {
      _investmentAmountController.text = sale.investmentAmount.toString();
    }
    if (sale.sipAmount != null) {
      _sipAmountController.text = sale.sipAmount.toString();
    }

    // Populate selected employees if sale has assignedEmployees
    if (sale.assignedEmployees.isNotEmpty) {
      _selectedEmployeeIds = sale.assignedEmployees
          .map((emp) => emp.userId)
          .toList();
    }
  }

  Future<void> _loadCustomers() async {
    setState(() => _isLoadingCustomers = true);
    try {
      final response = await ApiService.getCustomers(limit: 100);
      if (response.success) {
        List<Customer> customers = [];

        // Handle both Map and List response formats
        if (response.data is Map<String, dynamic>) {
          final data = response.data as Map<String, dynamic>;
          customers = (data['data'] as List)
              .map((c) => Customer.fromJson(c as Map<String, dynamic>))
              .toList();
        } else if (response.data is List) {
          customers = (response.data as List)
              .map((c) => Customer.fromJson(c as Map<String, dynamic>))
              .toList();
        }

        setState(() => _customers = customers);
      }
    } catch (e) {
      _showError('Failed to load customers. Please try again.');
    } finally {
      setState(() => _isLoadingCustomers = false);
    }
  }

  Future<void> _loadEmployees() async {
    setState(() => _loadingEmployees = true);
    try {
      final response = await ApiService.get('/api/users?role=employee,field_staff,telecaller,manager');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final employees = (data['data'] as List)
            .map((e) => Employee(
                  id: e['_id'] ?? '',
                  firstName: e['firstName'] ?? '',
                  lastName: e['lastName'] ?? '',
                  email: e['email'],
                  phone: e['phone'],
                  role: e['role'],
                  branch: e['branch'],
                ))
            .toList();
        setState(() => _availableEmployees = employees);
      }
    } catch (e) {
      _showError('Failed to load employees: $e');
    } finally {
      setState(() => _loadingEmployees = false);
    }
  }

  Future<void> _createNewCustomer() async {
    if (_customerNameController.text.isEmpty || _mobileController.text.isEmpty) {
      _showError('Please enter customer name and mobile number');
      return;
    }

    try {
      final response = await ApiService.createCustomer(
        name: _customerNameController.text.trim(),
        mobileNumber: _mobileController.text.trim(),
      );

      if (mounted) {
        if (response.success) {
          final customerData = response.data as Map<String, dynamic>;
          setState(() {
            _selectedCustomer = Customer.fromJson(customerData);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Customer created successfully'),
              backgroundColor: CrmColors.successColor,
            ),
          );
        } else {
          _showError(response.message);
        }
      }
    } catch (e) {
      _showError('Failed to create customer: $e');
    }
  }

  Future<void> _selectDateOfSale() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDateOfSale ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() => _selectedDateOfSale = picked);
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedCustomer == null) {
      _showError('Please select or create a customer');
      return;
    }

    if (_selectedProductType == null) {
      _showError('Please select a product type');
      return;
    }

    if (_selectedDateOfSale == null) {
      _showError('Please select a date of sale');
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (widget.sale != null) {
        // Update existing sale
        final response = await ApiService.updateSale(
          saleId: widget.sale!.id,
          productType: _selectedProductType,
          dateOfSale: _selectedDateOfSale,
          companyName: _companyNameController.text.trim(),
          productPlanName: _productPlanNameController.text.trim(),
          premiumAmount:
              _premiumAmountController.text.isEmpty ? null : double.tryParse(_premiumAmountController.text),
          investmentAmount: _investmentAmountController.text.isEmpty
              ? null
              : double.tryParse(_investmentAmountController.text),
          sipAmount:
              _sipAmountController.text.isEmpty ? null : double.tryParse(_sipAmountController.text),
          paymentFrequency: _selectedPaymentFrequency,
          investmentType: _selectedInvestmentType,
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        );

        if (!mounted) return;

        if (response.success) {
          Navigator.of(context).pop(true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sale updated successfully'),
              backgroundColor: CrmColors.successColor,
            ),
          );
        } else {
          _showError(response.message);
        }
      } else {
        // Create new sale
        final response = await ApiService.createSale(
          customerId: _selectedCustomer!.id,
          productType: _selectedProductType!,
          dateOfSale: _selectedDateOfSale!,
          companyName: _companyNameController.text.trim(),
          productPlanName: _productPlanNameController.text.trim(),
          premiumAmount:
              _premiumAmountController.text.isEmpty ? null : double.tryParse(_premiumAmountController.text),
          investmentAmount: _investmentAmountController.text.isEmpty
              ? null
              : double.tryParse(_investmentAmountController.text),
          sipAmount:
              _sipAmountController.text.isEmpty ? null : double.tryParse(_sipAmountController.text),
          paymentFrequency: _selectedPaymentFrequency,
          investmentType: _selectedInvestmentType,
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        );

        if (!mounted) return;

        if (response.success) {
          Navigator.of(context).pop(true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sale created successfully'),
              backgroundColor: CrmColors.successColor,
            ),
          );
        } else {
          _showError(response.message);
        }
      }
    } catch (e) {
      _showError('Failed to save sale: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: CrmColors.errorColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          Navigator.of(context).pop(false);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.sale != null ? 'Edit Sale' : 'Add Sale'),
          backgroundColor: CrmColors.primary,
          elevation: 2,
        ),
        body: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Customer Selection Section
                    _buildSectionTitle('Customer Information'),
                    const SizedBox(height: 12),
                    _buildCustomerSelection(),
                    const SizedBox(height: 24),

                    // Product Type Selection
                    _buildSectionTitle('Product Details'),
                    const SizedBox(height: 12),
                    ProductTypeSelector(
                      selectedType: _selectedProductType,
                      onChanged: (type) {
                        setState(() {
                          _selectedProductType = type;
                          // Reset product-specific fields
                          _premiumAmountController.clear();
                          _investmentAmountController.clear();
                          _sipAmountController.clear();
                          _selectedPaymentFrequency = null;
                          _selectedInvestmentType = null;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Common Product Fields
                    TextFormField(
                      controller: _companyNameController,
                      decoration: InputDecoration(
                        labelText: _selectedProductType == 'mutual_funds'
                            ? 'Fund House *'
                            : 'Company Name (Insurer) *',
                        filled: true,
                        fillColor: CrmColors.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return _selectedProductType == 'mutual_funds'
                              ? 'Fund house is required'
                              : 'Company name is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _productPlanNameController,
                      decoration: InputDecoration(
                        labelText: _selectedProductType == 'mutual_funds'
                            ? 'Scheme Name *'
                            : 'Product / Plan Name *',
                        filled: true,
                        fillColor: CrmColors.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'Product name is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    // Date of Sale
                    TextFormField(
                      readOnly: true,
                      onTap: _selectDateOfSale,
                      decoration: InputDecoration(
                        labelText: 'Date of Sale *',
                        filled: true,
                        fillColor: CrmColors.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        suffixIcon: const Icon(Icons.calendar_today),
                      ),
                      controller: TextEditingController(
                        text: _selectedDateOfSale == null
                            ? ''
                            : DateFormat('dd MMM yyyy').format(_selectedDateOfSale!),
                      ),
                      validator: (value) {
                        if (_selectedDateOfSale == null) {
                          return 'Date of sale is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    // Product-Specific Fields
                    if (_selectedProductType == 'mutual_funds')
                      _buildMutualFundsFields()
                    else if (_selectedProductType != null)
                      _buildInsuranceFields(),

                    const SizedBox(height: 12),

                    // Notes
                    TextFormField(
                      controller: _notesController,
                      decoration: InputDecoration(
                        labelText: 'Notes (Optional)',
                        hintText: 'Add any additional notes about this sale',
                        filled: true,
                        fillColor: CrmColors.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      maxLines: 3,
                      minLines: 3,
                    ),
                    const SizedBox(height: 24),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: CrmColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(Colors.white),
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                widget.sale != null ? 'Update Sale' : 'Create Sale',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: CrmColors.textDark,
          ),
    );
  }

  Widget _buildCustomerSelection() {
    if (_selectedCustomer != null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: CrmColors.success.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: CrmColors.success.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedCustomer!.name,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: CrmColors.textDark,
                      ),
                ),
                Text(
                  _selectedCustomer!.mobileNumber,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: CrmColors.textLight,
                      ),
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.edit, color: CrmColors.primary),
              onPressed: () {
                setState(() => _selectedCustomer = null);
              },
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // New Customer Creation
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: CrmColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: CrmColors.borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Create New Customer',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: CrmColors.textLight,
                    ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _customerNameController,
                decoration: InputDecoration(
                  labelText: 'Customer Name *',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                validator: (value) {
                  if (_selectedCustomer == null && (value?.isEmpty ?? true)) {
                    return 'Customer name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _mobileController,
                decoration: InputDecoration(
                  labelText: 'Mobile Number *',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (_selectedCustomer == null && (value?.isEmpty ?? true)) {
                    return 'Mobile number is required';
                  }
                  if (_selectedCustomer == null && (value?.length ?? 0) < 10) {
                    return 'Mobile number must be at least 10 digits';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoadingCustomers ? null : _createNewCustomer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CrmColors.secondary,
                  ),
                  child: _isLoadingCustomers
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Create Customer'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Or select from existing customers:',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: CrmColors.textLight,
              ),
        ),
        const SizedBox(height: 12),
        if (_customers.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'No customers found. Create one above.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: CrmColors.textLight,
                    ),
              ),
            ),
          )
        else
          ...List.generate(
            _customers.length,
            (index) {
              final customer = _customers[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: CrmColors.borderColor),
                ),
                child: ListTile(
                  title: Text(customer.name),
                  subtitle: Text(customer.mobileNumber),
                  onTap: () {
                    setState(() => _selectedCustomer = customer);
                  },
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildInsuranceFields() {
    return Column(
      children: [
        TextFormField(
          controller: _premiumAmountController,
          decoration: InputDecoration(
            labelText: 'Premium Amount *',
            prefixText: '₹ ',
            filled: true,
            fillColor: CrmColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validator: (value) {
            if (value?.isEmpty ?? true) {
              return 'Premium amount is required';
            }
            if (double.tryParse(value!) == null) {
              return 'Please enter a valid amount';
            }
            if (double.parse(value) <= 0) {
              return 'Amount must be positive';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _selectedPaymentFrequency,
          decoration: InputDecoration(
            labelText: 'Payment Frequency *',
            filled: true,
            fillColor: CrmColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          items: ['daily', 'monthly', 'quarterly', 'half_yearly', 'yearly', 'single']
              .map(
                (frequency) => DropdownMenuItem(
                  value: frequency,
                  child: Text(_formatFrequency(frequency)),
                ),
              )
              .toList(),
          onChanged: (value) {
            setState(() => _selectedPaymentFrequency = value);
          },
          validator: (value) {
            if (value == null) {
              return 'Payment frequency is required';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildMutualFundsFields() {
    return Column(
      children: [
        DropdownButtonFormField<String>(
          initialValue: _selectedInvestmentType,
          decoration: InputDecoration(
            labelText: 'Investment Type *',
            filled: true,
            fillColor: CrmColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          items: ['sip', 'lumpsum']
              .map(
                (type) => DropdownMenuItem(
                  value: type,
                  child: Text(type == 'sip' ? 'SIP (Systematic Investment)' : 'Lumpsum'),
                ),
              )
              .toList(),
          onChanged: (value) {
            setState(() {
              _selectedInvestmentType = value;
              _sipAmountController.clear();
              _investmentAmountController.clear();
              _selectedPaymentFrequency = null;
            });
          },
          validator: (value) {
            if (value == null) {
              return 'Investment type is required';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        if (_selectedInvestmentType == 'sip') ...[
          TextFormField(
            controller: _sipAmountController,
            decoration: InputDecoration(
              labelText: 'SIP Amount *',
              prefixText: '₹ ',
              filled: true,
              fillColor: CrmColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return 'SIP amount is required';
              }
              if (double.tryParse(value!) == null) {
                return 'Please enter a valid amount';
              }
              if (double.parse(value) <= 0) {
                return 'Amount must be positive';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _selectedPaymentFrequency,
            decoration: InputDecoration(
              labelText: 'SIP Frequency *',
              filled: true,
              fillColor: CrmColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            items: ['monthly', 'quarterly', 'weekly']
                .map(
                  (frequency) => DropdownMenuItem(
                    value: frequency,
                    child: Text(_formatFrequency(frequency)),
                  ),
                )
                .toList(),
            onChanged: (value) {
              setState(() => _selectedPaymentFrequency = value);
            },
            validator: (value) {
              if (_selectedInvestmentType == 'sip' && value == null) {
                return 'SIP frequency is required';
              }
              return null;
            },
          ),
        ] else if (_selectedInvestmentType == 'lumpsum') ...[
          TextFormField(
            controller: _investmentAmountController,
            decoration: InputDecoration(
              labelText: 'Investment Amount *',
              prefixText: '₹ ',
              filled: true,
              fillColor: CrmColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return 'Investment amount is required';
              }
              if (double.tryParse(value!) == null) {
                return 'Please enter a valid amount';
              }
              if (double.parse(value) <= 0) {
                return 'Amount must be positive';
              }
              return null;
            },
          ),
        ],
      ],
    );
  }

  String _formatFrequency(String frequency) {
    switch (frequency) {
      case 'daily':
        return 'Daily';
      case 'monthly':
        return 'Monthly';
      case 'quarterly':
        return 'Quarterly';
      case 'half_yearly':
        return 'Half-Yearly';
      case 'yearly':
        return 'Yearly';
      case 'single':
        return 'Single';
      case 'weekly':
        return 'Weekly';
      default:
        return frequency;
    }
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _mobileController.dispose();
    _companyNameController.dispose();
    _productPlanNameController.dispose();
    _premiumAmountController.dispose();
    _investmentAmountController.dispose();
    _sipAmountController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}

class Employee {
  final String id;
  final String firstName;
  final String lastName;
  final String? email;
  final String? phone;
  final String? role;
  final String? branch;

  Employee({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.email,
    this.phone,
    this.role,
    this.branch,
  });

  String get fullName => '$firstName $lastName';
}

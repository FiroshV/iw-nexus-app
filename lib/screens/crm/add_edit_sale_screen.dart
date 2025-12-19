import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/crm_colors.dart';
import '../../models/customer.dart';
import '../../models/sale.dart';
import '../../models/sale_document.dart';
import '../../models/sale_extended_details.dart';
import '../../services/api_service.dart';
import '../../services/sale_service.dart';
import '../../widgets/crm/product_type_selector.dart';
import '../../widgets/crm/extended_sale_fields.dart';
import '../../utils/timezone_util.dart';

class AddEditSaleScreen extends StatefulWidget {
  final Sale? sale;

  const AddEditSaleScreen({super.key, this.sale});

  @override
  State<AddEditSaleScreen> createState() => _AddEditSaleScreenState();
}

class _AddEditSaleScreenState extends State<AddEditSaleScreen> {
  late GlobalKey<FormState> _formKey;
  bool _isLoading = false;
  // ignore: unused_field
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

  // Mutual Funds - Folio Number
  late TextEditingController _folioNumberController;

  // Insurance - Policy Details
  late TextEditingController _policyNumberController;
  DateTime? _selectedPolicyIssuanceDate;

  // Employee selection
  // ignore: unused_field
  List<Employee> _availableEmployees = [];
  // ignore: unused_field
  List<String> _selectedEmployeeIds = [];
  // ignore: unused_field
  bool _loadingEmployees = false;

  // Document upload state
  late List<PendingDocument> _pendingDocuments;
  late List<SaleDocument> _existingDocuments;
  late bool _isLoadingDocuments;

  // Extended fields state
  ProposerDetails? _proposerDetails;
  List<Nominee> _nominees = [];
  List<InsuredPerson> _insuredPersons = [];

  // Predefined document types
  final List<String> _predefinedDocTypes = [
    'KYC Documents',
    'Proposal Form',
    'Policy Copy',
    'Medical Reports',
    'ID Proof',
    'Address Proof',
    'Payment Receipt',
    'Other (Custom Name)',
  ];

  @override
  void initState() {
    super.initState();
    _formKey = GlobalKey<FormState>();
    _pendingDocuments = [];
    _existingDocuments = [];
    _isLoadingDocuments = false;
    _initializeControllers();
    _loadEmployees();
    if (widget.sale != null) {
      _populateFormWithSaleData(widget.sale!);
      _loadExistingDocuments();
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
    _folioNumberController = TextEditingController();
    _policyNumberController = TextEditingController();
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

    // Populate extended fields
    _proposerDetails = sale.proposerDetails;
    _nominees = List.from(sale.nominees);
    _insuredPersons = List.from(sale.insuredPersons);
    if (sale.mutualFundDetails?.folioNumber != null) {
      _folioNumberController.text = sale.mutualFundDetails!.folioNumber!;
    }
    // Populate policy details
    if (sale.policyDetails != null) {
      _policyNumberController.text = sale.policyDetails!.policyNumber ?? '';
      _selectedPolicyIssuanceDate = sale.policyDetails!.policyIssuanceDate;
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
      final response = await ApiService.get(
        '/api/users?role=employee,field_staff,telecaller,manager',
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final employees = (data['data'] as List)
            .map(
              (e) => Employee(
                id: e['_id'] ?? '',
                firstName: e['firstName'] ?? '',
                lastName: e['lastName'] ?? '',
                email: e['email'],
                phone: e['phone'],
                role: e['role'],
                branch: e['branch'],
              ),
            )
            .toList();
        setState(() => _availableEmployees = employees);
      }
    } catch (e) {
      _showError('Failed to load employees: $e');
    } finally {
      setState(() => _loadingEmployees = false);
    }
  }

  // Document methods

  Future<void> _loadExistingDocuments() async {
    if (widget.sale == null) return;

    setState(() => _isLoadingDocuments = true);

    try {
      final response = await SaleService.getSaleDocuments(widget.sale!.id);
      if (response.success && response.data != null) {
        setState(() => _existingDocuments = response.data!);
      }
    } catch (e) {
      debugPrint('Error loading documents: $e');
    } finally {
      setState(() => _isLoadingDocuments = false);
    }
  }

  Future<void> _deleteExistingDocument(String documentId) async {
    if (widget.sale == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Document'),
        content: const Text('Are you sure you want to delete this document?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final response = await SaleService.deleteSaleDocument(
        widget.sale!.id,
        documentId,
      );

      if (!mounted) return;

      if (response.success) {
        setState(() {
          _existingDocuments.removeWhere((doc) => doc.id == documentId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Document deleted successfully')),
        );
      } else {
        _showError(response.message ?? 'Failed to delete document');
      }
    } catch (e) {
      _showError('Error deleting document: $e');
    }
  }

  Future<String?> _showDocumentTypeBottomSheet() async {
    final localCustomNameController = TextEditingController();

    return showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Title
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'Select Document Type',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF272579),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Predefined document types list (excluding "Other")
                ...(_predefinedDocTypes
                    .where((type) => type != 'Other (Custom Name)')
                    .map((docType) {
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        title: Text(
                          docType,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                        leading: Icon(
                          Icons.radio_button_unchecked,
                          color: const Color(0xFF0071bf),
                        ),
                        onTap: () {
                          Navigator.pop(context, docType);
                        },
                      );
                    })),

                const SizedBox(height: 16),

                // Divider
                const Divider(),

                const SizedBox(height: 8),

                // Custom name section
                const Text(
                  'Or Enter Custom Name',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF272579),
                  ),
                ),
                const SizedBox(height: 12),

                // Custom name text field
                TextField(
                  controller: localCustomNameController,
                  decoration: InputDecoration(
                    hintText: 'Enter document name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(
                      Icons.edit,
                      color: Color(0xFF0071bf),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 12),

                // Use custom name button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      final customName = localCustomNameController.text.trim();
                      if (customName.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please enter a document name'),
                          ),
                        );
                        return;
                      }
                      Navigator.pop(context, customName);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0071bf),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'Use Custom Name',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickDocument() async {
    final selectedDocType = await _showDocumentTypeBottomSheet();

    if (selectedDocType == null || selectedDocType.isEmpty) {
      return;
    }

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png', 'txt'],
      allowMultiple: false,
    );

    if (result == null || result.files.isEmpty) {
      return;
    }

    final file = File(result.files.single.path!);
    final fileSize = await file.length();

    if (fileSize > 10 * 1024 * 1024) {
      _showError('File size exceeds 10MB limit');
      return;
    }

    // Always add to pending documents (both create and edit mode)
    setState(() {
      _pendingDocuments.add(
        PendingDocument(
          file: file,
          documentName: selectedDocType,
          documentType: _predefinedDocTypes.contains(selectedDocType)
              ? selectedDocType
              : 'Other',
        ),
      );
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${result.files.single.name} added')),
    );
  }

  void _removePendingDocument(int index) {
    setState(() {
      _pendingDocuments.removeAt(index);
    });
  }

  void _showCustomerBottomSheet() {
    List<Customer> filteredCustomers = _customers;
    final TextEditingController searchController = TextEditingController();

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
                      Text(
                        'Select Customer',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: CrmColors.textDark,
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
                    vertical: 12,
                  ),
                  child: TextField(
                    controller: searchController,
                    onChanged: (query) {
                      setModalState(() {
                        if (query.isEmpty) {
                          filteredCustomers = _customers;
                        } else {
                          final lowerQuery = query.toLowerCase();
                          filteredCustomers = _customers.where((customer) {
                            final name = customer.name.toLowerCase();
                            final mobile = customer.mobileNumber.toLowerCase();
                            return name.contains(lowerQuery) ||
                                mobile.contains(lowerQuery);
                          }).toList();
                        }
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search by name or phone...',
                      prefixIcon: const Icon(
                        Icons.search,
                        color: CrmColors.primary,
                      ),
                      suffixIcon: searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                searchController.clear();
                                setModalState(() {
                                  filteredCustomers = _customers;
                                });
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: CrmColors.surface,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                // Customer list
                Expanded(
                  child: _isLoadingCustomers
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF0071bf),
                          ),
                        )
                      : filteredCustomers.isEmpty
                      ? Center(
                          child: Text(
                            'No customers found',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: CrmColors.textLight),
                          ),
                        )
                      : ListView.separated(
                          controller: scrollController,
                          itemCount: filteredCustomers.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final customer = filteredCustomers[index];
                            final isSelected =
                                _selectedCustomer?.id == customer.id;
                            return ListTile(
                              onTap: () {
                                setState(() => _selectedCustomer = customer);
                                Navigator.pop(context);
                              },
                              title: Text(customer.name),
                              subtitle: Text(customer.mobileNumber),
                              trailing: isSelected
                                  ? const Icon(
                                      Icons.check_circle,
                                      color: CrmColors.primary,
                                    )
                                  : null,
                              selected: isSelected,
                              selectedTileColor: CrmColors.primary.withValues(
                                alpha: 0.1,
                              ),
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

  void _showPaymentFrequencyBottomSheet(List<String> frequencies) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Select Payment Frequency',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: CrmColors.textDark,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: CrmColors.textLight),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Frequency options
              ...frequencies.map((frequency) {
                final isSelected = _selectedPaymentFrequency == frequency;
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedPaymentFrequency = frequency);
                    Navigator.pop(context);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? CrmColors.primary.withValues(alpha: 0.1)
                          : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? CrmColors.primary
                            : Colors.grey.shade200,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            _formatFrequency(frequency),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: CrmColors.textDark,
                            ),
                          ),
                        ),
                        if (isSelected)
                          const Icon(
                            Icons.check_circle,
                            color: CrmColors.primary,
                            size: 24,
                          ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  void _showInvestmentTypeBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Select Investment Type',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: CrmColors.textDark,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: CrmColors.textLight),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Investment type options
              ...['sip', 'lumpsum'].map((type) {
                final isSelected = _selectedInvestmentType == type;
                final label = type == 'sip'
                    ? 'SIP (Systematic Investment)'
                    : 'Lumpsum';
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedInvestmentType = type;
                      _sipAmountController.clear();
                      _investmentAmountController.clear();
                      _selectedPaymentFrequency = null;
                    });
                    Navigator.pop(context);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? CrmColors.primary.withValues(alpha: 0.1)
                          : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? CrmColors.primary
                            : Colors.grey.shade200,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            label,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: CrmColors.textDark,
                            ),
                          ),
                        ),
                        if (isSelected)
                          const Icon(
                            Icons.check_circle,
                            color: CrmColors.primary,
                            size: 24,
                          ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
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
      _showError('Please select a customer');
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

    // Validate payment frequency for insurance
    if ((_selectedProductType == 'life_insurance' ||
            _selectedProductType == 'general_insurance') &&
        _selectedPaymentFrequency == null) {
      _showError('Please select a payment frequency');
      return;
    }

    // Validate investment type and frequency for mutual funds
    if (_selectedProductType == 'mutual_funds') {
      if (_selectedInvestmentType == null) {
        _showError('Please select an investment type');
        return;
      }
      if (_selectedInvestmentType == 'sip' &&
          _selectedPaymentFrequency == null) {
        _showError('Please select a SIP frequency');
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      if (widget.sale != null) {
        // Update existing sale with documents
        final response = await ApiService.updateSale(
          saleId: widget.sale!.id,
          productType: _selectedProductType,
          dateOfSale: _selectedDateOfSale,
          companyName: _companyNameController.text.trim(),
          productPlanName: _productPlanNameController.text.trim(),
          premiumAmount: _premiumAmountController.text.isEmpty
              ? null
              : double.tryParse(_premiumAmountController.text),
          investmentAmount: _investmentAmountController.text.isEmpty
              ? null
              : double.tryParse(_investmentAmountController.text),
          sipAmount: _sipAmountController.text.isEmpty
              ? null
              : double.tryParse(_sipAmountController.text),
          paymentFrequency: _selectedPaymentFrequency,
          investmentType: _selectedInvestmentType,
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
          documents: _pendingDocuments.isNotEmpty ? _pendingDocuments : null,
          policyDetails:
              (_selectedProductType == 'life_insurance' ||
                  _selectedProductType == 'general_insurance')
              ? PolicyDetails(
                  policyNumber: _policyNumberController.text.isEmpty
                      ? null
                      : _policyNumberController.text,
                  policyIssuanceDate: _selectedPolicyIssuanceDate,
                )
              : null,
          proposerDetails: _proposerDetails,
          nominees: _nominees,
          insuredPersons: _insuredPersons,
          mutualFundDetails:
              _selectedProductType == 'mutual_funds' &&
                  _folioNumberController.text.isNotEmpty
              ? MutualFundDetails(folioNumber: _folioNumberController.text)
              : null,
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
        // Create new sale with documents
        final response = await ApiService.createSale(
          customerId: _selectedCustomer!.id,
          productType: _selectedProductType!,
          dateOfSale: _selectedDateOfSale!,
          companyName: _companyNameController.text.trim(),
          productPlanName: _productPlanNameController.text.trim(),
          premiumAmount: _premiumAmountController.text.isEmpty
              ? null
              : double.tryParse(_premiumAmountController.text),
          investmentAmount: _investmentAmountController.text.isEmpty
              ? null
              : double.tryParse(_investmentAmountController.text),
          sipAmount: _sipAmountController.text.isEmpty
              ? null
              : double.tryParse(_sipAmountController.text),
          paymentFrequency: _selectedPaymentFrequency,
          investmentType: _selectedInvestmentType,
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
          documents: _pendingDocuments.isNotEmpty ? _pendingDocuments : null,
          policyDetails:
              (_selectedProductType == 'life_insurance' ||
                  _selectedProductType == 'general_insurance')
              ? PolicyDetails(
                  policyNumber: _policyNumberController.text.isEmpty
                      ? null
                      : _policyNumberController.text,
                  policyIssuanceDate: _selectedPolicyIssuanceDate,
                )
              : null,
          proposerDetails: _proposerDetails,
          nominees: _nominees,
          insuredPersons: _insuredPersons,
          mutualFundDetails:
              _selectedProductType == 'mutual_funds' &&
                  _folioNumberController.text.isNotEmpty
              ? MutualFundDetails(folioNumber: _folioNumberController.text)
              : null,
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
      SnackBar(content: Text(message), backgroundColor: CrmColors.errorColor),
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
                          _folioNumberController.clear();
                          _policyNumberController.clear();
                          _selectedPolicyIssuanceDate = null;
                          _selectedPaymentFrequency = null;
                          _selectedInvestmentType = null;
                          // Reset extended fields
                          _proposerDetails = null;
                          _nominees = [];
                          _insuredPersons = [];
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    // Product-Specific Fields
                    if (_selectedProductType == 'mutual_funds')
                      _buildMutualFundsFields()
                    else if (_selectedProductType != null)
                      _buildInsuranceFields(),

                    const SizedBox(height: 12),
                    // Common Product Fields
                    TextFormField(
                      controller: _companyNameController,
                      decoration: InputDecoration(
                        labelText: _selectedProductType == 'mutual_funds'
                            ? 'AMC Name *'
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
                              ? 'AMC name is required'
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
                            : DateFormat(
                                'dd MMM yyyy',
                              ).format(_selectedDateOfSale!),
                      ),
                      validator: (value) {
                        if (_selectedDateOfSale == null) {
                          return 'Date of sale is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    if (_selectedProductType == 'mutual_funds')
                      // Investment Type Bottom Sheet
                      GestureDetector(
                        onTap: _showInvestmentTypeBottomSheet,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: CrmColors.borderColor),
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.white,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _selectedInvestmentType != null
                                    ? (_selectedInvestmentType == 'sip'
                                          ? 'SIP (Systematic Investment)'
                                          : 'Lumpsum')
                                    : 'Select investment type...',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: _selectedInvestmentType != null
                                      ? CrmColors.textDark
                                      : CrmColors.textLight,
                                ),
                              ),
                              Icon(Icons.expand_more, color: CrmColors.primary),
                            ],
                          ),
                        ),
                      ),

                    // Validation for investment type
                    if (_selectedInvestmentType == null &&
                        _selectedProductType == 'mutual_funds')
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Investment type is required',
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),

                    if (_selectedInvestmentType == 'sip') ...[
                      // SIP Frequency Bottom Sheet
                      GestureDetector(
                        onTap: () => _showPaymentFrequencyBottomSheet([
                          'daily',
                          'monthly',
                          'quarterly',
                          'half_yearly',
                          'yearly',
                        ]),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: CrmColors.borderColor),
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.white,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _selectedPaymentFrequency != null
                                    ? _formatFrequency(
                                        _selectedPaymentFrequency!,
                                      )
                                    : 'Select SIP frequency...',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: _selectedPaymentFrequency != null
                                      ? CrmColors.textDark
                                      : CrmColors.textLight,
                                ),
                              ),
                              Icon(Icons.expand_more, color: CrmColors.primary),
                            ],
                          ),
                        ),
                      ),
                      // Validation for SIP frequency
                      if (_selectedPaymentFrequency == null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'SIP frequency is required',
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      const SizedBox(height: 12),
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
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
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
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
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

                    // Extended Fields - Proposer/Insured/Nominees (Insurance only)
                    if (_selectedProductType == 'life_insurance' ||
                        _selectedProductType == 'general_insurance') ...[
                      ProposerDetailsSection(
                        initialData: _proposerDetails,
                        onChanged: (details) {
                          setState(() => _proposerDetails = details);
                        },
                      ),
                      const SizedBox(height: 12),
                      InsuredPersonsSection(
                        insuredPersons: _insuredPersons,
                        onChanged: (persons) {
                          setState(() => _insuredPersons = persons);
                        },
                      ),
                      const SizedBox(height: 12),
                      NomineesSection(
                        nominees: _nominees,
                        onChanged: (nominees) {
                          setState(() => _nominees = nominees);
                        },
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Extended Fields (Mutual Funds only)
                    if (_selectedProductType == 'mutual_funds') ...[
                      NomineesSection(
                        nominees: _nominees,
                        onChanged: (nominees) {
                          setState(() => _nominees = nominees);
                        },
                      ),
                      const SizedBox(height: 12),
                    ],

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

                    // Documents Section
                    _buildSectionTitle('Documents (Optional)'),
                    const SizedBox(height: 12),

                    // Document upload card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: CrmColors.borderColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Upload button
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _isLoading ? null : _pickDocument,
                              icon: const Icon(
                                Icons.add,
                                color: Color(0xFF0071bf),
                              ),
                              label: const Text('Add Document'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                side: const BorderSide(
                                  color: Color(0xFF0071bf),
                                ),
                              ),
                            ),
                          ),

                          // Existing documents (edit mode only)
                          if (widget.sale != null &&
                              _existingDocuments.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            const Divider(),
                            const SizedBox(height: 8),
                            const Text(
                              'Existing Documents',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF272579),
                              ),
                            ),
                            const SizedBox(height: 8),
                            ...List.generate(_existingDocuments.length, (
                              index,
                            ) {
                              final doc = _existingDocuments[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  leading: const Icon(
                                    Icons.description,
                                    color: Color(0xFF0071bf),
                                  ),
                                  title: Text(
                                    doc.documentName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  subtitle: Text(
                                    doc.originalFileName,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    onPressed: () =>
                                        _deleteExistingDocument(doc.id),
                                  ),
                                ),
                              );
                            }),
                          ],

                          // Pending documents list (create mode only)
                          if (widget.sale == null &&
                              _pendingDocuments.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            const Divider(),
                            const SizedBox(height: 8),
                            const Text(
                              'Documents to Upload',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF272579),
                              ),
                            ),
                            const SizedBox(height: 8),
                            ...List.generate(_pendingDocuments.length, (index) {
                              final doc = _pendingDocuments[index];
                              final fileName = doc.file.path.split('/').last;
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  leading: const Icon(
                                    Icons.description,
                                    color: Color(0xFF0071bf),
                                  ),
                                  title: Text(
                                    doc.documentName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  subtitle: Text(
                                    fileName,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    onPressed: () =>
                                        _removePendingDocument(index),
                                  ),
                                ),
                              );
                            }),
                          ],

                          // Info text (create mode only)
                          if (widget.sale == null &&
                              _pendingDocuments.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Documents will be uploaded after sale is created',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],

                          // Loading indicator
                          if (_isLoadingDocuments)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: CircularProgressIndicator(),
                              ),
                            ),
                        ],
                      ),
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
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                widget.sale != null
                                    ? 'Update Sale'
                                    : 'Create Sale',
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
    return GestureDetector(
      onTap: _showCustomerBottomSheet,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: CrmColors.borderColor),
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _selectedCustomer?.name ?? 'Select customer...',
              style: TextStyle(
                fontSize: 14,
                color: _selectedCustomer != null
                    ? CrmColors.textDark
                    : CrmColors.textLight,
              ),
            ),
            Icon(Icons.expand_more, color: CrmColors.primary),
          ],
        ),
      ),
    );
  }

  Widget _buildInsuranceFields() {
    return Column(
      children: [
        // ============= POLICY NUMBER (FIRST FIELD) =============
        TextFormField(
          controller: _policyNumberController,
          decoration: InputDecoration(
            labelText: 'Policy Number',
            hintText: 'Enter policy number',
            filled: true,
            fillColor: CrmColors.surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 12),

        // ============= POLICY ISSUANCE DATE (SECOND FIELD) =============
        TextFormField(
          readOnly: true,
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: _selectedPolicyIssuanceDate ?? DateTime.now(),
              firstDate: DateTime(1900),
              lastDate: DateTime.now(),
            );
            if (date != null) {
              setState(() => _selectedPolicyIssuanceDate = date);
            }
          },
          decoration: InputDecoration(
            labelText: 'Policy Issuance Date',
            hintText: 'Select date',
            filled: true,
            fillColor: CrmColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            suffixIcon: Icon(Icons.calendar_today, color: CrmColors.primary),
          ),
          controller: TextEditingController(
            text: _selectedPolicyIssuanceDate != null
                ? DateFormat(
                    'dd MMM yyyy',
                  ).format(_selectedPolicyIssuanceDate!)
                : '',
          ),
        ),
        const SizedBox(height: 12),

        // ============= PREMIUM AMOUNT FIELD =============
        TextFormField(
          controller: _premiumAmountController,
          decoration: InputDecoration(
            labelText: 'Premium Amount *',
            prefixText: '₹ ',
            filled: true,
            fillColor: CrmColors.surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
        // Payment Frequency Bottom Sheet
        GestureDetector(
          onTap: () => _showPaymentFrequencyBottomSheet([
            'daily',
            'monthly',
            'quarterly',
            'half_yearly',
            'yearly',
            'single',
          ]),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: CrmColors.borderColor),
              borderRadius: BorderRadius.circular(12),
              color: Colors.white,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedPaymentFrequency != null
                      ? _formatFrequency(_selectedPaymentFrequency!)
                      : 'Select frequency...',
                  style: TextStyle(
                    fontSize: 14,
                    color: _selectedPaymentFrequency != null
                        ? CrmColors.textDark
                        : CrmColors.textLight,
                  ),
                ),
                Icon(Icons.expand_more, color: CrmColors.primary),
              ],
            ),
          ),
        ),
        // Validation for payment frequency
        if (_selectedPaymentFrequency == null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Payment frequency is required',
              style: TextStyle(color: Colors.red.shade700, fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _buildMutualFundsFields() {
    return Column(
      children: [
        // Folio Number FIRST
        TextFormField(
          controller: _folioNumberController,
          decoration: InputDecoration(
            labelText: 'Folio Number',
            hintText: 'Enter folio number',
            filled: true,
            fillColor: CrmColors.surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 12),
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
    _folioNumberController.dispose();
    _policyNumberController.dispose();
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

class PendingDocument {
  final File file;
  final String documentName;
  final String documentType;

  PendingDocument({
    required this.file,
    required this.documentName,
    required this.documentType,
  });
}

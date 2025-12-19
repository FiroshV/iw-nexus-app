import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/sale.dart';
import '../../models/sale_document.dart';
import '../../services/sale_service.dart';
import '../../providers/crm/sale_provider.dart';
import '../../services/access_control_service.dart';
import '../../services/api_service.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/crm_design_system.dart';
import '../../config/crm_colors.dart';

class SaleDetailsScreen extends StatefulWidget {
  final String saleId;
  final String userId;
  final String userRole;

  const SaleDetailsScreen({
    super.key,
    required this.saleId,
    required this.userId,
    required this.userRole,
  });

  @override
  State<SaleDetailsScreen> createState() => _SaleDetailsScreenState();
}

class _SaleDetailsScreenState extends State<SaleDetailsScreen>
    with TickerProviderStateMixin {
  Sale? _sale;
  List<SaleDocument> _documents = [];
  bool _isLoadingSale = true;
  bool _isLoadingDocuments = true;
  bool _isUploadingDocument = false;
  String? _error;
  late TabController _tabController;

  String? _selectedDocumentType;
  final TextEditingController _customDocNameController =
      TextEditingController();

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
    _tabController = TabController(length: 2, vsync: this);
    _loadSaleDetails();
    _loadDocuments();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _customDocNameController.dispose();
    super.dispose();
  }

  Future<void> _loadSaleDetails() async {
    setState(() {
      _isLoadingSale = true;
      _error = null;
    });

    try {
      final response = await SaleService.getSale(widget.saleId);
      if (response.success && response.data != null) {
        setState(() => _sale = response.data);
      } else {
        setState(
          () => _error = response.message ?? 'Failed to load sale details',
        );
      }
    } catch (e) {
      setState(() => _error = 'Error: $e');
    } finally {
      setState(() => _isLoadingSale = false);
    }
  }

  Future<void> _loadDocuments() async {
    setState(() {
      _isLoadingDocuments = true;
    });

    try {
      final response = await SaleService.getSaleDocuments(widget.saleId);
      if (response.success && response.data != null) {
        setState(() => _documents = response.data!);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading documents: $e')));
      }
    } finally {
      setState(() => _isLoadingDocuments = false);
    }
  }

  Future<void> _pickAndUploadDocument() async {
    try {
      // Validate document type is selected
      if (_selectedDocumentType == null || _selectedDocumentType!.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please select or enter a document type'),
            ),
          );
        }
        return;
      }

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png', 'txt'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        return; // User cancelled
      }

      final file = File(result.files.single.path!);
      final fileSize = await file.length();

      // Validate file size (10MB)
      if (fileSize > 10 * 1024 * 1024) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('File size exceeds 10MB limit')),
          );
        }
        return;
      }

      // Get document name
      String documentName = _selectedDocumentType!;

      // Determine document type for backend
      String docType = _predefinedDocTypes.contains(_selectedDocumentType)
          ? _selectedDocumentType!
          : 'Other';

      await _uploadDocument(file, documentName, docType);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _uploadDocument(
    File file,
    String documentName,
    String documentType,
  ) async {
    setState(() => _isUploadingDocument = true);

    try {
      final response = await SaleService.uploadSaleDocument(
        widget.saleId,
        file,
        documentName: documentName,
        documentType: documentType,
      );

      if (!mounted) return;

      if (response.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Document uploaded successfully')),
        );

        // Reset form
        _customDocNameController.clear();
        setState(() => _selectedDocumentType = null);

        // Reload documents
        await _loadDocuments();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message ?? 'Failed to upload document'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Upload error: $e')));
      }
    } finally {
      setState(() => _isUploadingDocument = false);
    }
  }

  Future<void> _deleteDocument(String documentId) async {
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
        widget.saleId,
        documentId,
      );

      if (!mounted) return;

      if (response.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Document deleted successfully')),
        );
        await _loadDocuments();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message ?? 'Failed to delete document'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  bool _canAccessDocuments() {
    // Admin/director/manager always have access
    if (['admin', 'director', 'manager'].contains(widget.userRole)) {
      return true;
    }

    if (_sale == null) return false;

    // Sale owner has access
    if (_sale!.userId == widget.userId) {
      return true;
    }

    // Assigned employees have access
    return _sale!.assignedEmployees.any((emp) => emp.userId == widget.userId);
  }

  bool _canEditSale() {
    // Admin/director can edit all sales
    if (['admin', 'director'].contains(widget.userRole)) {
      return true;
    }

    if (_sale == null) return false;

    // Sale creator can edit
    if (_sale!.userId == widget.userId) {
      return true;
    }

    // Managers can edit sales in their branch
    if (widget.userRole == 'manager') {
      return true;
    }

    return false;
  }

  bool _canDeleteSale() {
    // Admin/director can delete all sales
    if (['admin', 'director'].contains(widget.userRole)) {
      return true;
    }

    if (_sale == null) return false;

    // Sale creator can delete
    if (_sale!.userId == widget.userId) {
      return true;
    }

    return false;
  }

  void _editSale() {
    if (_sale == null) return;

    Navigator.of(context)
        .pushNamed(
          '/crm/add-edit-sale',
          arguments: {
            'userId': widget.userId,
            'userRole': widget.userRole,
            'saleId': widget.saleId,
            'sale': _sale,
          },
        )
        .then((result) {
          if (result == true && mounted) {
            // Refresh sale details
            _loadSaleDetails();

            // Invalidate cache
            try {
              context.read<SaleProvider>().invalidateAll();
            } catch (e) {
              // Provider might not be available
            }
          }
        });
  }

  Future<void> _confirmAndDeleteSale() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Sale'),
        content: Text(
          'Are you sure you want to delete this sale for ${_sale?.customerName ?? 'this customer'}?',
        ),
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

    await _deleteSale();
  }

  Future<void> _deleteSale() async {
    try {
      final response = await ApiService.deleteSale(widget.saleId);

      if (!mounted) return;

      if (response.success) {
        // Invalidate cache
        try {
          context.read<SaleProvider>().invalidateAll();
        } catch (e) {
          // Provider might not be available
        }

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sale deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate back to sales list
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message ?? 'Failed to delete sale'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _downloadDocument(SaleDocument document) async {
    final url = SaleService.getSaleDocumentDownloadUrl(
      widget.saleId,
      document.id,
    );
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open document')),
        );
      }
    }
  }

  void _showDocumentTypeBottomSheet() {
    final localCustomNameController = TextEditingController();

    showModalBottomSheet(
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
                      final isSelected = _selectedDocumentType == docType;
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        title: Text(
                          docType,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w500,
                            color: isSelected
                                ? const Color(0xFF0071bf)
                                : Colors.black87,
                          ),
                        ),
                        leading: Icon(
                          isSelected
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                          color: const Color(0xFF0071bf),
                        ),
                        onTap: () {
                          setState(() {
                            _selectedDocumentType = docType;
                            _customDocNameController.clear();
                          });
                          Navigator.pop(context);
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
                      setState(() {
                        _selectedDocumentType = customName;
                        _customDocNameController.text = customName;
                      });
                      Navigator.pop(context);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Sale Details',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF0071bf),
        elevation: 2,
        shadowColor: const Color(0xFF0071bf).withValues(alpha: 0.3),
        actions: [
          // Edit button
          if (_canEditSale())
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.white),
              onPressed: _editSale,
              tooltip: 'Edit Sale',
            ),
          // Delete button
          if (_canDeleteSale())
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.white),
              onPressed: _confirmAndDeleteSale,
              tooltip: 'Delete Sale',
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: const Color(0xFF5cfbd8),
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Sale Info'),
            Tab(text: 'Documents'),
          ],
        ),
      ),
      backgroundColor: const Color(0xFFf8f9fa),
      body: _isLoadingSale
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0071bf)),
              ),
            )
          : _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(_error!),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadSaleDetails,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0071bf),
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Sale Info
                _buildSaleInfoTab(),
                // Tab 2: Documents
                _buildDocumentsTab(),
              ],
            ),
    );
  }

  Widget _buildSaleInfoTab() {
    if (_sale == null) {
      return const Center(child: Text('Sale not found'));
    }

    final sale = _sale!;
    final dateFormat = DateFormat('dd MMM yyyy');
    final productColor = CrmColors.getProductTypeColor(sale.productType);
    final productName = CrmColors.getProductTypeName(sale.productType);

    return SingleChildScrollView(
      padding: EdgeInsets.all(CrmDesignSystem.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sale Header with product type color
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(CrmDesignSystem.xl),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.black, productColor.withValues(alpha: 0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(CrmDesignSystem.radiusLarge),
              boxShadow: CrmDesignSystem.elevationMedium,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sale.saleId,
                  style: CrmDesignSystem.headlineMedium.copyWith(
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: CrmDesignSystem.sm),
                Text(
                  sale.customerName,
                  style: CrmDesignSystem.bodyLarge.copyWith(
                    color: Colors.white70,
                  ),
                ),
                SizedBox(height: CrmDesignSystem.md),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: CrmDesignSystem.md,
                    vertical: CrmDesignSystem.sm,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(
                      CrmDesignSystem.radiusMedium,
                    ),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    productName,
                    style: CrmDesignSystem.labelMedium.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: CrmDesignSystem.xl),

          // Customer Section
          _buildSectionHeaderWithIcon(
            'Customer Details',
            Icons.person,
            CrmColors.primary,
          ),
          SizedBox(height: CrmDesignSystem.md),
          Container(
            padding: EdgeInsets.all(CrmDesignSystem.lg),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(CrmDesignSystem.radiusLarge),
              border: Border.all(
                color: CrmColors.primary.withValues(alpha: 0.15),
              ),
              boxShadow: CrmDesignSystem.elevationSmall,
            ),
            child: Column(
              children: [
                _buildDetailRowWithIcon(
                  label: 'Customer Name',
                  value: sale.customerName,
                  icon: Icons.person_outline,
                  iconColor: CrmColors.primary,
                ),
                _buildDetailRowWithIcon(
                  label: 'Mobile Number',
                  value: sale.mobileNumber,
                  icon: Icons.phone_outlined,
                  iconColor: CrmColors.secondary,
                ),
              ],
            ),
          ),
          SizedBox(height: CrmDesignSystem.xl),

          // Product Section
          _buildSectionHeaderWithIcon(
            'Product Information',
            Icons.shopping_bag,
            CrmColors.primary,
          ),
          SizedBox(height: CrmDesignSystem.md),
          Container(
            padding: EdgeInsets.all(CrmDesignSystem.lg),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(CrmDesignSystem.radiusLarge),
              border: Border.all(color: productColor.withValues(alpha: 0.2)),
              boxShadow: CrmDesignSystem.elevationSmall,
            ),
            child: Column(
              children: [
                _buildDetailRowWithIcon(
                  label: 'Product Type',
                  value: productName,
                  icon: Icons.category_outlined,
                  iconColor: productColor,
                ),
                _buildDetailRowWithIcon(
                  label: 'Company',
                  value: sale.companyName,
                  icon: Icons.business_outlined,
                  iconColor: productColor,
                ),
                _buildDetailRowWithIcon(
                  label: 'Product Plan',
                  value: sale.productPlanName,
                  icon: Icons.description_outlined,
                  iconColor: productColor,
                ),
              ],
            ),
          ),
          SizedBox(height: CrmDesignSystem.xl),

          // Financial Section - Highlighted
          _buildMetricCard(
            label: sale.amountLabel,
            value: sale.displayAmount.toStringAsFixed(2),
            icon: Icons.currency_rupee,
            color: CrmColors.primary,
          ),
          if (sale.paymentFrequency != null) ...[
            SizedBox(height: CrmDesignSystem.md),
            Container(
              padding: EdgeInsets.all(CrmDesignSystem.lg),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(
                  CrmDesignSystem.radiusLarge,
                ),
                boxShadow: CrmDesignSystem.elevationSmall,
              ),
              child: _buildDetailRowWithIcon(
                label: 'Payment Frequency',
                value: _formatFrequency(sale.paymentFrequency!),
                icon: Icons.schedule,
                iconColor: CrmColors.secondary,
              ),
            ),
          ],
          if (sale.investmentType != null) ...[
            SizedBox(height: CrmDesignSystem.md),
            Container(
              padding: EdgeInsets.all(CrmDesignSystem.lg),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(
                  CrmDesignSystem.radiusLarge,
                ),
                boxShadow: CrmDesignSystem.elevationSmall,
              ),
              child: _buildDetailRowWithIcon(
                label: 'Investment Type',
                value: sale.investmentType == 'sip' ? 'SIP' : 'Lumpsum',
                icon: Icons.account_balance_wallet,
                iconColor: CrmColors.primary,
              ),
            ),
          ],
          SizedBox(height: CrmDesignSystem.xl),

          // Status & Timeline Section
          Container(
            padding: EdgeInsets.all(CrmDesignSystem.lg),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(CrmDesignSystem.radiusLarge),
              boxShadow: CrmDesignSystem.elevationSmall,
            ),
            child: Column(
              children: [
                _buildDetailRowWithIcon(
                  label: 'Sale Date',
                  value: dateFormat.format(sale.dateOfSale.toLocal()),
                  icon: Icons.calendar_today,
                  iconColor: CrmColors.primary,
                ),
                SizedBox(height: CrmDesignSystem.md),
                Row(
                  children: [
                    Text('Status:', style: CrmDesignSystem.labelMedium),
                    SizedBox(width: CrmDesignSystem.sm),
                    _buildSaleStatusBadge(sale.status),
                  ],
                ),
                if (sale.notes != null && sale.notes!.isNotEmpty) ...[
                  SizedBox(height: CrmDesignSystem.md),
                  Container(
                    padding: EdgeInsets.all(CrmDesignSystem.md),
                    decoration: BoxDecoration(
                      color: CrmColors.surface,
                      borderRadius: BorderRadius.circular(
                        CrmDesignSystem.radiusMedium,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.notes,
                              size: 16,
                              color: CrmColors.textLight,
                            ),
                            SizedBox(width: CrmDesignSystem.sm),
                            Text('Notes', style: CrmDesignSystem.labelSmall),
                          ],
                        ),
                        SizedBox(height: CrmDesignSystem.sm),
                        Text(sale.notes!, style: CrmDesignSystem.bodySmall),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(height: CrmDesignSystem.xl),

          // Extended Fields (Insurance only)
          if (sale.productType == 'life_insurance' ||
              sale.productType == 'general_insurance') ...[
            // Policy Details
            if (sale.policyDetails != null) ...[
              _buildSectionHeaderWithIcon(
                'Policy Details',
                Icons.description_outlined,
                CrmColors.lifeInsuranceColor,
              ),
              SizedBox(height: CrmDesignSystem.md),
              Container(
                padding: EdgeInsets.all(CrmDesignSystem.lg),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(
                    CrmDesignSystem.radiusLarge,
                  ),
                  border: Border.all(
                    color: CrmColors.lifeInsuranceColor.withValues(alpha: 0.2),
                  ),
                  boxShadow: CrmDesignSystem.elevationSmall,
                ),
                child: Column(
                  children: [
                    if (sale.policyDetails!.policyNumber != null)
                      _buildDetailRowWithIcon(
                        label: 'Policy Number',
                        value: sale.policyDetails!.policyNumber!,
                        icon: Icons.confirmation_number,
                        iconColor: CrmColors.lifeInsuranceColor,
                      ),
                    if (sale.policyDetails!.policyIssuanceDate != null) ...[
                      SizedBox(height: CrmDesignSystem.sm),
                      _buildDetailRowWithIcon(
                        label: 'Issuance Date',
                        value: dateFormat.format(
                          sale.policyDetails!.policyIssuanceDate!,
                        ),
                        icon: Icons.event,
                        iconColor: CrmColors.lifeInsuranceColor,
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(height: CrmDesignSystem.xl),
            ],

            // Proposer Details
            if (sale.proposerDetails != null) ...[
              _buildSectionHeaderWithIcon(
                'Proposer Details',
                Icons.person_outline,
                CrmColors.primary,
              ),
              SizedBox(height: CrmDesignSystem.md),
              Container(
                padding: EdgeInsets.all(CrmDesignSystem.lg),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(
                    CrmDesignSystem.radiusLarge,
                  ),
                  border: Border.all(
                    color: CrmColors.primary.withValues(alpha: 0.15),
                  ),
                  boxShadow: CrmDesignSystem.elevationSmall,
                ),
                child: Column(
                  children: [
                    if (sale.proposerDetails!.fullName != null)
                      _buildDetailRowWithIcon(
                        label: 'Full Name',
                        value: sale.proposerDetails!.fullName!,
                        icon: Icons.badge,
                        iconColor: CrmColors.primary,
                      ),
                    if (sale.proposerDetails!.gender != null) ...[
                      SizedBox(height: CrmDesignSystem.sm),
                      _buildDetailRowWithIcon(
                        label: 'Gender',
                        value: sale.proposerDetails!.gender!,
                        icon: Icons.wc,
                        iconColor: CrmColors.secondary,
                      ),
                    ],
                    if (sale.proposerDetails!.dateOfBirth != null) ...[
                      SizedBox(height: CrmDesignSystem.sm),
                      _buildDetailRowWithIcon(
                        label: 'Date of Birth',
                        value: dateFormat.format(
                          sale.proposerDetails!.dateOfBirth!,
                        ),
                        icon: Icons.cake,
                        iconColor: CrmColors.success,
                      ),
                    ],
                    if (sale.proposerDetails!.email != null) ...[
                      SizedBox(height: CrmDesignSystem.sm),
                      _buildDetailRowWithIcon(
                        label: 'Email',
                        value: sale.proposerDetails!.email!,
                        icon: Icons.email_outlined,
                        iconColor: CrmColors.secondary,
                      ),
                    ],
                    if (sale.proposerDetails!.mobileNumber != null) ...[
                      SizedBox(height: CrmDesignSystem.sm),
                      _buildDetailRowWithIcon(
                        label: 'Mobile',
                        value: sale.proposerDetails!.mobileNumber!,
                        icon: Icons.phone_outlined,
                        iconColor: CrmColors.primary,
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(height: CrmDesignSystem.xl),
            ],

            // Nominees
            if (sale.nominees.isNotEmpty) ...[
              _buildSectionHeaderWithIcon(
                'Nominees',
                Icons.people_outline,
                CrmColors.secondary,
              ),
              SizedBox(height: CrmDesignSystem.md),
              ...List.generate(sale.nominees.length, (index) {
                final nominee = sale.nominees[index];
                return Padding(
                  padding: EdgeInsets.only(bottom: CrmDesignSystem.md),
                  child: Container(
                    padding: EdgeInsets.all(CrmDesignSystem.lg),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(
                        CrmDesignSystem.radiusLarge,
                      ),
                      border: Border.all(
                        color: CrmColors.secondary.withValues(alpha: 0.3),
                      ),
                      boxShadow: CrmDesignSystem.elevationSmall,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: CrmColors.secondary.withValues(
                                  alpha: 0.1,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '${index + 1}',
                                  style: CrmDesignSystem.titleSmall.copyWith(
                                    color: CrmColors.secondary,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: CrmDesignSystem.md),
                            Text(
                              'Nominee ${index + 1}',
                              style: CrmDesignSystem.titleMedium.copyWith(
                                color: CrmColors.secondary,
                              ),
                            ),
                          ],
                        ),
                        if (nominee.name != null) ...[
                          SizedBox(height: CrmDesignSystem.md),
                          _buildVerticalDetailRow('Name', nominee.name!),
                        ],
                        if (nominee.dateOfBirth != null) ...[
                          SizedBox(height: CrmDesignSystem.sm),
                          _buildVerticalDetailRow(
                            'Date of Birth',
                            dateFormat.format(nominee.dateOfBirth!),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }),
              SizedBox(height: CrmDesignSystem.xl),
            ],

            // Insured Persons
            if (sale.insuredPersons.isNotEmpty) ...[
              _buildSectionHeaderWithIcon(
                'Insured Persons',
                Icons.health_and_safety_outlined,
                CrmColors.generalInsuranceColor,
              ),
              SizedBox(height: CrmDesignSystem.md),
              ...List.generate(sale.insuredPersons.length, (index) {
                final person = sale.insuredPersons[index];
                return Padding(
                  padding: EdgeInsets.only(bottom: CrmDesignSystem.md),
                  child: Container(
                    padding: EdgeInsets.all(CrmDesignSystem.lg),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(
                        CrmDesignSystem.radiusLarge,
                      ),
                      border: Border.all(
                        color: CrmColors.generalInsuranceColor.withValues(
                          alpha: 0.3,
                        ),
                      ),
                      boxShadow: CrmDesignSystem.elevationSmall,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: CrmDesignSystem.md,
                                vertical: CrmDesignSystem.sm,
                              ),
                              decoration: BoxDecoration(
                                color: CrmColors.generalInsuranceColor
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(
                                  CrmDesignSystem.radiusMedium,
                                ),
                              ),
                              child: Text(
                                'Person ${index + 1}',
                                style: CrmDesignSystem.titleSmall.copyWith(
                                  color: CrmColors.generalInsuranceColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: CrmDesignSystem.md),
                        if (person.fullName != null) ...[
                          _buildVerticalDetailRow('Name', person.fullName!),
                          SizedBox(height: CrmDesignSystem.sm),
                        ],
                        if (person.gender != null) ...[
                          _buildVerticalDetailRow('Gender', person.gender!),
                          SizedBox(height: CrmDesignSystem.sm),
                        ],
                        if (person.dateOfBirth != null) ...[
                          _buildVerticalDetailRow(
                            'Date of Birth',
                            dateFormat.format(person.dateOfBirth!),
                          ),
                          SizedBox(height: CrmDesignSystem.sm),
                        ],
                        if (person.height != null) ...[
                          _buildVerticalDetailRow(
                            'Height',
                            '${person.height!.value} ${person.height!.unit}',
                          ),
                          SizedBox(height: CrmDesignSystem.sm),
                        ],
                        if (person.weight != null) ...[
                          _buildVerticalDetailRow(
                            'Weight',
                            '${person.weight!.value} ${person.weight!.unit}',
                          ),
                          SizedBox(height: CrmDesignSystem.sm),
                        ],
                        if (person.preExistingDiseases != null) ...[
                          _buildVerticalDetailRow(
                            'Pre-existing Diseases',
                            person.preExistingDiseases!,
                          ),
                          SizedBox(height: CrmDesignSystem.sm),
                        ],
                        if (person.medicationDetails != null)
                          _buildVerticalDetailRow(
                            'Medication Details',
                            person.medicationDetails!,
                          ),
                      ],
                    ),
                  ),
                );
              }),
              SizedBox(height: CrmDesignSystem.xl),
            ],
          ],

          // Extended Fields (Mutual Funds only)
          if (sale.productType == 'mutual_funds' &&
              sale.mutualFundDetails != null) ...[
            _buildSectionHeaderWithIcon(
              'Mutual Fund Details',
              Icons.account_balance_outlined,
              CrmColors.primary,
            ),
            SizedBox(height: CrmDesignSystem.md),
            Container(
              padding: EdgeInsets.all(CrmDesignSystem.lg),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(
                  CrmDesignSystem.radiusLarge,
                ),
                border: Border.all(
                  color: CrmColors.mutualFundsColor.withValues(alpha: 0.2),
                ),
                boxShadow: CrmDesignSystem.elevationSmall,
              ),
              child: Column(
                children: [
                  if (sale.mutualFundDetails!.folioNumber != null)
                    _buildDetailRowWithIcon(
                      label: 'Folio Number',
                      value: sale.mutualFundDetails!.folioNumber!,
                      icon: Icons.folder_outlined,
                      iconColor: CrmColors.mutualFundsColor,
                    ),
                ],
              ),
            ),
            SizedBox(height: CrmDesignSystem.xl),
          ],
          // Nominees (for mutual funds)
          if (sale.productType == 'mutual_funds' &&
              sale.nominees.isNotEmpty) ...[
            _buildSectionHeaderWithIcon(
              'Nominees',
              Icons.people_outline,
              CrmColors.secondary,
            ),
            SizedBox(height: CrmDesignSystem.md),
            ...List.generate(sale.nominees.length, (index) {
              final nominee = sale.nominees[index];
              return Padding(
                padding: EdgeInsets.only(bottom: CrmDesignSystem.md),
                child: Container(
                  padding: EdgeInsets.all(CrmDesignSystem.lg),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(
                      CrmDesignSystem.radiusLarge,
                    ),
                    border: Border.all(
                      color: CrmColors.secondary.withValues(alpha: 0.3),
                    ),
                    boxShadow: CrmDesignSystem.elevationSmall,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: CrmColors.secondary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: CrmDesignSystem.titleSmall.copyWith(
                                  color: CrmColors.secondary,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: CrmDesignSystem.md),
                          Text(
                            'Nominee ${index + 1}',
                            style: CrmDesignSystem.titleMedium.copyWith(
                              color: CrmColors.secondary,
                            ),
                          ),
                        ],
                      ),
                      if (nominee.name != null) ...[
                        SizedBox(height: CrmDesignSystem.md),
                        _buildVerticalDetailRow('Name', nominee.name!),
                      ],
                      if (nominee.dateOfBirth != null) ...[
                        SizedBox(height: CrmDesignSystem.sm),
                        _buildVerticalDetailRow(
                          'Date of Birth',
                          dateFormat.format(nominee.dateOfBirth!.toLocal()),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildDocumentsTab() {
    if (!_canAccessDocuments()) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'You do not have access to manage documents for this sale',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Upload Section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.cloud_upload, color: Color(0xFF272579)),
                    const SizedBox(width: 8),
                    const Text(
                      'Upload Document',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF272579),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Document Type Selection Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _showDocumentTypeBottomSheet,
                    icon: const Icon(Icons.category, color: Color(0xFF0071bf)),
                    label: Text(
                      _selectedDocumentType ?? 'Select document type',
                      style: TextStyle(
                        fontSize: 16,
                        color: _selectedDocumentType != null
                            ? Colors.black87
                            : Colors.grey[600],
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: Colors.grey, width: 1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Upload Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isUploadingDocument
                        ? null
                        : _pickAndUploadDocument,
                    icon: _isUploadingDocument
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Icon(Icons.add, color: Colors.white),
                    label: Text(
                      _isUploadingDocument ? 'Uploading...' : 'Select Document',
                      style: const TextStyle(fontSize: 16, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF272579),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),

                const SizedBox(height: 12),
                Text(
                  'Supported formats: PDF, DOC, DOCX, JPG, PNG, TXT (Max 10MB)',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Documents List Section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.description, color: Color(0xFF272579)),
                    const SizedBox(width: 8),
                    Text(
                      'Documents (${_documents.length})',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF272579),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                if (_isLoadingDocuments)
                  const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF0071bf),
                      ),
                    ),
                  )
                else if (_documents.isEmpty)
                  Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.folder_open,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No documents yet',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _documents.length,
                    itemBuilder: (context, index) {
                      final doc = _documents[index];
                      return _buildDocumentCard(doc);
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentCard(SaleDocument document) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          // File Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF272579).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                document.fileIcon,
                style: const TextStyle(fontSize: 20),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Document Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  document.documentName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF272579),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  document.originalFileName,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Uploaded by ${document.uploadedByName ?? 'Unknown'}',
                        style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      ' • ${document.fileSizeFormatted}',
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Actions Menu
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'download') {
                _downloadDocument(document);
              } else if (value == 'delete') {
                _deleteDocument(document.id);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'download',
                child: Row(
                  children: [
                    const Icon(
                      Icons.download,
                      color: Color(0xFF0071bf),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text('Download'),
                  ],
                ),
              ),
              if (_canAccessDocuments())
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      const Icon(Icons.delete, color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      const Text('Delete', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatFrequency(String frequency) {
    switch (frequency) {
      case 'daily':
        return 'Daily';
      case 'weekly':
        return 'Weekly';
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
      default:
        return frequency;
    }
  }

  Widget _buildSectionHeaderWithIcon(String title, IconData icon, Color color) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(
                  CrmDesignSystem.radiusMedium,
                ),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            SizedBox(width: CrmDesignSystem.md),
            Text(
              title,
              style: CrmDesignSystem.titleMedium.copyWith(color: color),
            ),
          ],
        ),
        SizedBox(height: CrmDesignSystem.sm),
        Container(
          height: 2,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.withValues(alpha: 0.3), Colors.transparent],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRowWithIcon({
    required String label,
    required String value,
    required IconData icon,
    required Color iconColor,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: CrmDesignSystem.sm),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(CrmDesignSystem.radiusMedium),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          SizedBox(width: CrmDesignSystem.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: CrmDesignSystem.labelSmall.copyWith(
                    color: CrmColors.textLight,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: CrmDesignSystem.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: CrmDesignSystem.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: CrmDesignSystem.labelSmall.copyWith(
              color: CrmColors.textLight,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: CrmDesignSystem.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(CrmDesignSystem.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.1), color.withValues(alpha: 0.05)],
        ),
        borderRadius: BorderRadius.circular(CrmDesignSystem.radiusLarge),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        boxShadow: CrmDesignSystem.elevationSmall,
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          SizedBox(width: CrmDesignSystem.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: CrmDesignSystem.labelMedium.copyWith(
                    color: CrmColors.textLight,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: CrmDesignSystem.headlineSmall.copyWith(color: color),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaleStatusBadge(String status) {
    final statusColor = status == 'active'
        ? CrmColors.success
        : status == 'inactive'
        ? Colors.orange
        : Colors.red;
    final statusIcon = status == 'active'
        ? Icons.check_circle
        : status == 'inactive'
        ? Icons.pause_circle
        : Icons.cancel;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: CrmDesignSystem.md,
        vertical: CrmDesignSystem.sm,
      ),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(CrmDesignSystem.radiusMedium),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusIcon, color: statusColor, size: 18),
          SizedBox(width: CrmDesignSystem.sm),
          Text(
            status.toUpperCase(),
            style: CrmDesignSystem.labelMedium.copyWith(
              color: statusColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

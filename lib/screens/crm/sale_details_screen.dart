import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/crm_colors.dart';
import '../../models/sale.dart';
import '../../models/sale_document.dart';
import '../../services/sale_service.dart';
import 'package:url_launcher/url_launcher.dart';

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

class _SaleDetailsScreenState extends State<SaleDetailsScreen> with TickerProviderStateMixin {
  Sale? _sale;
  List<SaleDocument> _documents = [];
  bool _isLoadingSale = true;
  bool _isLoadingDocuments = true;
  bool _isUploadingDocument = false;
  String? _error;
  late TabController _tabController;

  String _selectedDocumentType = 'KYC Documents';
  final TextEditingController _customDocNameController = TextEditingController();

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
        setState(() => _error = response.message ?? 'Failed to load sale details');
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading documents: $e')),
        );
      }
    } finally {
      setState(() => _isLoadingDocuments = false);
    }
  }

  Future<void> _pickAndUploadDocument() async {
    try {
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
      String documentName = _selectedDocumentType;
      if (_selectedDocumentType == 'Other (Custom Name)') {
        if (_customDocNameController.text.trim().isEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please enter a custom document name')),
            );
          }
          return;
        }
        documentName = _customDocNameController.text.trim();
      }

      // Determine document type for backend (without "Custom Name" text)
      String docType = _selectedDocumentType == 'Other (Custom Name)'
          ? 'Other'
          : _selectedDocumentType;

      await _uploadDocument(file, documentName, docType);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
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
        setState(() => _selectedDocumentType = 'KYC Documents');

        // Reload documents
        await _loadDocuments();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.message ?? 'Failed to upload document')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload error: $e')),
        );
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
          SnackBar(content: Text(response.message ?? 'Failed to delete document')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
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

  void _downloadDocument(SaleDocument document) async {
    final url = SaleService.getSaleDocumentDownloadUrl(widget.saleId, document.id);
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
        shadowColor: const Color(0xFF0071bf).withOpacity(0.3),
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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sale Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF272579), Color(0xFF0071bf)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sale.saleId,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  sale.customerName,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Sale Details Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('Product Type', sale.productType.replaceAll('_', ' ').toUpperCase()),
                const Divider(height: 24),
                _buildDetailRow('Customer', sale.customerName),
                const Divider(height: 24),
                _buildDetailRow('Company', sale.companyName),
                const Divider(height: 24),
                _buildDetailRow('Product Plan', sale.productPlanName),
                const Divider(height: 24),
                _buildDetailRow(sale.amountLabel, '₹${sale.displayAmount.toStringAsFixed(2)}'),
                const Divider(height: 24),
                _buildDetailRow('Sale Date', dateFormat.format(sale.dateOfSale.toLocal())),
                const Divider(height: 24),
                _buildDetailRow('Status', sale.status.toUpperCase()),
              ],
            ),
          ),
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
            Icon(
              Icons.lock,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'You do not have access to manage documents for this sale',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
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
                  color: Colors.black.withOpacity(0.04),
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

                // Document Type Dropdown
                DropdownButtonFormField<String>(
                  value: _selectedDocumentType,
                  items: _predefinedDocTypes
                      .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedDocumentType = value!;
                      _customDocNameController.clear();
                    });
                  },
                  decoration: InputDecoration(
                    labelText: 'Document Type',
                    hintText: 'Select document type',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.category, color: Color(0xFF0071bf)),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                  ),
                ),

                // Custom Name Field (shown if "Other" is selected)
                if (_selectedDocumentType == 'Other (Custom Name)') ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: _customDocNameController,
                    decoration: InputDecoration(
                      labelText: 'Custom Document Name',
                      hintText: 'Enter document name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.edit, color: Color(0xFF0071bf)),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                // Upload Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isUploadingDocument ? null : _pickAndUploadDocument,
                    icon: _isUploadingDocument
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.add),
                    label: Text(
                      _isUploadingDocument ? 'Uploading...' : 'Select Document',
                      style: const TextStyle(fontSize: 16),
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
                  color: Colors.black.withOpacity(0.04),
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
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0071bf)),
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
              color: const Color(0xFF272579).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(document.fileIcon, style: const TextStyle(fontSize: 20)),
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
                    Text(
                      'Uploaded by ${document.uploadedByName ?? 'Unknown'}',
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
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
                    const Icon(Icons.download, color: Color(0xFF0071bf), size: 20),
                    const SizedBox(width: 8),
                    const Text('Download'),
                  ],
                ),
              ),
              if (_canAccessDocuments)
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

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF272579),
          ),
        ),
      ],
    );
  }
}

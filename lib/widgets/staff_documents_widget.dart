import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../services/api_service.dart';
import '../constants/document_categories.dart';

/// Widget to display documents for a specific user (used by Admin/Director)
/// Shows documents grouped by category with completion status
class StaffDocumentsWidget extends StatefulWidget {
  final String userId;
  final String userName;
  final String employeeId;

  const StaffDocumentsWidget({
    super.key,
    required this.userId,
    required this.userName,
    required this.employeeId,
  });

  @override
  State<StaffDocumentsWidget> createState() => _StaffDocumentsWidgetState();
}

class _StaffDocumentsWidgetState extends State<StaffDocumentsWidget> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _documents = [];
  Set<String> _uploadedCategories = {};
  Map<String, Map<String, dynamic>> _documentsByCategory = {};
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiService.getUserDocumentsByUserId(widget.userId);

      if (response.success && response.data != null) {
        final documentsData = response.data is List
            ? response.data as List
            : (response.data as Map<String, dynamic>)['data'] as List? ?? [];
        final docsList = List<Map<String, dynamic>>.from(documentsData);

        // Build uploaded categories set and documents by category map
        final uploadedCats = <String>{};
        final docsByCat = <String, Map<String, dynamic>>{};
        for (final doc in docsList) {
          final category = doc['documentCategory'] as String?;
          if (category != null) {
            uploadedCats.add(category);
            if (!docsByCat.containsKey(category)) {
              docsByCat[category] = doc;
            }
          }
        }

        setState(() {
          _documents = docsList;
          _uploadedCategories = uploadedCats;
          _documentsByCategory = docsByCat;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = response.message.isNotEmpty
              ? response.message
              : 'Failed to load documents';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  String _getFileIcon(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return '📄';
      case 'doc':
      case 'docx':
        return '📝';
      case 'jpg':
      case 'jpeg':
      case 'png':
        return '🖼️';
      case 'txt':
        return '📃';
      default:
        return '📁';
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case DocumentCategories.educationalCertificate:
        return Icons.school_outlined;
      case DocumentCategories.experienceCertificate:
        return Icons.work_outline;
      case DocumentCategories.salarySlips:
        return Icons.receipt_long_outlined;
      case DocumentCategories.identityProof:
        return Icons.badge_outlined;
      case DocumentCategories.addressProof:
        return Icons.home_outlined;
      case DocumentCategories.bankStatement:
        return Icons.account_balance_outlined;
      case DocumentCategories.panCard:
        return Icons.credit_card_outlined;
      default:
        return Icons.description_outlined;
    }
  }

  Future<void> _openDocument(String? documentId) async {
    if (documentId == null || documentId.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Document not available'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Fetch signed URL from backend
    final response = await ApiService.getDocumentSignedUrl(documentId);

    if (response.success && response.data != null) {
      final uri = Uri.parse(response.data!);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open document'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message.isNotEmpty ? response.message : 'Failed to get document URL'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _shareDocument(String? documentId, String? originalFileName, String? documentCategory) async {
    if (documentId == null) return;

    // Build filename: employeeId_CategoryLabel.extension (spaces replaced with _)
    final extension = originalFileName?.split('.').last ?? 'pdf';
    final categoryLabel = DocumentCategories.getLabel(documentCategory ?? 'other').replaceAll(' ', '_');
    final safeName = '${widget.employeeId}_$categoryLabel.$extension';

    try {
      // Get signed URL
      final response = await ApiService.getDocumentSignedUrl(documentId);
      if (!response.success || response.data == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to get document'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Download to temp directory
      final dir = await getTemporaryDirectory();
      final filePath = '${dir.path}/$safeName';

      await Dio().download(response.data!, filePath);

      // Share the file with employee name and document info
      await Share.shareXFiles(
        [XFile(filePath)],
        subject: '${widget.employeeId} - ${widget.userName} - $categoryLabel',
        text: 'Document: $safeName\nEmployee: ${widget.employeeId} - ${widget.userName}',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Share failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF0071bf)),
            )
          : _errorMessage != null
              ? _buildErrorState()
              : _buildDocumentsView(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Color(0xFFEF4444),
            ),
            const SizedBox(height: 16),
            const Text(
              'Unable to Load Documents',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Something went wrong',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadDocuments,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0071bf),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentsView() {
    final mandatoryUploaded = _uploadedCategories
        .where((c) => DocumentCategories.mandatoryCategories.contains(c))
        .length;
    final totalMandatory = DocumentCategories.mandatoryCategories.length;
    final isComplete = mandatoryUploaded == totalMandatory;

    return RefreshIndicator(
      onRefresh: _loadDocuments,
      color: const Color(0xFF0071bf),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Completion Status Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: isComplete
                    ? const Color(0xFF10B981).withValues(alpha: 0.1)
                    : const Color(0xFFEF4444).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isComplete
                      ? const Color(0xFF10B981).withValues(alpha: 0.3)
                      : const Color(0xFFEF4444).withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isComplete
                          ? const Color(0xFF10B981).withValues(alpha: 0.2)
                          : const Color(0xFFEF4444).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isComplete
                          ? Icons.check_circle_outline
                          : Icons.warning_amber_outlined,
                      color: isComplete
                          ? const Color(0xFF10B981)
                          : const Color(0xFFEF4444),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isComplete
                              ? 'Documents Complete'
                              : 'Documents Incomplete',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isComplete
                                ? const Color(0xFF10B981)
                                : const Color(0xFFEF4444),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$mandatoryUploaded of $totalMandatory required documents uploaded',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Mandatory Documents Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.checklist, color: Color(0xFF272579), size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Required Documents',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF272579),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ...DocumentCategories.mandatoryCategories.map((category) {
                    final isUploaded = _uploadedCategories.contains(category);
                    final doc = _documentsByCategory[category];
                    return _buildCategoryItem(
                      category: category,
                      isUploaded: isUploaded,
                      document: doc,
                    );
                  }),
                ],
              ),
            ),

            // Other Documents Section
            if (_documents
                .where((d) => d['documentCategory'] == DocumentCategories.other)
                .isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.folder_outlined,
                            color: Color(0xFF272579), size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Other Documents',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF272579),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ..._documents
                        .where((d) =>
                            d['documentCategory'] == DocumentCategories.other)
                        .map((doc) => _buildDocumentItem(doc)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryItem({
    required String category,
    required bool isUploaded,
    Map<String, dynamic>? document,
  }) {
    final label = DocumentCategories.getLabel(category);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isUploaded
            ? const Color(0xFF10B981).withValues(alpha: 0.05)
            : Colors.grey[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isUploaded
              ? const Color(0xFF10B981).withValues(alpha: 0.3)
              : Colors.grey[200]!,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: isUploaded
                  ? const Color(0xFF10B981).withValues(alpha: 0.1)
                  : const Color(0xFF272579).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isUploaded ? Icons.check_circle : _getCategoryIcon(category),
              color: isUploaded
                  ? const Color(0xFF10B981)
                  : const Color(0xFF272579),
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isUploaded
                        ? const Color(0xFF10B981)
                        : const Color(0xFF1E293B),
                  ),
                ),
                if (isUploaded && document != null)
                  Text(
                    document['originalFileName'] as String? ?? '',
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                else
                  Text(
                    'Not uploaded',
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
              ],
            ),
          ),
          if (isUploaded && document != null)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // View button
                IconButton(
                  icon: const Icon(Icons.visibility_outlined, size: 18),
                  color: const Color(0xFF272579),
                  onPressed: () => _openDocument(document['_id'] as String?),
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  padding: EdgeInsets.zero,
                  tooltip: 'View',
                ),
                const SizedBox(width: 4),
                // Share button
                IconButton(
                  icon: const Icon(Icons.share_outlined, size: 18),
                  color: const Color(0xFF00b8d9),
                  onPressed: () => _shareDocument(
                    document['_id'] as String?,
                    document['originalFileName'] as String?,
                    category,
                  ),
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  padding: EdgeInsets.zero,
                  tooltip: 'Share',
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildDocumentItem(Map<String, dynamic> document) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFF272579).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Text(
                _getFileIcon(document['originalFileName'] ?? ''),
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  document['documentName'] ?? 'Untitled',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF272579),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  document['originalFileName'] ?? '',
                  style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.visibility_outlined, size: 16),
                color: const Color(0xFF272579),
                onPressed: () => _openDocument(document['_id'] as String?),
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                padding: EdgeInsets.zero,
                tooltip: 'View',
              ),
              const SizedBox(width: 2),
              IconButton(
                icon: const Icon(Icons.share_outlined, size: 16),
                color: const Color(0xFF00b8d9),
                onPressed: () => _shareDocument(
                  document['_id'] as String?,
                  document['originalFileName'] as String?,
                  document['documentCategory'] as String?,
                ),
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                padding: EdgeInsets.zero,
                tooltip: 'Share',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

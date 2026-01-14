import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/api_service.dart';
import '../../services/access_control_service.dart';
import '../../utils/timezone_util.dart';

class FeedbackDetailScreen extends StatefulWidget {
  final String feedbackId;

  const FeedbackDetailScreen({
    super.key,
    required this.feedbackId,
  });

  @override
  State<FeedbackDetailScreen> createState() => _FeedbackDetailScreenState();
}

class _FeedbackDetailScreenState extends State<FeedbackDetailScreen> {
  Map<String, dynamic>? _feedback;
  bool _isLoading = true;
  bool _isAdmin = false;
  bool _canDelete = false;
  String _userRole = '';

  final TextEditingController _responseController = TextEditingController();
  bool _isSubmittingResponse = false;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
    _loadFeedback();
  }

  @override
  void dispose() {
    _responseController.dispose();
    super.dispose();
  }

  Future<void> _loadUserRole() async {
    final userData = await ApiService.getUserData();
    if (userData != null) {
      setState(() {
        _userRole = userData['role']?.toString() ?? '';
        _isAdmin = AccessControlService.hasAccess(_userRole, 'feedback_management', 'respond');
        _canDelete = AccessControlService.hasAccess(_userRole, 'feedback_management', 'delete');
      });
    }
  }

  Future<void> _loadFeedback() async {
    setState(() => _isLoading = true);

    try {
      final response = await ApiService.getFeedbackById(widget.feedbackId);

      if (response.success && response.data != null) {
        setState(() {
          _feedback = response.data as Map<String, dynamic>;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        _showError(response.message);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Failed to load feedback: $e');
    }
  }

  Future<void> _showUpdateDialog() async {
    final currentStatus = _feedback!['status']?.toString() ?? 'open';
    final currentPriority = _feedback!['priority']?.toString() ?? 'low';

    String selectedStatus = currentStatus;
    String selectedPriority = currentPriority;

    final result = await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Title
                const Text(
                  'Update Feedback',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF272579),
                  ),
                ),
                const SizedBox(height: 20),

                // Status dropdown
                const Text(
                  'Status',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF272579),
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: selectedStatus,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF0071bf), width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'open', child: Text('Open')),
                    DropdownMenuItem(value: 'in_progress', child: Text('In Progress')),
                    DropdownMenuItem(value: 'resolved', child: Text('Resolved')),
                    DropdownMenuItem(value: 'closed', child: Text('Closed')),
                  ],
                  onChanged: (value) {
                    setSheetState(() => selectedStatus = value!);
                  },
                ),
                const SizedBox(height: 20),

                // Priority dropdown
                const Text(
                  'Priority',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF272579),
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: selectedPriority,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF0071bf), width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'low', child: Text('Low')),
                    DropdownMenuItem(value: 'medium', child: Text('Medium')),
                    DropdownMenuItem(value: 'high', child: Text('High')),
                    DropdownMenuItem(value: 'critical', child: Text('Critical')),
                  ],
                  onChanged: (value) {
                    setSheetState(() => selectedPriority = value!);
                  },
                ),
                const SizedBox(height: 24),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF272579),
                          side: const BorderSide(color: Color(0xFF272579)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context, {
                          'status': selectedStatus,
                          'priority': selectedPriority,
                        }),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0071bf),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Update',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );

    if (result != null) {
      await _updateFeedback(
        status: result['status'] != currentStatus ? result['status'] : null,
        priority: result['priority'] != currentPriority ? result['priority'] : null,
      );
    }
  }

  Future<void> _updateFeedback({String? status, String? priority}) async {
    if (status == null && priority == null) return;

    try {
      final response = await ApiService.updateFeedbackStatus(
        feedbackId: widget.feedbackId,
        status: status,
        priority: priority,
      );

      if (response.success) {
        _loadFeedback();
      } else {
        _showError(response.message);
      }
    } catch (e) {
      _showError('Failed to update: $e');
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Warning icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.delete_forever,
                size: 48,
                color: Colors.red.shade400,
              ),
            ),
            const SizedBox(height: 16),

            // Title
            const Text(
              'Delete Feedback?',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF272579),
              ),
            ),
            const SizedBox(height: 8),

            // Description
            Text(
              'This action cannot be undone. The feedback and all its responses will be permanently deleted.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF272579),
                      side: const BorderSide(color: Color(0xFF272579)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Delete',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      await _deleteFeedback();
    }
  }

  Future<void> _deleteFeedback() async {
    try {
      final response = await ApiService.deleteFeedback(widget.feedbackId);

      if (response.success) {
        if (mounted) {
          Navigator.pop(context, true); // Return to list with refresh flag
        }
      } else {
        _showError(response.message);
      }
    } catch (e) {
      _showError('Failed to delete feedback: $e');
    }
  }

  Future<void> _submitResponse() async {
    final message = _responseController.text.trim();
    if (message.isEmpty || message.length < 5) {
      _showError('Response must be at least 5 characters');
      return;
    }

    setState(() => _isSubmittingResponse = true);

    try {
      final response = await ApiService.addFeedbackResponse(
        feedbackId: widget.feedbackId,
        message: message,
      );

      if (response.success) {
        _responseController.clear();
        _showSuccess('Response added successfully');
        _loadFeedback();
      } else {
        _showError(response.message);
      }
    } catch (e) {
      _showError('Failed to add response: $e');
    } finally {
      setState(() => _isSubmittingResponse = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF4caf50),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'critical':
        return const Color(0xFFf44336);
      case 'high':
        return const Color(0xFFff9800);
      case 'medium':
        return const Color(0xFF00b8d9);
      case 'low':
      default:
        return const Color(0xFF4caf50); // Material Green (better legibility)
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'resolved':
      case 'closed':
        return const Color(0xFF4caf50); // Material Green (better legibility)
      case 'in_progress':
        return const Color(0xFF00b8d9);
      case 'open':
      default:
        return const Color(0xFFff9800);
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'bug':
        return Icons.bug_report;
      case 'complaint':
        return Icons.report_problem;
      case 'feedback':
      default:
        return Icons.feedback;
    }
  }

  String _formatDate(String dateStr) {
    try {
      // Parse and convert to IST
      final istDate = TimezoneUtil.parseToIST(dateStr);
      return TimezoneUtil.formatIST(istDate, 'dd MMM yyyy, h:mm a');
    } catch (e) {
      return '';
    }
  }

  Future<void> _openFile(String fileUrl) async {
    try {
      final url = Uri.parse('${ApiService.baseUrl}$fileUrl');
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        _showError('Cannot open file');
      }
    } catch (e) {
      _showError('Failed to open file: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFf8f9fa),
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
        title: const Text(
          'Feedback Details',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          if (_isAdmin && _feedback != null)
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.white),
              onPressed: _showUpdateDialog,
              tooltip: 'Update Status & Priority',
            ),
          if (_canDelete && _feedback != null)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.white),
              onPressed: _confirmDelete,
              tooltip: 'Delete Feedback',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _feedback == null
              ? const Center(child: Text('Feedback not found'))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildFeedbackCard(),
                    const SizedBox(height: 16),
                    _buildAttachmentsSection(),
                    const SizedBox(height: 16),
                    _buildResponsesSection(),
                    if (_isAdmin) ...[
                      const SizedBox(height: 16),
                      _buildAdminResponseInput(),
                    ],
                    const SizedBox(height: 32),
                  ],
                ),
    );
  }

  Widget _buildFeedbackCard() {
    final type = _feedback!['type']?.toString() ?? '';
    final category = _feedback!['category']?.toString() ?? '';
    final status = _feedback!['status']?.toString() ?? '';
    final priority = _feedback!['priority']?.toString() ?? '';
    final title = _feedback!['title']?.toString() ?? '';
    final description = _feedback!['description']?.toString() ?? '';
    final createdAt = _feedback!['createdAt']?.toString() ?? '';

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Type, Status, and Priority badges
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getPriorityColor(priority).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_getTypeIcon(type), size: 16, color: _getPriorityColor(priority)),
                      const SizedBox(width: 6),
                      Text(
                        type.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _getPriorityColor(priority),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status.replaceAll('_', ' ').toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _getStatusColor(status),
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getPriorityColor(priority).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    priority.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: _getPriorityColor(priority),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Title
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF272579),
              ),
            ),

            const SizedBox(height: 8),

            // Category
            Row(
              children: [
                Icon(Icons.category_outlined, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 6),
                Text(
                  category.replaceAll('_', ' ').toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Description
            Text(
              description,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[800],
                height: 1.5,
              ),
            ),

            const SizedBox(height: 12),

            // Date
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.grey[500]),
                const SizedBox(width: 6),
                Text(
                  'Submitted ${_formatDate(createdAt)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentsSection() {
    final attachments = _feedback!['attachments'] as List?;
    if (attachments == null || attachments.isEmpty) return const SizedBox.shrink();

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.attach_file, size: 20, color: Color(0xFF0071bf)),
                const SizedBox(width: 8),
                const Text(
                  'Attachments',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF272579),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0071bf).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${attachments.length}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0071bf),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...attachments.map<Widget>((attachment) {
              final fileName = attachment['originalName']?.toString() ?? '';
              final fileUrl = attachment['fileUrl']?.toString() ?? '';
              final mimeType = attachment['mimeType']?.toString() ?? '';

              IconData icon = Icons.insert_drive_file;
              if (mimeType.startsWith('image/')) {
                icon = Icons.image;
              } else if (mimeType.startsWith('video/')) {
                icon = Icons.videocam;
              } else if (mimeType.contains('pdf')) {
                icon = Icons.picture_as_pdf;
              }

              return InkWell(
                onTap: () => _openFile(fileUrl),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0071bf).withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF0071bf).withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(icon, color: const Color(0xFF0071bf), size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          fileName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(Icons.download, size: 20, color: Color(0xFF0071bf)),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildResponsesSection() {
    final responses = _feedback!['responses'] as List?;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.comment, size: 20, color: Color(0xFF0071bf)),
                const SizedBox(width: 8),
                const Text(
                  'Responses',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF272579),
                  ),
                ),
                if (responses != null && responses.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0071bf).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${responses.length}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0071bf),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            if (responses == null || responses.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    'No responses yet',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ),
              )
            else
              ...responses.map<Widget>((response) {
                final responderName = response['responderName']?.toString() ?? 'Admin';
                final message = response['message']?.toString() ?? '';
                final createdAt = response['createdAt']?.toString() ?? '';

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4caf50).withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF4caf50).withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: const Color(0xFF4caf50),
                            child: Text(
                              responderName[0].toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  responderName,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF272579),
                                  ),
                                ),
                                Text(
                                  _formatDate(createdAt),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        message,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[800],
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminResponseInput() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add Response',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF272579),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _responseController,
              decoration: InputDecoration(
                hintText: 'Type your response here...',
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF0071bf), width: 2),
                ),
                contentPadding: const EdgeInsets.all(14),
              ),
              maxLines: 4,
              maxLength: 1000,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmittingResponse ? null : _submitResponse,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0071bf),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _isSubmittingResponse
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Submit Response',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

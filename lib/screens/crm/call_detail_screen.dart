import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../services/api_service.dart';
import '../../services/access_control_service.dart';
import '../../config/api_config.dart';

class CallDetailScreen extends StatefulWidget {
  final String callLogId;
  final String userId;
  final String userRole;

  const CallDetailScreen({
    super.key,
    required this.callLogId,
    required this.userId,
    required this.userRole,
  });

  @override
  State<CallDetailScreen> createState() => _CallDetailScreenState();
}

class _CallDetailScreenState extends State<CallDetailScreen> {
  Map<String, dynamic>? _callLog;
  bool _isLoading = true;
  String? _error;
  bool _isEditing = false;
  late TextEditingController _notesController;

  final Map<String, String> _outcomeLabels = {
    'connected': '✅ Connected',
    'no_answer': '❌ No Answer',
    'voicemail': '📞 Voicemail',
    'busy': '⏰ Busy',
    'failed': '✗ Failed',
  };

  final Map<String, Color> _outcomeColors = {
    'connected': const Color(0xFF5cfbd8),
    'no_answer': Colors.orange,
    'voicemail': const Color(0xFF00b8d9),
    'busy': Colors.amber,
    'failed': Colors.red,
  };

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController();
    _loadCallDetail();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadCallDetail() async {
    try {
      final response = await ApiService.get('/call-logs/${widget.callLogId}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _callLog = data['data'];
          _notesController.text = data['data']['notes'] ?? '';
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Call log not found';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error loading call details: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _updateCallLog() async {
    try {
      final requestBody = {
        'customerId': _callLog!['customerId']['_id'],
        'phoneNumber': _callLog!['phoneNumber'],
        'direction': _callLog!['direction'],
        'outcome': _callLog!['outcome'],
        'callStartTime': _callLog!['callStartTime'],
        'callEndTime': _callLog!['callEndTime'],
        'durationSeconds': _callLog!['durationSeconds'],
        'notes': _notesController.text.isNotEmpty ? _notesController.text : null,
      };

      final token = await ApiService.getToken();
      final headers = {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/call-logs/${widget.callLogId}'),
        headers: headers,
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _callLog = data['data'];
          _isEditing = false;
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Call log updated successfully'),
            backgroundColor: Color(0xFF5cfbd8),
          ),
        );
      } else {
        throw Exception('Failed to update call log');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Call Details'),
          backgroundColor: const Color(0xFF0071bf),
        ),
        body: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0071bf)),
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Call Details'),
          backgroundColor: const Color(0xFF0071bf),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(_error!),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadCallDetail,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0071bf),
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_callLog == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Call Details'),
          backgroundColor: const Color(0xFF0071bf),
        ),
        body: const Center(child: Text('Call log not found')),
      );
    }

    final callLog = _callLog!;
    final customer = callLog['customerId'];
    final user = callLog['userId'];
    final outcome = callLog['outcome'];
    final callStartTime = DateTime.parse(callLog['callStartTime']);
    final duration = callLog['durationSeconds'] ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Call Details',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF0071bf),
        elevation: 2,
        actions: [
          if (!_isEditing && _canEditCallLog())
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
              tooltip: 'Edit notes',
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Call Header Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF0071bf).withValues(alpha: 0.15),
                  ),
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
                    // Customer Name
                    Text(
                      customer['name'] ?? 'Unknown',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF272579),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Phone Number
                    Row(
                      children: [
                        const Icon(Icons.phone, size: 18, color: Color(0xFF0071bf)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            customer['mobileNumber'] ?? callLog['phoneNumber'],
                            style: const TextStyle(
                              fontSize: 15,
                              color: Color(0xFF272579),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Call ID
                    Row(
                      children: [
                        const Icon(Icons.receipt, size: 18, color: Color(0xFF0071bf)),
                        const SizedBox(width: 12),
                        Text(
                          callLog['callLogId'] ?? 'N/A',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Call Information Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF00b8d9).withValues(alpha: 0.15),
                  ),
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
                    const Text(
                      'Call Information',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF272579),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Direction
                    _buildDetailRow(
                      'Direction',
                      callLog['direction'] == 'outgoing' ? 'Outgoing' : 'Incoming',
                      callLog['direction'] == 'outgoing' ? Icons.call_made : Icons.call_received,
                    ),
                    const SizedBox(height: 12),

                    // Date & Time
                    _buildDetailRow(
                      'Date & Time',
                      '${_formatDate(callStartTime)} ${_formatTime(callStartTime)}',
                      Icons.calendar_today,
                    ),
                    const SizedBox(height: 12),

                    // Duration
                    _buildDetailRow(
                      'Duration',
                      _formatDuration(duration),
                      Icons.timer,
                    ),
                    const SizedBox(height: 12),

                    // Outcome Badge
                    Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 18,
                          color: _outcomeColors[outcome] ?? Colors.grey,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Outcome',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF272579),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      (_outcomeColors[outcome] ?? Colors.grey).withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  _outcomeLabels[outcome] ?? outcome,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: _outcomeColors[outcome] ?? Colors.grey,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // User Information Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF0071bf).withValues(alpha: 0.15),
                  ),
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
                    const Text(
                      'Logged By',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF272579),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      'Agent',
                      '${user['firstName']} ${user['lastName']}',
                      Icons.person,
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      'Email',
                      user['email'] ?? 'N/A',
                      Icons.email,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Notes Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFfbf8ff),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF272579).withValues(alpha: 0.1),
                  ),
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Notes',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF272579),
                          ),
                        ),
                        if (_isEditing)
                          TextButton(
                            onPressed: () => setState(() => _isEditing = false),
                            child: const Text('Cancel'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_isEditing)
                      Column(
                        children: [
                          TextField(
                            controller: _notesController,
                            maxLines: 4,
                            decoration: InputDecoration(
                              hintText: 'Add notes...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.all(12),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: _updateCallLog,
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF0071bf),
                              ),
                              child: const Text('Save Notes'),
                            ),
                          ),
                        ],
                      )
                    else
                      Text(
                        _notesController.text.isEmpty ? 'No notes' : _notesController.text,
                        style: TextStyle(
                          fontSize: 14,
                          color: _notesController.text.isEmpty ? Colors.grey[600] : Colors.grey[700],
                          height: 1.6,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Linked Activity
              if (callLog['activityId'] != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF0071bf).withValues(alpha: 0.15),
                    ),
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
                      const Text(
                        'Linked Activity',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF272579),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildDetailRow(
                        'Activity ID',
                        callLog['activityId']['activityId'] ?? 'N/A',
                        Icons.link,
                      ),
                      const SizedBox(height: 8),
                      _buildDetailRow(
                        'Type',
                        callLog['activityId']['type'] ?? 'N/A',
                        Icons.category,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF0071bf)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF272579),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  bool _canEditCallLog() {
    final callLog = _callLog!;
    // User can edit their own call logs
    if (callLog['userId']['_id'] == widget.userId) {
      return AccessControlService.hasAccess(widget.userRole, 'call_management', 'edit_own');
    }
    // Admin can edit any call log
    return AccessControlService.hasAccess(widget.userRole, 'call_management', 'edit_own');
  }

  String _formatDate(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.year}';
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _formatDuration(int seconds) {
    if (seconds == 0) return '0 seconds';
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    if (minutes > 0) {
      return '$minutes min $secs sec';
    }
    return '$secs sec';
  }
}

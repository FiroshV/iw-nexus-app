import 'dart:convert';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class CallLogsScreen extends StatefulWidget {
  final String userId;
  final String userRole;

  const CallLogsScreen({
    super.key,
    required this.userId,
    required this.userRole,
  });

  @override
  State<CallLogsScreen> createState() => _CallLogsScreenState();
}

class _CallLogsScreenState extends State<CallLogsScreen> {
  List<dynamic> _callLogs = [];
  bool _isLoading = false;
  final TextEditingController _searchController = TextEditingController();
  String? _selectedOutcomeFilter;
  int _currentPage = 1;
  int _totalPages = 1;

  final List<String> _outcomes = [
    'connected',
    'no_answer',
    'voicemail',
    'busy',
    'failed',
  ];

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
    _loadCallLogs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCallLogs({int page = 1}) async {
    setState(() => _isLoading = true);

    try {
      String query = '/call-logs?page=$page&limit=20';

      if (_searchController.text.isNotEmpty) {
        query += '&search=${_searchController.text}';
      }

      if (_selectedOutcomeFilter != null) {
        query += '&outcome=$_selectedOutcomeFilter';
      }

      final response = await ApiService.get(query);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _callLogs = data['data'] as List<dynamic>;
          _currentPage = data['pagination']['page'];
          _totalPages = data['pagination']['totalPages'];
        });
      } else {
        throw Exception('Failed to load call logs');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading call logs: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _onSearchChanged(String value) {
    _currentPage = 1;
    _loadCallLogs(page: 1);
  }

  void _onOutcomeFilterChanged(String? value) {
    setState(() => _selectedOutcomeFilter = value);
    _currentPage = 1;
    _loadCallLogs(page: 1);
  }

  void _navigateToCallDetail(String callLogId) {
    Navigator.pushNamed(
      context,
      '/crm/call-detail',
      arguments: {
        'callLogId': callLogId,
        'userId': widget.userId,
        'userRole': widget.userRole,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Call Logs',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF0071bf),
        elevation: 2,
        shadowColor: const Color(0xFF0071bf).withValues(alpha: 0.3),
      ),
      body: _isLoading && _callLogs.isEmpty
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0071bf)),
              ),
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Search Bar
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      decoration: InputDecoration(
                        hintText: 'Search by customer or phone...',
                        prefixIcon: const Icon(Icons.search, color: Color(0xFF0071bf)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFF0071bf)),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                  ),

                  // Filter Chips
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Wrap(
                        spacing: 8,
                        children: [
                          FilterChip(
                            label: const Text('All'),
                            selected: _selectedOutcomeFilter == null,
                            onSelected: (selected) {
                              _onOutcomeFilterChanged(null);
                            },
                            selectedColor: const Color(0xFF5cfbd8),
                          ),
                          ..._outcomes.map((outcome) {
                            final isSelected = _selectedOutcomeFilter == outcome;
                            return FilterChip(
                              label: Text(_outcomeLabels[outcome] ?? outcome),
                              selected: isSelected,
                              onSelected: (selected) {
                                _onOutcomeFilterChanged(selected ? outcome : null);
                              },
                              selectedColor: _outcomeColors[outcome]?.withValues(alpha: 0.3),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Call Logs List
                  if (_callLogs.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Column(
                          children: [
                            Icon(
                              Icons.phone_missed,
                              size: 48,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No call logs found',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _callLogs.length,
                      itemBuilder: (context, index) {
                        final callLog = _callLogs[index];
                        final customer = callLog['customerId'];
                        final outcome = callLog['outcome'];
                        final callStartTime = DateTime.parse(callLog['callStartTime']);
                        final duration = callLog['durationSeconds'] ?? 0;

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: GestureDetector(
                            onTap: () => _navigateToCallDetail(callLog['callLogId']),
                            child: Container(
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
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Customer Name
                                  Text(
                                    customer['name'] ?? 'Unknown',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF272579),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 6),

                                  // Phone Number
                                  Row(
                                    children: [
                                      const Icon(Icons.phone, size: 14, color: Color(0xFF0071bf)),
                                      const SizedBox(width: 6),
                                      Text(
                                        customer['mobileNumber'] ?? callLog['phoneNumber'],
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),

                                  // Call Info Row
                                  Row(
                                    children: [
                                      // Direction
                                      Icon(
                                        callLog['direction'] == 'outgoing'
                                            ? Icons.call_made
                                            : Icons.call_received,
                                        size: 16,
                                        color: const Color(0xFF0071bf),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${callLog['direction'] == 'outgoing' ? 'Outgoing' : 'Incoming'}  •  ${_formatTime(callStartTime)}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),

                                  // Duration and Outcome
                                  Row(
                                    children: [
                                      // Duration
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFfbf8ff),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          '⏱️ ${_formatDuration(duration)}',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Color(0xFF272579),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),

                                      // Outcome Badge
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: (_outcomeColors[outcome] ?? Colors.grey)
                                              .withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          _outcomeLabels[outcome] ?? outcome,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: _outcomeColors[outcome] ?? Colors.grey,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                  // Pagination
                  if (_totalPages > 1)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_currentPage > 1)
                            IconButton(
                              icon: const Icon(Icons.chevron_left),
                              onPressed: () => _loadCallLogs(page: _currentPage - 1),
                            ),
                          Text(
                            'Page $_currentPage of $_totalPages',
                            style: const TextStyle(fontSize: 14),
                          ),
                          if (_currentPage < _totalPages)
                            IconButton(
                              icon: const Icon(Icons.chevron_right),
                              onPressed: () => _loadCallLogs(page: _currentPage + 1),
                            ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _formatDuration(int seconds) {
    if (seconds == 0) return '0s';
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    if (minutes > 0) {
      return '${minutes}m ${secs}s';
    }
    return '${secs}s';
  }
}

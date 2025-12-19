import 'dart:convert';
import 'package:flutter/material.dart';
import '../../models/customer.dart';
import '../../services/api_service.dart';
import '../../services/customer_service.dart';
import '../../services/call_service.dart';
import '../../widgets/crm/timeline_widget.dart';
import 'quick_activity_log_screen.dart';

class CustomerDetailScreen extends StatefulWidget {
  final String customerId;
  final String userId;
  final String userRole;

  const CustomerDetailScreen({
    super.key,
    required this.customerId,
    required this.userId,
    required this.userRole,
  });

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  Customer? _customer;
  bool _isLoading = true;
  String? _error;

  Map<String, dynamic>? _timelineData;
  bool _isLoadingTimeline = false;

  @override
  void initState() {
    super.initState();
    _loadCustomerDetails();
  }

  Future<void> _loadTimeline() async {
    setState(() {
      _isLoadingTimeline = true;
    });

    try {
      final timelineResponse = await CustomerService.getCustomerTimeline(widget.customerId);

      if (timelineResponse.success && timelineResponse.data != null) {
          debugPrint('Timeline data received for customer ${widget.customerId}');
          debugPrint('Total activities: ${timelineResponse.data!['activities']?.length ?? 0}');

        // Debug log each activity to identify problematic ones
        final activities = timelineResponse.data!['activities'] as List?;
        activities?.asMap().forEach((index, activity) {
            debugPrint('Activity $index: '
              'type=${activity['type']}, '
              'date=${activity['date']}, '
              'hasNotes=${activity['notes'] != null}, '
              'outcome=${activity['outcome']}');
        });

        setState(() {
          _timelineData = timelineResponse.data;
        });
      }
    } catch (e) {
        debugPrint('ERROR loading timeline: $e');
      // Silent fail - timeline is optional
    } finally {
      setState(() {
        _isLoadingTimeline = false;
      });
    }
  }

  Future<void> _loadCustomerDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final customerResponse =
          await ApiService.get('/crm/customers/${widget.customerId}');

      if (customerResponse.statusCode != 200) {
        setState(() => _error = 'Customer not found');
        return;
      }

      final responseData = jsonDecode(customerResponse.body) as Map<String, dynamic>;
      final customer =
          Customer.fromJson(responseData['data']['customer'] as Map<String, dynamic>);

      setState(() {
        _customer = customer;
      });
      _loadTimeline();
    } catch (e) {
      setState(() => _error = 'Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _scheduleAppointment() {
    Navigator.of(context).pushNamed(
      '/crm/simplified-appointment',
      arguments: {
        'customerId': widget.customerId,
        'userId': widget.userId,
        'userRole': widget.userRole,
      },
    );
  }

  void _logActivity() {
    Navigator.of(context).pushNamed(
      '/crm/log-activity',
      arguments: {
        'customerId': widget.customerId,
        'userId': widget.userId,
        'userRole': widget.userRole,
      },
    );
  }

  void _recordSale() {
    Navigator.of(context).pushNamed(
      '/crm/add-edit-sale',
      arguments: {'customerId': widget.customerId},
    );
  }

  Future<void> _initiateCall(String phoneNumber, String customerId) async {
    try {
      // Make direct call using CallService
      final callInitiated = await CallService.makeDirectCall(phoneNumber);

      if (!callInitiated) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cannot make calls. Please grant permission in settings.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Show call logging screen after call ends (with a delay for user to complete the call)
      // Note: This provides a reasonable window for users to complete their call
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        _showCallLoggingScreen(customerId, phoneNumber);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error initiating call: $e')),
      );
    }
  }

  Future<void> _showCallLoggingScreen(String customerId, String phoneNumber) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuickActivityLogScreen(
          userId: widget.userId,
          userRole: widget.userRole,
          initialCustomerId: customerId,
          initialActivityType: 'quick_call',
          initialPhoneNumber: phoneNumber,
          initialDurationSeconds: 120, // 2 minutes default estimate
        ),
      ),
    );

    // Refresh timeline if activity was logged
    if (result == true) {
      _loadTimeline();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Customer Details',
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
      ),
      body: _isLoading
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
                        onPressed: _loadCustomerDetails,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0071bf),
                        ),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _customer == null
                  ? const Center(child: Text('Customer not found'))
                  : SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Customer Header Card
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Container(
                              padding: const EdgeInsets.all(20),
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
                                  Text(
                                    _customer!.name,
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF272579),
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      const Icon(Icons.phone, size: 18, color: Color(0xFF0071bf)),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          _customer!.mobileNumber,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            color: Color(0xFF272579),
                                            fontWeight: FontWeight.w500,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.call, color: Color(0xFF5cfbd8)),
                                        onPressed: () => _initiateCall(_customer!.mobileNumber, _customer!.id),
                                        tooltip: 'Call Customer',
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      const Icon(Icons.badge, size: 18, color: Color(0xFF0071bf)),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          _customer!.customerId,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Additional Information Section
                          if (_customer!.email != null && _customer!.email!.isNotEmpty ||
                              _customer!.address != null && _customer!.address!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Container(
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
                                    Text(
                                      'Additional Information',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF272579),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    // Email
                                    if (_customer!.email != null && _customer!.email!.isNotEmpty) ...[
                                      _buildDetailItem(
                                        label: 'Email',
                                        value: _customer!.email!,
                                        icon: Icons.email_outlined,
                                      ),
                                      const SizedBox(height: 12),
                                    ],
                                    // Address
                                    if (_customer!.address != null && _customer!.address!.isNotEmpty) ...[
                                      _buildDetailItem(
                                        label: 'Address',
                                        value: _customer!.address!,
                                        icon: Icons.location_on_outlined,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),

                          const SizedBox(height: 16),

                          // Notes Section (only show if notes exist)
                          if (_customer!.notes != null && _customer!.notes!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Container(
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
                                      children: [
                                        const Icon(
                                          Icons.note_outlined,
                                          size: 20,
                                          color: Color(0xFF272579),
                                        ),
                                        const SizedBox(width: 10),
                                        const Text(
                                          'Notes',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF272579),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      _customer!.notes!,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[700],
                                        height: 1.6,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                          const SizedBox(height: 16),

                          // Quick Actions Card
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Container(
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
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildActionButton(
                                          label: 'Schedule',
                                          icon: Icons.event_note,
                                          onPressed: _scheduleAppointment,
                                          color: const Color(0xFF0071bf),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: _buildActionButton(
                                          label: 'Activity',
                                          icon: Icons.phone_outlined,
                                          onPressed: _logActivity,
                                          color: const Color(0xFF00b8d9),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: _buildActionButton(
                                          label: 'Sale',
                                          icon: Icons.trending_up,
                                          onPressed: _recordSale,
                                          color: const Color(0xFF5cfbd8),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Timeline Section
                          if (_isLoadingTimeline)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(32),
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0071bf)),
                                ),
                              ),
                            )
                          else if (_timelineData != null)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: TimelineWidget(
                                stats: _timelineData!['stats'] as Map<String, dynamic>? ?? {},
                                activities: (_timelineData!['activities'] as List?)
                                    ?.cast<Map<String, dynamic>>() ?? [],
                              ),
                            ),

                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildDetailItem({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFfbf8ff),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF00b8d9).withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 18,
            color: const Color(0xFF0071bf),
          ),
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
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    Color color = const Color(0xFF0071bf),
  }) {
    // Determine text color based on background brightness
    final isDark = color == const Color(0xFF5cfbd8);
    final textColor = isDark ? const Color(0xFF272579) : Colors.white;

    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: color,
        padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 0,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24, color: textColor),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/crm_colors.dart';

class TimelineItem extends StatefulWidget {
  final String type; // 'activity', 'appointment', 'sale'
  final Map<String, dynamic> data;
  final bool isFirst;
  final bool isLast;

  const TimelineItem({
    super.key,
    required this.type,
    required this.data,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  State<TimelineItem> createState() => _TimelineItemState();
}

class _TimelineItemState extends State<TimelineItem> {
  bool _isExpanded = false;

  IconData _getIcon() {
    switch (widget.type) {
      case 'activity':
        final activityType = widget.data['type'] as String?;
        switch (activityType) {
          case 'quick_call':
            return Icons.phone;
          case 'walkin_visit':
            return Icons.store;
          case 'email':
            return Icons.email;
          case 'whatsapp':
            return Icons.chat;
          default:
            return Icons.assignment;
        }
      case 'appointment':
        return Icons.event;
      case 'sale':
        return Icons.trending_up;
      default:
        return Icons.circle;
    }
  }

  Color _getColor() {
    switch (widget.type) {
      case 'activity':
        return CrmColors.secondary;
      case 'appointment':
        return CrmColors.primary;
      case 'sale':
        return CrmColors.success;
      default:
        return Colors.grey;
    }
  }

  String _getTypeLabel() {
    switch (widget.type) {
      case 'activity':
        final activityType = widget.data['type'] as String?;
        const labels = {
          'quick_call': 'Call',
          'walkin_visit': 'Walk-in',
          'email': 'Email',
          'whatsapp': 'WhatsApp',
          'sms': 'SMS',
          'other': 'Other',
        };
        return labels[activityType] ?? 'Activity';
      case 'appointment':
        return 'Appointment';
      case 'sale':
        return 'Sale';
      default:
        return '';
    }
  }

  String _getSummary() {
    switch (widget.type) {
      case 'activity':
        final outcome = widget.data['outcome'] as String?;
        final notes = widget.data['notes'] as String?;
        return notes?.isNotEmpty == true ? notes! : outcome ?? '';
      case 'appointment':
        final purpose = widget.data['purpose'] as String?;
        final status = widget.data['status'] as String?;
        return '${purpose ?? 'Appointment'} - ${status ?? ''}';
      case 'sale':
        final productPlanName = widget.data['productPlanName'] as String?;
        final amount = widget.data['premiumAmount'] ??
                       widget.data['investmentAmount'] ??
                       widget.data['sipAmount'];
        return '${productPlanName ?? 'Product'} - ₹${amount ?? 0}';
      default:
        return '';
    }
  }

  String _getFormattedDate() {
    try {
      final date = widget.data['date'];
      if (date == null) return '';

      final dateTime = date is DateTime ? date : DateTime.parse(date.toString());
      return DateFormat('dd MMM yyyy, hh:mm a').format(dateTime);
    } catch (e) {
      return '';
    }
  }

  Widget _buildExpandedContent() {
    switch (widget.type) {
      case 'activity':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.data['outcome'] != null)
              _buildDetailRow('Outcome', widget.data['outcome'].toString()),
            if (widget.data['notes'] != null && (widget.data['notes'] as String).isNotEmpty)
              _buildDetailRow('Notes', widget.data['notes'].toString()),
            if (widget.data['assignedEmployees'] != null &&
                (widget.data['assignedEmployees'] as List).isNotEmpty)
              _buildDetailRow(
                'Assigned',
                (widget.data['assignedEmployees'] as List)
                    .map((e) {
                      if (e['userId'] is Map) {
                        final user = e['userId'] as Map;
                        return '${user['firstName']} ${user['lastName']}';
                      }
                      return e['userName'] ?? 'Unknown';
                    })
                    .join(', '),
              ),
          ],
        );
      case 'appointment':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.data['purpose'] != null)
              _buildDetailRow('Purpose', widget.data['purpose'].toString()),
            if (widget.data['status'] != null)
              _buildDetailRow('Status', widget.data['status'].toString()),
            if (widget.data['outcome'] != null)
              _buildDetailRow('Outcome', widget.data['outcome'].toString()),
            if (widget.data['assignedEmployees'] != null &&
                (widget.data['assignedEmployees'] as List).isNotEmpty)
              _buildDetailRow(
                'Assigned',
                (widget.data['assignedEmployees'] as List)
                    .map((e) {
                      if (e['userId'] is Map) {
                        final user = e['userId'] as Map;
                        return '${user['firstName']} ${user['lastName']}';
                      }
                      return 'Unknown';
                    })
                    .join(', '),
              ),
          ],
        );
      case 'sale':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.data['productType'] != null)
              _buildDetailRow('Product Type', widget.data['productType'].toString()),
            if (widget.data['companyName'] != null)
              _buildDetailRow('Company', widget.data['companyName'].toString()),
            if (widget.data['premiumAmount'] != null ||
                widget.data['investmentAmount'] != null ||
                widget.data['sipAmount'] != null)
              _buildDetailRow(
                'Amount',
                '₹${widget.data['premiumAmount'] ?? widget.data['investmentAmount'] ?? widget.data['sipAmount']}',
              ),
            if (widget.data['status'] != null)
              _buildDetailRow('Status', widget.data['status'].toString()),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline line and icon
          SizedBox(
            width: 40,
            child: Column(
              children: [
                // Top line
                if (!widget.isFirst)
                  Container(
                    width: 2,
                    height: 12,
                    color: _getColor().withValues(alpha: 0.3),
                  ),
                // Icon
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _getColor(),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getIcon(),
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                // Bottom line
                if (!widget.isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: _getColor().withValues(alpha: 0.3),
                    ),
                  ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => _isExpanded = !_isExpanded);
              },
              child: Container(
                margin: const EdgeInsets.only(left: 12, bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _getColor().withValues(alpha: 0.2),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        // Type badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getColor().withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _getTypeLabel(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _getColor(),
                            ),
                          ),
                        ),
                        const Spacer(),
                        // Expand icon
                        Icon(
                          _isExpanded ? Icons.expand_less : Icons.expand_more,
                          size: 20,
                          color: Colors.grey[600],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Date/time
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 12, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text(
                          _getFormattedDate(),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Summary
                    Text(
                      _getSummary(),
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[800],
                        height: 1.4,
                      ),
                      maxLines: _isExpanded ? null : 2,
                      overflow: _isExpanded ? null : TextOverflow.ellipsis,
                    ),

                    // Expanded details
                    if (_isExpanded) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFfbf8ff),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: _buildExpandedContent(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

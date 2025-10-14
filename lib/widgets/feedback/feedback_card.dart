import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;
import '../../utils/timezone_util.dart';

class FeedbackCard extends StatelessWidget {
  final Map<String, dynamic> feedback;
  final VoidCallback? onTap;
  final bool showUser;
  final bool showPriority;

  const FeedbackCard({
    super.key,
    required this.feedback,
    this.onTap,
    this.showUser = false,
    this.showPriority = true,
  });

  Color _getPriorityColor() {
    final priority = feedback['priority']?.toString() ?? 'low';
    switch (priority) {
      case 'critical':
        return const Color(0xFFf44336); // Red
      case 'high':
        return const Color(0xFFff9800); // Orange
      case 'medium':
        return const Color(0xFF00b8d9); // Secondary blue
      case 'low':
      default:
        return const Color(0xFF4caf50); // Material Green (better legibility)
    }
  }

  Color _getStatusColor() {
    final status = feedback['status']?.toString() ?? 'open';
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

  IconData _getTypeIcon() {
    final type = feedback['type']?.toString() ?? 'feedback';
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

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      // Parse and convert to IST
      final istDate = TimezoneUtil.parseToIST(dateStr);
      final now = TimezoneUtil.nowIST();
      final difference = now.difference(istDate);

      if (difference.inDays == 0) {
        return 'Today ${TimezoneUtil.formatIST(istDate, 'h:mm a')}';
      } else if (difference.inDays == 1) {
        return 'Yesterday ${TimezoneUtil.formatIST(istDate, 'h:mm a')}';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else {
        return TimezoneUtil.dateOnlyIST(istDate);
      }
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final type = feedback['type']?.toString() ?? 'feedback';
    final status = feedback['status']?.toString() ?? 'open';
    final priority = feedback['priority']?.toString() ?? 'low';
    final title = feedback['title']?.toString() ?? 'No title';
    final description = feedback['description']?.toString() ?? '';
    final createdAt = feedback['createdAt']?.toString();
    final attachments = feedback['attachments'] as List<dynamic>?;
    final responses = feedback['responses'] as List<dynamic>?;

    // User info (for admin view)
    final userId = feedback['userId'];
    String userName = '';
    if (showUser && userId != null) {
      final userMap = userId as Map<String, dynamic>;
      final firstName = userMap['firstName']?.toString() ?? '';
      final lastName = userMap['lastName']?.toString() ?? '';
      userName = '$firstName $lastName'.trim();
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: _getPriorityColor().withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with type, priority, and status
              Row(
                children: [
                  // Type icon
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: _getPriorityColor().withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getTypeIcon(),
                      size: 18,
                      color: _getPriorityColor(),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Type and priority labels
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          type.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _getPriorityColor(),
                            letterSpacing: 0.5,
                          ),
                        ),
                        if (showUser && userName.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            userName,
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor().withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _getStatusColor().withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      status.replaceAll('_', ' ').toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: _getStatusColor(),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Title
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF272579),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 6),

              // Description preview
              if (description.isNotEmpty)
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

              const SizedBox(height: 12),

              // Footer with metadata
              Row(
                children: [
                  // Attachments count
                  if (attachments != null && attachments.isNotEmpty) ...[
                    Icon(
                      Icons.attachment,
                      size: 14,
                      color: Colors.grey[500],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${attachments.length}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],

                  // Responses count
                  if (responses != null && responses.isNotEmpty) ...[
                    Icon(
                      Icons.comment,
                      size: 14,
                      color: Colors.grey[500],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${responses.length}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],

                  // Priority badge (only show if showPriority is true)
                  if (showPriority)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getPriorityColor().withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        priority.toUpperCase(),
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: _getPriorityColor(),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),

                  const Spacer(),

                  // Date
                  Text(
                    _formatDate(createdAt),
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

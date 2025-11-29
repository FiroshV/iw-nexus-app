import 'package:flutter/material.dart';
import '../../services/incentive_api_service.dart';
import '../../widgets/incentive_tier_visualizer.dart';
import 'create_edit_template_screen.dart';

/// Screen for admins/directors to manage incentive templates
class IncentiveTemplatesScreen extends StatefulWidget {
  const IncentiveTemplatesScreen({Key? key}) : super(key: key);

  @override
  State<IncentiveTemplatesScreen> createState() =>
      _IncentiveTemplatesScreenState();
}

class _IncentiveTemplatesScreenState extends State<IncentiveTemplatesScreen> {
  late Future<List<Map<String, dynamic>>> _templatesFuture;

  @override
  void initState() {
    super.initState();
    _refreshTemplates();
  }

  void _refreshTemplates() {
    _templatesFuture = IncentiveApiService.getAllTemplates();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Incentive Templates'),
        elevation: 0,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _templatesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load templates',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() => _refreshTemplates()),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final templates = snapshot.data ?? [];

          if (templates.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.dashboard_customize_rounded,
                      size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No Templates Created',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create your first incentive template to get started',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _createTemplate,
                    icon: const Icon(Icons.add),
                    label: const Text('Create Template'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => setState(() => _refreshTemplates()),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: templates.length,
              itemBuilder: (context, index) {
                return _buildTemplateCard(context, templates[index]);
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createTemplate,
        tooltip: 'Create Template',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTemplateCard(
    BuildContext context,
    Map<String, dynamic> template,
  ) {
    final templateName = template['templateName'] as String? ?? 'Unnamed';
    final description = template['description'] as String? ?? '';
    final structureType = template['structureType'] as String? ?? 'unknown';
    final templateId = template['_id'] as String?;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: InkWell(
        onTap: () => _viewTemplateDetails(template),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with name and actions
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          templateName,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getStructureTypeColor(structureType)
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _getStructureTypeLabel(structureType),
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                              color:
                                  _getStructureTypeColor(structureType),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        _editTemplate(template);
                      } else if (value == 'delete') {
                        _deleteTemplate(context, templateId, templateName);
                      }
                    },
                    itemBuilder: (BuildContext context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 18),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 18, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              if (description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              const SizedBox(height: 12),

              // Structure preview
              _buildStructurePreview(context, template, structureType),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStructurePreview(
    BuildContext context,
    Map<String, dynamic> template,
    String structureType,
  ) {
    if (structureType == 'tiered') {
      final tiers = template['tiers'] as List? ?? [];
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tiers: ${tiers.length}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 120,
            child: IncentiveTierVisualizer(
              tiers: tiers.map((t) => Map<String, dynamic>.from(t as Map)).toList(),
            ),
          ),
        ],
      );
    } else if (structureType == 'flat_percentage') {
      final percentage = template['flatPercentage'] as num? ?? 0;
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.percent, color: Color(0xFF0071bf)),
            const SizedBox(width: 8),
            Text(
              'Flat Rate: $percentage% of sales',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF0071bf),
              ),
            ),
          ],
        ),
      );
    } else {
      final amount = template['fixedAmount'] as num? ?? 0;
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.green[50],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.account_balance_wallet, color: Color(0xFF5cfbd8)),
            const SizedBox(width: 8),
            Text(
              'Fixed: ₹${(amount as double).toStringAsFixed(0)}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF5cfbd8),
              ),
            ),
          ],
        ),
      );
    }
  }

  void _createTemplate() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const CreateEditTemplateScreen(),
      ),
    ).then((_) => setState(() => _refreshTemplates()));
  }

  void _editTemplate(Map<String, dynamic> template) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CreateEditTemplateScreen(template: template),
      ),
    ).then((_) => setState(() => _refreshTemplates()));
  }

  void _viewTemplateDetails(Map<String, dynamic> template) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(template['templateName'] as String? ?? 'Template Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if ((template['description'] as String? ?? '').isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Description:',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(template['description'] as String),
                    const SizedBox(height: 12),
                  ],
                ),
              const Text('Type:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(_getStructureTypeLabel(
                  template['structureType'] as String? ?? '')),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _deleteTemplate(
    BuildContext context,
    String? templateId,
    String templateName,
  ) {
    if (templateId == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Template?'),
        content: Text(
          'Are you sure you want to delete "$templateName"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success =
                  await IncentiveApiService.deleteTemplate(templateId);

              if (mounted) {
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Template deleted')),
                  );
                  setState(() => _refreshTemplates());
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to delete template'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Color _getStructureTypeColor(String structureType) {
    switch (structureType.toLowerCase()) {
      case 'tiered':
        return const Color(0xFF0071bf);
      case 'flat_percentage':
        return const Color(0xFF00b8d9);
      case 'fixed':
        return const Color(0xFF5cfbd8);
      default:
        return Colors.grey;
    }
  }

  String _getStructureTypeLabel(String structureType) {
    switch (structureType.toLowerCase()) {
      case 'tiered':
        return 'Tiered Structure';
      case 'flat_percentage':
        return 'Flat Percentage';
      case 'fixed':
        return 'Fixed Amount';
      default:
        return 'Unknown';
    }
  }
}

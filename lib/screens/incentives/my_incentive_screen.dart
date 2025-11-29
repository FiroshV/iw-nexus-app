import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/incentive_api_service.dart';
import '../../widgets/incentive_tier_visualizer.dart';
import '../../widgets/incentive_calculation_helper.dart';

/// Screen for employees to view their assigned incentive structure
class MyIncentiveScreen extends StatefulWidget {
  const MyIncentiveScreen({Key? key}) : super(key: key);

  @override
  State<MyIncentiveScreen> createState() => _MyIncentiveScreenState();
}

class _MyIncentiveScreenState extends State<MyIncentiveScreen> {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _currentIncentive;
  List<Map<String, dynamic>> _history = [];
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadIncentiveData();
  }

  Future<void> _loadIncentiveData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Get current user ID
      final userData = await ApiService.getUserData();
      if (userData == null) {
        throw Exception('Unable to get user data');
      }

      _currentUserId = userData['_id'] as String?;

      // Fetch current incentive structure
      final incentive =
          await IncentiveApiService.getEmployeeIncentive(_currentUserId!);

      // Fetch incentive history
      final history = await IncentiveApiService.getEmployeeIncentiveHistory(
        _currentUserId!,
      );

      setState(() {
        _currentIncentive = incentive;
        _history = history;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load incentive data: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Incentive Structure'),
        elevation: 0,
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadIncentiveData,
        tooltip: 'Refresh',
        child: const Icon(Icons.refresh),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.red[700],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadIncentiveData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_currentIncentive == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No Incentive Structure Assigned',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please contact your administrator to assign an incentive structure.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadIncentiveData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current Structure Card
            _buildCurrentStructureCard(),

            const SizedBox(height: 24),

            // Tier Visualization (if tiered)
            if (_getStructureType() == 'tiered')
              _buildTierVisualization(),

            const SizedBox(height: 24),

            // Calculation Helper
            _buildCalculationHelper(),

            const SizedBox(height: 24),

            // History Section
            if (_history.isNotEmpty) _buildHistorySection(),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStructureCard() {
    final sourceType = _currentIncentive!['sourceType'] as String?;
    final templateId = _currentIncentive!['templateId'];
    final templateName = templateId != null
        ? (templateId is Map
            ? (templateId['templateName'] as String?)
            : null)
        : null;
    final performanceMultiplier =
        _currentIncentive!['performanceMultiplier'] as num? ?? 1.0;
    final effectiveFrom = _currentIncentive!['effectiveFrom'] as String?;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF272579).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.trending_up,
                    color: Color(0xFF272579),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current Incentive Structure',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        sourceType == 'template' ? 'Template-based' : 'Custom',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            Divider(color: Colors.grey[200]),
            const SizedBox(height: 16),

            // Source info
            if (sourceType == 'template' && templateName != null)
              _buildInfoRow('Template', templateName)
            else
              _buildInfoRow('Type', 'Custom Structure'),

            const SizedBox(height: 12),

            _buildInfoRow(
              'Effective From',
              effectiveFrom != null
                  ? _formatDate(effectiveFrom)
                  : 'Not specified',
            ),

            const SizedBox(height: 12),

            // Performance multiplier
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: performanceMultiplier != 1.0
                    ? const Color(0xFF5cfbd8).withValues(alpha: 0.1)
                    : Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Performance Multiplier',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: performanceMultiplier != 1.0
                          ? const Color(0xFF5cfbd8).withValues(alpha: 0.2)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: performanceMultiplier != 1.0
                            ? const Color(0xFF5cfbd8)
                            : Colors.grey[300]!,
                      ),
                    ),
                    child: Text(
                      '${((performanceMultiplier as double) * 100).toStringAsFixed(0)}%',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: performanceMultiplier != 1.0
                            ? const Color(0xFF5cfbd8)
                            : Colors.grey[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            if (performanceMultiplier != 1.0) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF5cfbd8).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF5cfbd8).withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  'You have a ${(((performanceMultiplier as double) - 1.0) * 100).toStringAsFixed(0)}% performance bonus applied to your incentives!',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF00b8d9),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTierVisualization() {
    final tiers = _getStructureTiers();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tier Structure',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        IncentiveTierVisualizer(
          tiers: tiers,
        ),
      ],
    );
  }

  Widget _buildCalculationHelper() {
    return IncentiveCalculationHelper(
      incentiveStructure: _currentIncentive!,
      performanceMultiplier:
          _currentIncentive!['performanceMultiplier'] as double? ?? 1.0,
    );
  }

  Widget _buildHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Assignment History',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _history.length,
          itemBuilder: (context, index) {
            final record = _history[index];
            final createdAt = record['createdAt'] as String?;
            final isActive = record['isActive'] as bool? ?? false;
            final sourceType = record['sourceType'] as String?;

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              elevation: 0,
              color: Colors.grey[50],
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(
                      isActive
                          ? Icons.check_circle
                          : Icons.history,
                      color:
                          isActive ? const Color(0xFF5cfbd8) : Colors.grey[600],
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            createdAt != null ? _formatDate(createdAt) : 'Unknown',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w500),
                          ),
                          Text(
                            sourceType == 'template'
                                ? 'Template-based'
                                : 'Custom',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                    if (isActive)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF5cfbd8).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Active',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: const Color(0xFF5cfbd8),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  String? _getStructureType() {
    if (_currentIncentive == null) return null;

    final sourceType = _currentIncentive!['sourceType'] as String?;

    if (sourceType == 'template') {
      final templateId = _currentIncentive!['templateId'];
      return templateId is Map
          ? (templateId['structureType'] as String?)
          : null;
    } else {
      final customStructure = _currentIncentive!['customStructure'] as Map?;
      return customStructure?['structureType'] as String?;
    }
  }

  List<Map<String, dynamic>> _getStructureTiers() {
    if (_currentIncentive == null) return [];

    final sourceType = _currentIncentive!['sourceType'] as String?;

    if (sourceType == 'template') {
      final templateId = _currentIncentive!['templateId'];
      if (templateId is Map) {
        final tiers = templateId['tiers'] as List? ?? [];
        return tiers.map((t) => Map<String, dynamic>.from(t as Map)).toList();
      }
    } else {
      final customStructure =
          _currentIncentive!['customStructure'] as Map? ?? {};
      final tiers = customStructure['tiers'] as List? ?? [];
      return tiers.map((t) => Map<String, dynamic>.from(t as Map)).toList();
    }

    return [];
  }
}

import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../widgets/feedback/feedback_card.dart';
import '../feedback/feedback_detail_screen.dart';

class FeedbackManagementScreen extends StatefulWidget {
  const FeedbackManagementScreen({super.key});

  @override
  State<FeedbackManagementScreen> createState() => _FeedbackManagementScreenState();
}

class _FeedbackManagementScreenState extends State<FeedbackManagementScreen> {
  List<Map<String, dynamic>> _feedbackList = [];
  Map<String, dynamic>? _stats;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _selectedType;
  String? _selectedStatus;
  String? _selectedPriority;
  String _searchQuery = '';
  int _currentPage = 1;
  int _totalPages = 1;

  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.9) {
      if (!_isLoadingMore && _currentPage < _totalPages) {
        _loadMoreFeedback();
      }
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _currentPage = 1;
    });

    await Future.wait([
      _loadStats(),
      _loadFeedback(),
    ]);
  }

  Future<void> _loadStats() async {
    try {
      final response = await ApiService.getFeedbackStats();
      if (response.success && response.data != null) {
        setState(() {
          _stats = response.data;
        });
      }
    } catch (e) {
      debugPrint('Failed to load feedback stats: $e');
    }
  }

  Future<void> _loadFeedback() async {
    try {
      final response = await ApiService.getAllFeedback(
        page: 1,
        limit: 10,
        type: _selectedType,
        status: _selectedStatus,
        priority: _selectedPriority,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
      );

      if (response.success && response.data != null) {
        final data = response.data!['data'] as List;
        final pagination = response.data!['pagination'] as Map<String, dynamic>;

        setState(() {
          _feedbackList = data.map((item) => item as Map<String, dynamic>).toList();
          _totalPages = pagination['total'] as int;
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

  Future<void> _loadMoreFeedback() async {
    if (_isLoadingMore) return;

    setState(() => _isLoadingMore = true);

    try {
      final response = await ApiService.getAllFeedback(
        page: _currentPage + 1,
        limit: 10,
        type: _selectedType,
        status: _selectedStatus,
        priority: _selectedPriority,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
      );

      if (response.success && response.data != null) {
        final data = response.data!['data'] as List;
        setState(() {
          _feedbackList.addAll(data.map((item) => item as Map<String, dynamic>).toList());
          _currentPage++;
          _isLoadingMore = false;
        });
      } else {
        setState(() => _isLoadingMore = false);
      }
    } catch (e) {
      setState(() => _isLoadingMore = false);
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

  Future<void> _navigateToDetail(String feedbackId) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => FeedbackDetailScreen(feedbackId: feedbackId)),
    );

    if (result == true) {
      _loadData();
    }
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            const Text(
              'Filter Feedback',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF272579),
              ),
            ),

            const SizedBox(height: 24),

            // Type filter
            const Text(
              'Type',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF272579),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildFilterChip('All', null, _selectedType, (value) {
                  setState(() => _selectedType = value);
                }),
                _buildFilterChip('Feedback', 'feedback', _selectedType, (value) {
                  setState(() => _selectedType = value);
                }),
                _buildFilterChip('Complaint', 'complaint', _selectedType, (value) {
                  setState(() => _selectedType = value);
                }),
                _buildFilterChip('Bug', 'bug', _selectedType, (value) {
                  setState(() => _selectedType = value);
                }),
              ],
            ),

            const SizedBox(height: 20),

            // Status filter
            const Text(
              'Status',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF272579),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildFilterChip('All', null, _selectedStatus, (value) {
                  setState(() => _selectedStatus = value);
                }),
                _buildFilterChip('Open', 'open', _selectedStatus, (value) {
                  setState(() => _selectedStatus = value);
                }),
                _buildFilterChip('In Progress', 'in_progress', _selectedStatus, (value) {
                  setState(() => _selectedStatus = value);
                }),
                _buildFilterChip('Resolved', 'resolved', _selectedStatus, (value) {
                  setState(() => _selectedStatus = value);
                }),
                _buildFilterChip('Closed', 'closed', _selectedStatus, (value) {
                  setState(() => _selectedStatus = value);
                }),
              ],
            ),

            const SizedBox(height: 20),

            // Priority filter
            const Text(
              'Priority',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF272579),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildFilterChip('All', null, _selectedPriority, (value) {
                  setState(() => _selectedPriority = value);
                }),
                _buildFilterChip('Low', 'low', _selectedPriority, (value) {
                  setState(() => _selectedPriority = value);
                }),
                _buildFilterChip('Medium', 'medium', _selectedPriority, (value) {
                  setState(() => _selectedPriority = value);
                }),
                _buildFilterChip('High', 'high', _selectedPriority, (value) {
                  setState(() => _selectedPriority = value);
                }),
                _buildFilterChip('Critical', 'critical', _selectedPriority, (value) {
                  setState(() => _selectedPriority = value);
                }),
              ],
            ),

            const SizedBox(height: 24),

            // Apply button
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _selectedType = null;
                        _selectedStatus = null;
                        _selectedPriority = null;
                      });
                      Navigator.pop(context);
                      _loadFeedback();
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF272579),
                      side: const BorderSide(color: Color(0xFF272579)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Clear'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _loadFeedback();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0071bf),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text('Apply Filters'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String? value, String? currentValue, Function(String?) onTap) {
    final isSelected = value == currentValue;
    return InkWell(
      onTap: () => onTap(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0071bf).withValues(alpha: 0.1) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF0071bf) : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? const Color(0xFF0071bf) : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasFilters = _selectedType != null || _selectedStatus != null || _selectedPriority != null;

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
          'Feedback Management',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.filter_list, color: Colors.white),
                onPressed: _showFilterSheet,
              ),
              if (hasFilters)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF5cfbd8),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Stats cards
          if (_stats != null)
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Total',
                      _stats!['total']?.toString() ?? '0',
                      Icons.feedback,
                      const Color(0xFF0071bf),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Open',
                      _stats!['byStatus']?['open']?.toString() ?? '0',
                      Icons.pending,
                      const Color(0xFFff9800),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Resolved',
                      _stats!['byStatus']?['resolved']?.toString() ?? '0',
                      Icons.check_circle,
                      const Color(0xFF5cfbd8),
                    ),
                  ),
                ],
              ),
            ),

          // Search bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search feedback...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                          _loadFeedback();
                        },
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFFf8f9fa),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (value) {
                setState(() => _searchQuery = value);
                _loadFeedback();
              },
            ),
          ),

          // Feedback list
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadData,
              color: const Color(0xFF0071bf),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _feedbackList.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.only(top: 8, bottom: 16),
                          itemCount: _feedbackList.length + (_isLoadingMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == _feedbackList.length) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16),
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }

                            final feedback = _feedbackList[index];
                            final feedbackId = feedback['_id']?.toString() ?? '';

                            return FeedbackCard(
                              feedback: feedback,
                              showUser: true,
                              onTap: feedbackId.isNotEmpty ? () => _navigateToDetail(feedbackId) : null,
                            );
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.feedback_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            hasFilters ? 'No feedback found' : 'No feedback yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hasFilters ? 'Try adjusting your filters' : 'Feedback will appear here',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  bool get hasFilters => _selectedType != null || _selectedStatus != null || _selectedPriority != null;
}

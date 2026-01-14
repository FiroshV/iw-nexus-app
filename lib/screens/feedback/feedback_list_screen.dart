import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/access_control_service.dart';
import '../../widgets/feedback/feedback_card.dart';
import 'submit_feedback_screen.dart';
import 'feedback_detail_screen.dart';

class FeedbackListScreen extends StatefulWidget {
  const FeedbackListScreen({super.key});

  @override
  State<FeedbackListScreen> createState() => _FeedbackListScreenState();
}

class _FeedbackListScreenState extends State<FeedbackListScreen> with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _myFeedbackList = [];
  List<Map<String, dynamic>> _allFeedbackList = [];
  bool _isLoadingMy = true;
  bool _isLoadingAll = true;
  bool _isLoadingMoreMy = false;
  bool _isLoadingMoreAll = false;
  int _currentPageMy = 1;
  int _currentPageAll = 1;
  int _totalPagesMy = 1;
  int _totalPagesAll = 1;

  bool _isAdmin = false;
  String _userRole = '';
  TabController? _tabController;

  final ScrollController _myScrollController = ScrollController();
  final ScrollController _allScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadUserRole();
    _myScrollController.addListener(_onScrollMy);
    _allScrollController.addListener(_onScrollAll);
  }

  @override
  void dispose() {
    _myScrollController.dispose();
    _allScrollController.dispose();
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> _loadUserRole() async {
    final userData = await ApiService.getUserData();
    if (userData != null) {
      setState(() {
        _userRole = userData['role']?.toString() ?? '';
        _isAdmin = AccessControlService.hasAccess(_userRole, 'feedback_management', 'view_all');

        if (_isAdmin) {
          _tabController = TabController(length: 2, vsync: this);
        }
      });

      _loadMyFeedback();
      if (_isAdmin) {
        _loadAllFeedback();
      }
    } else {
      _loadMyFeedback();
    }
  }

  void _onScrollMy() {
    if (_myScrollController.position.pixels >= _myScrollController.position.maxScrollExtent * 0.9) {
      if (!_isLoadingMoreMy && _currentPageMy < _totalPagesMy) {
        _loadMoreMyFeedback();
      }
    }
  }

  void _onScrollAll() {
    if (_allScrollController.position.pixels >= _allScrollController.position.maxScrollExtent * 0.9) {
      if (!_isLoadingMoreAll && _currentPageAll < _totalPagesAll) {
        _loadMoreAllFeedback();
      }
    }
  }

  Future<void> _loadMyFeedback() async {
    setState(() {
      _isLoadingMy = true;
      _currentPageMy = 1;
    });

    try {
      final response = await ApiService.getUserFeedback(
        page: 1,
        limit: 10,
      );

      if (response.success && response.data != null) {
        try {
          final data = response.data;

          if (data is! Map) {
            final feedbackArray = data is List ? data : [];

            setState(() {
              _myFeedbackList = feedbackArray.map((item) {
                if (item is Map<String, dynamic>) {
                  return item;
                } else if (item is Map) {
                  return Map<String, dynamic>.from(item);
                }
                return <String, dynamic>{};
              }).toList();

              _totalPagesMy = 1;
              _isLoadingMy = false;
            });
          } else {
            final dataField = data['data'] as List? ?? [];
            final pagination = data['pagination'] as Map<String, dynamic>? ?? {};

            setState(() {
              _myFeedbackList = dataField.map((item) {
                if (item is Map<String, dynamic>) {
                  return item;
                } else if (item is Map) {
                  return Map<String, dynamic>.from(item);
                }
                return <String, dynamic>{};
              }).toList();

              final total = pagination['total'] ?? pagination['totalPages'] ?? 1;
              _totalPagesMy = total is int ? total : int.tryParse(total.toString()) ?? 1;
              _isLoadingMy = false;
            });
          }
        } catch (parseError) {
          setState(() => _isLoadingMy = false);
          _showError('Failed to parse feedback data: $parseError');
        }
      } else {
        setState(() => _isLoadingMy = false);
        _showError(response.message);
      }
    } catch (e) {
      setState(() => _isLoadingMy = false);
      _showError('Failed to load feedback: $e');
    }
  }

  Future<void> _loadAllFeedback() async {
    setState(() {
      _isLoadingAll = true;
      _currentPageAll = 1;
    });

    try {
      final response = await ApiService.getAllFeedback(
        page: 1,
        limit: 10,
      );

      if (response.success && response.data != null) {
        try {
          final data = response.data;

          if (data is! Map) {
            final feedbackArray = data is List ? data : [];

            setState(() {
              _allFeedbackList = feedbackArray.map((item) {
                if (item is Map<String, dynamic>) {
                  return item;
                } else if (item is Map) {
                  return Map<String, dynamic>.from(item);
                }
                return <String, dynamic>{};
              }).toList();

              _totalPagesAll = 1;
              _isLoadingAll = false;
            });
          } else {
            final dataField = data['data'] as List? ?? [];
            final pagination = data['pagination'] as Map<String, dynamic>? ?? {};

            setState(() {
              _allFeedbackList = dataField.map((item) {
                if (item is Map<String, dynamic>) {
                  return item;
                } else if (item is Map) {
                  return Map<String, dynamic>.from(item);
                }
                return <String, dynamic>{};
              }).toList();

              final total = pagination['total'] ?? pagination['totalPages'] ?? 1;
              _totalPagesAll = total is int ? total : int.tryParse(total.toString()) ?? 1;
              _isLoadingAll = false;
            });
          }
        } catch (parseError) {
          setState(() => _isLoadingAll = false);
          _showError('Failed to parse feedback data: $parseError');
        }
      } else {
        setState(() => _isLoadingAll = false);
        _showError(response.message);
      }
    } catch (e) {
      setState(() => _isLoadingAll = false);
      _showError('Failed to load all feedback: $e');
    }
  }

  Future<void> _loadMoreMyFeedback() async {
    if (_isLoadingMoreMy) return;

    setState(() => _isLoadingMoreMy = true);

    try {
      final response = await ApiService.getUserFeedback(
        page: _currentPageMy + 1,
        limit: 10,
      );

      if (response.success && response.data != null) {
        try {
          final data = response.data;

          if (data is! Map) {
            final feedbackArray = data is List ? data : [];

            setState(() {
              _myFeedbackList.addAll(feedbackArray.map((item) {
                if (item is Map<String, dynamic>) {
                  return item;
                } else if (item is Map) {
                  return Map<String, dynamic>.from(item);
                }
                return <String, dynamic>{};
              }).toList());
              _currentPageMy++;
              _isLoadingMoreMy = false;
            });
          } else {
            final dataField = data['data'] as List? ?? [];
            final pagination = data['pagination'] as Map<String, dynamic>?;

            setState(() {
              _myFeedbackList.addAll(dataField.map((item) {
                if (item is Map<String, dynamic>) {
                  return item;
                } else if (item is Map) {
                  return Map<String, dynamic>.from(item);
                }
                return <String, dynamic>{};
              }).toList());
              _currentPageMy++;
              if (pagination != null) {
                final total = pagination['total'] ?? pagination['totalPages'];
                if (total != null) {
                  _totalPagesMy = total is int ? total : int.tryParse(total.toString()) ?? _totalPagesMy;
                }
              }
              _isLoadingMoreMy = false;
            });
          }
        } catch (e) {
          setState(() => _isLoadingMoreMy = false);
        }
      } else {
        setState(() => _isLoadingMoreMy = false);
      }
    } catch (e) {
      setState(() => _isLoadingMoreMy = false);
    }
  }

  Future<void> _loadMoreAllFeedback() async {
    if (_isLoadingMoreAll) return;

    setState(() => _isLoadingMoreAll = true);

    try {
      final response = await ApiService.getAllFeedback(
        page: _currentPageAll + 1,
        limit: 10,
      );

      if (response.success && response.data != null) {
        try {
          final data = response.data;

          if (data is! Map) {
            final feedbackArray = data is List ? data : [];

            setState(() {
              _allFeedbackList.addAll(feedbackArray.map((item) {
                if (item is Map<String, dynamic>) {
                  return item;
                } else if (item is Map) {
                  return Map<String, dynamic>.from(item);
                }
                return <String, dynamic>{};
              }).toList());
              _currentPageAll++;
              _isLoadingMoreAll = false;
            });
          } else {
            final dataField = data['data'] as List? ?? [];
            final pagination = data['pagination'] as Map<String, dynamic>?;

            setState(() {
              _allFeedbackList.addAll(dataField.map((item) {
                if (item is Map<String, dynamic>) {
                  return item;
                } else if (item is Map) {
                  return Map<String, dynamic>.from(item);
                }
                return <String, dynamic>{};
              }).toList());
              _currentPageAll++;
              if (pagination != null) {
                final total = pagination['total'] ?? pagination['totalPages'];
                if (total != null) {
                  _totalPagesAll = total is int ? total : int.tryParse(total.toString()) ?? _totalPagesAll;
                }
              }
              _isLoadingMoreAll = false;
            });
          }
        } catch (e) {
          setState(() => _isLoadingMoreAll = false);
        }
      } else {
        setState(() => _isLoadingMoreAll = false);
      }
    } catch (e) {
      setState(() => _isLoadingMoreAll = false);
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

  Future<void> _navigateToSubmit() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SubmitFeedbackScreen()),
    );

    if (result == true) {
      _loadMyFeedback();
    }
  }

  Future<void> _navigateToDetail(String feedbackId) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => FeedbackDetailScreen(feedbackId: feedbackId)),
    );

    if (result == true) {
      // Refresh current tab
      if (_isAdmin && _tabController != null) {
        if (_tabController!.index == 0) {
          _loadMyFeedback();
        } else {
          _loadAllFeedback();
        }
      } else {
        _loadMyFeedback();
      }
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
          'Feedback',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        bottom: _isAdmin && _tabController != null
            ? TabBar(
                controller: _tabController,
                indicatorColor: Colors.white,
                indicatorWeight: 3,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                labelStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                tabs: const [
                  Tab(text: 'My Feedback'),
                  Tab(text: 'All Feedback'),
                ],
              )
            : null,
      ),
      body: _isAdmin && _tabController != null
          ? TabBarView(
              controller: _tabController,
              children: [
                _buildMyFeedbackTab(),
                _buildAllFeedbackTab(),
              ],
            )
          : _buildMyFeedbackTab(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToSubmit,
        backgroundColor: const Color(0xFF0071bf),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New Feedback', style: TextStyle(color: Colors.white),),
      ),
    );
  }

  Widget _buildMyFeedbackTab() {
    return RefreshIndicator(
      onRefresh: _loadMyFeedback,
      color: const Color(0xFF0071bf),
      child: _isLoadingMy
          ? const Center(child: CircularProgressIndicator())
          : _myFeedbackList.isEmpty
              ? _buildEmptyState('No feedback yet', 'Share your thoughts with us!')
              : ListView.builder(
                  controller: _myScrollController,
                  padding: const EdgeInsets.only(top: 8, bottom: 80),
                  itemCount: _myFeedbackList.length + (_isLoadingMoreMy ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _myFeedbackList.length) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }

                    final feedback = _myFeedbackList[index];
                    final feedbackId = feedback['_id']?.toString() ?? '';

                    return FeedbackCard(
                      feedback: feedback,
                      onTap: feedbackId.isNotEmpty ? () => _navigateToDetail(feedbackId) : null,
                      showPriority: false, // Don't show priority in "My Feedback" tab
                    );
                  },
                ),
    );
  }

  Widget _buildAllFeedbackTab() {
    return RefreshIndicator(
      onRefresh: _loadAllFeedback,
      color: const Color(0xFF0071bf),
      child: _isLoadingAll
          ? const Center(child: CircularProgressIndicator())
          : _allFeedbackList.isEmpty
              ? _buildEmptyState('No feedback submitted', 'All user feedback will appear here')
              : ListView.builder(
                  controller: _allScrollController,
                  padding: const EdgeInsets.only(top: 8, bottom: 80),
                  itemCount: _allFeedbackList.length + (_isLoadingMoreAll ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _allFeedbackList.length) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }

                    final feedback = _allFeedbackList[index];
                    final feedbackId = feedback['_id']?.toString() ?? '';

                    return FeedbackCard(
                      feedback: feedback,
                      onTap: feedbackId.isNotEmpty ? () => _navigateToDetail(feedbackId) : null,
                      showUser: true, // Show user info in "All Feedback" tab
                    );
                  },
                ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
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
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}

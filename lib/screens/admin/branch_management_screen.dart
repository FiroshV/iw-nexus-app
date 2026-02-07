import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../services/access_control_service.dart';
import '../../providers/auth_provider.dart';
import '../../models/branch_model.dart';
import 'add_edit_branch_screen.dart';

class BranchManagementScreen extends StatefulWidget {
  const BranchManagementScreen({super.key});

  @override
  State<BranchManagementScreen> createState() => _BranchManagementScreenState();
}

class _BranchManagementScreenState extends State<BranchManagementScreen> {
  List<Branch> branches = [];
  bool isLoading = true;
  String? error;
  int currentPage = 1;
  int totalPages = 1;
  bool hasMore = true;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  bool showFilters = false;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _loadBranches();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      if (hasMore && !isLoading) {
        _loadMoreBranches();
      }
    }
  }

  Future<void> _loadBranches({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        currentPage = 1;
        branches.clear();
        hasMore = true;
        isLoading = true;
        error = null;
      });
    }

    try {
      final response = await ApiService.getBranches(
        page: currentPage,
        limit: 20,
        status: null,
        search: _searchController.text.isEmpty ? null : _searchController.text,
      );

      if (response.success && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final branchList = data['branches'] as List<dynamic>? ?? [];
        final pagination = data['pagination'] as Map<String, dynamic>? ?? {};

        List<Branch> newBranches = branchList
            .map((json) => Branch.fromJson(json as Map<String, dynamic>))
            .toList();

        if (mounted) {
          setState(() {
            if (refresh) {
              branches = newBranches;
            } else {
              branches.addAll(newBranches);
            }

            currentPage = pagination['currentPage'] ?? 1;
            totalPages = pagination['totalPages'] ?? 1;
            hasMore = pagination['hasNext'] ?? false;
            isLoading = false;
            error = null;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            error = response.message;
            isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          error = 'Failed to load branches: $e';
          isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMoreBranches() async {
    if (isLoading || !hasMore) return;

    setState(() {
      isLoading = true;
    });

    currentPage++;
    await _loadBranches();
  }

  Future<void> _refreshBranches() async {
    await _loadBranches(refresh: true);
  }

  void _showDeleteConfirmation(Branch branch) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Delete Branch',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(0xFF272579),
            ),
          ),
          content: SingleChildScrollView(
            child: Text(
              'Are you sure you want to delete "${branch.branchName}"?\n\nThis action cannot be undone.',
              style: const TextStyle(fontSize: 16),
            ),
          ),
          actions: [
            TextButton(
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Delete',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              onPressed: () async {
                Navigator.of(context).pop();
                if (mounted) {
                  await _deleteBranch(branch);
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteBranch(Branch branch) async {
    try {
      final response = await ApiService.deleteBranch(branch.id);

      if (mounted) {
        if (response.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Branch "${branch.branchName}" deleted successfully',
              ),
              backgroundColor: Colors.green,
            ),
          );
          _refreshBranches();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete branch: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildBranchCard(Branch branch) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          final userRole = authProvider.user?['role'] as String?;
          final canEdit = AccessControlService.hasAccess(userRole, 'branch_management', 'edit');

          return InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: canEdit ? () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddEditBranchScreen(branch: branch),
                ),
              );
              if (result == true) {
                _refreshBranches();
              }
            } : null,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF5cfbd8).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.business,
                      color: Color(0xFF0071bf),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          branch.branchName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF272579),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          branch.branchId,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Consumer<AuthProvider>(
                    builder: (context, authProvider, _) {
                      final userRole = authProvider.user?['role'] as String?;
                      final canEdit = AccessControlService.hasAccess(userRole, 'branch_management', 'edit');
                      final canDelete = AccessControlService.hasAccess(userRole, 'branch_management', 'delete');

                      // Don't show popup menu if user has no edit/delete permissions
                      if (!canEdit && !canDelete) {
                        return const SizedBox.shrink();
                      }

                      return PopupMenuButton(
                        onSelected: (value) {
                          if (value == 'edit' && canEdit) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    AddEditBranchScreen(branch: branch),
                              ),
                            ).then((result) {
                              if (result == true) {
                                _refreshBranches();
                              }
                            });
                          } else if (value == 'delete' && canDelete) {
                            _showDeleteConfirmation(branch);
                          }
                        },
                        itemBuilder: (context) => [
                          if (canEdit)
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit, size: 20),
                                  SizedBox(width: 8),
                                  Text('Edit'),
                                ],
                              ),
                            ),
                          if (canDelete)
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete, size: 20, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('Delete', style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Icon(
                      Icons.location_on,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      branch.branchName,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Icon(
                      Icons.person,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Manager: ${branch.managerName}',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(Icons.people, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      '${branch.employeeCount} employees',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                 
                ],
              ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          'Branches',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      backgroundColor: const Color(0xFFf8f9fa),
      body: Column(
        children: [
          // Search bar
          Container(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                _debounceTimer?.cancel();
                _debounceTimer = Timer(const Duration(milliseconds: 500), () {
                  _refreshBranches();
                });
              },
              decoration: InputDecoration(
                hintText: 'Search branches...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),

          // Content
          Expanded(
            child: error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          error!,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _refreshBranches,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF272579),
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : branches.isEmpty && !isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.business_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No branches found',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add your first branch to get started',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _refreshBranches,
                    child: ListView.builder(
                      controller: _scrollController,
                      itemCount: branches.length + (isLoading ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index >= branches.length) {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        return _buildBranchCard(branches[index]);
                      },
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          final userRole = authProvider.user?['role'] as String?;
          final canCreate = AccessControlService.hasAccess(userRole, 'branch_management', 'create');

          if (!canCreate) {
            return const SizedBox.shrink();
          }

          return FloatingActionButton(
            heroTag: null,
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddEditBranchScreen(),
                ),
              );
              if (result == true) {
                _refreshBranches();
              }
            },
            backgroundColor: const Color(0xFF5cfbd8),
            foregroundColor: const Color(0xFF272579),
            child: const Icon(Icons.add),
          );
        },
      ),
    );
  }
}

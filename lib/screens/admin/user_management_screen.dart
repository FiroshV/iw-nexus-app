import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../services/access_control_service.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/loading_widget.dart';
import 'add_user_screen.dart';
import 'edit_user_screen.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  List<Map<String, dynamic>> users = [];
  bool isLoading = true;
  String? error;
  int currentPage = 1;
  int totalPages = 1;
  bool hasMore = true;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      if (hasMore && !isLoading) {
        _loadMoreUsers();
      }
    }
  }

  Future<void> _loadUsers({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        currentPage = 1;
        users.clear();
        hasMore = true;
        isLoading = true;
        error = null;
      });
    }

    try {
      final response = await ApiService.getAllUsers(
        page: currentPage,
        limit: 20,
        search: _searchController.text.isEmpty ? null : _searchController.text,
      );

      if (response.success && response.data != null) {
        List<Map<String, dynamic>> newUsers;
        Map<String, dynamic>? pagination;

        // Handle different response formats
        if (response.data is List) {
          // Direct array response
          newUsers = List<Map<String, dynamic>>.from(response.data as List);
          pagination = null; // No pagination info in direct array response
        } else if (response.data is Map<String, dynamic>) {
          // Standard object response with data and pagination
          final responseMap = response.data as Map<String, dynamic>;
          newUsers = List<Map<String, dynamic>>.from(responseMap['data'] ?? []);
          pagination = responseMap['pagination'] as Map<String, dynamic>?;
        } else {
          // Unexpected response format
          newUsers = [];
          pagination = null;
        }

        setState(() {
          // Filter out admin users
          final filteredUsers = newUsers.where((user) => 
            user['role'] != 'admin'
          ).toList();
          
          if (refresh || currentPage == 1) {
            users = filteredUsers;
          } else {
            users.addAll(filteredUsers);
          }

          if (pagination != null) {
            totalPages = pagination['total'] ?? 1;
            hasMore = currentPage < totalPages;
          } else {
            // If no pagination info, assume this is the only page
            totalPages = 1;
            hasMore = false;
          }

          isLoading = false;
          error = null;
        });
      } else {
        setState(() {
          isLoading = false;
          error = response.message;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        error = 'Failed to load users: $e';
      });
    }
  }

  Future<void> _loadMoreUsers() async {
    if (hasMore && !isLoading) {
      setState(() {
        currentPage++;
      });
      await _loadUsers();
    }
  }

  Future<void> _deleteUser(String userId, String userName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: Text(
          'Are you sure you want to deactivate $userName? This action will terminate their account.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final response = await ApiService.deleteUser(userId);
        if (!mounted) return;
        if (response.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('User $userName deactivated successfully'),
              backgroundColor: Colors.green,
            ),
          );
          _loadUsers(refresh: true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete user: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    final String fullName =
        '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}'.trim();
    final String employeeId = user['employeeId'] ?? '';
    final String email = user['email'] ?? '';
    // final String role = user['role'] ?? '';
    final String designation = user['designation'] ?? '';
    final String employmentType = user['employmentType'] ?? 'permanent';

    // Cache access control checks to avoid multiple calls during build
    final currentUser = context.read<AuthProvider>().user;
    final canEdit = AccessControlService.canManageUser(currentUser, user, 'edit');
    final canDelete = AccessControlService.canManageUser(currentUser, user, 'delete');

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, const Color(0xFFfbf8ff)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: const Color(0xFF272579).withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
        border: Border.all(
          color: const Color(0xFF272579).withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                // User Avatar
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: user['avatar'] != null
                        ? null
                        : const LinearGradient(
                            colors: [Color(0xFF272579), Color(0xFF0071bf)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF272579).withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: user['avatar'] != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            user['avatar'],
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Color(0xFF272579), Color(0xFF0071bf)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    fullName.isNotEmpty ? fullName[0].toUpperCase() : 'U',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        )
                      : Center(
                          child: Text(
                            fullName.isNotEmpty ? fullName[0].toUpperCase() : 'U',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                ),

                const SizedBox(width: 16),

                // User Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              fullName.isEmpty ? 'Unknown User' : fullName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF272579),
                                letterSpacing: -0.2,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 6),

                      Row(
                        children: [
                          Icon(
                            Icons.badge_rounded,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'ID: $employeeId',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 4),

                      Row(
                        children: [
                          Icon(
                            Icons.email_rounded,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              email,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),

                      Row(
                        children: [
                          Icon(
                            Icons.work_rounded,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Designation: $designation',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.business_center_rounded,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Employment: ${employmentType.substring(0, 1).toUpperCase()}${employmentType.substring(1)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Actions Menu - Only show if user has any management permissions
                // If user has no permissions, show empty space to maintain layout
                if (!canEdit && !canDelete)
                  const SizedBox(
                    width: 36,
                    height: 36,
                  )
                else
                  PopupMenuButton(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF272579).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.more_vert_rounded,
                          color: const Color(0xFF272579),
                          size: 20,
                        ),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      itemBuilder: (context) {
                        final menuItems = <PopupMenuEntry<String>>[];

                        if (canEdit) {
                          menuItems.add(
                            PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFF0071bf,
                                      ).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.edit_rounded,
                                      size: 16,
                                      color: Color(0xFF0071bf),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'Edit User',
                                    style: TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        if (canDelete) {
                          menuItems.add(
                            PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.delete_rounded,
                                      size: 16,
                                      color: Colors.red,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'Delete User',
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        return menuItems;
                      },
                      onSelected: (value) {
                        switch (value) {
                          case 'edit':
                            Navigator.of(context)
                                .push(
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        EditUserScreen(user: user),
                                  ),
                                )
                                .then((_) => _loadUsers(refresh: true));
                            break;
                          case 'delete':
                            _deleteUser(user['_id'], fullName);
                            break;
                        }
                      },
                    ),
              ],
            ),
          ],
        ),
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
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.people_outline,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'User Management',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                  Text(
                    'Manage team members',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        foregroundColor: Colors.white,
      ),
      backgroundColor: const Color(0xFFf8f9fa),
      body: RefreshIndicator(
        onRefresh: () => _loadUsers(refresh: true),
        color: const Color(0xFF272579),
        child: Column(
          children: [
            // Search and filters section
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Search bar with filter button
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              color: const Color(0xFFf8f9fa),
                              border: Border.all(
                                color: const Color(
                                  0xFF272579,
                                ).withValues(alpha: 0.1),
                                width: 1,
                              ),
                            ),
                            child: TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                hintText:
                                    'Search by name, email, or employee ID...',
                                hintStyle: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 14,
                                ),
                                prefixIcon: Icon(
                                  Icons.search_rounded,
                                  color: const Color(
                                    0xFF272579,
                                  ).withValues(alpha: 0.6),
                                ),
                                suffixIcon: _searchController.text.isNotEmpty
                                    ? IconButton(
                                        icon: Icon(
                                          Icons.clear_rounded,
                                          color: Colors.grey[600],
                                        ),
                                        onPressed: () {
                                          _searchController.clear();
                                          _loadUsers(refresh: true);
                                        },
                                      )
                                    : null,
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                              ),
                              onChanged: (value) {
                                // Debounce search
                                Future.delayed(
                                  const Duration(milliseconds: 500),
                                  () {
                                    if (_searchController.text == value) {
                                      _loadUsers(refresh: true);
                                    }
                                  },
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Users list
            Expanded(
              child: error != null
                  ? Center(
                      child: Container(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Icon(
                                Icons.error_outline_rounded,
                                size: 48,
                                color: Colors.red[400],
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Oops! Something went wrong',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.grey[800],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              error!,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: () => _loadUsers(refresh: true),
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text('Try Again'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF272579),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : users.isEmpty
                  ? isLoading
                        ? const LoadingWidget(message: 'Loading users...')
                        : Center(
                            child: Container(
                              padding: const EdgeInsets.all(40),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFF272579,
                                      ).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Icon(
                                      Icons.people_outline_rounded,
                                      size: 48,
                                      color: const Color(0xFF272579),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  Text(
                                    'No users found',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Try adjusting your search or filters',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(20),
                      itemCount: users.length + (hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index >= users.length) {
                          return Container(
                            padding: const EdgeInsets.all(20),
                            alignment: Alignment.center,
                            child: const CircularProgressIndicator(
                              color: Color(0xFF272579),
                              strokeWidth: 2,
                            ),
                          );
                        }
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: _buildUserCard(users[index]),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            colors: [Color(0xFF272579), Color(0xFF0071bf)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF272579).withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 8),
              spreadRadius: 0,
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: () {
            Navigator.of(context)
                .push(
                  MaterialPageRoute(
                    builder: (context) => const AddUserScreen(),
                  ),
                )
                .then((_) => _loadUsers(refresh: true));
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          icon: const Icon(
            Icons.person_add_rounded,
            color: Colors.white,
            size: 20,
          ),
          label: const Text(
            'Add User',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}

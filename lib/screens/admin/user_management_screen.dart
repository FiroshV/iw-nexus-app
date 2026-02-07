import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../services/access_control_service.dart';
import '../../services/incentive_service.dart';
import '../../providers/auth_provider.dart';
import '../../models/employee_incentive.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/staff_attendance_widget.dart';
import '../../widgets/staff_documents_widget.dart';
import '../../utils/date_util.dart';
import 'add_user_screen.dart';
import 'edit_user_screen.dart';
import 'payroll/salary_structure_form_screen.dart';

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

  void _showUserDetailsBottomSheet(Map<String, dynamic> user) {
    final String fullName =
        '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}'.trim();
    final String employeeId = user['employeeId'] ?? '';
    final String email = user['email'] ?? '';
    final String designation = user['designation'] ?? '';
    final String employmentType = user['employmentType'] ?? 'permanent';
    final String role = user['role'] ?? '';
    final String userId = user['_id'] ?? '';

    // Check if current user can view staff attendance
    final currentUser = context.read<AuthProvider>().user;
    final currentUserRole = currentUser == null ? null : currentUser['role']?.toString();
    final canViewStaffAttendance = AccessControlService.hasAccess(
      currentUserRole,
      'attendance',
      'view_all',
    ) || AccessControlService.hasAccess(
      currentUserRole,
      'attendance',
      'view_team',
    );

    // Check if current user can view user documents (admin/director only)
    final canViewUserDocuments = AccessControlService.hasAccess(
      currentUserRole,
      'document_management',
      'view_user',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _UserDetailsBottomSheet(
        user: user,
        fullName: fullName,
        employeeId: employeeId,
        email: email,
        designation: designation,
        employmentType: employmentType,
        role: role,
        userId: userId,
        canViewStaffAttendance: canViewStaffAttendance,
        canViewUserDocuments: canViewUserDocuments,
      ),
    );
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

  void _showIncentiveBottomSheet(Map<String, dynamic> user) {
    final String fullName =
        '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}'.trim();
    final String userId = user['_id'] ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _UserIncentiveBottomSheet(
        userId: userId,
        userName: fullName,
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    final String fullName =
        '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}'.trim();
    final String employeeId = user['employeeId'] ?? '';
    // final String role = user['role'] ?? '';
    final String designation = user['designation'] ?? '';

    // Cache access control checks to avoid multiple calls during build
    final currentUser = context.read<AuthProvider>().user;

    debugPrint('🔥🔥🔥 USER CARD: Building card for ${user['firstName']} ${user['lastName']} (${user['role']})');
    debugPrint('🔥🔥🔥 USER CARD: Current user role: ${currentUser == null ? 'null' : currentUser['role']}');

    final canEdit = AccessControlService.canManageUser(currentUser, user, 'edit');
    final canDelete = AccessControlService.canManageUser(currentUser, user, 'delete');
    final currentUserRole = currentUser == null ? null : currentUser['role']?.toString();
    final canViewIncentive = AccessControlService.hasAccess(
      currentUserRole,
      'incentive_management',
      'view_assignments',
    );

    debugPrint('🔥🔥🔥 USER CARD: canEdit: $canEdit, canDelete: $canDelete');

    return GestureDetector(
      onTap: () => _showUserDetailsBottomSheet(user),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: const Color(0xFF272579).withValues(alpha: 0.06),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // User Avatar
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: user['avatar'] == null
                      ? const LinearGradient(
                          colors: [Color(0xFF272579), Color(0xFF0071bf)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: user['avatar'] != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          user['avatar'],
                          width: 48,
                          height: 48,
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
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
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
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
              ),

              const SizedBox(width: 12),

              // User Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fullName.isEmpty ? 'Unknown User' : fullName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF272579),
                        letterSpacing: -0.1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      designation,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 1),
                    Text(
                      employeeId,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),

              // Quick actions
              Row(
                children: [
                  // Actions Menu - Only show if user has any management permissions
                  if (canEdit || canDelete)
                    PopupMenuButton(
                      icon: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF272579).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.more_vert_rounded,
                          color: const Color(0xFF272579),
                          size: 16,
                        ),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      itemBuilder: (context) {
                        final menuItems = <PopupMenuEntry<String>>[];

                        // Setup Salary option (always available for non-admin users)
                        if (user['role'] != 'admin') {
                          menuItems.add(
                            PopupMenuItem(
                              value: 'salary',
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.account_balance_wallet_rounded,
                                    size: 16,
                                    color: const Color(0xFF0071bf),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Setup Salary',
                                    style: TextStyle(fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        // View Incentive option (for admin/director)
                        if (canViewIncentive && user['role'] != 'admin') {
                          menuItems.add(
                            PopupMenuItem(
                              value: 'incentive',
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.trending_up_rounded,
                                    size: 16,
                                    color: const Color(0xFF00b8d9),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'View Incentive',
                                    style: TextStyle(fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        if (canEdit) {
                          menuItems.add(
                            PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.edit_rounded,
                                    size: 16,
                                    color: const Color(0xFF0071bf),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Edit',
                                    style: TextStyle(fontWeight: FontWeight.w500),
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
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.delete_rounded,
                                    size: 16,
                                    color: Colors.red,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Delete',
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.w500,
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
                          case 'salary':
                            Navigator.of(context)
                                .push(
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        SalaryStructureFormScreen(
                                          userId: user['_id'] as String,
                                          userName: fullName,
                                        ),
                                  ),
                                )
                                .then((_) => _loadUsers(refresh: true));
                            break;
                          case 'incentive':
                            _showIncentiveBottomSheet(user);
                            break;
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
                    )
                  else
                    const SizedBox(width: 30), // Maintain layout spacing
                ],
              ),
            ],
          ),
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
          heroTag: null,
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

// Bottom sheet widget for user details with tabs
class _UserDetailsBottomSheet extends StatefulWidget {
  final Map<String, dynamic> user;
  final String fullName;
  final String employeeId;
  final String email;
  final String designation;
  final String employmentType;
  final String role;
  final String userId;
  final bool canViewStaffAttendance;
  final bool canViewUserDocuments;

  const _UserDetailsBottomSheet({
    required this.user,
    required this.fullName,
    required this.employeeId,
    required this.email,
    required this.designation,
    required this.employmentType,
    required this.role,
    required this.userId,
    required this.canViewStaffAttendance,
    required this.canViewUserDocuments,
  });

  @override
  State<_UserDetailsBottomSheet> createState() => _UserDetailsBottomSheetState();
}

class _UserDetailsBottomSheetState extends State<_UserDetailsBottomSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late int _tabCount;
  late bool _showTabs;

  @override
  void initState() {
    super.initState();
    // Calculate tab count: Details (always) + Attendance (optional) + Documents (optional)
    _tabCount = 1; // Details tab is always shown
    if (widget.canViewStaffAttendance) _tabCount++;
    if (widget.canViewUserDocuments) _tabCount++;
    _showTabs = _tabCount > 1;

    _tabController = TabController(
      length: _tabCount,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF272579).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 16,
              color: const Color(0xFF272579),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF272579),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailRow(Icons.badge_rounded, 'Employee ID', widget.employeeId),
          _buildDetailRow(Icons.email_rounded, 'Email', widget.email),
          _buildDetailRow(
            Icons.business_center_rounded,
            'Employment Type',
            '${widget.employmentType.substring(0, 1).toUpperCase()}${widget.employmentType.substring(1)}',
          ),
          if (widget.user['phoneNumber'] != null)
            _buildDetailRow(Icons.phone_rounded, 'Phone', widget.user['phoneNumber']),
          if (widget.user['dateOfJoining'] != null)
            _buildDetailRow(
              Icons.calendar_today_rounded,
              'Date of Joining',
              DateUtil.formatDateForDisplayLong(
                DateUtil.parseDateFromApi(widget.user['dateOfJoining']),
              ),
            ),
          if (widget.user['branchId'] != null && widget.user['branchId'] is Map)
            _buildDetailRow(
              Icons.location_on_rounded,
              'Branch',
              widget.user['branchId']['branchName'] ?? 'Unknown Branch',
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // User Avatar
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: widget.user['avatar'] == null
                        ? const LinearGradient(
                            colors: [Color(0xFF272579), Color(0xFF0071bf)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: widget.user['avatar'] != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            widget.user['avatar'],
                            width: 64,
                            height: 64,
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
                                    widget.fullName.isNotEmpty
                                        ? widget.fullName[0].toUpperCase()
                                        : 'U',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
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
                            widget.fullName.isNotEmpty
                                ? widget.fullName[0].toUpperCase()
                                : 'U',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                ),

                const SizedBox(width: 16),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.fullName.isEmpty ? 'Unknown User' : widget.fullName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF272579),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.designation,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0071bf).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          widget.role.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF0071bf),
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Tab bar (only show if more than 1 tab)
          if (_showTabs)
            Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Colors.grey.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorColor: const Color(0xFF0071bf),
                indicatorWeight: 3,
                labelColor: const Color(0xFF0071bf),
                unselectedLabelColor: Colors.grey,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                tabs: [
                  const Tab(
                    icon: Icon(Icons.info_outline, size: 18),
                    text: 'Details',
                  ),
                  if (widget.canViewStaffAttendance)
                    const Tab(
                      icon: Icon(Icons.calendar_today, size: 18),
                      text: 'Attendance',
                    ),
                  if (widget.canViewUserDocuments)
                    const Tab(
                      icon: Icon(Icons.folder_outlined, size: 18),
                      text: 'Documents',
                    ),
                ],
              ),
            ),

          // Content
          Expanded(
            child: _showTabs
                ? TabBarView(
                    controller: _tabController,
                    children: [
                      _buildDetailsTab(),
                      if (widget.canViewStaffAttendance)
                        StaffAttendanceWidget(
                          userId: widget.userId,
                          userName: widget.fullName,
                        ),
                      if (widget.canViewUserDocuments)
                        StaffDocumentsWidget(
                          userId: widget.userId,
                          userName: widget.fullName,
                          employeeId: widget.employeeId,
                        ),
                    ],
                  )
                : _buildDetailsTab(),
          ),
        ],
      ),
    );
  }
}

/// Bottom sheet widget for displaying user incentive details
class _UserIncentiveBottomSheet extends StatefulWidget {
  final String userId;
  final String userName;

  const _UserIncentiveBottomSheet({
    required this.userId,
    required this.userName,
  });

  @override
  State<_UserIncentiveBottomSheet> createState() =>
      _UserIncentiveBottomSheetState();
}

class _UserIncentiveBottomSheetState extends State<_UserIncentiveBottomSheet> {
  bool _isLoading = true;
  String? _error;
  EmployeeIncentive? _incentive;

  @override
  void initState() {
    super.initState();
    _loadIncentive();
  }

  Future<void> _loadIncentive() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await IncentiveService.getEmployeeIncentive(widget.userId);

      if (!mounted) return;

      if (response.success && response.data != null) {
        setState(() {
          _incentive = response.data;
          _isLoading = false;
        });
      } else {
        // Check if this is "no assignment" vs actual error
        final message = response.message?.toLowerCase() ?? '';
        final isNoAssignment = message.contains('no incentive') ||
            message.contains('not found') ||
            message.contains('no assignment');

        setState(() {
          if (isNoAssignment) {
            // Valid state - user has no incentive assigned
            _incentive = null;
            _error = null;
          } else {
            // Actual error
            _error = response.message ?? 'Failed to load incentive';
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Error loading incentive: $e';
        _isLoading = false;
      });
    }
  }

  String _getCurrentMonth() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  MonthlyProgress? _getCurrentMonthProgress() {
    if (_incentive == null) return null;
    final incentive = _incentive!;
    final currentMonth = _getCurrentMonth();
    try {
      return incentive.monthlyProgress.firstWhere(
        (p) => p.month == currentMonth,
      );
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00b8d9), Color(0xFF0071bf)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.trending_up_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.userName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF272579),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Incentive Details',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    Icons.close_rounded,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF272579),
                    ),
                  )
                : _error != null
                    ? _buildErrorState()
                    : _incentive == null
                        ? _buildNoIncentiveState()
                        : _buildIncentiveDetails(),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 40,
                color: Colors.red[400],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Unable to load incentive',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Unknown error',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: _loadIncentive,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoIncentiveState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF272579).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.assignment_outlined,
                size: 40,
                color: const Color(0xFF272579).withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No Incentive Assigned',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This employee has not been assigned an incentive template yet.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIncentiveDetails() {
    final template = _incentive!.currentTemplate;
    final currentMonthProgress = _getCurrentMonthProgress();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Current Bracket Card
          _buildCard(
            title: 'Current Bracket',
            icon: Icons.workspace_premium_rounded,
            iconColor: const Color(0xFF00b8d9),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        template?.name ?? 'Unknown Template',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF272579),
                        ),
                      ),
                    ),
                  ],
                ),
                if (template != null &&
                    template.description != null &&
                    template.description!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    template.description!,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Commission Rates Card
          if (template?.commissionRates != null)
            _buildCard(
              title: 'Commission Rates',
              icon: Icons.percent_rounded,
              iconColor: const Color(0xFF0071bf),
              child: Column(
                children: [
                  _buildCommissionRow(
                    'Life Insurance',
                    template!.commissionRates.lifeInsurance,
                  ),
                  _buildCommissionRow(
                    'General Insurance',
                    template.commissionRates.generalInsurance,
                  ),
                  _buildCommissionRow(
                    'Mutual Funds',
                    template.commissionRates.mutualFunds,
                  ),
                ],
              ),
            ),

          const SizedBox(height: 16),

          // Current Month Progress Card
          _buildCard(
            title: 'Current Month Progress',
            icon: Icons.timeline_rounded,
            iconColor: const Color(0xFF5cfbd8),
            child: currentMonthProgress != null
                ? _buildProgressContent(currentMonthProgress)
                : Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        'No sales recorded this month',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ),
          ),

          const SizedBox(height: 16),

          // Next Bracket Preview
          if (_incentive!.currentTemplate?.nextTemplate != null)
            _buildCard(
              title: 'Next Bracket',
              icon: Icons.arrow_upward_rounded,
              iconColor: Colors.orange,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.stars_rounded,
                        size: 18,
                        color: Colors.orange[400],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _incentive == null || _incentive!.currentTemplate == null || _incentive!.currentTemplate!.nextTemplate == null
                            ? 'Next Bracket'
                            : _incentive!.currentTemplate!.nextTemplate!.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF272579),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Complete targets to unlock higher commission rates!',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF272579).withValues(alpha: 0.08),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    size: 16,
                    color: iconColor,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: Colors.grey.withValues(alpha: 0.1),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildCommissionRow(String label, double? rate) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF0071bf).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '${rate == null ? '0.0' : rate.toStringAsFixed(1)}%',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0071bf),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressContent(MonthlyProgress progress) {
    final incentive = _incentive;
    final targetAmount = incentive == null || incentive.currentTemplate == null
        ? 0.0
        : incentive.currentTemplate!.overallTarget.amount.toDouble();
    final achievedAmount = progress.overallSalesAmount;
    final progressPercent =
        targetAmount > 0 ? (achievedAmount / targetAmount).clamp(0.0, 1.0) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Progress bar
        if (targetAmount > 0) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(progressPercent * 100).toStringAsFixed(0)}% Complete',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF272579),
                ),
              ),
              Text(
                'Rs ${_formatAmount(achievedAmount)} / Rs ${_formatAmount(targetAmount)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progressPercent,
              minHeight: 10,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                progress.targetAchieved
                    ? const Color(0xFF5cfbd8)
                    : const Color(0xFF0071bf),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Commission earned
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF5cfbd8).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.monetization_on_rounded,
                    size: 20,
                    color: const Color(0xFF0071bf),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Total Commission',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF272579),
                    ),
                  ),
                ],
              ),
              Text(
                'Rs ${_formatAmount(progress.totalCommission)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF272579),
                ),
              ),
            ],
          ),
        ),

        // Target achieved badge
        if (progress.targetAchieved) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF5cfbd8).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFF5cfbd8),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  size: 16,
                  color: Colors.green[700],
                ),
                const SizedBox(width: 6),
                Text(
                  'Target Achieved!',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.green[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  String _formatAmount(double amount) {
    if (amount >= 100000) {
      return '${(amount / 100000).toStringAsFixed(1)}L';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    }
    return amount.toStringAsFixed(0);
  }
}

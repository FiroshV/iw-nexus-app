import 'package:flutter/material.dart';
import '../../services/api_service.dart';
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
  
  String? selectedDepartment;
  String? selectedRole;
  String? selectedStatus;
  
  final List<String> departments = [
    'All',
    'HR',
    'Engineering',
    'Marketing',
    'Sales',
    'Finance',
    'Operations',
    'Admin'
  ];
  
  final List<String> roles = [
    'All',
    'employee',
    'manager',
    'hr',
    'admin'
  ];
  
  final List<String> statuses = [
    'All',
    'active',
    'inactive',
    'terminated'
  ];

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
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.8) {
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
        department: selectedDepartment == 'All' ? null : selectedDepartment,
        role: selectedRole == 'All' ? null : selectedRole,
        status: selectedStatus == 'All' ? null : selectedStatus,
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
          if (refresh || currentPage == 1) {
            users = newUsers;
          } else {
            users.addAll(newUsers);
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
        content: Text('Are you sure you want to deactivate $userName? This action will terminate their account.'),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete user: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip('Department', selectedDepartment, departments, (value) {
            setState(() {
              selectedDepartment = value;
            });
            _loadUsers(refresh: true);
          }),
          const SizedBox(width: 8),
          _buildFilterChip('Role', selectedRole, roles, (value) {
            setState(() {
              selectedRole = value;
            });
            _loadUsers(refresh: true);
          }),
          const SizedBox(width: 8),
          _buildFilterChip('Status', selectedStatus, statuses, (value) {
            setState(() {
              selectedStatus = value;
            });
            _loadUsers(refresh: true);
          }),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String? selected, List<String> options, Function(String) onSelected) {
    return PopupMenuButton<String>(
      child: Chip(
        label: Text('$label: ${selected ?? 'All'}'),
        deleteIcon: selected != null && selected != 'All' ? const Icon(Icons.clear, size: 18) : null,
        onDeleted: selected != null && selected != 'All' ? () {
          onSelected('All');
        } : null,
      ),
      itemBuilder: (context) => options.map((option) => 
        PopupMenuItem(value: option, child: Text(option))
      ).toList(),
      onSelected: onSelected,
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    final String fullName = '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}'.trim();
    final String employeeId = user['employeeId'] ?? '';
    final String email = user['email'] ?? '';
    final String department = user['department'] ?? '';
    final String role = user['role'] ?? '';
    final String status = user['status'] ?? '';
    
    Color statusColor;
    switch (status.toLowerCase()) {
      case 'active':
        statusColor = Colors.green;
        break;
      case 'inactive':
        statusColor = Colors.orange;
        break;
      case 'terminated':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF272579),
          child: Text(
            fullName.isNotEmpty ? fullName[0].toUpperCase() : 'U',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          fullName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ID: $employeeId'),
            Text('Email: $email'),
            Text('$department • $role'),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: ListTile(
                leading: Icon(Icons.edit),
                title: Text('Edit'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            if (status.toLowerCase() != 'terminated')
              const PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  leading: Icon(Icons.delete, color: Colors.red),
                  title: Text('Delete', style: TextStyle(color: Colors.red)),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
          ],
          onSelected: (value) {
            switch (value) {
              case 'edit':
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => EditUserScreen(user: user),
                  ),
                ).then((_) => _loadUsers(refresh: true));
                break;
              case 'delete':
                _deleteUser(user['_id'], fullName);
                break;
            }
          },
        ),
        isThreeLine: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        backgroundColor: const Color(0xFF272579),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadUsers(refresh: true),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search users...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _loadUsers(refresh: true);
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                // Debounce search
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (_searchController.text == value) {
                    _loadUsers(refresh: true);
                  }
                });
              },
            ),
          ),
          
          // Filter chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildFilterChips(),
          ),
          
          const SizedBox(height: 8),
          
          // Users list
          Expanded(
            child: error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error, size: 64, color: Colors.red.shade300),
                        const SizedBox(height: 16),
                        Text(
                          error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => _loadUsers(refresh: true),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : users.isEmpty
                    ? isLoading
                        ? const LoadingWidget(message: 'Loading users...')
                        : const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.people, size: 64, color: Colors.grey),
                                SizedBox(height: 16),
                                Text(
                                  'No users found',
                                  style: TextStyle(fontSize: 18, color: Colors.grey),
                                ),
                              ],
                            ),
                          )
                    : ListView.builder(
                        controller: _scrollController,
                        itemCount: users.length + (hasMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index >= users.length) {
                            return const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }
                          return _buildUserCard(users[index]);
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const AddUserScreen(),
            ),
          ).then((_) => _loadUsers(refresh: true));
        },
        backgroundColor: const Color(0xFF272579),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
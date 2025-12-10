import 'package:flutter/material.dart';
import '../../config/crm_colors.dart';
import '../../config/crm_design_system.dart';

class EmployeeSelectionSection extends StatefulWidget {
  final List<dynamic> allEmployees; // Raw employee data from API
  final List<String> selectedEmployeeIds; // IDs of selected employees
  final String currentUserId; // Current user ID (always primary)
  final String? currentUserName; // Current user name
  final ValueChanged<List<String>> onEmployeesChanged;
  final int maxEmployees; // Maximum employees selectable

  const EmployeeSelectionSection({
    super.key,
    required this.allEmployees,
    required this.selectedEmployeeIds,
    required this.currentUserId,
    this.currentUserName,
    required this.onEmployeesChanged,
    this.maxEmployees = 5,
  });

  @override
  State<EmployeeSelectionSection> createState() => _EmployeeSelectionSectionState();
}

class _EmployeeSelectionSectionState extends State<EmployeeSelectionSection> {
  late TextEditingController _searchController;
  List<dynamic> _filteredEmployees = [];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _filterEmployees();
  }

  @override
  void didUpdateWidget(EmployeeSelectionSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.allEmployees != widget.allEmployees) {
      _filterEmployees();
    }
  }

  void _filterEmployees() {
    List<dynamic> filtered = widget.allEmployees;

    // Filter by search only
    final query = _searchController.text.toLowerCase();
    if (query.isNotEmpty) {
      filtered = filtered.where((emp) {
        final firstName = emp['firstName'] as String?;
        final lastName = emp['lastName'] as String?;
        final email = emp['email'] as String?;
        final fullName = '${firstName ?? ''} ${lastName ?? ''}'.toLowerCase();
        return fullName.contains(query) || (email ?? '').toLowerCase().contains(query);
      }).toList();
    }

    setState(() => _filteredEmployees = filtered);
  }

  bool _isEmployeeSelected(String employeeId) {
    return widget.selectedEmployeeIds.contains(employeeId);
  }

  bool _isCurrentUser(String employeeId) {
    return employeeId == widget.currentUserId;
  }

  void _toggleEmployee(String employeeId) {
    // Don't allow deselecting current user
    if (_isCurrentUser(employeeId)) {
      return;
    }

    final selected = List<String>.from(widget.selectedEmployeeIds);

    if (_isEmployeeSelected(employeeId)) {
      selected.remove(employeeId);
    } else {
      // Check max limit
      if (selected.length >= widget.maxEmployees) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Maximum ${widget.maxEmployees} employees can be selected'),
            duration: const Duration(seconds: 2),
          ),
        );
        return;
      }
      selected.add(employeeId);
    }

    widget.onEmployeesChanged(selected);
  }

  String _getEmployeeRole(String? role) {
    final roleMap = {
      'field_staff': 'Field Staff',
      'telecaller': 'Telecaller',
      'employee': 'Employee',
      'manager': 'Manager',
      'admin': 'Admin',
    };
    return roleMap[role] ?? role ?? 'Employee';
  }

  void _showEmployeeBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.7,
              minChildSize: 0.5,
              maxChildSize: 0.9,
              expand: false,
              builder: (context, scrollController) {
                return Column(
                  children: [
                    // Header
                    _buildBottomSheetHeader(context),

                    // Search field
                    _buildSearchField(setModalState),

                    // Employee list
                    Expanded(
                      child: _filteredEmployees.isEmpty
                          ? Center(
                              child: Text(
                                'No employees found',
                                style: CrmDesignSystem.bodySmall.copyWith(
                                  color: CrmColors.textLight,
                                ),
                              ),
                            )
                          : ListView.separated(
                              controller: scrollController,
                              itemCount: _filteredEmployees.length,
                              separatorBuilder: (_, __) => const Divider(height: 1),
                              itemBuilder: (context, index) {
                                return _buildEmployeeCheckboxTile(
                                  _filteredEmployees[index],
                                  setModalState,
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildBottomSheetHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: CrmDesignSystem.lg,
        vertical: CrmDesignSystem.md,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Select Employees',
            style: CrmDesignSystem.titleMedium,
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField(StateSetter setModalState) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: CrmDesignSystem.lg,
        vertical: CrmDesignSystem.md,
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (_) {
          _filterEmployees();
          setModalState(() {});
        },
        decoration: InputDecoration(
          hintText: 'Search employees...',
          prefixIcon: const Icon(Icons.search, color: CrmColors.primary),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _filterEmployees();
                    setModalState(() {});
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(CrmDesignSystem.radiusMedium),
          ),
          filled: true,
          fillColor: CrmColors.surface,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: CrmDesignSystem.md,
            vertical: CrmDesignSystem.md,
          ),
        ),
      ),
    );
  }

  Widget _buildEmployeeCheckboxTile(
    dynamic employee,
    StateSetter setModalState,
  ) {
    final empId = employee['_id'] as String? ?? employee['id'] as String?;
    final firstName = employee['firstName'] as String?;
    final lastName = employee['lastName'] as String?;
    final role = employee['role'] as String?;

    if (empId == null) return const SizedBox.shrink();

    final isSelected = _isEmployeeSelected(empId);
    final isCurrent = _isCurrentUser(empId);

    return CheckboxListTile(
      value: isSelected || isCurrent,
      enabled: !isCurrent,
      onChanged: isCurrent
          ? null
          : (_) {
              _toggleEmployee(empId);
              setModalState(() {});
            },
      title: Row(
        children: [
          Expanded(
            child: Text(
              '${firstName ?? ''} ${lastName ?? ''}'.trim(),
              style: CrmDesignSystem.bodyMedium.copyWith(
                fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
          if (isCurrent)
            Container(
              margin: const EdgeInsets.only(left: CrmDesignSystem.md),
              padding: const EdgeInsets.symmetric(
                horizontal: CrmDesignSystem.md,
                vertical: CrmDesignSystem.xs,
              ),
              decoration: BoxDecoration(
                color: CrmColors.success,
                borderRadius: BorderRadius.circular(CrmDesignSystem.radiusSmall),
              ),
              child: Text(
                'Primary',
                style: CrmDesignSystem.bodySmall.copyWith(
                  color: CrmColors.primary,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      subtitle: Text(
        _getEmployeeRole(role),
        style: CrmDesignSystem.bodySmall.copyWith(
          color: CrmColors.textLight,
        ),
      ),
      activeColor: CrmColors.primary,
      checkColor: Colors.white,
    );
  }

  Widget _buildSelectedChip(String employeeId) {
    final employee = widget.allEmployees.firstWhere(
      (e) => e['_id'] == employeeId || e['id'] == employeeId,
      orElse: () => null,
    );

    String name = 'Employee';
    final isCurrent = _isCurrentUser(employeeId);

    if (employee != null) {
      final firstName = employee['firstName'] as String?;
      final lastName = employee['lastName'] as String?;
      name = '${firstName ?? ''} ${lastName ?? ''}'.trim();
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: CrmDesignSystem.md,
        vertical: CrmDesignSystem.sm,
      ),
      decoration: BoxDecoration(
        color: isCurrent
            ? CrmColors.success.withValues(alpha: 0.1)
            : CrmColors.primary.withValues(alpha: 0.1),
        border: Border.all(
          color: isCurrent ? CrmColors.success : CrmColors.primary,
        ),
        borderRadius: BorderRadius.circular(CrmDesignSystem.radiusLarge),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            name,
            style: CrmDesignSystem.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: CrmDesignSystem.sm),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: CrmDesignSystem.sm,
              vertical: CrmDesignSystem.xs,
            ),
            decoration: BoxDecoration(
              color: isCurrent ? CrmColors.success : CrmColors.primary,
              borderRadius: BorderRadius.circular(CrmDesignSystem.radiusSmall),
            ),
            child: Text(
              isCurrent ? 'Primary' : 'Secondary',
              style: CrmDesignSystem.bodySmall.copyWith(
                color: isCurrent ? CrmColors.primary : Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (!isCurrent)
            GestureDetector(
              onTap: () {
                _toggleEmployee(employeeId);
              },
              child: Padding(
                padding: const EdgeInsets.only(left: CrmDesignSystem.sm),
                child: Icon(
                  Icons.close,
                  size: 16,
                  color: CrmColors.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Selected employees chips
        if (widget.selectedEmployeeIds.isNotEmpty) ...[
          Wrap(
            spacing: CrmDesignSystem.sm,
            runSpacing: CrmDesignSystem.sm,
            children: widget.selectedEmployeeIds.map((empId) {
              return _buildSelectedChip(empId);
            }).toList(),
          ),
          const SizedBox(height: CrmDesignSystem.md),
        ],

        // Tappable text field to open bottom sheet
        GestureDetector(
          onTap: () => _showEmployeeBottomSheet(context),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: CrmDesignSystem.md,
              vertical: CrmDesignSystem.md,
            ),
            decoration: BoxDecoration(
              border: Border.all(color: CrmColors.borderColor),
              borderRadius: BorderRadius.circular(CrmDesignSystem.radiusMedium),
              color: Colors.white,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.selectedEmployeeIds.isEmpty
                      ? 'Add employees...'
                      : '${widget.selectedEmployeeIds.length} employee${widget.selectedEmployeeIds.length != 1 ? 's' : ''} selected',
                  style: TextStyle(
                    fontSize: 14,
                    color: widget.selectedEmployeeIds.isEmpty
                        ? CrmColors.textLight
                        : CrmColors.textDark,
                  ),
                ),
                const Icon(
                  Icons.expand_more,
                  color: CrmColors.primary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

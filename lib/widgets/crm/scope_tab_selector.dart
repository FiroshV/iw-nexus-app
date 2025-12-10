import 'package:flutter/material.dart';
import '../../config/crm_colors.dart';
import '../../config/crm_design_system.dart';

/// Standard TabBar component for Customers, Sales, and Activity Log modules
/// Shows two tabs: "Assigned to Me" and "Branch/All" based on user role
class ScopeTabSelector extends StatelessWidget implements PreferredSizeWidget {
  final TabController controller;
  final String userRole;

  const ScopeTabSelector({
    super.key,
    required this.controller,
    required this.userRole,
  });

  String _getSecondTabLabel() {
    if (userRole == 'admin' || userRole == 'director') {
      return 'All';
    } else if (userRole == 'manager') {
      return 'Branch';
    }
    return 'All';
  }

  @override
  Size get preferredSize => const Size.fromHeight(48);

  @override
  Widget build(BuildContext context) {
    return TabBar(
      controller: controller,
      labelColor: Colors.white,
      unselectedLabelColor: Colors.white70,
      indicatorColor: Colors.white,
      indicatorWeight: 3,
      tabs: [
        const Tab(text: 'Assigned to Me'),
        Tab(text: _getSecondTabLabel()),
      ],
    );
  }
}

/// Pill-style TabBar component for Appointments module
/// Used within the My Schedule and All Appointments tabs
class PillTabSelector extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTabChanged;
  final String userRole;

  const PillTabSelector({
    super.key,
    required this.selectedIndex,
    required this.onTabChanged,
    required this.userRole,
  });

  String _getSecondTabLabel() {
    if (userRole == 'admin' || userRole == 'director') {
      return 'All';
    }
    return 'Branch';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(CrmDesignSystem.md),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: CrmColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CrmColors.borderColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildPillTab(
              label: 'Assigned to Me',
              isSelected: selectedIndex == 0,
              onTap: () => onTabChanged(0),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _buildPillTab(
              label: _getSecondTabLabel(),
              isSelected: selectedIndex == 1,
              onTap: () => onTabChanged(1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPillTab({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          vertical: CrmDesignSystem.sm,
          horizontal: CrmDesignSystem.md,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? CrmColors.primary.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? CrmColors.primary : Colors.transparent,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: CrmDesignSystem.labelMedium.copyWith(
            color: isSelected ? CrmColors.primary : CrmColors.textLight,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

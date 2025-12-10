import 'package:flutter/material.dart';
import '../../config/crm_colors.dart';
import '../../config/crm_design_system.dart';

class QuickDateFilters extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateChanged;

  const QuickDateFilters({
    super.key,
    required this.selectedDate,
    required this.onDateChanged,
  });

  DateTime _getNextMonday() {
    final now = DateTime.now();
    int daysAhead = DateTime.monday - now.weekday;
    if (daysAhead <= 0) {
      daysAhead += 7;
    }
    return now.add(Duration(days: daysAhead));
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final tomorrow = today.add(const Duration(days: 1));
    final nextMonday = _getNextMonday();

    final isToday = _isSameDay(selectedDate, today);
    final isTomorrow = _isSameDay(selectedDate, tomorrow);
    final isNextMonday = _isSameDay(selectedDate, nextMonday);

    return Row(
      children: [
        // Today button
        Expanded(
          child: _buildDateButton(
            label: 'Today',
            isSelected: isToday,
            onTap: () => onDateChanged(
              DateTime(today.year, today.month, today.day),
            ),
          ),
        ),
        const SizedBox(width: CrmDesignSystem.md),

        // Tomorrow button
        Expanded(
          child: _buildDateButton(
            label: 'Tomorrow',
            isSelected: isTomorrow,
            onTap: () => onDateChanged(
              DateTime(tomorrow.year, tomorrow.month, tomorrow.day),
            ),
          ),
        ),
        const SizedBox(width: CrmDesignSystem.md),

        // Next Week (Monday) button
        Expanded(
          child: _buildDateButton(
            label: 'Next Week',
            isSelected: isNextMonday,
            onTap: () => onDateChanged(
              DateTime(nextMonday.year, nextMonday.month, nextMonday.day),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(CrmDesignSystem.radiusMedium),
        splashColor: CrmColors.primary.withValues(alpha: 0.1),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: CrmDesignSystem.md,
            vertical: CrmDesignSystem.sm,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? CrmColors.primary.withValues(alpha: 0.1)
                : Colors.transparent,
            border: Border.all(
              color: isSelected ? CrmColors.primary : CrmColors.borderColor,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(CrmDesignSystem.radiusMedium),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? CrmColors.primary : CrmColors.textLight,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

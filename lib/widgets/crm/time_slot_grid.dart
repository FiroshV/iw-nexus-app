import 'package:flutter/material.dart';

class TimeSlot {
  final String startTime; // "09:00"
  final String endTime; // "10:00"
  final bool isAvailable;
  final bool isSelected;
  final String? reason; // Reason if not available

  TimeSlot({
    required this.startTime,
    required this.endTime,
    this.isAvailable = true,
    this.isSelected = false,
    this.reason,
  });
}

class TimeSlotGrid extends StatefulWidget {
  final List<TimeSlot> slots;
  final Function(TimeSlot) onSlotSelected;
  final TimeSlot? selectedSlot;
  final bool singleSelect;

  const TimeSlotGrid({
    super.key,
    required this.slots,
    required this.onSlotSelected,
    this.selectedSlot,
    this.singleSelect = true,
  });

  @override
  State<TimeSlotGrid> createState() => _TimeSlotGridState();
}

class _TimeSlotGridState extends State<TimeSlotGrid> {
  late TimeSlot? _selectedSlot;

  @override
  void initState() {
    super.initState();
    _selectedSlot = widget.selectedSlot;
  }

  void _selectSlot(TimeSlot slot) {
    if (!slot.isAvailable) return;

    setState(() {
      if (widget.singleSelect) {
        _selectedSlot = _selectedSlot == slot ? null : slot;
      } else {
        _selectedSlot = _selectedSlot == slot ? null : slot;
      }
    });

    if (_selectedSlot != null) {
      widget.onSlotSelected(_selectedSlot!);
    }
  }

  Color _getSlotColor(TimeSlot slot) {
    if (!slot.isAvailable) {
      return Colors.grey[200]!;
    }
    if (_selectedSlot == slot) {
      return const Color(0xFF0071bf);
    }
    return const Color(0xFFfbf8ff);
  }

  Color _getSlotTextColor(TimeSlot slot) {
    if (!slot.isAvailable) {
      return Colors.grey[500]!;
    }
    if (_selectedSlot == slot) {
      return Colors.white;
    }
    return const Color(0xFF272579);
  }

  Color _getSlotBorderColor(TimeSlot slot) {
    if (!slot.isAvailable) {
      return Colors.grey[300]!;
    }
    if (_selectedSlot == slot) {
      return const Color(0xFF0071bf);
    }
    return const Color(0xFF00b8d9).withValues(alpha: 0.3);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Text(
            'Select Time Slot (9 AM - 6 PM)',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF272579),
                ),
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.2,
          ),
          itemCount: widget.slots.length,
          itemBuilder: (context, index) {
            final slot = widget.slots[index];
            return _buildTimeSlotCard(slot, context);
          },
        ),
        if (_selectedSlot != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF5cfbd8).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF5cfbd8),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: Color(0xFF5cfbd8),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Selected: ${_selectedSlot!.startTime} - ${_selectedSlot!.endTime}',
                      style: const TextStyle(
                        color: Color(0xFF272579),
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTimeSlotCard(TimeSlot slot, BuildContext context) {
    return GestureDetector(
      onTap: () => _selectSlot(slot),
      child: Container(
        decoration: BoxDecoration(
          color: _getSlotColor(slot),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _getSlotBorderColor(slot),
            width: _selectedSlot == slot ? 2 : 1,
          ),
          boxShadow: _selectedSlot == slot
              ? [
                  BoxShadow(
                    color: const Color(0xFF0071bf).withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: InkWell(
          onTap: slot.isAvailable ? () => _selectSlot(slot) : null,
          borderRadius: BorderRadius.circular(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!slot.isAvailable)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Icon(
                    Icons.block,
                    color: Colors.grey[500],
                    size: 18,
                  ),
                ),
              Text(
                slot.startTime,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _getSlotTextColor(slot),
                ),
              ),
              Text(
                slot.endTime,
                style: TextStyle(
                  fontSize: 12,
                  color: _getSlotTextColor(slot),
                ),
              ),
              if (!slot.isAvailable && slot.reason != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    slot.reason!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 8,
                      color: Colors.grey[500],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../../models/venue_booking.dart';

class BookingTimeSlots extends StatelessWidget {
  final List<BookingSlot> slots;
  final String? selectedSlot;
  final int duration;
  final Function(String) onSlotSelected;

  const BookingTimeSlots({
    Key? key,
    required this.slots,
    this.selectedSlot,
    required this.duration,
    required this.onSlotSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (slots.isEmpty) {
      return _buildEmptyState(context);
    }

    // Group slots by time
    final groupedSlots = _groupSlotsByTime(slots);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Time Slot',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: groupedSlots.entries.map((entry) {
            final timeSlot = entry.key;
            final slot = entry.value;
            final isSelected = selectedSlot == timeSlot;
            final isAvailable = _isSlotAvailable(slot, duration);

            return GestureDetector(
              onTap: isAvailable ? () => onSlotSelected(timeSlot) : null,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(context).primaryColor
                      : isAvailable
                          ? Colors.white
                          : Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected
                        ? Theme.of(context).primaryColor
                        : isAvailable
                            ? Colors.grey.withValues(alpha: 0.3)
                            : Colors.grey.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      timeSlot,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : isAvailable
                                ? Colors.black
                                : Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '\$${slot.price.toStringAsFixed(0)}',
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : isAvailable
                                ? Colors.grey[600]
                                : Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                    if (!isAvailable) ...[
                      const SizedBox(height: 2),
                      Icon(
                        Icons.block,
                        color: Colors.grey,
                        size: 12,
                      ),
                    ],
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        if (selectedSlot != null) ...[
          const SizedBox(height: 16),
          _buildSelectedSlotInfo(context),
        ],
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            Icons.schedule,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No time slots available',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try selecting a different date',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedSlotInfo(BuildContext context) {
    final selectedSlotData = slots.firstWhere(
      (slot) => slot.startTime == selectedSlot,
    );

    final endTime = _calculateEndTime(selectedSlot!, duration);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.schedule,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selected Time',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  '$selectedSlot - $endTime',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '\$${(selectedSlotData.price * duration).toStringAsFixed(0)}',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Map<String, BookingSlot> _groupSlotsByTime(List<BookingSlot> slots) {
    final Map<String, BookingSlot> grouped = {};
    for (final slot in slots) {
      grouped[slot.startTime] = slot;
    }
    return grouped;
  }

  bool _isSlotAvailable(BookingSlot slot, int duration) {
    if (!slot.isAvailable) return false;
    
    // Check if there are enough consecutive slots for the duration
    // This is a simplified check - in a real app, you'd want to verify
    // that all required time slots are available
    return true;
  }

  String _calculateEndTime(String startTime, int duration) {
    final timeParts = startTime.split(':');
    final startHour = int.parse(timeParts[0]);
    final startMinute = int.parse(timeParts[1]);
    
    final startDateTime = DateTime(2023, 1, 1, startHour, startMinute);
    final endDateTime = startDateTime.add(Duration(hours: duration));
    
    final endHour = endDateTime.hour.toString().padLeft(2, '0');
    final endMinute = endDateTime.minute.toString().padLeft(2, '0');
    
    return '$endHour:$endMinute';
  }
}

import 'package:flutter/material.dart';
import '../../../models/venue_booking.dart';

class BookingTimeSlots extends StatelessWidget {
  final List<BookingSlot> slots;
  final String? selectedSlot;
  final int duration;
  final String currencySymbol;
  final Function(String) onSlotSelected;

  const BookingTimeSlots({
    Key? key,
    required this.slots,
    this.selectedSlot,
    required this.duration,
    required this.onSlotSelected,
    this.currencySymbol = '₨',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (slots.isEmpty) {
      return _buildEmptyState(context);
    }

    // Group slots by time
    final groupedSlots = _groupSlotsByTime(slots);

    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxWidth = constraints.maxWidth;
        final int columns;
        if (maxWidth >= 720) {
          columns = 3;
        } else if (maxWidth >= 420) {
          columns = 2;
        } else {
          columns = 1;
        }
        final double spacing = 12;
        final double tileWidth = columns == 1
            ? maxWidth
            : (maxWidth - (columns - 1) * spacing) / columns;

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
              spacing: spacing,
              runSpacing: spacing,
              children: groupedSlots.entries.map((entry) {
                final timeSlot = entry.key;
                final slot = entry.value;
                final isSelected = selectedSlot == timeSlot;
                final isAvailable = _isSlotAvailable(slot, duration);

                final baseColor = Theme.of(context).primaryColor;
                final unavailableColor = Colors.white.withOpacity(0.06);

                return GestureDetector(
                  onTap: isAvailable ? () => onSlotSelected(timeSlot) : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: tileWidth,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: isSelected
                          ? LinearGradient(
                              colors: [
                                baseColor,
                                baseColor.withOpacity(0.7),
                              ],
                            )
                          : isAvailable
                              ? const LinearGradient(
                                  colors: [
                                    Color(0xFF1B1938),
                                    Color(0xFF0E0C22),
                                  ],
                                )
                              : LinearGradient(
                                  colors: [
                                    unavailableColor,
                                    unavailableColor.withOpacity(0.6),
                                  ],
                                ),
                      border: Border.all(
                        color: isSelected
                            ? Colors.white.withOpacity(0.4)
                            : isAvailable
                                ? Colors.white.withOpacity(0.08)
                                : Colors.white.withOpacity(0.04),
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: baseColor.withOpacity(0.35),
                                blurRadius: 18,
                                offset: const Offset(0, 10),
                              ),
                            ]
                          : [],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Icon(
                              Icons.schedule_rounded,
                              size: 16,
                              color: isSelected
                                  ? Colors.white
                                  : isAvailable
                                      ? Colors.white.withOpacity(0.72)
                                      : Colors.white.withOpacity(0.4),
                            ),
                            Text(
                              isAvailable ? 'Available' : 'Booked',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? Colors.white.withOpacity(0.9)
                                    : isAvailable
                                        ? Colors.white.withOpacity(0.6)
                                        : Colors.white.withOpacity(0.4),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          timeSlot,
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : isAvailable
                                    ? Colors.white.withOpacity(0.92)
                                    : Colors.white.withOpacity(0.4),
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '$currencySymbol${slot.price.toStringAsFixed(0)}',
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white.withOpacity(0.85)
                                : isAvailable
                                    ? Colors.white.withOpacity(0.65)
                                    : Colors.white.withOpacity(0.35),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
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
      },
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).primaryColor.withOpacity(0.18),
            Theme.of(context).primaryColor.withOpacity(0.08),
          ],
        ),
        border: Border.all(
          color: Theme.of(context).primaryColor.withOpacity(0.35),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.2),
            ),
            child: Icon(
              Icons.schedule_rounded,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selected Time',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white.withOpacity(0.75),
                        letterSpacing: 0.2,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$selectedSlot - $endTime',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                ),
              ],
            ),
          ),
          Text(
            '$currencySymbol${(selectedSlotData.price * duration).toStringAsFixed(0)}',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
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

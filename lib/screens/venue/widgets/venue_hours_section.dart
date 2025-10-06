import 'package:flutter/material.dart';
import '../../../models/venue.dart';

class VenueHoursSection extends StatelessWidget {
  final VenueHours hours;

  const VenueHoursSection({
    Key? key,
    required this.hours,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Opening Hours',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: _buildHoursList(context),
          ),
        ),
        if (hours.holidays.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'Holidays',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: hours.holidays.map((holiday) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Icon(
                        Icons.event_busy,
                        color: Colors.amber[700],
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        holiday,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.amber[700],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ],
    );
  }

  List<Widget> _buildHoursList(BuildContext context) {
    final days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    return days.map((day) {
      final dayHours = hours.weeklyHours[day.toLowerCase()];
      final isToday = _isToday(day);
      
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            SizedBox(
              width: 80,
              child: Text(
                day,
                style: TextStyle(
                  fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                  color: isToday ? Theme.of(context).primaryColor : null,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildDayHours(context, dayHours, isToday),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildDayHours(BuildContext context, DayHours? dayHours, bool isToday) {
    if (dayHours == null || !dayHours.isOpen) {
      return Text(
        'Closed',
        style: TextStyle(
          color: Colors.grey[600],
          fontWeight: isToday ? FontWeight.w500 : FontWeight.normal,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${dayHours.openTime} - ${dayHours.closeTime}',
          style: TextStyle(
            fontWeight: isToday ? FontWeight.w500 : FontWeight.normal,
            color: isToday ? Theme.of(context).primaryColor : null,
          ),
        ),
        if (dayHours.breakStartTime != null && dayHours.breakEndTime != null)
          Text(
            'Break: ${dayHours.breakStartTime} - ${dayHours.breakEndTime}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
      ],
    );
  }

  bool _isToday(String day) {
    final now = DateTime.now();
    final weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    
    final todayIndex = now.weekday - 1; // Monday = 0, Sunday = 6
    return weekdays[todayIndex] == day;
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import '../../models/user_profile.dart';
import '../../theming/colors.dart';
import '../../theming/styles.dart';

/// Time slot picker widget for selecting availability
class AppTimeSlotPicker extends StatefulWidget {
  final String label;
  final List<TimeSlot> selectedSlots;
  final Function(List<TimeSlot>) onChanged;
  final String? Function(List<TimeSlot>?)? validator;
  final bool isRequired;

  const AppTimeSlotPicker({
    super.key,
    required this.label,
    required this.selectedSlots,
    required this.onChanged,
    this.validator,
    this.isRequired = false,
  });

  @override
  State<AppTimeSlotPicker> createState() => _AppTimeSlotPickerState();
}

class _AppTimeSlotPickerState extends State<AppTimeSlotPicker> {
  String? _errorText;

  static const List<String> _daysOfWeek = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  static const List<String> _timeOptions = [
    '06:00', '07:00', '08:00', '09:00', '10:00', '11:00',
    '12:00', '13:00', '14:00', '15:00', '16:00', '17:00',
    '18:00', '19:00', '20:00', '21:00', '22:00',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Row(
          children: [
            Text(
              widget.label,
              style: TextStyles.font14DarkBlue500Weight,
            ),
            if (widget.isRequired) ...[
              Gap(4.w),
              Text(
                '*',
                style: TextStyles.font14DarkBlue500Weight.copyWith(
                  color: ColorsManager.coralRed,
                ),
              ),
            ],
          ],
        ),
        Gap(8.h),

        // Selected slots display
        if (widget.selectedSlots.isNotEmpty) ...[
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: ColorsManager.lightShadeOfGray,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _errorText != null 
                    ? ColorsManager.coralRed 
                    : ColorsManager.gray93Color,
                width: 1.3.w,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selected Time Slots:',
                  style: TextStyles.font12Grey400Weight,
                ),
                Gap(8.h),
                Wrap(
                  spacing: 8.w,
                  runSpacing: 8.h,
                  children: widget.selectedSlots
                      .map((slot) => _buildTimeSlotChip(slot))
                      .toList(),
                ),
              ],
            ),
          ),
          Gap(12.h),
        ],

        // Add time slot button
        GestureDetector(
          onTap: _showTimeSlotDialog,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 16.h),
            decoration: BoxDecoration(
              color: ColorsManager.mainBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: ColorsManager.mainBlue,
                width: 1.w,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add,
                  color: ColorsManager.mainBlue,
                  size: 20.sp,
                ),
                Gap(8.w),
                Text(
                  'Add Time Slot',
                  style: TextStyles.font14DarkBlue500Weight.copyWith(
                    color: ColorsManager.mainBlue,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Error text
        if (_errorText != null) ...[
          Gap(4.h),
          Text(
            _errorText!,
            style: TextStyles.font12Grey400Weight.copyWith(
              color: ColorsManager.coralRed,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTimeSlotChip(TimeSlot slot) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: ColorsManager.mainBlue,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            slot.toString(),
            style: TextStyles.font11DarkBlue500Weight.copyWith(
              color: Colors.white,
            ),
          ),
          Gap(4.w),
          GestureDetector(
            onTap: () => _removeTimeSlot(slot),
            child: Icon(
              Icons.close,
              size: 16.sp,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _showTimeSlotDialog() {
    String? selectedDay;
    String? selectedStartTime;
    String? selectedEndTime;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            'Add Time Slot',
            style: TextStyles.font18DarkBlue600Weight,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Day selection
              DropdownButtonFormField<String>(
                value: selectedDay,
                decoration: InputDecoration(
                  labelText: 'Day',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: _daysOfWeek.map((day) {
                  return DropdownMenuItem(
                    value: day,
                    child: Text(day),
                  );
                }).toList(),
                onChanged: (value) {
                  setDialogState(() {
                    selectedDay = value;
                  });
                },
              ),
              Gap(16.h),

              // Start time selection
              DropdownButtonFormField<String>(
                value: selectedStartTime,
                decoration: InputDecoration(
                  labelText: 'Start Time',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: _timeOptions.map((time) {
                  return DropdownMenuItem(
                    value: time,
                    child: Text(time),
                  );
                }).toList(),
                onChanged: (value) {
                  setDialogState(() {
                    selectedStartTime = value;
                    // Reset end time if it's before start time
                    if (selectedEndTime != null && value != null) {
                      final startIndex = _timeOptions.indexOf(value);
                      final endIndex = _timeOptions.indexOf(selectedEndTime!);
                      if (endIndex <= startIndex) {
                        selectedEndTime = null;
                      }
                    }
                  });
                },
              ),
              Gap(16.h),

              // End time selection
              DropdownButtonFormField<String>(
                value: selectedEndTime,
                decoration: InputDecoration(
                  labelText: 'End Time',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: selectedStartTime != null
                    ? _timeOptions
                        .where((time) {
                          final startIndex = _timeOptions.indexOf(selectedStartTime!);
                          final timeIndex = _timeOptions.indexOf(time);
                          return timeIndex > startIndex;
                        })
                        .map((time) {
                          return DropdownMenuItem(
                            value: time,
                            child: Text(time),
                          );
                        }).toList()
                    : [],
                onChanged: (value) {
                  setDialogState(() {
                    selectedEndTime = value;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyles.font14Grey400Weight,
              ),
            ),
            TextButton(
              onPressed: selectedDay != null && 
                         selectedStartTime != null && 
                         selectedEndTime != null
                  ? () {
                      _addTimeSlot(TimeSlot(
                        day: selectedDay!,
                        startTime: selectedStartTime!,
                        endTime: selectedEndTime!,
                      ));
                      Navigator.of(context).pop();
                    }
                  : null,
              child: Text(
                'Add',
                style: TextStyles.font14Blue400Weight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addTimeSlot(TimeSlot slot) {
    // Check for conflicts
    final hasConflict = widget.selectedSlots.any((existing) =>
        existing.day == slot.day &&
        _timesOverlap(existing.startTime, existing.endTime, slot.startTime, slot.endTime));

    if (hasConflict) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Time slot conflicts with existing slot'),
          backgroundColor: ColorsManager.coralRed,
        ),
      );
      return;
    }

    final newSlots = [...widget.selectedSlots, slot];
    widget.onChanged(newSlots);
    _validateSlots(newSlots);
  }

  void _removeTimeSlot(TimeSlot slot) {
    final newSlots = widget.selectedSlots.where((s) => s != slot).toList();
    widget.onChanged(newSlots);
    _validateSlots(newSlots);
  }

  bool _timesOverlap(String start1, String end1, String start2, String end2) {
    final start1Minutes = _timeToMinutes(start1);
    final end1Minutes = _timeToMinutes(end1);
    final start2Minutes = _timeToMinutes(start2);
    final end2Minutes = _timeToMinutes(end2);

    return start1Minutes < end2Minutes && start2Minutes < end1Minutes;
  }

  int _timeToMinutes(String time) {
    final parts = time.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  void _validateSlots(List<TimeSlot> slots) {
    if (widget.validator != null) {
      setState(() {
        _errorText = widget.validator!(slots);
      });
    }
  }
}

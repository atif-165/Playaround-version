import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import '../../../models/listing_model.dart';
import '../../../theming/colors.dart';
import '../../../theming/styles.dart';

/// Widget for selecting available time slots
class TimeslotSelector extends StatefulWidget {
  final List<TimeSlot> selectedTimeSlots;
  final ValueChanged<List<TimeSlot>> onChanged;

  const TimeslotSelector({
    super.key,
    required this.selectedTimeSlots,
    required this.onChanged,
  });

  @override
  State<TimeslotSelector> createState() => _TimeslotSelectorState();
}

class _TimeslotSelectorState extends State<TimeslotSelector> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Available Time Slots',
              style: TextStyles.font14DarkBlueMedium,
            ),
            TextButton.icon(
              onPressed: _showAddTimeSlotDialog,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Slot'),
              style: TextButton.styleFrom(
                foregroundColor: ColorsManager.mainBlue,
              ),
            ),
          ],
        ),
        Gap(12.h),
        if (widget.selectedTimeSlots.isEmpty)
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.access_time,
                  size: 32.sp,
                  color: Colors.grey[400],
                ),
                Gap(8.h),
                Text(
                  'No time slots added',
                  style: TextStyles.font14Grey400Weight,
                ),
                Gap(4.h),
                Text(
                  'Tap "Add Slot" to add available time slots',
                  style: TextStyles.font12Grey400Weight,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          Column(
            children: widget.selectedTimeSlots.asMap().entries.map((entry) {
              final index = entry.key;
              final timeSlot = entry.value;
              return Container(
                margin: EdgeInsets.only(bottom: 8.h),
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: ColorsManager.mainBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(
                    color: ColorsManager.mainBlue.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 20.sp,
                      color: ColorsManager.mainBlue,
                    ),
                    Gap(12.w),
                    Expanded(
                      child: Text(
                        '${timeSlot.start} - ${timeSlot.end}',
                        style: TextStyles.font14DarkBlueMedium,
                      ),
                    ),
                    IconButton(
                      onPressed: () => _removeTimeSlot(index),
                      icon: const Icon(
                        Icons.close,
                        color: Colors.red,
                      ),
                      iconSize: 20.sp,
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  void _showAddTimeSlotDialog() {
    TimeOfDay? startTime;
    TimeOfDay? endTime;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                'Add Time Slot',
                style: TextStyles.font18DarkBlueBold,
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Start Time',
                              style: TextStyles.font14DarkBlueMedium,
                            ),
                            Gap(8.h),
                            GestureDetector(
                              onTap: () async {
                                final time = await showTimePicker(
                                  context: context,
                                  initialTime: TimeOfDay.now(),
                                );
                                if (time != null) {
                                  setDialogState(() {
                                    startTime = time;
                                  });
                                }
                              },
                              child: Container(
                                padding: EdgeInsets.all(12.w),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey[300]!),
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                                child: Text(
                                  startTime?.format(context) ?? 'Select time',
                                  style: TextStyles.font14DarkBlueMedium,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Gap(16.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'End Time',
                              style: TextStyles.font14DarkBlueMedium,
                            ),
                            Gap(8.h),
                            GestureDetector(
                              onTap: () async {
                                final time = await showTimePicker(
                                  context: context,
                                  initialTime: startTime ?? TimeOfDay.now(),
                                );
                                if (time != null) {
                                  setDialogState(() {
                                    endTime = time;
                                  });
                                }
                              },
                              child: Container(
                                padding: EdgeInsets.all(12.w),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey[300]!),
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                                child: Text(
                                  endTime?.format(context) ?? 'Select time',
                                  style: TextStyles.font14DarkBlueMedium,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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
                  onPressed: () {
                    if (startTime != null && endTime != null) {
                      _addTimeSlot(startTime!, endTime!);
                      Navigator.of(context).pop();
                    }
                  },
                  child: Text(
                    'Add',
                    style: TextStyles.font14BlueRegular.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _addTimeSlot(TimeOfDay startTime, TimeOfDay endTime) {
    // Validate that end time is after start time
    final startMinutes = startTime.hour * 60 + startTime.minute;
    final endMinutes = endTime.hour * 60 + endTime.minute;

    if (endMinutes <= startMinutes) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('End time must be after start time'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final timeSlot = TimeSlot(
      start: _formatTimeOfDay(startTime),
      end: _formatTimeOfDay(endTime),
    );

    // Check for overlapping time slots
    final hasOverlap = widget.selectedTimeSlots.any((existingSlot) {
      return _timeSlotsOverlap(timeSlot, existingSlot);
    });

    if (hasOverlap) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Time slot overlaps with existing slot'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final updatedSlots = List<TimeSlot>.from(widget.selectedTimeSlots);
    updatedSlots.add(timeSlot);
    
    // Sort time slots by start time
    updatedSlots.sort((a, b) {
      final aMinutes = _timeToMinutes(a.start);
      final bMinutes = _timeToMinutes(b.start);
      return aMinutes.compareTo(bMinutes);
    });

    widget.onChanged(updatedSlots);
  }

  void _removeTimeSlot(int index) {
    final updatedSlots = List<TimeSlot>.from(widget.selectedTimeSlots);
    updatedSlots.removeAt(index);
    widget.onChanged(updatedSlots);
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  bool _timeSlotsOverlap(TimeSlot slot1, TimeSlot slot2) {
    final start1 = _timeToMinutes(slot1.start);
    final end1 = _timeToMinutes(slot1.end);
    final start2 = _timeToMinutes(slot2.start);
    final end2 = _timeToMinutes(slot2.end);

    return start1 < end2 && start2 < end1;
  }

  int _timeToMinutes(String time) {
    final parts = time.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }
}

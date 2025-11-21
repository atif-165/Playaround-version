import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import '../../../models/listing_model.dart';
import '../../../theming/colors.dart';
import '../../../theming/styles.dart';

/// Widget for selecting time slots
class TimeSlotSelector extends StatefulWidget {
  final List<TimeSlot> selectedTimeSlots;
  final Function(List<TimeSlot>) onTimeSlotsChanged;

  const TimeSlotSelector({
    super.key,
    required this.selectedTimeSlots,
    required this.onTimeSlotsChanged,
  });

  @override
  State<TimeSlotSelector> createState() => _TimeSlotSelectorState();
}

class _TimeSlotSelectorState extends State<TimeSlotSelector> {
  final List<TimeSlot> _predefinedSlots = [
    const TimeSlot(start: '06:00', end: '08:00'),
    const TimeSlot(start: '08:00', end: '10:00'),
    const TimeSlot(start: '10:00', end: '12:00'),
    const TimeSlot(start: '12:00', end: '14:00'),
    const TimeSlot(start: '14:00', end: '16:00'),
    const TimeSlot(start: '16:00', end: '18:00'),
    const TimeSlot(start: '18:00', end: '20:00'),
    const TimeSlot(start: '20:00', end: '22:00'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Time Slots *',
              style: TextStyles.font14DarkBlue600Weight,
            ),
            TextButton.icon(
              onPressed: _showAddCustomSlotDialog,
              icon: Icon(
                Icons.add,
                size: 16.sp,
                color: ColorsManager.mainBlue,
              ),
              label: Text(
                'Custom',
                style: TextStyles.font12MainBlue500Weight,
              ),
            ),
          ],
        ),
        Gap(8.h),
        Text(
          'Select available time slots',
          style: TextStyles.font12Grey400Weight,
        ),
        Gap(12.h),
        _buildPredefinedSlots(),
        if (widget.selectedTimeSlots.isNotEmpty) ...[
          Gap(16.h),
          _buildSelectedSlots(),
        ],
      ],
    );
  }

  Widget _buildPredefinedSlots() {
    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      children: _predefinedSlots.map((slot) {
        final isSelected = widget.selectedTimeSlots.any((selected) =>
            selected.start == slot.start && selected.end == slot.end);

        return GestureDetector(
          onTap: () => _toggleTimeSlot(slot),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: isSelected ? ColorsManager.mainBlue : Colors.grey[100],
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: isSelected ? ColorsManager.mainBlue : Colors.grey[300]!,
              ),
            ),
            child: Text(
              '${slot.start} - ${slot.end}',
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : Colors.grey[700],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSelectedSlots() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Selected Time Slots (${widget.selectedTimeSlots.length})',
          style: TextStyles.font14DarkBlue600Weight,
        ),
        Gap(8.h),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: ColorsManager.mainBlue.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(
                color: ColorsManager.mainBlue.withValues(alpha: 0.2)),
          ),
          child: Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: widget.selectedTimeSlots.map((slot) {
              return Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: ColorsManager.mainBlue,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        '${slot.start} - ${slot.end}',
                        style: TextStyle(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Gap(4.w),
                    GestureDetector(
                      onTap: () => _removeTimeSlot(slot),
                      child: Icon(
                        Icons.close,
                        size: 12.sp,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  void _toggleTimeSlot(TimeSlot slot) {
    final currentSlots = List<TimeSlot>.from(widget.selectedTimeSlots);
    final existingIndex = currentSlots.indexWhere(
        (selected) => selected.start == slot.start && selected.end == slot.end);

    if (existingIndex >= 0) {
      currentSlots.removeAt(existingIndex);
    } else {
      currentSlots.add(slot);
    }

    widget.onTimeSlotsChanged(currentSlots);
  }

  void _removeTimeSlot(TimeSlot slot) {
    final currentSlots = List<TimeSlot>.from(widget.selectedTimeSlots);
    currentSlots.removeWhere(
        (selected) => selected.start == slot.start && selected.end == slot.end);
    widget.onTimeSlotsChanged(currentSlots);
  }

  void _showAddCustomSlotDialog() {
    TimeOfDay? startTime;
    TimeOfDay? endTime;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            'Add Custom Time Slot',
            style: TextStyles.font16DarkBlueBold,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
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
                      child: Text(
                        startTime != null
                            ? startTime!.format(context)
                            : 'Start Time',
                      ),
                    ),
                  ),
                  Gap(8.w),
                  Text('to', style: TextStyles.font12Grey400Weight),
                  Gap(8.w),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
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
                      child: Text(
                        endTime != null ? endTime!.format(context) : 'End Time',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyles.font14Grey400Weight,
              ),
            ),
            ElevatedButton(
              onPressed: startTime != null && endTime != null
                  ? () {
                      final customSlot = TimeSlot(
                        start: _formatTimeOfDay(startTime!),
                        end: _formatTimeOfDay(endTime!),
                      );

                      // Validate that end time is after start time
                      if (_timeOfDayToMinutes(endTime!) <=
                          _timeOfDayToMinutes(startTime!)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('End time must be after start time'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      _toggleTimeSlot(customSlot);
                      Navigator.pop(context);
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorsManager.mainBlue,
                foregroundColor: Colors.white,
              ),
              child: Text(
                'Add',
                style: TextStyles.font14White600Weight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  int _timeOfDayToMinutes(TimeOfDay time) {
    return time.hour * 60 + time.minute;
  }
}

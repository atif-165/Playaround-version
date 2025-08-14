import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import '../../../models/listing_model.dart';
import '../../../theming/colors.dart';
import '../../../theming/styles.dart';

/// Grid widget for displaying and selecting time slots
class TimeSlotGrid extends StatelessWidget {
  final List<TimeSlot> timeSlots;
  final TimeSlot? selectedTimeSlot;
  final ValueChanged<TimeSlot> onTimeSlotSelected;

  const TimeSlotGrid({
    super.key,
    required this.timeSlots,
    required this.selectedTimeSlot,
    required this.onTimeSlotSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Available Time Slots',
            style: TextStyles.font14DarkBlueMedium,
          ),
          Gap(12.h),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12.w,
              mainAxisSpacing: 12.h,
              childAspectRatio: 2.5,
            ),
            itemCount: timeSlots.length,
            itemBuilder: (context, index) {
              final timeSlot = timeSlots[index];
              final isSelected = selectedTimeSlot == timeSlot;

              return GestureDetector(
                onTap: () => onTimeSlotSelected(timeSlot),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? ColorsManager.mainBlue
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(
                      color: isSelected
                          ? ColorsManager.mainBlue
                          : Colors.grey[300]!,
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 16.sp,
                        color: isSelected ? Colors.white : ColorsManager.mainBlue,
                      ),
                      Gap(4.h),
                      Text(
                        '${timeSlot.start} - ${timeSlot.end}',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : Colors.grey[700],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      Gap(2.h),
                      Text(
                        '${_calculateDuration(timeSlot).toStringAsFixed(1)}h',
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: isSelected ? Colors.white70 : Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          if (selectedTimeSlot != null) ...[
            Gap(16.h),
            Container(
              width: double.infinity,
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
                    Icons.check_circle,
                    size: 20.sp,
                    color: ColorsManager.mainBlue,
                  ),
                  Gap(8.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Selected Time Slot',
                          style: TextStyles.font12BlueRegular.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${selectedTimeSlot!.start} - ${selectedTimeSlot!.end} (${_calculateDuration(selectedTimeSlot!).toStringAsFixed(1)} hours)',
                          style: TextStyles.font12BlueRegular,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  double _calculateDuration(TimeSlot timeSlot) {
    final startParts = timeSlot.start.split(':');
    final endParts = timeSlot.end.split(':');
    
    final startMinutes = int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
    final endMinutes = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);
    
    return (endMinutes - startMinutes) / 60.0;
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import '../../../theming/colors.dart';
import '../../../theming/styles.dart';

/// Widget for selecting available weekdays
class WeekdaySelector extends StatelessWidget {
  final List<String> selectedDays;
  final ValueChanged<List<String>> onChanged;

  const WeekdaySelector({
    super.key,
    required this.selectedDays,
    required this.onChanged,
  });

  static const List<String> _weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  static const List<String> _weekdayAbbreviations = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Available Days',
          style: TextStyles.font14DarkBlueMedium,
        ),
        Gap(12.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: _weekdays.asMap().entries.map((entry) {
            final index = entry.key;
            final day = entry.value;
            final abbreviation = _weekdayAbbreviations[index];
            final isSelected = selectedDays.contains(day);

            return GestureDetector(
              onTap: () => _toggleDay(day),
              child: Container(
                width: 45.w,
                height: 45.h,
                decoration: BoxDecoration(
                  color: isSelected ? ColorsManager.mainBlue : Colors.grey[100],
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: isSelected ? ColorsManager.mainBlue : Colors.grey[300]!,
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    abbreviation,
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : Colors.grey[600],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        Gap(8.h),
        Row(
          children: [
            TextButton(
              onPressed: _selectAll,
              child: Text(
                'Select All',
                style: TextStyles.font12BlueRegular,
              ),
            ),
            Gap(16.w),
            TextButton(
              onPressed: _clearAll,
              child: Text(
                'Clear All',
                style: TextStyles.font12BlueRegular,
              ),
            ),
          ],
        ),
        if (selectedDays.isNotEmpty) ...[
          Gap(8.h),
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: ColorsManager.mainBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selected Days:',
                  style: TextStyles.font12BlueRegular.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Gap(4.h),
                Text(
                  selectedDays.join(', '),
                  style: TextStyles.font12BlueRegular,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  void _toggleDay(String day) {
    final updatedDays = List<String>.from(selectedDays);
    if (updatedDays.contains(day)) {
      updatedDays.remove(day);
    } else {
      updatedDays.add(day);
    }
    onChanged(updatedDays);
  }

  void _selectAll() {
    onChanged(List<String>.from(_weekdays));
  }

  void _clearAll() {
    onChanged([]);
  }
}

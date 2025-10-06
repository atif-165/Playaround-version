import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import '../../theming/colors.dart';
import '../../theming/styles.dart';

class ScheduleScreen extends StatelessWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Schedule', style: TextStyles.font18DarkBlueBold.copyWith(color: Colors.white)),
        backgroundColor: Colors.grey[900],
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
            _buildScheduleItem('Basketball Training', 'Today 3:00 PM', 'John Doe'),
            Gap(12.h),
            _buildScheduleItem('Tennis Lesson', 'Tomorrow 10:00 AM', 'Sarah Smith'),
            Gap(12.h),
            _buildScheduleItem('Football Practice', 'Friday 5:00 PM', 'Mike Johnson'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: ColorsManager.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildScheduleItem(String title, String time, String student) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          Container(
            width: 4.w,
            height: 40.h,
            decoration: BoxDecoration(
              color: ColorsManager.primary,
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          Gap(16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyles.font16DarkBlueBold.copyWith(color: Colors.white)),
                Text(time, style: TextStyles.font14Grey400Weight.copyWith(color: Colors.grey[400])),
                Text('with $student', style: TextStyles.font12Grey400Weight.copyWith(color: Colors.grey[500])),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: Colors.grey[400]),
        ],
      ),
    );
  }
}
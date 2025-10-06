import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import '../../theming/colors.dart';
import '../../theming/styles.dart';

class BookCoachScreen extends StatelessWidget {
  final String coachId;
  
  const BookCoachScreen({super.key, required this.coachId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Book Coach', style: TextStyles.font18DarkBlueBold.copyWith(color: Colors.white)),
        backgroundColor: Colors.grey[900],
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 32.r,
                    backgroundColor: ColorsManager.primary,
                    child: const Icon(Icons.person, color: Colors.white, size: 32),
                  ),
                  Gap(16.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Coach Mike Wilson', style: TextStyles.font18DarkBlueBold.copyWith(color: Colors.white)),
                        Text('Basketball • 5 years exp', style: TextStyles.font14Grey400Weight.copyWith(color: Colors.grey[400])),
                        Text('\$50/hour', style: TextStyles.font16DarkBlueBold.copyWith(color: ColorsManager.primary)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Gap(24.h),
            Text('Select Date & Time', style: TextStyles.font16DarkBlueBold.copyWith(color: Colors.white)),
            Gap(16.h),
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Column(
                children: [
                  _buildTimeSlot('Today 3:00 PM - 4:00 PM'),
                  Gap(8.h),
                  _buildTimeSlot('Tomorrow 10:00 AM - 11:00 AM'),
                  Gap(8.h),
                  _buildTimeSlot('Friday 5:00 PM - 6:00 PM'),
                ],
              ),
            ),
            const Spacer(),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: ColorsManager.primary,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Text('Book Session - \$50', textAlign: TextAlign.center, 
                          style: TextStyles.font16DarkBlueBold.copyWith(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSlot(String time) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        children: [
          Icon(Icons.schedule, color: ColorsManager.primary, size: 20.sp),
          Gap(12.w),
          Text(time, style: TextStyles.font14Grey400Weight.copyWith(color: Colors.white)),
        ],
      ),
    );
  }
}
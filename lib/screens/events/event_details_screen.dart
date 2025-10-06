import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import '../../theming/colors.dart';
import '../../theming/styles.dart';

class EventDetailsScreen extends StatelessWidget {
  final String eventId;
  
  const EventDetailsScreen({super.key, required this.eventId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Event Details', style: TextStyles.font18DarkBlueBold.copyWith(color: Colors.white)),
        backgroundColor: Colors.grey[900],
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 200.h,
              decoration: BoxDecoration(
                color: ColorsManager.primary,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Center(
                child: Icon(Icons.event, size: 64.sp, color: Colors.white),
              ),
            ),
            Gap(16.h),
            Text('Basketball Tournament Finals', style: TextStyles.font20DarkBlueBold.copyWith(color: Colors.white)),
            Gap(8.h),
            Text('December 25, 2024 at 3:00 PM', style: TextStyles.font14Grey400Weight.copyWith(color: Colors.grey[400])),
            Gap(16.h),
            Text('Description', style: TextStyles.font16DarkBlueBold.copyWith(color: Colors.white)),
            Gap(8.h),
            Text('Join us for an exciting basketball tournament featuring the best teams in the city. Great prizes await!', 
                 style: TextStyles.font14Grey400Weight.copyWith(color: Colors.grey[300])),
            Gap(24.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: ColorsManager.primary,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Text('Join Event', textAlign: TextAlign.center, 
                          style: TextStyles.font16DarkBlueBold.copyWith(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
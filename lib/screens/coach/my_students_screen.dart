import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import '../../theming/colors.dart';
import '../../theming/styles.dart';

class MyStudentsScreen extends StatelessWidget {
  const MyStudentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('My Students',
            style: TextStyles.font18DarkBlueBold.copyWith(color: Colors.white)),
        backgroundColor: Colors.grey[900],
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
            _buildStudentCard('John Doe', 'Basketball', 'Beginner'),
            Gap(12.h),
            _buildStudentCard('Sarah Smith', 'Tennis', 'Intermediate'),
            Gap(12.h),
            _buildStudentCard('Mike Johnson', 'Football', 'Advanced'),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentCard(String name, String sport, String level) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24.r,
            backgroundColor: ColorsManager.primary,
            child: Text(name[0],
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          Gap(16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: TextStyles.font16DarkBlueBold
                        .copyWith(color: Colors.white)),
                Text('$sport • $level',
                    style: TextStyles.font14Grey400Weight
                        .copyWith(color: Colors.grey[400])),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.message, color: ColorsManager.primary),
          ),
        ],
      ),
    );
  }
}

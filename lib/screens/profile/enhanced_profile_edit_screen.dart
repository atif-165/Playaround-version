import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import '../../theming/colors.dart';
import '../../theming/styles.dart';
import '../../models/user_profile.dart';

class EnhancedProfileEditScreen extends StatefulWidget {
  final UserProfile? userProfile;

  const EnhancedProfileEditScreen({
    Key? key,
    this.userProfile,
  }) : super(key: key);

  @override
  State<EnhancedProfileEditScreen> createState() =>
      _EnhancedProfileEditScreenState();
}

class _EnhancedProfileEditScreenState extends State<EnhancedProfileEditScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: ColorsManager.primary,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Edit your profile',
                style: TextStyles.font24DarkBlue700Weight,
              ),
              Gap(24.h),
              Center(
                child: Text(
                  'Profile editing functionality coming soon',
                  style: TextStyles.font16DarkBlue400Weight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

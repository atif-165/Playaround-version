import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import '../../theming/colors.dart';
import '../../theming/styles.dart';
import '../../core/widgets/app_text_button.dart';

/// Screen for finding and joining sports teams
class TeamFinderScreen extends StatefulWidget {
  const TeamFinderScreen({super.key});

  @override
  State<TeamFinderScreen> createState() => _TeamFinderScreenState();
}

class _TeamFinderScreenState extends State<TeamFinderScreen> {
  String _selectedSport = 'All Sports';
  String _selectedLevel = 'All Levels';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorsManager.surface,
      appBar: AppBar(
        title: Text(
          'Find Team',
          style: TextStyles.font18DarkBlue600Weight,
        ),
        backgroundColor: ColorsManager.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: ColorsManager.onSurface,
            size: 20.sp,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.add,
              color: ColorsManager.primary,
              size: 24.sp,
            ),
            onPressed: _showCreateTeamDialog,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeaderSection(),
          Gap(32.h),
          _buildFilterSection(),
          Gap(24.h),
          _buildTeamsList(),
        ],
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: ColorsManager.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: ColorsManager.success.withValues(alpha: 0.2),
          width: 1.w,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.group,
                color: ColorsManager.success,
                size: 24.sp,
              ),
              Gap(8.w),
              Text(
                'Find Your Team',
                style: TextStyles.font18DarkBlue600Weight,
              ),
            ],
          ),
          Gap(8.h),
          Text(
            'Join existing teams or create your own. Connect with players who share your passion for sports.',
            style: TextStyles.font14Grey400Weight,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Filters',
          style: TextStyles.font16DarkBlue600Weight,
        ),
        Gap(16.h),
        Row(
          children: [
            Expanded(
              child: _buildDropdownFilter(
                'Sport',
                _selectedSport,
                [
                  'All Sports',
                  'Football',
                  'Basketball',
                  'Tennis',
                  'Swimming',
                  'Volleyball'
                ],
                (value) => setState(() => _selectedSport = value!),
              ),
            ),
            Gap(12.w),
            Expanded(
              child: _buildDropdownFilter(
                'Level',
                _selectedLevel,
                [
                  'All Levels',
                  'Beginner',
                  'Intermediate',
                  'Advanced',
                  'Professional'
                ],
                (value) => setState(() => _selectedLevel = value!),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDropdownFilter(
    String label,
    String value,
    List<String> options,
    ValueChanged<String?> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyles.font14DarkBlue600Weight,
        ),
        Gap(8.h),
        DropdownButtonFormField<String>(
          value: value,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(
                color: ColorsManager.outline,
                width: 1.w,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(
                color: ColorsManager.outline,
                width: 1.w,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(
                color: ColorsManager.primary,
                width: 2.w,
              ),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 12.w,
              vertical: 8.h,
            ),
          ),
          items: options.map((option) {
            return DropdownMenuItem(
              value: option,
              child: Text(
                option,
                style: TextStyles.font14Grey400Weight,
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildTeamsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Available Teams',
          style: TextStyles.font16DarkBlue600Weight,
        ),
        Gap(16.h),
        _buildComingSoonCard(),
      ],
    );
  }

  Widget _buildComingSoonCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: ColorsManager.outline.withValues(alpha: 0.1),
            blurRadius: 8.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.groups,
            size: 48.sp,
            color: ColorsManager.success,
          ),
          Gap(16.h),
          Text(
            'Team Finder Coming Soon!',
            style: TextStyles.font18DarkBlue600Weight,
            textAlign: TextAlign.center,
          ),
          Gap(8.h),
          Text(
            'We\'re building an amazing team discovery feature. Soon you\'ll be able to find and join teams that match your skill level and interests.',
            style: TextStyles.font14Grey400Weight,
            textAlign: TextAlign.center,
          ),
          Gap(20.h),
          AppTextButton(
            buttonText: 'Use People Search Instead',
            textStyle: TextStyles.font16White600Weight,
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/peopleSearchScreen');
            },
            backgroundColor: ColorsManager.success,
          ),
        ],
      ),
    );
  }

  void _showCreateTeamDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Create Team',
          style: TextStyles.font18DarkBlue600Weight,
        ),
        content: Text(
          'Team creation feature is coming soon! For now, you can connect with other players through the People Search feature.',
          style: TextStyles.font14Grey400Weight,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyles.font14Grey400Weight,
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/peopleSearchScreen');
            },
            child: Text(
              'Go to People Search',
              style: TextStyles.font16Blue600Weight,
            ),
          ),
        ],
      ),
    );
  }
}

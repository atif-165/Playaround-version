import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import '../../routing/app_router.dart';
import '../../theming/colors.dart';
import '../../theming/styles.dart';
import '../../core/widgets/app_text_button.dart';

/// Screen for viewing analytics and performance metrics
class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  String _selectedPeriod = 'This Month';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorsManager.surface,
      appBar: AppBar(
        title: Text(
          'Analytics',
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
              Icons.refresh,
              color: ColorsManager.primary,
              size: 24.sp,
            ),
            onPressed: _refreshData,
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
          _buildPeriodSelector(),
          Gap(24.h),
          _buildStatsOverview(),
          Gap(24.h),
          _buildChartsSection(),
          Gap(24.h),
          _buildDetailedAnalytics(),
        ],
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: ColorsManager.tertiary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: ColorsManager.tertiary.withValues(alpha: 0.2),
          width: 1.w,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.analytics,
                color: ColorsManager.tertiary,
                size: 24.sp,
              ),
              Gap(8.w),
              Text(
                'Performance Analytics',
                style: TextStyles.font18DarkBlue600Weight,
              ),
            ],
          ),
          Gap(8.h),
          Text(
            'Track your progress, analyze performance trends, and gain insights into your sports journey.',
            style: TextStyles.font14Grey400Weight,
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Time Period',
          style: TextStyles.font16DarkBlue600Weight,
        ),
        Gap(12.h),
        DropdownButtonFormField<String>(
          value: _selectedPeriod,
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
          items: [
            'This Week',
            'This Month',
            'Last 3 Months',
            'This Year',
            'All Time'
          ].map((period) {
            return DropdownMenuItem(
              value: period,
              child: Text(
                period,
                style: TextStyles.font14Grey400Weight,
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedPeriod = value!;
            });
          },
        ),
      ],
    );
  }

  Widget _buildStatsOverview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Overview',
          style: TextStyles.font16DarkBlue600Weight,
        ),
        Gap(16.h),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Sessions',
                '24',
                Icons.sports,
                ColorsManager.primary,
              ),
            ),
            Gap(12.w),
            Expanded(
              child: _buildStatCard(
                'Hours',
                '36',
                Icons.access_time,
                ColorsManager.secondary,
              ),
            ),
          ],
        ),
        Gap(12.h),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Skill Points',
                '1,250',
                Icons.trending_up,
                ColorsManager.success,
              ),
            ),
            Gap(12.w),
            Expanded(
              child: _buildStatCard(
                'Achievements',
                '8',
                Icons.emoji_events,
                ColorsManager.tertiary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: ColorsManager.outline.withValues(alpha: 0.1),
            blurRadius: 8.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: color,
                size: 20.sp,
              ),
              const Spacer(),
              Icon(
                Icons.trending_up,
                color: ColorsManager.success,
                size: 16.sp,
              ),
            ],
          ),
          Gap(8.h),
          Text(
            value,
            style: TextStyles.font18DarkBlue600Weight,
          ),
          Text(
            title,
            style: TextStyles.font12Grey400Weight,
          ),
        ],
      ),
    );
  }

  Widget _buildChartsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Performance Trends',
          style: TextStyles.font16DarkBlue600Weight,
        ),
        Gap(16.h),
        _buildComingSoonCard(
          'Charts & Graphs',
          'Interactive charts showing your progress over time will be available soon.',
          Icons.show_chart,
          ColorsManager.primary,
        ),
      ],
    );
  }

  Widget _buildDetailedAnalytics() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Detailed Reports',
          style: TextStyles.font16DarkBlue600Weight,
        ),
        Gap(16.h),
        _buildComingSoonCard(
          'Advanced Analytics',
          'Detailed performance reports, skill breakdowns, and personalized insights coming soon.',
          Icons.assessment,
          ColorsManager.secondary,
        ),
        Gap(16.h),
        AppTextButton(
          buttonText: 'View Existing Analytics',
          textStyle: TextStyles.font16White600Weight,
          onPressed: () {
            Navigator.pushReplacementNamed(
              context,
              AppRoutePath.coachAnalyticsDashboardScreen,
            );
          },
          backgroundColor: ColorsManager.tertiary,
        ),
      ],
    );
  }

  Widget _buildComingSoonCard(
      String title, String description, IconData icon, Color color) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
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
            icon,
            size: 40.sp,
            color: color,
          ),
          Gap(12.h),
          Text(
            title,
            style: TextStyles.font16DarkBlue600Weight,
            textAlign: TextAlign.center,
          ),
          Gap(8.h),
          Text(
            description,
            style: TextStyles.font14Grey400Weight,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _refreshData() {
    // TODO: Implement data refresh logic
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Analytics data refreshed!'),
      ),
    );
  }
}

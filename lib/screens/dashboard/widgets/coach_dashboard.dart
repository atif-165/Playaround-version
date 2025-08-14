import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import '../../../theming/colors.dart';
import '../../../theming/styles.dart';
import '../../../models/coach_profile.dart';

/// Coach-specific dashboard widget with coaching-related functionality
class CoachDashboard extends StatelessWidget {
  final CoachProfile coachProfile;
  final VoidCallback? onCreateSession;
  final VoidCallback? onManageBookings;
  final VoidCallback? onMyTeam;
  final VoidCallback? onAnalytics;

  const CoachDashboard({
    super.key,
    required this.coachProfile,
    this.onCreateSession,
    this.onManageBookings,
    this.onMyTeam,
    this.onAnalytics,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeSection(),
          Gap(24.h),
          _buildQuickStatsSection(),
          Gap(24.h),
          _buildActionButtonsSection(),
          Gap(24.h),
          _buildUpcomingSessionsSection(),
          Gap(24.h),
          _buildRecentActivitySection(),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [ColorsManager.mainBlue, ColorsManager.mainBlue.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: ColorsManager.mainBlue.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome back, Coach!',
            style: TextStyles.font16White600Weight.copyWith(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          Gap(8.h),
          Text(
            coachProfile.fullName,
            style: TextStyles.font16White600Weight.copyWith(
              fontSize: 24.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          Gap(4.h),
          Text(
            '${coachProfile.experienceYears} years of experience',
            style: TextStyles.font13Grey400Weight.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Stats',
          style: TextStyles.font18DarkBlue600Weight,
        ),
        Gap(12.h),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'Active Players',
                value: '12', // This would come from actual data
                icon: Icons.people,
                color: Colors.green,
              ),
            ),
            Gap(12.w),
            Expanded(
              child: _buildStatCard(
                title: 'Sessions This Week',
                value: '8',
                icon: Icons.schedule,
                color: Colors.orange,
              ),
            ),
            Gap(12.w),
            Expanded(
              child: _buildStatCard(
                title: 'Rating',
                value: '4.8',
                icon: Icons.star,
                color: Colors.amber,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 24.sp,
          ),
          Gap(8.h),
          Text(
            value,
            style: TextStyles.font18DarkBlue600Weight.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Gap(4.h),
          Text(
            title,
            style: TextStyles.font13Grey400Weight,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtonsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: TextStyles.font18DarkBlue600Weight,
        ),
        Gap(12.h),
        _buildActionButton(
          title: 'Create Session',
          subtitle: 'Schedule a new training session',
          icon: Icons.add_circle,
          color: ColorsManager.mainBlue,
          onPressed: onCreateSession,
        ),
        Gap(12.h),
        _buildActionButton(
          title: 'Manage Bookings',
          subtitle: 'View and manage player bookings',
          icon: Icons.calendar_today,
          color: Colors.green,
          onPressed: onManageBookings,
        ),
        Gap(12.h),
        _buildActionButton(
          title: 'My Team',
          subtitle: 'View and manage your team',
          icon: Icons.group,
          color: Colors.purple,
          onPressed: onMyTeam,
        ),
        Gap(12.h),
        _buildActionButton(
          title: 'Team Analytics',
          subtitle: 'View team performance and player insights',
          icon: Icons.analytics,
          color: Colors.orange,
          onPressed: onAnalytics ?? () => _navigateToAnalytics(),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    VoidCallback? onPressed,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12.r),
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 24.sp,
                  ),
                ),
                Gap(16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyles.font15DarkBlue500Weight,
                      ),
                      Gap(4.h),
                      Text(
                        subtitle,
                        style: TextStyles.font13Grey400Weight,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: ColorsManager.gray,
                  size: 16.sp,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUpcomingSessionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Upcoming Sessions',
          style: TextStyles.font18DarkBlue600Weight,
        ),
        Gap(12.h),
        SizedBox(
          height: 120.h,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 3, // This would come from actual data
            itemBuilder: (context, index) {
              return Container(
                width: 200.w,
                margin: EdgeInsets.only(right: 12.w),
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Session ${index + 1}',
                      style: TextStyles.font14Blue400Weight,
                    ),
                    Gap(4.h),
                    Text(
                      'Today, 3:00 PM',
                      style: TextStyles.font13Grey400Weight,
                    ),
                    Gap(8.h),
                    Text(
                      '5 players enrolled',
                      style: TextStyles.font13Grey400Weight,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Activity',
          style: TextStyles.font18DarkBlue600Weight,
        ),
        Gap(12.h),
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.r),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildActivityItem(
                title: 'New booking from John Doe',
                time: '2 hours ago',
                icon: Icons.book_online,
              ),
              Divider(height: 24.h),
              _buildActivityItem(
                title: 'Session completed with Team A',
                time: '1 day ago',
                icon: Icons.check_circle,
              ),
              Divider(height: 24.h),
              _buildActivityItem(
                title: 'Payment received from Sarah',
                time: '2 days ago',
                icon: Icons.payment,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActivityItem({
    required String title,
    required String time,
    required IconData icon,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          color: ColorsManager.mainBlue,
          size: 20.sp,
        ),
        Gap(12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyles.font14Blue400Weight,
              ),
              Gap(2.h),
              Text(
                time,
                style: TextStyles.font13Grey400Weight,
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _navigateToAnalytics() {
    // Default navigation to analytics if no callback provided
    // This will be called from the dashboard screen context
  }
}

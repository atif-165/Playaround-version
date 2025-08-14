import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:gap/gap.dart';

import '../../../theming/colors.dart';
import '../../../theming/typography.dart';
import '../../../models/user_profile.dart';
import '../../../models/dashboard_models.dart';
import '../../../models/player_profile.dart';
import '../../../models/coach_profile.dart';

/// Personalized header widget for the dashboard
/// Displays user greeting, profile picture, and quick stats
class PersonalizedHeader extends StatelessWidget {
  final UserProfile userProfile;
  final DashboardStats stats;
  final VoidCallback? onProfileTap;

  const PersonalizedHeader({
    super.key,
    required this.userProfile,
    required this.stats,
    this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ColorsManager.primary,
            Color(0xFF1E6BFF),
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24.r),
          bottomRight: Radius.circular(24.r),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildUserInfo(),
            Gap(20.h),
            _buildQuickStats(),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfo() {
    return Row(
      children: [
        GestureDetector(
          onTap: onProfileTap,
          child: Container(
            width: 60.w,
            height: 60.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 2.w,
              ),
            ),
            child: ClipOval(
              child: userProfile.profilePictureUrl != null
                  ? CachedNetworkImage(
                      imageUrl: userProfile.profilePictureUrl!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.white.withValues(alpha: 0.2),
                        child: Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 30.sp,
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.white.withValues(alpha: 0.2),
                        child: Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 30.sp,
                        ),
                      ),
                    )
                  : Container(
                      color: Colors.white.withValues(alpha: 0.2),
                      child: Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 30.sp,
                      ),
                    ),
            ),
          ),
        ),
        Gap(16.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getGreeting(),
                style: AppTypography.bodyMedium.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
              Gap(4.h),
              Text(
                userProfile.fullName,
                style: AppTypography.headlineSmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Gap(4.h),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 8.w,
                  vertical: 4.h,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  _getRoleText(),
                  style: AppTypography.labelSmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStats() {
    return Row(
      children: [
        Expanded(
          child: _buildStatItem(
            icon: Icons.fitness_center,
            label: 'Sessions',
            value: stats.sessionsThisMonth.toString(),
          ),
        ),
        Gap(16.w),
        Expanded(
          child: _buildStatItem(
            icon: Icons.schedule,
            label: 'Hours',
            value: stats.hoursTrained.toString(),
          ),
        ),
        Gap(16.w),
        Expanded(
          child: _buildStatItem(
            icon: Icons.trending_up,
            label: userProfile.role == UserRole.player ? 'Skill Points' : 'Rating',
            value: userProfile.role == UserRole.player 
                ? stats.skillPoints.toString()
                : stats.averageRating.toStringAsFixed(1),
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1.w,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 20.sp,
          ),
          Gap(4.h),
          Text(
            value,
            style: AppTypography.titleMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          Gap(2.h),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: Colors.white.withValues(alpha: 0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good morning';
    } else if (hour < 17) {
      return 'Good afternoon';
    } else {
      return 'Good evening';
    }
  }

  String _getRoleText() {
    switch (userProfile.role) {
      case UserRole.player:
        if (userProfile is PlayerProfile) {
          final player = userProfile as PlayerProfile;
          return '${player.skillLevel.name.toUpperCase()} PLAYER';
        }
        return 'PLAYER';
      case UserRole.coach:
        if (userProfile is CoachProfile) {
          final coach = userProfile as CoachProfile;
          return '${coach.experienceYears}Y COACH';
        }
        return 'COACH';
      case UserRole.admin:
        return 'ADMIN';
    }
  }
}

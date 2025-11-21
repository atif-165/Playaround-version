import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import '../../../theming/colors.dart';
import '../../../theming/styles.dart';
import '../models/dashboard_models.dart';

class DashboardHeader extends StatelessWidget {
  final UserProfile? userProfile;
  final UserRole userRole;

  const DashboardHeader({
    Key? key,
    required this.userProfile,
    required this.userRole,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: ColorsManager.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: ColorsManager.primary, width: 2.w),
        boxShadow: [
          BoxShadow(
            color: ColorsManager.primary.withValues(alpha: 0.1),
            blurRadius: 10.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Row(
        children: [
          // Profile Picture
          Container(
            width: 80.w,
            height: 80.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: ColorsManager.primary, width: 3.w),
              color: ColorsManager.surfaceVariant,
            ),
            child: userProfile?.photoUrl != null
                ? ClipOval(
                    child: Image.network(
                      userProfile!.photoUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildDefaultAvatar(),
                    ),
                  )
                : _buildDefaultAvatar(),
          ),
          Gap(16.w),

          // User Info & Stats
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name & Role
                Text(
                  userProfile?.name ?? 'User',
                  style: TextStyles.font20DarkBlueBold.copyWith(
                    color: ColorsManager.textPrimary,
                  ),
                ),
                Gap(4.h),
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: ColorsManager.primary,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    userProfile?.role ?? 'Player',
                    style: TextStyles.font12White600Weight,
                  ),
                ),
                Gap(12.h),

                // Quick Stats Row
                Row(
                  children: [
                    _buildStatItem(
                      'Matches',
                      '${userProfile?.quickStats.matches ?? 0}',
                      Icons.sports_basketball,
                    ),
                    Gap(16.w),
                    _buildStatItem(
                      'Wins',
                      '${userProfile?.quickStats.wins ?? 0}',
                      Icons.emoji_events,
                    ),
                    Gap(16.w),
                    _buildStatItem(
                      'Rank',
                      userProfile?.quickStats.ranking ?? 'N/A',
                      Icons.trending_up,
                    ),
                  ],
                ),

                // Next Event
                if (userProfile?.quickStats.nextEvent != null) ...[
                  Gap(8.h),
                  Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color: ColorsManager.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(
                          color: ColorsManager.primary.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.schedule,
                          color: ColorsManager.primary,
                          size: 16.sp,
                        ),
                        Gap(6.w),
                        Expanded(
                          child: Text(
                            userProfile!.quickStats.nextEvent!,
                            style: TextStyles.font12DarkBlue500Weight.copyWith(
                              color: ColorsManager.primary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Edit Profile Button
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/profile'),
            child: Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: ColorsManager.primary,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(
                Icons.edit,
                color: ColorsManager.onPrimary,
                size: 20.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            ColorsManager.primary,
            ColorsManager.primary.withValues(alpha: 0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Icon(
        Icons.person,
        color: ColorsManager.onPrimary,
        size: 40.sp,
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: ColorsManager.primary,
          size: 16.sp,
        ),
        Gap(2.h),
        Text(
          value,
          style: TextStyles.font14DarkBlueBold.copyWith(
            color: ColorsManager.textPrimary,
          ),
        ),
        Text(
          label,
          style: TextStyles.font10Grey400Weight.copyWith(
            color: ColorsManager.textSecondary,
          ),
        ),
      ],
    );
  }
}

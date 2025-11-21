import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import '../../../theming/colors.dart';
import '../../../theming/styles.dart';
import '../models/dashboard_models.dart';

class TeamRosterWidget extends StatelessWidget {
  final TeamInfo teamInfo;

  const TeamRosterWidget({
    Key? key,
    required this.teamInfo,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Team Roster',
              style: TextStyles.font18DarkBlueBold.copyWith(
                color: ColorsManager.textPrimary,
              ),
            ),
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/team-details'),
              child: Text(
                'View Team',
                style: TextStyles.font14Blue400Weight.copyWith(
                  color: ColorsManager.primary,
                ),
              ),
            ),
          ],
        ),
        Gap(16.h),

        // Team Header
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: ColorsManager.surface,
            borderRadius: BorderRadius.circular(12.r),
            border:
                Border.all(color: ColorsManager.primary.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              // Team Logo
              Container(
                width: 50.w,
                height: 50.w,
                decoration: BoxDecoration(
                  color: ColorsManager.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: ColorsManager.primary),
                ),
                child: teamInfo.logoUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12.r),
                        child: Image.network(
                          teamInfo.logoUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              _buildDefaultLogo(),
                        ),
                      )
                    : _buildDefaultLogo(),
              ),
              Gap(16.w),

              // Team Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      teamInfo.name,
                      style: TextStyles.font16DarkBlueBold.copyWith(
                        color: ColorsManager.textPrimary,
                      ),
                    ),
                    Gap(4.h),
                    Row(
                      children: [
                        Icon(
                          Icons.sports_basketball,
                          color: ColorsManager.primary,
                          size: 16.sp,
                        ),
                        Gap(4.w),
                        Text(
                          teamInfo.sport,
                          style: TextStyles.font14Grey400Weight.copyWith(
                            color: ColorsManager.primary,
                          ),
                        ),
                        Gap(16.w),
                        Icon(
                          Icons.group,
                          color: ColorsManager.textSecondary,
                          size: 16.sp,
                        ),
                        Gap(4.w),
                        Text(
                          '${teamInfo.members.length} members',
                          style: TextStyles.font14Grey400Weight,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Gap(16.h),

        // Members List
        SizedBox(
          height: 100.h,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: teamInfo.members.length,
            itemBuilder: (context, index) {
              final member = teamInfo.members[index];
              return _buildMemberCard(member);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDefaultLogo() {
    return Icon(
      Icons.groups,
      color: ColorsManager.primary,
      size: 24.sp,
    );
  }

  Widget _buildMemberCard(TeamMember member) {
    return Container(
      width: 80.w,
      margin: EdgeInsets.only(right: 12.w),
      child: Column(
        children: [
          // Member Avatar with Online Status
          Stack(
            children: [
              Container(
                width: 60.w,
                height: 60.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: member.isOnline
                        ? ColorsManager.success
                        : ColorsManager.outline,
                    width: 2.w,
                  ),
                  color: ColorsManager.surfaceVariant,
                ),
                child: member.photoUrl != null
                    ? ClipOval(
                        child: Image.network(
                          member.photoUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              _buildDefaultMemberAvatar(),
                        ),
                      )
                    : _buildDefaultMemberAvatar(),
              ),

              // Online Status Indicator
              if (member.isOnline)
                Positioned(
                  bottom: 2.h,
                  right: 2.w,
                  child: Container(
                    width: 16.w,
                    height: 16.w,
                    decoration: BoxDecoration(
                      color: ColorsManager.success,
                      shape: BoxShape.circle,
                      border:
                          Border.all(color: ColorsManager.surface, width: 2.w),
                    ),
                  ),
                ),
            ],
          ),
          Gap(8.h),

          // Member Name
          Text(
            member.name,
            style: TextStyles.font12DarkBlue600Weight.copyWith(
              color: ColorsManager.textPrimary,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          // Member Role
          Container(
            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
            decoration: BoxDecoration(
              color: _getRoleColor(member.role).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Text(
              member.role,
              style: TextStyles.font10Grey400Weight.copyWith(
                color: _getRoleColor(member.role),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultMemberAvatar() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            ColorsManager.primary.withValues(alpha: 0.7),
            ColorsManager.primary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Icon(
        Icons.person,
        color: ColorsManager.onPrimary,
        size: 24.sp,
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'captain':
        return ColorsManager.primary;
      case 'coach':
        return ColorsManager.secondary;
      case 'player':
        return ColorsManager.success;
      default:
        return ColorsManager.textSecondary;
    }
  }
}

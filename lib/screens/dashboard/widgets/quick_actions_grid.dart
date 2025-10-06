import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import '../../../theming/colors.dart';
import '../../../theming/styles.dart';
import '../models/dashboard_models.dart';

class QuickActionsGrid extends StatelessWidget {
  final UserRole userRole;
  final Function(QuickActionType) onActionTap;

  const QuickActionsGrid({
    Key? key,
    required this.userRole,
    required this.onActionTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final actions = _getActionsForRole(userRole);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: TextStyles.font18DarkBlueBold.copyWith(
            color: ColorsManager.textPrimary,
          ),
        ),
        Gap(16.h),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16.w,
            mainAxisSpacing: 16.h,
            childAspectRatio: 1.2,
          ),
          itemCount: actions.length,
          itemBuilder: (context, index) {
            final action = actions[index];
            return _buildActionCard(action);
          },
        ),
      ],
    );
  }

  List<QuickAction> _getActionsForRole(UserRole role) {
    switch (role) {
      case UserRole.player:
        return [
          QuickAction(
            type: QuickActionType.bookFacility,
            title: 'Book Facility',
            icon: Icons.sports_tennis,
            color: ColorsManager.primary,
          ),
          QuickAction(
            type: QuickActionType.findCoach,
            title: 'Find Coach',
            icon: Icons.person_search,
            color: ColorsManager.secondary,
          ),
          QuickAction(
            type: QuickActionType.joinTeam,
            title: 'Join Team',
            icon: Icons.group_add,
            color: ColorsManager.success,
          ),
          QuickAction(
            type: QuickActionType.trackSkills,
            title: 'Track Skills',
            icon: Icons.trending_up,
            color: ColorsManager.warning,
          ),
        ];
      
      case UserRole.coach:
        return [
          QuickAction(
            type: QuickActionType.bookFacility,
            title: 'Book Facility',
            icon: Icons.sports_tennis,
            color: ColorsManager.primary,
          ),
          QuickAction(
            type: QuickActionType.trackSkills,
            title: 'Student Progress',
            icon: Icons.analytics,
            color: ColorsManager.success,
          ),
          QuickAction(
            type: QuickActionType.communityForums,
            title: 'Community',
            icon: Icons.forum,
            color: ColorsManager.secondary,
          ),
          QuickAction(
            type: QuickActionType.tournaments,
            title: 'Tournaments',
            icon: Icons.emoji_events,
            color: ColorsManager.warning,
          ),
        ];
      
      case UserRole.team:
        return [
          QuickAction(
            type: QuickActionType.bookFacility,
            title: 'Book Facility',
            icon: Icons.sports_tennis,
            color: ColorsManager.primary,
          ),
          QuickAction(
            type: QuickActionType.tournaments,
            title: 'Tournaments',
            icon: Icons.emoji_events,
            color: ColorsManager.success,
          ),
          QuickAction(
            type: QuickActionType.trackSkills,
            title: 'Team Stats',
            icon: Icons.leaderboard,
            color: ColorsManager.secondary,
          ),
          QuickAction(
            type: QuickActionType.communityForums,
            title: 'Community',
            icon: Icons.forum,
            color: ColorsManager.warning,
          ),
        ];
      
      case UserRole.admin:
        return [
          QuickAction(
            type: QuickActionType.communityForums,
            title: 'Moderate',
            icon: Icons.admin_panel_settings,
            color: ColorsManager.primary,
          ),
          QuickAction(
            type: QuickActionType.trackSkills,
            title: 'Analytics',
            icon: Icons.analytics,
            color: ColorsManager.success,
          ),
          QuickAction(
            type: QuickActionType.tournaments,
            title: 'Events',
            icon: Icons.event,
            color: ColorsManager.secondary,
          ),
          QuickAction(
            type: QuickActionType.bookFacility,
            title: 'Facilities',
            icon: Icons.business,
            color: ColorsManager.warning,
          ),
        ];
    }
  }

  Widget _buildActionCard(QuickAction action) {
    return GestureDetector(
      onTap: () => onActionTap(action.type),
      child: Container(
        decoration: BoxDecoration(
          color: ColorsManager.surface,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: action.color, width: 2.w),
          boxShadow: [
            BoxShadow(
              color: action.color.withOpacity(0.2),
              blurRadius: 8.r,
              offset: Offset(0, 4.h),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: action.color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                action.icon,
                color: action.color,
                size: 32.sp,
              ),
            ),
            Gap(12.h),
            Text(
              action.title,
              style: TextStyles.font14DarkBlueBold.copyWith(
                color: ColorsManager.textPrimary,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
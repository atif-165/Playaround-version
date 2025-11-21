import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import '../../../theming/colors.dart';
import '../../../theming/styles.dart';
import '../models/dashboard_models.dart';

class QuickActionsGrid extends StatelessWidget {
  final UserRole userRole;
  final Function(QuickActionType) onActionTap;
  final bool showTitle;

  const QuickActionsGrid({
    Key? key,
    required this.userRole,
    required this.onActionTap,
    this.showTitle = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final actions = _getActionsForRole(userRole);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showTitle) ...[
          Text(
            'Quick Actions',
            style: TextStyles.font18DarkBlueBold.copyWith(
              color: ColorsManager.textPrimary,
            ),
          ),
          Gap(16.h),
        ],
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.85, end: 1),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutBack,
          builder: (context, scale, child) {
            return Transform.scale(
              scale: scale,
              alignment: Alignment.topCenter,
              child: child,
            );
          },
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16.w,
              mainAxisSpacing: 16.h,
              childAspectRatio: 1.05,
            ),
            itemCount: actions.length,
            itemBuilder: (context, index) {
              final action = actions[index];
              return _buildActionCard(action);
            },
          ),
        ),
      ],
    );
  }

  List<QuickAction> _getActionsForRole(UserRole role) {
    switch (role) {
      case UserRole.player:
        return [
          QuickAction(
            type: QuickActionType.userMatchmaking,
            title: 'Matchmaking',
            icon: Icons.people_outline,
            color: ColorsManager.primary,
          ),
          QuickAction(
            type: QuickActionType.communityForums,
            title: 'Community',
            icon: Icons.forum,
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onActionTap(action.type),
        borderRadius: BorderRadius.circular(18.r),
        splashColor: action.color.withValues(alpha: 0.2),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18.r),
            gradient: LinearGradient(
              colors: [
                action.color.withValues(alpha: 0.9),
                action.color.withValues(alpha: 0.7),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: action.color.withValues(alpha: 0.25),
                blurRadius: 14.r,
                offset: Offset(0, 8.h),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                top: -24.h,
                right: -12.w,
                child: Icon(
                  Icons.blur_on,
                  size: 80.sp,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(18.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        action.icon,
                        color: Colors.white,
                        size: 28.sp,
                      ),
                    ),
                    Gap(12.h),
                    Text(
                      action.title,
                      style: TextStyles.font16White600Weight.copyWith(
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

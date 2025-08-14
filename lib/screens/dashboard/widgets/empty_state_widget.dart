import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import '../../../theming/colors.dart';
import '../../../theming/typography.dart';

/// Empty state widget for dashboard sections with no data
class EmptyStateWidget extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final String? actionText;
  final VoidCallback? onAction;
  final Color? iconColor;

  const EmptyStateWidget({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    this.actionText,
    this.onAction,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(32.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: (iconColor ?? ColorsManager.primary).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 48.sp,
              color: iconColor ?? ColorsManager.primary,
            ),
          ),
          Gap(20.h),
          Text(
            title,
            style: AppTypography.headlineSmall.copyWith(
              color: ColorsManager.onSurface,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          Gap(8.h),
          Text(
            description,
            style: AppTypography.bodyMedium.copyWith(
              color: ColorsManager.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          if (actionText != null && onAction != null) ...[
            Gap(24.h),
            FilledButton.icon(
              onPressed: onAction,
              icon: Icon(
                Icons.add,
                size: 18.sp,
              ),
              label: Text(actionText!),
              style: FilledButton.styleFrom(
                backgroundColor: ColorsManager.primary,
                padding: EdgeInsets.symmetric(
                  horizontal: 24.w,
                  vertical: 12.h,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Compact empty state for smaller sections
class CompactEmptyState extends StatelessWidget {
  final String message;
  final IconData icon;
  final VoidCallback? onTap;

  const CompactEmptyState({
    super.key,
    required this.message,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: ColorsManager.surfaceVariant.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: ColorsManager.outlineVariant,
            width: 1.w,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 32.sp,
              color: ColorsManager.onSurfaceVariant,
            ),
            Gap(8.h),
            Text(
              message,
              style: AppTypography.bodyMedium.copyWith(
                color: ColorsManager.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Specific empty states for different dashboard sections
class DashboardEmptyStates {
  static Widget noEvents() {
    return const EmptyStateWidget(
      title: 'No Events Found',
      description: 'There are no upcoming events in your area. Check back later or explore other locations.',
      icon: Icons.event_busy,
      iconColor: ColorsManager.secondary,
    );
  }

  static Widget noCoaches() {
    return const EmptyStateWidget(
      title: 'No Coaches Available',
      description: 'We couldn\'t find any coaches matching your preferences. Try adjusting your filters.',
      icon: Icons.person_search,
      iconColor: ColorsManager.primary,
    );
  }

  static Widget noMatches() {
    return const EmptyStateWidget(
      title: 'No Matches Found',
      description: 'We\'re still looking for the perfect matches for you. Complete your profile to get better suggestions.',
      icon: Icons.favorite_border,
      iconColor: ColorsManager.tertiary,
    );
  }

  static Widget noProducts() {
    return const EmptyStateWidget(
      title: 'No Products Available',
      description: 'We don\'t have any product recommendations for you right now. Check back later!',
      icon: Icons.shopping_bag_outlined,
      iconColor: ColorsManager.success,
    );
  }

  static Widget noSessions() {
    return EmptyStateWidget(
      title: 'No Upcoming Sessions',
      description: 'You don\'t have any sessions scheduled. Book a session with a coach to get started!',
      icon: Icons.calendar_today,
      iconColor: ColorsManager.primary,
      actionText: 'Find a Coach',
      onAction: () {
        // Navigate to coaches screen
      },
    );
  }

  static Widget noTeams() {
    return EmptyStateWidget(
      title: 'No Teams Yet',
      description: 'You haven\'t joined any teams. Find a team that matches your interests and skill level.',
      icon: Icons.group_add,
      iconColor: ColorsManager.success,
      actionText: 'Find Teams',
      onAction: () {
        // Navigate to teams screen
      },
    );
  }

  static Widget noTournaments() {
    return EmptyStateWidget(
      title: 'No Tournaments',
      description: 'There are no tournaments available right now. Create your own or wait for new ones!',
      icon: Icons.emoji_events,
      iconColor: ColorsManager.secondary,
      actionText: 'Create Tournament',
      onAction: () {
        // Navigate to create tournament
      },
    );
  }

  static Widget noStudents() {
    return EmptyStateWidget(
      title: 'No Students Yet',
      description: 'You don\'t have any students enrolled. Start promoting your coaching services to attract students.',
      icon: Icons.school,
      iconColor: ColorsManager.primary,
      actionText: 'Promote Services',
      onAction: () {
        // Navigate to promotion tools
      },
    );
  }

  static Widget noBookings() {
    return EmptyStateWidget(
      title: 'No Bookings',
      description: 'You don\'t have any upcoming bookings. Students can book sessions through your profile.',
      icon: Icons.book_online,
      iconColor: ColorsManager.tertiary,
      actionText: 'View Profile',
      onAction: () {
        // Navigate to coach profile
      },
    );
  }
}

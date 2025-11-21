import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/app_text_button.dart';
import '../../core/widgets/progress_indicator.dart';
import '../../models/notification_model.dart';
import '../../services/notification_service.dart';
import '../../theming/colors.dart';
import '../../theming/public_profile_theme.dart';
import '../../theming/styles.dart';
import '../../config/app_route_paths.dart';

const _notificationHeroGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [
    Color(0xFF1B1848),
    Color(0xFF080612),
  ],
);

/// Screen displaying user notifications
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationService _notificationService = NotificationService();
  bool _initializedListener = false;

  @override
  void initState() {
    super.initState();
    _ensureRealtimeListener();
  }

  Future<void> _ensureRealtimeListener() async {
    if (_initializedListener) return;
    try {
      await _notificationService.startRealtimeListener();
      setState(() {
        _initializedListener = true;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to start notification listener: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PublicProfileTheme.backgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: 40.h,
        iconTheme: const IconThemeData(color: Colors.white),
        systemOverlayStyle: SystemUiOverlayStyle.light,
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 0,
        title: const SizedBox.shrink(),
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: _notificationHeroGradient),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 2.h),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        'Notifications',
                        style: TextStyles.font18White600Weight,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _markAllAsRead,
                    child: Text(
                      'Mark All Read',
                      style: TextStyles.font14MainBlue500Weight
                          .copyWith(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: PublicProfileTheme.backgroundGradient,
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Column(
              children: [
                Gap(20.h),
                Expanded(
                  child: StreamBuilder<List<NotificationModel>>(
                    stream: _notificationService.getUserNotifications(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(child: CustomProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return _buildStateMessage(
                          icon: Icons.error_outline,
                          title: 'Error loading notifications',
                          message: snapshot.error.toString(),
                        );
                      }

                      final notifications = snapshot.data ?? [];

                      if (notifications.isEmpty) {
                        return _buildStateMessage(
                          icon: Icons.notifications_none_outlined,
                          title: 'No notifications yet',
                          message:
                              'You\'ll see notifications here when you have updates.',
                        );
                      }

                      return ListView.builder(
                        padding: EdgeInsets.only(bottom: 24.h),
                        itemCount: notifications.length,
                        itemBuilder: (context, index) {
                          final notification = notifications[index];
                          return _buildNotificationItem(notification);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStateMessage({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64.sp, color: Colors.white30),
            Gap(16.h),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyles.font18DarkBlueBold.copyWith(color: Colors.white),
            ),
            Gap(8.h),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyles.font14Grey400Weight
                  .copyWith(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationItem(NotificationModel notification) {
    final cardColor = notification.isRead
        ? PublicProfileTheme.panelColor.withOpacity(0.92)
        : PublicProfileTheme.panelOverlayColor.withOpacity(0.96);
    final borderColor = notification.isRead
        ? Colors.white.withOpacity(0.04)
        : ColorsManager.mainBlue.withOpacity(0.35);

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 18.w),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(22.r),
        ),
        child: Icon(Icons.delete, color: Colors.white, size: 24.sp),
      ),
      onDismissed: (_) => _deleteNotification(notification.id),
      child: GestureDetector(
        onTap: () => _onNotificationTap(notification),
        child: Container(
          margin: EdgeInsets.only(bottom: 16.h),
          padding: EdgeInsets.all(18.w),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(24.r),
            border: Border.all(color: borderColor, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 24,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48.w,
                height: 48.w,
                decoration: BoxDecoration(
                  color: _getNotificationColor(notification.type)
                      .withOpacity(0.18),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getNotificationIcon(notification.type),
                  color: _getNotificationColor(notification.type),
                  size: 22.sp,
                ),
              ),
              Gap(14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyles.font16DarkBlueBold
                                .copyWith(color: Colors.white),
                          ),
                        ),
                        Text(
                          _formatDate(notification.createdAt),
                          style: TextStyles.font12Grey400Weight
                              .copyWith(color: Colors.white54),
                        ),
                      ],
                    ),
                    Gap(6.h),
                    Text(
                      notification.message,
                      style: TextStyles.font14Grey400Weight
                          .copyWith(color: Colors.white70, height: 1.4),
                    ),
                    if (notification.data != null &&
                        notification.data!['action'] != null) ...[
                      Gap(12.h),
                      AppTextButton(
                        buttonText: 'View Details',
                        textStyle: TextStyles.font14White600Weight,
                        onPressed: () => _handleNotificationAction(notification),
                        backgroundColor: ColorsManager.mainBlue,
                        buttonHeight: 38,
                      ),
                    ],
                    Gap(2.h),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.venueBooking:
        return Icons.location_city;
      case NotificationType.tournamentRegistration:
        return Icons.emoji_events;
      case NotificationType.tournamentApproval:
        return Icons.check_circle;
      case NotificationType.tournamentRejection:
        return Icons.cancel;
      case NotificationType.tournamentRemoval:
        return Icons.remove_circle;
      case NotificationType.tournamentTeamUpdate:
        return Icons.update;
      case NotificationType.matchScheduled:
        return Icons.schedule;
      case NotificationType.scoreUpdate:
        return Icons.scoreboard;
      case NotificationType.tournamentComplete:
        return Icons.emoji_events;
      case NotificationType.tournamentUpdate:
        return Icons.update;
      case NotificationType.teamInvite:
        return Icons.group_add;
      case NotificationType.ratingReceived:
        return Icons.star;
      case NotificationType.ratingRequest:
        return Icons.rate_review;
      case NotificationType.profileLike:
        return Icons.favorite;
      case NotificationType.profileComment:
        return Icons.comment;
      case NotificationType.profileFollow:
        return Icons.person_add_alt_1;
      case NotificationType.profileUpdate:
        return Icons.campaign_outlined;
      case NotificationType.userMatch:
        return Icons.people;
      case NotificationType.coachVenueRequest:
        return Icons.apartment;
      case NotificationType.coachTeamRequest:
        return Icons.groups;
      case NotificationType.coachPlayerRequest:
        return Icons.person_add_alt_1;
      case NotificationType.sessionCreated:
        return Icons.event_available;
      case NotificationType.sessionUpdated:
        return Icons.edit_calendar;
      case NotificationType.sessionCancelled:
        return Icons.event_busy;
      case NotificationType.bookingUpdate:
        return Icons.calendar_month_outlined;
      case NotificationType.general:
        return Icons.info_outline;
    }
  }

  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.venueBooking:
        return ColorsManager.success;
      case NotificationType.tournamentRegistration:
        return ColorsManager.secondary;
      case NotificationType.tournamentApproval:
        return ColorsManager.success;
      case NotificationType.tournamentRejection:
        return ColorsManager.error;
      case NotificationType.tournamentRemoval:
        return ColorsManager.error;
      case NotificationType.tournamentTeamUpdate:
        return ColorsManager.primary;
      case NotificationType.matchScheduled:
        return ColorsManager.secondary;
      case NotificationType.scoreUpdate:
        return ColorsManager.warning;
      case NotificationType.tournamentComplete:
        return ColorsManager.success;
      case NotificationType.tournamentUpdate:
        return ColorsManager.primary;
      case NotificationType.teamInvite:
        return ColorsManager.primary;
      case NotificationType.ratingReceived:
        return ColorsManager.warning;
      case NotificationType.ratingRequest:
        return ColorsManager.tertiary;
      case NotificationType.profileLike:
        return Colors.pink;
      case NotificationType.profileComment:
        return Colors.blue;
      case NotificationType.profileFollow:
        return ColorsManager.primary;
      case NotificationType.profileUpdate:
        return ColorsManager.secondary;
      case NotificationType.userMatch:
        return Colors.green;
      case NotificationType.coachVenueRequest:
        return ColorsManager.coachAccent;
      case NotificationType.coachTeamRequest:
        return ColorsManager.primary;
      case NotificationType.coachPlayerRequest:
        return ColorsManager.success;
      case NotificationType.sessionCreated:
        return ColorsManager.secondary;
      case NotificationType.sessionUpdated:
        return ColorsManager.primary;
      case NotificationType.sessionCancelled:
        return ColorsManager.error;
      case NotificationType.bookingUpdate:
        return ColorsManager.coachAccent;
      case NotificationType.general:
        return ColorsManager.textSecondary;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 7) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }

  void _onNotificationTap(NotificationModel notification) {
    if (!notification.isRead) {
      _notificationService.markAsRead(notification.id);
    }

    // Handle navigation based on notification type and data
    if (notification.data != null) {
      // final data = notification.data!;

      switch (notification.type) {
        case NotificationType.venueBooking:
          // Navigate to venue bookings or venue detail
          // TODO: Implement navigation to venue detail
          break;
        case NotificationType.tournamentRegistration:
          // Navigate to tournament detail
          // TODO: Implement navigation to tournament detail
          break;
        case NotificationType.tournamentApproval:
          // Navigate to tournament detail
          // TODO: Implement navigation to tournament detail
          break;
        case NotificationType.tournamentRejection:
          // Navigate to tournament detail
          // TODO: Implement navigation to tournament detail
          break;
        case NotificationType.tournamentRemoval:
          // Navigate to tournament detail
          // TODO: Implement navigation to tournament detail
          break;
        case NotificationType.tournamentTeamUpdate:
          // Navigate to tournament detail
          // TODO: Implement navigation to tournament detail
          break;
        case NotificationType.matchScheduled:
          // Navigate to match detail
          // TODO: Implement navigation to match detail
          break;
        case NotificationType.scoreUpdate:
          // Navigate to match detail
          // TODO: Implement navigation to match detail
          break;
        case NotificationType.tournamentComplete:
          // Navigate to tournament detail
          // TODO: Implement navigation to tournament detail
          break;
        case NotificationType.tournamentUpdate:
          // Navigate to tournament detail
          // TODO: Implement navigation to tournament detail
          break;
        case NotificationType.teamInvite:
          // Navigate to team detail or team invites
          // TODO: Implement navigation to team detail
          break;
        case NotificationType.ratingReceived:
          // Navigate to ratings screen
          // TODO: Implement navigation to ratings detail
          break;
        case NotificationType.ratingRequest:
          // Navigate to pending ratings
          // TODO: Implement navigation to pending ratings
          break;
        case NotificationType.profileLike:
          // Navigate to people search or profile
          Navigator.pushNamed(context, '/peopleSearchScreen');
          break;
        case NotificationType.profileComment:
          // Navigate to profile or comments
          Navigator.pushNamed(context, '/profileScreen');
          break;
        case NotificationType.profileFollow:
          Navigator.pushNamed(context, '/peopleSearchScreen');
          break;
        case NotificationType.profileUpdate:
          Navigator.pushNamed(context, '/profileScreen');
          break;
        case NotificationType.userMatch:
          // Navigate to matches or chat
          Navigator.pushNamed(context, '/peopleSearchScreen');
          break;
        case NotificationType.coachVenueRequest:
          // Navigate to venue management or requests
          // TODO: Implement navigation for coach venue requests
          break;
        case NotificationType.coachTeamRequest:
          // Navigate to team requests management
          // TODO: Implement navigation for coach team requests
          break;
        case NotificationType.coachPlayerRequest:
          // Navigate to player management or approvals
          // TODO: Implement navigation for coach player requests
          break;
        case NotificationType.sessionCreated:
          // Navigate to schedule
          context.pushNamed(AppRouteNames.schedule);
          break;
        case NotificationType.sessionUpdated:
          context.pushNamed(AppRouteNames.schedule);
          break;
        case NotificationType.sessionCancelled:
          context.pushNamed(AppRouteNames.schedule);
          break;
        case NotificationType.bookingUpdate:
          // Navigate to booking detail screen if available
          // TODO: Implement navigation to booking detail
          break;
        case NotificationType.general:
          // Handle general notifications
          // TODO: Implement general notification handling
          break;
      }
    }
  }

  void _handleNotificationAction(NotificationModel notification) {
    if (!notification.isRead) {
      _notificationService.markAsRead(notification.id);
    }

    final data = notification.data;
    if (data == null) {
      _onNotificationTap(notification);
      return;
    }

    final action = data['action'] as String?;
    if (action == null) {
      _onNotificationTap(notification);
      return;
    }

    switch (action) {
      case 'navigate':
      case 'navigate_to_route':
      case 'open_route':
      case 'route':
        final routeName = data['routeName'] as String?;
        final routePath =
            data['route'] as String? ?? data['path'] as String?;
        final extra = data['extra'];

        if (routeName != null) {
          context.pushNamed(routeName, extra: extra);
        } else if (routePath != null) {
          context.push(routePath, extra: extra);
        } else {
          _onNotificationTap(notification);
        }
        break;
      case 'open_profile':
        context.pushNamed(
          AppRouteNames.profile,
          extra: data['userId'],
        );
        break;
      default:
        _onNotificationTap(notification);
        break;
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      await _notificationService.markAllAsRead();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All notifications marked as read'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to mark notifications as read: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteNotification(String notificationId) async {
    try {
      await _notificationService.deleteNotification(notificationId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete notification: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}


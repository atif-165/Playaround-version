import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import '../../core/widgets/progress_indicator.dart';
import '../../models/notification_model.dart';
import '../../services/notification_service.dart';
import '../../theming/colors.dart';
import '../../theming/styles.dart';

/// Screen displaying user notifications
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationService _notificationService = NotificationService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: TextStyles.font18DarkBlueBold,
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: ColorsManager.darkBlue),
        actions: [
          TextButton(
            onPressed: _markAllAsRead,
            child: Text(
              'Mark All Read',
              style: TextStyles.font12MainBlue500Weight,
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<NotificationModel>>(
        stream: _notificationService.getUserNotifications(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CustomProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48.sp,
                    color: Colors.grey[400],
                  ),
                  Gap(16.h),
                  Text(
                    'Error loading notifications',
                    style: TextStyles.font16Grey400Weight,
                  ),
                  Gap(8.h),
                  Text(
                    snapshot.error.toString(),
                    style: TextStyles.font12Grey400Weight,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final notifications = snapshot.data ?? [];

          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none_outlined,
                    size: 64.sp,
                    color: Colors.grey[400],
                  ),
                  Gap(16.h),
                  Text(
                    'No notifications yet',
                    style: TextStyles.font18DarkBlue600Weight,
                  ),
                  Gap(8.h),
                  Text(
                    'You\'ll see notifications here when you have updates',
                    style: TextStyles.font14Grey400Weight,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(16.w),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return _buildNotificationItem(notification);
            },
          );
        },
      ),
    );
  }

  Widget _buildNotificationItem(NotificationModel notification) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 16.w),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Icon(
          Icons.delete,
          color: Colors.white,
          size: 24.sp,
        ),
      ),
      onDismissed: (direction) {
        _deleteNotification(notification.id);
      },
      child: GestureDetector(
        onTap: () => _onNotificationTap(notification),
        child: Container(
          margin: EdgeInsets.only(bottom: 12.h),
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: notification.isRead ? Colors.white : ColorsManager.mainBlue.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(
              color: notification.isRead 
                  ? Colors.grey[200]! 
                  : ColorsManager.mainBlue.withValues(alpha: 0.2),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.1),
                spreadRadius: 1,
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40.w,
                height: 40.h,
                decoration: BoxDecoration(
                  color: _getNotificationColor(notification.type).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getNotificationIcon(notification.type),
                  color: _getNotificationColor(notification.type),
                  size: 20.sp,
                ),
              ),
              Gap(12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: notification.isRead 
                                ? TextStyles.font14DarkBlue600Weight
                                : TextStyles.font14DarkBlueBold,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 8.w,
                            height: 8.h,
                            decoration: const BoxDecoration(
                              color: ColorsManager.mainBlue,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    Gap(4.h),
                    Text(
                      notification.message,
                      style: TextStyles.font12Grey400Weight,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Gap(8.h),
                    Text(
                      _formatDate(notification.createdAt),
                      style: TextStyles.font10Grey400Weight,
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
      case NotificationType.userMatch:
        return Icons.people;
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
      case NotificationType.userMatch:
        return Colors.green;
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
        case NotificationType.userMatch:
          // Navigate to matches or chat
          Navigator.pushNamed(context, '/peopleSearchScreen');
          break;
        case NotificationType.general:
          // Handle general notifications
          // TODO: Implement general notification handling
          break;
      }
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

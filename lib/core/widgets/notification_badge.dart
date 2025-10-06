import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import '../../theming/colors.dart';
import '../../theming/typography.dart';

/// Widget for displaying notification badges with count
class NotificationBadge extends StatelessWidget {
  final int count;
  final Widget child;
  final Color? badgeColor;
  final Color? textColor;
  final double? size;

  const NotificationBadge({
    super.key,
    required this.count,
    required this.child,
    this.badgeColor,
    this.textColor,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        if (count > 0)
          Positioned(
            right: -6.w,
            top: -6.h,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: count > 99 ? 6.w : 4.w,
                vertical: 2.h,
              ),
              decoration: BoxDecoration(
                color: badgeColor ?? ColorsManager.error,
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(
                  color: Colors.white,
                  width: 1.w,
                ),
              ),
              constraints: BoxConstraints(
                minWidth: 16.w,
                minHeight: 16.h,
              ),
              child: Text(
                count > 99 ? '99+' : count.toString(),
                style: AppTypography.labelSmall.copyWith(
                  color: textColor ?? Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 10.sp,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}

/// Widget for displaying notification list
class NotificationList extends StatelessWidget {
  final List<NotificationItem> notifications;
  final Function(NotificationItem)? onNotificationTap;
  final Function(NotificationItem)? onNotificationDismiss;

  const NotificationList({
    super.key,
    required this.notifications,
    this.onNotificationTap,
    this.onNotificationDismiss,
  });

  @override
  Widget build(BuildContext context) {
    if (notifications.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      shrinkWrap: true,
      itemCount: notifications.length,
      itemBuilder: (context, index) {
        final notification = notifications[index];
        return NotificationItemWidget(
          notification: notification,
          onTap: () => onNotificationTap?.call(notification),
          onDismiss: () => onNotificationDismiss?.call(notification),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: EdgeInsets.all(32.w),
      child: Column(
        children: [
          Icon(
            Icons.notifications_none,
            size: 48.sp,
            color: ColorsManager.onSurfaceVariant,
          ),
          Gap(12.h),
          Text(
            'No Notifications',
            style: AppTypography.titleMedium.copyWith(
              color: ColorsManager.onSurfaceVariant,
            ),
          ),
          Gap(4.h),
          Text(
            'You\'re all caught up!',
            style: AppTypography.bodySmall.copyWith(
              color: ColorsManager.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget for individual notification item
class NotificationItemWidget extends StatelessWidget {
  final NotificationItem notification;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;

  const NotificationItemWidget({
    super.key,
    required this.notification,
    this.onTap,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 8.h),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(12.w),
          child: Row(
            children: [
              // Notification Icon
              Container(
                width: 40.w,
                height: 40.w,
                decoration: BoxDecoration(
                  color: _getNotificationColor().withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(
                  _getNotificationIcon(),
                  color: _getNotificationColor(),
                  size: 20.sp,
                ),
              ),
              Gap(12.w),
              // Notification Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: AppTypography.bodyMedium.copyWith(
                        color: ColorsManager.onSurface,
                        fontWeight: notification.isRead ? FontWeight.normal : FontWeight.w600,
                      ),
                    ),
                    Gap(4.h),
                    Text(
                      notification.message,
                      style: AppTypography.bodySmall.copyWith(
                        color: ColorsManager.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Gap(4.h),
                    Text(
                      _formatTime(notification.timestamp),
                      style: AppTypography.labelSmall.copyWith(
                        color: ColorsManager.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              // Dismiss Button
              if (onDismiss != null)
                IconButton(
                  onPressed: onDismiss,
                  icon: Icon(
                    Icons.close,
                    size: 16.sp,
                    color: ColorsManager.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getNotificationColor() {
    switch (notification.type) {
      case NotificationType.match:
        return ColorsManager.primary;
      case NotificationType.tournament:
        return ColorsManager.warning;
      case NotificationType.team:
        return ColorsManager.secondary;
      case NotificationType.system:
        return ColorsManager.onSurfaceVariant;
    }
  }

  IconData _getNotificationIcon() {
    switch (notification.type) {
      case NotificationType.match:
        return Icons.sports_soccer;
      case NotificationType.tournament:
        return Icons.emoji_events;
      case NotificationType.team:
        return Icons.groups;
      case NotificationType.system:
        return Icons.info;
    }
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.day}/${timestamp.month}';
    }
  }
}

/// Model for notification items
class NotificationItem {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final DateTime timestamp;
  final bool isRead;
  final Map<String, dynamic>? data;

  const NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.timestamp,
    this.isRead = false,
    this.data,
  });
}

/// Enum for notification types
enum NotificationType {
  match,
  tournament,
  team,
  system;
}

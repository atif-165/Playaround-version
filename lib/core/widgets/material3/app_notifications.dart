import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import '../../../theming/colors.dart';
import '../../../theming/typography.dart';
import 'app_cards.dart';
import 'app_buttons.dart';
import 'app_chips.dart';

/// Material 3 Notification Components for PlayAround App
/// Comprehensive notification system with different types and styles

enum NotificationType {
  info,
  success,
  warning,
  error,
  booking,
  tournament,
  social,
  system,
}

enum NotificationPriority {
  low,
  normal,
  high,
  urgent,
}

/// In-app notification model
class AppNotification {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final NotificationPriority priority;
  final DateTime timestamp;
  final String? imageUrl;
  final String? actionText;
  final VoidCallback? onAction;
  final VoidCallback? onDismiss;
  final bool isRead;
  final Map<String, dynamic>? data;

  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    this.priority = NotificationPriority.normal,
    required this.timestamp,
    this.imageUrl,
    this.actionText,
    this.onAction,
    this.onDismiss,
    this.isRead = false,
    this.data,
  });

  AppNotification copyWith({
    String? id,
    String? title,
    String? message,
    NotificationType? type,
    NotificationPriority? priority,
    DateTime? timestamp,
    String? imageUrl,
    String? actionText,
    VoidCallback? onAction,
    VoidCallback? onDismiss,
    bool? isRead,
    Map<String, dynamic>? data,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      timestamp: timestamp ?? this.timestamp,
      imageUrl: imageUrl ?? this.imageUrl,
      actionText: actionText ?? this.actionText,
      onAction: onAction ?? this.onAction,
      onDismiss: onDismiss ?? this.onDismiss,
      isRead: isRead ?? this.isRead,
      data: data ?? this.data,
    );
  }
}

/// Notification card widget
class NotificationCard extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;
  final bool showDismissButton;
  final bool showTimestamp;

  const NotificationCard({
    super.key,
    required this.notification,
    this.onTap,
    this.onDismiss,
    this.showDismissButton = true,
    this.showTimestamp = true,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      variant: notification.isRead ? CardVariant.filled : CardVariant.elevated,
      size: CardSize.medium,
      onTap: onTap,
      backgroundColor: notification.isRead
          ? ColorsManager.surfaceVariant.withValues(alpha: 0.5)
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          Gap(8.h),
          _buildContent(),
          if (notification.actionText != null || showTimestamp) ...[
            Gap(12.h),
            _buildFooter(),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        _buildTypeIcon(),
        Gap(12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                notification.title,
                style: AppTypography.titleMedium.copyWith(
                  fontWeight:
                      notification.isRead ? FontWeight.w500 : FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (_getPriorityText() != null) ...[
                Gap(2.h),
                AppBadge(
                  label: _getPriorityText()!,
                  variant: _getPriorityBadgeVariant(),
                ),
              ],
            ],
          ),
        ),
        if (showDismissButton) ...[
          Gap(8.w),
          IconButton(
            onPressed: onDismiss ?? notification.onDismiss,
            icon: const Icon(Icons.close),
            iconSize: 20.w,
            color: ColorsManager.onSurfaceVariant,
          ),
        ],
      ],
    );
  }

  Widget _buildTypeIcon() {
    return Container(
      padding: EdgeInsets.all(8.w),
      decoration: BoxDecoration(
        color: _getTypeColor().withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Icon(
        _getTypeIcon(),
        color: _getTypeColor(),
        size: 20.w,
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          notification.message,
          style: AppTypography.bodyMedium.copyWith(
            color: notification.isRead
                ? ColorsManager.onSurfaceVariant
                : ColorsManager.onSurface,
          ),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        if (notification.imageUrl != null) ...[
          Gap(8.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(8.r),
            child: Image.network(
              notification.imageUrl!,
              height: 120.h,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                height: 120.h,
                color: ColorsManager.surfaceVariant,
                child: Icon(
                  Icons.image_not_supported,
                  color: ColorsManager.onSurfaceVariant,
                  size: 32.w,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFooter() {
    return Row(
      children: [
        if (showTimestamp) ...[
          Icon(
            Icons.access_time,
            size: 14.w,
            color: ColorsManager.onSurfaceVariant,
          ),
          Gap(4.w),
          Text(
            _formatTimestamp(),
            style: AppTypography.bodySmall.copyWith(
              color: ColorsManager.onSurfaceVariant,
            ),
          ),
        ],
        const Spacer(),
        if (notification.actionText != null) ...[
          AppTextButton(
            text: notification.actionText!,
            onPressed: notification.onAction,
            size: ButtonSize.small,
            variant: _getActionButtonVariant(),
          ),
        ],
      ],
    );
  }

  IconData _getTypeIcon() {
    switch (notification.type) {
      case NotificationType.info:
        return Icons.info_outline;
      case NotificationType.success:
        return Icons.check_circle_outline;
      case NotificationType.warning:
        return Icons.warning_amber_outlined;
      case NotificationType.error:
        return Icons.error_outline;
      case NotificationType.booking:
        return Icons.event_available;
      case NotificationType.tournament:
        return Icons.emoji_events_outlined;
      case NotificationType.social:
        return Icons.people_outline;
      case NotificationType.system:
        return Icons.settings_outlined;
    }
  }

  Color _getTypeColor() {
    switch (notification.type) {
      case NotificationType.info:
        return ColorsManager.info;
      case NotificationType.success:
        return ColorsManager.success;
      case NotificationType.warning:
        return ColorsManager.warning;
      case NotificationType.error:
        return ColorsManager.error;
      case NotificationType.booking:
        return ColorsManager.primary;
      case NotificationType.tournament:
        return ColorsManager.secondary;
      case NotificationType.social:
        return ColorsManager.tertiary;
      case NotificationType.system:
        return ColorsManager.onSurfaceVariant;
    }
  }

  String? _getPriorityText() {
    switch (notification.priority) {
      case NotificationPriority.urgent:
        return 'URGENT';
      case NotificationPriority.high:
        return 'HIGH';
      case NotificationPriority.normal:
      case NotificationPriority.low:
        return null;
    }
  }

  BadgeVariant _getPriorityBadgeVariant() {
    switch (notification.priority) {
      case NotificationPriority.urgent:
        return BadgeVariant.error;
      case NotificationPriority.high:
        return BadgeVariant.warning;
      case NotificationPriority.normal:
      case NotificationPriority.low:
        return BadgeVariant.primary;
    }
  }

  ButtonVariant _getActionButtonVariant() {
    switch (notification.type) {
      case NotificationType.success:
        return ButtonVariant.success;
      case NotificationType.warning:
        return ButtonVariant.warning;
      case NotificationType.error:
        return ButtonVariant.error;
      default:
        return ButtonVariant.primary;
    }
  }

  String _formatTimestamp() {
    final now = DateTime.now();
    final difference = now.difference(notification.timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${notification.timestamp.day}/${notification.timestamp.month}/${notification.timestamp.year}';
    }
  }
}

/// Notification list widget
class NotificationList extends StatelessWidget {
  final List<AppNotification> notifications;
  final Function(AppNotification)? onNotificationTap;
  final Function(AppNotification)? onNotificationDismiss;
  final bool showEmptyState;
  final Widget? emptyStateWidget;

  const NotificationList({
    super.key,
    required this.notifications,
    this.onNotificationTap,
    this.onNotificationDismiss,
    this.showEmptyState = true,
    this.emptyStateWidget,
  });

  @override
  Widget build(BuildContext context) {
    if (notifications.isEmpty && showEmptyState) {
      return emptyStateWidget ?? _buildEmptyState();
    }

    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: notifications.length,
      itemBuilder: (context, index) {
        final notification = notifications[index];
        return Padding(
          padding: EdgeInsets.only(bottom: 12.h),
          child: NotificationCard(
            notification: notification,
            onTap: () => onNotificationTap?.call(notification),
            onDismiss: () => onNotificationDismiss?.call(notification),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_none,
              size: 80.w,
              color: ColorsManager.onSurfaceVariant,
            ),
            Gap(24.h),
            Text(
              'No notifications',
              style: AppTypography.headlineSmall.copyWith(
                color: ColorsManager.onSurfaceVariant,
              ),
            ),
            Gap(16.h),
            Text(
              'You\'re all caught up! New notifications will appear here.',
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

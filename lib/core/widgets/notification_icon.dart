import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../services/notification_service.dart';
import '../../theming/colors.dart';
import '../../screens/notifications/notifications_screen.dart';

/// Notification icon widget with badge for unread count
class NotificationIcon extends StatelessWidget {
  final NotificationService _notificationService = NotificationService();

  NotificationIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: _notificationService.getUnreadNotificationsCount(),
      builder: (context, snapshot) {
        final unreadCount = snapshot.data ?? 0;
        
        return Stack(
          children: [
            IconButton(
              onPressed: () => _navigateToNotifications(context),
              icon: Icon(
                Icons.notifications_outlined,
                color: ColorsManager.darkBlue,
                size: 24.sp,
              ),
            ),
            if (unreadCount > 0)
              Positioned(
                right: 8.w,
                top: 8.h,
                child: Container(
                  padding: EdgeInsets.all(2.w),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  constraints: BoxConstraints(
                    minWidth: 16.w,
                    minHeight: 16.h,
                  ),
                  child: Text(
                    unreadCount > 99 ? '99+' : unreadCount.toString(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  void _navigateToNotifications(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const NotificationsScreen(),
      ),
    );
  }
}

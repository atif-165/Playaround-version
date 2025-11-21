import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import '../../../theming/colors.dart';
import '../../../theming/styles.dart';

class NotificationsPanel extends StatelessWidget {
  final List<dynamic> notifications;

  const NotificationsPanel({
    Key? key,
    required this.notifications,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: ColorsManager.surface,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Notifications',
                style: TextStyles.font18DarkBlue600Weight,
              ),
              if (notifications.isNotEmpty)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: ColorsManager.primary,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    '${notifications.length}',
                    style: TextStyles.font12White500Weight,
                  ),
                ),
            ],
          ),
          Gap(12.h),
          if (notifications.isEmpty)
            Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24.h),
                child: Column(
                  children: [
                    Icon(
                      Icons.notifications_none,
                      size: 48.sp,
                      color: ColorsManager.grey,
                    ),
                    Gap(8.h),
                    Text(
                      'No new notifications',
                      style: TextStyles.font14Grey400Weight,
                    ),
                  ],
                ),
              ),
            )
          else
            ...notifications
                .take(5)
                .map((notification) => _buildNotificationItem(notification)),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(dynamic notification) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: ColorsManager.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(
              Icons.notifications,
              color: ColorsManager.primary,
              size: 16.sp,
            ),
          ),
          Gap(12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification.toString(),
                  style: TextStyles.font14DarkBlue500Weight,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Gap(4.h),
                Text(
                  'Just now',
                  style: TextStyles.font12Grey400Weight,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

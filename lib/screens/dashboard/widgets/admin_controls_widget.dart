import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import '../../../routing/routes.dart';
import '../../../theming/colors.dart';
import '../../../theming/styles.dart';

class AdminControlsWidget extends StatelessWidget {
  final dynamic adminData;

  const AdminControlsWidget({
    Key? key,
    this.adminData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: ColorsManager.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: ColorsManager.primary.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: ColorsManager.primary.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.admin_panel_settings,
                color: ColorsManager.primary,
                size: 24.sp,
              ),
              Gap(8.w),
              Text(
                'Admin Controls',
                style: TextStyles.font18DarkBlue600Weight,
              ),
            ],
          ),
          Gap(16.h),
          _buildAdminAction(
            icon: Icons.people,
            label: 'Manage Users',
            count: adminData?.toString() ?? '0',
            onTap: () {
              // TODO: Navigate to user management
            },
          ),
          Gap(12.h),
          _buildAdminAction(
            icon: Icons.flag,
            label: 'Moderate Community',
            count: '',
            onTap: () {
              Navigator.pushNamed(context, Routes.communityAdminModeration);
            },
          ),
          Gap(12.h),
          _buildAdminAction(
            icon: Icons.settings,
            label: 'System Settings',
            count: '',
            onTap: () {
              // TODO: Navigate to settings
            },
          ),
          Gap(12.h),
          _buildAdminAction(
            icon: Icons.shopping_bag,
            label: 'Manage Orders',
            count: '',
            onTap: () {
              Navigator.pushNamed(context, Routes.shopAdminOrders);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAdminAction({
    required IconData icon,
    required String label,
    required String count,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8.r),
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: ColorsManager.background,
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: ColorsManager.primary,
              size: 20.sp,
            ),
            Gap(12.w),
            Expanded(
              child: Text(
                label,
                style: TextStyles.font14DarkBlue500Weight,
              ),
            ),
            if (count.isNotEmpty)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: ColorsManager.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  count,
                  style: TextStyles.font12DarkBlue500Weight.copyWith(
                    color: ColorsManager.primary,
                  ),
                ),
              ),
            Gap(8.w),
            Icon(
              Icons.chevron_right,
              color: ColorsManager.gray,
              size: 20.sp,
            ),
          ],
        ),
      ),
    );
  }
}

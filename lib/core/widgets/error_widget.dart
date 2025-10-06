import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../theming/colors.dart';
import '../../theming/styles.dart';

/// Error widget for showing error states
class AppErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final IconData? icon;

  const AppErrorWidget({
    super.key,
    required this.message,
    this.onRetry,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon ?? Icons.error_outline,
              size: 64.w,
              color: ColorsManager.error,
            ),
            SizedBox(height: 16.h),
            Text(
              'Oops! Something went wrong',
              style: TextStyles.font16White600Weight,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8.h),
            Text(
              message,
              style: TextStyles.font14White500Weight.copyWith(
                color: ColorsManager.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              SizedBox(height: 24.h),
              ElevatedButton(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorsManager.primary,
                  foregroundColor: ColorsManager.onPrimary,
                  padding: EdgeInsets.symmetric(
                    horizontal: 24.w,
                    vertical: 12.h,
                  ),
                ),
                child: Text(
                  'Try Again',
                  style: TextStyles.font14WhiteSemiBold,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

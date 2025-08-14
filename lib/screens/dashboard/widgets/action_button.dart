import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import '../../../theming/colors.dart';
import '../../../theming/typography.dart';

/// Action button widget for dashboard quick actions
class ActionButton extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;
  final bool isLoading;
  final bool isEnabled;
  final Widget? badge;

  const ActionButton({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onPressed,
    this.isLoading = false,
    this.isEnabled = true,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isEnabled && !isLoading ? onPressed : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: isEnabled ? Colors.white : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: isEnabled
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.1),
                    blurRadius: 12.r,
                    offset: Offset(0, 4.h),
                  ),
                ]
              : [],
          border: Border.all(
            color: isEnabled 
                ? color.withValues(alpha: 0.2)
                : ColorsManager.outlineVariant,
            width: 1.w,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Stack(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: isEnabled 
                            ? color.withValues(alpha: 0.1)
                            : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: isLoading
                          ? SizedBox(
                              width: 24.sp,
                              height: 24.sp,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.w,
                                color: color,
                              ),
                            )
                          : Icon(
                              icon,
                              color: isEnabled ? color : Colors.grey,
                              size: 24.sp,
                            ),
                    ),
                    if (badge != null)
                      Positioned(
                        top: 0,
                        right: 0,
                        child: badge!,
                      ),
                  ],
                ),
                const Spacer(),
                Icon(
                  Icons.arrow_forward_ios,
                  color: isEnabled 
                      ? ColorsManager.onSurfaceVariant 
                      : Colors.grey,
                  size: 16.sp,
                ),
              ],
            ),
            Gap(12.h),
            Text(
              title,
              style: AppTypography.titleMedium.copyWith(
                color: isEnabled 
                    ? ColorsManager.onSurface 
                    : Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
            Gap(4.h),
            Text(
              subtitle,
              style: AppTypography.bodySmall.copyWith(
                color: isEnabled 
                    ? ColorsManager.onSurfaceVariant 
                    : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact action button for grid layouts
class CompactActionButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;
  final bool isLoading;
  final Widget? badge;

  const CompactActionButton({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.onPressed,
    this.isLoading = false,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: !isLoading ? onPressed : null,
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 8.r,
              offset: Offset(0, 2.h),
            ),
          ],
          border: Border.all(
            color: color.withValues(alpha: 0.2),
            width: 1.w,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              children: [
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: isLoading
                      ? SizedBox(
                          width: 24.sp,
                          height: 24.sp,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.w,
                            color: color,
                          ),
                        )
                      : Icon(
                          icon,
                          color: color,
                          size: 24.sp,
                        ),
                ),
                if (badge != null)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: badge!,
                  ),
              ],
            ),
            Gap(8.h),
            Text(
              title,
              style: AppTypography.labelMedium.copyWith(
                color: ColorsManager.onSurface,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Floating action button for primary actions
class FloatingActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool isLoading;
  final Color? backgroundColor;

  const FloatingActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.isLoading = false,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: !isLoading ? onPressed : null,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 20.w,
          vertical: 12.h,
        ),
        decoration: BoxDecoration(
          color: backgroundColor ?? ColorsManager.primary,
          borderRadius: BorderRadius.circular(24.r),
          boxShadow: [
            BoxShadow(
              color: (backgroundColor ?? ColorsManager.primary).withValues(alpha: 0.3),
              blurRadius: 12.r,
              offset: Offset(0, 6.h),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLoading)
              SizedBox(
                width: 20.sp,
                height: 20.sp,
                child: CircularProgressIndicator(
                  strokeWidth: 2.w,
                  color: Colors.white,
                ),
              )
            else
              Icon(
                icon,
                color: Colors.white,
                size: 20.sp,
              ),
            Gap(8.w),
            Text(
              label,
              style: AppTypography.labelLarge.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Badge widget for action buttons
class ActionBadge extends StatelessWidget {
  final String text;
  final Color? backgroundColor;
  final Color? textColor;

  const ActionBadge({
    super.key,
    required this.text,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 6.w,
        vertical: 2.h,
      ),
      decoration: BoxDecoration(
        color: backgroundColor ?? ColorsManager.error,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Text(
        text,
        style: AppTypography.labelSmall.copyWith(
          color: textColor ?? Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

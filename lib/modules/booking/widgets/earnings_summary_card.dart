import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import '../../../theming/styles.dart';

/// Card widget for displaying earnings summary information
class EarningsSummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String? subtitle;
  final VoidCallback? onTap;

  const EarningsSummaryCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 20.w,
                  ),
                ),
                const Spacer(),
                if (onTap != null)
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16.w,
                    color: Colors.grey[400],
                  ),
              ],
            ),
            Gap(12.h),
            Text(
              value,
              style: TextStyles.font20DarkBlueBold,
            ),
            Gap(4.h),
            Text(
              title,
              style: TextStyles.font12Grey400Weight,
            ),
            if (subtitle != null) ...[
              Gap(4.h),
              Text(
                subtitle!,
                style: TextStyles.font10Grey400Weight,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Horizontal earnings summary card for compact display
class HorizontalEarningsSummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String? changeText;
  final bool? isPositiveChange;

  const HorizontalEarningsSummaryCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.changeText,
    this.isPositiveChange,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24.w,
            ),
          ),
          Gap(16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyles.font12Grey400Weight,
                ),
                Gap(4.h),
                Text(
                  value,
                  style: TextStyles.font18DarkBlueBold,
                ),
                if (changeText != null) ...[
                  Gap(4.h),
                  Row(
                    children: [
                      Icon(
                        isPositiveChange == true
                            ? Icons.trending_up
                            : Icons.trending_down,
                        size: 14.w,
                        color: isPositiveChange == true
                            ? Colors.green
                            : Colors.red,
                      ),
                      Gap(4.w),
                      Text(
                        changeText!,
                        style: TextStyles.font10Grey400Weight.copyWith(
                          color: isPositiveChange == true
                              ? Colors.green
                              : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

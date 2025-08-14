import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import '../../../theming/colors.dart';
import '../../../theming/typography.dart';

/// Reusable quick stats card widget for displaying metrics
class QuickStatsCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool showTrend;
  final double? trendValue;
  final bool isPositiveTrend;

  const QuickStatsCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
    this.onTap,
    this.showTrend = false,
    this.trendValue,
    this.isPositiveTrend = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: ColorsManager.surfaceVariant,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 10.r,
              offset: Offset(0, 4.h),
            ),
          ],
          border: Border.all(
            color: ColorsManager.outline,
            width: 1.w,
          ),
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
                    size: 20.sp,
                  ),
                ),
                const Spacer(),
                if (showTrend && trendValue != null) _buildTrendIndicator(),
              ],
            ),
            Gap(12.h),
            Text(
              value,
              style: AppTypography.headlineMedium.copyWith(
                color: ColorsManager.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
            Gap(4.h),
            Text(
              title,
              style: AppTypography.bodyMedium.copyWith(
                color: ColorsManager.onSurfaceVariant,
              ),
            ),
            if (subtitle != null) ...[
              Gap(4.h),
              Text(
                subtitle!,
                style: AppTypography.labelSmall.copyWith(
                  color: ColorsManager.onSurfaceVariant.withValues(alpha: 0.7),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTrendIndicator() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 6.w,
        vertical: 2.h,
      ),
      decoration: BoxDecoration(
        color: isPositiveTrend
            ? ColorsManager.success.withValues(alpha: 0.1)
            : ColorsManager.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPositiveTrend ? Icons.trending_up : Icons.trending_down,
            color: isPositiveTrend ? ColorsManager.success : ColorsManager.error,
            size: 12.sp,
          ),
          Gap(2.w),
          Text(
            '${trendValue!.abs().toStringAsFixed(1)}%',
            style: AppTypography.labelSmall.copyWith(
              color: isPositiveTrend ? ColorsManager.success : ColorsManager.error,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Specialized stats card for sports metrics
class SportsStatsCard extends StatelessWidget {
  final String sport;
  final int sessions;
  final double hours;
  final int skillPoints;
  final VoidCallback? onTap;

  const SportsStatsCard({
    super.key,
    required this.sport,
    required this.sessions,
    required this.hours,
    required this.skillPoints,
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
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10.r,
              offset: Offset(0, 4.h),
            ),
          ],
          border: Border.all(
            color: ColorsManager.outlineVariant,
            width: 1.w,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: ColorsManager.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(
                    _getSportIcon(sport),
                    color: ColorsManager.primary,
                    size: 20.sp,
                  ),
                ),
                Gap(8.w),
                Expanded(
                  child: Text(
                    sport,
                    style: AppTypography.titleMedium.copyWith(
                      color: ColorsManager.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            Gap(16.h),
            Row(
              children: [
                Expanded(
                  child: _buildMiniStat(
                    label: 'Sessions',
                    value: sessions.toString(),
                    icon: Icons.fitness_center,
                  ),
                ),
                Gap(8.w),
                Expanded(
                  child: _buildMiniStat(
                    label: 'Hours',
                    value: hours.toStringAsFixed(1),
                    icon: Icons.schedule,
                  ),
                ),
                Gap(8.w),
                Expanded(
                  child: _buildMiniStat(
                    label: 'Points',
                    value: skillPoints.toString(),
                    icon: Icons.trending_up,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: ColorsManager.onSurfaceVariant,
          size: 16.sp,
        ),
        Gap(4.h),
        Text(
          value,
          style: AppTypography.titleSmall.copyWith(
            color: ColorsManager.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        Gap(2.h),
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: ColorsManager.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  IconData _getSportIcon(String sport) {
    switch (sport.toLowerCase()) {
      case 'football':
      case 'soccer':
        return Icons.sports_soccer;
      case 'basketball':
        return Icons.sports_basketball;
      case 'tennis':
        return Icons.sports_tennis;
      case 'volleyball':
        return Icons.sports_volleyball;
      case 'baseball':
        return Icons.sports_baseball;
      case 'golf':
        return Icons.sports_golf;
      case 'hockey':
        return Icons.sports_hockey;
      case 'cricket':
        return Icons.sports_cricket;
      default:
        return Icons.sports;
    }
  }
}

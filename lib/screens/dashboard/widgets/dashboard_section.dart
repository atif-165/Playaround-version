import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import '../../../theming/colors.dart';
import '../../../theming/typography.dart';

/// Reusable section widget for dashboard content
class DashboardSection extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  final VoidCallback? onSeeAll;
  final String? seeAllText;
  final EdgeInsetsGeometry? padding;
  final bool showDivider;

  const DashboardSection({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
    this.onSeeAll,
    this.seeAllText,
    this.padding,
    this.showDivider = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: padding ?? EdgeInsets.symmetric(horizontal: 20.w),
          child: _buildSectionHeader(),
        ),
        Gap(16.h),
        child,
        if (showDivider) ...[
          Gap(24.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Divider(
              color: ColorsManager.outlineVariant,
              thickness: 1.h,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSectionHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.headlineSmall.copyWith(
                  color: ColorsManager.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (subtitle != null) ...[
                Gap(4.h),
                Text(
                  subtitle!,
                  style: AppTypography.bodyMedium.copyWith(
                    color: ColorsManager.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (onSeeAll != null)
          TextButton(
            onPressed: onSeeAll,
            style: TextButton.styleFrom(
              foregroundColor: ColorsManager.primary,
              padding: EdgeInsets.symmetric(
                horizontal: 12.w,
                vertical: 8.h,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  seeAllText ?? 'See All',
                  style: AppTypography.labelLarge.copyWith(
                    color: ColorsManager.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Gap(4.w),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 14.sp,
                  color: ColorsManager.primary,
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Carousel section widget for horizontal scrollable content
class CarouselSection extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget> children;
  final VoidCallback? onSeeAll;
  final String? seeAllText;
  final double height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? itemPadding;

  const CarouselSection({
    super.key,
    required this.title,
    this.subtitle,
    required this.children,
    this.onSeeAll,
    this.seeAllText,
    required this.height,
    this.padding,
    this.itemPadding,
  });

  @override
  Widget build(BuildContext context) {
    return DashboardSection(
      title: title,
      subtitle: subtitle,
      onSeeAll: onSeeAll,
      seeAllText: seeAllText,
      padding: padding,
      child: SizedBox(
        height: height,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: itemPadding ?? EdgeInsets.symmetric(horizontal: 20.w),
          itemCount: children.length,
          itemBuilder: (context, index) => children[index],
        ),
      ),
    );
  }
}

/// Grid section widget for grid layout content
class GridSection extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget> children;
  final VoidCallback? onSeeAll;
  final String? seeAllText;
  final int crossAxisCount;
  final double childAspectRatio;
  final double crossAxisSpacing;
  final double mainAxisSpacing;
  final EdgeInsetsGeometry? padding;

  const GridSection({
    super.key,
    required this.title,
    this.subtitle,
    required this.children,
    this.onSeeAll,
    this.seeAllText,
    this.crossAxisCount = 2,
    this.childAspectRatio = 1.0,
    this.crossAxisSpacing = 16.0,
    this.mainAxisSpacing = 16.0,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return DashboardSection(
      title: title,
      subtitle: subtitle,
      onSeeAll: onSeeAll,
      seeAllText: seeAllText,
      padding: padding,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: childAspectRatio,
            crossAxisSpacing: crossAxisSpacing.w,
            mainAxisSpacing: mainAxisSpacing.h,
          ),
          itemCount: children.length,
          itemBuilder: (context, index) => children[index],
        ),
      ),
    );
  }
}

/// Stats section widget for displaying statistics
class StatsSection extends StatelessWidget {
  final String title;
  final List<Widget> statCards;
  final EdgeInsetsGeometry? padding;

  const StatsSection({
    super.key,
    required this.title,
    required this.statCards,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return DashboardSection(
      title: title,
      padding: padding,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        child: Row(
          children: statCards
              .map((card) => Expanded(child: card))
              .expand((widget) => [widget, Gap(12.w)])
              .toList()
            ..removeLast(), // Remove last gap
        ),
      ),
    );
  }
}

/// Action section widget for action buttons
class ActionSection extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget> actionButtons;
  final int crossAxisCount;
  final EdgeInsetsGeometry? padding;

  const ActionSection({
    super.key,
    required this.title,
    this.subtitle,
    required this.actionButtons,
    this.crossAxisCount = 2,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return DashboardSection(
      title: title,
      subtitle: subtitle,
      padding: padding,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 1.2,
            crossAxisSpacing: 12.w,
            mainAxisSpacing: 12.h,
          ),
          itemCount: actionButtons.length,
          itemBuilder: (context, index) => actionButtons[index],
        ),
      ),
    );
  }
}

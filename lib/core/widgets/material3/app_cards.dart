import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../theming/colors.dart';
import '../../../theming/typography.dart';

/// Material 3 Card Components for PlayAround App
/// Standardized card system with consistent styling and elevation

enum CardVariant { elevated, filled, outlined }

enum CardSize { small, medium, large }

/// Base App Card Component
class AppCard extends StatelessWidget {
  final Widget child;
  final CardVariant variant;
  final CardSize size;
  final VoidCallback? onTap;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final Color? backgroundColor;
  final double? elevation;
  final BorderRadius? borderRadius;

  const AppCard({
    super.key,
    required this.child,
    this.variant = CardVariant.elevated,
    this.size = CardSize.medium,
    this.onTap,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.elevation,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final cardPadding = padding ?? _getDefaultPadding();
    final cardMargin = margin ?? _getDefaultMargin();
    final cardBorderRadius = borderRadius ?? _getDefaultBorderRadius();

    Widget cardContent = Container(
      padding: cardPadding,
      child: child,
    );

    switch (variant) {
      case CardVariant.elevated:
        return Container(
          margin: cardMargin,
          child: Card(
            elevation: elevation ?? _getDefaultElevation(),
            surfaceTintColor: ColorsManager.surfaceTint,
            color: backgroundColor ?? ColorsManager.surface,
            shape: RoundedRectangleBorder(
              borderRadius: cardBorderRadius,
            ),
            child: onTap != null
                ? InkWell(
                    onTap: onTap,
                    borderRadius: cardBorderRadius,
                    child: cardContent,
                  )
                : cardContent,
          ),
        );

      case CardVariant.filled:
        return Container(
          margin: cardMargin,
          decoration: BoxDecoration(
            color: backgroundColor ?? ColorsManager.surfaceVariant,
            borderRadius: cardBorderRadius,
          ),
          child: onTap != null
              ? InkWell(
                  onTap: onTap,
                  borderRadius: cardBorderRadius,
                  child: cardContent,
                )
              : cardContent,
        );

      case CardVariant.outlined:
        return Container(
          margin: cardMargin,
          decoration: BoxDecoration(
            color: backgroundColor ?? ColorsManager.surface,
            borderRadius: cardBorderRadius,
            border: Border.all(
              color: ColorsManager.outline,
              width: 1,
            ),
          ),
          child: onTap != null
              ? InkWell(
                  onTap: onTap,
                  borderRadius: cardBorderRadius,
                  child: cardContent,
                )
              : cardContent,
        );
    }
  }

  EdgeInsets _getDefaultPadding() {
    switch (size) {
      case CardSize.small:
        return EdgeInsets.all(12.w);
      case CardSize.medium:
        return EdgeInsets.all(16.w);
      case CardSize.large:
        return EdgeInsets.all(20.w);
    }
  }

  EdgeInsets _getDefaultMargin() {
    switch (size) {
      case CardSize.small:
        return EdgeInsets.all(4.w);
      case CardSize.medium:
        return EdgeInsets.all(8.w);
      case CardSize.large:
        return EdgeInsets.all(12.w);
    }
  }

  BorderRadius _getDefaultBorderRadius() {
    switch (size) {
      case CardSize.small:
        return BorderRadius.circular(8.r);
      case CardSize.medium:
        return BorderRadius.circular(12.r);
      case CardSize.large:
        return BorderRadius.circular(16.r);
    }
  }

  double _getDefaultElevation() {
    switch (size) {
      case CardSize.small:
        return 1;
      case CardSize.medium:
        return 2;
      case CardSize.large:
        return 3;
    }
  }
}

/// Sports Statistics Card
class StatsCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color? iconColor;
  final String? subtitle;
  final VoidCallback? onTap;
  final CardVariant variant;

  const StatsCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.iconColor,
    this.subtitle,
    this.onTap,
    this.variant = CardVariant.elevated,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      variant: variant,
      size: CardSize.medium,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: (iconColor ?? ColorsManager.primary)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(
                  icon,
                  color: iconColor ?? ColorsManager.primary,
                  size: 20.w,
                ),
              ),
              const Spacer(),
              if (onTap != null)
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16.w,
                  color: ColorsManager.onSurfaceVariant,
                ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            value,
            style: AppTypography.scoreText,
          ),
          SizedBox(height: 4.h),
          Text(
            title,
            style: AppTypography.bodyMedium.copyWith(
              color: ColorsManager.onSurfaceVariant,
            ),
          ),
          if (subtitle != null) ...[
            SizedBox(height: 2.h),
            Text(
              subtitle!,
              style: AppTypography.bodySmall.copyWith(
                color: ColorsManager.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Player/Coach Profile Card
class ProfileCard extends StatelessWidget {
  final String name;
  final String? subtitle;
  final String? imageUrl;
  final Widget? avatar;
  final List<Widget>? actions;
  final VoidCallback? onTap;
  final CardVariant variant;

  const ProfileCard({
    super.key,
    required this.name,
    this.subtitle,
    this.imageUrl,
    this.avatar,
    this.actions,
    this.onTap,
    this.variant = CardVariant.elevated,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      variant: variant,
      size: CardSize.medium,
      onTap: onTap,
      child: Row(
        children: [
          // Avatar
          avatar ??
              CircleAvatar(
                radius: 24.r,
                backgroundColor: ColorsManager.primaryContainer,
                backgroundImage: (imageUrl != null && imageUrl!.isNotEmpty)
                    ? NetworkImage(imageUrl!)
                    : null,
                child: (imageUrl == null || imageUrl!.isEmpty)
                    ? Icon(
                        Icons.person,
                        color: ColorsManager.onPrimaryContainer,
                        size: 24.w,
                      )
                    : null,
              ),
          SizedBox(width: 12.w),

          // Name and subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  style: AppTypography.playerName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null) ...[
                  SizedBox(height: 2.h),
                  Text(
                    subtitle!,
                    style: AppTypography.bodySmall.copyWith(
                      color: ColorsManager.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),

          // Actions
          if (actions != null) ...[
            SizedBox(width: 8.w),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: actions!,
            ),
          ],
        ],
      ),
    );
  }
}

/// Action Card with Icon and Text
class ActionCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Color? iconColor;
  final Color? backgroundColor;
  final VoidCallback? onTap;
  final CardVariant variant;
  final bool showArrow;

  const ActionCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.icon,
    this.iconColor,
    this.backgroundColor,
    this.onTap,
    this.variant = CardVariant.elevated,
    this.showArrow = true,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      variant: variant,
      size: CardSize.medium,
      onTap: onTap,
      backgroundColor: backgroundColor,
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color:
                  (iconColor ?? ColorsManager.primary).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              icon,
              color: iconColor ?? ColorsManager.primary,
              size: 24.w,
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: AppTypography.titleMedium,
                ),
                if (subtitle != null) ...[
                  SizedBox(height: 2.h),
                  Text(
                    subtitle!,
                    style: AppTypography.bodySmall.copyWith(
                      color: ColorsManager.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (showArrow && onTap != null) ...[
            SizedBox(width: 8.w),
            Icon(
              Icons.arrow_forward_ios,
              size: 16.w,
              color: ColorsManager.onSurfaceVariant,
            ),
          ],
        ],
      ),
    );
  }
}

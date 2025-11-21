import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../theming/colors.dart';
import '../../../theming/typography.dart';

/// Material 3 Chip and Badge Components for PlayAround App
/// Standardized chip system with consistent styling and accessibility

enum ChipVariant { assist, filter, input, suggestion }

enum ChipSize { small, medium, large }

enum BadgeVariant { primary, secondary, success, warning, error, info }

/// Base App Chip Component
class AppChip extends StatelessWidget {
  final String label;
  final Widget? avatar;
  final Widget? deleteIcon;
  final VoidCallback? onPressed;
  final VoidCallback? onDeleted;
  final bool selected;
  final ChipVariant variant;
  final ChipSize size;
  final Color? backgroundColor;
  final Color? selectedColor;
  final Color? labelColor;

  const AppChip({
    super.key,
    required this.label,
    this.avatar,
    this.deleteIcon,
    this.onPressed,
    this.onDeleted,
    this.selected = false,
    this.variant = ChipVariant.assist,
    this.size = ChipSize.medium,
    this.backgroundColor,
    this.selectedColor,
    this.labelColor,
  });

  @override
  Widget build(BuildContext context) {
    switch (variant) {
      case ChipVariant.assist:
        return _buildAssistChip();
      case ChipVariant.filter:
        return _buildFilterChip();
      case ChipVariant.input:
        return _buildInputChip();
      case ChipVariant.suggestion:
        return _buildSuggestionChip();
    }
  }

  Widget _buildAssistChip() {
    return ActionChip(
      label: Text(label),
      avatar: avatar,
      onPressed: onPressed,
      backgroundColor: backgroundColor ?? ColorsManager.surfaceVariant,
      labelStyle: _getLabelStyle(),
      shape: _getChipShape(),
      padding: _getChipPadding(),
      side: const BorderSide(
        color: ColorsManager.outline,
        width: 1,
      ),
    );
  }

  Widget _buildFilterChip() {
    return FilterChip(
      label: Text(label),
      avatar: avatar,
      onSelected: onPressed != null ? (_) => onPressed!() : null,
      selected: selected,
      backgroundColor: backgroundColor ?? ColorsManager.surfaceVariant,
      selectedColor: selectedColor ?? ColorsManager.secondaryContainer,
      labelStyle: _getLabelStyle(),
      shape: _getChipShape(),
      padding: _getChipPadding(),
      side: BorderSide(
        color: selected ? ColorsManager.secondary : ColorsManager.outline,
        width: 1,
      ),
    );
  }

  Widget _buildInputChip() {
    return InputChip(
      label: Text(label),
      avatar: avatar,
      deleteIcon: deleteIcon,
      onPressed: onPressed,
      onDeleted: onDeleted,
      backgroundColor: backgroundColor ?? ColorsManager.surfaceVariant,
      labelStyle: _getLabelStyle(),
      shape: _getChipShape(),
      padding: _getChipPadding(),
      side: const BorderSide(
        color: ColorsManager.outline,
        width: 1,
      ),
    );
  }

  Widget _buildSuggestionChip() {
    return ActionChip(
      label: Text(label),
      avatar: avatar,
      onPressed: onPressed,
      backgroundColor: backgroundColor ?? ColorsManager.primaryContainer,
      labelStyle: _getLabelStyle().copyWith(
        color: ColorsManager.onPrimaryContainer,
      ),
      shape: _getChipShape(),
      padding: _getChipPadding(),
      side: BorderSide.none,
    );
  }

  TextStyle _getLabelStyle() {
    final baseStyle = _getBaseTextStyle();
    return baseStyle.copyWith(
      color: labelColor ?? ColorsManager.onSurfaceVariant,
    );
  }

  TextStyle _getBaseTextStyle() {
    switch (size) {
      case ChipSize.small:
        return AppTypography.labelSmall;
      case ChipSize.medium:
        return AppTypography.labelMedium;
      case ChipSize.large:
        return AppTypography.labelLarge;
    }
  }

  OutlinedBorder _getChipShape() {
    final radius = _getBorderRadius();
    return RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
    );
  }

  double _getBorderRadius() {
    switch (size) {
      case ChipSize.small:
        return 16.r;
      case ChipSize.medium:
        return 20.r;
      case ChipSize.large:
        return 24.r;
    }
  }

  EdgeInsets _getChipPadding() {
    switch (size) {
      case ChipSize.small:
        return EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h);
      case ChipSize.medium:
        return EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h);
      case ChipSize.large:
        return EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h);
    }
  }
}

/// Skill Level Chip
class SkillLevelChip extends StatelessWidget {
  final String skillLevel;
  final ChipSize size;
  final VoidCallback? onPressed;

  const SkillLevelChip({
    super.key,
    required this.skillLevel,
    this.size = ChipSize.medium,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getSkillLevelColor();

    return AppChip(
      label: skillLevel,
      variant: ChipVariant.assist,
      size: size,
      onPressed: onPressed,
      backgroundColor: color.withValues(alpha: 0.1),
      labelColor: color,
    );
  }

  Color _getSkillLevelColor() {
    switch (skillLevel.toLowerCase()) {
      case 'beginner':
        return ColorsManager.beginnerColor;
      case 'intermediate':
        return ColorsManager.intermediateColor;
      case 'advanced':
        return ColorsManager.advancedColor;
      case 'expert':
        return ColorsManager.expertColor;
      default:
        return ColorsManager.primary;
    }
  }
}

/// Sport Type Chip
class SportTypeChip extends StatelessWidget {
  final String sportType;
  final bool selected;
  final ChipSize size;
  final VoidCallback? onPressed;

  const SportTypeChip({
    super.key,
    required this.sportType,
    this.selected = false,
    this.size = ChipSize.medium,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AppChip(
      label: sportType,
      variant: ChipVariant.filter,
      size: size,
      selected: selected,
      onPressed: onPressed,
      avatar: Icon(
        _getSportIcon(),
        size: _getIconSize(),
        color: selected
            ? ColorsManager.onSecondaryContainer
            : ColorsManager.onSurfaceVariant,
      ),
    );
  }

  IconData _getSportIcon() {
    switch (sportType.toLowerCase()) {
      case 'football':
      case 'soccer':
        return Icons.sports_soccer;
      case 'basketball':
        return Icons.sports_basketball;
      case 'tennis':
        return Icons.sports_tennis;
      case 'cricket':
        return Icons.sports_cricket;
      case 'volleyball':
        return Icons.sports_volleyball;
      case 'badminton':
        return Icons.sports_tennis; // Using tennis icon as placeholder
      default:
        return Icons.sports;
    }
  }

  double _getIconSize() {
    switch (size) {
      case ChipSize.small:
        return 16.w;
      case ChipSize.medium:
        return 18.w;
      case ChipSize.large:
        return 20.w;
    }
  }
}

/// Badge Component
class AppBadge extends StatelessWidget {
  final String label;
  final BadgeVariant variant;
  final Widget? child;
  final bool showBadge;

  const AppBadge({
    super.key,
    required this.label,
    this.variant = BadgeVariant.primary,
    this.child,
    this.showBadge = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!showBadge) {
      return child ?? const SizedBox.shrink();
    }

    if (child != null) {
      return Badge(
        label: Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: _getTextColor(),
          ),
        ),
        backgroundColor: _getBackgroundColor(),
        child: child,
      );
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: _getBackgroundColor(),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Text(
        label,
        style: AppTypography.labelSmall.copyWith(
          color: _getTextColor(),
        ),
      ),
    );
  }

  Color _getBackgroundColor() {
    switch (variant) {
      case BadgeVariant.primary:
        return ColorsManager.primary;
      case BadgeVariant.secondary:
        return ColorsManager.secondary;
      case BadgeVariant.success:
        return ColorsManager.success;
      case BadgeVariant.warning:
        return ColorsManager.warning;
      case BadgeVariant.error:
        return ColorsManager.error;
      case BadgeVariant.info:
        return ColorsManager.info;
    }
  }

  Color _getTextColor() {
    switch (variant) {
      case BadgeVariant.primary:
        return ColorsManager.onPrimary;
      case BadgeVariant.secondary:
        return ColorsManager.onSecondary;
      case BadgeVariant.success:
      case BadgeVariant.warning:
      case BadgeVariant.error:
      case BadgeVariant.info:
        return Colors.white;
    }
  }
}

/// Notification Badge
class NotificationBadge extends StatelessWidget {
  final int count;
  final Widget child;
  final bool showZero;

  const NotificationBadge({
    super.key,
    required this.count,
    required this.child,
    this.showZero = false,
  });

  @override
  Widget build(BuildContext context) {
    if (count == 0 && !showZero) {
      return child;
    }

    return Badge(
      label: Text(
        count > 99 ? '99+' : count.toString(),
        style: AppTypography.labelSmall.copyWith(
          color: Colors.white,
        ),
      ),
      backgroundColor: ColorsManager.error,
      child: child,
    );
  }
}

/// Status Badge
class StatusBadge extends StatelessWidget {
  final String status;
  final BadgeVariant? variant;

  const StatusBadge({
    super.key,
    required this.status,
    this.variant,
  });

  @override
  Widget build(BuildContext context) {
    final badgeVariant = variant ?? _getVariantFromStatus();

    return AppBadge(
      label: status,
      variant: badgeVariant,
    );
  }

  BadgeVariant _getVariantFromStatus() {
    switch (status.toLowerCase()) {
      case 'active':
      case 'confirmed':
      case 'completed':
        return BadgeVariant.success;
      case 'pending':
      case 'waiting':
        return BadgeVariant.warning;
      case 'cancelled':
      case 'rejected':
      case 'failed':
        return BadgeVariant.error;
      case 'draft':
      case 'scheduled':
        return BadgeVariant.info;
      default:
        return BadgeVariant.primary;
    }
  }
}

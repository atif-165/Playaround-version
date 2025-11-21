import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../theming/colors.dart';
import '../../../theming/typography.dart';

/// Material 3 Button Components for PlayAround App
/// Standardized button system with consistent styling and accessibility

enum ButtonSize { small, medium, large }

enum ButtonVariant { primary, secondary, tertiary, success, warning, error }

/// Primary Filled Button - Main action button
class AppFilledButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonSize size;
  final ButtonVariant variant;
  final Widget? icon;
  final bool isLoading;
  final bool fullWidth;

  const AppFilledButton({
    super.key,
    required this.text,
    this.onPressed,
    this.size = ButtonSize.medium,
    this.variant = ButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final buttonStyle = _getButtonStyle();
    final textStyle = _getTextStyle();
    final padding = _getPadding();

    Widget buttonChild = isLoading
        ? SizedBox(
            height: _getIconSize(),
            width: _getIconSize(),
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                _getTextColor(),
              ),
            ),
          )
        : Row(
            mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                icon!,
                SizedBox(width: 8.w),
              ],
              Flexible(
                child: Text(
                  text,
                  style: textStyle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                ),
              ),
            ],
          );

    return SizedBox(
      width: fullWidth ? double.infinity : null,
      child: FilledButton(
        onPressed: isLoading ? null : onPressed,
        style: buttonStyle.copyWith(
          padding: WidgetStateProperty.all(padding),
        ),
        child: buttonChild,
      ),
    );
  }

  ButtonStyle _getButtonStyle() {
    final backgroundColor = _getBackgroundColor();
    final foregroundColor = _getTextColor();

    return FilledButton.styleFrom(
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      elevation: 1,
    );
  }

  Color _getBackgroundColor() {
    switch (variant) {
      case ButtonVariant.primary:
        return ColorsManager.primary;
      case ButtonVariant.secondary:
        return ColorsManager.secondary;
      case ButtonVariant.tertiary:
        return ColorsManager.tertiary;
      case ButtonVariant.success:
        return ColorsManager.success;
      case ButtonVariant.warning:
        return ColorsManager.warning;
      case ButtonVariant.error:
        return ColorsManager.error;
    }
  }

  Color _getTextColor() {
    switch (variant) {
      case ButtonVariant.primary:
        return ColorsManager.onPrimary;
      case ButtonVariant.secondary:
        return ColorsManager.onSecondary;
      case ButtonVariant.tertiary:
        return ColorsManager.onTertiary;
      case ButtonVariant.success:
      case ButtonVariant.warning:
      case ButtonVariant.error:
        return Colors.white;
    }
  }

  TextStyle _getTextStyle() {
    switch (size) {
      case ButtonSize.small:
        return AppTypography.buttonSmall.copyWith(color: _getTextColor());
      case ButtonSize.medium:
        return AppTypography.buttonMedium.copyWith(color: _getTextColor());
      case ButtonSize.large:
        return AppTypography.buttonLarge.copyWith(color: _getTextColor());
    }
  }

  EdgeInsets _getPadding() {
    switch (size) {
      case ButtonSize.small:
        return EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h);
      case ButtonSize.medium:
        return EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h);
      case ButtonSize.large:
        return EdgeInsets.symmetric(horizontal: 32.w, vertical: 16.h);
    }
  }

  double _getIconSize() {
    switch (size) {
      case ButtonSize.small:
        return 16.w;
      case ButtonSize.medium:
        return 20.w;
      case ButtonSize.large:
        return 24.w;
    }
  }
}

/// Outlined Button - Secondary action button
class AppOutlinedButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonSize size;
  final ButtonVariant variant;
  final Widget? icon;
  final bool isLoading;
  final bool fullWidth;

  const AppOutlinedButton({
    super.key,
    required this.text,
    this.onPressed,
    this.size = ButtonSize.medium,
    this.variant = ButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final buttonStyle = _getButtonStyle();
    final textStyle = _getTextStyle();
    final padding = _getPadding();

    Widget buttonChild = isLoading
        ? SizedBox(
            height: _getIconSize(),
            width: _getIconSize(),
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                _getTextColor(),
              ),
            ),
          )
        : Row(
            mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                icon!,
                SizedBox(width: 8.w),
              ],
              Flexible(
                child: Text(
                  text,
                  style: textStyle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                ),
              ),
            ],
          );

    return SizedBox(
      width: fullWidth ? double.infinity : null,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: buttonStyle.copyWith(
          padding: WidgetStateProperty.all(padding),
        ),
        child: buttonChild,
      ),
    );
  }

  ButtonStyle _getButtonStyle() {
    final borderColor = _getBorderColor();
    final foregroundColor = _getTextColor();

    return OutlinedButton.styleFrom(
      foregroundColor: foregroundColor,
      side: BorderSide(color: borderColor, width: 1.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
    );
  }

  Color _getBorderColor() {
    switch (variant) {
      case ButtonVariant.primary:
        return ColorsManager.primary;
      case ButtonVariant.secondary:
        return ColorsManager.secondary;
      case ButtonVariant.tertiary:
        return ColorsManager.tertiary;
      case ButtonVariant.success:
        return ColorsManager.success;
      case ButtonVariant.warning:
        return ColorsManager.warning;
      case ButtonVariant.error:
        return ColorsManager.error;
    }
  }

  Color _getTextColor() {
    return _getBorderColor();
  }

  TextStyle _getTextStyle() {
    switch (size) {
      case ButtonSize.small:
        return AppTypography.buttonSmall.copyWith(color: _getTextColor());
      case ButtonSize.medium:
        return AppTypography.buttonMedium.copyWith(color: _getTextColor());
      case ButtonSize.large:
        return AppTypography.buttonLarge.copyWith(color: _getTextColor());
    }
  }

  EdgeInsets _getPadding() {
    switch (size) {
      case ButtonSize.small:
        return EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h);
      case ButtonSize.medium:
        return EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h);
      case ButtonSize.large:
        return EdgeInsets.symmetric(horizontal: 32.w, vertical: 16.h);
    }
  }

  double _getIconSize() {
    switch (size) {
      case ButtonSize.small:
        return 16.w;
      case ButtonSize.medium:
        return 20.w;
      case ButtonSize.large:
        return 24.w;
    }
  }
}

/// Text Button - Tertiary action button
class AppTextButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonSize size;
  final ButtonVariant variant;
  final Widget? icon;
  final bool isLoading;

  const AppTextButton({
    super.key,
    required this.text,
    this.onPressed,
    this.size = ButtonSize.medium,
    this.variant = ButtonVariant.primary,
    this.icon,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final buttonStyle = _getButtonStyle();
    final textStyle = _getTextStyle();
    final padding = _getPadding();

    Widget buttonChild = isLoading
        ? SizedBox(
            height: _getIconSize(),
            width: _getIconSize(),
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                _getTextColor(),
              ),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                icon!,
                SizedBox(width: 8.w),
              ],
              Flexible(
                child: Text(
                  text,
                  style: textStyle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                ),
              ),
            ],
          );

    return TextButton(
      onPressed: isLoading ? null : onPressed,
      style: buttonStyle.copyWith(
        padding: WidgetStateProperty.all(padding),
      ),
      child: buttonChild,
    );
  }

  ButtonStyle _getButtonStyle() {
    final foregroundColor = _getTextColor();

    return TextButton.styleFrom(
      foregroundColor: foregroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
    );
  }

  Color _getTextColor() {
    switch (variant) {
      case ButtonVariant.primary:
        return ColorsManager.primary;
      case ButtonVariant.secondary:
        return ColorsManager.secondary;
      case ButtonVariant.tertiary:
        return ColorsManager.tertiary;
      case ButtonVariant.success:
        return ColorsManager.success;
      case ButtonVariant.warning:
        return ColorsManager.warning;
      case ButtonVariant.error:
        return ColorsManager.error;
    }
  }

  TextStyle _getTextStyle() {
    switch (size) {
      case ButtonSize.small:
        return AppTypography.buttonSmall.copyWith(color: _getTextColor());
      case ButtonSize.medium:
        return AppTypography.buttonMedium.copyWith(color: _getTextColor());
      case ButtonSize.large:
        return AppTypography.buttonLarge.copyWith(color: _getTextColor());
    }
  }

  EdgeInsets _getPadding() {
    switch (size) {
      case ButtonSize.small:
        return EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h);
      case ButtonSize.medium:
        return EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h);
      case ButtonSize.large:
        return EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h);
    }
  }

  double _getIconSize() {
    switch (size) {
      case ButtonSize.small:
        return 16.w;
      case ButtonSize.medium:
        return 20.w;
      case ButtonSize.large:
        return 24.w;
    }
  }
}

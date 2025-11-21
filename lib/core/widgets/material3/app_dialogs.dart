import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../theming/colors.dart';
import '../../../theming/typography.dart';
import 'app_buttons.dart';

/// Material 3 Dialog Components for PlayAround App
/// Standardized dialog system with consistent styling and accessibility

/// Confirmation Dialog
class AppConfirmationDialog extends StatelessWidget {
  final String title;
  final String content;
  final String? confirmText;
  final String? cancelText;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final ButtonVariant confirmVariant;
  final IconData? icon;
  final Color? iconColor;

  const AppConfirmationDialog({
    super.key,
    required this.title,
    required this.content,
    this.confirmText,
    this.cancelText,
    this.onConfirm,
    this.onCancel,
    this.confirmVariant = ButtonVariant.primary,
    this.icon,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: ColorsManager.surface,
      surfaceTintColor: ColorsManager.surfaceTint,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
      ),
      title: Row(
        children: [
          if (icon != null) ...[
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color:
                    (iconColor ?? ColorsManager.primary).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(
                icon!,
                color: iconColor ?? ColorsManager.primary,
                size: 24.w,
              ),
            ),
            SizedBox(width: 12.w),
          ],
          Expanded(
            child: Text(
              title,
              style: AppTypography.headlineSmall,
            ),
          ),
        ],
      ),
      content: Text(
        content,
        style: AppTypography.bodyMedium.copyWith(
          color: ColorsManager.onSurfaceVariant,
        ),
      ),
      actions: [
        AppTextButton(
          text: cancelText ?? 'Cancel',
          onPressed: onCancel ?? () => Navigator.of(context).pop(false),
          variant: ButtonVariant.secondary,
        ),
        SizedBox(width: 8.w),
        AppFilledButton(
          text: confirmText ?? 'Confirm',
          onPressed: onConfirm ?? () => Navigator.of(context).pop(true),
          variant: confirmVariant,
        ),
      ],
    );
  }

  /// Show confirmation dialog
  static Future<bool?> show({
    required BuildContext context,
    required String title,
    required String content,
    String? confirmText,
    String? cancelText,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
    ButtonVariant confirmVariant = ButtonVariant.primary,
    IconData? icon,
    Color? iconColor,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AppConfirmationDialog(
        title: title,
        content: content,
        confirmText: confirmText,
        cancelText: cancelText,
        onConfirm: onConfirm,
        onCancel: onCancel,
        confirmVariant: confirmVariant,
        icon: icon,
        iconColor: iconColor,
      ),
    );
  }
}

/// Loading Dialog
class AppLoadingDialog extends StatelessWidget {
  final String? message;
  final bool canDismiss;

  const AppLoadingDialog({
    super.key,
    this.message,
    this.canDismiss = false,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: canDismiss,
      child: AlertDialog(
        backgroundColor: ColorsManager.surface,
        surfaceTintColor: ColorsManager.surfaceTint,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              color: ColorsManager.primary,
              strokeWidth: 3,
            ),
            if (message != null) ...[
              SizedBox(height: 16.h),
              Text(
                message!,
                style: AppTypography.bodyMedium.copyWith(
                  color: ColorsManager.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Show loading dialog
  static void show({
    required BuildContext context,
    String? message,
    bool canDismiss = false,
  }) {
    showDialog(
      context: context,
      barrierDismissible: canDismiss,
      builder: (context) => AppLoadingDialog(
        message: message,
        canDismiss: canDismiss,
      ),
    );
  }

  /// Hide loading dialog
  static void hide(BuildContext context) {
    Navigator.of(context).pop();
  }
}

/// Success Dialog
class AppSuccessDialog extends StatelessWidget {
  final String title;
  final String content;
  final String? buttonText;
  final VoidCallback? onPressed;

  const AppSuccessDialog({
    super.key,
    required this.title,
    required this.content,
    this.buttonText,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: ColorsManager.surface,
      surfaceTintColor: ColorsManager.surfaceTint,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
      ),
      title: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: ColorsManager.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(
              Icons.check_circle,
              color: ColorsManager.success,
              size: 24.w,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              title,
              style: AppTypography.headlineSmall,
            ),
          ),
        ],
      ),
      content: Text(
        content,
        style: AppTypography.bodyMedium.copyWith(
          color: ColorsManager.onSurfaceVariant,
        ),
      ),
      actions: [
        AppFilledButton(
          text: buttonText ?? 'OK',
          onPressed: onPressed ?? () => Navigator.of(context).pop(),
          variant: ButtonVariant.success,
        ),
      ],
    );
  }

  /// Show success dialog
  static Future<void> show({
    required BuildContext context,
    required String title,
    required String content,
    String? buttonText,
    VoidCallback? onPressed,
  }) {
    return showDialog(
      context: context,
      builder: (context) => AppSuccessDialog(
        title: title,
        content: content,
        buttonText: buttonText,
        onPressed: onPressed,
      ),
    );
  }
}

/// Error Dialog
class AppErrorDialog extends StatelessWidget {
  final String title;
  final String content;
  final String? buttonText;
  final VoidCallback? onPressed;

  const AppErrorDialog({
    super.key,
    required this.title,
    required this.content,
    this.buttonText,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: ColorsManager.surface,
      surfaceTintColor: ColorsManager.surfaceTint,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
      ),
      title: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: ColorsManager.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(
              Icons.error,
              color: ColorsManager.error,
              size: 24.w,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              title,
              style: AppTypography.headlineSmall,
            ),
          ),
        ],
      ),
      content: Text(
        content,
        style: AppTypography.bodyMedium.copyWith(
          color: ColorsManager.onSurfaceVariant,
        ),
      ),
      actions: [
        AppFilledButton(
          text: buttonText ?? 'OK',
          onPressed: onPressed ?? () => Navigator.of(context).pop(),
          variant: ButtonVariant.error,
        ),
      ],
    );
  }

  /// Show error dialog
  static Future<void> show({
    required BuildContext context,
    required String title,
    required String content,
    String? buttonText,
    VoidCallback? onPressed,
  }) {
    return showDialog(
      context: context,
      builder: (context) => AppErrorDialog(
        title: title,
        content: content,
        buttonText: buttonText,
        onPressed: onPressed,
      ),
    );
  }
}

/// Bottom Sheet Dialog
class AppBottomSheet extends StatelessWidget {
  final String? title;
  final Widget child;
  final bool showDragHandle;
  final double? height;
  final bool isScrollControlled;

  const AppBottomSheet({
    super.key,
    this.title,
    required this.child,
    this.showDragHandle = true,
    this.height,
    this.isScrollControlled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: ColorsManager.surface,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16.r),
          topRight: Radius.circular(16.r),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDragHandle) ...[
            SizedBox(height: 8.h),
            Container(
              width: 32.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: ColorsManager.onSurfaceVariant.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            SizedBox(height: 8.h),
          ],
          if (title != null) ...[
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title!,
                      style: AppTypography.headlineSmall,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.close,
                      color: ColorsManager.onSurfaceVariant,
                      size: 24.w,
                    ),
                  ),
                ],
              ),
            ),
            Divider(
              color: ColorsManager.outlineVariant,
              height: 1.h,
            ),
          ],
          Flexible(
            child: child,
          ),
        ],
      ),
    );
  }

  /// Show bottom sheet
  static Future<T?> show<T>({
    required BuildContext context,
    String? title,
    required Widget child,
    bool showDragHandle = true,
    double? height,
    bool isScrollControlled = false,
    bool isDismissible = true,
    bool enableDrag = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      backgroundColor: Colors.transparent,
      builder: (context) => AppBottomSheet(
        title: title,
        showDragHandle: showDragHandle,
        height: height,
        isScrollControlled: isScrollControlled,
        child: child,
      ),
    );
  }
}

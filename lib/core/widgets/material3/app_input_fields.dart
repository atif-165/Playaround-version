import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../theming/colors.dart';
import '../../../theming/typography.dart';

/// Material 3 Input Field Components for PlayAround App
/// Standardized input system with consistent styling and validation

enum InputFieldVariant { outlined, filled }
enum InputFieldSize { small, medium, large }

/// Base App Text Field Component
class AppTextField extends StatefulWidget {
  final String? labelText;
  final String? hintText;
  final String? helperText;
  final String? errorText;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final VoidCallback? onTap;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final bool enabled;
  final bool readOnly;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final String? prefixText;
  final String? suffixText;
  final InputFieldVariant variant;
  final InputFieldSize size;
  final List<TextInputFormatter>? inputFormatters;
  final FocusNode? focusNode;
  final bool autofocus;
  final TextCapitalization textCapitalization;

  const AppTextField({
    super.key,
    this.labelText,
    this.hintText,
    this.helperText,
    this.errorText,
    this.controller,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.enabled = true,
    this.readOnly = false,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.prefixIcon,
    this.suffixIcon,
    this.prefixText,
    this.suffixText,
    this.variant = InputFieldVariant.outlined,
    this.size = InputFieldSize.medium,
    this.inputFormatters,
    this.focusNode,
    this.autofocus = false,
    this.textCapitalization = TextCapitalization.none,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _obscureText;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        TextFormField(
          controller: widget.controller,
          validator: widget.validator,
          onChanged: widget.onChanged,
          onFieldSubmitted: widget.onSubmitted,
          onTap: widget.onTap,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          obscureText: _obscureText,
          enabled: widget.enabled,
          readOnly: widget.readOnly,
          maxLines: widget.obscureText ? 1 : widget.maxLines,
          minLines: widget.minLines,
          maxLength: widget.maxLength,
          inputFormatters: widget.inputFormatters,
          focusNode: widget.focusNode,
          autofocus: widget.autofocus,
          textCapitalization: widget.textCapitalization,
          style: _getTextStyle(),
          decoration: _getInputDecoration(),
        ),
        if (widget.helperText != null && widget.errorText == null) ...[
          SizedBox(height: 4.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Text(
              widget.helperText!,
              style: AppTypography.bodySmall.copyWith(
                color: ColorsManager.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ],
    );
  }

  InputDecoration _getInputDecoration() {
    final borderRadius = _getBorderRadius();
    final contentPadding = _getContentPadding();

    Widget? suffixIcon = widget.suffixIcon;
    if (widget.obscureText) {
      suffixIcon = IconButton(
        icon: Icon(
          _obscureText ? Icons.visibility : Icons.visibility_off,
          color: ColorsManager.onSurfaceVariant,
          size: _getIconSize(),
        ),
        onPressed: () {
          setState(() {
            _obscureText = !_obscureText;
          });
        },
      );
    }

    switch (widget.variant) {
      case InputFieldVariant.outlined:
        return InputDecoration(
          labelText: widget.labelText,
          hintText: widget.hintText,
          errorText: widget.errorText,
          prefixIcon: widget.prefixIcon,
          suffixIcon: suffixIcon,
          prefixText: widget.prefixText,
          suffixText: widget.suffixText,
          border: OutlineInputBorder(
            borderRadius: borderRadius,
            borderSide: const BorderSide(color: ColorsManager.outline),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: borderRadius,
            borderSide: const BorderSide(color: ColorsManager.outline),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: borderRadius,
            borderSide: const BorderSide(color: ColorsManager.primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: borderRadius,
            borderSide: const BorderSide(color: ColorsManager.error),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: borderRadius,
            borderSide: const BorderSide(color: ColorsManager.error, width: 2),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: borderRadius,
            borderSide: BorderSide(color: ColorsManager.outline.withValues(alpha: 0.5)),
          ),
          contentPadding: contentPadding,
          labelStyle: _getLabelStyle(),
          hintStyle: _getHintStyle(),
          errorStyle: _getErrorStyle(),
          helperStyle: _getHelperStyle(),
        );

      case InputFieldVariant.filled:
        return InputDecoration(
          labelText: widget.labelText,
          hintText: widget.hintText,
          errorText: widget.errorText,
          prefixIcon: widget.prefixIcon,
          suffixIcon: suffixIcon,
          prefixText: widget.prefixText,
          suffixText: widget.suffixText,
          filled: true,
          fillColor: ColorsManager.surfaceVariant.withValues(alpha: 0.3),
          border: OutlineInputBorder(
            borderRadius: borderRadius,
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: borderRadius,
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: borderRadius,
            borderSide: const BorderSide(color: ColorsManager.primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: borderRadius,
            borderSide: const BorderSide(color: ColorsManager.error),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: borderRadius,
            borderSide: const BorderSide(color: ColorsManager.error, width: 2),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: borderRadius,
            borderSide: BorderSide.none,
          ),
          contentPadding: contentPadding,
          labelStyle: _getLabelStyle(),
          hintStyle: _getHintStyle(),
          errorStyle: _getErrorStyle(),
          helperStyle: _getHelperStyle(),
        );
    }
  }

  BorderRadius _getBorderRadius() {
    switch (widget.size) {
      case InputFieldSize.small:
        return BorderRadius.circular(8.r);
      case InputFieldSize.medium:
        return BorderRadius.circular(12.r);
      case InputFieldSize.large:
        return BorderRadius.circular(16.r);
    }
  }

  EdgeInsets _getContentPadding() {
    switch (widget.size) {
      case InputFieldSize.small:
        return EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h);
      case InputFieldSize.medium:
        return EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h);
      case InputFieldSize.large:
        return EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h);
    }
  }

  double _getIconSize() {
    switch (widget.size) {
      case InputFieldSize.small:
        return 20.w;
      case InputFieldSize.medium:
        return 24.w;
      case InputFieldSize.large:
        return 28.w;
    }
  }

  TextStyle _getTextStyle() {
    switch (widget.size) {
      case InputFieldSize.small:
        return AppTypography.bodySmall;
      case InputFieldSize.medium:
        return AppTypography.bodyMedium;
      case InputFieldSize.large:
        return AppTypography.bodyLarge;
    }
  }

  TextStyle _getLabelStyle() {
    return _getTextStyle().copyWith(
      color: ColorsManager.onSurfaceVariant,
    );
  }

  TextStyle _getHintStyle() {
    return _getTextStyle().copyWith(
      color: ColorsManager.onSurfaceVariant.withValues(alpha: 0.7),
    );
  }

  TextStyle _getErrorStyle() {
    return AppTypography.bodySmall.copyWith(
      color: ColorsManager.error,
    );
  }

  TextStyle _getHelperStyle() {
    return AppTypography.bodySmall.copyWith(
      color: ColorsManager.onSurfaceVariant,
    );
  }
}

/// Search Field Component
class AppSearchField extends StatelessWidget {
  final String? hintText;
  final TextEditingController? controller;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final VoidCallback? onClear;
  final bool enabled;
  final InputFieldSize size;

  const AppSearchField({
    super.key,
    this.hintText,
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.enabled = true,
    this.size = InputFieldSize.medium,
  });

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: controller,
      hintText: hintText ?? 'Search...',
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      enabled: enabled,
      size: size,
      variant: InputFieldVariant.filled,
      prefixIcon: Icon(
        Icons.search,
        color: ColorsManager.onSurfaceVariant,
        size: _getIconSize(),
      ),
      suffixIcon: controller?.text.isNotEmpty == true
          ? IconButton(
              icon: Icon(
                Icons.clear,
                color: ColorsManager.onSurfaceVariant,
                size: _getIconSize(),
              ),
              onPressed: () {
                controller?.clear();
                onClear?.call();
              },
            )
          : null,
      keyboardType: TextInputType.text,
      textInputAction: TextInputAction.search,
    );
  }

  double _getIconSize() {
    switch (size) {
      case InputFieldSize.small:
        return 20.w;
      case InputFieldSize.medium:
        return 24.w;
      case InputFieldSize.large:
        return 28.w;
    }
  }
}

/// Dropdown Field Component
class AppDropdownField<T> extends StatelessWidget {
  final String? labelText;
  final String? hintText;
  final String? errorText;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final void Function(T?)? onChanged;
  final String? Function(T?)? validator;
  final bool enabled;
  final Widget? prefixIcon;
  final InputFieldSize size;

  const AppDropdownField({
    super.key,
    this.labelText,
    this.hintText,
    this.errorText,
    this.value,
    required this.items,
    this.onChanged,
    this.validator,
    this.enabled = true,
    this.prefixIcon,
    this.size = InputFieldSize.medium,
  });

  @override
  Widget build(BuildContext context) {
    final borderRadius = _getBorderRadius();
    final contentPadding = _getContentPadding();

    return DropdownButtonFormField<T>(
      value: value,
      items: items,
      onChanged: enabled ? onChanged : null,
      validator: validator,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        errorText: errorText,
        prefixIcon: prefixIcon,
        border: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: const BorderSide(color: ColorsManager.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: const BorderSide(color: ColorsManager.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: const BorderSide(color: ColorsManager.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: const BorderSide(color: ColorsManager.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: const BorderSide(color: ColorsManager.error, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: BorderSide(color: ColorsManager.outline.withValues(alpha: 0.5)),
        ),
        contentPadding: contentPadding,
        labelStyle: _getLabelStyle(),
        hintStyle: _getHintStyle(),
        errorStyle: _getErrorStyle(),
      ),
      style: _getTextStyle(),
      dropdownColor: ColorsManager.surface,
      icon: Icon(
        Icons.keyboard_arrow_down,
        color: ColorsManager.onSurfaceVariant,
        size: _getIconSize(),
      ),
    );
  }

  BorderRadius _getBorderRadius() {
    switch (size) {
      case InputFieldSize.small:
        return BorderRadius.circular(8.r);
      case InputFieldSize.medium:
        return BorderRadius.circular(12.r);
      case InputFieldSize.large:
        return BorderRadius.circular(16.r);
    }
  }

  EdgeInsets _getContentPadding() {
    switch (size) {
      case InputFieldSize.small:
        return EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h);
      case InputFieldSize.medium:
        return EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h);
      case InputFieldSize.large:
        return EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h);
    }
  }

  double _getIconSize() {
    switch (size) {
      case InputFieldSize.small:
        return 20.w;
      case InputFieldSize.medium:
        return 24.w;
      case InputFieldSize.large:
        return 28.w;
    }
  }

  TextStyle _getTextStyle() {
    switch (size) {
      case InputFieldSize.small:
        return AppTypography.bodySmall;
      case InputFieldSize.medium:
        return AppTypography.bodyMedium;
      case InputFieldSize.large:
        return AppTypography.bodyLarge;
    }
  }

  TextStyle _getLabelStyle() {
    return _getTextStyle().copyWith(
      color: ColorsManager.onSurfaceVariant,
    );
  }

  TextStyle _getHintStyle() {
    return _getTextStyle().copyWith(
      color: ColorsManager.onSurfaceVariant.withValues(alpha: 0.7),
    );
  }

  TextStyle _getErrorStyle() {
    return AppTypography.bodySmall.copyWith(
      color: ColorsManager.error,
    );
  }
}

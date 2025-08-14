import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import '../../theming/colors.dart';
import '../../theming/styles.dart';

/// Number input field widget for numeric values
class AppNumberField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final Function(String)? onChanged;
  final String? Function(String?)? validator;
  final bool isRequired;
  final int? minValue;
  final int? maxValue;
  final String? prefix;
  final String? suffix;
  final bool allowDecimals;
  final int? decimalPlaces;

  const AppNumberField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.onChanged,
    this.validator,
    this.isRequired = false,
    this.minValue,
    this.maxValue,
    this.prefix,
    this.suffix,
    this.allowDecimals = false,
    this.decimalPlaces = 2,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Row(
          children: [
            Text(
              label,
              style: TextStyles.font14DarkBlue500Weight,
            ),
            if (isRequired) ...[
              Gap(4.w),
              Text(
                '*',
                style: TextStyles.font14DarkBlue500Weight.copyWith(
                  color: ColorsManager.coralRed,
                ),
              ),
            ],
          ],
        ),
        Gap(8.h),

        // Number input field
        TextFormField(
          controller: controller,
          onChanged: onChanged,
          validator: validator,
          keyboardType: allowDecimals 
              ? const TextInputType.numberWithOptions(decimal: true)
              : TextInputType.number,
          inputFormatters: _buildInputFormatters(),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyles.font14Hint500Weight,
            prefixText: prefix,
            suffixText: suffix,
            isDense: true,
            filled: true,
            fillColor: ColorsManager.lightShadeOfGray,
            contentPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 17.h),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: ColorsManager.gray93Color,
                width: 1.3.w,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: ColorsManager.mainBlue,
                width: 1.3.w,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            errorBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: ColorsManager.coralRed,
                width: 1.3.w,
              ),
              borderRadius: BorderRadius.circular(16.0),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: ColorsManager.coralRed,
                width: 1.3.w,
              ),
              borderRadius: BorderRadius.circular(16.0),
            ),
          ),
          style: TextStyles.font14DarkBlue500Weight,
        ),

        // Helper text for range
        if (minValue != null || maxValue != null) ...[
          Gap(4.h),
          Text(
            _buildRangeText(),
            style: TextStyles.font11MediumLightShadeOfGray400Weight,
          ),
        ],
      ],
    );
  }

  List<TextInputFormatter> _buildInputFormatters() {
    final formatters = <TextInputFormatter>[];

    if (allowDecimals) {
      // Allow decimals with specified decimal places
      formatters.add(
        FilteringTextInputFormatter.allow(
          RegExp(r'^\d*\.?\d{0,' '${decimalPlaces ?? 2}' '}'),
        ),
      );
    } else {
      // Only allow integers
      formatters.add(FilteringTextInputFormatter.digitsOnly);
    }

    // Add range validation if specified
    if (minValue != null || maxValue != null) {
      formatters.add(_RangeTextInputFormatter(
        minValue: minValue,
        maxValue: maxValue,
        allowDecimals: allowDecimals,
      ));
    }

    return formatters;
  }

  String _buildRangeText() {
    if (minValue != null && maxValue != null) {
      return 'Range: $minValue - $maxValue';
    } else if (minValue != null) {
      return 'Minimum: $minValue';
    } else if (maxValue != null) {
      return 'Maximum: $maxValue';
    }
    return '';
  }
}

/// Custom text input formatter for range validation
class _RangeTextInputFormatter extends TextInputFormatter {
  final int? minValue;
  final int? maxValue;
  final bool allowDecimals;

  _RangeTextInputFormatter({
    this.minValue,
    this.maxValue,
    this.allowDecimals = false,
  });

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    final numericValue = allowDecimals 
        ? double.tryParse(newValue.text)
        : int.tryParse(newValue.text);

    if (numericValue == null) {
      return oldValue;
    }

    // Check minimum value
    if (minValue != null && numericValue < minValue!) {
      return oldValue;
    }

    // Check maximum value
    if (maxValue != null && numericValue > maxValue!) {
      return oldValue;
    }

    return newValue;
  }
}

/// Validator functions for number fields
class NumberFieldValidators {
  static String? validateAge(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your age';
    }

    final age = int.tryParse(value);
    if (age == null) {
      return 'Please enter a valid age';
    }

    if (age < 13 || age > 100) {
      return 'Age must be between 13 and 100';
    }

    return null;
  }

  static String? validateExperienceYears(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter years of experience';
    }

    final years = int.tryParse(value);
    if (years == null) {
      return 'Please enter a valid number';
    }

    if (years < 0 || years > 50) {
      return 'Experience must be between 0 and 50 years';
    }

    return null;
  }

  static String? validateHourlyRate(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your hourly rate';
    }

    final rate = double.tryParse(value);
    if (rate == null) {
      return 'Please enter a valid rate';
    }

    if (rate < 0 || rate > 1000) {
      return 'Rate must be between \$0 and \$1000';
    }

    return null;
  }

  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return 'Please enter $fieldName';
    }
    return null;
  }

  static String? validateRange(String? value, String fieldName, int min, int max) {
    if (value == null || value.isEmpty) {
      return 'Please enter $fieldName';
    }

    final number = int.tryParse(value);
    if (number == null) {
      return 'Please enter a valid number';
    }

    if (number < min || number > max) {
      return '$fieldName must be between $min and $max';
    }

    return null;
  }
}

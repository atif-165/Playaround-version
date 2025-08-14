import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import '../../theming/colors.dart';
import '../../theming/styles.dart';

/// Multi-select field widget for selecting multiple options from a list
class AppMultiSelectField extends StatefulWidget {
  final String label;
  final List<String> options;
  final List<String> selectedValues;
  final Function(List<String>) onChanged;
  final String? Function(List<String>?)? validator;
  final String? hint;
  final int maxSelections;
  final bool isRequired;

  const AppMultiSelectField({
    super.key,
    required this.label,
    required this.options,
    required this.selectedValues,
    required this.onChanged,
    this.validator,
    this.hint,
    this.maxSelections = 10,
    this.isRequired = false,
  });

  @override
  State<AppMultiSelectField> createState() => _AppMultiSelectFieldState();
}

class _AppMultiSelectFieldState extends State<AppMultiSelectField> {
  String? _errorText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Row(
          children: [
            Text(
              widget.label,
              style: TextStyles.font14DarkBlue500Weight,
            ),
            if (widget.isRequired) ...[
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

        // Selected items display
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: ColorsManager.lightShadeOfGray,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _errorText != null 
                  ? ColorsManager.coralRed 
                  : ColorsManager.gray93Color,
              width: 1.3.w,
            ),
          ),
          child: widget.selectedValues.isEmpty
              ? Text(
                  widget.hint ?? 'Tap to select ${widget.label.toLowerCase()}',
                  style: TextStyles.font14Hint500Weight,
                )
              : Wrap(
                  spacing: 8.w,
                  runSpacing: 8.h,
                  children: widget.selectedValues
                      .map((value) => _buildSelectedChip(value))
                      .toList(),
                ),
        ),

        // Error text
        if (_errorText != null) ...[
          Gap(4.h),
          Text(
            _errorText!,
            style: TextStyles.font12Grey400Weight.copyWith(
              color: ColorsManager.coralRed,
            ),
          ),
        ],

        Gap(8.h),

        // Options grid
        _buildOptionsGrid(),
      ],
    );
  }

  Widget _buildSelectedChip(String value) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: ColorsManager.mainBlue,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyles.font11DarkBlue500Weight.copyWith(
              color: Colors.white,
            ),
          ),
          Gap(4.w),
          GestureDetector(
            onTap: () => _removeSelection(value),
            child: Icon(
              Icons.close,
              size: 16.sp,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionsGrid() {
    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      children: widget.options.map((option) {
        final isSelected = widget.selectedValues.contains(option);
        final canSelect = widget.selectedValues.length < widget.maxSelections;
        
        return GestureDetector(
          onTap: () {
            if (isSelected) {
              _removeSelection(option);
            } else if (canSelect) {
              _addSelection(option);
            }
          },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: isSelected
                  ? ColorsManager.mainBlue.withValues(alpha: 0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected 
                    ? ColorsManager.mainBlue
                    : ColorsManager.gray76,
                width: 1.w,
              ),
            ),
            child: Text(
              option,
              style: TextStyles.font12Grey400Weight.copyWith(
                color: isSelected 
                    ? ColorsManager.mainBlue
                    : ColorsManager.darkBlue,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  void _addSelection(String value) {
    final newSelection = [...widget.selectedValues, value];
    widget.onChanged(newSelection);
    _validateSelection(newSelection);
  }

  void _removeSelection(String value) {
    final newSelection = widget.selectedValues.where((v) => v != value).toList();
    widget.onChanged(newSelection);
    _validateSelection(newSelection);
  }

  void _validateSelection(List<String> selection) {
    if (widget.validator != null) {
      setState(() {
        _errorText = widget.validator!(selection);
      });
    }
  }
}

/// Validator functions for multi-select fields
class MultiSelectValidators {
  static String? validateRequired(List<String>? values, String fieldName) {
    if (values == null || values.isEmpty) {
      return 'Please select at least one $fieldName';
    }
    return null;
  }

  static String? validateMinSelections(List<String>? values, int minCount, String fieldName) {
    if (values == null || values.length < minCount) {
      return 'Please select at least $minCount $fieldName';
    }
    return null;
  }

  static String? validateMaxSelections(List<String>? values, int maxCount, String fieldName) {
    if (values != null && values.length > maxCount) {
      return 'Please select no more than $maxCount $fieldName';
    }
    return null;
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import '../../models/models.dart';
import '../../theming/colors.dart';
import '../../theming/styles.dart';

/// Dropdown field widget following the app's design patterns
class AppDropdownField<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final Function(T?) onChanged;
  final String? Function(T?)? validator;
  final String? hint;
  final bool isRequired;
  final Widget? prefixIcon;

  const AppDropdownField({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.validator,
    this.hint,
    this.isRequired = false,
    this.prefixIcon,
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

        // Dropdown
        DropdownButtonFormField<T>(
          value: value,
          items: items,
          onChanged: onChanged,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyles.font14Hint500Weight,
            prefixIcon: prefixIcon,
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
          dropdownColor: ColorsManager.lightShadeOfGray,
          icon: Icon(
            Icons.keyboard_arrow_down,
            color: ColorsManager.gray,
            size: 24.sp,
          ),
        ),
      ],
    );
  }
}

/// Helper class for creating common dropdown items
class DropdownHelper {
  /// Create dropdown items for Gender enum
  static List<DropdownMenuItem<Gender>> genderItems() {
    return Gender.values.map((gender) {
      return DropdownMenuItem<Gender>(
        value: gender,
        child: Text(gender.displayName),
      );
    }).toList();
  }

  /// Create dropdown items for SkillLevel enum
  static List<DropdownMenuItem<SkillLevel>> skillLevelItems() {
    return SkillLevel.values.map((level) {
      return DropdownMenuItem<SkillLevel>(
        value: level,
        child: Text(level.displayName),
      );
    }).toList();
  }

  /// Create dropdown items for TrainingType enum
  static List<DropdownMenuItem<TrainingType>> trainingTypeItems() {
    return TrainingType.values.map((type) {
      return DropdownMenuItem<TrainingType>(
        value: type,
        child: Text(type.displayName),
      );
    }).toList();
  }

  /// Create dropdown items for string list
  static List<DropdownMenuItem<String>> stringItems(List<String> items) {
    return items.map((item) {
      return DropdownMenuItem<String>(
        value: item,
        child: Text(item),
      );
    }).toList();
  }

  /// Create dropdown items for age range
  static List<DropdownMenuItem<int>> ageItems({int minAge = 13, int maxAge = 80}) {
    return List.generate(maxAge - minAge + 1, (index) {
      final age = minAge + index;
      return DropdownMenuItem<int>(
        value: age,
        child: Text('$age years old'),
      );
    });
  }

  /// Create dropdown items for experience years
  static List<DropdownMenuItem<int>> experienceYearItems({int maxYears = 50}) {
    return List.generate(maxYears + 1, (index) {
      return DropdownMenuItem<int>(
        value: index,
        child: Text(index == 0 ? 'No experience' : '$index year${index == 1 ? '' : 's'}'),
      );
    });
  }
}



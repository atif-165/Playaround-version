import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../models/listing_model.dart';
import '../../../theming/colors.dart';
import '../../../theming/styles.dart';

/// Dropdown widget for selecting sport types
class SportTypeDropdown extends StatelessWidget {
  final SportType? selectedSportType;
  final ValueChanged<SportType?> onChanged;
  final String? hintText;

  const SportTypeDropdown({
    super.key,
    required this.selectedSportType,
    required this.onChanged,
    this.hintText,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<SportType>(
      value: selectedSportType,
      decoration: InputDecoration(
        hintText: hintText ?? 'Select sport type',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.r),
          borderSide: const BorderSide(color: ColorsManager.mainBlue),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      ),
      items: SportType.values.map((sportType) {
        return DropdownMenuItem<SportType>(
          value: sportType,
          child: Text(
            sportType.displayName,
            style: TextStyles.font14DarkBlueMedium,
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: onChanged,
      validator: (value) {
        if (value == null) {
          return 'Please select a sport type';
        }
        return null;
      },
      dropdownColor: Colors.white,
      icon: const Icon(
        Icons.keyboard_arrow_down,
        color: ColorsManager.mainBlue,
      ),
    );
  }

  // Removed unused _getSportIcon method
}

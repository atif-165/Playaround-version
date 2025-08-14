import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'colors.dart';

class TextStyles {
  static TextStyle font24Blue700Weight = TextStyle(
    fontSize: 24.sp,
    fontWeight: FontWeight.w700,
    color: ColorsManager.primary,                       // Fiery Red instead of blue
  );

  static TextStyle font14Blue400Weight = TextStyle(
    fontSize: 14.sp,
    fontWeight: FontWeight.w400,
    color: ColorsManager.primary,                       // Fiery Red instead of blue
  );

  static TextStyle font16White600Weight = TextStyle(
    fontSize: 16.sp,
    fontWeight: FontWeight.w600,
    color: ColorsManager.textPrimary,                   // Use theme white
  );
  static TextStyle font13Grey400Weight = TextStyle(
    fontSize: 13.sp,
    fontWeight: FontWeight.w400,
    color: ColorsManager.textSecondary,                 // Light gray for dark theme
  );
  static TextStyle font14Grey400Weight = TextStyle(
    fontSize: 14.sp,
    fontWeight: FontWeight.w400,
    color: ColorsManager.textSecondary,                 // Light gray for dark theme
  );
  static TextStyle font14Hint500Weight = TextStyle(
    fontSize: 14.sp,
    fontWeight: FontWeight.w500,
    color: ColorsManager.textTertiary,                  // Medium gray for hints
  );
  static TextStyle font14DarkBlue500Weight = TextStyle(
    fontSize: 14.sp,
    fontWeight: FontWeight.w500,
    color: ColorsManager.textPrimary,                   // White for dark theme
  );
  static TextStyle font15DarkBlue500Weight = TextStyle(
    fontSize: 15.sp,
    fontWeight: FontWeight.w500,
    color: ColorsManager.textPrimary,                   // White for dark theme
  );
  static TextStyle font11DarkBlue500Weight = TextStyle(
    fontSize: 11.sp,
    fontWeight: FontWeight.w500,
    color: ColorsManager.textPrimary,                   // White for dark theme
  );
  static TextStyle font11DarkBlue400Weight = TextStyle(
    fontSize: 11.sp,
    fontWeight: FontWeight.w400,
    color: ColorsManager.textPrimary,                   // White for dark theme
  );
  static TextStyle font11Blue600Weight = TextStyle(
    fontSize: 11.sp,
    fontWeight: FontWeight.w600,
    color: ColorsManager.primary,                       // Fiery Red instead of blue
  );
  static TextStyle font11MediumLightShadeOfGray400Weight = TextStyle(
    fontSize: 11.sp,
    fontWeight: FontWeight.w400,
    color: ColorsManager.mediumLightShadeOfGray,
  );

  static TextStyle font18DarkBlue600Weight = TextStyle(
    fontSize: 18.sp,
    fontWeight: FontWeight.w600,
    color: ColorsManager.textPrimary,                   // White for dark theme
  );

  static TextStyle font16Blue600Weight = TextStyle(
    fontSize: 16.sp,
    fontWeight: FontWeight.w600,
    color: ColorsManager.primary,                       // Fiery Red instead of blue
  );

  static TextStyle font12Grey400Weight = TextStyle(
    fontSize: 12.sp,
    fontWeight: FontWeight.w400,
    color: ColorsManager.gray,
  );

  static TextStyle font16Grey400Weight = TextStyle(
    fontSize: 16.sp,
    fontWeight: FontWeight.w400,
    color: ColorsManager.gray,
  );

  // Additional text styles for team and tournament modules
  static TextStyle font16DarkBlue500Weight = TextStyle(
    fontSize: 16.sp,
    fontWeight: FontWeight.w500,
    color: ColorsManager.darkBlue,
  );

  static TextStyle font16DarkBlue600Weight = TextStyle(
    fontSize: 16.sp,
    fontWeight: FontWeight.w600,
    color: ColorsManager.darkBlue,
  );

  static TextStyle font12DarkBlue400Weight = TextStyle(
    fontSize: 12.sp,
    fontWeight: FontWeight.w400,
    color: ColorsManager.darkBlue,
  );

  static TextStyle font13White400Weight = TextStyle(
    fontSize: 13.sp,
    fontWeight: FontWeight.w400,
    color: Colors.white,
  );

  static TextStyle font14White500Weight = TextStyle(
    fontSize: 14.sp,
    fontWeight: FontWeight.w500,
    color: Colors.white,
  );

  // Additional styles for new features
  static TextStyle font18DarkBlueBold = TextStyle(
    fontSize: 18.sp,
    fontWeight: FontWeight.bold,
    color: ColorsManager.darkBlue,
  );

  static TextStyle font16DarkBlueBold = TextStyle(
    fontSize: 16.sp,
    fontWeight: FontWeight.bold,
    color: ColorsManager.darkBlue,
  );

  static TextStyle font14DarkBlueMedium = TextStyle(
    fontSize: 14.sp,
    fontWeight: FontWeight.w500,
    color: ColorsManager.darkBlue,
  );

  static TextStyle font16WhiteSemiBold = TextStyle(
    fontSize: 16.sp,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  static TextStyle font14BlueRegular = TextStyle(
    fontSize: 14.sp,
    fontWeight: FontWeight.w400,
    color: ColorsManager.mainBlue,
  );

  static TextStyle font12BlueRegular = TextStyle(
    fontSize: 12.sp,
    fontWeight: FontWeight.w400,
    color: ColorsManager.mainBlue,
  );

  static TextStyle font12WhiteMedium = TextStyle(
    fontSize: 12.sp,
    fontWeight: FontWeight.w500,
    color: Colors.white,
  );

  static TextStyle font16BlueRegular = TextStyle(
    fontSize: 16.sp,
    fontWeight: FontWeight.w400,
    color: ColorsManager.mainBlue,
  );

  // Additional missing text styles
  static TextStyle font20DarkBlueBold = TextStyle(
    fontSize: 20.sp,
    fontWeight: FontWeight.bold,
    color: ColorsManager.darkBlue,
  );

  static TextStyle font14MainBlue500Weight = TextStyle(
    fontSize: 14.sp,
    fontWeight: FontWeight.w500,
    color: ColorsManager.mainBlue,
  );

  static TextStyle font14DarkBlue600Weight = TextStyle(
    fontSize: 14.sp,
    fontWeight: FontWeight.w600,
    color: ColorsManager.darkBlue,
  );

  static TextStyle font12DarkBlue600Weight = TextStyle(
    fontSize: 12.sp,
    fontWeight: FontWeight.w600,
    color: ColorsManager.darkBlue,
  );

  static TextStyle font14DarkBlueBold = TextStyle(
    fontSize: 14.sp,
    fontWeight: FontWeight.bold,
    color: ColorsManager.darkBlue,
  );

  static TextStyle font10Grey400Weight = TextStyle(
    fontSize: 10.sp,
    fontWeight: FontWeight.w400,
    color: ColorsManager.gray,
  );

  static TextStyle font10DarkBlue600Weight = TextStyle(
    fontSize: 10.sp,
    fontWeight: FontWeight.w600,
    color: ColorsManager.darkBlue,
  );

  static TextStyle font12MainBlue500Weight = TextStyle(
    fontSize: 12.sp,
    fontWeight: FontWeight.w500,
    color: ColorsManager.mainBlue,
  );

  static TextStyle font14White600Weight = TextStyle(
    fontSize: 14.sp,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );
}

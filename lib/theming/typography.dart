import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'colors.dart';

/// PlayAround Material 3 Typography System - Fiery Red & Deep Black Sports Theme
/// Comprehensive typography following Material Design 3 type scale
/// with responsive sizing, dark theme optimization, and accessibility compliance
class AppTypography {
  // Private constructor to prevent instantiation
  AppTypography._();

  // Base font family - Clean sans-serif for sports
  static const String fontFamily = 'Roboto';

  /// Display styles - Large, expressive text (White for dark theme)
  static TextStyle get displayLarge => TextStyle(
        fontSize: 57.sp,
        fontWeight: FontWeight.w700, // Bolder for sports impact
        letterSpacing: -0.25,
        height: 1.12,
        color: ColorsManager.textPrimary, // White text
        fontFamily: fontFamily,
      );

  static TextStyle get displayMedium => TextStyle(
        fontSize: 45.sp,
        fontWeight: FontWeight.w600, // Bolder for sports impact
        letterSpacing: 0,
        height: 1.16,
        color: ColorsManager.textPrimary, // White text
        fontFamily: fontFamily,
      );

  static TextStyle get displaySmall => TextStyle(
        fontSize: 36.sp,
        fontWeight: FontWeight.w600, // Bolder for sports impact
        letterSpacing: 0,
        height: 1.22,
        color: ColorsManager.textPrimary, // White text
        fontFamily: fontFamily,
      );

  /// Headline styles - High-emphasis text (White for dark theme)
  static TextStyle get headlineLarge => TextStyle(
        fontSize: 32.sp,
        fontWeight: FontWeight.w700, // Bold for sports headings
        letterSpacing: 0,
        height: 1.25,
        color: ColorsManager.textPrimary, // White text
        fontFamily: fontFamily,
      );

  static TextStyle get headlineMedium => TextStyle(
        fontSize: 28.sp,
        fontWeight: FontWeight.w600, // Semi-bold for sports
        letterSpacing: 0,
        height: 1.29,
        color: ColorsManager.textPrimary, // White text
        fontFamily: fontFamily,
      );

  static TextStyle get headlineSmall => TextStyle(
        fontSize: 24.sp,
        fontWeight: FontWeight.w600, // Semi-bold for sports
        letterSpacing: 0,
        height: 1.33,
        color: ColorsManager.textPrimary, // White text
        fontFamily: fontFamily,
      );

  /// Title styles - Medium-emphasis text (White for dark theme)
  static TextStyle get titleLarge => TextStyle(
        fontSize: 22.sp,
        fontWeight: FontWeight.w600, // Bolder for sports
        letterSpacing: 0,
        height: 1.27,
        color: ColorsManager.textPrimary, // White text
        fontFamily: fontFamily,
      );

  static TextStyle get titleMedium => TextStyle(
        fontSize: 16.sp,
        fontWeight: FontWeight.w600, // Bolder for sports
        letterSpacing: 0.15,
        height: 1.50,
        color: ColorsManager.textPrimary, // White text
        fontFamily: fontFamily,
      );

  static TextStyle get titleSmall => TextStyle(
        fontSize: 14.sp,
        fontWeight: FontWeight.w600, // Bolder for sports
        letterSpacing: 0.1,
        height: 1.43,
        color: ColorsManager.textPrimary, // White text
        fontFamily: fontFamily,
      );

  /// Label styles - Small text for components (Light gray for dark theme)
  static TextStyle get labelLarge => TextStyle(
        fontSize: 14.sp,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        height: 1.43,
        color: ColorsManager.textSecondary, // Light gray for labels
        fontFamily: fontFamily,
      );

  static TextStyle get labelMedium => TextStyle(
        fontSize: 12.sp,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        height: 1.33,
        color: ColorsManager.textSecondary, // Light gray for labels
        fontFamily: fontFamily,
      );

  static TextStyle get labelSmall => TextStyle(
        fontSize: 11.sp,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        height: 1.45,
        color: ColorsManager.textSecondary, // Light gray for labels
        fontFamily: fontFamily,
      );

  /// Body styles - Regular text content (White/Light gray for dark theme)
  static TextStyle get bodyLarge => TextStyle(
        fontSize: 16.sp,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.5,
        height: 1.50,
        color: ColorsManager.textPrimary, // White for body text
        fontFamily: fontFamily,
      );

  static TextStyle get bodyMedium => TextStyle(
        fontSize: 14.sp,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
        height: 1.43,
        color: ColorsManager.textSecondary, // Light gray for secondary body
        fontFamily: fontFamily,
      );

  static TextStyle get bodySmall => TextStyle(
        fontSize: 12.sp,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.4,
        height: 1.33,
        color: ColorsManager.textSecondary, // Light gray for small body
        fontFamily: fontFamily,
      );

  /// Sports-specific typography variants (Dark theme optimized)

  // Score and statistics text - Fiery red for impact
  static TextStyle get scoreText => TextStyle(
        fontSize: 32.sp,
        fontWeight: FontWeight.w800, // Extra bold for scores
        letterSpacing: -0.5,
        height: 1.0,
        color: ColorsManager.primary, // Fiery red
        fontFamily: fontFamily,
      );

  // Player/Coach names - White for visibility
  static TextStyle get playerName => TextStyle(
        fontSize: 18.sp,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        height: 1.22,
        color: ColorsManager.textPrimary, // White text
        fontFamily: fontFamily,
      );

  // Skill level indicators - White on colored backgrounds
  static TextStyle get skillLevel => TextStyle(
        fontSize: 12.sp,
        fontWeight: FontWeight.w700, // Bold for visibility
        letterSpacing: 0.5,
        height: 1.33,
        color: ColorsManager.textPrimary, // White for contrast
        fontFamily: fontFamily,
      );

  // Price text - Fiery red for emphasis
  static TextStyle get priceText => TextStyle(
        fontSize: 20.sp,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
        height: 1.20,
        color: ColorsManager.primary, // Fiery red
        fontFamily: fontFamily,
      );

  // Live update text - Neon green for success/wins
  static TextStyle get liveUpdateText => TextStyle(
        fontSize: 14.sp,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.1,
        height: 1.29,
        color: ColorsManager.success, // Neon green
        fontFamily: fontFamily,
      );

  // Button text variants - White text on colored buttons
  static TextStyle get buttonLarge => TextStyle(
        fontSize: 16.sp,
        fontWeight: FontWeight.w600, // Bolder for sports buttons
        letterSpacing: 0.1,
        height: 1.25,
        color: ColorsManager.onPrimary, // White on red buttons
        fontFamily: fontFamily,
      );

  static TextStyle get buttonMedium => TextStyle(
        fontSize: 14.sp,
        fontWeight: FontWeight.w600, // Bolder for sports buttons
        letterSpacing: 0.1,
        height: 1.29,
        color: ColorsManager.onPrimary, // White on red buttons
        fontFamily: fontFamily,
      );

  static TextStyle get buttonSmall => TextStyle(
        fontSize: 12.sp,
        fontWeight: FontWeight.w600, // Bolder for sports buttons
        letterSpacing: 0.5,
        height: 1.33,
        color: ColorsManager.onPrimary, // White on red buttons
        fontFamily: fontFamily,
      );

  /// Color variants for different contexts (Dark theme optimized)

  // Primary color variants - Fiery red
  static TextStyle primaryColor(TextStyle base) => base.copyWith(
        color: ColorsManager.primary, // Fiery red
      );

  static TextStyle onPrimaryColor(TextStyle base) => base.copyWith(
        color: ColorsManager.onPrimary, // White on red
      );

  // Secondary color variants - Vibrant orange
  static TextStyle secondaryColor(TextStyle base) => base.copyWith(
        color: ColorsManager.secondary, // Vibrant orange
      );

  static TextStyle onSecondaryColor(TextStyle base) => base.copyWith(
        color: ColorsManager.onSecondary, // White on orange
      );

  // Surface color variants - Light gray for dark theme
  static TextStyle onSurfaceVariant(TextStyle base) => base.copyWith(
        color: ColorsManager.textSecondary, // Light gray
      );

  // Error color variants - Fiery red (same as primary)
  static TextStyle errorColor(TextStyle base) => base.copyWith(
        color: ColorsManager.error, // Fiery red
      );

  // Success color variants - Neon green
  static TextStyle successColor(TextStyle base) => base.copyWith(
        color: ColorsManager.success, // Neon green
      );

  // Warning color variants - Gold
  static TextStyle warningColor(TextStyle base) => base.copyWith(
        color: ColorsManager.warning, // Gold
      );

  // Text color variants for dark theme
  static TextStyle primaryTextColor(TextStyle base) => base.copyWith(
        color: ColorsManager.textPrimary, // White
      );

  static TextStyle secondaryTextColor(TextStyle base) => base.copyWith(
        color: ColorsManager.textSecondary, // Light gray
      );

  static TextStyle tertiaryTextColor(TextStyle base) => base.copyWith(
        color: ColorsManager.textTertiary, // Medium gray
      );

  /// Utility methods for common text modifications

  static TextStyle bold(TextStyle base) => base.copyWith(
        fontWeight: FontWeight.w700,
      );

  static TextStyle semiBold(TextStyle base) => base.copyWith(
        fontWeight: FontWeight.w600,
      );

  static TextStyle medium(TextStyle base) => base.copyWith(
        fontWeight: FontWeight.w500,
      );

  static TextStyle italic(TextStyle base) => base.copyWith(
        fontStyle: FontStyle.italic,
      );

  static TextStyle underline(TextStyle base) => base.copyWith(
        decoration: TextDecoration.underline,
      );

  static TextStyle lineThrough(TextStyle base) => base.copyWith(
        decoration: TextDecoration.lineThrough,
      );

  /// Accessibility helpers

  static TextStyle withOpacity(TextStyle base, double opacity) => base.copyWith(
        color: base.color?.withValues(alpha: opacity),
      );

  static TextStyle withHeight(TextStyle base, double height) => base.copyWith(
        height: height,
      );

  static TextStyle withLetterSpacing(TextStyle base, double letterSpacing) =>
      base.copyWith(
        letterSpacing: letterSpacing,
      );
}

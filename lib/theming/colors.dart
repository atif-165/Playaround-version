import 'package:flutter/material.dart';

/// PlayAround Material 3 Color System - Fiery Red & Deep Black Sports Theme
/// Comprehensive color palette following Material Design 3 guidelines
/// with aggressive sports-themed branding for the PlayAround app
class ColorsManager {
  // Legacy colors (maintained for backward compatibility)
  static const Color mainBlue = Color(0xFF247CFF);
  static const Color gray = Color(0xFF757575);
  static const Color gray93Color = Color(0xFFEDEDED);
  static const Color gray76 = Color(0xFFC2C2C2);
  static const Color darkBlue = Color(0xFF242424);
  static const Color lightShadeOfGray = Color(0xFFFDFDFF);
  static const Color mediumLightShadeOfGray = Color(0xFF9E9E9E);
  static const Color coralRed = Color(0xFFFF4C5E);

  // Material 3 Primary Color Palette (Fiery Red Theme)
  static const Color primary = Color(0xFFFF3B30); // Fiery Red
  static const Color onPrimary = Color(0xFFFFFFFF); // White text on red
  static const Color primaryContainer = Color(0xFF4D0000); // Dark red container
  static const Color onPrimaryContainer =
      Color(0xFFFFFFFF); // White text on dark red

  // Material 3 Secondary Color Palette (Vibrant Orange Accent)
  static const Color secondary = Color(0xFFFF6B00); // Vibrant Orange
  static const Color onSecondary = Color(0xFFFFFFFF); // White text on orange
  static const Color secondaryContainer =
      Color(0xFF4D2000); // Dark orange container
  static const Color onSecondaryContainer =
      Color(0xFFFFFFFF); // White text on dark orange

  // Material 3 Tertiary Color Palette (Neon Green Success)
  static const Color tertiary = Color(0xFF00FF85); // Neon Green
  static const Color onTertiary = Color(0xFF000000); // Black text on neon green
  static const Color tertiaryContainer =
      Color(0xFF004D2A); // Dark green container
  static const Color onTertiaryContainer =
      Color(0xFFFFFFFF); // White text on dark green

  // Material 3 Error Color Palette (Consistent with Primary Red)
  static const Color error = Color(0xFFFF3B30); // Same as primary red
  static const Color onError = Color(0xFFFFFFFF); // White text on red
  static const Color errorContainer = Color(0xFF4D0000); // Dark red container
  static const Color onErrorContainer =
      Color(0xFFFFFFFF); // White text on dark red

  // Material 3 Surface Color Palette (Deep Black Theme)
  static const Color surface =
      Color(0xFF000000); // Pure Black primary background
  static const Color onSurface = Color(0xFFFFFFFF); // White text on black
  static const Color surfaceVariant =
      Color(0xFF1A1A1A); // Dark gray for sections/cards
  static const Color onSurfaceVariant =
      Color(0xFFCCCCCC); // Light gray for less prominent info
  static const Color surfaceTint = primary; // Red tint

  // Material 3 Background Colors (Deep Black)
  static const Color background = Color(0xFF000000); // Pure Black background
  static const Color onBackground = Color(0xFFFFFFFF); // White text on black

  // Material 3 Outline Colors (Subtle borders)
  static const Color outline = Color(0xFF404040); // Dark gray outlines
  static const Color outlineVariant = Color(0xFF2A2A2A); // Darker gray variant

  // Material 3 Inverse Colors (Light mode equivalents)
  static const Color inverseSurface =
      Color(0xFFFFFFFF); // White inverse surface
  static const Color onInverseSurface =
      Color(0xFF0D0D0D); // Black text on white
  static const Color inversePrimary =
      Color(0xFFFF3B30); // Red remains consistent

  // Sports-specific semantic colors (Dark Theme Optimized)
  static const Color success = Color(0xFF00FF85); // Neon Green for wins/success
  static const Color warning = Color(0xFFFFC300); // Gold for cautions
  static const Color info = Color(0xFFFF3B30); // Red for important info
  static const Color panelAccentColor = Color(0xFFFFC56F); // Warm accent for panels

  // Role-specific colors (Dark Theme Sports)
  static const Color playerAccent = Color(0xFF00FF85); // Neon Green for players
  static const Color coachAccent = Color(0xFFFF3B30); // Fiery Red for coaches
  static const Color adminAccent =
      Color(0xFFFF6B00); // Vibrant Orange for admins

  // Skill level colors (High Contrast for Dark Theme)
  static const Color beginnerColor =
      Color(0xFF00FF85); // Neon Green for beginners
  static const Color intermediateColor =
      Color(0xFFFFC300); // Gold for intermediate
  static const Color advancedColor = Color(0xFFFF6B00); // Orange for advanced
  static const Color expertColor = Color(0xFFFF3B30); // Red for experts
  static const Color proColor =
      Color(0xFFFF3B30); // Red for pro (same as expert)

  // Chart and data visualization colors (Dark Theme Optimized)
  static const List<Color> chartColors = [
    Color(0xFFFF3B30), // Fiery Red
    Color(0xFF00FF85), // Neon Green
    Color(0xFFFF6B00), // Vibrant Orange
    Color(0xFFFFC300), // Gold
    Color(0xFF00D4FF), // Cyan Blue
    Color(0xFFFF1493), // Deep Pink
  ];

  // Gradient definitions (Dark Theme Sports)
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFFF3B30), Color(0xFFFF1A0D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF00FF85), Color(0xFF00CC6A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient warningGradient = LinearGradient(
    colors: [Color(0xFFFFC300), Color(0xFFE6B000)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Additional Dark Theme Specific Colors
  static const Color cardBackground = Color(0xFF000000); // Pure black for cards
  static const Color dividerColor = Color(0xFF404040); // Subtle dividers
  static const Color shimmerBase = Color(0xFF2A2A2A); // Shimmer base color
  static const Color shimmerHighlight = Color(0xFF404040); // Shimmer highlight

  // Chat-specific colors
  static const Color neonBlue =
      Color(0xFF00D4FF); // Neon blue for chat backgrounds
  static const Color chatBackground =
      Color(0xFF0A1A2A); // Dark blue chat background

  // Text colors for dark theme
  static const Color textPrimary = Color(0xFFFFFFFF); // White for headings/body
  static const Color textSecondary =
      Color(0xFFCCCCCC); // Light gray for secondary text
  static const Color textTertiary =
      Color(0xFF999999); // Medium gray for tertiary text

  // Legacy alias support
  static const Color grey = gray;
}

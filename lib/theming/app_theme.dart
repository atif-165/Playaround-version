import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'colors.dart';

/// PlayAround Material 3 Theme Configuration - Fiery Red & Deep Black Sports Theme
/// Comprehensive theme system following Material Design 3 guidelines
/// with aggressive sports-themed branding and accessibility compliance
class AppTheme {
  // Private constructor to prevent instantiation
  AppTheme._();

  /// Dark theme configuration (Primary theme - Fiery Red & Deep Black)
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      // Color scheme - Dark theme with fiery red accents
      colorScheme: const ColorScheme.dark(
        primary: ColorsManager.primary,                    // Fiery Red
        onPrimary: ColorsManager.onPrimary,               // White
        primaryContainer: ColorsManager.primaryContainer,  // Dark Red
        onPrimaryContainer: ColorsManager.onPrimaryContainer, // White
        secondary: ColorsManager.secondary,               // Vibrant Orange
        onSecondary: ColorsManager.onSecondary,          // White
        secondaryContainer: ColorsManager.secondaryContainer, // Dark Orange
        onSecondaryContainer: ColorsManager.onSecondaryContainer, // White
        tertiary: ColorsManager.tertiary,                // Neon Green
        onTertiary: ColorsManager.onTertiary,            // Black
        tertiaryContainer: ColorsManager.tertiaryContainer, // Dark Green
        onTertiaryContainer: ColorsManager.onTertiaryContainer, // White
        error: ColorsManager.error,                      // Fiery Red
        onError: ColorsManager.onError,                  // White
        errorContainer: ColorsManager.errorContainer,    // Dark Red
        onErrorContainer: ColorsManager.onErrorContainer, // White
        surface: ColorsManager.surface,                  // Deep Black
        onSurface: ColorsManager.onSurface,             // White
        surfaceContainerHighest: ColorsManager.surfaceVariant, // Dark Gray
        onSurfaceVariant: ColorsManager.onSurfaceVariant, // Light Gray
        outline: ColorsManager.outline,                  // Dark Gray
        outlineVariant: ColorsManager.outlineVariant,    // Darker Gray
        inverseSurface: ColorsManager.inverseSurface,    // White
        onInverseSurface: ColorsManager.onInverseSurface, // Black
        inversePrimary: ColorsManager.inversePrimary,    // Red
        surfaceTint: ColorsManager.surfaceTint,          // Red
      ),

      // App Bar Theme - Deep black with red accents
      appBarTheme: const AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 2,
        backgroundColor: Colors.black,           // Deep Black
        foregroundColor: Colors.white,        // White
        surfaceTintColor: ColorsManager.primary,         // Red tint
        systemOverlayStyle: SystemUiOverlayStyle.light,  // Light status bar for dark theme
        titleTextStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,                   // Bolder for sports theme
          color: Colors.white,               // White
        ),
        iconTheme: IconThemeData(
          color: Colors.white,               // White icons
          size: 24,
        ),
      ),

      // Card Theme - Dark gray cards with red accents
      cardTheme: CardThemeData(
        elevation: 2,
        color: ColorsManager.surfaceVariant,             // Dark gray background
        surfaceTintColor: ColorsManager.primary,         // Red tint
        shadowColor: Colors.black.withValues(alpha: 0.3),     // Subtle shadow
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),       // More rounded for sports feel
          side: BorderSide(
            color: ColorsManager.outline.withValues(alpha: 0.2), // Subtle border
            width: 1,
          ),
        ),
        margin: const EdgeInsets.all(8),
      ),

      // Elevated Button Theme - Fiery red primary buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 3,
          backgroundColor: ColorsManager.primary,         // Fiery Red
          foregroundColor: ColorsManager.onPrimary,      // White
          surfaceTintColor: ColorsManager.primary,       // Red tint
          shadowColor: ColorsManager.primary.withValues(alpha: 0.3), // Red glow
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,                 // Bolder for sports
          ),
        ),
      ),

      // Filled Button Theme - Solid red buttons
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: ColorsManager.primary,         // Fiery Red
          foregroundColor: ColorsManager.onPrimary,      // White
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,                 // Bolder for sports
          ),
        ),
      ),

      // Outlined Button Theme - White outline with red hover
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ColorsManager.onSurface,      // White text
          side: const BorderSide(
            color: ColorsManager.onSurface,              // White border
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,                 // Bolder for sports
          ),
        ).copyWith(
          // Hover state with orange
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered)) {
              return ColorsManager.secondary.withValues(alpha: 0.1); // Orange hover
            }
            return null;
          }),
        ),
      ),

      // Text Button Theme - Red text buttons
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: ColorsManager.primary,        // Red text
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,                 // Bolder for sports
          ),
        ),
      ),

      // Input Decoration Theme - Dark theme optimized
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ColorsManager.surfaceVariant.withValues(alpha: 0.5), // Darker fill
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: ColorsManager.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: ColorsManager.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: ColorsManager.primary, width: 2), // Red focus
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: ColorsManager.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: ColorsManager.error, width: 2),
        ),
        labelStyle: const TextStyle(
          color: ColorsManager.textSecondary,            // Light gray labels
          fontSize: 16,
        ),
        hintStyle: const TextStyle(
          color: ColorsManager.textTertiary,             // Medium gray hints
          fontSize: 16,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),

      // Floating Action Button Theme - Red with glow effect
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: ColorsManager.primary,          // Fiery Red
        foregroundColor: ColorsManager.onPrimary,       // White
        elevation: 6,
        shape: CircleBorder(),
        extendedSizeConstraints: BoxConstraints.tightFor(height: 56),
        extendedIconLabelSpacing: 8,
        extendedPadding: EdgeInsets.symmetric(horizontal: 16),
      ),

      // Bottom Navigation Bar Theme - Deep black with red accents
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.black,          // Deep Black
        selectedItemColor: ColorsManager.primary,        // Red for active
        unselectedItemColor: ColorsManager.textSecondary, // Light gray for inactive
        elevation: 8,
        selectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,                   // Bolder for sports
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
      ),

      // Navigation Bar Theme (Material 3) - Deep black with red indicators
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.black,          // Deep Black
        surfaceTintColor: ColorsManager.primary,         // Red tint
        indicatorColor: ColorsManager.primary,           // Red indicator
        height: 80,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,               // Bolder for sports
              color: ColorsManager.textPrimary,          // White for selected
            );
          }
          return const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: ColorsManager.textSecondary,          // Light gray for unselected
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(
              color: ColorsManager.onPrimary,             // White icons on red
              size: 26,                                   // Slightly larger for sports
            );
          }
          return const IconThemeData(
            color: ColorsManager.textSecondary,          // Light gray for inactive
            size: 24,
          );
        }),
      ),

      // Chip Theme - Dark theme with red/orange accents
      chipTheme: ChipThemeData(
        backgroundColor: ColorsManager.surfaceVariant,   // Dark gray background
        selectedColor: ColorsManager.primary,            // Red when selected
        disabledColor: ColorsManager.surfaceVariant.withValues(alpha: 0.3),
        labelStyle: const TextStyle(
          color: ColorsManager.textSecondary,            // Light gray text
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        secondaryLabelStyle: const TextStyle(
          color: ColorsManager.onPrimary,                // White text on red
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),       // More rounded for modern look
        ),
        side: BorderSide(
          color: ColorsManager.outline.withValues(alpha: 0.3), // Subtle border
          width: 1,
        ),
        elevation: 1,
      ),

      // Dialog Theme - Dark background with red/orange accents
      dialogTheme: DialogThemeData(
        backgroundColor: ColorsManager.surfaceVariant,   // Dark gray background
        surfaceTintColor: ColorsManager.primary,         // Red tint
        elevation: 12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),       // More rounded for modern look
          side: BorderSide(
            color: ColorsManager.primary.withValues(alpha: 0.2), // Subtle red border
            width: 1,
          ),
        ),
        titleTextStyle: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,                   // Bold for sports
          color: ColorsManager.textPrimary,              // White
        ),
        contentTextStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: ColorsManager.textSecondary,            // Light gray
        ),
      ),

      // Snack Bar Theme - Dark with red/orange accents
      snackBarTheme: SnackBarThemeData(
        backgroundColor: ColorsManager.surfaceVariant,   // Dark gray
        contentTextStyle: const TextStyle(
          color: ColorsManager.textPrimary,              // White text
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        actionTextColor: ColorsManager.primary,          // Red action text
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 6,
      ),

      // Text Selection Theme - Red selection
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: ColorsManager.primary,              // Red cursor
        selectionColor: ColorsManager.primary.withValues(alpha: 0.3), // Red selection
        selectionHandleColor: ColorsManager.primary,     // Red handles
      ),

      // Divider Theme - Subtle dark dividers
      dividerTheme: const DividerThemeData(
        color: ColorsManager.dividerColor,               // Dark gray dividers
        thickness: 1,
        space: 1,
      ),

      // List Tile Theme - Dark theme optimized
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        titleTextStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,                   // Bolder for sports
          color: ColorsManager.textPrimary,              // White
        ),
        subtitleTextStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: ColorsManager.textSecondary,            // Light gray
        ),
        iconColor: ColorsManager.textSecondary,          // Light gray icons
        tileColor: Colors.transparent,
        selectedTileColor: ColorsManager.primary.withValues(alpha: 0.1), // Red selection
      ),

      // Progress Indicator Theme - Red progress indicators
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: ColorsManager.primary,                    // Red progress
        linearTrackColor: ColorsManager.outline,         // Dark track
        circularTrackColor: ColorsManager.outline,       // Dark track
      ),

      // Switch Theme - Red switches
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return ColorsManager.primary;                // Red when on
          }
          return ColorsManager.outline;                  // Gray when off
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return ColorsManager.primary.withValues(alpha: 0.5); // Red track when on
          }
          return ColorsManager.outline.withValues(alpha: 0.3); // Gray track when off
        }),
      ),
    );
  }

  /// Dark theme configuration (same as light theme for this sports app)
  static ThemeData get darkTheme {
    return lightTheme; // Using the same dark theme for consistency
  }
}

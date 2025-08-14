import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

/// Accessibility helpers for PlayAround app
/// Provides semantic labels, focus management, and accessibility compliance

class AccessibilityHelper {
  /// Check if high contrast mode is enabled
  static bool isHighContrastEnabled(BuildContext context) {
    return MediaQuery.of(context).highContrast;
  }

  /// Check if reduce motion is enabled
  static bool isReduceMotionEnabled(BuildContext context) {
    return MediaQuery.of(context).disableAnimations;
  }

  /// Check if large text is enabled
  static bool isLargeTextEnabled(BuildContext context) {
    return MediaQuery.of(context).textScaler.scale(1.0) > 1.3;
  }

  /// Get accessible text size
  static double getAccessibleTextSize(BuildContext context, double baseSize) {
    final textScaler = MediaQuery.of(context).textScaler;
    return textScaler.scale(baseSize);
  }

  /// Create semantic label for buttons
  static String createButtonLabel({
    required String action,
    String? target,
    String? context,
  }) {
    final parts = <String>[action];
    if (target != null) parts.add(target);
    if (context != null) parts.add('in $context');
    return parts.join(' ');
  }

  /// Create semantic label for navigation
  static String createNavigationLabel({
    required String destination,
    bool isSelected = false,
    int? badgeCount,
  }) {
    final parts = <String>[];
    
    if (isSelected) {
      parts.add('Selected');
    }
    
    parts.add(destination);
    parts.add('tab');
    
    if (badgeCount != null && badgeCount > 0) {
      parts.add('$badgeCount notifications');
    }
    
    return parts.join(' ');
  }

  /// Create semantic label for form fields
  static String createFormFieldLabel({
    required String fieldName,
    bool isRequired = false,
    String? hint,
    String? error,
  }) {
    final parts = <String>[fieldName];
    
    if (isRequired) {
      parts.add('required');
    }
    
    if (hint != null) {
      parts.add(hint);
    }
    
    if (error != null) {
      parts.add('Error: $error');
    }
    
    return parts.join(', ');
  }

  /// Create semantic label for lists
  static String createListItemLabel({
    required String title,
    String? subtitle,
    int? position,
    int? totalItems,
  }) {
    final parts = <String>[title];
    
    if (subtitle != null) {
      parts.add(subtitle);
    }
    
    if (position != null && totalItems != null) {
      parts.add('item $position of $totalItems');
    }
    
    return parts.join(', ');
  }

  /// Announce message to screen reader
  static void announceMessage(BuildContext context, String message) {
    SemanticsService.announce(message, TextDirection.ltr);
  }

  /// Focus on widget
  static void focusWidget(FocusNode focusNode) {
    focusNode.requestFocus();
  }

  /// Check if widget is focused
  static bool isWidgetFocused(FocusNode focusNode) {
    return focusNode.hasFocus;
  }
}

/// Accessible button wrapper
class AccessibleButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final String? semanticLabel;
  final String? tooltip;
  final bool excludeSemantics;

  const AccessibleButton({
    super.key,
    required this.child,
    this.onPressed,
    this.semanticLabel,
    this.tooltip,
    this.excludeSemantics = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget button = child;

    if (tooltip != null) {
      button = Tooltip(
        message: tooltip!,
        child: button,
      );
    }

    if (!excludeSemantics && semanticLabel != null) {
      button = Semantics(
        label: semanticLabel,
        button: true,
        enabled: onPressed != null,
        child: button,
      );
    }

    return button;
  }
}

/// Accessible text field wrapper
class AccessibleTextField extends StatelessWidget {
  final Widget child;
  final String? label;
  final String? hint;
  final String? error;
  final bool isRequired;
  final bool excludeSemantics;

  const AccessibleTextField({
    super.key,
    required this.child,
    this.label,
    this.hint,
    this.error,
    this.isRequired = false,
    this.excludeSemantics = false,
  });

  @override
  Widget build(BuildContext context) {
    if (excludeSemantics) {
      return child;
    }

    final semanticLabel = AccessibilityHelper.createFormFieldLabel(
      fieldName: label ?? 'Text field',
      isRequired: isRequired,
      hint: hint,
      error: error,
    );

    return Semantics(
      label: semanticLabel,
      textField: true,
      child: child,
    );
  }
}

/// Accessible list item wrapper
class AccessibleListItem extends StatelessWidget {
  final Widget child;
  final String title;
  final String? subtitle;
  final int? position;
  final int? totalItems;
  final VoidCallback? onTap;
  final bool excludeSemantics;

  const AccessibleListItem({
    super.key,
    required this.child,
    required this.title,
    this.subtitle,
    this.position,
    this.totalItems,
    this.onTap,
    this.excludeSemantics = false,
  });

  @override
  Widget build(BuildContext context) {
    if (excludeSemantics) {
      return child;
    }

    final semanticLabel = AccessibilityHelper.createListItemLabel(
      title: title,
      subtitle: subtitle,
      position: position,
      totalItems: totalItems,
    );

    return Semantics(
      label: semanticLabel,
      button: onTap != null,
      child: child,
    );
  }
}

/// High contrast color helper
class HighContrastColors {
  static Color getTextColor(BuildContext context, Color defaultColor) {
    if (AccessibilityHelper.isHighContrastEnabled(context)) {
      return Colors.black;
    }
    return defaultColor;
  }

  static Color getBackgroundColor(BuildContext context, Color defaultColor) {
    if (AccessibilityHelper.isHighContrastEnabled(context)) {
      return Colors.white;
    }
    return defaultColor;
  }

  static Color getBorderColor(BuildContext context, Color defaultColor) {
    if (AccessibilityHelper.isHighContrastEnabled(context)) {
      return Colors.black;
    }
    return defaultColor;
  }
}

/// Focus management helper
class FocusHelper {
  /// Move focus to next focusable widget
  static void focusNext(BuildContext context) {
    FocusScope.of(context).nextFocus();
  }

  /// Move focus to previous focusable widget
  static void focusPrevious(BuildContext context) {
    FocusScope.of(context).previousFocus();
  }

  /// Remove focus from current widget
  static void unfocus(BuildContext context) {
    FocusScope.of(context).unfocus();
  }

  /// Create focus traversal order
  static Widget createFocusTraversalGroup({
    required Widget child,
    FocusTraversalPolicy? policy,
  }) {
    return FocusTraversalGroup(
      policy: policy ?? OrderedTraversalPolicy(),
      child: child,
    );
  }
}

/// Semantic announcements helper
class SemanticAnnouncements {
  /// Announce loading state
  static void announceLoading(BuildContext context) {
    AccessibilityHelper.announceMessage(context, 'Loading');
  }

  /// Announce success
  static void announceSuccess(BuildContext context, String message) {
    AccessibilityHelper.announceMessage(context, 'Success: $message');
  }

  /// Announce error
  static void announceError(BuildContext context, String message) {
    AccessibilityHelper.announceMessage(context, 'Error: $message');
  }

  /// Announce navigation
  static void announceNavigation(BuildContext context, String destination) {
    AccessibilityHelper.announceMessage(context, 'Navigated to $destination');
  }

  /// Announce item added
  static void announceItemAdded(BuildContext context, String item) {
    AccessibilityHelper.announceMessage(context, '$item added');
  }

  /// Announce item removed
  static void announceItemRemoved(BuildContext context, String item) {
    AccessibilityHelper.announceMessage(context, '$item removed');
  }
}

/// Accessibility testing helper
class AccessibilityTester {
  /// Check if widget has semantic label
  static bool hasSemanticLabel(Widget widget) {
    // This would be used in tests to verify accessibility
    return true; // Placeholder implementation
  }

  /// Check if widget is focusable
  static bool isFocusable(Widget widget) {
    // This would be used in tests to verify focus behavior
    return true; // Placeholder implementation
  }

  /// Check color contrast ratio
  static double getContrastRatio(Color foreground, Color background) {
    // Calculate WCAG contrast ratio
    final fgLuminance = _getLuminance(foreground);
    final bgLuminance = _getLuminance(background);
    
    final lighter = fgLuminance > bgLuminance ? fgLuminance : bgLuminance;
    final darker = fgLuminance > bgLuminance ? bgLuminance : fgLuminance;
    
    return (lighter + 0.05) / (darker + 0.05);
  }

  static double _getLuminance(Color color) {
    final r = _getRelativeLuminance(color.r / 255.0);
    final g = _getRelativeLuminance(color.g / 255.0);
    final b = _getRelativeLuminance(color.b / 255.0);
    
    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  }

  static double _getRelativeLuminance(double value) {
    return value <= 0.03928 
        ? value / 12.92 
        : ((value + 0.055) / 1.055) * ((value + 0.055) / 1.055);
  }

  /// Check if contrast ratio meets WCAG AA standards
  static bool meetsWCAGAA(Color foreground, Color background) {
    return getContrastRatio(foreground, background) >= 4.5;
  }

  /// Check if contrast ratio meets WCAG AAA standards
  static bool meetsWCAGAAA(Color foreground, Color background) {
    return getContrastRatio(foreground, background) >= 7.0;
  }
}

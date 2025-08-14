import 'package:flutter/material.dart';

/// Custom page transitions for PlayAround app
/// Provides smooth, Material 3 compliant animations between screens

enum TransitionType {
  slide,
  fade,
  scale,
  slideUp,
  slideDown,
  none,
}

class AppPageTransitions {
  static const Duration _defaultDuration = Duration(milliseconds: 300);
  static const Curve _defaultCurve = Curves.easeInOut;

  /// Create a page route with custom transition
  static PageRouteBuilder<T> createRoute<T>({
    required Widget page,
    TransitionType type = TransitionType.slide,
    Duration duration = _defaultDuration,
    Curve curve = _defaultCurve,
    RouteSettings? settings,
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return _buildTransition(
          type: type,
          animation: animation,
          secondaryAnimation: secondaryAnimation,
          child: child,
          curve: curve,
        );
      },
    );
  }

  /// Build the appropriate transition based on type
  static Widget _buildTransition({
    required TransitionType type,
    required Animation<double> animation,
    required Animation<double> secondaryAnimation,
    required Widget child,
    required Curve curve,
  }) {
    final curvedAnimation = CurvedAnimation(
      parent: animation,
      curve: curve,
    );

    switch (type) {
      case TransitionType.slide:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: child,
        );

      case TransitionType.fade:
        return FadeTransition(
          opacity: curvedAnimation,
          child: child,
        );

      case TransitionType.scale:
        return ScaleTransition(
          scale: Tween<double>(
            begin: 0.0,
            end: 1.0,
          ).animate(curvedAnimation),
          child: child,
        );

      case TransitionType.slideUp:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.0, 1.0),
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: child,
        );

      case TransitionType.slideDown:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.0, -1.0),
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: child,
        );

      case TransitionType.none:
        return child;
    }
  }

  /// Slide transition from right (default Material behavior)
  static Route<T> slideFromRight<T>(Widget page, [RouteSettings? settings]) {
    return createRoute<T>(
      page: page,
      type: TransitionType.slide,
      settings: settings,
    );
  }

  /// Slide transition from bottom (for modals)
  static Route<T> slideFromBottom<T>(Widget page, [RouteSettings? settings]) {
    return createRoute<T>(
      page: page,
      type: TransitionType.slideUp,
      settings: settings,
    );
  }

  /// Fade transition (for overlays)
  static Route<T> fadeIn<T>(Widget page, [RouteSettings? settings]) {
    return createRoute<T>(
      page: page,
      type: TransitionType.fade,
      settings: settings,
    );
  }

  /// Scale transition (for dialogs)
  static Route<T> scaleIn<T>(Widget page, [RouteSettings? settings]) {
    return createRoute<T>(
      page: page,
      type: TransitionType.scale,
      curve: Curves.elasticOut,
      settings: settings,
    );
  }

  /// No transition (instant)
  static Route<T> instant<T>(Widget page, [RouteSettings? settings]) {
    return createRoute<T>(
      page: page,
      type: TransitionType.none,
      duration: Duration.zero,
      settings: settings,
    );
  }

  /// Hero transition for shared elements
  static Route<T> heroTransition<T>({
    required Widget page,
    required String heroTag,
    RouteSettings? settings,
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: _defaultDuration,
      reverseTransitionDuration: _defaultDuration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: _defaultCurve,
          ),
          child: child,
        );
      },
    );
  }

  /// Shared axis transition (Material 3 style)
  static Route<T> sharedAxisTransition<T>({
    required Widget page,
    SharedAxisTransitionType transitionType = SharedAxisTransitionType.horizontal,
    RouteSettings? settings,
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: _defaultDuration,
      reverseTransitionDuration: _defaultDuration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return _buildSharedAxisTransition(
          animation: animation,
          secondaryAnimation: secondaryAnimation,
          child: child,
          transitionType: transitionType,
        );
      },
    );
  }

  static Widget _buildSharedAxisTransition({
    required Animation<double> animation,
    required Animation<double> secondaryAnimation,
    required Widget child,
    required SharedAxisTransitionType transitionType,
  }) {
    final curvedAnimation = CurvedAnimation(
      parent: animation,
      curve: _defaultCurve,
    );

    final secondaryCurvedAnimation = CurvedAnimation(
      parent: secondaryAnimation,
      curve: _defaultCurve,
    );

    switch (transitionType) {
      case SharedAxisTransitionType.horizontal:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: SlideTransition(
            position: Tween<Offset>(
              begin: Offset.zero,
              end: const Offset(-1.0, 0.0),
            ).animate(secondaryCurvedAnimation),
            child: child,
          ),
        );

      case SharedAxisTransitionType.vertical:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.0, 1.0),
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: SlideTransition(
            position: Tween<Offset>(
              begin: Offset.zero,
              end: const Offset(0.0, -1.0),
            ).animate(secondaryCurvedAnimation),
            child: child,
          ),
        );

      case SharedAxisTransitionType.scaled:
        return ScaleTransition(
          scale: Tween<double>(
            begin: 0.8,
            end: 1.0,
          ).animate(curvedAnimation),
          child: FadeTransition(
            opacity: curvedAnimation,
            child: child,
          ),
        );
    }
  }
}

enum SharedAxisTransitionType {
  horizontal,
  vertical,
  scaled,
}

/// Extension to add transition methods to Navigator
extension NavigatorTransitions on NavigatorState {
  Future<T?> pushWithTransition<T extends Object?>(
    Widget page, {
    TransitionType transition = TransitionType.slide,
    Duration? duration,
    Curve? curve,
  }) {
    return push<T>(
      AppPageTransitions.createRoute<T>(
        page: page,
        type: transition,
        duration: duration ?? const Duration(milliseconds: 300),
        curve: curve ?? Curves.easeInOut,
      ),
    );
  }

  Future<T?> pushReplacementWithTransition<T extends Object?, TO extends Object?>(
    Widget page, {
    TransitionType transition = TransitionType.slide,
    Duration? duration,
    Curve? curve,
    TO? result,
  }) {
    return pushReplacement<T, TO>(
      AppPageTransitions.createRoute<T>(
        page: page,
        type: transition,
        duration: duration ?? const Duration(milliseconds: 300),
        curve: curve ?? Curves.easeInOut,
      ),
      result: result,
    );
  }
}

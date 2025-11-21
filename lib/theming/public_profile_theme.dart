import 'package:flutter/material.dart';

/// Shared design tokens for the public-profile experience.
class PublicProfileTheme {
  const PublicProfileTheme._();

  static const Color backgroundColor = Color(0xFF050414);

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF1B1848),
      Color(0xFF080612),
    ],
  );

  static const LinearGradient panelGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF181536),
      Color(0xFF0E0D24),
    ],
  );

  static const Color panelColor = Color(0xFF14112D);
  static const Color panelOverlayColor = Color(0xFF1C1A3C);
  static const Color panelAccentColor = Color(0xFFFFC56F);

  static const double defaultBlurSigma = 14;

  static List<BoxShadow> defaultShadow() {
    return [
      BoxShadow(
        color: Colors.black.withOpacity(0.35),
        blurRadius: 26,
        offset: const Offset(0, 18),
      ),
    ];
  }

  static BoxDecoration glassPanelDecoration({
    double borderRadius = 24,
    List<BoxShadow>? shadows,
  }) {
    return BoxDecoration(
      gradient: panelGradient,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: Colors.white.withOpacity(0.06),
        width: 1,
      ),
      boxShadow: shadows ?? defaultShadow(),
    );
  }
}

import 'package:flutter/foundation.dart';

/// Centralizes configuration needed for third-party video call SDKs.
class VideoCallConfig {
  /// ZEGO app identifier injected at build time to avoid committing secrets.
  static const int zegoAppId =
      int.fromEnvironment('ZEGO_APP_ID', defaultValue: 0);

  /// ZEGO app sign injected at build time.
  static const String zegoAppSign =
      String.fromEnvironment('ZEGO_APP_SIGN', defaultValue: '');

  /// Whether the ZEGO credentials are usable.
  static bool get hasValidZegoCredentials =>
      zegoAppId > 0 && zegoAppSign.isNotEmpty;

  /// Helper to assert credentials during development.
  static void debugAssertCredentials() {
    assert(
      hasValidZegoCredentials ||
          kDebugMode,
      'ZEGO credentials missing. Provide ZEGO_APP_ID and ZEGO_APP_SIGN at build time.',
    );
  }
}


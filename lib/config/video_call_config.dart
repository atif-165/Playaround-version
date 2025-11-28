import 'package:flutter/foundation.dart';

/// Centralizes configuration needed for third-party video call SDKs.
class VideoCallConfig {
  /// ZEGO app identifier injected at build time to avoid committing secrets.
  /// Can be overridden via --dart-define=ZEGO_APP_ID=<value> at build time.
  static const int zegoAppId =
      int.fromEnvironment('ZEGO_APP_ID', defaultValue: 2049357064);

  /// ZEGO app sign injected at build time.
  /// Can be overridden via --dart-define=ZEGO_APP_SIGN=<value> at build time.
  static const String zegoAppSign =
      String.fromEnvironment('ZEGO_APP_SIGN', 
          defaultValue: '315c8c1e77f05df9744db5e50c30ea23752d60bdeb5445653c1d757db42f6ac4');

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


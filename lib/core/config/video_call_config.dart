class VideoCallConfig {
  const VideoCallConfig._();

  /// Configure these via --dart-define at build time.
  static const int zegoAppId =
      int.fromEnvironment('ZEGO_APP_ID', defaultValue: 0);
  static const String zegoAppSign =
      String.fromEnvironment('ZEGO_APP_SIGN', defaultValue: '');

  static bool get isConfigured => zegoAppId != 0 && zegoAppSign.isNotEmpty;
}


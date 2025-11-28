class VideoCallConfig {
  const VideoCallConfig._();

  /// Configure these via --dart-define at build time.
  /// Can be overridden via --dart-define=ZEGO_APP_ID=<value> at build time.
  static const int zegoAppId =
      int.fromEnvironment('ZEGO_APP_ID', defaultValue: 2049357064);
  
  /// ZEGO app sign injected at build time.
  /// Can be overridden via --dart-define=ZEGO_APP_SIGN=<value> at build time.
  static const String zegoAppSign =
      String.fromEnvironment('ZEGO_APP_SIGN', 
          defaultValue: '315c8c1e77f05df9744db5e50c30ea23752d60bdeb5445653c1d757db42f6ac4');

  static bool get isConfigured => zegoAppId != 0 && zegoAppSign.isNotEmpty;
}


class AppConfig {
  AppConfig._();

  // Feature flags (read-only constants for now; wire to remote config later)
  static const bool enableEmojiPicker = true; // Toggle to disable the emoji panel globally
}


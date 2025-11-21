class AppConfig {
  AppConfig._();

  // Feature flags (read-only constants for now; wire to remote config later)
  static const bool enableEmojiPicker =
      true; // Toggle to disable the emoji panel globally

  /// Temporary flag to expose tournament admin tools publicly for QA
  static const bool enablePublicTournamentAdmin = true;

  /// Temporary flag to expose team admin tools publicly for QA
  static const bool enablePublicTeamAdmin = true;

  /// Enables demo tournament content (matches, teams, stats) when backend data is missing
  static const bool enableDemoTournamentContent = true;
}

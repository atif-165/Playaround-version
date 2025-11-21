import '../modules/team/models/team_model.dart';
import '../modules/tournament/models/tournament_model.dart';

/// Central place to toggle temporary admin overrides during testing.
class AdminOverrideHelper {
  AdminOverrideHelper._();

  /// Enable full tournament admin access for everyone (temporary testing).
  static const bool enableGlobalTournamentAdmin = true;

  /// Enable team admin override for every team (keep false to target specific teams).
  static const bool enableGlobalTeamAdmin = false;

  /// Specific team identifiers that should remain publicly editable.
  static const List<String> publicTeamKeywords = [
    'royal tiger',
    'royal tigers',
    'regional sports league',
  ];

  /// Tournament names that should always allow public admin access
  /// when [enableGlobalTournamentAdmin] is turned off.
  static const List<String> publicTournamentKeywords = [
    'regional sports league',
    'royal sports league',
    'royal tiger',
    'royal tigers',
  ];

  /// Determine if a team should ignore admin-only restrictions.
  static bool allowTeamOverride(Team? team) {
    if (team == null) return false;
    if (enableGlobalTeamAdmin) return true;
    final normalizedName = team.name.toLowerCase();
    final normalizedId = team.id.toLowerCase();
    return publicTeamKeywords.any(
      (keyword) =>
          normalizedName.contains(keyword) ||
          normalizedId.contains(keyword.replaceAll(' ', '_')),
    );
  }

  /// Determine if a tournament should ignore organizer-only restrictions.
  static bool allowTournamentOverride(Tournament? tournament) {
    if (tournament == null) return false;
    if (enableGlobalTournamentAdmin) return true;
    final normalizedName = tournament.name.toLowerCase();
    return publicTournamentKeywords.any(
      (keyword) => normalizedName.contains(keyword),
    );
  }
}


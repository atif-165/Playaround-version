import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'player_match_stats.freezed.dart';
part 'player_match_stats.g.dart';

/// Model for individual player statistics in a match
@freezed
class PlayerMatchStats with _$PlayerMatchStats {
  const factory PlayerMatchStats({
    required String playerId,
    required String playerName,
    String? playerImageUrl,

    // Common stats
    @Default(0) int goals,
    @Default(0) int assists,
    @Default(0) int yellowCards,
    @Default(0) int redCards,

    // Cricket-specific stats
    @Default(0) int runs,
    @Default(0) int balls,
    @Default(0) int wickets,
    @Default(0) int catches,

    // Basketball-specific stats
    @Default(0) int points,
    @Default(0) int rebounds,
    @Default(0) int steals,

    // Generic stats
    @Default(0) int fouls,
    @Default(0) int saves,

    // Other
    Map<String, dynamic>? customStats,
  }) = _PlayerMatchStats;

  factory PlayerMatchStats.fromJson(Map<String, dynamic> json) =>
      _$PlayerMatchStatsFromJson(json);
}

/// Model for tournament team (different from regular team module)
@freezed
class TournamentTeam with _$TournamentTeam {
  const factory TournamentTeam({
    required String id,
    required String tournamentId,
    required String name,
    String? logoUrl,
    String? coachId,
    String? coachName,
    String? coachImageUrl,
    String? captainId,
    String? captainName,
    @Default([]) List<String> playerIds,
    @Default([]) List<String> playerNames,
    @Default(true) bool isActive,
    @Default(0) int wins,
    @Default(0) int losses,
    @Default(0) int draws,
    @Default(0) int points,
    @Default(0) int goalsFor,
    @Default(0) int goalsAgainst,
    DateTime? createdAt,
    String? createdBy,
  }) = _TournamentTeam;

  factory TournamentTeam.fromJson(Map<String, dynamic> json) =>
      _$TournamentTeamFromJson(json);

  factory TournamentTeam.fromFireStore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data();
    if (data == null) {
      throw Exception('Tournament team document data is null');
    }

    final safeData = Map<String, dynamic>.from(data);
    safeData['id'] ??= snapshot.id;

    return TournamentTeam.fromJson(safeData);
  }
}

/// Extension for calculating derived stats
extension PlayerMatchStatsExtensions on PlayerMatchStats {
  /// Get strike rate for cricket (runs per 100 balls)
  double get strikeRate {
    if (balls == 0) return 0.0;
    return (runs / balls) * 100;
  }

  /// Get average for cricket
  double get average {
    // This would need total dismissals, simplified here
    return runs.toDouble();
  }

  /// Check if player was man of the match
  bool get isPotentialMOM {
    return goals > 2 || runs > 50 || wickets > 3 || points > 20;
  }
}

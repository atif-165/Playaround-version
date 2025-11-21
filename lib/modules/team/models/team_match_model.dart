import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../helpers/timestamp_converter.dart';
import '../../team/models/team_model.dart';

part 'team_match_model.freezed.dart';
part 'team_match_model.g.dart';

/// Enum for match type
enum TeamMatchType {
  tournament,
  friendly,
  practice,
  league;

  String get displayName {
    switch (this) {
      case TeamMatchType.tournament:
        return 'Tournament';
      case TeamMatchType.friendly:
        return 'Friendly';
      case TeamMatchType.practice:
        return 'Practice';
      case TeamMatchType.league:
        return 'League';
    }
  }
}

/// Enum for team match status
enum TeamMatchStatus {
  scheduled,
  live,
  completed,
  cancelled;

  String get displayName {
    switch (this) {
      case TeamMatchStatus.scheduled:
        return 'Scheduled';
      case TeamMatchStatus.live:
        return 'Live';
      case TeamMatchStatus.completed:
        return 'Completed';
      case TeamMatchStatus.cancelled:
        return 'Cancelled';
    }
  }
}

/// Model for team score in a match
@freezed
class TeamScore with _$TeamScore {
  const factory TeamScore({
    required String teamId,
    required String teamName,
    String? teamLogoUrl,
    @Default(0) int score,
    Map<String, dynamic>? sportSpecificData,
  }) = _TeamScore;

  factory TeamScore.fromJson(Map<String, dynamic> json) =>
      _$TeamScoreFromJson(json);
}

/// Model for team matches (both tournament and custom)
@freezed
class TeamMatch with _$TeamMatch {
  const factory TeamMatch({
    required String id,
    required String homeTeamId,
    required String awayTeamId,
    required TeamScore homeTeam,
    required TeamScore awayTeam,
    required SportType sportType,
    @Default(TeamMatchType.friendly) TeamMatchType matchType,
    @Default(TeamMatchStatus.scheduled) TeamMatchStatus status,
    @TimestampConverter() required DateTime scheduledTime,
    @TimestampConverter() DateTime? actualStartTime,
    @TimestampConverter() DateTime? actualEndTime,
    String? tournamentId, // If this is a tournament match
    String? tournamentName,
    String? venueId,
    String? venueName,
    String? venueLocation,
    String? result, // 'Home won by 2 goals', 'Match drawn', etc.
    String? winnerTeamId,
    String? notes, // Match notes/commentary
    @TimestampConverter() required DateTime createdAt,
    String? createdBy, // User ID who created the match
    Map<String, dynamic>? metadata,
  }) = _TeamMatch;

  factory TeamMatch.fromJson(Map<String, dynamic> json) =>
      _$TeamMatchFromJson(json);

  factory TeamMatch.fromFireStore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data();
    if (data == null) {
      throw Exception('Team match document data is null');
    }

    final safeData = Map<String, dynamic>.from(data);
    safeData['id'] ??= snapshot.id;

    // Ensure required String fields are not null
    safeData['homeTeamId'] = safeData['homeTeamId']?.toString() ?? '';
    safeData['awayTeamId'] = safeData['awayTeamId']?.toString() ?? '';

    // Handle timestamp conversions
    if (safeData['scheduledTime'] != null) {
      if (safeData['scheduledTime'] is Timestamp) {
        safeData['scheduledTime'] =
            (safeData['scheduledTime'] as Timestamp).toDate().toIso8601String();
      }
    }

    if (safeData['actualStartTime'] != null) {
      if (safeData['actualStartTime'] is Timestamp) {
        safeData['actualStartTime'] = (safeData['actualStartTime'] as Timestamp)
            .toDate()
            .toIso8601String();
      }
    }

    if (safeData['actualEndTime'] != null) {
      if (safeData['actualEndTime'] is Timestamp) {
        safeData['actualEndTime'] =
            (safeData['actualEndTime'] as Timestamp).toDate().toIso8601String();
      }
    }

    if (safeData['createdAt'] != null) {
      if (safeData['createdAt'] is Timestamp) {
        safeData['createdAt'] =
            (safeData['createdAt'] as Timestamp).toDate().toIso8601String();
      }
    }

    // Sanitize homeTeam data
    if (safeData['homeTeam'] is Map<String, dynamic>) {
      final homeTeam = Map<String, dynamic>.from(
          safeData['homeTeam'] as Map<String, dynamic>);
      homeTeam['teamId'] =
          homeTeam['teamId']?.toString() ?? safeData['homeTeamId'];
      homeTeam['teamName'] = homeTeam['teamName']?.toString() ?? 'Home Team';
      safeData['homeTeam'] = homeTeam;
    }

    // Sanitize awayTeam data
    if (safeData['awayTeam'] is Map<String, dynamic>) {
      final awayTeam = Map<String, dynamic>.from(
          safeData['awayTeam'] as Map<String, dynamic>);
      awayTeam['teamId'] =
          awayTeam['teamId']?.toString() ?? safeData['awayTeamId'];
      awayTeam['teamName'] = awayTeam['teamName']?.toString() ?? 'Away Team';
      safeData['awayTeam'] = awayTeam;
    }

    return TeamMatch.fromJson(safeData);
  }
}

/// Extension methods for TeamMatch
extension TeamMatchExtensions on TeamMatch {
  /// Check if match is live
  bool get isLive => status == TeamMatchStatus.live;

  /// Check if match is completed
  bool get isCompleted => status == TeamMatchStatus.completed;

  /// Check if match is upcoming
  bool get isUpcoming => status == TeamMatchStatus.scheduled;

  /// Check if match is cancelled
  bool get isCancelled => status == TeamMatchStatus.cancelled;

  /// Get match duration
  Duration? get duration {
    if (actualStartTime == null || actualEndTime == null) return null;
    return actualEndTime!.difference(actualStartTime!);
  }

  /// Get current match time (for live matches)
  Duration? get currentMatchTime {
    if (!isLive || actualStartTime == null) return null;
    return DateTime.now().difference(actualStartTime!);
  }

  /// Check if match has started
  bool get hasStarted => actualStartTime != null;

  /// Get score difference
  int get scoreDifference => (homeTeam.score - awayTeam.score).abs();

  /// Get winning team
  TeamScore? get winningTeam {
    if (!isCompleted) return null;
    if (homeTeam.score > awayTeam.score) return homeTeam;
    if (awayTeam.score > homeTeam.score) return awayTeam;
    return null; // Draw
  }

  /// Get score summary
  String get scoreSummary =>
      '${homeTeam.teamName} ${homeTeam.score} - ${awayTeam.score} ${awayTeam.teamName}';

  /// Check if user can edit match
  bool canUserEdit(String? currentUserId) {
    return createdBy == currentUserId;
  }

  /// Get opponent team ID for a given team
  String? getOpponentTeamId(String teamId) {
    if (homeTeamId == teamId) return awayTeamId;
    if (awayTeamId == teamId) return homeTeamId;
    return null;
  }

  /// Get opponent team for a given team ID
  TeamScore? getOpponentTeam(String teamId) {
    if (homeTeamId == teamId) return awayTeam;
    if (awayTeamId == teamId) return homeTeam;
    return null;
  }

  /// Get team score for a given team ID
  TeamScore? getTeamScore(String teamId) {
    if (homeTeamId == teamId) return homeTeam;
    if (awayTeamId == teamId) return awayTeam;
    return null;
  }
}

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../models/user_profile.dart';
import '../../team/models/team_model.dart' show SportType;
import 'player_match_stats.dart';
import 'tournament_match_model.dart';

/// Represents the phase/state of a live match.
enum MatchPhase {
  upcoming,
  live,
  completed,
  cancelled,
}

/// Describes a predefined scoring template for a tournament.
enum ScoringTemplate {
  football,
  basketball,
  cricket,
  futsal,
  custom,
}

extension ScoringTemplateX on ScoringTemplate {
  String get label {
    switch (this) {
      case ScoringTemplate.football:
        return 'Football';
      case ScoringTemplate.basketball:
        return 'Basketball';
      case ScoringTemplate.cricket:
        return 'Cricket';
      case ScoringTemplate.futsal:
        return 'Futsal';
      case ScoringTemplate.custom:
        return 'Custom';
    }
  }
}

@immutable
class LivePlayer {
  const LivePlayer({
    required this.id,
    required this.name,
    required this.jerseyNumber,
    this.avatarUrl,
    this.position,
    this.stats = const {},
  });

  final String id;
  final String name;
  final int? jerseyNumber;
  final String? avatarUrl;
  final String? position;
  final Map<String, dynamic> stats;
}

@immutable
class LiveTeam {
  const LiveTeam({
    required this.id,
    required this.name,
    required this.score,
    required this.players,
    required this.primaryColor,
    required this.secondaryColor,
    this.isWinner = false,
  });

  final String id;
  final String name;
  final int score;
  final List<LivePlayer> players;
  final int primaryColor;
  final int secondaryColor;
  final bool isWinner;
}

@immutable
class LiveComment {
  const LiveComment({
    required this.id,
    required this.text,
    required this.authorId,
    required this.authorName,
    required this.timestamp,
    this.minute,
    this.isSystem = false,
    this.reactions = const {},
  });

  final String id;
  final String text;
  final String authorId;
  final String authorName;
  final DateTime timestamp;
  final int? minute;
  final bool isSystem;
  final Map<String, int> reactions;
}

@immutable
class LiveReaction {
  const LiveReaction({
    required this.id,
    required this.userId,
    required this.userName,
    this.emoji,
    this.text,
    required this.reactionType,
    required this.timestamp,
  });

  final String id;
  final String userId;
  final String userName;
  final String? emoji;
  final String? text;
  final String reactionType;
  final DateTime timestamp;
}

@immutable
class LiveMatchStat {
  const LiveMatchStat({
    required this.label,
    required this.valueLeft,
    required this.valueRight,
  });

  final String label;
  final String valueLeft;
  final String valueRight;
}

@immutable
class LiveMatch {
  const LiveMatch({
    required this.id,
    required this.tournamentId,
    required this.phase,
    required this.template,
    required this.teamA,
    required this.teamB,
    required this.startTime,
    required this.venueName,
    required this.commentary,
    required this.reactions,
    required this.matchStats,
    required this.playerStats,
    this.metadata,
    this.admins = const [],
    this.lockedAt,
    this.winnerTeamId,
    this.countdownSeconds = 0,
    this.currentMinute = 0,
  });

  final String id;
  final String tournamentId;
  final MatchPhase phase;
  final ScoringTemplate template;
  final LiveTeam teamA;
  final LiveTeam teamB;
  final DateTime startTime;
  final String venueName;
  final List<LiveComment> commentary;
  final List<LiveReaction> reactions;
  final List<LiveMatchStat> matchStats;
  final List<PlayerMatchStats> playerStats;
  final Map<String, dynamic>? metadata;
  final List<String> admins;
  final DateTime? lockedAt;
  final String? winnerTeamId;
  final int countdownSeconds;
  final int currentMinute;

  bool get isLive => phase == MatchPhase.live;
  bool get isUpcoming => phase == MatchPhase.upcoming;
  bool get isCompleted => phase == MatchPhase.completed;
  bool get isLocked => lockedAt != null;
}

class LiveMatchMapper {
  static LiveMatch fromTournamentMatch(TournamentMatch match) {
    final phase = _derivePhase(match.status);
    final template = _deriveTemplate(match.sportType);

    return LiveMatch(
      id: match.id,
      tournamentId: match.tournamentId ?? 'unknown',
      phase: phase,
      template: template,
      teamA: _mapTeam(match.team1, match.team1PlayerStats, isWinner: match.winnerTeamId == match.team1.teamId),
      teamB: _mapTeam(match.team2, match.team2PlayerStats, isWinner: match.winnerTeamId == match.team2.teamId),
      startTime: match.scheduledTime,
      venueName: match.venueName ?? 'TBC',
      commentary: match.commentary
          .map(
            (entry) => LiveComment(
              id: entry.id,
              text: entry.text,
              authorId: 'system',
              authorName: 'Match Centre',
              timestamp: entry.timestamp,
              minute: entry.minute != null ? int.tryParse(entry.minute!) : null,
              isSystem: true,
            ),
          )
          .toList(),
      reactions: const [],
      matchStats: _buildMatchStats(match),
      playerStats: [
        ...match.team1PlayerStats,
        ...match.team2PlayerStats,
      ],
      metadata:
          match.metadata != null ? Map<String, dynamic>.from(match.metadata!) : null,
      admins: const [],
      lockedAt: match.actualEndTime,
      winnerTeamId: match.winnerTeamId,
      countdownSeconds: match.scheduledTime.difference(DateTime.now()).inSeconds.clamp(0, 1 << 31),
      currentMinute: match.currentMatchTime?.inMinutes ?? 0,
    );
  }

  static LiveTeam _mapTeam(
    TeamMatchScore team,
    List<PlayerMatchStats> stats, {
    bool isWinner = false,
  }) {
    final players = stats.isNotEmpty
        ? stats
            .map(
              (s) => LivePlayer(
                id: s.playerId,
                name: s.playerName,
                jerseyNumber: null,
                position: null,
                avatarUrl: null,
                stats: _playerStatMap(s),
              ),
            )
            .toList()
        : team.playerIds
            .asMap()
            .map(
              (index, playerId) => MapEntry(
                index,
                LivePlayer(
                  id: playerId,
                  name: 'Player ${index + 1}',
                  jerseyNumber: 10 + index,
                  stats: const {},
                ),
              ),
            )
            .values
            .toList();

    return LiveTeam(
      id: team.teamId,
      name: team.teamName,
      score: team.score,
      players: players,
      primaryColor: Colors.orange.value,
      secondaryColor: Colors.deepOrange.value,
      isWinner: isWinner,
    );
  }

  static List<LiveMatchStat> _buildMatchStats(TournamentMatch match) {
    return [
      LiveMatchStat(
        label: 'Goals',
        valueLeft: match.team1.score.toString(),
        valueRight: match.team2.score.toString(),
      ),
      LiveMatchStat(
        label: 'Attempts',
        valueLeft: '${_sportValue(match.team1.sportSpecificData, 'attempts')}',
        valueRight: '${_sportValue(match.team2.sportSpecificData, 'attempts')}',
      ),
      LiveMatchStat(
        label: 'Cards',
        valueLeft: '${_sportValue(match.team1.sportSpecificData, 'cards')}',
        valueRight: '${_sportValue(match.team2.sportSpecificData, 'cards')}',
      ),
    ];
  }

  static MatchPhase _derivePhase(TournamentMatchStatus status) {
    switch (status) {
      case TournamentMatchStatus.scheduled:
        return MatchPhase.upcoming;
      case TournamentMatchStatus.live:
        return MatchPhase.live;
      case TournamentMatchStatus.completed:
        return MatchPhase.completed;
      case TournamentMatchStatus.cancelled:
        return MatchPhase.cancelled;
    }
  }

  static ScoringTemplate _deriveTemplate(SportType? type) {
    if (type == null) return ScoringTemplate.custom;
    switch (type) {
      case SportType.football:
      case SportType.soccer:
        return ScoringTemplate.football;
      case SportType.basketball:
        return ScoringTemplate.basketball;
      case SportType.cricket:
        return ScoringTemplate.cricket;
      case SportType.baseball:
      case SportType.badminton:
      case SportType.tennis:
      case SportType.volleyball:
      case SportType.hockey:
      case SportType.rugby:
      case SportType.swimming:
      case SportType.running:
      case SportType.cycling:
      case SportType.other:
        return ScoringTemplate.custom;
    }
  }

  static num _sportValue(Map<String, dynamic>? data, String key) {
    if (data == null) return 0;
    final value = data[key];
    if (value is num) return value;
    if (value is String) {
      return num.tryParse(value) ?? 0;
    }
    return 0;
  }

  static Map<String, dynamic> _playerStatMap(PlayerMatchStats stats) {
    final custom = stats.customStats;
    if (custom != null && custom.isNotEmpty) {
      return Map<String, dynamic>.from(custom);
    }

    // Fallback: no predefined metrics, return empty map so UI can show
    // "No metrics yet" until admins add manual entries.
    return const {};
  }
}


// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'player_match_stats.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PlayerMatchStatsImpl _$$PlayerMatchStatsImplFromJson(
        Map<String, dynamic> json) =>
    _$PlayerMatchStatsImpl(
      playerId: json['playerId'] as String,
      playerName: json['playerName'] as String,
      playerImageUrl: json['playerImageUrl'] as String?,
      goals: (json['goals'] as num?)?.toInt() ?? 0,
      assists: (json['assists'] as num?)?.toInt() ?? 0,
      yellowCards: (json['yellowCards'] as num?)?.toInt() ?? 0,
      redCards: (json['redCards'] as num?)?.toInt() ?? 0,
      runs: (json['runs'] as num?)?.toInt() ?? 0,
      balls: (json['balls'] as num?)?.toInt() ?? 0,
      wickets: (json['wickets'] as num?)?.toInt() ?? 0,
      catches: (json['catches'] as num?)?.toInt() ?? 0,
      points: (json['points'] as num?)?.toInt() ?? 0,
      rebounds: (json['rebounds'] as num?)?.toInt() ?? 0,
      steals: (json['steals'] as num?)?.toInt() ?? 0,
      fouls: (json['fouls'] as num?)?.toInt() ?? 0,
      saves: (json['saves'] as num?)?.toInt() ?? 0,
      customStats: json['customStats'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$$PlayerMatchStatsImplToJson(
        _$PlayerMatchStatsImpl instance) =>
    <String, dynamic>{
      'playerId': instance.playerId,
      'playerName': instance.playerName,
      'playerImageUrl': instance.playerImageUrl,
      'goals': instance.goals,
      'assists': instance.assists,
      'yellowCards': instance.yellowCards,
      'redCards': instance.redCards,
      'runs': instance.runs,
      'balls': instance.balls,
      'wickets': instance.wickets,
      'catches': instance.catches,
      'points': instance.points,
      'rebounds': instance.rebounds,
      'steals': instance.steals,
      'fouls': instance.fouls,
      'saves': instance.saves,
      'customStats': instance.customStats,
    };

_$TournamentTeamImpl _$$TournamentTeamImplFromJson(Map<String, dynamic> json) =>
    _$TournamentTeamImpl(
      id: json['id'] as String,
      tournamentId: json['tournamentId'] as String,
      name: json['name'] as String,
      logoUrl: json['logoUrl'] as String?,
      coachId: json['coachId'] as String?,
      coachName: json['coachName'] as String?,
      coachImageUrl: json['coachImageUrl'] as String?,
      captainId: json['captainId'] as String?,
      captainName: json['captainName'] as String?,
      playerIds: (json['playerIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      playerNames: (json['playerNames'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      isActive: json['isActive'] as bool? ?? true,
      wins: (json['wins'] as num?)?.toInt() ?? 0,
      losses: (json['losses'] as num?)?.toInt() ?? 0,
      draws: (json['draws'] as num?)?.toInt() ?? 0,
      points: (json['points'] as num?)?.toInt() ?? 0,
      goalsFor: (json['goalsFor'] as num?)?.toInt() ?? 0,
      goalsAgainst: (json['goalsAgainst'] as num?)?.toInt() ?? 0,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      createdBy: json['createdBy'] as String?,
    );

Map<String, dynamic> _$$TournamentTeamImplToJson(
        _$TournamentTeamImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'tournamentId': instance.tournamentId,
      'name': instance.name,
      'logoUrl': instance.logoUrl,
      'coachId': instance.coachId,
      'coachName': instance.coachName,
      'coachImageUrl': instance.coachImageUrl,
      'captainId': instance.captainId,
      'captainName': instance.captainName,
      'playerIds': instance.playerIds,
      'playerNames': instance.playerNames,
      'isActive': instance.isActive,
      'wins': instance.wins,
      'losses': instance.losses,
      'draws': instance.draws,
      'points': instance.points,
      'goalsFor': instance.goalsFor,
      'goalsAgainst': instance.goalsAgainst,
      'createdAt': instance.createdAt?.toIso8601String(),
      'createdBy': instance.createdBy,
    };

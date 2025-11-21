// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'team_match_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TeamScoreImpl _$$TeamScoreImplFromJson(Map<String, dynamic> json) =>
    _$TeamScoreImpl(
      teamId: json['teamId'] as String,
      teamName: json['teamName'] as String,
      teamLogoUrl: json['teamLogoUrl'] as String?,
      score: (json['score'] as num?)?.toInt() ?? 0,
      sportSpecificData: json['sportSpecificData'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$$TeamScoreImplToJson(_$TeamScoreImpl instance) =>
    <String, dynamic>{
      'teamId': instance.teamId,
      'teamName': instance.teamName,
      'teamLogoUrl': instance.teamLogoUrl,
      'score': instance.score,
      'sportSpecificData': instance.sportSpecificData,
    };

_$TeamMatchImpl _$$TeamMatchImplFromJson(Map<String, dynamic> json) =>
    _$TeamMatchImpl(
      id: json['id'] as String,
      homeTeamId: json['homeTeamId'] as String,
      awayTeamId: json['awayTeamId'] as String,
      homeTeam: TeamScore.fromJson(json['homeTeam'] as Map<String, dynamic>),
      awayTeam: TeamScore.fromJson(json['awayTeam'] as Map<String, dynamic>),
      sportType: $enumDecode(_$SportTypeEnumMap, json['sportType']),
      matchType:
          $enumDecodeNullable(_$TeamMatchTypeEnumMap, json['matchType']) ??
              TeamMatchType.friendly,
      status: $enumDecodeNullable(_$TeamMatchStatusEnumMap, json['status']) ??
          TeamMatchStatus.scheduled,
      scheduledTime: DateTime.parse(json['scheduledTime'] as String),
      actualStartTime:
          const TimestampConverter().fromJson(json['actualStartTime']),
      actualEndTime: const TimestampConverter().fromJson(json['actualEndTime']),
      tournamentId: json['tournamentId'] as String?,
      tournamentName: json['tournamentName'] as String?,
      venueId: json['venueId'] as String?,
      venueName: json['venueName'] as String?,
      venueLocation: json['venueLocation'] as String?,
      result: json['result'] as String?,
      winnerTeamId: json['winnerTeamId'] as String?,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      createdBy: json['createdBy'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$$TeamMatchImplToJson(_$TeamMatchImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'homeTeamId': instance.homeTeamId,
      'awayTeamId': instance.awayTeamId,
      'homeTeam': instance.homeTeam,
      'awayTeam': instance.awayTeam,
      'sportType': _$SportTypeEnumMap[instance.sportType]!,
      'matchType': _$TeamMatchTypeEnumMap[instance.matchType]!,
      'status': _$TeamMatchStatusEnumMap[instance.status]!,
      'scheduledTime': instance.scheduledTime.toIso8601String(),
      'actualStartTime':
          const TimestampConverter().toJson(instance.actualStartTime),
      'actualEndTime':
          const TimestampConverter().toJson(instance.actualEndTime),
      'tournamentId': instance.tournamentId,
      'tournamentName': instance.tournamentName,
      'venueId': instance.venueId,
      'venueName': instance.venueName,
      'venueLocation': instance.venueLocation,
      'result': instance.result,
      'winnerTeamId': instance.winnerTeamId,
      'notes': instance.notes,
      'createdAt': instance.createdAt.toIso8601String(),
      'createdBy': instance.createdBy,
      'metadata': instance.metadata,
    };

const _$SportTypeEnumMap = {
  SportType.cricket: 'cricket',
  SportType.football: 'football',
  SportType.soccer: 'soccer',
  SportType.basketball: 'basketball',
  SportType.volleyball: 'volleyball',
  SportType.tennis: 'tennis',
  SportType.badminton: 'badminton',
  SportType.hockey: 'hockey',
  SportType.rugby: 'rugby',
  SportType.baseball: 'baseball',
  SportType.swimming: 'swimming',
  SportType.running: 'running',
  SportType.cycling: 'cycling',
  SportType.other: 'other',
};

const _$TeamMatchTypeEnumMap = {
  TeamMatchType.tournament: 'tournament',
  TeamMatchType.friendly: 'friendly',
  TeamMatchType.practice: 'practice',
  TeamMatchType.league: 'league',
};

const _$TeamMatchStatusEnumMap = {
  TeamMatchStatus.scheduled: 'scheduled',
  TeamMatchStatus.live: 'live',
  TeamMatchStatus.completed: 'completed',
  TeamMatchStatus.cancelled: 'cancelled',
};

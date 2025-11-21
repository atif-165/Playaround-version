// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tournament_match_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CommentaryEntryImpl _$$CommentaryEntryImplFromJson(
        Map<String, dynamic> json) =>
    _$CommentaryEntryImpl(
      id: json['id'] as String,
      text: json['text'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      minute: json['minute'] as String?,
      playerName: json['playerName'] as String?,
      eventType: json['eventType'] as String?,
    );

Map<String, dynamic> _$$CommentaryEntryImplToJson(
        _$CommentaryEntryImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'text': instance.text,
      'timestamp': instance.timestamp.toIso8601String(),
      'minute': instance.minute,
      'playerName': instance.playerName,
      'eventType': instance.eventType,
    };

_$TeamMatchScoreImpl _$$TeamMatchScoreImplFromJson(Map<String, dynamic> json) =>
    _$TeamMatchScoreImpl(
      teamId: json['teamId'] as String,
      teamName: json['teamName'] as String,
      teamLogoUrl: json['teamLogoUrl'] as String?,
      score: (json['score'] as num?)?.toInt() ?? 0,
      sportSpecificData: json['sportSpecificData'] as Map<String, dynamic>?,
      playerIds: (json['playerIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$TeamMatchScoreImplToJson(
        _$TeamMatchScoreImpl instance) =>
    <String, dynamic>{
      'teamId': instance.teamId,
      'teamName': instance.teamName,
      'teamLogoUrl': instance.teamLogoUrl,
      'score': instance.score,
      'sportSpecificData': instance.sportSpecificData,
      'playerIds': instance.playerIds,
    };

_$TournamentMatchImpl _$$TournamentMatchImplFromJson(
        Map<String, dynamic> json) =>
    _$TournamentMatchImpl(
      id: json['id'] as String,
      tournamentId: json['tournamentId'] as String,
      tournamentName: json['tournamentName'] as String,
      sportType: $enumDecode(_$SportTypeEnumMap, json['sportType']),
      team1: TeamMatchScore.fromJson(json['team1'] as Map<String, dynamic>),
      team2: TeamMatchScore.fromJson(json['team2'] as Map<String, dynamic>),
      matchNumber: json['matchNumber'] as String,
      round: json['round'] as String?,
      scheduledTime: DateTime.parse(json['scheduledTime'] as String),
      actualStartTime:
          const TimestampConverter().fromJson(json['actualStartTime']),
      actualEndTime: const TimestampConverter().fromJson(json['actualEndTime']),
      status:
          $enumDecodeNullable(_$TournamentMatchStatusEnumMap, json['status']) ??
              TournamentMatchStatus.scheduled,
      commentary: (json['commentary'] as List<dynamic>?)
              ?.map((e) => CommentaryEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      result: json['result'] as String?,
      winnerTeamId: json['winnerTeamId'] as String?,
      team1PlayerStats: (json['team1PlayerStats'] as List<dynamic>?)
              ?.map((e) => PlayerMatchStats.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      team2PlayerStats: (json['team2PlayerStats'] as List<dynamic>?)
              ?.map((e) => PlayerMatchStats.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      manOfTheMatch: json['manOfTheMatch'] as String?,
      team1CoachId: json['team1CoachId'] as String?,
      team1CoachName: json['team1CoachName'] as String?,
      team2CoachId: json['team2CoachId'] as String?,
      team2CoachName: json['team2CoachName'] as String?,
      venueId: json['venueId'] as String?,
      venueName: json['venueName'] as String?,
      venueLocation: json['venueLocation'] as String?,
      backgroundImageUrl: json['backgroundImageUrl'] as String?,
      createdAt: const TimestampConverter().fromJson(json['createdAt']),
      updatedAt: const TimestampConverter().fromJson(json['updatedAt']),
      createdBy: json['createdBy'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$$TournamentMatchImplToJson(
        _$TournamentMatchImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'tournamentId': instance.tournamentId,
      'tournamentName': instance.tournamentName,
      'sportType': _$SportTypeEnumMap[instance.sportType]!,
      'team1': instance.team1,
      'team2': instance.team2,
      'matchNumber': instance.matchNumber,
      'round': instance.round,
      'scheduledTime': instance.scheduledTime.toIso8601String(),
      'actualStartTime':
          const TimestampConverter().toJson(instance.actualStartTime),
      'actualEndTime':
          const TimestampConverter().toJson(instance.actualEndTime),
      'status': _$TournamentMatchStatusEnumMap[instance.status]!,
      'commentary': instance.commentary,
      'result': instance.result,
      'winnerTeamId': instance.winnerTeamId,
      'team1PlayerStats': instance.team1PlayerStats,
      'team2PlayerStats': instance.team2PlayerStats,
      'manOfTheMatch': instance.manOfTheMatch,
      'team1CoachId': instance.team1CoachId,
      'team1CoachName': instance.team1CoachName,
      'team2CoachId': instance.team2CoachId,
      'team2CoachName': instance.team2CoachName,
      'venueId': instance.venueId,
      'venueName': instance.venueName,
      'venueLocation': instance.venueLocation,
      'backgroundImageUrl': instance.backgroundImageUrl,
      'createdAt': const TimestampConverter().toJson(instance.createdAt),
      'updatedAt': const TimestampConverter().toJson(instance.updatedAt),
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

const _$TournamentMatchStatusEnumMap = {
  TournamentMatchStatus.scheduled: 'scheduled',
  TournamentMatchStatus.live: 'live',
  TournamentMatchStatus.completed: 'completed',
  TournamentMatchStatus.cancelled: 'cancelled',
};

_$TournamentJoinRequestImpl _$$TournamentJoinRequestImplFromJson(
        Map<String, dynamic> json) =>
    _$TournamentJoinRequestImpl(
      id: json['id'] as String,
      tournamentId: json['tournamentId'] as String,
      requesterId: json['requesterId'] as String,
      requesterName: json['requesterName'] as String,
      requesterProfileUrl: json['requesterProfileUrl'] as String?,
      isTeamRequest: json['isTeamRequest'] as bool,
      teamId: json['teamId'] as String?,
      teamName: json['teamName'] as String?,
      teamLogoUrl: json['teamLogoUrl'] as String?,
      sport: json['sport'] as String?,
      position: json['position'] as String?,
      skillLevel: (json['skillLevel'] as num?)?.toInt(),
      bio: json['bio'] as String?,
      formResponses: json['formResponses'] as Map<String, dynamic>? ?? const {},
      storagePath: json['storagePath'] as String?,
      status: json['status'] as String? ?? 'pending',
      reviewedBy: json['reviewedBy'] as String?,
      reviewedAt: const TimestampConverter().fromJson(json['reviewedAt']),
      reviewNote: json['reviewNote'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$$TournamentJoinRequestImplToJson(
        _$TournamentJoinRequestImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'tournamentId': instance.tournamentId,
      'requesterId': instance.requesterId,
      'requesterName': instance.requesterName,
      'requesterProfileUrl': instance.requesterProfileUrl,
      'isTeamRequest': instance.isTeamRequest,
      'teamId': instance.teamId,
      'teamName': instance.teamName,
      'teamLogoUrl': instance.teamLogoUrl,
      'sport': instance.sport,
      'position': instance.position,
      'skillLevel': instance.skillLevel,
      'bio': instance.bio,
      'formResponses': instance.formResponses,
      'storagePath': instance.storagePath,
      'status': instance.status,
      'reviewedBy': instance.reviewedBy,
      'reviewedAt': const TimestampConverter().toJson(instance.reviewedAt),
      'reviewNote': instance.reviewNote,
      'createdAt': instance.createdAt.toIso8601String(),
      'metadata': instance.metadata,
    };

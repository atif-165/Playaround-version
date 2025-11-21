// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'team_match_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

TeamScore _$TeamScoreFromJson(Map<String, dynamic> json) {
  return _TeamScore.fromJson(json);
}

/// @nodoc
mixin _$TeamScore {
  String get teamId => throw _privateConstructorUsedError;
  String get teamName => throw _privateConstructorUsedError;
  String? get teamLogoUrl => throw _privateConstructorUsedError;
  int get score => throw _privateConstructorUsedError;
  Map<String, dynamic>? get sportSpecificData =>
      throw _privateConstructorUsedError;

  /// Serializes this TeamScore to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TeamScore
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TeamScoreCopyWith<TeamScore> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TeamScoreCopyWith<$Res> {
  factory $TeamScoreCopyWith(TeamScore value, $Res Function(TeamScore) then) =
      _$TeamScoreCopyWithImpl<$Res, TeamScore>;
  @useResult
  $Res call(
      {String teamId,
      String teamName,
      String? teamLogoUrl,
      int score,
      Map<String, dynamic>? sportSpecificData});
}

/// @nodoc
class _$TeamScoreCopyWithImpl<$Res, $Val extends TeamScore>
    implements $TeamScoreCopyWith<$Res> {
  _$TeamScoreCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TeamScore
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? teamId = null,
    Object? teamName = null,
    Object? teamLogoUrl = freezed,
    Object? score = null,
    Object? sportSpecificData = freezed,
  }) {
    return _then(_value.copyWith(
      teamId: null == teamId
          ? _value.teamId
          : teamId // ignore: cast_nullable_to_non_nullable
              as String,
      teamName: null == teamName
          ? _value.teamName
          : teamName // ignore: cast_nullable_to_non_nullable
              as String,
      teamLogoUrl: freezed == teamLogoUrl
          ? _value.teamLogoUrl
          : teamLogoUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      score: null == score
          ? _value.score
          : score // ignore: cast_nullable_to_non_nullable
              as int,
      sportSpecificData: freezed == sportSpecificData
          ? _value.sportSpecificData
          : sportSpecificData // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$TeamScoreImplCopyWith<$Res>
    implements $TeamScoreCopyWith<$Res> {
  factory _$$TeamScoreImplCopyWith(
          _$TeamScoreImpl value, $Res Function(_$TeamScoreImpl) then) =
      __$$TeamScoreImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String teamId,
      String teamName,
      String? teamLogoUrl,
      int score,
      Map<String, dynamic>? sportSpecificData});
}

/// @nodoc
class __$$TeamScoreImplCopyWithImpl<$Res>
    extends _$TeamScoreCopyWithImpl<$Res, _$TeamScoreImpl>
    implements _$$TeamScoreImplCopyWith<$Res> {
  __$$TeamScoreImplCopyWithImpl(
      _$TeamScoreImpl _value, $Res Function(_$TeamScoreImpl) _then)
      : super(_value, _then);

  /// Create a copy of TeamScore
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? teamId = null,
    Object? teamName = null,
    Object? teamLogoUrl = freezed,
    Object? score = null,
    Object? sportSpecificData = freezed,
  }) {
    return _then(_$TeamScoreImpl(
      teamId: null == teamId
          ? _value.teamId
          : teamId // ignore: cast_nullable_to_non_nullable
              as String,
      teamName: null == teamName
          ? _value.teamName
          : teamName // ignore: cast_nullable_to_non_nullable
              as String,
      teamLogoUrl: freezed == teamLogoUrl
          ? _value.teamLogoUrl
          : teamLogoUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      score: null == score
          ? _value.score
          : score // ignore: cast_nullable_to_non_nullable
              as int,
      sportSpecificData: freezed == sportSpecificData
          ? _value._sportSpecificData
          : sportSpecificData // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$TeamScoreImpl implements _TeamScore {
  const _$TeamScoreImpl(
      {required this.teamId,
      required this.teamName,
      this.teamLogoUrl,
      this.score = 0,
      final Map<String, dynamic>? sportSpecificData})
      : _sportSpecificData = sportSpecificData;

  factory _$TeamScoreImpl.fromJson(Map<String, dynamic> json) =>
      _$$TeamScoreImplFromJson(json);

  @override
  final String teamId;
  @override
  final String teamName;
  @override
  final String? teamLogoUrl;
  @override
  @JsonKey()
  final int score;
  final Map<String, dynamic>? _sportSpecificData;
  @override
  Map<String, dynamic>? get sportSpecificData {
    final value = _sportSpecificData;
    if (value == null) return null;
    if (_sportSpecificData is EqualUnmodifiableMapView)
      return _sportSpecificData;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  String toString() {
    return 'TeamScore(teamId: $teamId, teamName: $teamName, teamLogoUrl: $teamLogoUrl, score: $score, sportSpecificData: $sportSpecificData)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TeamScoreImpl &&
            (identical(other.teamId, teamId) || other.teamId == teamId) &&
            (identical(other.teamName, teamName) ||
                other.teamName == teamName) &&
            (identical(other.teamLogoUrl, teamLogoUrl) ||
                other.teamLogoUrl == teamLogoUrl) &&
            (identical(other.score, score) || other.score == score) &&
            const DeepCollectionEquality()
                .equals(other._sportSpecificData, _sportSpecificData));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, teamId, teamName, teamLogoUrl,
      score, const DeepCollectionEquality().hash(_sportSpecificData));

  /// Create a copy of TeamScore
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TeamScoreImplCopyWith<_$TeamScoreImpl> get copyWith =>
      __$$TeamScoreImplCopyWithImpl<_$TeamScoreImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TeamScoreImplToJson(
      this,
    );
  }
}

abstract class _TeamScore implements TeamScore {
  const factory _TeamScore(
      {required final String teamId,
      required final String teamName,
      final String? teamLogoUrl,
      final int score,
      final Map<String, dynamic>? sportSpecificData}) = _$TeamScoreImpl;

  factory _TeamScore.fromJson(Map<String, dynamic> json) =
      _$TeamScoreImpl.fromJson;

  @override
  String get teamId;
  @override
  String get teamName;
  @override
  String? get teamLogoUrl;
  @override
  int get score;
  @override
  Map<String, dynamic>? get sportSpecificData;

  /// Create a copy of TeamScore
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TeamScoreImplCopyWith<_$TeamScoreImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

TeamMatch _$TeamMatchFromJson(Map<String, dynamic> json) {
  return _TeamMatch.fromJson(json);
}

/// @nodoc
mixin _$TeamMatch {
  String get id => throw _privateConstructorUsedError;
  String get homeTeamId => throw _privateConstructorUsedError;
  String get awayTeamId => throw _privateConstructorUsedError;
  TeamScore get homeTeam => throw _privateConstructorUsedError;
  TeamScore get awayTeam => throw _privateConstructorUsedError;
  SportType get sportType => throw _privateConstructorUsedError;
  TeamMatchType get matchType => throw _privateConstructorUsedError;
  TeamMatchStatus get status => throw _privateConstructorUsedError;
  @TimestampConverter()
  DateTime get scheduledTime => throw _privateConstructorUsedError;
  @TimestampConverter()
  DateTime? get actualStartTime => throw _privateConstructorUsedError;
  @TimestampConverter()
  DateTime? get actualEndTime => throw _privateConstructorUsedError;
  String? get tournamentId =>
      throw _privateConstructorUsedError; // If this is a tournament match
  String? get tournamentName => throw _privateConstructorUsedError;
  String? get venueId => throw _privateConstructorUsedError;
  String? get venueName => throw _privateConstructorUsedError;
  String? get venueLocation => throw _privateConstructorUsedError;
  String? get result =>
      throw _privateConstructorUsedError; // 'Home won by 2 goals', 'Match drawn', etc.
  String? get winnerTeamId => throw _privateConstructorUsedError;
  String? get notes =>
      throw _privateConstructorUsedError; // Match notes/commentary
  @TimestampConverter()
  DateTime get createdAt => throw _privateConstructorUsedError;
  String? get createdBy =>
      throw _privateConstructorUsedError; // User ID who created the match
  Map<String, dynamic>? get metadata => throw _privateConstructorUsedError;

  /// Serializes this TeamMatch to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TeamMatch
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TeamMatchCopyWith<TeamMatch> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TeamMatchCopyWith<$Res> {
  factory $TeamMatchCopyWith(TeamMatch value, $Res Function(TeamMatch) then) =
      _$TeamMatchCopyWithImpl<$Res, TeamMatch>;
  @useResult
  $Res call(
      {String id,
      String homeTeamId,
      String awayTeamId,
      TeamScore homeTeam,
      TeamScore awayTeam,
      SportType sportType,
      TeamMatchType matchType,
      TeamMatchStatus status,
      @TimestampConverter() DateTime scheduledTime,
      @TimestampConverter() DateTime? actualStartTime,
      @TimestampConverter() DateTime? actualEndTime,
      String? tournamentId,
      String? tournamentName,
      String? venueId,
      String? venueName,
      String? venueLocation,
      String? result,
      String? winnerTeamId,
      String? notes,
      @TimestampConverter() DateTime createdAt,
      String? createdBy,
      Map<String, dynamic>? metadata});

  $TeamScoreCopyWith<$Res> get homeTeam;
  $TeamScoreCopyWith<$Res> get awayTeam;
}

/// @nodoc
class _$TeamMatchCopyWithImpl<$Res, $Val extends TeamMatch>
    implements $TeamMatchCopyWith<$Res> {
  _$TeamMatchCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TeamMatch
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? homeTeamId = null,
    Object? awayTeamId = null,
    Object? homeTeam = null,
    Object? awayTeam = null,
    Object? sportType = null,
    Object? matchType = null,
    Object? status = null,
    Object? scheduledTime = null,
    Object? actualStartTime = freezed,
    Object? actualEndTime = freezed,
    Object? tournamentId = freezed,
    Object? tournamentName = freezed,
    Object? venueId = freezed,
    Object? venueName = freezed,
    Object? venueLocation = freezed,
    Object? result = freezed,
    Object? winnerTeamId = freezed,
    Object? notes = freezed,
    Object? createdAt = null,
    Object? createdBy = freezed,
    Object? metadata = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      homeTeamId: null == homeTeamId
          ? _value.homeTeamId
          : homeTeamId // ignore: cast_nullable_to_non_nullable
              as String,
      awayTeamId: null == awayTeamId
          ? _value.awayTeamId
          : awayTeamId // ignore: cast_nullable_to_non_nullable
              as String,
      homeTeam: null == homeTeam
          ? _value.homeTeam
          : homeTeam // ignore: cast_nullable_to_non_nullable
              as TeamScore,
      awayTeam: null == awayTeam
          ? _value.awayTeam
          : awayTeam // ignore: cast_nullable_to_non_nullable
              as TeamScore,
      sportType: null == sportType
          ? _value.sportType
          : sportType // ignore: cast_nullable_to_non_nullable
              as SportType,
      matchType: null == matchType
          ? _value.matchType
          : matchType // ignore: cast_nullable_to_non_nullable
              as TeamMatchType,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as TeamMatchStatus,
      scheduledTime: null == scheduledTime
          ? _value.scheduledTime
          : scheduledTime // ignore: cast_nullable_to_non_nullable
              as DateTime,
      actualStartTime: freezed == actualStartTime
          ? _value.actualStartTime
          : actualStartTime // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      actualEndTime: freezed == actualEndTime
          ? _value.actualEndTime
          : actualEndTime // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      tournamentId: freezed == tournamentId
          ? _value.tournamentId
          : tournamentId // ignore: cast_nullable_to_non_nullable
              as String?,
      tournamentName: freezed == tournamentName
          ? _value.tournamentName
          : tournamentName // ignore: cast_nullable_to_non_nullable
              as String?,
      venueId: freezed == venueId
          ? _value.venueId
          : venueId // ignore: cast_nullable_to_non_nullable
              as String?,
      venueName: freezed == venueName
          ? _value.venueName
          : venueName // ignore: cast_nullable_to_non_nullable
              as String?,
      venueLocation: freezed == venueLocation
          ? _value.venueLocation
          : venueLocation // ignore: cast_nullable_to_non_nullable
              as String?,
      result: freezed == result
          ? _value.result
          : result // ignore: cast_nullable_to_non_nullable
              as String?,
      winnerTeamId: freezed == winnerTeamId
          ? _value.winnerTeamId
          : winnerTeamId // ignore: cast_nullable_to_non_nullable
              as String?,
      notes: freezed == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      createdBy: freezed == createdBy
          ? _value.createdBy
          : createdBy // ignore: cast_nullable_to_non_nullable
              as String?,
      metadata: freezed == metadata
          ? _value.metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
    ) as $Val);
  }

  /// Create a copy of TeamMatch
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $TeamScoreCopyWith<$Res> get homeTeam {
    return $TeamScoreCopyWith<$Res>(_value.homeTeam, (value) {
      return _then(_value.copyWith(homeTeam: value) as $Val);
    });
  }

  /// Create a copy of TeamMatch
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $TeamScoreCopyWith<$Res> get awayTeam {
    return $TeamScoreCopyWith<$Res>(_value.awayTeam, (value) {
      return _then(_value.copyWith(awayTeam: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$TeamMatchImplCopyWith<$Res>
    implements $TeamMatchCopyWith<$Res> {
  factory _$$TeamMatchImplCopyWith(
          _$TeamMatchImpl value, $Res Function(_$TeamMatchImpl) then) =
      __$$TeamMatchImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String homeTeamId,
      String awayTeamId,
      TeamScore homeTeam,
      TeamScore awayTeam,
      SportType sportType,
      TeamMatchType matchType,
      TeamMatchStatus status,
      @TimestampConverter() DateTime scheduledTime,
      @TimestampConverter() DateTime? actualStartTime,
      @TimestampConverter() DateTime? actualEndTime,
      String? tournamentId,
      String? tournamentName,
      String? venueId,
      String? venueName,
      String? venueLocation,
      String? result,
      String? winnerTeamId,
      String? notes,
      @TimestampConverter() DateTime createdAt,
      String? createdBy,
      Map<String, dynamic>? metadata});

  @override
  $TeamScoreCopyWith<$Res> get homeTeam;
  @override
  $TeamScoreCopyWith<$Res> get awayTeam;
}

/// @nodoc
class __$$TeamMatchImplCopyWithImpl<$Res>
    extends _$TeamMatchCopyWithImpl<$Res, _$TeamMatchImpl>
    implements _$$TeamMatchImplCopyWith<$Res> {
  __$$TeamMatchImplCopyWithImpl(
      _$TeamMatchImpl _value, $Res Function(_$TeamMatchImpl) _then)
      : super(_value, _then);

  /// Create a copy of TeamMatch
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? homeTeamId = null,
    Object? awayTeamId = null,
    Object? homeTeam = null,
    Object? awayTeam = null,
    Object? sportType = null,
    Object? matchType = null,
    Object? status = null,
    Object? scheduledTime = null,
    Object? actualStartTime = freezed,
    Object? actualEndTime = freezed,
    Object? tournamentId = freezed,
    Object? tournamentName = freezed,
    Object? venueId = freezed,
    Object? venueName = freezed,
    Object? venueLocation = freezed,
    Object? result = freezed,
    Object? winnerTeamId = freezed,
    Object? notes = freezed,
    Object? createdAt = null,
    Object? createdBy = freezed,
    Object? metadata = freezed,
  }) {
    return _then(_$TeamMatchImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      homeTeamId: null == homeTeamId
          ? _value.homeTeamId
          : homeTeamId // ignore: cast_nullable_to_non_nullable
              as String,
      awayTeamId: null == awayTeamId
          ? _value.awayTeamId
          : awayTeamId // ignore: cast_nullable_to_non_nullable
              as String,
      homeTeam: null == homeTeam
          ? _value.homeTeam
          : homeTeam // ignore: cast_nullable_to_non_nullable
              as TeamScore,
      awayTeam: null == awayTeam
          ? _value.awayTeam
          : awayTeam // ignore: cast_nullable_to_non_nullable
              as TeamScore,
      sportType: null == sportType
          ? _value.sportType
          : sportType // ignore: cast_nullable_to_non_nullable
              as SportType,
      matchType: null == matchType
          ? _value.matchType
          : matchType // ignore: cast_nullable_to_non_nullable
              as TeamMatchType,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as TeamMatchStatus,
      scheduledTime: null == scheduledTime
          ? _value.scheduledTime
          : scheduledTime // ignore: cast_nullable_to_non_nullable
              as DateTime,
      actualStartTime: freezed == actualStartTime
          ? _value.actualStartTime
          : actualStartTime // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      actualEndTime: freezed == actualEndTime
          ? _value.actualEndTime
          : actualEndTime // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      tournamentId: freezed == tournamentId
          ? _value.tournamentId
          : tournamentId // ignore: cast_nullable_to_non_nullable
              as String?,
      tournamentName: freezed == tournamentName
          ? _value.tournamentName
          : tournamentName // ignore: cast_nullable_to_non_nullable
              as String?,
      venueId: freezed == venueId
          ? _value.venueId
          : venueId // ignore: cast_nullable_to_non_nullable
              as String?,
      venueName: freezed == venueName
          ? _value.venueName
          : venueName // ignore: cast_nullable_to_non_nullable
              as String?,
      venueLocation: freezed == venueLocation
          ? _value.venueLocation
          : venueLocation // ignore: cast_nullable_to_non_nullable
              as String?,
      result: freezed == result
          ? _value.result
          : result // ignore: cast_nullable_to_non_nullable
              as String?,
      winnerTeamId: freezed == winnerTeamId
          ? _value.winnerTeamId
          : winnerTeamId // ignore: cast_nullable_to_non_nullable
              as String?,
      notes: freezed == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      createdBy: freezed == createdBy
          ? _value.createdBy
          : createdBy // ignore: cast_nullable_to_non_nullable
              as String?,
      metadata: freezed == metadata
          ? _value._metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$TeamMatchImpl implements _TeamMatch {
  const _$TeamMatchImpl(
      {required this.id,
      required this.homeTeamId,
      required this.awayTeamId,
      required this.homeTeam,
      required this.awayTeam,
      required this.sportType,
      this.matchType = TeamMatchType.friendly,
      this.status = TeamMatchStatus.scheduled,
      @TimestampConverter() required this.scheduledTime,
      @TimestampConverter() this.actualStartTime,
      @TimestampConverter() this.actualEndTime,
      this.tournamentId,
      this.tournamentName,
      this.venueId,
      this.venueName,
      this.venueLocation,
      this.result,
      this.winnerTeamId,
      this.notes,
      @TimestampConverter() required this.createdAt,
      this.createdBy,
      final Map<String, dynamic>? metadata})
      : _metadata = metadata;

  factory _$TeamMatchImpl.fromJson(Map<String, dynamic> json) =>
      _$$TeamMatchImplFromJson(json);

  @override
  final String id;
  @override
  final String homeTeamId;
  @override
  final String awayTeamId;
  @override
  final TeamScore homeTeam;
  @override
  final TeamScore awayTeam;
  @override
  final SportType sportType;
  @override
  @JsonKey()
  final TeamMatchType matchType;
  @override
  @JsonKey()
  final TeamMatchStatus status;
  @override
  @TimestampConverter()
  final DateTime scheduledTime;
  @override
  @TimestampConverter()
  final DateTime? actualStartTime;
  @override
  @TimestampConverter()
  final DateTime? actualEndTime;
  @override
  final String? tournamentId;
// If this is a tournament match
  @override
  final String? tournamentName;
  @override
  final String? venueId;
  @override
  final String? venueName;
  @override
  final String? venueLocation;
  @override
  final String? result;
// 'Home won by 2 goals', 'Match drawn', etc.
  @override
  final String? winnerTeamId;
  @override
  final String? notes;
// Match notes/commentary
  @override
  @TimestampConverter()
  final DateTime createdAt;
  @override
  final String? createdBy;
// User ID who created the match
  final Map<String, dynamic>? _metadata;
// User ID who created the match
  @override
  Map<String, dynamic>? get metadata {
    final value = _metadata;
    if (value == null) return null;
    if (_metadata is EqualUnmodifiableMapView) return _metadata;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  String toString() {
    return 'TeamMatch(id: $id, homeTeamId: $homeTeamId, awayTeamId: $awayTeamId, homeTeam: $homeTeam, awayTeam: $awayTeam, sportType: $sportType, matchType: $matchType, status: $status, scheduledTime: $scheduledTime, actualStartTime: $actualStartTime, actualEndTime: $actualEndTime, tournamentId: $tournamentId, tournamentName: $tournamentName, venueId: $venueId, venueName: $venueName, venueLocation: $venueLocation, result: $result, winnerTeamId: $winnerTeamId, notes: $notes, createdAt: $createdAt, createdBy: $createdBy, metadata: $metadata)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TeamMatchImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.homeTeamId, homeTeamId) ||
                other.homeTeamId == homeTeamId) &&
            (identical(other.awayTeamId, awayTeamId) ||
                other.awayTeamId == awayTeamId) &&
            (identical(other.homeTeam, homeTeam) ||
                other.homeTeam == homeTeam) &&
            (identical(other.awayTeam, awayTeam) ||
                other.awayTeam == awayTeam) &&
            (identical(other.sportType, sportType) ||
                other.sportType == sportType) &&
            (identical(other.matchType, matchType) ||
                other.matchType == matchType) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.scheduledTime, scheduledTime) ||
                other.scheduledTime == scheduledTime) &&
            (identical(other.actualStartTime, actualStartTime) ||
                other.actualStartTime == actualStartTime) &&
            (identical(other.actualEndTime, actualEndTime) ||
                other.actualEndTime == actualEndTime) &&
            (identical(other.tournamentId, tournamentId) ||
                other.tournamentId == tournamentId) &&
            (identical(other.tournamentName, tournamentName) ||
                other.tournamentName == tournamentName) &&
            (identical(other.venueId, venueId) || other.venueId == venueId) &&
            (identical(other.venueName, venueName) ||
                other.venueName == venueName) &&
            (identical(other.venueLocation, venueLocation) ||
                other.venueLocation == venueLocation) &&
            (identical(other.result, result) || other.result == result) &&
            (identical(other.winnerTeamId, winnerTeamId) ||
                other.winnerTeamId == winnerTeamId) &&
            (identical(other.notes, notes) || other.notes == notes) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.createdBy, createdBy) ||
                other.createdBy == createdBy) &&
            const DeepCollectionEquality().equals(other._metadata, _metadata));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        id,
        homeTeamId,
        awayTeamId,
        homeTeam,
        awayTeam,
        sportType,
        matchType,
        status,
        scheduledTime,
        actualStartTime,
        actualEndTime,
        tournamentId,
        tournamentName,
        venueId,
        venueName,
        venueLocation,
        result,
        winnerTeamId,
        notes,
        createdAt,
        createdBy,
        const DeepCollectionEquality().hash(_metadata)
      ]);

  /// Create a copy of TeamMatch
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TeamMatchImplCopyWith<_$TeamMatchImpl> get copyWith =>
      __$$TeamMatchImplCopyWithImpl<_$TeamMatchImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TeamMatchImplToJson(
      this,
    );
  }
}

abstract class _TeamMatch implements TeamMatch {
  const factory _TeamMatch(
      {required final String id,
      required final String homeTeamId,
      required final String awayTeamId,
      required final TeamScore homeTeam,
      required final TeamScore awayTeam,
      required final SportType sportType,
      final TeamMatchType matchType,
      final TeamMatchStatus status,
      @TimestampConverter() required final DateTime scheduledTime,
      @TimestampConverter() final DateTime? actualStartTime,
      @TimestampConverter() final DateTime? actualEndTime,
      final String? tournamentId,
      final String? tournamentName,
      final String? venueId,
      final String? venueName,
      final String? venueLocation,
      final String? result,
      final String? winnerTeamId,
      final String? notes,
      @TimestampConverter() required final DateTime createdAt,
      final String? createdBy,
      final Map<String, dynamic>? metadata}) = _$TeamMatchImpl;

  factory _TeamMatch.fromJson(Map<String, dynamic> json) =
      _$TeamMatchImpl.fromJson;

  @override
  String get id;
  @override
  String get homeTeamId;
  @override
  String get awayTeamId;
  @override
  TeamScore get homeTeam;
  @override
  TeamScore get awayTeam;
  @override
  SportType get sportType;
  @override
  TeamMatchType get matchType;
  @override
  TeamMatchStatus get status;
  @override
  @TimestampConverter()
  DateTime get scheduledTime;
  @override
  @TimestampConverter()
  DateTime? get actualStartTime;
  @override
  @TimestampConverter()
  DateTime? get actualEndTime;
  @override
  String? get tournamentId; // If this is a tournament match
  @override
  String? get tournamentName;
  @override
  String? get venueId;
  @override
  String? get venueName;
  @override
  String? get venueLocation;
  @override
  String? get result; // 'Home won by 2 goals', 'Match drawn', etc.
  @override
  String? get winnerTeamId;
  @override
  String? get notes; // Match notes/commentary
  @override
  @TimestampConverter()
  DateTime get createdAt;
  @override
  String? get createdBy; // User ID who created the match
  @override
  Map<String, dynamic>? get metadata;

  /// Create a copy of TeamMatch
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TeamMatchImplCopyWith<_$TeamMatchImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'tournament_match_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

CommentaryEntry _$CommentaryEntryFromJson(Map<String, dynamic> json) {
  return _CommentaryEntry.fromJson(json);
}

/// @nodoc
mixin _$CommentaryEntry {
  String get id => throw _privateConstructorUsedError;
  String get text => throw _privateConstructorUsedError;
  @TimestampConverter()
  DateTime get timestamp => throw _privateConstructorUsedError;
  String? get minute =>
      throw _privateConstructorUsedError; // For sports like football, cricket overs, etc.
  String? get playerName => throw _privateConstructorUsedError;
  String? get eventType => throw _privateConstructorUsedError;

  /// Serializes this CommentaryEntry to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CommentaryEntry
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CommentaryEntryCopyWith<CommentaryEntry> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CommentaryEntryCopyWith<$Res> {
  factory $CommentaryEntryCopyWith(
          CommentaryEntry value, $Res Function(CommentaryEntry) then) =
      _$CommentaryEntryCopyWithImpl<$Res, CommentaryEntry>;
  @useResult
  $Res call(
      {String id,
      String text,
      @TimestampConverter() DateTime timestamp,
      String? minute,
      String? playerName,
      String? eventType});
}

/// @nodoc
class _$CommentaryEntryCopyWithImpl<$Res, $Val extends CommentaryEntry>
    implements $CommentaryEntryCopyWith<$Res> {
  _$CommentaryEntryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CommentaryEntry
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? text = null,
    Object? timestamp = null,
    Object? minute = freezed,
    Object? playerName = freezed,
    Object? eventType = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      text: null == text
          ? _value.text
          : text // ignore: cast_nullable_to_non_nullable
              as String,
      timestamp: null == timestamp
          ? _value.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as DateTime,
      minute: freezed == minute
          ? _value.minute
          : minute // ignore: cast_nullable_to_non_nullable
              as String?,
      playerName: freezed == playerName
          ? _value.playerName
          : playerName // ignore: cast_nullable_to_non_nullable
              as String?,
      eventType: freezed == eventType
          ? _value.eventType
          : eventType // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$CommentaryEntryImplCopyWith<$Res>
    implements $CommentaryEntryCopyWith<$Res> {
  factory _$$CommentaryEntryImplCopyWith(_$CommentaryEntryImpl value,
          $Res Function(_$CommentaryEntryImpl) then) =
      __$$CommentaryEntryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String text,
      @TimestampConverter() DateTime timestamp,
      String? minute,
      String? playerName,
      String? eventType});
}

/// @nodoc
class __$$CommentaryEntryImplCopyWithImpl<$Res>
    extends _$CommentaryEntryCopyWithImpl<$Res, _$CommentaryEntryImpl>
    implements _$$CommentaryEntryImplCopyWith<$Res> {
  __$$CommentaryEntryImplCopyWithImpl(
      _$CommentaryEntryImpl _value, $Res Function(_$CommentaryEntryImpl) _then)
      : super(_value, _then);

  /// Create a copy of CommentaryEntry
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? text = null,
    Object? timestamp = null,
    Object? minute = freezed,
    Object? playerName = freezed,
    Object? eventType = freezed,
  }) {
    return _then(_$CommentaryEntryImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      text: null == text
          ? _value.text
          : text // ignore: cast_nullable_to_non_nullable
              as String,
      timestamp: null == timestamp
          ? _value.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as DateTime,
      minute: freezed == minute
          ? _value.minute
          : minute // ignore: cast_nullable_to_non_nullable
              as String?,
      playerName: freezed == playerName
          ? _value.playerName
          : playerName // ignore: cast_nullable_to_non_nullable
              as String?,
      eventType: freezed == eventType
          ? _value.eventType
          : eventType // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$CommentaryEntryImpl implements _CommentaryEntry {
  const _$CommentaryEntryImpl(
      {required this.id,
      required this.text,
      @TimestampConverter() required this.timestamp,
      this.minute,
      this.playerName,
      this.eventType});

  factory _$CommentaryEntryImpl.fromJson(Map<String, dynamic> json) =>
      _$$CommentaryEntryImplFromJson(json);

  @override
  final String id;
  @override
  final String text;
  @override
  @TimestampConverter()
  final DateTime timestamp;
  @override
  final String? minute;
// For sports like football, cricket overs, etc.
  @override
  final String? playerName;
  @override
  final String? eventType;

  @override
  String toString() {
    return 'CommentaryEntry(id: $id, text: $text, timestamp: $timestamp, minute: $minute, playerName: $playerName, eventType: $eventType)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CommentaryEntryImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.text, text) || other.text == text) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp) &&
            (identical(other.minute, minute) || other.minute == minute) &&
            (identical(other.playerName, playerName) ||
                other.playerName == playerName) &&
            (identical(other.eventType, eventType) ||
                other.eventType == eventType));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, id, text, timestamp, minute, playerName, eventType);

  /// Create a copy of CommentaryEntry
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CommentaryEntryImplCopyWith<_$CommentaryEntryImpl> get copyWith =>
      __$$CommentaryEntryImplCopyWithImpl<_$CommentaryEntryImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CommentaryEntryImplToJson(
      this,
    );
  }
}

abstract class _CommentaryEntry implements CommentaryEntry {
  const factory _CommentaryEntry(
      {required final String id,
      required final String text,
      @TimestampConverter() required final DateTime timestamp,
      final String? minute,
      final String? playerName,
      final String? eventType}) = _$CommentaryEntryImpl;

  factory _CommentaryEntry.fromJson(Map<String, dynamic> json) =
      _$CommentaryEntryImpl.fromJson;

  @override
  String get id;
  @override
  String get text;
  @override
  @TimestampConverter()
  DateTime get timestamp;
  @override
  String? get minute; // For sports like football, cricket overs, etc.
  @override
  String? get playerName;
  @override
  String? get eventType;

  /// Create a copy of CommentaryEntry
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CommentaryEntryImplCopyWith<_$CommentaryEntryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

TeamMatchScore _$TeamMatchScoreFromJson(Map<String, dynamic> json) {
  return _TeamMatchScore.fromJson(json);
}

/// @nodoc
mixin _$TeamMatchScore {
  String get teamId => throw _privateConstructorUsedError;
  String get teamName => throw _privateConstructorUsedError;
  String? get teamLogoUrl => throw _privateConstructorUsedError;
  int get score => throw _privateConstructorUsedError;
  Map<String, dynamic>? get sportSpecificData =>
      throw _privateConstructorUsedError; // For cricket: runs, wickets, overs; Basketball: quarters, etc.
  List<String> get playerIds => throw _privateConstructorUsedError;

  /// Serializes this TeamMatchScore to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TeamMatchScore
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TeamMatchScoreCopyWith<TeamMatchScore> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TeamMatchScoreCopyWith<$Res> {
  factory $TeamMatchScoreCopyWith(
          TeamMatchScore value, $Res Function(TeamMatchScore) then) =
      _$TeamMatchScoreCopyWithImpl<$Res, TeamMatchScore>;
  @useResult
  $Res call(
      {String teamId,
      String teamName,
      String? teamLogoUrl,
      int score,
      Map<String, dynamic>? sportSpecificData,
      List<String> playerIds});
}

/// @nodoc
class _$TeamMatchScoreCopyWithImpl<$Res, $Val extends TeamMatchScore>
    implements $TeamMatchScoreCopyWith<$Res> {
  _$TeamMatchScoreCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TeamMatchScore
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? teamId = null,
    Object? teamName = null,
    Object? teamLogoUrl = freezed,
    Object? score = null,
    Object? sportSpecificData = freezed,
    Object? playerIds = null,
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
      playerIds: null == playerIds
          ? _value.playerIds
          : playerIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$TeamMatchScoreImplCopyWith<$Res>
    implements $TeamMatchScoreCopyWith<$Res> {
  factory _$$TeamMatchScoreImplCopyWith(_$TeamMatchScoreImpl value,
          $Res Function(_$TeamMatchScoreImpl) then) =
      __$$TeamMatchScoreImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String teamId,
      String teamName,
      String? teamLogoUrl,
      int score,
      Map<String, dynamic>? sportSpecificData,
      List<String> playerIds});
}

/// @nodoc
class __$$TeamMatchScoreImplCopyWithImpl<$Res>
    extends _$TeamMatchScoreCopyWithImpl<$Res, _$TeamMatchScoreImpl>
    implements _$$TeamMatchScoreImplCopyWith<$Res> {
  __$$TeamMatchScoreImplCopyWithImpl(
      _$TeamMatchScoreImpl _value, $Res Function(_$TeamMatchScoreImpl) _then)
      : super(_value, _then);

  /// Create a copy of TeamMatchScore
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? teamId = null,
    Object? teamName = null,
    Object? teamLogoUrl = freezed,
    Object? score = null,
    Object? sportSpecificData = freezed,
    Object? playerIds = null,
  }) {
    return _then(_$TeamMatchScoreImpl(
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
      playerIds: null == playerIds
          ? _value._playerIds
          : playerIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$TeamMatchScoreImpl implements _TeamMatchScore {
  const _$TeamMatchScoreImpl(
      {required this.teamId,
      required this.teamName,
      this.teamLogoUrl,
      this.score = 0,
      final Map<String, dynamic>? sportSpecificData,
      final List<String> playerIds = const []})
      : _sportSpecificData = sportSpecificData,
        _playerIds = playerIds;

  factory _$TeamMatchScoreImpl.fromJson(Map<String, dynamic> json) =>
      _$$TeamMatchScoreImplFromJson(json);

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

// For cricket: runs, wickets, overs; Basketball: quarters, etc.
  final List<String> _playerIds;
// For cricket: runs, wickets, overs; Basketball: quarters, etc.
  @override
  @JsonKey()
  List<String> get playerIds {
    if (_playerIds is EqualUnmodifiableListView) return _playerIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_playerIds);
  }

  @override
  String toString() {
    return 'TeamMatchScore(teamId: $teamId, teamName: $teamName, teamLogoUrl: $teamLogoUrl, score: $score, sportSpecificData: $sportSpecificData, playerIds: $playerIds)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TeamMatchScoreImpl &&
            (identical(other.teamId, teamId) || other.teamId == teamId) &&
            (identical(other.teamName, teamName) ||
                other.teamName == teamName) &&
            (identical(other.teamLogoUrl, teamLogoUrl) ||
                other.teamLogoUrl == teamLogoUrl) &&
            (identical(other.score, score) || other.score == score) &&
            const DeepCollectionEquality()
                .equals(other._sportSpecificData, _sportSpecificData) &&
            const DeepCollectionEquality()
                .equals(other._playerIds, _playerIds));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      teamId,
      teamName,
      teamLogoUrl,
      score,
      const DeepCollectionEquality().hash(_sportSpecificData),
      const DeepCollectionEquality().hash(_playerIds));

  /// Create a copy of TeamMatchScore
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TeamMatchScoreImplCopyWith<_$TeamMatchScoreImpl> get copyWith =>
      __$$TeamMatchScoreImplCopyWithImpl<_$TeamMatchScoreImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TeamMatchScoreImplToJson(
      this,
    );
  }
}

abstract class _TeamMatchScore implements TeamMatchScore {
  const factory _TeamMatchScore(
      {required final String teamId,
      required final String teamName,
      final String? teamLogoUrl,
      final int score,
      final Map<String, dynamic>? sportSpecificData,
      final List<String> playerIds}) = _$TeamMatchScoreImpl;

  factory _TeamMatchScore.fromJson(Map<String, dynamic> json) =
      _$TeamMatchScoreImpl.fromJson;

  @override
  String get teamId;
  @override
  String get teamName;
  @override
  String? get teamLogoUrl;
  @override
  int get score;
  @override
  Map<String, dynamic>?
      get sportSpecificData; // For cricket: runs, wickets, overs; Basketball: quarters, etc.
  @override
  List<String> get playerIds;

  /// Create a copy of TeamMatchScore
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TeamMatchScoreImplCopyWith<_$TeamMatchScoreImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

TournamentMatch _$TournamentMatchFromJson(Map<String, dynamic> json) {
  return _TournamentMatch.fromJson(json);
}

/// @nodoc
mixin _$TournamentMatch {
  String get id => throw _privateConstructorUsedError;
  String get tournamentId => throw _privateConstructorUsedError;
  String get tournamentName => throw _privateConstructorUsedError;
  SportType get sportType => throw _privateConstructorUsedError; // Teams
  TeamMatchScore get team1 => throw _privateConstructorUsedError;
  TeamMatchScore get team2 =>
      throw _privateConstructorUsedError; // Match details
  String get matchNumber =>
      throw _privateConstructorUsedError; // 'Match 1', 'Quarter Final 1', 'Semi Final 1', 'Final'
  String? get round =>
      throw _privateConstructorUsedError; // 'Group Stage', 'Quarter Finals', 'Semi Finals', 'Finals'
  @TimestampConverter()
  DateTime get scheduledTime => throw _privateConstructorUsedError;
  @TimestampConverter()
  DateTime? get actualStartTime => throw _privateConstructorUsedError;
  @TimestampConverter()
  DateTime? get actualEndTime => throw _privateConstructorUsedError; // Status
  TournamentMatchStatus get status =>
      throw _privateConstructorUsedError; // Scores and commentary
  List<CommentaryEntry> get commentary => throw _privateConstructorUsedError;
  String? get result =>
      throw _privateConstructorUsedError; // 'Team 1 won by 2 goals', 'Match drawn', etc.
  String? get winnerTeamId =>
      throw _privateConstructorUsedError; // Player Statistics (NEW)
  List<PlayerMatchStats> get team1PlayerStats =>
      throw _privateConstructorUsedError;
  List<PlayerMatchStats> get team2PlayerStats =>
      throw _privateConstructorUsedError;
  String? get manOfTheMatch => throw _privateConstructorUsedError; // Player ID
// Coaches (NEW)
  String? get team1CoachId => throw _privateConstructorUsedError;
  String? get team1CoachName => throw _privateConstructorUsedError;
  String? get team2CoachId => throw _privateConstructorUsedError;
  String? get team2CoachName => throw _privateConstructorUsedError; // Venue
  String? get venueId => throw _privateConstructorUsedError;
  String? get venueName => throw _privateConstructorUsedError;
  String? get venueLocation =>
      throw _privateConstructorUsedError; // Background Image
  String? get backgroundImageUrl =>
      throw _privateConstructorUsedError; // Metadata
  @TimestampConverter()
  DateTime? get createdAt => throw _privateConstructorUsedError;
  @TimestampConverter()
  DateTime? get updatedAt => throw _privateConstructorUsedError;
  String? get createdBy => throw _privateConstructorUsedError;
  Map<String, dynamic>? get metadata => throw _privateConstructorUsedError;

  /// Serializes this TournamentMatch to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TournamentMatch
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TournamentMatchCopyWith<TournamentMatch> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TournamentMatchCopyWith<$Res> {
  factory $TournamentMatchCopyWith(
          TournamentMatch value, $Res Function(TournamentMatch) then) =
      _$TournamentMatchCopyWithImpl<$Res, TournamentMatch>;
  @useResult
  $Res call(
      {String id,
      String tournamentId,
      String tournamentName,
      SportType sportType,
      TeamMatchScore team1,
      TeamMatchScore team2,
      String matchNumber,
      String? round,
      @TimestampConverter() DateTime scheduledTime,
      @TimestampConverter() DateTime? actualStartTime,
      @TimestampConverter() DateTime? actualEndTime,
      TournamentMatchStatus status,
      List<CommentaryEntry> commentary,
      String? result,
      String? winnerTeamId,
      List<PlayerMatchStats> team1PlayerStats,
      List<PlayerMatchStats> team2PlayerStats,
      String? manOfTheMatch,
      String? team1CoachId,
      String? team1CoachName,
      String? team2CoachId,
      String? team2CoachName,
      String? venueId,
      String? venueName,
      String? venueLocation,
      String? backgroundImageUrl,
      @TimestampConverter() DateTime? createdAt,
      @TimestampConverter() DateTime? updatedAt,
      String? createdBy,
      Map<String, dynamic>? metadata});

  $TeamMatchScoreCopyWith<$Res> get team1;
  $TeamMatchScoreCopyWith<$Res> get team2;
}

/// @nodoc
class _$TournamentMatchCopyWithImpl<$Res, $Val extends TournamentMatch>
    implements $TournamentMatchCopyWith<$Res> {
  _$TournamentMatchCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TournamentMatch
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? tournamentId = null,
    Object? tournamentName = null,
    Object? sportType = null,
    Object? team1 = null,
    Object? team2 = null,
    Object? matchNumber = null,
    Object? round = freezed,
    Object? scheduledTime = null,
    Object? actualStartTime = freezed,
    Object? actualEndTime = freezed,
    Object? status = null,
    Object? commentary = null,
    Object? result = freezed,
    Object? winnerTeamId = freezed,
    Object? team1PlayerStats = null,
    Object? team2PlayerStats = null,
    Object? manOfTheMatch = freezed,
    Object? team1CoachId = freezed,
    Object? team1CoachName = freezed,
    Object? team2CoachId = freezed,
    Object? team2CoachName = freezed,
    Object? venueId = freezed,
    Object? venueName = freezed,
    Object? venueLocation = freezed,
    Object? backgroundImageUrl = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
    Object? createdBy = freezed,
    Object? metadata = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      tournamentId: null == tournamentId
          ? _value.tournamentId
          : tournamentId // ignore: cast_nullable_to_non_nullable
              as String,
      tournamentName: null == tournamentName
          ? _value.tournamentName
          : tournamentName // ignore: cast_nullable_to_non_nullable
              as String,
      sportType: null == sportType
          ? _value.sportType
          : sportType // ignore: cast_nullable_to_non_nullable
              as SportType,
      team1: null == team1
          ? _value.team1
          : team1 // ignore: cast_nullable_to_non_nullable
              as TeamMatchScore,
      team2: null == team2
          ? _value.team2
          : team2 // ignore: cast_nullable_to_non_nullable
              as TeamMatchScore,
      matchNumber: null == matchNumber
          ? _value.matchNumber
          : matchNumber // ignore: cast_nullable_to_non_nullable
              as String,
      round: freezed == round
          ? _value.round
          : round // ignore: cast_nullable_to_non_nullable
              as String?,
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
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as TournamentMatchStatus,
      commentary: null == commentary
          ? _value.commentary
          : commentary // ignore: cast_nullable_to_non_nullable
              as List<CommentaryEntry>,
      result: freezed == result
          ? _value.result
          : result // ignore: cast_nullable_to_non_nullable
              as String?,
      winnerTeamId: freezed == winnerTeamId
          ? _value.winnerTeamId
          : winnerTeamId // ignore: cast_nullable_to_non_nullable
              as String?,
      team1PlayerStats: null == team1PlayerStats
          ? _value.team1PlayerStats
          : team1PlayerStats // ignore: cast_nullable_to_non_nullable
              as List<PlayerMatchStats>,
      team2PlayerStats: null == team2PlayerStats
          ? _value.team2PlayerStats
          : team2PlayerStats // ignore: cast_nullable_to_non_nullable
              as List<PlayerMatchStats>,
      manOfTheMatch: freezed == manOfTheMatch
          ? _value.manOfTheMatch
          : manOfTheMatch // ignore: cast_nullable_to_non_nullable
              as String?,
      team1CoachId: freezed == team1CoachId
          ? _value.team1CoachId
          : team1CoachId // ignore: cast_nullable_to_non_nullable
              as String?,
      team1CoachName: freezed == team1CoachName
          ? _value.team1CoachName
          : team1CoachName // ignore: cast_nullable_to_non_nullable
              as String?,
      team2CoachId: freezed == team2CoachId
          ? _value.team2CoachId
          : team2CoachId // ignore: cast_nullable_to_non_nullable
              as String?,
      team2CoachName: freezed == team2CoachName
          ? _value.team2CoachName
          : team2CoachName // ignore: cast_nullable_to_non_nullable
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
      backgroundImageUrl: freezed == backgroundImageUrl
          ? _value.backgroundImageUrl
          : backgroundImageUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
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

  /// Create a copy of TournamentMatch
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $TeamMatchScoreCopyWith<$Res> get team1 {
    return $TeamMatchScoreCopyWith<$Res>(_value.team1, (value) {
      return _then(_value.copyWith(team1: value) as $Val);
    });
  }

  /// Create a copy of TournamentMatch
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $TeamMatchScoreCopyWith<$Res> get team2 {
    return $TeamMatchScoreCopyWith<$Res>(_value.team2, (value) {
      return _then(_value.copyWith(team2: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$TournamentMatchImplCopyWith<$Res>
    implements $TournamentMatchCopyWith<$Res> {
  factory _$$TournamentMatchImplCopyWith(_$TournamentMatchImpl value,
          $Res Function(_$TournamentMatchImpl) then) =
      __$$TournamentMatchImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String tournamentId,
      String tournamentName,
      SportType sportType,
      TeamMatchScore team1,
      TeamMatchScore team2,
      String matchNumber,
      String? round,
      @TimestampConverter() DateTime scheduledTime,
      @TimestampConverter() DateTime? actualStartTime,
      @TimestampConverter() DateTime? actualEndTime,
      TournamentMatchStatus status,
      List<CommentaryEntry> commentary,
      String? result,
      String? winnerTeamId,
      List<PlayerMatchStats> team1PlayerStats,
      List<PlayerMatchStats> team2PlayerStats,
      String? manOfTheMatch,
      String? team1CoachId,
      String? team1CoachName,
      String? team2CoachId,
      String? team2CoachName,
      String? venueId,
      String? venueName,
      String? venueLocation,
      String? backgroundImageUrl,
      @TimestampConverter() DateTime? createdAt,
      @TimestampConverter() DateTime? updatedAt,
      String? createdBy,
      Map<String, dynamic>? metadata});

  @override
  $TeamMatchScoreCopyWith<$Res> get team1;
  @override
  $TeamMatchScoreCopyWith<$Res> get team2;
}

/// @nodoc
class __$$TournamentMatchImplCopyWithImpl<$Res>
    extends _$TournamentMatchCopyWithImpl<$Res, _$TournamentMatchImpl>
    implements _$$TournamentMatchImplCopyWith<$Res> {
  __$$TournamentMatchImplCopyWithImpl(
      _$TournamentMatchImpl _value, $Res Function(_$TournamentMatchImpl) _then)
      : super(_value, _then);

  /// Create a copy of TournamentMatch
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? tournamentId = null,
    Object? tournamentName = null,
    Object? sportType = null,
    Object? team1 = null,
    Object? team2 = null,
    Object? matchNumber = null,
    Object? round = freezed,
    Object? scheduledTime = null,
    Object? actualStartTime = freezed,
    Object? actualEndTime = freezed,
    Object? status = null,
    Object? commentary = null,
    Object? result = freezed,
    Object? winnerTeamId = freezed,
    Object? team1PlayerStats = null,
    Object? team2PlayerStats = null,
    Object? manOfTheMatch = freezed,
    Object? team1CoachId = freezed,
    Object? team1CoachName = freezed,
    Object? team2CoachId = freezed,
    Object? team2CoachName = freezed,
    Object? venueId = freezed,
    Object? venueName = freezed,
    Object? venueLocation = freezed,
    Object? backgroundImageUrl = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
    Object? createdBy = freezed,
    Object? metadata = freezed,
  }) {
    return _then(_$TournamentMatchImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      tournamentId: null == tournamentId
          ? _value.tournamentId
          : tournamentId // ignore: cast_nullable_to_non_nullable
              as String,
      tournamentName: null == tournamentName
          ? _value.tournamentName
          : tournamentName // ignore: cast_nullable_to_non_nullable
              as String,
      sportType: null == sportType
          ? _value.sportType
          : sportType // ignore: cast_nullable_to_non_nullable
              as SportType,
      team1: null == team1
          ? _value.team1
          : team1 // ignore: cast_nullable_to_non_nullable
              as TeamMatchScore,
      team2: null == team2
          ? _value.team2
          : team2 // ignore: cast_nullable_to_non_nullable
              as TeamMatchScore,
      matchNumber: null == matchNumber
          ? _value.matchNumber
          : matchNumber // ignore: cast_nullable_to_non_nullable
              as String,
      round: freezed == round
          ? _value.round
          : round // ignore: cast_nullable_to_non_nullable
              as String?,
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
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as TournamentMatchStatus,
      commentary: null == commentary
          ? _value._commentary
          : commentary // ignore: cast_nullable_to_non_nullable
              as List<CommentaryEntry>,
      result: freezed == result
          ? _value.result
          : result // ignore: cast_nullable_to_non_nullable
              as String?,
      winnerTeamId: freezed == winnerTeamId
          ? _value.winnerTeamId
          : winnerTeamId // ignore: cast_nullable_to_non_nullable
              as String?,
      team1PlayerStats: null == team1PlayerStats
          ? _value._team1PlayerStats
          : team1PlayerStats // ignore: cast_nullable_to_non_nullable
              as List<PlayerMatchStats>,
      team2PlayerStats: null == team2PlayerStats
          ? _value._team2PlayerStats
          : team2PlayerStats // ignore: cast_nullable_to_non_nullable
              as List<PlayerMatchStats>,
      manOfTheMatch: freezed == manOfTheMatch
          ? _value.manOfTheMatch
          : manOfTheMatch // ignore: cast_nullable_to_non_nullable
              as String?,
      team1CoachId: freezed == team1CoachId
          ? _value.team1CoachId
          : team1CoachId // ignore: cast_nullable_to_non_nullable
              as String?,
      team1CoachName: freezed == team1CoachName
          ? _value.team1CoachName
          : team1CoachName // ignore: cast_nullable_to_non_nullable
              as String?,
      team2CoachId: freezed == team2CoachId
          ? _value.team2CoachId
          : team2CoachId // ignore: cast_nullable_to_non_nullable
              as String?,
      team2CoachName: freezed == team2CoachName
          ? _value.team2CoachName
          : team2CoachName // ignore: cast_nullable_to_non_nullable
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
      backgroundImageUrl: freezed == backgroundImageUrl
          ? _value.backgroundImageUrl
          : backgroundImageUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
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
class _$TournamentMatchImpl implements _TournamentMatch {
  const _$TournamentMatchImpl(
      {required this.id,
      required this.tournamentId,
      required this.tournamentName,
      required this.sportType,
      required this.team1,
      required this.team2,
      required this.matchNumber,
      this.round,
      @TimestampConverter() required this.scheduledTime,
      @TimestampConverter() this.actualStartTime,
      @TimestampConverter() this.actualEndTime,
      this.status = TournamentMatchStatus.scheduled,
      final List<CommentaryEntry> commentary = const [],
      this.result,
      this.winnerTeamId,
      final List<PlayerMatchStats> team1PlayerStats = const [],
      final List<PlayerMatchStats> team2PlayerStats = const [],
      this.manOfTheMatch,
      this.team1CoachId,
      this.team1CoachName,
      this.team2CoachId,
      this.team2CoachName,
      this.venueId,
      this.venueName,
      this.venueLocation,
      this.backgroundImageUrl,
      @TimestampConverter() this.createdAt,
      @TimestampConverter() this.updatedAt,
      this.createdBy,
      final Map<String, dynamic>? metadata})
      : _commentary = commentary,
        _team1PlayerStats = team1PlayerStats,
        _team2PlayerStats = team2PlayerStats,
        _metadata = metadata;

  factory _$TournamentMatchImpl.fromJson(Map<String, dynamic> json) =>
      _$$TournamentMatchImplFromJson(json);

  @override
  final String id;
  @override
  final String tournamentId;
  @override
  final String tournamentName;
  @override
  final SportType sportType;
// Teams
  @override
  final TeamMatchScore team1;
  @override
  final TeamMatchScore team2;
// Match details
  @override
  final String matchNumber;
// 'Match 1', 'Quarter Final 1', 'Semi Final 1', 'Final'
  @override
  final String? round;
// 'Group Stage', 'Quarter Finals', 'Semi Finals', 'Finals'
  @override
  @TimestampConverter()
  final DateTime scheduledTime;
  @override
  @TimestampConverter()
  final DateTime? actualStartTime;
  @override
  @TimestampConverter()
  final DateTime? actualEndTime;
// Status
  @override
  @JsonKey()
  final TournamentMatchStatus status;
// Scores and commentary
  final List<CommentaryEntry> _commentary;
// Scores and commentary
  @override
  @JsonKey()
  List<CommentaryEntry> get commentary {
    if (_commentary is EqualUnmodifiableListView) return _commentary;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_commentary);
  }

  @override
  final String? result;
// 'Team 1 won by 2 goals', 'Match drawn', etc.
  @override
  final String? winnerTeamId;
// Player Statistics (NEW)
  final List<PlayerMatchStats> _team1PlayerStats;
// Player Statistics (NEW)
  @override
  @JsonKey()
  List<PlayerMatchStats> get team1PlayerStats {
    if (_team1PlayerStats is EqualUnmodifiableListView)
      return _team1PlayerStats;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_team1PlayerStats);
  }

  final List<PlayerMatchStats> _team2PlayerStats;
  @override
  @JsonKey()
  List<PlayerMatchStats> get team2PlayerStats {
    if (_team2PlayerStats is EqualUnmodifiableListView)
      return _team2PlayerStats;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_team2PlayerStats);
  }

  @override
  final String? manOfTheMatch;
// Player ID
// Coaches (NEW)
  @override
  final String? team1CoachId;
  @override
  final String? team1CoachName;
  @override
  final String? team2CoachId;
  @override
  final String? team2CoachName;
// Venue
  @override
  final String? venueId;
  @override
  final String? venueName;
  @override
  final String? venueLocation;
// Background Image
  @override
  final String? backgroundImageUrl;
// Metadata
  @override
  @TimestampConverter()
  final DateTime? createdAt;
  @override
  @TimestampConverter()
  final DateTime? updatedAt;
  @override
  final String? createdBy;
  final Map<String, dynamic>? _metadata;
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
    return 'TournamentMatch(id: $id, tournamentId: $tournamentId, tournamentName: $tournamentName, sportType: $sportType, team1: $team1, team2: $team2, matchNumber: $matchNumber, round: $round, scheduledTime: $scheduledTime, actualStartTime: $actualStartTime, actualEndTime: $actualEndTime, status: $status, commentary: $commentary, result: $result, winnerTeamId: $winnerTeamId, team1PlayerStats: $team1PlayerStats, team2PlayerStats: $team2PlayerStats, manOfTheMatch: $manOfTheMatch, team1CoachId: $team1CoachId, team1CoachName: $team1CoachName, team2CoachId: $team2CoachId, team2CoachName: $team2CoachName, venueId: $venueId, venueName: $venueName, venueLocation: $venueLocation, backgroundImageUrl: $backgroundImageUrl, createdAt: $createdAt, updatedAt: $updatedAt, createdBy: $createdBy, metadata: $metadata)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TournamentMatchImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.tournamentId, tournamentId) ||
                other.tournamentId == tournamentId) &&
            (identical(other.tournamentName, tournamentName) ||
                other.tournamentName == tournamentName) &&
            (identical(other.sportType, sportType) ||
                other.sportType == sportType) &&
            (identical(other.team1, team1) || other.team1 == team1) &&
            (identical(other.team2, team2) || other.team2 == team2) &&
            (identical(other.matchNumber, matchNumber) ||
                other.matchNumber == matchNumber) &&
            (identical(other.round, round) || other.round == round) &&
            (identical(other.scheduledTime, scheduledTime) ||
                other.scheduledTime == scheduledTime) &&
            (identical(other.actualStartTime, actualStartTime) ||
                other.actualStartTime == actualStartTime) &&
            (identical(other.actualEndTime, actualEndTime) ||
                other.actualEndTime == actualEndTime) &&
            (identical(other.status, status) || other.status == status) &&
            const DeepCollectionEquality()
                .equals(other._commentary, _commentary) &&
            (identical(other.result, result) || other.result == result) &&
            (identical(other.winnerTeamId, winnerTeamId) ||
                other.winnerTeamId == winnerTeamId) &&
            const DeepCollectionEquality()
                .equals(other._team1PlayerStats, _team1PlayerStats) &&
            const DeepCollectionEquality()
                .equals(other._team2PlayerStats, _team2PlayerStats) &&
            (identical(other.manOfTheMatch, manOfTheMatch) ||
                other.manOfTheMatch == manOfTheMatch) &&
            (identical(other.team1CoachId, team1CoachId) ||
                other.team1CoachId == team1CoachId) &&
            (identical(other.team1CoachName, team1CoachName) ||
                other.team1CoachName == team1CoachName) &&
            (identical(other.team2CoachId, team2CoachId) ||
                other.team2CoachId == team2CoachId) &&
            (identical(other.team2CoachName, team2CoachName) ||
                other.team2CoachName == team2CoachName) &&
            (identical(other.venueId, venueId) || other.venueId == venueId) &&
            (identical(other.venueName, venueName) ||
                other.venueName == venueName) &&
            (identical(other.venueLocation, venueLocation) ||
                other.venueLocation == venueLocation) &&
            (identical(other.backgroundImageUrl, backgroundImageUrl) ||
                other.backgroundImageUrl == backgroundImageUrl) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.createdBy, createdBy) ||
                other.createdBy == createdBy) &&
            const DeepCollectionEquality().equals(other._metadata, _metadata));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        id,
        tournamentId,
        tournamentName,
        sportType,
        team1,
        team2,
        matchNumber,
        round,
        scheduledTime,
        actualStartTime,
        actualEndTime,
        status,
        const DeepCollectionEquality().hash(_commentary),
        result,
        winnerTeamId,
        const DeepCollectionEquality().hash(_team1PlayerStats),
        const DeepCollectionEquality().hash(_team2PlayerStats),
        manOfTheMatch,
        team1CoachId,
        team1CoachName,
        team2CoachId,
        team2CoachName,
        venueId,
        venueName,
        venueLocation,
        backgroundImageUrl,
        createdAt,
        updatedAt,
        createdBy,
        const DeepCollectionEquality().hash(_metadata)
      ]);

  /// Create a copy of TournamentMatch
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TournamentMatchImplCopyWith<_$TournamentMatchImpl> get copyWith =>
      __$$TournamentMatchImplCopyWithImpl<_$TournamentMatchImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TournamentMatchImplToJson(
      this,
    );
  }
}

abstract class _TournamentMatch implements TournamentMatch {
  const factory _TournamentMatch(
      {required final String id,
      required final String tournamentId,
      required final String tournamentName,
      required final SportType sportType,
      required final TeamMatchScore team1,
      required final TeamMatchScore team2,
      required final String matchNumber,
      final String? round,
      @TimestampConverter() required final DateTime scheduledTime,
      @TimestampConverter() final DateTime? actualStartTime,
      @TimestampConverter() final DateTime? actualEndTime,
      final TournamentMatchStatus status,
      final List<CommentaryEntry> commentary,
      final String? result,
      final String? winnerTeamId,
      final List<PlayerMatchStats> team1PlayerStats,
      final List<PlayerMatchStats> team2PlayerStats,
      final String? manOfTheMatch,
      final String? team1CoachId,
      final String? team1CoachName,
      final String? team2CoachId,
      final String? team2CoachName,
      final String? venueId,
      final String? venueName,
      final String? venueLocation,
      final String? backgroundImageUrl,
      @TimestampConverter() final DateTime? createdAt,
      @TimestampConverter() final DateTime? updatedAt,
      final String? createdBy,
      final Map<String, dynamic>? metadata}) = _$TournamentMatchImpl;

  factory _TournamentMatch.fromJson(Map<String, dynamic> json) =
      _$TournamentMatchImpl.fromJson;

  @override
  String get id;
  @override
  String get tournamentId;
  @override
  String get tournamentName;
  @override
  SportType get sportType; // Teams
  @override
  TeamMatchScore get team1;
  @override
  TeamMatchScore get team2; // Match details
  @override
  String
      get matchNumber; // 'Match 1', 'Quarter Final 1', 'Semi Final 1', 'Final'
  @override
  String? get round; // 'Group Stage', 'Quarter Finals', 'Semi Finals', 'Finals'
  @override
  @TimestampConverter()
  DateTime get scheduledTime;
  @override
  @TimestampConverter()
  DateTime? get actualStartTime;
  @override
  @TimestampConverter()
  DateTime? get actualEndTime; // Status
  @override
  TournamentMatchStatus get status; // Scores and commentary
  @override
  List<CommentaryEntry> get commentary;
  @override
  String? get result; // 'Team 1 won by 2 goals', 'Match drawn', etc.
  @override
  String? get winnerTeamId; // Player Statistics (NEW)
  @override
  List<PlayerMatchStats> get team1PlayerStats;
  @override
  List<PlayerMatchStats> get team2PlayerStats;
  @override
  String? get manOfTheMatch; // Player ID
// Coaches (NEW)
  @override
  String? get team1CoachId;
  @override
  String? get team1CoachName;
  @override
  String? get team2CoachId;
  @override
  String? get team2CoachName; // Venue
  @override
  String? get venueId;
  @override
  String? get venueName;
  @override
  String? get venueLocation; // Background Image
  @override
  String? get backgroundImageUrl; // Metadata
  @override
  @TimestampConverter()
  DateTime? get createdAt;
  @override
  @TimestampConverter()
  DateTime? get updatedAt;
  @override
  String? get createdBy;
  @override
  Map<String, dynamic>? get metadata;

  /// Create a copy of TournamentMatch
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TournamentMatchImplCopyWith<_$TournamentMatchImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

TournamentJoinRequest _$TournamentJoinRequestFromJson(
    Map<String, dynamic> json) {
  return _TournamentJoinRequest.fromJson(json);
}

/// @nodoc
mixin _$TournamentJoinRequest {
  String get id => throw _privateConstructorUsedError;
  String get tournamentId => throw _privateConstructorUsedError;
  String get requesterId => throw _privateConstructorUsedError;
  String get requesterName => throw _privateConstructorUsedError;
  String? get requesterProfileUrl =>
      throw _privateConstructorUsedError; // Request type
  bool get isTeamRequest =>
      throw _privateConstructorUsedError; // true for team, false for individual
  String? get teamId => throw _privateConstructorUsedError;
  String? get teamName => throw _privateConstructorUsedError;
  String? get teamLogoUrl =>
      throw _privateConstructorUsedError; // Player details (for individual requests)
  String? get sport => throw _privateConstructorUsedError;
  String? get position => throw _privateConstructorUsedError;
  int? get skillLevel => throw _privateConstructorUsedError;
  String? get bio => throw _privateConstructorUsedError;
  Map<String, dynamic> get formResponses => throw _privateConstructorUsedError;
  String? get storagePath =>
      throw _privateConstructorUsedError; // Request status
  String get status =>
      throw _privateConstructorUsedError; // 'pending', 'accepted', 'rejected'
  String? get reviewedBy => throw _privateConstructorUsedError;
  @TimestampConverter()
  DateTime? get reviewedAt => throw _privateConstructorUsedError;
  String? get reviewNote => throw _privateConstructorUsedError;
  @TimestampConverter()
  DateTime get createdAt => throw _privateConstructorUsedError;
  Map<String, dynamic>? get metadata => throw _privateConstructorUsedError;

  /// Serializes this TournamentJoinRequest to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TournamentJoinRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TournamentJoinRequestCopyWith<TournamentJoinRequest> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TournamentJoinRequestCopyWith<$Res> {
  factory $TournamentJoinRequestCopyWith(TournamentJoinRequest value,
          $Res Function(TournamentJoinRequest) then) =
      _$TournamentJoinRequestCopyWithImpl<$Res, TournamentJoinRequest>;
  @useResult
  $Res call(
      {String id,
      String tournamentId,
      String requesterId,
      String requesterName,
      String? requesterProfileUrl,
      bool isTeamRequest,
      String? teamId,
      String? teamName,
      String? teamLogoUrl,
      String? sport,
      String? position,
      int? skillLevel,
      String? bio,
      Map<String, dynamic> formResponses,
      String? storagePath,
      String status,
      String? reviewedBy,
      @TimestampConverter() DateTime? reviewedAt,
      String? reviewNote,
      @TimestampConverter() DateTime createdAt,
      Map<String, dynamic>? metadata});
}

/// @nodoc
class _$TournamentJoinRequestCopyWithImpl<$Res,
        $Val extends TournamentJoinRequest>
    implements $TournamentJoinRequestCopyWith<$Res> {
  _$TournamentJoinRequestCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TournamentJoinRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? tournamentId = null,
    Object? requesterId = null,
    Object? requesterName = null,
    Object? requesterProfileUrl = freezed,
    Object? isTeamRequest = null,
    Object? teamId = freezed,
    Object? teamName = freezed,
    Object? teamLogoUrl = freezed,
    Object? sport = freezed,
    Object? position = freezed,
    Object? skillLevel = freezed,
    Object? bio = freezed,
    Object? formResponses = null,
    Object? storagePath = freezed,
    Object? status = null,
    Object? reviewedBy = freezed,
    Object? reviewedAt = freezed,
    Object? reviewNote = freezed,
    Object? createdAt = null,
    Object? metadata = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      tournamentId: null == tournamentId
          ? _value.tournamentId
          : tournamentId // ignore: cast_nullable_to_non_nullable
              as String,
      requesterId: null == requesterId
          ? _value.requesterId
          : requesterId // ignore: cast_nullable_to_non_nullable
              as String,
      requesterName: null == requesterName
          ? _value.requesterName
          : requesterName // ignore: cast_nullable_to_non_nullable
              as String,
      requesterProfileUrl: freezed == requesterProfileUrl
          ? _value.requesterProfileUrl
          : requesterProfileUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      isTeamRequest: null == isTeamRequest
          ? _value.isTeamRequest
          : isTeamRequest // ignore: cast_nullable_to_non_nullable
              as bool,
      teamId: freezed == teamId
          ? _value.teamId
          : teamId // ignore: cast_nullable_to_non_nullable
              as String?,
      teamName: freezed == teamName
          ? _value.teamName
          : teamName // ignore: cast_nullable_to_non_nullable
              as String?,
      teamLogoUrl: freezed == teamLogoUrl
          ? _value.teamLogoUrl
          : teamLogoUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      sport: freezed == sport
          ? _value.sport
          : sport // ignore: cast_nullable_to_non_nullable
              as String?,
      position: freezed == position
          ? _value.position
          : position // ignore: cast_nullable_to_non_nullable
              as String?,
      skillLevel: freezed == skillLevel
          ? _value.skillLevel
          : skillLevel // ignore: cast_nullable_to_non_nullable
              as int?,
      bio: freezed == bio
          ? _value.bio
          : bio // ignore: cast_nullable_to_non_nullable
              as String?,
      formResponses: null == formResponses
          ? _value.formResponses
          : formResponses // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      storagePath: freezed == storagePath
          ? _value.storagePath
          : storagePath // ignore: cast_nullable_to_non_nullable
              as String?,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      reviewedBy: freezed == reviewedBy
          ? _value.reviewedBy
          : reviewedBy // ignore: cast_nullable_to_non_nullable
              as String?,
      reviewedAt: freezed == reviewedAt
          ? _value.reviewedAt
          : reviewedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      reviewNote: freezed == reviewNote
          ? _value.reviewNote
          : reviewNote // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      metadata: freezed == metadata
          ? _value.metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$TournamentJoinRequestImplCopyWith<$Res>
    implements $TournamentJoinRequestCopyWith<$Res> {
  factory _$$TournamentJoinRequestImplCopyWith(
          _$TournamentJoinRequestImpl value,
          $Res Function(_$TournamentJoinRequestImpl) then) =
      __$$TournamentJoinRequestImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String tournamentId,
      String requesterId,
      String requesterName,
      String? requesterProfileUrl,
      bool isTeamRequest,
      String? teamId,
      String? teamName,
      String? teamLogoUrl,
      String? sport,
      String? position,
      int? skillLevel,
      String? bio,
      Map<String, dynamic> formResponses,
      String? storagePath,
      String status,
      String? reviewedBy,
      @TimestampConverter() DateTime? reviewedAt,
      String? reviewNote,
      @TimestampConverter() DateTime createdAt,
      Map<String, dynamic>? metadata});
}

/// @nodoc
class __$$TournamentJoinRequestImplCopyWithImpl<$Res>
    extends _$TournamentJoinRequestCopyWithImpl<$Res,
        _$TournamentJoinRequestImpl>
    implements _$$TournamentJoinRequestImplCopyWith<$Res> {
  __$$TournamentJoinRequestImplCopyWithImpl(_$TournamentJoinRequestImpl _value,
      $Res Function(_$TournamentJoinRequestImpl) _then)
      : super(_value, _then);

  /// Create a copy of TournamentJoinRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? tournamentId = null,
    Object? requesterId = null,
    Object? requesterName = null,
    Object? requesterProfileUrl = freezed,
    Object? isTeamRequest = null,
    Object? teamId = freezed,
    Object? teamName = freezed,
    Object? teamLogoUrl = freezed,
    Object? sport = freezed,
    Object? position = freezed,
    Object? skillLevel = freezed,
    Object? bio = freezed,
    Object? formResponses = null,
    Object? storagePath = freezed,
    Object? status = null,
    Object? reviewedBy = freezed,
    Object? reviewedAt = freezed,
    Object? reviewNote = freezed,
    Object? createdAt = null,
    Object? metadata = freezed,
  }) {
    return _then(_$TournamentJoinRequestImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      tournamentId: null == tournamentId
          ? _value.tournamentId
          : tournamentId // ignore: cast_nullable_to_non_nullable
              as String,
      requesterId: null == requesterId
          ? _value.requesterId
          : requesterId // ignore: cast_nullable_to_non_nullable
              as String,
      requesterName: null == requesterName
          ? _value.requesterName
          : requesterName // ignore: cast_nullable_to_non_nullable
              as String,
      requesterProfileUrl: freezed == requesterProfileUrl
          ? _value.requesterProfileUrl
          : requesterProfileUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      isTeamRequest: null == isTeamRequest
          ? _value.isTeamRequest
          : isTeamRequest // ignore: cast_nullable_to_non_nullable
              as bool,
      teamId: freezed == teamId
          ? _value.teamId
          : teamId // ignore: cast_nullable_to_non_nullable
              as String?,
      teamName: freezed == teamName
          ? _value.teamName
          : teamName // ignore: cast_nullable_to_non_nullable
              as String?,
      teamLogoUrl: freezed == teamLogoUrl
          ? _value.teamLogoUrl
          : teamLogoUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      sport: freezed == sport
          ? _value.sport
          : sport // ignore: cast_nullable_to_non_nullable
              as String?,
      position: freezed == position
          ? _value.position
          : position // ignore: cast_nullable_to_non_nullable
              as String?,
      skillLevel: freezed == skillLevel
          ? _value.skillLevel
          : skillLevel // ignore: cast_nullable_to_non_nullable
              as int?,
      bio: freezed == bio
          ? _value.bio
          : bio // ignore: cast_nullable_to_non_nullable
              as String?,
      formResponses: null == formResponses
          ? _value._formResponses
          : formResponses // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      storagePath: freezed == storagePath
          ? _value.storagePath
          : storagePath // ignore: cast_nullable_to_non_nullable
              as String?,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      reviewedBy: freezed == reviewedBy
          ? _value.reviewedBy
          : reviewedBy // ignore: cast_nullable_to_non_nullable
              as String?,
      reviewedAt: freezed == reviewedAt
          ? _value.reviewedAt
          : reviewedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      reviewNote: freezed == reviewNote
          ? _value.reviewNote
          : reviewNote // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      metadata: freezed == metadata
          ? _value._metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$TournamentJoinRequestImpl implements _TournamentJoinRequest {
  const _$TournamentJoinRequestImpl(
      {required this.id,
      required this.tournamentId,
      required this.requesterId,
      required this.requesterName,
      this.requesterProfileUrl,
      required this.isTeamRequest,
      this.teamId,
      this.teamName,
      this.teamLogoUrl,
      this.sport,
      this.position,
      this.skillLevel,
      this.bio,
      final Map<String, dynamic> formResponses = const {},
      this.storagePath,
      this.status = 'pending',
      this.reviewedBy,
      @TimestampConverter() this.reviewedAt,
      this.reviewNote,
      @TimestampConverter() required this.createdAt,
      final Map<String, dynamic>? metadata})
      : _formResponses = formResponses,
        _metadata = metadata;

  factory _$TournamentJoinRequestImpl.fromJson(Map<String, dynamic> json) =>
      _$$TournamentJoinRequestImplFromJson(json);

  @override
  final String id;
  @override
  final String tournamentId;
  @override
  final String requesterId;
  @override
  final String requesterName;
  @override
  final String? requesterProfileUrl;
// Request type
  @override
  final bool isTeamRequest;
// true for team, false for individual
  @override
  final String? teamId;
  @override
  final String? teamName;
  @override
  final String? teamLogoUrl;
// Player details (for individual requests)
  @override
  final String? sport;
  @override
  final String? position;
  @override
  final int? skillLevel;
  @override
  final String? bio;
  final Map<String, dynamic> _formResponses;
  @override
  @JsonKey()
  Map<String, dynamic> get formResponses {
    if (_formResponses is EqualUnmodifiableMapView) return _formResponses;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_formResponses);
  }

  @override
  final String? storagePath;
// Request status
  @override
  @JsonKey()
  final String status;
// 'pending', 'accepted', 'rejected'
  @override
  final String? reviewedBy;
  @override
  @TimestampConverter()
  final DateTime? reviewedAt;
  @override
  final String? reviewNote;
  @override
  @TimestampConverter()
  final DateTime createdAt;
  final Map<String, dynamic>? _metadata;
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
    return 'TournamentJoinRequest(id: $id, tournamentId: $tournamentId, requesterId: $requesterId, requesterName: $requesterName, requesterProfileUrl: $requesterProfileUrl, isTeamRequest: $isTeamRequest, teamId: $teamId, teamName: $teamName, teamLogoUrl: $teamLogoUrl, sport: $sport, position: $position, skillLevel: $skillLevel, bio: $bio, formResponses: $formResponses, storagePath: $storagePath, status: $status, reviewedBy: $reviewedBy, reviewedAt: $reviewedAt, reviewNote: $reviewNote, createdAt: $createdAt, metadata: $metadata)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TournamentJoinRequestImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.tournamentId, tournamentId) ||
                other.tournamentId == tournamentId) &&
            (identical(other.requesterId, requesterId) ||
                other.requesterId == requesterId) &&
            (identical(other.requesterName, requesterName) ||
                other.requesterName == requesterName) &&
            (identical(other.requesterProfileUrl, requesterProfileUrl) ||
                other.requesterProfileUrl == requesterProfileUrl) &&
            (identical(other.isTeamRequest, isTeamRequest) ||
                other.isTeamRequest == isTeamRequest) &&
            (identical(other.teamId, teamId) || other.teamId == teamId) &&
            (identical(other.teamName, teamName) ||
                other.teamName == teamName) &&
            (identical(other.teamLogoUrl, teamLogoUrl) ||
                other.teamLogoUrl == teamLogoUrl) &&
            (identical(other.sport, sport) || other.sport == sport) &&
            (identical(other.position, position) ||
                other.position == position) &&
            (identical(other.skillLevel, skillLevel) ||
                other.skillLevel == skillLevel) &&
            (identical(other.bio, bio) || other.bio == bio) &&
            const DeepCollectionEquality()
                .equals(other._formResponses, _formResponses) &&
            (identical(other.storagePath, storagePath) ||
                other.storagePath == storagePath) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.reviewedBy, reviewedBy) ||
                other.reviewedBy == reviewedBy) &&
            (identical(other.reviewedAt, reviewedAt) ||
                other.reviewedAt == reviewedAt) &&
            (identical(other.reviewNote, reviewNote) ||
                other.reviewNote == reviewNote) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            const DeepCollectionEquality().equals(other._metadata, _metadata));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        id,
        tournamentId,
        requesterId,
        requesterName,
        requesterProfileUrl,
        isTeamRequest,
        teamId,
        teamName,
        teamLogoUrl,
        sport,
        position,
        skillLevel,
        bio,
        const DeepCollectionEquality().hash(_formResponses),
        storagePath,
        status,
        reviewedBy,
        reviewedAt,
        reviewNote,
        createdAt,
        const DeepCollectionEquality().hash(_metadata)
      ]);

  /// Create a copy of TournamentJoinRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TournamentJoinRequestImplCopyWith<_$TournamentJoinRequestImpl>
      get copyWith => __$$TournamentJoinRequestImplCopyWithImpl<
          _$TournamentJoinRequestImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TournamentJoinRequestImplToJson(
      this,
    );
  }
}

abstract class _TournamentJoinRequest implements TournamentJoinRequest {
  const factory _TournamentJoinRequest(
      {required final String id,
      required final String tournamentId,
      required final String requesterId,
      required final String requesterName,
      final String? requesterProfileUrl,
      required final bool isTeamRequest,
      final String? teamId,
      final String? teamName,
      final String? teamLogoUrl,
      final String? sport,
      final String? position,
      final int? skillLevel,
      final String? bio,
      final Map<String, dynamic> formResponses,
      final String? storagePath,
      final String status,
      final String? reviewedBy,
      @TimestampConverter() final DateTime? reviewedAt,
      final String? reviewNote,
      @TimestampConverter() required final DateTime createdAt,
      final Map<String, dynamic>? metadata}) = _$TournamentJoinRequestImpl;

  factory _TournamentJoinRequest.fromJson(Map<String, dynamic> json) =
      _$TournamentJoinRequestImpl.fromJson;

  @override
  String get id;
  @override
  String get tournamentId;
  @override
  String get requesterId;
  @override
  String get requesterName;
  @override
  String? get requesterProfileUrl; // Request type
  @override
  bool get isTeamRequest; // true for team, false for individual
  @override
  String? get teamId;
  @override
  String? get teamName;
  @override
  String? get teamLogoUrl; // Player details (for individual requests)
  @override
  String? get sport;
  @override
  String? get position;
  @override
  int? get skillLevel;
  @override
  String? get bio;
  @override
  Map<String, dynamic> get formResponses;
  @override
  String? get storagePath; // Request status
  @override
  String get status; // 'pending', 'accepted', 'rejected'
  @override
  String? get reviewedBy;
  @override
  @TimestampConverter()
  DateTime? get reviewedAt;
  @override
  String? get reviewNote;
  @override
  @TimestampConverter()
  DateTime get createdAt;
  @override
  Map<String, dynamic>? get metadata;

  /// Create a copy of TournamentJoinRequest
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TournamentJoinRequestImplCopyWith<_$TournamentJoinRequestImpl>
      get copyWith => throw _privateConstructorUsedError;
}

// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'player_match_stats.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

PlayerMatchStats _$PlayerMatchStatsFromJson(Map<String, dynamic> json) {
  return _PlayerMatchStats.fromJson(json);
}

/// @nodoc
mixin _$PlayerMatchStats {
  String get playerId => throw _privateConstructorUsedError;
  String get playerName => throw _privateConstructorUsedError;
  String? get playerImageUrl =>
      throw _privateConstructorUsedError; // Common stats
  int get goals => throw _privateConstructorUsedError;
  int get assists => throw _privateConstructorUsedError;
  int get yellowCards => throw _privateConstructorUsedError;
  int get redCards =>
      throw _privateConstructorUsedError; // Cricket-specific stats
  int get runs => throw _privateConstructorUsedError;
  int get balls => throw _privateConstructorUsedError;
  int get wickets => throw _privateConstructorUsedError;
  int get catches =>
      throw _privateConstructorUsedError; // Basketball-specific stats
  int get points => throw _privateConstructorUsedError;
  int get rebounds => throw _privateConstructorUsedError;
  int get steals => throw _privateConstructorUsedError; // Generic stats
  int get fouls => throw _privateConstructorUsedError;
  int get saves => throw _privateConstructorUsedError; // Other
  Map<String, dynamic>? get customStats => throw _privateConstructorUsedError;

  /// Serializes this PlayerMatchStats to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PlayerMatchStats
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PlayerMatchStatsCopyWith<PlayerMatchStats> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PlayerMatchStatsCopyWith<$Res> {
  factory $PlayerMatchStatsCopyWith(
          PlayerMatchStats value, $Res Function(PlayerMatchStats) then) =
      _$PlayerMatchStatsCopyWithImpl<$Res, PlayerMatchStats>;
  @useResult
  $Res call(
      {String playerId,
      String playerName,
      String? playerImageUrl,
      int goals,
      int assists,
      int yellowCards,
      int redCards,
      int runs,
      int balls,
      int wickets,
      int catches,
      int points,
      int rebounds,
      int steals,
      int fouls,
      int saves,
      Map<String, dynamic>? customStats});
}

/// @nodoc
class _$PlayerMatchStatsCopyWithImpl<$Res, $Val extends PlayerMatchStats>
    implements $PlayerMatchStatsCopyWith<$Res> {
  _$PlayerMatchStatsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PlayerMatchStats
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? playerId = null,
    Object? playerName = null,
    Object? playerImageUrl = freezed,
    Object? goals = null,
    Object? assists = null,
    Object? yellowCards = null,
    Object? redCards = null,
    Object? runs = null,
    Object? balls = null,
    Object? wickets = null,
    Object? catches = null,
    Object? points = null,
    Object? rebounds = null,
    Object? steals = null,
    Object? fouls = null,
    Object? saves = null,
    Object? customStats = freezed,
  }) {
    return _then(_value.copyWith(
      playerId: null == playerId
          ? _value.playerId
          : playerId // ignore: cast_nullable_to_non_nullable
              as String,
      playerName: null == playerName
          ? _value.playerName
          : playerName // ignore: cast_nullable_to_non_nullable
              as String,
      playerImageUrl: freezed == playerImageUrl
          ? _value.playerImageUrl
          : playerImageUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      goals: null == goals
          ? _value.goals
          : goals // ignore: cast_nullable_to_non_nullable
              as int,
      assists: null == assists
          ? _value.assists
          : assists // ignore: cast_nullable_to_non_nullable
              as int,
      yellowCards: null == yellowCards
          ? _value.yellowCards
          : yellowCards // ignore: cast_nullable_to_non_nullable
              as int,
      redCards: null == redCards
          ? _value.redCards
          : redCards // ignore: cast_nullable_to_non_nullable
              as int,
      runs: null == runs
          ? _value.runs
          : runs // ignore: cast_nullable_to_non_nullable
              as int,
      balls: null == balls
          ? _value.balls
          : balls // ignore: cast_nullable_to_non_nullable
              as int,
      wickets: null == wickets
          ? _value.wickets
          : wickets // ignore: cast_nullable_to_non_nullable
              as int,
      catches: null == catches
          ? _value.catches
          : catches // ignore: cast_nullable_to_non_nullable
              as int,
      points: null == points
          ? _value.points
          : points // ignore: cast_nullable_to_non_nullable
              as int,
      rebounds: null == rebounds
          ? _value.rebounds
          : rebounds // ignore: cast_nullable_to_non_nullable
              as int,
      steals: null == steals
          ? _value.steals
          : steals // ignore: cast_nullable_to_non_nullable
              as int,
      fouls: null == fouls
          ? _value.fouls
          : fouls // ignore: cast_nullable_to_non_nullable
              as int,
      saves: null == saves
          ? _value.saves
          : saves // ignore: cast_nullable_to_non_nullable
              as int,
      customStats: freezed == customStats
          ? _value.customStats
          : customStats // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PlayerMatchStatsImplCopyWith<$Res>
    implements $PlayerMatchStatsCopyWith<$Res> {
  factory _$$PlayerMatchStatsImplCopyWith(_$PlayerMatchStatsImpl value,
          $Res Function(_$PlayerMatchStatsImpl) then) =
      __$$PlayerMatchStatsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String playerId,
      String playerName,
      String? playerImageUrl,
      int goals,
      int assists,
      int yellowCards,
      int redCards,
      int runs,
      int balls,
      int wickets,
      int catches,
      int points,
      int rebounds,
      int steals,
      int fouls,
      int saves,
      Map<String, dynamic>? customStats});
}

/// @nodoc
class __$$PlayerMatchStatsImplCopyWithImpl<$Res>
    extends _$PlayerMatchStatsCopyWithImpl<$Res, _$PlayerMatchStatsImpl>
    implements _$$PlayerMatchStatsImplCopyWith<$Res> {
  __$$PlayerMatchStatsImplCopyWithImpl(_$PlayerMatchStatsImpl _value,
      $Res Function(_$PlayerMatchStatsImpl) _then)
      : super(_value, _then);

  /// Create a copy of PlayerMatchStats
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? playerId = null,
    Object? playerName = null,
    Object? playerImageUrl = freezed,
    Object? goals = null,
    Object? assists = null,
    Object? yellowCards = null,
    Object? redCards = null,
    Object? runs = null,
    Object? balls = null,
    Object? wickets = null,
    Object? catches = null,
    Object? points = null,
    Object? rebounds = null,
    Object? steals = null,
    Object? fouls = null,
    Object? saves = null,
    Object? customStats = freezed,
  }) {
    return _then(_$PlayerMatchStatsImpl(
      playerId: null == playerId
          ? _value.playerId
          : playerId // ignore: cast_nullable_to_non_nullable
              as String,
      playerName: null == playerName
          ? _value.playerName
          : playerName // ignore: cast_nullable_to_non_nullable
              as String,
      playerImageUrl: freezed == playerImageUrl
          ? _value.playerImageUrl
          : playerImageUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      goals: null == goals
          ? _value.goals
          : goals // ignore: cast_nullable_to_non_nullable
              as int,
      assists: null == assists
          ? _value.assists
          : assists // ignore: cast_nullable_to_non_nullable
              as int,
      yellowCards: null == yellowCards
          ? _value.yellowCards
          : yellowCards // ignore: cast_nullable_to_non_nullable
              as int,
      redCards: null == redCards
          ? _value.redCards
          : redCards // ignore: cast_nullable_to_non_nullable
              as int,
      runs: null == runs
          ? _value.runs
          : runs // ignore: cast_nullable_to_non_nullable
              as int,
      balls: null == balls
          ? _value.balls
          : balls // ignore: cast_nullable_to_non_nullable
              as int,
      wickets: null == wickets
          ? _value.wickets
          : wickets // ignore: cast_nullable_to_non_nullable
              as int,
      catches: null == catches
          ? _value.catches
          : catches // ignore: cast_nullable_to_non_nullable
              as int,
      points: null == points
          ? _value.points
          : points // ignore: cast_nullable_to_non_nullable
              as int,
      rebounds: null == rebounds
          ? _value.rebounds
          : rebounds // ignore: cast_nullable_to_non_nullable
              as int,
      steals: null == steals
          ? _value.steals
          : steals // ignore: cast_nullable_to_non_nullable
              as int,
      fouls: null == fouls
          ? _value.fouls
          : fouls // ignore: cast_nullable_to_non_nullable
              as int,
      saves: null == saves
          ? _value.saves
          : saves // ignore: cast_nullable_to_non_nullable
              as int,
      customStats: freezed == customStats
          ? _value._customStats
          : customStats // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PlayerMatchStatsImpl implements _PlayerMatchStats {
  const _$PlayerMatchStatsImpl(
      {required this.playerId,
      required this.playerName,
      this.playerImageUrl,
      this.goals = 0,
      this.assists = 0,
      this.yellowCards = 0,
      this.redCards = 0,
      this.runs = 0,
      this.balls = 0,
      this.wickets = 0,
      this.catches = 0,
      this.points = 0,
      this.rebounds = 0,
      this.steals = 0,
      this.fouls = 0,
      this.saves = 0,
      final Map<String, dynamic>? customStats})
      : _customStats = customStats;

  factory _$PlayerMatchStatsImpl.fromJson(Map<String, dynamic> json) =>
      _$$PlayerMatchStatsImplFromJson(json);

  @override
  final String playerId;
  @override
  final String playerName;
  @override
  final String? playerImageUrl;
// Common stats
  @override
  @JsonKey()
  final int goals;
  @override
  @JsonKey()
  final int assists;
  @override
  @JsonKey()
  final int yellowCards;
  @override
  @JsonKey()
  final int redCards;
// Cricket-specific stats
  @override
  @JsonKey()
  final int runs;
  @override
  @JsonKey()
  final int balls;
  @override
  @JsonKey()
  final int wickets;
  @override
  @JsonKey()
  final int catches;
// Basketball-specific stats
  @override
  @JsonKey()
  final int points;
  @override
  @JsonKey()
  final int rebounds;
  @override
  @JsonKey()
  final int steals;
// Generic stats
  @override
  @JsonKey()
  final int fouls;
  @override
  @JsonKey()
  final int saves;
// Other
  final Map<String, dynamic>? _customStats;
// Other
  @override
  Map<String, dynamic>? get customStats {
    final value = _customStats;
    if (value == null) return null;
    if (_customStats is EqualUnmodifiableMapView) return _customStats;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  String toString() {
    return 'PlayerMatchStats(playerId: $playerId, playerName: $playerName, playerImageUrl: $playerImageUrl, goals: $goals, assists: $assists, yellowCards: $yellowCards, redCards: $redCards, runs: $runs, balls: $balls, wickets: $wickets, catches: $catches, points: $points, rebounds: $rebounds, steals: $steals, fouls: $fouls, saves: $saves, customStats: $customStats)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PlayerMatchStatsImpl &&
            (identical(other.playerId, playerId) ||
                other.playerId == playerId) &&
            (identical(other.playerName, playerName) ||
                other.playerName == playerName) &&
            (identical(other.playerImageUrl, playerImageUrl) ||
                other.playerImageUrl == playerImageUrl) &&
            (identical(other.goals, goals) || other.goals == goals) &&
            (identical(other.assists, assists) || other.assists == assists) &&
            (identical(other.yellowCards, yellowCards) ||
                other.yellowCards == yellowCards) &&
            (identical(other.redCards, redCards) ||
                other.redCards == redCards) &&
            (identical(other.runs, runs) || other.runs == runs) &&
            (identical(other.balls, balls) || other.balls == balls) &&
            (identical(other.wickets, wickets) || other.wickets == wickets) &&
            (identical(other.catches, catches) || other.catches == catches) &&
            (identical(other.points, points) || other.points == points) &&
            (identical(other.rebounds, rebounds) ||
                other.rebounds == rebounds) &&
            (identical(other.steals, steals) || other.steals == steals) &&
            (identical(other.fouls, fouls) || other.fouls == fouls) &&
            (identical(other.saves, saves) || other.saves == saves) &&
            const DeepCollectionEquality()
                .equals(other._customStats, _customStats));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      playerId,
      playerName,
      playerImageUrl,
      goals,
      assists,
      yellowCards,
      redCards,
      runs,
      balls,
      wickets,
      catches,
      points,
      rebounds,
      steals,
      fouls,
      saves,
      const DeepCollectionEquality().hash(_customStats));

  /// Create a copy of PlayerMatchStats
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PlayerMatchStatsImplCopyWith<_$PlayerMatchStatsImpl> get copyWith =>
      __$$PlayerMatchStatsImplCopyWithImpl<_$PlayerMatchStatsImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PlayerMatchStatsImplToJson(
      this,
    );
  }
}

abstract class _PlayerMatchStats implements PlayerMatchStats {
  const factory _PlayerMatchStats(
      {required final String playerId,
      required final String playerName,
      final String? playerImageUrl,
      final int goals,
      final int assists,
      final int yellowCards,
      final int redCards,
      final int runs,
      final int balls,
      final int wickets,
      final int catches,
      final int points,
      final int rebounds,
      final int steals,
      final int fouls,
      final int saves,
      final Map<String, dynamic>? customStats}) = _$PlayerMatchStatsImpl;

  factory _PlayerMatchStats.fromJson(Map<String, dynamic> json) =
      _$PlayerMatchStatsImpl.fromJson;

  @override
  String get playerId;
  @override
  String get playerName;
  @override
  String? get playerImageUrl; // Common stats
  @override
  int get goals;
  @override
  int get assists;
  @override
  int get yellowCards;
  @override
  int get redCards; // Cricket-specific stats
  @override
  int get runs;
  @override
  int get balls;
  @override
  int get wickets;
  @override
  int get catches; // Basketball-specific stats
  @override
  int get points;
  @override
  int get rebounds;
  @override
  int get steals; // Generic stats
  @override
  int get fouls;
  @override
  int get saves; // Other
  @override
  Map<String, dynamic>? get customStats;

  /// Create a copy of PlayerMatchStats
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PlayerMatchStatsImplCopyWith<_$PlayerMatchStatsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

TournamentTeam _$TournamentTeamFromJson(Map<String, dynamic> json) {
  return _TournamentTeam.fromJson(json);
}

/// @nodoc
mixin _$TournamentTeam {
  String get id => throw _privateConstructorUsedError;
  String get tournamentId => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String? get logoUrl => throw _privateConstructorUsedError;
  String? get coachId => throw _privateConstructorUsedError;
  String? get coachName => throw _privateConstructorUsedError;
  String? get coachImageUrl => throw _privateConstructorUsedError;
  String? get captainId => throw _privateConstructorUsedError;
  String? get captainName => throw _privateConstructorUsedError;
  List<String> get playerIds => throw _privateConstructorUsedError;
  List<String> get playerNames => throw _privateConstructorUsedError;
  bool get isActive => throw _privateConstructorUsedError;
  int get wins => throw _privateConstructorUsedError;
  int get losses => throw _privateConstructorUsedError;
  int get draws => throw _privateConstructorUsedError;
  int get points => throw _privateConstructorUsedError;
  int get goalsFor => throw _privateConstructorUsedError;
  int get goalsAgainst => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError;
  String? get createdBy => throw _privateConstructorUsedError;

  /// Serializes this TournamentTeam to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TournamentTeam
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TournamentTeamCopyWith<TournamentTeam> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TournamentTeamCopyWith<$Res> {
  factory $TournamentTeamCopyWith(
          TournamentTeam value, $Res Function(TournamentTeam) then) =
      _$TournamentTeamCopyWithImpl<$Res, TournamentTeam>;
  @useResult
  $Res call(
      {String id,
      String tournamentId,
      String name,
      String? logoUrl,
      String? coachId,
      String? coachName,
      String? coachImageUrl,
      String? captainId,
      String? captainName,
      List<String> playerIds,
      List<String> playerNames,
      bool isActive,
      int wins,
      int losses,
      int draws,
      int points,
      int goalsFor,
      int goalsAgainst,
      DateTime? createdAt,
      String? createdBy});
}

/// @nodoc
class _$TournamentTeamCopyWithImpl<$Res, $Val extends TournamentTeam>
    implements $TournamentTeamCopyWith<$Res> {
  _$TournamentTeamCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TournamentTeam
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? tournamentId = null,
    Object? name = null,
    Object? logoUrl = freezed,
    Object? coachId = freezed,
    Object? coachName = freezed,
    Object? coachImageUrl = freezed,
    Object? captainId = freezed,
    Object? captainName = freezed,
    Object? playerIds = null,
    Object? playerNames = null,
    Object? isActive = null,
    Object? wins = null,
    Object? losses = null,
    Object? draws = null,
    Object? points = null,
    Object? goalsFor = null,
    Object? goalsAgainst = null,
    Object? createdAt = freezed,
    Object? createdBy = freezed,
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
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      logoUrl: freezed == logoUrl
          ? _value.logoUrl
          : logoUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      coachId: freezed == coachId
          ? _value.coachId
          : coachId // ignore: cast_nullable_to_non_nullable
              as String?,
      coachName: freezed == coachName
          ? _value.coachName
          : coachName // ignore: cast_nullable_to_non_nullable
              as String?,
      coachImageUrl: freezed == coachImageUrl
          ? _value.coachImageUrl
          : coachImageUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      captainId: freezed == captainId
          ? _value.captainId
          : captainId // ignore: cast_nullable_to_non_nullable
              as String?,
      captainName: freezed == captainName
          ? _value.captainName
          : captainName // ignore: cast_nullable_to_non_nullable
              as String?,
      playerIds: null == playerIds
          ? _value.playerIds
          : playerIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      playerNames: null == playerNames
          ? _value.playerNames
          : playerNames // ignore: cast_nullable_to_non_nullable
              as List<String>,
      isActive: null == isActive
          ? _value.isActive
          : isActive // ignore: cast_nullable_to_non_nullable
              as bool,
      wins: null == wins
          ? _value.wins
          : wins // ignore: cast_nullable_to_non_nullable
              as int,
      losses: null == losses
          ? _value.losses
          : losses // ignore: cast_nullable_to_non_nullable
              as int,
      draws: null == draws
          ? _value.draws
          : draws // ignore: cast_nullable_to_non_nullable
              as int,
      points: null == points
          ? _value.points
          : points // ignore: cast_nullable_to_non_nullable
              as int,
      goalsFor: null == goalsFor
          ? _value.goalsFor
          : goalsFor // ignore: cast_nullable_to_non_nullable
              as int,
      goalsAgainst: null == goalsAgainst
          ? _value.goalsAgainst
          : goalsAgainst // ignore: cast_nullable_to_non_nullable
              as int,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      createdBy: freezed == createdBy
          ? _value.createdBy
          : createdBy // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$TournamentTeamImplCopyWith<$Res>
    implements $TournamentTeamCopyWith<$Res> {
  factory _$$TournamentTeamImplCopyWith(_$TournamentTeamImpl value,
          $Res Function(_$TournamentTeamImpl) then) =
      __$$TournamentTeamImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String tournamentId,
      String name,
      String? logoUrl,
      String? coachId,
      String? coachName,
      String? coachImageUrl,
      String? captainId,
      String? captainName,
      List<String> playerIds,
      List<String> playerNames,
      bool isActive,
      int wins,
      int losses,
      int draws,
      int points,
      int goalsFor,
      int goalsAgainst,
      DateTime? createdAt,
      String? createdBy});
}

/// @nodoc
class __$$TournamentTeamImplCopyWithImpl<$Res>
    extends _$TournamentTeamCopyWithImpl<$Res, _$TournamentTeamImpl>
    implements _$$TournamentTeamImplCopyWith<$Res> {
  __$$TournamentTeamImplCopyWithImpl(
      _$TournamentTeamImpl _value, $Res Function(_$TournamentTeamImpl) _then)
      : super(_value, _then);

  /// Create a copy of TournamentTeam
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? tournamentId = null,
    Object? name = null,
    Object? logoUrl = freezed,
    Object? coachId = freezed,
    Object? coachName = freezed,
    Object? coachImageUrl = freezed,
    Object? captainId = freezed,
    Object? captainName = freezed,
    Object? playerIds = null,
    Object? playerNames = null,
    Object? isActive = null,
    Object? wins = null,
    Object? losses = null,
    Object? draws = null,
    Object? points = null,
    Object? goalsFor = null,
    Object? goalsAgainst = null,
    Object? createdAt = freezed,
    Object? createdBy = freezed,
  }) {
    return _then(_$TournamentTeamImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      tournamentId: null == tournamentId
          ? _value.tournamentId
          : tournamentId // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      logoUrl: freezed == logoUrl
          ? _value.logoUrl
          : logoUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      coachId: freezed == coachId
          ? _value.coachId
          : coachId // ignore: cast_nullable_to_non_nullable
              as String?,
      coachName: freezed == coachName
          ? _value.coachName
          : coachName // ignore: cast_nullable_to_non_nullable
              as String?,
      coachImageUrl: freezed == coachImageUrl
          ? _value.coachImageUrl
          : coachImageUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      captainId: freezed == captainId
          ? _value.captainId
          : captainId // ignore: cast_nullable_to_non_nullable
              as String?,
      captainName: freezed == captainName
          ? _value.captainName
          : captainName // ignore: cast_nullable_to_non_nullable
              as String?,
      playerIds: null == playerIds
          ? _value._playerIds
          : playerIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      playerNames: null == playerNames
          ? _value._playerNames
          : playerNames // ignore: cast_nullable_to_non_nullable
              as List<String>,
      isActive: null == isActive
          ? _value.isActive
          : isActive // ignore: cast_nullable_to_non_nullable
              as bool,
      wins: null == wins
          ? _value.wins
          : wins // ignore: cast_nullable_to_non_nullable
              as int,
      losses: null == losses
          ? _value.losses
          : losses // ignore: cast_nullable_to_non_nullable
              as int,
      draws: null == draws
          ? _value.draws
          : draws // ignore: cast_nullable_to_non_nullable
              as int,
      points: null == points
          ? _value.points
          : points // ignore: cast_nullable_to_non_nullable
              as int,
      goalsFor: null == goalsFor
          ? _value.goalsFor
          : goalsFor // ignore: cast_nullable_to_non_nullable
              as int,
      goalsAgainst: null == goalsAgainst
          ? _value.goalsAgainst
          : goalsAgainst // ignore: cast_nullable_to_non_nullable
              as int,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      createdBy: freezed == createdBy
          ? _value.createdBy
          : createdBy // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$TournamentTeamImpl implements _TournamentTeam {
  const _$TournamentTeamImpl(
      {required this.id,
      required this.tournamentId,
      required this.name,
      this.logoUrl,
      this.coachId,
      this.coachName,
      this.coachImageUrl,
      this.captainId,
      this.captainName,
      final List<String> playerIds = const [],
      final List<String> playerNames = const [],
      this.isActive = true,
      this.wins = 0,
      this.losses = 0,
      this.draws = 0,
      this.points = 0,
      this.goalsFor = 0,
      this.goalsAgainst = 0,
      this.createdAt,
      this.createdBy})
      : _playerIds = playerIds,
        _playerNames = playerNames;

  factory _$TournamentTeamImpl.fromJson(Map<String, dynamic> json) =>
      _$$TournamentTeamImplFromJson(json);

  @override
  final String id;
  @override
  final String tournamentId;
  @override
  final String name;
  @override
  final String? logoUrl;
  @override
  final String? coachId;
  @override
  final String? coachName;
  @override
  final String? coachImageUrl;
  @override
  final String? captainId;
  @override
  final String? captainName;
  final List<String> _playerIds;
  @override
  @JsonKey()
  List<String> get playerIds {
    if (_playerIds is EqualUnmodifiableListView) return _playerIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_playerIds);
  }

  final List<String> _playerNames;
  @override
  @JsonKey()
  List<String> get playerNames {
    if (_playerNames is EqualUnmodifiableListView) return _playerNames;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_playerNames);
  }

  @override
  @JsonKey()
  final bool isActive;
  @override
  @JsonKey()
  final int wins;
  @override
  @JsonKey()
  final int losses;
  @override
  @JsonKey()
  final int draws;
  @override
  @JsonKey()
  final int points;
  @override
  @JsonKey()
  final int goalsFor;
  @override
  @JsonKey()
  final int goalsAgainst;
  @override
  final DateTime? createdAt;
  @override
  final String? createdBy;

  @override
  String toString() {
    return 'TournamentTeam(id: $id, tournamentId: $tournamentId, name: $name, logoUrl: $logoUrl, coachId: $coachId, coachName: $coachName, coachImageUrl: $coachImageUrl, captainId: $captainId, captainName: $captainName, playerIds: $playerIds, playerNames: $playerNames, isActive: $isActive, wins: $wins, losses: $losses, draws: $draws, points: $points, goalsFor: $goalsFor, goalsAgainst: $goalsAgainst, createdAt: $createdAt, createdBy: $createdBy)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TournamentTeamImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.tournamentId, tournamentId) ||
                other.tournamentId == tournamentId) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.logoUrl, logoUrl) || other.logoUrl == logoUrl) &&
            (identical(other.coachId, coachId) || other.coachId == coachId) &&
            (identical(other.coachName, coachName) ||
                other.coachName == coachName) &&
            (identical(other.coachImageUrl, coachImageUrl) ||
                other.coachImageUrl == coachImageUrl) &&
            (identical(other.captainId, captainId) ||
                other.captainId == captainId) &&
            (identical(other.captainName, captainName) ||
                other.captainName == captainName) &&
            const DeepCollectionEquality()
                .equals(other._playerIds, _playerIds) &&
            const DeepCollectionEquality()
                .equals(other._playerNames, _playerNames) &&
            (identical(other.isActive, isActive) ||
                other.isActive == isActive) &&
            (identical(other.wins, wins) || other.wins == wins) &&
            (identical(other.losses, losses) || other.losses == losses) &&
            (identical(other.draws, draws) || other.draws == draws) &&
            (identical(other.points, points) || other.points == points) &&
            (identical(other.goalsFor, goalsFor) ||
                other.goalsFor == goalsFor) &&
            (identical(other.goalsAgainst, goalsAgainst) ||
                other.goalsAgainst == goalsAgainst) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.createdBy, createdBy) ||
                other.createdBy == createdBy));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        id,
        tournamentId,
        name,
        logoUrl,
        coachId,
        coachName,
        coachImageUrl,
        captainId,
        captainName,
        const DeepCollectionEquality().hash(_playerIds),
        const DeepCollectionEquality().hash(_playerNames),
        isActive,
        wins,
        losses,
        draws,
        points,
        goalsFor,
        goalsAgainst,
        createdAt,
        createdBy
      ]);

  /// Create a copy of TournamentTeam
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TournamentTeamImplCopyWith<_$TournamentTeamImpl> get copyWith =>
      __$$TournamentTeamImplCopyWithImpl<_$TournamentTeamImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TournamentTeamImplToJson(
      this,
    );
  }
}

abstract class _TournamentTeam implements TournamentTeam {
  const factory _TournamentTeam(
      {required final String id,
      required final String tournamentId,
      required final String name,
      final String? logoUrl,
      final String? coachId,
      final String? coachName,
      final String? coachImageUrl,
      final String? captainId,
      final String? captainName,
      final List<String> playerIds,
      final List<String> playerNames,
      final bool isActive,
      final int wins,
      final int losses,
      final int draws,
      final int points,
      final int goalsFor,
      final int goalsAgainst,
      final DateTime? createdAt,
      final String? createdBy}) = _$TournamentTeamImpl;

  factory _TournamentTeam.fromJson(Map<String, dynamic> json) =
      _$TournamentTeamImpl.fromJson;

  @override
  String get id;
  @override
  String get tournamentId;
  @override
  String get name;
  @override
  String? get logoUrl;
  @override
  String? get coachId;
  @override
  String? get coachName;
  @override
  String? get coachImageUrl;
  @override
  String? get captainId;
  @override
  String? get captainName;
  @override
  List<String> get playerIds;
  @override
  List<String> get playerNames;
  @override
  bool get isActive;
  @override
  int get wins;
  @override
  int get losses;
  @override
  int get draws;
  @override
  int get points;
  @override
  int get goalsFor;
  @override
  int get goalsAgainst;
  @override
  DateTime? get createdAt;
  @override
  String? get createdBy;

  /// Create a copy of TournamentTeam
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TournamentTeamImplCopyWith<_$TournamentTeamImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

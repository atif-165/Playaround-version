import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../helpers/timestamp_converter.dart';
import '../../team/models/team_model.dart';
import 'player_match_stats.dart';

part 'tournament_match_model.freezed.dart';
part 'tournament_match_model.g.dart';

/// Enum for match status
enum TournamentMatchStatus {
  scheduled,
  live,
  completed,
  cancelled;

  String get displayName {
    switch (this) {
      case TournamentMatchStatus.scheduled:
        return 'Scheduled';
      case TournamentMatchStatus.live:
        return 'Live';
      case TournamentMatchStatus.completed:
        return 'Completed';
      case TournamentMatchStatus.cancelled:
        return 'Cancelled';
    }
  }
}

/// Type alias for backward compatibility
typedef MatchStatus = TournamentMatchStatus;

/// Model for live commentary entries
@freezed
class CommentaryEntry with _$CommentaryEntry {
  const factory CommentaryEntry({
    required String id,
    required String text,
    @TimestampConverter() required DateTime timestamp,
    String? minute, // For sports like football, cricket overs, etc.
    String? playerName,
    String? eventType, // 'goal', 'wicket', 'point', etc.
  }) = _CommentaryEntry;

  factory CommentaryEntry.fromJson(Map<String, dynamic> json) =>
      _$CommentaryEntryFromJson(json);
}

/// Model for team score in a match
@freezed
class TeamMatchScore with _$TeamMatchScore {
  const factory TeamMatchScore({
    required String teamId,
    required String teamName,
    String? teamLogoUrl,
    @Default(0) int score,
    Map<String, dynamic>?
        sportSpecificData, // For cricket: runs, wickets, overs; Basketball: quarters, etc.
    @Default([]) List<String> playerIds,
  }) = _TeamMatchScore;

  factory TeamMatchScore.fromJson(Map<String, dynamic> json) =>
      _$TeamMatchScoreFromJson(json);
}

/// Model for tournament match
@freezed
class TournamentMatch with _$TournamentMatch {
  const factory TournamentMatch({
    required String id,
    required String tournamentId,
    required String tournamentName,
    required SportType sportType,

    // Teams
    required TeamMatchScore team1,
    required TeamMatchScore team2,

    // Match details
    required String
        matchNumber, // 'Match 1', 'Quarter Final 1', 'Semi Final 1', 'Final'
    String? round, // 'Group Stage', 'Quarter Finals', 'Semi Finals', 'Finals'
    @TimestampConverter() required DateTime scheduledTime,
    @TimestampConverter() DateTime? actualStartTime,
    @TimestampConverter() DateTime? actualEndTime,

    // Status
    @Default(TournamentMatchStatus.scheduled) TournamentMatchStatus status,

    // Scores and commentary
    @Default([]) List<CommentaryEntry> commentary,
    String? result, // 'Team 1 won by 2 goals', 'Match drawn', etc.
    String? winnerTeamId,

    // Player Statistics (NEW)
    @Default([]) List<PlayerMatchStats> team1PlayerStats,
    @Default([]) List<PlayerMatchStats> team2PlayerStats,
    String? manOfTheMatch, // Player ID

    // Coaches (NEW)
    String? team1CoachId,
    String? team1CoachName,
    String? team2CoachId,
    String? team2CoachName,

    // Venue
    String? venueId,
    String? venueName,
    String? venueLocation,

    // Background Image
    String? backgroundImageUrl,

    // Metadata
    @TimestampConverter() DateTime? createdAt,
    @TimestampConverter() DateTime? updatedAt,
    String? createdBy,
    Map<String, dynamic>? metadata,
  }) = _TournamentMatch;

  factory TournamentMatch.fromJson(Map<String, dynamic> json) =>
      _$TournamentMatchFromJson(json);

  factory TournamentMatch.fromFireStore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data();
    if (data == null) {
      throw Exception('Tournament match document data is null');
    }

    final safeData = Map<String, dynamic>.from(data);
    safeData['id'] ??= snapshot.id;

    String? normalizeTimestampValue(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) {
        return value.toDate().toIso8601String();
      }
      if (value is DateTime) {
        return value.toIso8601String();
      }
      if (value is int) {
        return DateTime.fromMillisecondsSinceEpoch(value).toIso8601String();
      }
      if (value is String) {
        return value;
      }
      try {
        return value.toString();
      } catch (_) {
        return null;
      }
    }

    void ensureString(String key) {
      final value = safeData[key];
      if (value == null) return;
      if (value is! String) {
        safeData[key] = value.toString();
      }
    }

    void ensureTimestampString(String key) {
      final normalized = normalizeTimestampValue(safeData[key]);
      if (normalized != null) {
        safeData[key] = normalized;
      }
    }

    for (final key in [
      'tournamentId',
      'tournamentName',
      'matchNumber',
      'round',
      'result',
      'winnerTeamId',
      'team1CoachId',
      'team1CoachName',
      'team2CoachId',
      'team2CoachName',
      'venueId',
      'venueName',
      'venueLocation',
      'backgroundImageUrl',
      'createdBy',
    ]) {
      ensureString(key);
    }

    // Normalize nested team1 and team2 objects
    void normalizeTeam(Map<String, dynamic> team) {
      // Normalize all string fields defensively
      for (final key in ['teamId', 'teamName', 'teamLogoUrl']) {
        if (team[key] != null && team[key] is! String) {
          try {
            team[key] = team[key].toString();
          } catch (_) {
            team[key] = '';
          }
        }
      }
      // Normalize playerIds array
      if (team['playerIds'] is List) {
        try {
          team['playerIds'] = (team['playerIds'] as List)
              .map((id) {
                if (id is String) return id;
                try {
                  return id.toString();
                } catch (_) {
                  return '';
                }
              })
              .where((id) => id.isNotEmpty)
              .toList();
        } catch (_) {
          team['playerIds'] = <String>[];
        }
      } else if (team['playerIds'] == null) {
        team['playerIds'] = <String>[];
      }
      // Ensure score is an int
      if (team['score'] != null && team['score'] is! int) {
        try {
          team['score'] = (team['score'] as num).toInt();
        } catch (_) {
          team['score'] = 0;
        }
      } else if (team['score'] == null) {
        team['score'] = 0;
      }
    }

    if (safeData['team1'] is Map) {
      final team1 = Map<String, dynamic>.from(safeData['team1'] as Map);
      normalizeTeam(team1);
      safeData['team1'] = team1;
    }

    if (safeData['team2'] is Map) {
      final team2 = Map<String, dynamic>.from(safeData['team2'] as Map);
      normalizeTeam(team2);
      safeData['team2'] = team2;
    }

    // Normalize commentary array
    if (safeData['commentary'] is List) {
      try {
        final commentary = (safeData['commentary'] as List).map((entry) {
          if (entry is! Map) return entry;
          try {
            final normalized = Map<String, dynamic>.from(entry as Map);
            // Normalize all string fields in commentary
            for (final key in ['id', 'text', 'minute', 'playerName', 'eventType']) {
              if (normalized[key] != null && normalized[key] is! String) {
                try {
                  normalized[key] = normalized[key].toString();
                } catch (_) {
                  normalized[key] = '';
                }
              }
            }
            if (normalized['timestamp'] != null) {
              final timestampString = normalizeTimestampValue(normalized['timestamp']);
              if (timestampString != null) {
                normalized['timestamp'] = timestampString;
              }
            }
            return normalized;
          } catch (_) {
            return entry;
          }
        }).toList();
        safeData['commentary'] = commentary;
      } catch (_) {
        safeData['commentary'] = <Map<String, dynamic>>[];
      }
    } else if (safeData['commentary'] == null) {
      safeData['commentary'] = <Map<String, dynamic>>[];
    }

    for (final key in [
      'scheduledTime',
      'scheduledDate',
      'actualStartTime',
      'actualEndTime',
      'createdAt',
      'updatedAt',
    ]) {
      ensureTimestampString(key);
    }

    // Normalize status field (might be string instead of enum)
    if (safeData['status'] != null && safeData['status'] is! String) {
      safeData['status'] = safeData['status'].toString();
    }

    // Normalize sportType field (might be string instead of enum)
    if (safeData['sportType'] != null && safeData['sportType'] is! String) {
      safeData['sportType'] = safeData['sportType'].toString();
    }

    // Normalize manOfTheMatch field
    if (safeData['manOfTheMatch'] != null && safeData['manOfTheMatch'] is! String) {
      safeData['manOfTheMatch'] = safeData['manOfTheMatch'].toString();
    }

    try {
      return TournamentMatch.fromJson(safeData);
    } catch (e) {
      // If fromJson still fails, try to provide defaults for missing required fields
      safeData['id'] ??= snapshot.id;
      safeData['tournamentId'] ??= '';
      safeData['tournamentName'] ??= 'Unknown Tournament';
      safeData['matchNumber'] ??= 'Match ${snapshot.id.substring(0, 8)}';
      safeData['sportType'] ??= 'football';
      safeData['scheduledTime'] ??= DateTime.now().toIso8601String();
      ensureTimestampString('scheduledTime');
      
      // Ensure team1 and team2 exist with minimal structure
      if (safeData['team1'] is! Map) {
        safeData['team1'] = {
          'teamId': '',
          'teamName': 'Team 1',
          'score': 0,
          'playerIds': <String>[],
        };
      }
      if (safeData['team2'] is! Map) {
        safeData['team2'] = {
          'teamId': '',
          'teamName': 'Team 2',
          'score': 0,
          'playerIds': <String>[],
        };
      }

      return TournamentMatch.fromJson(safeData);
    }
  }
}

/// Extension methods for TournamentMatch
extension TournamentMatchExtensions on TournamentMatch {
  /// Check if match is live
  bool get isLive => status == TournamentMatchStatus.live;

  /// Check if match is completed
  bool get isCompleted => status == TournamentMatchStatus.completed;

  /// Check if match is upcoming
  bool get isUpcoming => status == TournamentMatchStatus.scheduled;

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
  int get scoreDifference => (team1.score - team2.score).abs();

  /// Get winning team
  TeamMatchScore? get winningTeam {
    if (!isCompleted) return null;
    if (team1.score > team2.score) return team1;
    if (team2.score > team1.score) return team2;
    return null;
  }

  /// Get latest commentary
  List<CommentaryEntry> get latestCommentary {
    final sorted = List<CommentaryEntry>.from(commentary);
    sorted.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return sorted.take(10).toList();
  }

  /// Get score summary
  String get scoreSummary =>
      '${team1.teamName} ${team1.score} - ${team2.score} ${team2.teamName}';

  /// Check if user can edit match
  bool canUserEdit(String? currentUserId) {
    return createdBy == currentUserId;
  }

  // Backward compatibility getters
  /// Alias for scheduledTime (backward compatibility)
  DateTime get scheduledDate => scheduledTime;

  /// Get team 1 ID (backward compatibility)
  String get team1Id => team1.teamId;

  /// Get team 1 name (backward compatibility)
  String get team1Name => team1.teamName;

  /// Get team 1 score (backward compatibility)
  int get team1Score => team1.score;

  /// Get team 2 ID (backward compatibility)
  String get team2Id => team2.teamId;

  /// Get team 2 name (backward compatibility)
  String get team2Name => team2.teamName;

  /// Get team 2 score (backward compatibility)
  int get team2Score => team2.score;

  /// Get winner team name (backward compatibility)
  String? get winnerTeamName {
    if (winnerTeamId == null) return null;
    if (winnerTeamId == team1.teamId) return team1.teamName;
    if (winnerTeamId == team2.teamId) return team2.teamName;
    return null;
  }

  /// Convert to Map (backward compatibility)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tournamentId': tournamentId,
      'tournamentName': tournamentName,
      'sportType': sportType.name,
      'team1Id': team1.teamId,
      'team1Name': team1.teamName,
      'team1Score': team1.score,
      'team2Id': team2.teamId,
      'team2Name': team2.teamName,
      'team2Score': team2.score,
      'matchNumber': matchNumber,
      'round': round,
      'scheduledDate': Timestamp.fromDate(scheduledTime),
      'scheduledTime': Timestamp.fromDate(scheduledTime),
      'actualStartTime':
          actualStartTime != null ? Timestamp.fromDate(actualStartTime!) : null,
      'actualEndTime':
          actualEndTime != null ? Timestamp.fromDate(actualEndTime!) : null,
      'status': status.name,
      'result': result,
      'winnerTeamId': winnerTeamId,
      'venueId': venueId,
      'venueName': venueName,
      'venueLocation': venueLocation,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'createdBy': createdBy,
      'metadata': metadata,
    };
  }
}

/// Model for join request
@freezed
class TournamentJoinRequest with _$TournamentJoinRequest {
  const factory TournamentJoinRequest({
    required String id,
    required String tournamentId,
    required String requesterId,
    required String requesterName,
    String? requesterProfileUrl,

    // Request type
    required bool isTeamRequest, // true for team, false for individual
    String? teamId,
    String? teamName,
    String? teamLogoUrl,

    // Player details (for individual requests)
    String? sport,
    String? position,
    int? skillLevel,
    String? bio,
    @Default({}) Map<String, dynamic> formResponses,
    String? storagePath,

    // Request status
    @Default('pending') String status, // 'pending', 'accepted', 'rejected'
    String? reviewedBy,
    @TimestampConverter() DateTime? reviewedAt,
    String? reviewNote,
    @TimestampConverter() required DateTime createdAt,
    Map<String, dynamic>? metadata,
  }) = _TournamentJoinRequest;

  factory TournamentJoinRequest.fromJson(Map<String, dynamic> json) =>
      _$TournamentJoinRequestFromJson(json);

  factory TournamentJoinRequest.fromFireStore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data();
    if (data == null) {
      throw Exception('Join request document data is null');
    }

    final safeData = Map<String, dynamic>.from(data);
    safeData['id'] ??= snapshot.id;
    safeData['storagePath'] ??= snapshot.reference.path;

    return TournamentJoinRequest.fromJson(safeData);
  }
}

/// Extension for join requests
extension TournamentJoinRequestExtensions on TournamentJoinRequest {
  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isRejected => status == 'rejected';
}

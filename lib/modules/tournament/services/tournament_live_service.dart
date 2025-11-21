import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../../services/notification_service.dart';
import '../../../models/notification_model.dart';
import '../models/tournament_model.dart';
import '../models/tournament_match_model.dart';
import '../../team/models/team_model.dart';

/// Service for live tournament updates and real-time notifications
class TournamentLiveService {
  static final TournamentLiveService _instance =
      TournamentLiveService._internal();
  factory TournamentLiveService() => _instance;
  TournamentLiveService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final NotificationService _notificationService = NotificationService();

  // Stream controllers for real-time updates
  final Map<String, StreamController<Tournament>> _tournamentStreams = {};
  final Map<String, StreamController<List<TournamentMatch>>> _matchStreams = {};
  final Map<String, StreamController<Map<String, int>>> _leaderboardStreams =
      {};

  // Cached latest snapshots so late subscribers receive data immediately
  final Map<String, Tournament> _latestTournamentSnapshot = {};
  final Map<String, List<TournamentMatch>> _latestMatchSnapshot = {};
  final Map<String, Map<String, int>> _latestLeaderboardSnapshot = {};

  // Collection references
  CollectionReference get _tournamentsCollection =>
      _firestore.collection('tournaments');
  CollectionReference get _matchesCollection =>
      _firestore.collection('tournament_matches');
  CollectionReference get _notificationsCollection =>
      _firestore.collection('tournament_notifications');

  /// Get real-time tournament updates
  Stream<Tournament> getTournamentUpdates(String tournamentId) {
    if (!_tournamentStreams.containsKey(tournamentId)) {
      late final StreamController<Tournament> controller;
      controller = StreamController<Tournament>.broadcast(
        onListen: () {
          final cached = _latestTournamentSnapshot[tournamentId];
          if (cached != null) {
            controller.add(cached);
          }
        },
      );
      _tournamentStreams[tournamentId] = controller;
      _startTournamentListener(tournamentId);
    }
    return _tournamentStreams[tournamentId]!.stream;
  }

  /// Get real-time match updates for a tournament
  Stream<List<TournamentMatch>> getMatchUpdates(String tournamentId) {
    if (!_matchStreams.containsKey(tournamentId)) {
      late final StreamController<List<TournamentMatch>> controller;
      controller = StreamController<List<TournamentMatch>>.broadcast(
        onListen: () {
          final cached = _latestMatchSnapshot[tournamentId];
          if (cached != null) {
            controller.add(List<TournamentMatch>.from(cached));
          }
        },
      );
      _matchStreams[tournamentId] = controller;
      _startMatchListener(tournamentId);
    }
    return _matchStreams[tournamentId]!.stream;
  }

  /// Get real-time leaderboard updates
  Stream<Map<String, int>> getLeaderboardUpdates(String tournamentId) {
    if (!_leaderboardStreams.containsKey(tournamentId)) {
      late final StreamController<Map<String, int>> controller;
      controller = StreamController<Map<String, int>>.broadcast(
        onListen: () {
          final cached = _latestLeaderboardSnapshot[tournamentId];
          if (cached != null) {
            controller.add(Map<String, int>.from(cached));
          }
        },
      );
      _leaderboardStreams[tournamentId] = controller;
      _startLeaderboardListener(tournamentId);
    }
    return _leaderboardStreams[tournamentId]!.stream;
  }

  /// Start listening to tournament changes
  void _startTournamentListener(String tournamentId) {
    _tournamentsCollection.doc(tournamentId).snapshots().listen((snapshot) {
      if (snapshot.exists) {
        final tournament =
            Tournament.fromMap(snapshot.data() as Map<String, dynamic>);
        _latestTournamentSnapshot[tournamentId] = tournament;
        _tournamentStreams[tournamentId]?.add(tournament);
      }
    });
  }

  /// Start listening to match changes
  void _startMatchListener(String tournamentId) {
    _matchesCollection
        .where('tournamentId', isEqualTo: tournamentId)
        .orderBy('scheduledTime', descending: false)
        .snapshots()
        .listen((snapshot) {
      final matches = snapshot.docs
          .map((doc) {
            try {
              final data = Map<String, dynamic>.from(
                doc.data() as Map<String, dynamic>,
              );
              data['id'] ??= doc.id;
              return TournamentMatch.fromJson(data);
            } catch (e) {
              if (kDebugMode) {
                debugPrint('Error parsing match: $e');
              }
              return null;
            }
          })
          .whereType<TournamentMatch>()
          .toList();
      _latestMatchSnapshot[tournamentId] = matches;
      _matchStreams[tournamentId]?.add(matches);
    });
  }

  /// Start listening to leaderboard changes
  void _startLeaderboardListener(String tournamentId) {
    _tournamentsCollection.doc(tournamentId).snapshots().listen((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        final teamPoints = Map<String, int>.from(data['teamPoints'] ?? {});
        _latestLeaderboardSnapshot[tournamentId] = teamPoints;
        _leaderboardStreams[tournamentId]?.add(teamPoints);
      }
    });
  }

  /// Update match score in real-time
  Future<void> updateMatchScore({
    required String tournamentId,
    required String matchId,
    required int team1Score,
    required int team2Score,
    String? winnerTeamId,
    String? winnerTeamName,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Update match in matches collection
      await _matchesCollection.doc(matchId).update({
        'team1.score': team1Score,
        'team2.score': team2Score,
        'winnerTeamId': winnerTeamId,
        'status': TournamentMatchStatus.completed.name,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      // Note: Matches are now managed separately via TournamentMatchService
      // We only need to update the tournament timestamp
      await _tournamentsCollection.doc(tournamentId).update({
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      // Update team points if there's a winner
      if (winnerTeamId != null) {
        await _updateTeamPoints(tournamentId, winnerTeamId);
      }

      // Send live notifications
      final winnerName =
          winnerTeamId != null ? (winnerTeamId == '' ? null : 'Winner') : null;
      await _sendScoreUpdateNotifications(
          tournamentId, matchId, team1Score, team2Score, winnerName);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ TournamentLiveService: Error updating match score - $e');
      }
      throw Exception('Failed to update match score: $e');
    }
  }

  /// Update team points
  Future<void> _updateTeamPoints(
      String tournamentId, String winnerTeamId) async {
    final tournamentDoc = await _tournamentsCollection.doc(tournamentId).get();
    if (tournamentDoc.exists) {
      final tournamentData = tournamentDoc.data() as Map<String, dynamic>;
      final currentPoints =
          Map<String, int>.from(tournamentData['teamPoints'] ?? {});
      currentPoints[winnerTeamId] =
          (currentPoints[winnerTeamId] ?? 0) + 3; // 3 points for a win

      await _tournamentsCollection.doc(tournamentId).update({
        'teamPoints': currentPoints,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    }
  }

  /// Send live notifications for score updates
  Future<void> _sendScoreUpdateNotifications(
    String tournamentId,
    String matchId,
    int team1Score,
    int team2Score,
    String? winnerTeamName,
  ) async {
    try {
      // Get tournament participants
      final participantIds = await _getTournamentParticipantIds(tournamentId);

      // Send push notifications
      for (final participantId in participantIds) {
        await _notificationService.createNotification(
          userId: participantId,
          type: NotificationType.scoreUpdate,
          title: 'Match Score Updated',
          message: winnerTeamName != null
              ? '$winnerTeamName won the match!'
              : 'Match score: $team1Score - $team2Score',
          data: {
            'tournamentId': tournamentId,
            'matchId': matchId,
            'team1Score': team1Score,
            'team2Score': team2Score,
            'winnerTeamName': winnerTeamName,
          },
        );
      }

      // Store notification in database
      await _notificationsCollection.add({
        'tournamentId': tournamentId,
        'matchId': matchId,
        'type': 'score_update',
        'title': 'Score Updated',
        'message': winnerTeamName != null
            ? '$winnerTeamName won the match!'
            : 'Match score: $team1Score - $team2Score',
        'participantIds': participantIds,
        'createdAt': Timestamp.fromDate(DateTime.now()),
        'readBy': <String>[],
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            '⚠️ TournamentLiveService: Failed to send score notifications - $e');
      }
    }
  }

  /// Send match schedule notifications
  Future<void> sendMatchScheduleNotification({
    required String tournamentId,
    required TournamentMatch match,
  }) async {
    try {
      final participantIds = await _getTournamentParticipantIds(tournamentId);

      for (final participantId in participantIds) {
        await _notificationService.createNotification(
          userId: participantId,
          type: NotificationType.matchScheduled,
          title: 'Match Scheduled',
          message: '${match.team1Name} vs ${match.team2Name}',
          data: {
            'tournamentId': tournamentId,
            'matchId': match.id,
            'team1Name': match.team1Name,
            'team2Name': match.team2Name,
            'scheduledDate': match.scheduledDate.toIso8601String(),
            'venueName': match.venueName,
          },
        );
      }

      // Store notification in database
      await _notificationsCollection.add({
        'tournamentId': tournamentId,
        'matchId': match.id,
        'type': 'match_scheduled',
        'title': 'Match Scheduled',
        'message': '${match.team1Name} vs ${match.team2Name} - ${match.round}',
        'participantIds': participantIds,
        'createdAt': Timestamp.fromDate(DateTime.now()),
        'readBy': <String>[],
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            '⚠️ TournamentLiveService: Failed to send schedule notifications - $e');
      }
    }
  }

  /// Send tournament status change notifications
  Future<void> sendTournamentStatusNotification({
    required String tournamentId,
    required TournamentStatus newStatus,
    required String tournamentName,
  }) async {
    try {
      final participantIds = await _getTournamentParticipantIds(tournamentId);

      for (final participantId in participantIds) {
        await _notificationService.createNotification(
          userId: participantId,
          type: NotificationType.tournamentUpdate,
          title: 'Tournament Status Updated',
          message: '$tournamentName status changed to ${newStatus.name}',
          data: {
            'tournamentId': tournamentId,
            'tournamentName': tournamentName,
            'newStatus': newStatus.name,
          },
        );
      }

      // Store notification in database
      await _notificationsCollection.add({
        'tournamentId': tournamentId,
        'type': 'status_change',
        'title': 'Tournament Status Updated',
        'message': '$tournamentName is now ${newStatus.displayName}',
        'participantIds': participantIds,
        'createdAt': Timestamp.fromDate(DateTime.now()),
        'readBy': <String>[],
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            '⚠️ TournamentLiveService: Failed to send status notifications - $e');
      }
    }
  }

  /// Get tournament participant IDs
  Future<List<String>> _getTournamentParticipantIds(String tournamentId) async {
    try {
      // Get all approved team registrations
      final registrationsQuery = await _firestore
          .collection('tournament_registrations')
          .where('tournamentId', isEqualTo: tournamentId)
          .where('status', isEqualTo: 'approved')
          .get();

      final participantIds = <String>{};

      for (final doc in registrationsQuery.docs) {
        final data = doc.data();
        participantIds.addAll(List<String>.from(data['teamMemberIds'] ?? []));
      }

      return participantIds.toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            '❌ TournamentLiveService: Error getting participant IDs - $e');
      }
      return [];
    }
  }

  /// Get live tournament notifications
  Stream<List<TournamentNotification>> getTournamentNotifications(
      String tournamentId) {
    return _notificationsCollection
        .where('tournamentId', isEqualTo: tournamentId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TournamentNotification.fromMap(
                doc.data() as Map<String, dynamic>))
            .toList());
  }

  /// Mark notification as read
  Future<void> markNotificationAsRead(
      String notificationId, String userId) async {
    try {
      await _notificationsCollection.doc(notificationId).update({
        'readBy': FieldValue.arrayUnion([userId]),
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            '❌ TournamentLiveService: Error marking notification as read - $e');
      }
    }
  }

  /// Clean up streams
  void dispose() {
    for (final stream in _tournamentStreams.values) {
      stream.close();
    }
    for (final stream in _matchStreams.values) {
      stream.close();
    }
    for (final stream in _leaderboardStreams.values) {
      stream.close();
    }
    _tournamentStreams.clear();
    _matchStreams.clear();
    _leaderboardStreams.clear();
    _latestTournamentSnapshot.clear();
    _latestMatchSnapshot.clear();
    _latestLeaderboardSnapshot.clear();
  }
}

/// Tournament notification model
class TournamentNotification {
  final String id;
  final String tournamentId;
  final String? matchId;
  final String type;
  final String title;
  final String message;
  final List<String> participantIds;
  final List<String> readBy;
  final DateTime createdAt;

  const TournamentNotification({
    required this.id,
    required this.tournamentId,
    this.matchId,
    required this.type,
    required this.title,
    required this.message,
    required this.participantIds,
    required this.readBy,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tournamentId': tournamentId,
      'matchId': matchId,
      'type': type,
      'title': title,
      'message': message,
      'participantIds': participantIds,
      'readBy': readBy,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory TournamentNotification.fromMap(Map<String, dynamic> map) {
    return TournamentNotification(
      id: map['id'] ?? '',
      tournamentId: map['tournamentId'] ?? '',
      matchId: map['matchId'],
      type: map['type'] ?? '',
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      participantIds: List<String>.from(map['participantIds'] ?? []),
      readBy: List<String>.from(map['readBy'] ?? []),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  bool isReadBy(String userId) => readBy.contains(userId);
}

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/tournament_match_model.dart';
import '../models/player_match_stats.dart';
import '../../team/models/team_model.dart';

class TournamentMatchService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String _matchesCollection = 'tournament_matches';
  static const String _legacyJoinRequestsCollection =
      'tournament_join_requests';
  static const String _individualJoinRequestsSubCollection =
      'joinRequests_individual';
  static const String _teamJoinRequestsSubCollection = 'joinRequests_team';

  /// Get matches collection reference
  CollectionReference<TournamentMatch> get _matchesRef =>
      _firestore.collection(_matchesCollection).withConverter<TournamentMatch>(
            fromFirestore: TournamentMatch.fromFireStore,
            toFirestore: (TournamentMatch match, _) => match.toJson(),
          );

  CollectionReference<Map<String, dynamic>> get _rawMatchesRef =>
      _firestore.collection(_matchesCollection);

  CollectionReference<TournamentJoinRequest> _typedJoinRequestsRef(
    String tournamentId, {
    required bool isTeamRequest,
  }) {
    final collectionName = isTeamRequest
        ? _teamJoinRequestsSubCollection
        : _individualJoinRequestsSubCollection;
    return _firestore
        .collection('tournaments')
        .doc(tournamentId)
        .collection(collectionName)
        .withConverter<TournamentJoinRequest>(
          fromFirestore: TournamentJoinRequest.fromFireStore,
          toFirestore: (TournamentJoinRequest request, _) {
            final json = request.toJson();
            json.remove('storagePath');
            return json;
          },
        );
  }

  /// Generate new match ID
  String get generateMatchId => _matchesRef.doc().id;

  /// Create a new match
  Future<String> createMatch({
    required String tournamentId,
    required String tournamentName,
    required SportType sportType,
    required TeamMatchScore team1,
    required TeamMatchScore team2,
    required String matchNumber,
    String? round,
    required DateTime scheduledTime,
    String? venueId,
    String? venueName,
    String? venueLocation,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final matchId = generateMatchId;
      final now = DateTime.now();

      final match = TournamentMatch(
        id: matchId,
        tournamentId: tournamentId,
        tournamentName: tournamentName,
        sportType: sportType,
        team1: team1,
        team2: team2,
        matchNumber: matchNumber,
        round: round,
        scheduledTime: scheduledTime,
        status: TournamentMatchStatus.scheduled,
        venueId: venueId,
        venueName: venueName,
        venueLocation: venueLocation,
        createdAt: now,
        updatedAt: now,
        createdBy: user.uid,
      );

      // Convert to JSON and manually serialize nested objects
      final matchJson = match.toJson();

      // Manually serialize team scores to avoid Freezed serialization bug
      matchJson['team1'] = match.team1.toJson();
      matchJson['team2'] = match.team2.toJson();

      // Manually serialize commentary list
      matchJson['commentary'] =
          match.commentary.map((entry) => entry.toJson()).toList();

      await _firestore
          .collection(_matchesCollection)
          .doc(matchId)
          .set(matchJson);

      if (kDebugMode) {
        debugPrint('Match created successfully: $matchId');
      }

      return matchId;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error creating match: $e');
      }
      rethrow;
    }
  }

  /// Update match
  Future<void> updateMatch({
    required String matchId,
    TeamMatchScore? team1,
    TeamMatchScore? team2,
    TournamentMatchStatus? status,
    DateTime? scheduledTime,
    DateTime? actualStartTime,
    DateTime? actualEndTime,
    String? result,
    String? winnerTeamId,
    String? venueId,
    String? venueName,
    String? venueLocation,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (team1 != null) updates['team1'] = team1.toJson();
      if (team2 != null) updates['team2'] = team2.toJson();
      if (status != null) updates['status'] = status.name;
      if (scheduledTime != null)
        updates['scheduledTime'] = Timestamp.fromDate(scheduledTime);
      if (actualStartTime != null)
        updates['actualStartTime'] = Timestamp.fromDate(actualStartTime);
      if (actualEndTime != null)
        updates['actualEndTime'] = Timestamp.fromDate(actualEndTime);
      if (result != null) updates['result'] = result;
      if (winnerTeamId != null) updates['winnerTeamId'] = winnerTeamId;
      if (venueId != null) updates['venueId'] = venueId;
      if (venueName != null) updates['venueName'] = venueName;
      if (venueLocation != null) updates['venueLocation'] = venueLocation;

      await _matchesRef.doc(matchId).update(updates);

      if (kDebugMode) {
        debugPrint('Match updated successfully: $matchId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error updating match: $e');
      }
      rethrow;
    }
  }

  /// Update match score
  Future<void> updateMatchScore({
    required String matchId,
    int? team1Score,
    int? team2Score,
    Map<String, dynamic>? team1SportSpecificData,
    Map<String, dynamic>? team2SportSpecificData,
  }) async {
    try {
      final matchDoc = await _matchesRef.doc(matchId).get();
      final match = matchDoc.data();

      if (match == null) throw Exception('Match not found');

      final updatedTeam1 = team1Score != null || team1SportSpecificData != null
          ? match.team1.copyWith(
              score: team1Score ?? match.team1.score,
              sportSpecificData:
                  team1SportSpecificData ?? match.team1.sportSpecificData,
            )
          : match.team1;

      final updatedTeam2 = team2Score != null || team2SportSpecificData != null
          ? match.team2.copyWith(
              score: team2Score ?? match.team2.score,
              sportSpecificData:
                  team2SportSpecificData ?? match.team2.sportSpecificData,
            )
          : match.team2;

      await _matchesRef.doc(matchId).update({
        'team1': updatedTeam1.toJson(),
        'team2': updatedTeam2.toJson(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (kDebugMode) {
        debugPrint('Match score updated: $matchId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error updating match score: $e');
      }
      rethrow;
    }
  }

  /// Add commentary to match
  Future<void> addCommentary({
    required String matchId,
    required String text,
    String? minute,
    String? playerName,
    String? eventType,
  }) async {
    try {
      final commentaryEntry = CommentaryEntry(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: text,
        timestamp: DateTime.now(),
        minute: minute,
        playerName: playerName,
        eventType: eventType,
      );

      await _matchesRef.doc(matchId).update({
        'commentary': FieldValue.arrayUnion([commentaryEntry.toJson()]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (kDebugMode) {
        debugPrint('Commentary added to match: $matchId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error adding commentary: $e');
      }
      rethrow;
    }
  }

  /// Update metadata entries for a match
  Future<void> updateMatchMetadata({
    required String matchId,
    required Map<String, dynamic> metadata,
  }) async {
    try {
      final updates = <String, dynamic>{};
      metadata.forEach((key, value) {
        updates['metadata.$key'] = value;
      });
      await _matchesRef.doc(matchId).update(updates);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error updating match metadata: $e');
      }
      rethrow;
    }
  }

  /// Start match (set to live)
  Future<void> startMatch(String matchId) async {
    try {
      await _matchesRef.doc(matchId).update({
        'status': TournamentMatchStatus.live.name,
        'actualStartTime': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (kDebugMode) {
        debugPrint('Match started: $matchId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error starting match: $e');
      }
      rethrow;
    }
  }

  /// End match
  Future<void> endMatch({
    required String matchId,
    required String result,
    String? winnerTeamId,
  }) async {
    try {
      await _matchesRef.doc(matchId).update({
        'status': TournamentMatchStatus.completed.name,
        'actualEndTime': FieldValue.serverTimestamp(),
        'result': result,
        'winnerTeamId': winnerTeamId,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (kDebugMode) {
        debugPrint('Match ended: $matchId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error ending match: $e');
      }
      rethrow;
    }
  }

  /// Get match by ID
  Future<TournamentMatch?> getMatchById(String matchId) async {
    try {
      final matchDoc = await _matchesRef.doc(matchId).get();
      return matchDoc.data();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting match: $e');
      }
      return null;
    }
  }

  /// Get matches for tournament
  Stream<List<TournamentMatch>> getTournamentMatchesStream(
      String tournamentId) {
    return _rawMatchesRef
        .where('tournamentId', isEqualTo: tournamentId)
        .snapshots()
        .map((snapshot) {
      final matches = <TournamentMatch>[];
      for (final doc in snapshot.docs) {
        try {
          matches.add(TournamentMatch.fromFireStore(doc, null));
        } catch (e) {
          if (kDebugMode) {
            debugPrint(
                'Skipping match document ${doc.id} due to conversion error: $e');
          }
        }
      }
      return _sortMatchesBySchedule(matches);
    });
  }

  /// Get live matches for tournament (client-side filter)
  Stream<List<TournamentMatch>> getLiveMatchesStream(String tournamentId) {
    return _rawMatchesRef
        .where('tournamentId', isEqualTo: tournamentId)
        .snapshots()
        .map((snapshot) {
      final matches = <TournamentMatch>[];
      for (final doc in snapshot.docs) {
        try {
          matches.add(TournamentMatch.fromFireStore(doc, null));
        } catch (e) {
          if (kDebugMode) {
            debugPrint(
                'Skipping match document ${doc.id} due to conversion error: $e');
          }
        }
      }
      final liveMatches = matches
          .where((match) => match.status == TournamentMatchStatus.live)
          .toList();
      return _sortMatchesBySchedule(liveMatches);
    });
  }

  List<TournamentMatch> _sortMatchesBySchedule(
    List<TournamentMatch> matches,
  ) {
    matches.sort((a, b) {
      final aTime = a.scheduledTime;
      final bTime = b.scheduledTime;
      if (aTime == null && bTime == null) return 0;
      if (aTime == null) return 1;
      if (bTime == null) return -1;
      return aTime.compareTo(bTime);
    });
    return matches;
  }

  /// Get match stream (for real-time updates)
  Stream<TournamentMatch?> getMatchStream(String matchId) {
    return _rawMatchesRef.doc(matchId).snapshots().map((snapshot) {
      if (!snapshot.exists) return null;
          try {
        return TournamentMatch.fromFireStore(snapshot, null);
          } catch (e) {
            if (kDebugMode) {
          debugPrint(
              'Skipping match document ${snapshot.id} due to conversion error: $e');
              }
              return null;
          }
        });
  }

  /// Delete match
  Future<void> deleteMatch(String matchId) async {
    try {
      await _matchesRef.doc(matchId).delete();

      if (kDebugMode) {
        debugPrint('Match deleted: $matchId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error deleting match: $e');
      }
      rethrow;
    }
  }

  // ============ JOIN REQUESTS ============

  DocumentReference<Map<String, dynamic>> _resolveJoinRequestDoc(
      TournamentJoinRequest request) {
    if (request.storagePath != null && request.storagePath!.isNotEmpty) {
      return _firestore.doc(request.storagePath!);
    }

    if (request.tournamentId.isEmpty) {
      return _firestore
          .collection(_legacyJoinRequestsCollection)
          .doc(request.id);
    }

    final collectionName = request.isTeamRequest
        ? _teamJoinRequestsSubCollection
        : _individualJoinRequestsSubCollection;
    return _firestore
        .collection('tournaments')
        .doc(request.tournamentId)
        .collection(collectionName)
        .doc(request.id);
  }

  /// Create join request
  Future<String> createJoinRequest({
    required String tournamentId,
    required bool isTeamRequest,
    Map<String, dynamic> formResponses = const {},
    String? teamId,
    String? teamName,
    String? teamLogoUrl,
    String? sport,
    String? position,
    int? skillLevel,
    String? bio,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final now = DateTime.now();
      final collection =
          _typedJoinRequestsRef(tournamentId, isTeamRequest: isTeamRequest);
      final resolvedId = isTeamRequest
          ? (teamId?.trim().isNotEmpty == true
              ? teamId!.trim()
              : collection.doc().id)
          : user.uid;
      final docRef = collection.doc(resolvedId);

      final request = TournamentJoinRequest(
        id: docRef.id,
        tournamentId: tournamentId,
        requesterId: user.uid,
        requesterName: user.displayName ?? 'Unknown User',
        requesterProfileUrl: user.photoURL,
        isTeamRequest: isTeamRequest,
        teamId: teamId,
        teamName: teamName,
        teamLogoUrl: teamLogoUrl,
        sport: sport,
        position: position,
        skillLevel: skillLevel,
        bio: bio,
        formResponses: formResponses,
        storagePath: docRef.path,
        createdAt: now,
      );

      await docRef.set(request);

      if (kDebugMode) {
        debugPrint(
            'Join request created (${isTeamRequest ? 'team' : 'individual'}): ${docRef.id}');
      }

      return docRef.id;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error creating join request: $e');
      }
      rethrow;
    }
  }

  /// Get independent player join requests
  Stream<List<TournamentJoinRequest>> getIndividualJoinRequestsStream(
    String tournamentId, {
    String status = 'pending',
  }) {
    return _typedJoinRequestsRef(tournamentId, isTeamRequest: false)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      final docs = snapshot.docs.map((doc) => doc.data()).toList();
      if (status.isEmpty) return docs;
      return docs.where((req) => req.status == status).toList();
    });
  }

  /// Get team join requests
  Stream<List<TournamentJoinRequest>> getTeamJoinRequestsStream(
    String tournamentId, {
    String status = 'pending',
  }) {
    return _typedJoinRequestsRef(tournamentId, isTeamRequest: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      final docs = snapshot.docs.map((doc) => doc.data()).toList();
      if (status.isEmpty) return docs;
      return docs.where((req) => req.status == status).toList();
    });
  }

  /// Review join request
  Future<void> reviewJoinRequest({
    required TournamentJoinRequest request,
    required bool accept,
    String? reviewNote,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final docRef = _resolveJoinRequestDoc(request);
      await docRef.update({
        'status': accept ? 'accepted' : 'rejected',
        'reviewedBy': user.uid,
        'reviewedAt': FieldValue.serverTimestamp(),
        'reviewNote': reviewNote,
      });

      if (kDebugMode) {
        debugPrint(
            'Join request reviewed: ${docRef.path} - ${accept ? 'accepted' : 'rejected'}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error reviewing join request: $e');
      }
      rethrow;
    }
  }

  /// Delete join request
  Future<void> deleteJoinRequest(TournamentJoinRequest request) async {
    try {
      final docRef = _resolveJoinRequestDoc(request);
      await docRef.delete();

      if (kDebugMode) {
        debugPrint('Join request deleted: ${docRef.path}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error deleting join request: $e');
      }
      rethrow;
    }
  }

  /// Update player statistics for a match
  Future<void> updatePlayerStats({
    required String matchId,
    required List<PlayerMatchStats> team1PlayerStats,
    required List<PlayerMatchStats> team2PlayerStats,
  }) async {
    try {
      await _firestore.collection(_matchesCollection).doc(matchId).update({
        'team1PlayerStats':
            team1PlayerStats.map((stat) => stat.toJson()).toList(),
        'team2PlayerStats':
            team2PlayerStats.map((stat) => stat.toJson()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (kDebugMode) {
        debugPrint('Player stats updated for match: $matchId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error updating player stats: $e');
      }
      rethrow;
    }
  }

  /// Update match coaches
  Future<void> updateCoaches({
    required String matchId,
    String? team1CoachId,
    String? team1CoachName,
    String? team2CoachId,
    String? team2CoachName,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (team1CoachId != null) updates['team1CoachId'] = team1CoachId;
      if (team1CoachName != null) updates['team1CoachName'] = team1CoachName;
      if (team2CoachId != null) updates['team2CoachId'] = team2CoachId;
      if (team2CoachName != null) updates['team2CoachName'] = team2CoachName;

      await _firestore
          .collection(_matchesCollection)
          .doc(matchId)
          .update(updates);

      if (kDebugMode) {
        debugPrint('Coaches updated for match: $matchId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error updating coaches: $e');
      }
      rethrow;
    }
  }

  /// Set man of the match
  Future<void> setManOfTheMatch({
    required String matchId,
    required String playerId,
  }) async {
    try {
      await _firestore.collection(_matchesCollection).doc(matchId).update({
        'manOfTheMatch': playerId,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (kDebugMode) {
        debugPrint('Man of the match set for match: $matchId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error setting man of the match: $e');
      }
      rethrow;
    }
  }

  /// Update match background image
  Future<void> updateMatchBackgroundImage({
    required String matchId,
    String? backgroundImageUrl,
  }) async {
    try {
      await _firestore.collection(_matchesCollection).doc(matchId).update({
        'backgroundImageUrl': backgroundImageUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (kDebugMode) {
        debugPrint('Background image updated for match: $matchId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error updating background image: $e');
      }
      rethrow;
    }
  }
}

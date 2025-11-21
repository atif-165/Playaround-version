import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/player_match_stats.dart';

class TournamentTeamService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String _tournamentTeamsCollection = 'tournament_teams';

  /// Get tournament teams collection reference
  CollectionReference<TournamentTeam> get _teamsRef => _firestore
      .collection(_tournamentTeamsCollection)
      .withConverter<TournamentTeam>(
        fromFirestore: TournamentTeam.fromFireStore,
        toFirestore: (TournamentTeam team, _) => team.toJson(),
      );

  /// Generate new team ID
  String get generateTeamId => _teamsRef.doc().id;

  /// Create a tournament team from selected players
  Future<String> createTeam({
    required String tournamentId,
    required String name,
    required List<String> playerIds,
    required List<String> playerNames,
    String? logoUrl,
    String? coachId,
    String? coachName,
    String? coachImageUrl,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final teamId = generateTeamId;
      final now = DateTime.now();
      final derivedCaptainId =
          playerIds.isNotEmpty ? playerIds.first : user.uid;
      final derivedCaptainName = playerNames.isNotEmpty
          ? playerNames.first
          : (coachName ??
              user.displayName ??
              (playerNames.isNotEmpty ? playerNames.first : 'Captain'));

      final team = TournamentTeam(
        id: teamId,
        tournamentId: tournamentId,
        name: name,
        logoUrl: logoUrl,
        coachId: coachId,
        coachName: coachName,
        coachImageUrl: coachImageUrl,
        captainId: derivedCaptainId,
        captainName: derivedCaptainName,
        playerIds: playerIds,
        playerNames: playerNames,
        createdAt: now,
        createdBy: user.uid,
      );

      // Manual serialization
      final teamJson = team.toJson();
      await _firestore
          .collection(_tournamentTeamsCollection)
          .doc(teamId)
          .set(teamJson);

      if (kDebugMode) {
        debugPrint('Tournament team created successfully: $teamId');
      }

      return teamId;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error creating tournament team: $e');
      }
      rethrow;
    }
  }

  /// Get teams for a tournament
  Stream<List<TournamentTeam>> getTeamsStream(String tournamentId) {
    return _teamsRef
        .where('tournamentId', isEqualTo: tournamentId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => doc.data())
              .where((team) => team.isActive)
              .toList(),
        );
  }

  /// Get team by ID
  Future<TournamentTeam?> getTeamById(String teamId) async {
    try {
      final teamDoc = await _teamsRef.doc(teamId).get();
      return teamDoc.data();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting team: $e');
      }
      return null;
    }
  }

  /// Update team stats
  Future<void> updateTeamStats({
    required String teamId,
    int? wins,
    int? losses,
    int? draws,
    int? points,
    int? goalsFor,
    int? goalsAgainst,
  }) async {
    try {
      final updates = <String, dynamic>{};

      if (wins != null) updates['wins'] = wins;
      if (losses != null) updates['losses'] = losses;
      if (draws != null) updates['draws'] = draws;
      if (points != null) updates['points'] = points;
      if (goalsFor != null) updates['goalsFor'] = goalsFor;
      if (goalsAgainst != null) updates['goalsAgainst'] = goalsAgainst;

      if (updates.isNotEmpty) {
        await _teamsRef.doc(teamId).update(updates);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error updating team stats: $e');
      }
      rethrow;
    }
  }

  /// Delete team
  Future<void> deleteTeam(String teamId) async {
    try {
      await _teamsRef.doc(teamId).update({'isActive': false});

      if (kDebugMode) {
        debugPrint('Team deactivated: $teamId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error deleting team: $e');
      }
      rethrow;
    }
  }

  /// Add players to team
  Future<void> addPlayersToTeam({
    required String teamId,
    required List<String> playerIds,
    required List<String> playerNames,
  }) async {
    try {
      await _teamsRef.doc(teamId).update({
        'playerIds': FieldValue.arrayUnion(playerIds),
        'playerNames': FieldValue.arrayUnion(playerNames),
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error adding players to team: $e');
      }
      rethrow;
    }
  }

  /// Remove player from team
  Future<void> removePlayerFromTeam({
    required String teamId,
    required String playerId,
    required String playerName,
  }) async {
    try {
      await _teamsRef.doc(teamId).update({
        'playerIds': FieldValue.arrayRemove([playerId]),
        'playerNames': FieldValue.arrayRemove([playerName]),
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error removing player from team: $e');
      }
      rethrow;
    }
  }
}

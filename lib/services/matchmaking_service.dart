import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/geo_models.dart';
import 'location_service.dart';

/// Model for a player match result
class PlayerMatch {
  final GeoPlayer player;
  final double matchScore; // 0-100 compatibility score
  final double? distance;
  final List<String> commonSports;
  final List<String> matchReasons;

  const PlayerMatch({
    required this.player,
    required this.matchScore,
    this.distance,
    required this.commonSports,
    required this.matchReasons,
  });
}

/// Service for intelligent player matchmaking
class MatchmakingService {
  static final MatchmakingService _instance = MatchmakingService._internal();
  factory MatchmakingService() => _instance;
  MatchmakingService._internal();

  final LocationService _locationService = LocationService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Find compatible players for matchmaking
  Future<List<PlayerMatch>> findMatches({
    required GeoPlayer currentPlayer,
    GeoPoint? userLocation,
    double maxDistance = 20.0,
    int skillTolerance = 10,
    int maxResults = 20,
  }) async {
    try {
      // Get all active players except current user
      final playersQuery = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'player')
          .where('isActive', isEqualTo: true)
          .get();

      List<GeoPlayer> potentialMatches = playersQuery.docs
          .map((doc) => GeoPlayer.fromFirestore(doc))
          .where((player) => player.uid != currentPlayer.uid)
          .toList();

      // Apply distance filter if location is available
      if (userLocation != null) {
        potentialMatches = potentialMatches.where((player) {
          final playerLocation = player.geoPoint ??
              _locationService
                  .getApproximateLocationFromString(player.location);
          if (playerLocation == null) return false;

          final distance = _locationService.calculateDistance(
            userLocation,
            playerLocation,
          );
          return distance <= maxDistance;
        }).toList();
      }

      // Calculate match scores
      List<PlayerMatch> matches = [];
      for (final player in potentialMatches) {
        final matchResult = _calculateMatchScore(
          currentPlayer,
          player,
          userLocation,
          skillTolerance,
        );

        if (matchResult != null && matchResult.matchScore > 30) {
          matches.add(matchResult);
        }
      }

      // Sort by match score (highest first)
      matches.sort((a, b) => b.matchScore.compareTo(a.matchScore));

      // Return top results
      return matches.take(maxResults).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ MatchmakingService: Error finding matches - $e');
      }
      return [];
    }
  }

  /// Calculate compatibility score between two players
  PlayerMatch? _calculateMatchScore(
    GeoPlayer currentPlayer,
    GeoPlayer otherPlayer,
    GeoPoint? userLocation,
    int skillTolerance,
  ) {
    double totalScore = 0;
    List<String> matchReasons = [];

    // 1. Sport compatibility (40% weight)
    final commonSports = currentPlayer.sportsOfInterest
        .where((sport) => otherPlayer.sportsOfInterest.contains(sport))
        .toList();

    if (commonSports.isEmpty) return null; // No common sports

    final sportScore = (commonSports.length /
            max(currentPlayer.sportsOfInterest.length,
                otherPlayer.sportsOfInterest.length)) *
        40;
    totalScore += sportScore;

    if (commonSports.length > 1) {
      matchReasons.add('${commonSports.length} sports in common');
    } else {
      matchReasons.add('Both play ${commonSports.first}');
    }

    // 2. Skill compatibility (30% weight)
    double skillScore = 0;
    int skillComparisons = 0;

    for (final sport in commonSports) {
      final currentSkill = currentPlayer.getSkillScore(sport);
      final otherSkill = otherPlayer.getSkillScore(sport);

      if (currentSkill > 0 && otherSkill > 0) {
        final skillDiff = (currentSkill - otherSkill).abs();
        if (skillDiff <= skillTolerance) {
          skillScore += (skillTolerance - skillDiff) / skillTolerance * 30;
          skillComparisons++;
        }
      }
    }

    if (skillComparisons > 0) {
      skillScore = skillScore / skillComparisons;
      totalScore += skillScore;

      final avgCurrentSkill = currentPlayer.averageSkillScore;
      final avgOtherSkill = otherPlayer.averageSkillScore;
      final skillDiff = (avgCurrentSkill - avgOtherSkill).abs();

      if (skillDiff <= 5) {
        matchReasons.add('Very similar skill level');
      } else if (skillDiff <= 10) {
        matchReasons.add('Compatible skill level');
      }
    }

    // 3. Age compatibility (10% weight)
    final ageDiff = (currentPlayer.age - otherPlayer.age).abs();
    double ageScore = 0;
    if (ageDiff <= 3) {
      ageScore = 10;
      matchReasons.add('Similar age');
    } else if (ageDiff <= 7) {
      ageScore = 7;
    } else if (ageDiff <= 12) {
      ageScore = 4;
    }
    totalScore += ageScore;

    // 4. Availability overlap (10% weight)
    final commonAvailability = currentPlayer.availability
        .where((slot) => otherPlayer.availability.contains(slot))
        .toList();

    double availabilityScore = 0;
    if (commonAvailability.isNotEmpty) {
      availabilityScore = (commonAvailability.length /
              max(currentPlayer.availability.length,
                  otherPlayer.availability.length)) *
          10;
      totalScore += availabilityScore;
      matchReasons.add('${commonAvailability.length} time slots match');
    }

    // 5. Distance bonus (10% weight)
    double? distance;
    if (userLocation != null) {
      final otherLocation = otherPlayer.geoPoint ??
          _locationService
              .getApproximateLocationFromString(otherPlayer.location);
      if (otherLocation != null) {
        distance =
            _locationService.calculateDistance(userLocation, otherLocation);

        double distanceScore = 0;
        if (distance <= 5) {
          distanceScore = 10;
          matchReasons.add('Very close by');
        } else if (distance <= 10) {
          distanceScore = 7;
          matchReasons.add('Nearby');
        } else if (distance <= 20) {
          distanceScore = 4;
        }
        totalScore += distanceScore;
      }
    }

    // Bonus for active players
    if (otherPlayer.isActive) {
      totalScore += 5;
    }

    return PlayerMatch(
      player: otherPlayer,
      matchScore: min(totalScore, 100), // Cap at 100
      distance: distance,
      commonSports: commonSports,
      matchReasons: matchReasons,
    );
  }

  /// Send a match request to another player
  Future<void> sendMatchRequest({
    required String fromPlayerId,
    required String toPlayerId,
    required double matchScore,
    required List<String> commonSports,
  }) async {
    try {
      await _firestore.collection('match_requests').add({
        'fromPlayerId': fromPlayerId,
        'toPlayerId': toPlayerId,
        'matchScore': matchScore,
        'commonSports': commonSports,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': Timestamp.fromDate(
          DateTime.now().add(const Duration(days: 7)),
        ),
      });

      if (kDebugMode) {
        debugPrint('✅ MatchmakingService: Match request sent successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ MatchmakingService: Error sending match request - $e');
      }
      rethrow;
    }
  }

  /// Get pending match requests for a player
  Future<List<Map<String, dynamic>>> getMatchRequests(String playerId) async {
    try {
      final requestsQuery = await _firestore
          .collection('match_requests')
          .where('toPlayerId', isEqualTo: playerId)
          .where('status', isEqualTo: 'pending')
          .where('expiresAt', isGreaterThan: Timestamp.now())
          .orderBy('expiresAt')
          .orderBy('createdAt', descending: true)
          .get();

      return requestsQuery.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ MatchmakingService: Error getting match requests - $e');
      }
      return [];
    }
  }

  /// Get sent match requests by a player
  Future<List<Map<String, dynamic>>> getSentMatchRequests(
      String playerId) async {
    try {
      final requestsQuery = await _firestore
          .collection('match_requests')
          .where('fromPlayerId', isEqualTo: playerId)
          .where('expiresAt', isGreaterThan: Timestamp.now())
          .orderBy('expiresAt')
          .orderBy('createdAt', descending: true)
          .get();

      return requestsQuery.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            '❌ MatchmakingService: Error getting sent match requests - $e');
      }
      return [];
    }
  }

  /// Respond to a match request
  Future<void> respondToMatchRequest({
    required String requestId,
    required bool accepted,
  }) async {
    try {
      await _firestore.collection('match_requests').doc(requestId).update({
        'status': accepted ? 'accepted' : 'declined',
        'respondedAt': FieldValue.serverTimestamp(),
      });

      if (kDebugMode) {
        debugPrint(
            '✅ MatchmakingService: Match request ${accepted ? 'accepted' : 'declined'}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            '❌ MatchmakingService: Error responding to match request - $e');
      }
      rethrow;
    }
  }
}

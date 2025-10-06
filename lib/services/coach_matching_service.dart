import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/coach_profile.dart';
import '../models/match_models.dart';


/// Model for coach match result
class CoachMatch {
  final CoachProfile coach;
  final double matchScore; // 0-100 compatibility score
  final double? distance;
  final List<String> commonSports;
  final List<String> matchReasons;

  const CoachMatch({
    required this.coach,
    required this.matchScore,
    this.distance,
    required this.commonSports,
    required this.matchReasons,
  });
}

/// Service for coach matchmaking
class CoachMatchingService {
  static final CoachMatchingService _instance = CoachMatchingService._internal();
  factory CoachMatchingService() => _instance;
  CoachMatchingService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Find compatible coaches for matchmaking
  Future<List<CoachMatch>> findCoachMatches({
    required String currentUserId,
    double maxDistance = 50.0,
    int maxResults = 20,
  }) async {
    try {
      // Get current user profile
      final currentUserDoc = await _firestore.collection('users').doc(currentUserId).get();
      if (!currentUserDoc.exists) throw Exception('User profile not found');

      final currentUserData = currentUserDoc.data() as Map<String, dynamic>;
      final currentUserLocation = currentUserData['location'] as String?;

      // Get all active coaches
      final coachesQuery = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'coach')
          .where('isProfileComplete', isEqualTo: true)
          .where('isActive', isEqualTo: true)
          .get();

      List<CoachProfile> potentialMatches = coachesQuery.docs
          .map((doc) => CoachProfile.fromFirestore(doc))
          .where((coach) => coach != null && coach.uid != currentUserId)
          .cast<CoachProfile>()
          .toList();

      // Calculate match scores
      List<CoachMatch> matches = [];
      for (final coach in potentialMatches) {
        final matchResult = _calculateCoachMatchScore(
          currentUserData,
          coach,
          currentUserLocation,
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
        debugPrint('❌ CoachMatchingService: Error finding coach matches - $e');
      }
      return [];
    }
  }

  /// Calculate compatibility score between user and coach
  CoachMatch? _calculateCoachMatchScore(
    Map<String, dynamic> currentUserData,
    CoachProfile coach,
    String? userLocation,
  ) {
    double totalScore = 0;
    List<String> matchReasons = [];
    
    // Sports compatibility (40% weight)
    final userSports = List<String>.from(currentUserData['sportsOfInterest'] ?? []);
    final commonSports = userSports.where((sport) => 
        coach.specializationSports.contains(sport)).toList();
    
    if (commonSports.isNotEmpty) {
      final sportsScore = (commonSports.length / userSports.length) * 40;
      totalScore += sportsScore;
      matchReasons.add('Common sports: ${commonSports.join(', ')}');
    }

    // Skill level compatibility (20% weight)
    final userSkillLevel = currentUserData['skillLevel'] as String?;
    if (userSkillLevel != null) {
      final skillScore = _calculateSkillCompatibility(userSkillLevel, coach.experienceYears);
      totalScore += skillScore * 20;
      if (skillScore > 0.7) {
        matchReasons.add('Good skill level match');
      }
    }

    // Experience preference (15% weight)
    final experienceScore = _calculateExperienceScore(coach.experienceYears);
    totalScore += experienceScore * 15;
    if (experienceScore > 0.8) {
      matchReasons.add('Experienced coach');
    }

    // Availability (10% weight)
    if (coach.availableTimeSlots.isNotEmpty) {
      totalScore += 10;
      matchReasons.add('Available for sessions');
    }

    // Location compatibility (10% weight)
    double? distance;
    if (userLocation != null && coach.location.isNotEmpty) {
      distance = _calculateDistance(userLocation, coach.location);
      if (distance <= 50) { // Within 50km
        final locationScore = (50 - distance) / 50 * 10;
        totalScore += locationScore;
        if (distance <= 10) {
          matchReasons.add('Very close by');
        } else if (distance <= 25) {
          matchReasons.add('Nearby');
        }
      }
    }

    // Rating and reviews (5% weight)
    // This would need to be implemented based on your rating system
    totalScore += 5; // Default score for now

    return CoachMatch(
      coach: coach,
      matchScore: totalScore.clamp(0, 100),
      distance: distance,
      commonSports: commonSports,
      matchReasons: matchReasons,
    );
  }

  double _calculateSkillCompatibility(String userSkillLevel, int coachExperience) {
    // Map skill levels to numeric values
    final skillLevels = {
      'beginner': 1,
      'intermediate': 2,
      'advanced': 3,
      'expert': 4,
    };
    
    final userLevel = skillLevels[userSkillLevel.toLowerCase()] ?? 1;
    final coachLevel = (coachExperience / 10).clamp(1, 4).round();
    
    // Calculate compatibility based on level difference
    final difference = (userLevel - coachLevel).abs();
    return (4 - difference) / 4;
  }

  double _calculateExperienceScore(int experienceYears) {
    // Prefer coaches with 2-10 years experience
    if (experienceYears >= 2 && experienceYears <= 10) {
      return 1.0;
    } else if (experienceYears < 2) {
      return 0.5;
    } else {
      return 0.8; // Very experienced coaches are good but not perfect
    }
  }

  double _calculateDistance(String location1, String location2) {
    // This is a simplified distance calculation
    // In a real app, you'd use proper geocoding and distance calculation
    // For now, return a random distance between 1-50km
    return Random().nextDouble() * 50 + 1;
  }

  /// Handle coach swipe action
  Future<bool> handleCoachSwipe({
    required String toCoachId,
    required SwipeAction action,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Record the swipe
      final swipeId = UserSwipe.generateSwipeId(user.uid, toCoachId);
      final swipe = UserSwipe(
        id: swipeId,
        fromUserId: user.uid,
        toUserId: toCoachId,
        action: action,
        createdAt: DateTime.now(),
      );

      await _firestore.collection('coach_swipes').doc(swipeId).set(swipe.toFirestore());

      // If it's a like, check for mutual like (match)
      if (action == SwipeAction.like) {
        final isMatch = await _checkForCoachMatch(user.uid, toCoachId);
        if (isMatch) {
          await _createCoachMatch(user.uid, toCoachId);
          await _sendCoachMatchNotifications(user.uid, toCoachId);
        } else {
          await _sendCoachLikeNotification(user.uid, toCoachId);
        }
        return isMatch;
      }

      return false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ CoachMatchingService: Error handling coach swipe - $e');
      }
      rethrow;
    }
  }

  Future<bool> _checkForCoachMatch(String userId, String coachId) async {
    try {
      final reverseSwipeQuery = await _firestore
          .collection('coach_swipes')
          .where('fromUserId', isEqualTo: coachId)
          .where('toUserId', isEqualTo: userId)
          .where('action', isEqualTo: SwipeAction.like.value)
          .get();

      return reverseSwipeQuery.docs.isNotEmpty;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ CoachMatchingService: Error checking for coach match - $e');
      }
      return false;
    }
  }

  Future<void> _createCoachMatch(String userId, String coachId) async {
    try {
      final matchId = UserMatch.generateMatchId(userId, coachId);
      
      // Get user and coach names
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final coachDoc = await _firestore.collection('users').doc(coachId).get();
      
      final userData = userDoc.data() as Map<String, dynamic>;
      final coachData = coachDoc.data() as Map<String, dynamic>;
      
      final match = UserMatch(
        id: matchId,
        user1Id: userId,
        user2Id: coachId,
        user1Name: userData['fullName'] as String,
        user2Name: coachData['fullName'] as String,
        user1ImageUrl: userData['profilePictureUrl'] as String?,
        user2ImageUrl: coachData['profilePictureUrl'] as String?,
        status: MatchStatus.matched,
        createdAt: DateTime.now(),
        commonSports: [], // Would be calculated based on compatibility
        compatibilityScore: 0.0, // Would be calculated
      );

      await _firestore.collection('coach_matches').doc(matchId).set(match.toFirestore());
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ CoachMatchingService: Error creating coach match - $e');
      }
      rethrow;
    }
  }

  Future<void> _sendCoachMatchNotifications(String userId, String coachId) async {
    // Implementation for sending match notifications
    // This would integrate with your notification service
  }

  Future<void> _sendCoachLikeNotification(String userId, String coachId) async {
    // Implementation for sending like notifications
    // This would integrate with your notification service
  }

  /// Add comment to coach profile
  Future<void> addCoachProfileComment({
    required String toCoachId,
    required String comment,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Get current user info
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data() as Map<String, dynamic>;

      final commentId = '${user.uid}_${toCoachId}_${DateTime.now().millisecondsSinceEpoch}';
      final profileComment = ProfileComment(
        id: commentId,
        fromUserId: user.uid,
        toUserId: toCoachId,
        fromUserName: userData['fullName'] as String,
        fromUserImageUrl: userData['profilePictureUrl'] as String?,
        comment: comment,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('coach_comments')
          .doc(commentId)
          .set(profileComment.toFirestore());
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ CoachMatchingService: Error adding coach comment - $e');
      }
      rethrow;
    }
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/match_models.dart';
import '../models/user_profile.dart';
import '../models/dashboard_models.dart';
import '../models/notification_model.dart';
import 'notification_service.dart';

/// Service for handling people search and matching functionality
class PeopleMatchingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final NotificationService _notificationService = NotificationService();

  // Collection references
  late final CollectionReference _usersCollection;
  late final CollectionReference _swipesCollection;
  late final CollectionReference _matchesCollection;
  late final CollectionReference _commentsCollection;
  late final CollectionReference _moodsCollection;

  PeopleMatchingService() {
    _usersCollection = _firestore.collection('users');
    _swipesCollection = _firestore.collection('user_swipes');
    _matchesCollection = _firestore.collection('user_matches');
    _commentsCollection = _firestore.collection('profile_comments');
    _moodsCollection = _firestore.collection('daily_moods');
  }

  /// Get potential matches for the current user
  Future<List<MatchmakingSuggestion>> getPotentialMatches({
    int limit = 20,
    List<String>? excludeUserIds,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Get current user profile
      final currentUserDoc = await _usersCollection.doc(user.uid).get();
      if (!currentUserDoc.exists) throw Exception('User profile not found');

      final currentUserData = currentUserDoc.data() as Map<String, dynamic>;
      final currentUserSports = List<String>.from(currentUserData['sportsOfInterest'] ?? []);
      final currentUserLocation = currentUserData['location'] as String?;

      // Get users that current user hasn't swiped on yet
      final swipedUserIds = await _getSwipedUserIds(user.uid);
      final allExcludeIds = [...swipedUserIds, user.uid, ...(excludeUserIds ?? [])];

      // Query for potential matches
      Query query = _usersCollection
          .where('isProfileComplete', isEqualTo: true)
          .limit(limit * 2); // Get more to filter out excluded users

      final snapshot = await query.get();
      List<MatchmakingSuggestion> suggestions = [];

      for (final doc in snapshot.docs) {
        final userData = doc.data() as Map<String, dynamic>;
        final userId = userData['uid'] as String;

        // Skip excluded users
        if (allExcludeIds.contains(userId)) continue;

        // Calculate compatibility
        final userSports = List<String>.from(userData['sportsOfInterest'] ?? []);
        final commonSports = currentUserSports.where((sport) => userSports.contains(sport)).toList();
        final compatibilityScore = _calculateCompatibilityScore(currentUserData, userData);

        // Skip if no common interests and low compatibility
        if (commonSports.isEmpty && compatibilityScore < 30) continue;

        suggestions.add(MatchmakingSuggestion(
          id: userId,
          fullName: userData['fullName'] as String,
          profilePictureUrl: userData['profilePictureUrl'] as String? ?? '',
          role: UserRole.fromString(userData['role'] as String),
          sportsOfInterest: userSports,
          location: userData['location'] as String,
          age: userData['age'] as int,
          skillLevel: userData['skillLevel'] != null 
              ? SkillLevel.fromString(userData['skillLevel'] as String)
              : null,
          bio: userData['bio'] as String? ?? '',
          compatibilityScore: compatibilityScore,
          commonInterests: commonSports,
          distance: _calculateDistance(currentUserLocation, userData['location'] as String?),
        ));

        if (suggestions.length >= limit) break;
      }

      // Sort by compatibility score
      suggestions.sort((a, b) => b.compatibilityScore.compareTo(a.compatibilityScore));

      return suggestions;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ PeopleMatchingService: Error getting potential matches - $e');
      }
      rethrow;
    }
  }

  /// Handle user swipe action
  Future<bool> handleSwipe({
    required String toUserId,
    required SwipeAction action,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Record the swipe
      final swipeId = UserSwipe.generateSwipeId(user.uid, toUserId);
      final swipe = UserSwipe(
        id: swipeId,
        fromUserId: user.uid,
        toUserId: toUserId,
        action: action,
        createdAt: DateTime.now(),
      );

      await _swipesCollection.doc(swipeId).set(swipe.toFirestore());

      // If it's a like, check for mutual like (match)
      if (action == SwipeAction.like) {
        final isMatch = await _checkForMatch(user.uid, toUserId);
        if (isMatch) {
          await _createMatch(user.uid, toUserId);
          await _sendMatchNotifications(user.uid, toUserId);
        } else {
          await _sendLikeNotification(user.uid, toUserId);
        }
        return isMatch;
      }

      return false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ PeopleMatchingService: Error handling swipe - $e');
      }
      rethrow;
    }
  }

  /// Add comment to user profile
  Future<void> addProfileComment({
    required String toUserId,
    required String comment,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Get current user info
      final currentUserDoc = await _usersCollection.doc(user.uid).get();
      final currentUserData = currentUserDoc.data() as Map<String, dynamic>;

      final commentId = _commentsCollection.doc().id;
      final profileComment = ProfileComment(
        id: commentId,
        fromUserId: user.uid,
        toUserId: toUserId,
        fromUserName: currentUserData['fullName'] as String,
        fromUserImageUrl: currentUserData['profilePictureUrl'] as String?,
        comment: comment,
        createdAt: DateTime.now(),
      );

      await _commentsCollection.doc(commentId).set(profileComment.toFirestore());

      // Send notification
      await _sendCommentNotification(user.uid, toUserId, comment);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ PeopleMatchingService: Error adding comment - $e');
      }
      rethrow;
    }
  }

  /// Update daily mood
  Future<void> updateDailyMood({
    required String mood,
    String? description,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final today = DateTime.now();
      final moodId = DailyMood.generateMoodId(user.uid, today);
      
      final dailyMood = DailyMood(
        id: moodId,
        userId: user.uid,
        mood: mood,
        description: description,
        date: DateTime(today.year, today.month, today.day),
        createdAt: DateTime.now(),
      );

      await _moodsCollection.doc(moodId).set(dailyMood.toFirestore());
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ PeopleMatchingService: Error updating mood - $e');
      }
      rethrow;
    }
  }



  /// Get list of user IDs that current user has already swiped on
  Future<List<String>> _getSwipedUserIds(String userId) async {
    try {
      final snapshot = await _swipesCollection
          .where('fromUserId', isEqualTo: userId)
          .get();

      return snapshot.docs
          .map((doc) => (doc.data() as Map<String, dynamic>)['toUserId'] as String)
          .toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ PeopleMatchingService: Error getting swiped users - $e');
      }
      return [];
    }
  }

  /// Check if there's a mutual like (match)
  Future<bool> _checkForMatch(String userId1, String userId2) async {
    try {
      final snapshot = await _swipesCollection
          .where('fromUserId', isEqualTo: userId2)
          .where('toUserId', isEqualTo: userId1)
          .where('action', isEqualTo: 'like')
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ PeopleMatchingService: Error checking for match - $e');
      }
      return false;
    }
  }

  /// Create a match between two users
  Future<void> _createMatch(String userId1, String userId2) async {
    try {
      // Get user profiles
      final user1Doc = await _usersCollection.doc(userId1).get();
      final user2Doc = await _usersCollection.doc(userId2).get();
      
      final user1Data = user1Doc.data() as Map<String, dynamic>;
      final user2Data = user2Doc.data() as Map<String, dynamic>;

      final user1Sports = List<String>.from(user1Data['sportsOfInterest'] ?? []);
      final user2Sports = List<String>.from(user2Data['sportsOfInterest'] ?? []);
      final commonSports = user1Sports.where((sport) => user2Sports.contains(sport)).toList();

      final matchId = UserMatch.generateMatchId(userId1, userId2);
      final match = UserMatch(
        id: matchId,
        user1Id: userId1,
        user2Id: userId2,
        user1Name: user1Data['fullName'] as String,
        user2Name: user2Data['fullName'] as String,
        user1ImageUrl: user1Data['profilePictureUrl'] as String?,
        user2ImageUrl: user2Data['profilePictureUrl'] as String?,
        status: MatchStatus.matched,
        createdAt: DateTime.now(),
        commonSports: commonSports,
        compatibilityScore: _calculateCompatibilityScore(user1Data, user2Data),
      );

      await _matchesCollection.doc(matchId).set(match.toFirestore());
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ PeopleMatchingService: Error creating match - $e');
      }
      rethrow;
    }
  }

  /// Calculate compatibility score between two users
  double _calculateCompatibilityScore(Map<String, dynamic> user1, Map<String, dynamic> user2) {
    double score = 0.0;

    // Sports compatibility (40% weight)
    final user1Sports = List<String>.from(user1['sportsOfInterest'] ?? []);
    final user2Sports = List<String>.from(user2['sportsOfInterest'] ?? []);
    final commonSports = user1Sports.where((sport) => user2Sports.contains(sport)).length;
    final totalSports = (user1Sports.length + user2Sports.length) / 2;
    if (totalSports > 0) {
      score += (commonSports / totalSports) * 40;
    }

    // Age compatibility (20% weight)
    final age1 = user1['age'] as int;
    final age2 = user2['age'] as int;
    final ageDiff = (age1 - age2).abs();
    final ageScore = (10 - ageDiff.clamp(0, 10)) / 10;
    score += ageScore * 20;

    // Location compatibility (20% weight)
    final location1 = user1['location'] as String?;
    final location2 = user2['location'] as String?;
    if (location1 != null && location2 != null && location1 == location2) {
      score += 20;
    }

    // Role compatibility (20% weight)
    final role1 = user1['role'] as String;
    final role2 = user2['role'] as String;
    if ((role1 == 'player' && role2 == 'coach') || (role1 == 'coach' && role2 == 'player')) {
      score += 20; // Player-coach pairs get bonus
    } else if (role1 == role2) {
      score += 15; // Same role gets some points
    }

    return score.clamp(0, 100);
  }

  /// Calculate distance between locations (simplified)
  double _calculateDistance(String? location1, String? location2) {
    // Simplified distance calculation - in real app, use proper geolocation
    if (location1 == null || location2 == null) return 999.0;
    if (location1 == location2) return 0.0;
    return 10.0; // Default distance for different locations
  }

  /// Send like notification
  Future<void> _sendLikeNotification(String fromUserId, String toUserId) async {
    try {
      final fromUserDoc = await _usersCollection.doc(fromUserId).get();
      final fromUserData = fromUserDoc.data() as Map<String, dynamic>;
      final fromUserName = fromUserData['fullName'] as String;

      await _notificationService.createNotification(
        userId: toUserId,
        type: NotificationType.profileLike,
        title: 'Someone likes you!',
        message: '$fromUserName liked your profile',
        data: {
          'fromUserId': fromUserId,
          'fromUserName': fromUserName,
        },
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ PeopleMatchingService: Error sending like notification - $e');
      }
    }
  }

  /// Send match notifications to both users
  Future<void> _sendMatchNotifications(String userId1, String userId2) async {
    try {
      final user1Doc = await _usersCollection.doc(userId1).get();
      final user2Doc = await _usersCollection.doc(userId2).get();
      
      final user1Data = user1Doc.data() as Map<String, dynamic>;
      final user2Data = user2Doc.data() as Map<String, dynamic>;

      // Notify user1
      await _notificationService.createNotification(
        userId: userId1,
        type: NotificationType.userMatch,
        title: 'It\'s a Match! 🎉',
        message: 'You and ${user2Data['fullName']} liked each other!',
        data: {
          'matchedUserId': userId2,
          'matchedUserName': user2Data['fullName'],
        },
      );

      // Notify user2
      await _notificationService.createNotification(
        userId: userId2,
        type: NotificationType.userMatch,
        title: 'It\'s a Match! 🎉',
        message: 'You and ${user1Data['fullName']} liked each other!',
        data: {
          'matchedUserId': userId1,
          'matchedUserName': user1Data['fullName'],
        },
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ PeopleMatchingService: Error sending match notifications - $e');
      }
    }
  }

  /// Send comment notification
  Future<void> _sendCommentNotification(String fromUserId, String toUserId, String comment) async {
    try {
      final fromUserDoc = await _usersCollection.doc(fromUserId).get();
      final fromUserData = fromUserDoc.data() as Map<String, dynamic>;
      final fromUserName = fromUserData['fullName'] as String;

      await _notificationService.createNotification(
        userId: toUserId,
        type: NotificationType.profileComment,
        title: 'New Comment',
        message: '$fromUserName commented on your profile: "$comment"',
        data: {
          'fromUserId': fromUserId,
          'fromUserName': fromUserName,
          'comment': comment,
        },
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ PeopleMatchingService: Error sending comment notification - $e');
      }
    }
  }
}

import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../../models/user_profile.dart';
import '../../../models/player_profile.dart';
import '../../../models/coach_profile.dart';
import '../../../repositories/user_repository.dart';
import '../../../helpers/distance_helper.dart';
import '../models/matchmaking_models.dart';
import '../../chat/services/chat_service.dart';
import '../../chat/models/connection.dart';

/// Result of a swipe action
class SwipeResult {
  final bool isMatch;
  final Match? match;
  final SwipeRecord swipeRecord;

  const SwipeResult({
    required this.isMatch,
    this.match,
    required this.swipeRecord,
  });
}

/// Service for handling matchmaking functionality
class MatchmakingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserRepository _userRepository = UserRepository();
  final ChatService _chatService = ChatService();

  // Collection references
  CollectionReference get _swipesCollection => _firestore.collection('swipes');
  CollectionReference get _matchesCollection =>
      _firestore.collection('matches');
  CollectionReference get _usersCollection => _firestore.collection('users');

  /// Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  /// Get potential matches for the current user with randomization and endless discovery
  Future<List<MatchProfile>> getPotentialMatches({
    int limit = 10,
    String? lastProfileId,
    Map<String, dynamic>? filters,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception('User not authenticated');

      final currentUserProfile =
          await _userRepository.getUserProfile(currentUser.uid);
      if (currentUserProfile == null) throw Exception('User profile not found');

      // Get all eligible users (excluding current user)
      Query query = _usersCollection
          .where('uid', isNotEqualTo: currentUser.uid)
          .where('isProfileComplete', isEqualTo: true);

      final querySnapshot = await query.get();
      final List<MatchProfile> allProfiles = [];

      // Process all users and create profiles
      for (final doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final userId = data['uid'] as String;

        // Create UserProfile from data
        final userProfile = await _createUserProfileFromData(data);
        if (userProfile == null) continue;

        // Apply filters if provided
        if (filters != null && !_matchesFilters(userProfile, data, filters)) {
          continue;
        }

        // Calculate compatibility and distance
        final compatibility =
            _calculateCompatibility(currentUserProfile, userProfile);
        final distance = _calculateDistance(currentUserProfile, userProfile);

        // Check if this user is already matched
        final isMatched = await _isUserMatched(currentUser.uid, userId);

        // Create MatchProfile
        final matchProfile = MatchProfile.fromUserProfile(
          userProfile,
          distanceKm: distance,
          compatibilityScore: compatibility,
          photos: List<String>.from(data['additionalPhotos'] ?? []),
          bio: data['bio'] as String?,
          interests: List<String>.from(data['interests'] ?? []),
          isOnline: data['isOnline'] as bool? ?? false,
          isMatched: isMatched, // Add matched status
        );

        allProfiles.add(matchProfile);
      }

      // Randomize the profiles for endless discovery
      allProfiles.shuffle(Random());

      // Prioritize profiles based on interaction history
      final swipedUserIds = await _getSwipedUserIds(currentUser.uid);
      final unswipedProfiles = allProfiles
          .where((profile) => !swipedUserIds.contains(profile.uid))
          .toList();
      final swipedProfiles = allProfiles
          .where((profile) => swipedUserIds.contains(profile.uid))
          .toList();

      // Return unswipped profiles first, then swiped ones for endless discovery
      final prioritizedProfiles = [...unswipedProfiles, ...swipedProfiles];

      // Return the requested limit
      return prioritizedProfiles.take(limit).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting potential matches: $e');
      }
      throw Exception('Failed to load potential matches');
    }
  }

  /// Record a swipe action and check for matches (only saves first interaction)
  Future<SwipeResult> recordSwipe({
    required String targetUserId,
    required SwipeAction action,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception('User not authenticated');

      // Check if there's already a swipe record between these users
      final existingSwipe =
          await _getExistingSwipe(currentUser.uid, targetUserId);

      SwipeRecord swipeRecord;

      if (existingSwipe != null) {
        // Use the existing swipe record (first interaction priority)
        swipeRecord = existingSwipe;
        if (kDebugMode) {
          debugPrint(
              'Using existing swipe record for first interaction priority');
        }
      } else {
        // Create new swipe record (this is the first interaction)
        final swipeId = _firestore.collection('temp').doc().id;
        swipeRecord = SwipeRecord(
          id: swipeId,
          swiperId: currentUser.uid,
          targetId: targetUserId,
          action: action,
          timestamp: DateTime.now(),
        );

        // Save the first swipe record
        await _swipesCollection.doc(swipeId).set(swipeRecord.toFirestore());
        if (kDebugMode) {
          debugPrint('Saved first interaction swipe: ${action.value}');
        }
      }

      // Check for match if the recorded action (first interaction) is a like or super like
      Match? match;
      bool isMatch = false;

      if (swipeRecord.action == SwipeAction.like ||
          swipeRecord.action == SwipeAction.superLike) {
        match = await _checkForMatch(
            currentUser.uid, targetUserId, swipeRecord.action);
        isMatch = match != null;
      }

      return SwipeResult(
        isMatch: isMatch,
        match: match,
        swipeRecord: swipeRecord,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error recording swipe: $e');
      }
      throw Exception('Failed to record swipe');
    }
  }

  /// Get matches for the current user
  Future<List<Match>> getUserMatches() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        if (kDebugMode) {
          debugPrint('❌ MatchmakingService: User not authenticated');
        }
        throw Exception('User not authenticated');
      }

      if (kDebugMode) {
        debugPrint(
            '🔍 MatchmakingService: Getting matches for user: ${currentUser.uid}');
      }

      final querySnapshot = await _matchesCollection
          .where('user1Id', isEqualTo: currentUser.uid)
          .where('status', isEqualTo: MatchStatus.matched.value)
          .get();

      final querySnapshot2 = await _matchesCollection
          .where('user2Id', isEqualTo: currentUser.uid)
          .where('status', isEqualTo: MatchStatus.matched.value)
          .get();

      if (kDebugMode) {
        debugPrint(
            '📊 MatchmakingService: Found ${querySnapshot.docs.length} matches as user1');
        debugPrint(
            '📊 MatchmakingService: Found ${querySnapshot2.docs.length} matches as user2');
      }

      final List<Match> matches = [];

      for (final doc in [...querySnapshot.docs, ...querySnapshot2.docs]) {
        try {
          final match = Match.fromFirestore(doc);
          if (match != null) {
            matches.add(match);
          } else {
            if (kDebugMode) {
              debugPrint(
                  '⚠️ MatchmakingService: Failed to parse match document: ${doc.id}');
            }
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint(
                '⚠️ MatchmakingService: Error parsing match document ${doc.id}: $e');
          }
        }
      }

      // Sort by creation date (newest first)
      matches.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      if (kDebugMode) {
        debugPrint(
            '✅ MatchmakingService: Successfully loaded ${matches.length} matches');
      }

      return matches;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('💥 MatchmakingService: Error getting user matches: $e');
      }
      rethrow;
    }
  }

  /// Get list of user IDs that have been swiped on
  Future<Set<String>> _getSwipedUserIds(String userId) async {
    try {
      final querySnapshot =
          await _swipesCollection.where('swiperId', isEqualTo: userId).get();

      return querySnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .map((data) => data['targetId'] as String)
          .toSet();
    } catch (e) {
      return <String>{};
    }
  }

  /// Check if two users are already matched
  Future<bool> _isUserMatched(String userId1, String userId2) async {
    try {
      // Check if there's a match between these two users
      final matchQuery1 = await _matchesCollection
          .where('user1Id', isEqualTo: userId1)
          .where('user2Id', isEqualTo: userId2)
          .where('status', isEqualTo: MatchStatus.matched.value)
          .get();

      final matchQuery2 = await _matchesCollection
          .where('user1Id', isEqualTo: userId2)
          .where('user2Id', isEqualTo: userId1)
          .where('status', isEqualTo: MatchStatus.matched.value)
          .get();

      return matchQuery1.docs.isNotEmpty || matchQuery2.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Get existing swipe record between two users (for first interaction priority)
  Future<SwipeRecord?> _getExistingSwipe(
      String swiperId, String targetId) async {
    try {
      final querySnapshot = await _swipesCollection
          .where('swiperId', isEqualTo: swiperId)
          .where('targetId', isEqualTo: targetId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        final data = doc.data() as Map<String, dynamic>;
        return SwipeRecord(
          id: data['id'] as String,
          swiperId: data['swiperId'] as String,
          targetId: data['targetId'] as String,
          action: SwipeAction.fromString(data['action'] as String),
          timestamp: (data['timestamp'] as Timestamp).toDate(),
        );
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Check if there's a mutual like to create a match
  Future<Match?> _checkForMatch(String currentUserId, String targetUserId,
      SwipeAction currentAction) async {
    try {
      // Check if target user has liked current user
      final targetSwipeQuery = await _swipesCollection
          .where('swiperId', isEqualTo: targetUserId)
          .where('targetId', isEqualTo: currentUserId)
          .where('action', whereIn: [
        SwipeAction.like.value,
        SwipeAction.superLike.value
      ]).get();

      if (targetSwipeQuery.docs.isEmpty) return null;

      // Get user profiles for match creation
      final currentUserProfile =
          await _userRepository.getUserProfile(currentUserId);
      final targetUserProfile =
          await _userRepository.getUserProfile(targetUserId);

      if (currentUserProfile == null || targetUserProfile == null) return null;

      // Check if target user super liked
      final targetSwipeData =
          targetSwipeQuery.docs.first.data() as Map<String, dynamic>;
      final targetAction =
          SwipeAction.fromString(targetSwipeData['action'] as String);

      // Calculate common sports and compatibility
      final commonSports =
          _getCommonSports(currentUserProfile, targetUserProfile);
      final compatibility =
          _calculateCompatibility(currentUserProfile, targetUserProfile);

      // Create chat room for the match
      final chatRoom = await _chatService.createDirectChat(targetUserId);

      // Automatically create accepted connection when match is created
      try {
        final connectionId = ConnectionHelper.generateConnectionId(
          currentUserId,
          targetUserId,
        );
        final now = DateTime.now();
        
        // Check if connection already exists
        final existingConnection = await _chatService.getConnection(targetUserId);
        if (existingConnection == null) {
          // Create new accepted connection directly in Firestore
          final connectionsCollection = _firestore.collection('connections');
          await connectionsCollection.doc(connectionId).set({
            'id': connectionId,
            'fromUserId': currentUserId,
            'toUserId': targetUserId,
            'fromUserName': currentUserProfile.fullName,
            'toUserName': targetUserProfile.fullName,
            'fromUserImageUrl': currentUserProfile.profilePictureUrl,
            'toUserImageUrl': targetUserProfile.profilePictureUrl,
            'status': ConnectionStatus.accepted.value,
            'createdAt': Timestamp.fromDate(now),
            'updatedAt': Timestamp.fromDate(now),
            'respondedAt': Timestamp.fromDate(now),
          });
          if (kDebugMode) {
            debugPrint(
                '✅ MatchmakingService: Auto-created accepted connection for match');
          }
        } else if (existingConnection.status != ConnectionStatus.accepted) {
          // If connection exists but not accepted, accept it
          await _chatService.respondToConnectionRequest(
            connectionId: connectionId,
            response: ConnectionStatus.accepted,
          );
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint(
              '⚠️ MatchmakingService: Error creating connection for match - $e');
        }
        // Don't fail match creation if connection creation fails
      }

      // Create match
      final matchId = _firestore.collection('temp').doc().id;
      final match = Match(
        id: matchId,
        user1Id: currentUserId,
        user2Id: targetUserId,
        user1Name: currentUserProfile.fullName,
        user2Name: targetUserProfile.fullName,
        user1PhotoUrl: currentUserProfile.profilePictureUrl,
        user2PhotoUrl: targetUserProfile.profilePictureUrl,
        status: MatchStatus.matched,
        createdAt: DateTime.now(),
        expiredAt: DateTime.now()
            .add(const Duration(days: 30)), // Matches expire after 30 days
        commonSports: commonSports,
        compatibilityScore: compatibility,
        chatRoomId: chatRoom?.id, // Link to chat room
        isUser1SuperLike: currentAction == SwipeAction.superLike,
        isUser2SuperLike: targetAction == SwipeAction.superLike,
      );

      // Save match
      await _matchesCollection.doc(matchId).set(match.toFirestore());

      return match;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error checking for match: $e');
      }
      return null;
    }
  }

  /// Create UserProfile from Firestore data
  Future<UserProfile?> _createUserProfileFromData(
      Map<String, dynamic> data) async {
    try {
      final role = UserRole.fromString(data['role'] as String? ?? 'player');

      if (role == UserRole.player) {
        return PlayerProfile(
          uid: data['uid'] as String,
          fullName: data['fullName'] as String,
          gender: Gender.fromString(data['gender'] as String? ?? 'male'),
          age: data['age'] as int,
          location: data['location'] as String,
          latitude: (data['latitude'] as num?)?.toDouble(),
          longitude: (data['longitude'] as num?)?.toDouble(),
          profilePictureUrl: data['profilePictureUrl'] as String?,
          isProfileComplete: data['isProfileComplete'] as bool? ?? false,
          createdAt:
              (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          updatedAt:
              (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          sportsOfInterest: List<String>.from(data['sportsOfInterest'] ?? []),
          skillLevel: SkillLevel.fromString(
              data['skillLevel'] as String? ?? 'beginner'),
          availability: [], // Simplified for matchmaking
          preferredTrainingType: TrainingType.fromString(
              data['preferredTrainingType'] as String? ?? 'in_person'),
        );
      } else if (role == UserRole.coach) {
        return CoachProfile(
          uid: data['uid'] as String,
          fullName: data['fullName'] as String,
          gender: Gender.fromString(data['gender'] as String? ?? 'male'),
          age: data['age'] as int,
          location: data['location'] as String,
          latitude: (data['latitude'] as num?)?.toDouble(),
          longitude: (data['longitude'] as num?)?.toDouble(),
          profilePictureUrl: data['profilePictureUrl'] as String?,
          isProfileComplete: data['isProfileComplete'] as bool? ?? false,
          createdAt:
              (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          updatedAt:
              (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          specializationSports:
              List<String>.from(data['specializationSports'] ?? []),
          experienceYears: data['experienceYears'] as int? ?? 0,
          certifications: data['certifications'] != null
              ? List<String>.from(data['certifications'])
              : null,
          hourlyRate: (data['hourlyRate'] as num?)?.toDouble() ?? 0.0,
          availableTimeSlots: [], // Simplified for matchmaking
          coachingType: TrainingType.fromString(
              data['coachingType'] as String? ?? 'in_person'),
          bio: data['bio'] as String?,
        );
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Calculate compatibility score between two users (0-100)
  int _calculateCompatibility(UserProfile user1, UserProfile user2) {
    int score = 0;

    // Age compatibility (max 20 points)
    final ageDiff = (user1.age - user2.age).abs();
    if (ageDiff <= 2) {
      score += 20;
    } else if (ageDiff <= 5) {
      score += 15;
    } else if (ageDiff <= 10) {
      score += 10;
    } else {
      score += 5;
    }

    // Sports compatibility (max 40 points)
    final commonSports = _getCommonSports(user1, user2);
    score += (commonSports.length * 10).clamp(0, 40);

    // Role compatibility (max 20 points)
    if (user1.role != user2.role) {
      score += 20; // Different roles (player-coach) are good matches
    } else {
      score += 10; // Same roles can still be compatible
    }

    // Location bonus (max 20 points)
    if (user1.location.toLowerCase() == user2.location.toLowerCase()) {
      score += 20;
    } else {
      score += 10; // Different locations but still possible
    }

    return score.clamp(0, 100);
  }

  /// Get common sports between two users
  List<String> _getCommonSports(UserProfile user1, UserProfile user2) {
    List<String> sports1 = [];
    List<String> sports2 = [];

    if (user1 is PlayerProfile) sports1 = user1.sportsOfInterest;
    if (user1 is CoachProfile) sports1 = user1.specializationSports;

    if (user2 is PlayerProfile) sports2 = user2.sportsOfInterest;
    if (user2 is CoachProfile) sports2 = user2.specializationSports;

    return sports1.where((sport) => sports2.contains(sport)).toList();
  }

  /// Calculate distance between two users based on their locations
  double _calculateDistance(UserProfile user1, UserProfile user2) {
    // First priority: Use GPS coordinates if both users have them
    if (user1.latitude != null &&
        user1.longitude != null &&
        user2.latitude != null &&
        user2.longitude != null) {
      final distance = DistanceHelper.calculateDistanceFromCoordinates(
        user1.latitude!,
        user1.longitude!,
        user2.latitude!,
        user2.longitude!,
      );

      if (kDebugMode) {
        debugPrint(
            '📍 GPS Distance: ${user1.fullName} (${user1.latitude}, ${user1.longitude}) ↔ ${user2.fullName} (${user2.latitude}, ${user2.longitude}): ${distance.toStringAsFixed(1)} km');
      }

      return distance;
    }

    // Second priority: Use city name matching
    final distance =
        DistanceHelper.calculateDistance(user1.location, user2.location);

    if (kDebugMode) {
      if (distance != null) {
        debugPrint(
            '📍 City Distance between ${user1.location} and ${user2.location}: ${distance.toStringAsFixed(1)} km');
      } else {
        debugPrint(
            '⚠️ Could not calculate distance between ${user1.location} and ${user2.location}, using fallback');
      }
    }

    // Return calculated distance or fallback to 20 km if null
    return distance ?? 20.0;
  }

  /// Check if a user profile matches the given filters
  bool _matchesFilters(UserProfile userProfile, Map<String, dynamic> data,
      Map<String, dynamic> filters) {
    // Age filter
    final minAge = filters['minAge'] as double? ?? 18.0;
    final maxAge = filters['maxAge'] as double? ?? 65.0;
    if (userProfile.age < minAge || userProfile.age > maxAge) {
      return false;
    }

    // Gender filter
    final allowedGenders =
        filters['genders'] as List<String>? ?? ['Male', 'Female', 'Other'];
    if (!allowedGenders.contains(userProfile.gender.displayName)) {
      return false;
    }

    // Sports filter
    final requiredSports = filters['sports'] as List<String>? ?? [];
    if (requiredSports.isNotEmpty) {
      // Check if user has any of the required sports
      final userSports = <String>[];

      // Get sports from different profile types
      if (data['sportsOfInterest'] != null) {
        userSports.addAll(List<String>.from(data['sportsOfInterest']));
      }
      if (data['specializationSports'] != null) {
        userSports.addAll(List<String>.from(data['specializationSports']));
      }

      // Check if any user sport matches required sports
      final hasMatchingSport = userSports.any((userSport) => requiredSports.any(
          (requiredSport) =>
              userSport.toLowerCase().contains(requiredSport.toLowerCase()) ||
              requiredSport.toLowerCase().contains(userSport.toLowerCase())));

      if (!hasMatchingSport) {
        return false;
      }
    }

    return true;
  }

  /// Get MatchProfile for a specific user by ID (for profile viewing)
  Future<MatchProfile?> getMatchProfileByUserId(String userId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return null;

      // Get the user's profile
      final userDoc = await _usersCollection.doc(userId).get();
      if (!userDoc.exists) return null;

      final data = userDoc.data() as Map<String, dynamic>;
      final userProfile = await _createUserProfileFromData(data);
      if (userProfile == null) return null;

      // Get current user profile for compatibility calculation
      final currentUserProfile =
          await _userRepository.getUserProfile(currentUser.uid);
      if (currentUserProfile == null) return null;

      // Calculate compatibility and distance
      final compatibility =
          _calculateCompatibility(currentUserProfile, userProfile);
      final distance = _calculateDistance(currentUserProfile, userProfile);

      // Check if already matched
      final isMatched = await _isUserMatched(currentUser.uid, userId);

      // Create MatchProfile
      return MatchProfile.fromUserProfile(
        userProfile,
        distanceKm: distance,
        compatibilityScore: compatibility,
        photos: List<String>.from(
            data['additionalPhotos'] ?? data['profilePhotos'] ?? []),
        bio: data['bio'] as String?,
        interests: List<String>.from(data['interests'] ?? []),
        isOnline: data['isOnline'] as bool? ?? false,
        isMatched: isMatched,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            '❌ MatchmakingService: Error getting match profile for user $userId: $e');
      }
      return null;
    }
  }
}

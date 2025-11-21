import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../models/notification_model.dart';
import '../../../modules/chat/models/connection.dart';
import '../../../modules/chat/services/chat_service.dart';
import '../../../modules/community/models/community_post.dart';
import '../../../services/firestore_cache_service.dart';
import '../../../services/notification_service.dart';
import '../models/user_profile_dashboard_models.dart';

/// Service that assembles the public profile experience.
///
/// Phase 1 returns demo data while the Firestore layer is prepared.
class PublicProfileService {
  PublicProfileService({
    FirebaseFirestore? firestore,
    FirestoreCacheService? cacheService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _cacheService = cacheService ?? FirestoreCacheService.instance;

  final FirebaseFirestore _firestore;
  final FirestoreCacheService _cacheService;

  static const Map<String, _SocialLinkMeta> _socialLinkDirectory = {
    'youtube': _SocialLinkMeta('YouTube', Icons.ondemand_video),
    'facebook': _SocialLinkMeta('Facebook', Icons.facebook),
    'instagram': _SocialLinkMeta('Instagram', Icons.camera_alt_outlined),
    'snapchat': _SocialLinkMeta('Snapchat', Icons.snapchat),
  };

  Future<PublicProfileData> fetchProfile(String userId) async {
    Map<String, dynamic>? userData;
    try {
      final userSnapshot =
          await _firestore.collection('users').doc(userId).get();
      userData = userSnapshot.data();
    } catch (error) {
      debugPrint('PublicProfileService: failed to fetch user doc: $error');
    }

    final fallback = _buildEmptyProfile(userId, userData);

    try {
      final profileRef = _firestore.collection('public_profiles').doc(userId);
      final snapshot = await profileRef.get();

      if (!snapshot.exists || snapshot.data() == null) {
        await profileRef.set(
          _serializeProfile(fallback),
          SetOptions(merge: true),
        );
        return fallback;
      }

      final data = snapshot.data()!;
      return await _fromDocument(userId, data, fallback);
    } catch (error, stackTrace) {
      debugPrint(
        'PublicProfileService: failed to load profile for $userId: $error',
      );
      debugPrint('$stackTrace');
      return fallback;
    }
  }

  Future<PublicProfileData> _fromDocument(
    String userId,
    Map<String, dynamic> data,
    PublicProfileData fallback,
  ) async {
    final identity = _parseIdentity(
      data['identity'] as Map<String, dynamic>?,
      fallback.identity,
      userId,
    );

    final about = _parseAbout(
      data['about'] as Map<String, dynamic>?,
      fallback.about,
    );

    final skillSummary = _parseSkillPerformance(
      data['skillPerformance'] as Map<String, dynamic>?,
      fallback.skillPerformance,
    );

    final associationsMap =
        data['associations'] as Map<String, dynamic>? ?? const {};

    final teams =
        _parseAssociationsList(associationsMap['teams']) ?? fallback.teams;
    final tournaments = _parseAssociationsList(
          associationsMap['tournaments'],
        ) ??
        fallback.tournaments;
    final venues =
        _parseAssociationsList(associationsMap['venues']) ?? fallback.venues;
    final coaches =
        _parseAssociationsList(associationsMap['coaches']) ?? fallback.coaches;

    final followersList =
        _parseConnections(data['followers']) ?? fallback.followers;
    final followingList =
        _parseConnections(data['following']) ?? fallback.following;
    final mutualConnections =
        _parseConnections(data['mutualConnections']) ??
            fallback.mutualConnections;

    final statsRaw = data['stats'];

    final postsCount = _intFrom(data['postsCount']) ??
        _extractCountFromStats(statsRaw, const ['posts']) ??
        fallback.postsCount;

    final matchesCount = _intFrom(data['matchesCount']) ??
        _extractCountFromStats(statsRaw, const ['swipe matches', 'matches']) ??
        mutualConnections.length;

    final followersCount = _intFrom(data['followersCount']) ??
        _extractCountFromStats(statsRaw, const ['followers']) ??
        followersList.length;

    final followingCount = _intFrom(data['followingCount']) ??
        _extractCountFromStats(statsRaw, const ['following']) ??
        followingList.length;

    // Check if current viewer is following this user by checking their following list
    final currentViewerId = FirebaseAuth.instance.currentUser?.uid;
    bool isFollowing = false;
    bool isFollowedByViewer = false;
    
    if (currentViewerId != null && currentViewerId != userId) {
      // Check if viewer is following this user (viewer's following list contains this user)
      final viewerFollowingSnapshot = await _firestore
          .collection('public_profiles')
          .doc(currentViewerId)
          .get();
      final viewerFollowingData = viewerFollowingSnapshot.data();
      final viewerFollowing = _extractConnectionList(viewerFollowingData?['following']);
      isFollowing = viewerFollowing.any(
        (entry) => entry['userId']?.toString() == userId,
      );

      // Check if this user is following the viewer (this user's following list contains viewer)
      isFollowedByViewer = followingList.any(
        (conn) => conn.userId == currentViewerId,
      );
    } else {
      // Fallback to stored values if no current user or viewing own profile
      isFollowing = data['isFollowing'] as bool? ?? fallback.isFollowing;
      isFollowedByViewer =
          data['isFollowedByViewer'] as bool? ?? fallback.isFollowedByViewer;
    }

    final matchmaking = _parseMatchmaking(
      data['matchmaking'] as Map<String, dynamic>?,
      fallback.matchmaking,
    );

    final reviews =
        _parseReviews(data['reviews']) ?? fallback.reviews;

    final contactPreferences = _parseContactPreferences(
      data['contact'] as Map<String, dynamic>?,
      fallback.contactPreferences,
    );

    final availableAssociations = _parseAvailableAssociations(
          data['availableAssociations'],
        ) ??
        fallback.availableAssociations;

    final matchmakingLibrary = _parseStringList(data['matchmakingLibrary']) ??
        fallback.matchmakingLibrary;

    final featuredPostIds =
        _parseStringList(data['featuredPostIds']) ?? fallback.featuredPostIds;

    final stats = _buildStatsFromCounts(
      postsCount,
      matchesCount,
      followingCount,
      followersCount,
    );

    return PublicProfileData(
      identity: identity,
      stats: stats,
      about: about,
      skillPerformance: skillSummary,
      teams: teams,
      tournaments: tournaments,
      coaches: coaches,
      venues: venues,
      communityPosts: const [],
      matchmaking: matchmaking,
      reviews: reviews,
      contactPreferences: contactPreferences,
      postsCount: postsCount,
      matchesCount: matchesCount,
      followersCount: followersCount,
      followingCount: followingCount,
      isFollowing: isFollowing,
      isFollowedByViewer: isFollowedByViewer,
      followers: followersList,
      following: followingList,
      mutualConnections: mutualConnections,
      availablePosts: const [],
      availableAssociations: availableAssociations,
      matchmakingLibrary: matchmakingLibrary,
      featuredPostIds: featuredPostIds,
    );
  }

  PublicProfileData _buildEmptyProfile(
    String userId,
    Map<String, dynamic>? userData,
  ) {
    final fullName =
        (userData?['fullName'] as String?)?.trim().maybeIfNotEmpty() ??
            'New Player';
    final role = (userData?['role'] as String?) ?? '';
    final headline = (userData?['headline'] as String?) ?? '';
    final city = (userData?['location'] as String?) ?? '';
    final age = _intFrom(userData?['age']) ?? 0;
    final profilePictureUrl =
        (userData?['profilePictureUrl'] as String?) ?? '';
    final coverMediaUrl = userData?['coverMediaUrl'] as String?;

    final sports =
        _parseStringList(userData?['sportsOfInterest']) ?? const <String>[];

    final identity = ProfileIdentity(
      userId: userId,
      fullName: fullName,
      role: role,
      tagline: headline,
      city: city,
      age: age,
      profilePictureUrl: profilePictureUrl,
      coverMediaUrl: coverMediaUrl,
      badges: const [],
      isVerified: userData?['isVerified'] as bool? ?? false,
    );

    final about = ProfileAboutData(
      bio: '',
      sports: sports,
      position: userData?['position']?.toString() ?? '',
      availability: userData?['availability']?.toString() ?? '',
      highlights: const <String>[],
      attributes: const <String, String>{},
      statusMessage: '',
    );

    const skillSummary = SkillPerformanceSummary(
      overallRating: 0,
      skillMetrics: <SkillMetric>[],
      recentTrends: <PerformanceTrendPoint>[],
      achievements: <AchievementHighlight>[],
    );

    final matchmaking = MatchmakingShowcase(
      tagline: '',
      about: '',
      images: const <String>[],
      age: age,
      city: city,
      sports: sports,
      seeking: const <String>[],
      distanceKm: null,
      distanceLink: null,
      featuredTeam: null,
      featuredVenue: null,
      featuredCoach: null,
      featuredTournament: null,
      allowMessagesFromFriendsOnly: false,
    );

    const contactPreferences = ContactPreferences(
      primaryActionLabel: 'Start chat',
      links: <ContactLink>[],
      allowMessagesFromFriendsOnly: false,
    );

    return PublicProfileData(
      identity: identity,
      stats: _buildStatsFromCounts(0, 0, 0, 0),
      about: about,
      skillPerformance: skillSummary,
      teams: const <AssociationCardData>[],
      tournaments: const <AssociationCardData>[],
      coaches: const <AssociationCardData>[],
      venues: const <AssociationCardData>[],
      communityPosts: const <CommunityPost>[],
      matchmaking: matchmaking,
      reviews: const <ReviewEntry>[],
      contactPreferences: contactPreferences,
      postsCount: 0,
      matchesCount: 0,
      followersCount: 0,
      followingCount: 0,
      isFollowing: false,
      isFollowedByViewer: false,
      followers: const <ProfileConnection>[],
      following: const <ProfileConnection>[],
      mutualConnections: const <ProfileConnection>[],
      availablePosts: const <CommunityPost>[],
      availableAssociations:
          const <String, List<AssociationCardData>>{},
      matchmakingLibrary: const <String>[],
      featuredPostIds: const <String>[],
    );
  }

  Map<String, dynamic> _serializeProfile(PublicProfileData data) {
    return {
      'identity': {
        'fullName': data.identity.fullName,
        'role': data.identity.role,
        'tagline': data.identity.tagline,
        'city': data.identity.city,
        'age': data.identity.age,
        'profilePictureUrl': data.identity.profilePictureUrl,
        'coverMediaUrl': data.identity.coverMediaUrl,
        'badges': data.identity.badges,
        'isVerified': data.identity.isVerified,
      },
      'about': {
        'bio': data.about.bio,
        'sports': data.about.sports,
        'position': data.about.position,
        'availability': data.about.availability,
        'highlights': data.about.highlights,
        'attributes': data.about.attributes,
        'statusMessage': data.about.statusMessage,
      },
      'skillPerformance': {
        'overallRating': data.skillPerformance.overallRating,
        'metrics': data.skillPerformance.skillMetrics
            .map(
              (metric) => {
                'name': metric.name,
                'score': metric.score,
                'maxScore': metric.maxScore,
                'description': metric.description,
              },
            )
            .toList(),
        'trends': data.skillPerformance.recentTrends
            .map(
              (trend) => {
                'label': trend.label,
                'value': trend.value,
              },
            )
            .toList(),
        'achievements': data.skillPerformance.achievements
            .map(
              (achievement) => {
                'title': achievement.title,
                'subtitle': achievement.subtitle,
                'date': Timestamp.fromDate(achievement.date),
              },
            )
            .toList(),
      },
      'associations': {
        'teams': data.teams.map(_associationToMap).toList(),
        'tournaments': data.tournaments.map(_associationToMap).toList(),
        'venues': data.venues.map(_associationToMap).toList(),
        'coaches': data.coaches.map(_associationToMap).toList(),
      },
      'followers': data.followers.map(_connectionToMap).toList(),
      'following': data.following.map(_connectionToMap).toList(),
      'mutualConnections':
          data.mutualConnections.map(_connectionToMap).toList(),
      'postsCount': data.postsCount,
      'matchesCount': data.matchesCount,
      'followersCount': data.followersCount,
      'followingCount': data.followingCount,
      'matchmaking': _serializeMatchmaking(data.matchmaking),
      'contact': {
        'primaryActionLabel': data.contactPreferences.primaryActionLabel,
        'allowMessagesFromFriendsOnly':
            data.contactPreferences.allowMessagesFromFriendsOnly,
        'links': _contactLinksToMap(data.contactPreferences.links),
      },
      'availableAssociations': data.availableAssociations.map(
        (key, value) => MapEntry(
          key,
          value.map(_associationToMap).toList(),
        ),
      ),
      'matchmakingLibrary': data.matchmakingLibrary,
      'featuredPostIds': data.featuredPostIds,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Future<void> updateProfileFields(
    String userId,
    Map<String, dynamic> data,
  ) async {
    final payload = {
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    await _firestore
        .collection('public_profiles')
        .doc(userId)
        .set(payload, SetOptions(merge: true));
  }

  Future<void> updateProfileMedia({
    required String userId,
    String? profilePictureUrl,
    String? coverMediaUrl,
  }) async {
    final updates = <String, dynamic>{};
    final userUpdates = <String, dynamic>{};
    final cacheUserUpdates = <String, dynamic>{};

    if (profilePictureUrl != null && profilePictureUrl.isNotEmpty) {
      updates['identity.profilePictureUrl'] = profilePictureUrl;
      userUpdates['profilePictureUrl'] = profilePictureUrl;
      cacheUserUpdates['profilePictureUrl'] = profilePictureUrl;
    }
    if (coverMediaUrl != null && coverMediaUrl.isNotEmpty) {
      updates['identity.coverMediaUrl'] = coverMediaUrl;
      userUpdates['coverMediaUrl'] = coverMediaUrl;
    }

    if (updates.isEmpty && userUpdates.isEmpty) return;

    final batch = _firestore.batch();
    final profileRef = _firestore.collection('public_profiles').doc(userId);
    final userRef = _firestore.collection('users').doc(userId);

    if (updates.isNotEmpty) {
      updates['updatedAt'] = FieldValue.serverTimestamp();
      batch.set(profileRef, updates, SetOptions(merge: true));
    }

    if (userUpdates.isNotEmpty) {
      final timestamp = Timestamp.now();
      userUpdates['updatedAt'] = FieldValue.serverTimestamp();
      cacheUserUpdates['updatedAt'] = timestamp;
      batch.set(userRef, userUpdates, SetOptions(merge: true));
    }

    await batch.commit();

    if (cacheUserUpdates.isNotEmpty) {
      await _cacheService.mergeDocument(
        collection: FirestoreCacheCollection.users,
        docId: userId,
        updates: cacheUserUpdates,
      );
    }
  }

  Future<void> createAssociationRequest({
    required String requesterId,
    required String requesterName,
    required AssociationCardData association,
    required String type,
  }) async {
    if (association.ownerId == null || association.ownerId!.isEmpty) {
      return;
    }
    await _firestore.collection('profile_association_requests').add({
      'requesterId': requesterId,
      'requesterName': requesterName,
      'associationId': association.id,
      'associationTitle': association.title,
      'associationOwnerId': association.ownerId,
      'associationOwnerName': association.ownerName,
      'type': type,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Save pending association to public_profiles document
  Future<void> savePendingAssociation({
    required String userId,
    required AssociationCardData association,
    required String type,
  }) async {
    try {
      final profileRef = _firestore.collection('public_profiles').doc(userId);
      final associationMap = _associationToMap(association);
      
      // Get current associations
      final snapshot = await profileRef.get();
      final data = snapshot.data() ?? {};
      final associations = data['associations'] as Map<String, dynamic>? ?? {};
      final typeAssociations = (associations[type] as List<dynamic>?) ?? [];
      
      // Check if association already exists
      final exists = typeAssociations.any(
        (item) => item is Map && item['id'] == association.id,
      );
      
      if (!exists) {
        // Add the pending association
        typeAssociations.add(associationMap);
        associations[type] = typeAssociations;
        
        // Update the document
        await profileRef.set(
          {
            'associations': associations,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }
    } catch (e) {
      debugPrint('PublicProfileService: failed to save pending association: $e');
      rethrow;
    }
  }

  Future<void> updateFollowStatus({
    required String targetUserId,
    required String targetUserName,
    String? targetAvatarUrl,
    required String viewerId,
    required String viewerName,
    String? viewerAvatarUrl,
    required bool follow,
  }) async {
    final targetRef = _firestore.collection('public_profiles').doc(targetUserId);
    final viewerRef = _firestore.collection('public_profiles').doc(viewerId);

    Map<String, dynamic> connectionEntry(
      String userId,
      String name,
      String? avatarUrl,
    ) {
      // Ensure name is not empty
      final safeName = name.trim();
      if (safeName.isEmpty) {
        debugPrint('⚠️ Warning: Empty name provided for connection entry');
      }
      return {
        'userId': userId,
        'name': safeName.isNotEmpty ? safeName : 'User',
        'avatarUrl': avatarUrl?.trim() ?? '',
        'isFollowing': true,
      };
    }

    await _firestore.runTransaction((txn) async {
      Map<String, dynamic> targetData = {};
      Map<String, dynamic> viewerData = {};

      // ALL READS MUST BE DONE FIRST
      final targetSnap = await txn.get(targetRef);
      if (targetSnap.exists) {
        targetData =
            Map<String, dynamic>.from(targetSnap.data() as Map<String, dynamic>);
      }

      final viewerSnap = await txn.get(viewerRef);
      if (viewerSnap.exists) {
        viewerData =
            Map<String, dynamic>.from(viewerSnap.data() as Map<String, dynamic>);
      }

      // Check for mutual follow and read connection if needed (BEFORE WRITES)
      DocumentSnapshot? existingConnection;
      bool isMutualFollow = false;
      String? connectionId;
      String? safeViewerName;
      String? safeTargetName;
      
      if (follow) {
        final targetFollowing = _extractConnectionList(targetData['following']);
        isMutualFollow = targetFollowing
            .any((entry) => entry['userId']?.toString() == viewerId);

        if (isMutualFollow) {
          // Validate required fields before creating connection
          safeViewerName = viewerName.trim();
          safeTargetName = targetUserName.trim();
          
          if (viewerId.isNotEmpty &&
              targetUserId.isNotEmpty &&
              safeViewerName.isNotEmpty &&
              safeTargetName.isNotEmpty) {
            // Read connection document BEFORE any writes
            connectionId = ConnectionHelper.generateConnectionId(
              viewerId,
              targetUserId,
            );
            final connectionsRef =
                _firestore.collection('connections').doc(connectionId!);
            existingConnection = await txn.get(connectionsRef);
          }
        }
      }

      // NOW DO ALL WRITES
      final targetFollowers = _extractConnectionList(targetData['followers']);
      final viewerFollowing = _extractConnectionList(viewerData['following']);

      final followerEntry =
          connectionEntry(viewerId, viewerName, viewerAvatarUrl);
      final followingEntry =
          connectionEntry(targetUserId, targetUserName, targetAvatarUrl);

      if (follow) {
        if (!targetFollowers
            .any((entry) => entry['userId'] == followerEntry['userId'])) {
          targetFollowers.add(followerEntry);
        }
        if (!viewerFollowing
            .any((entry) => entry['userId'] == followingEntry['userId'])) {
          viewerFollowing.add(followingEntry);
        }
      } else {
        targetFollowers.removeWhere(
            (entry) => entry['userId']?.toString() == viewerId);
        viewerFollowing.removeWhere(
            (entry) => entry['userId']?.toString() == targetUserId);
      }

      txn.set(
        targetRef,
        {
          'followers': targetFollowers,
          'followersCount': targetFollowers.length,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      txn.set(
        viewerRef,
        {
          'following': viewerFollowing,
          'followingCount': viewerFollowing.length,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      // Create or update connection if mutual follow (AFTER all reads are done)
      if (follow && isMutualFollow && connectionId != null && 
          safeViewerName != null && safeTargetName != null) {
        final connectionsRef =
            _firestore.collection('connections').doc(connectionId!);

        if (existingConnection == null || !existingConnection!.exists) {
          final now = DateTime.now();
          txn.set(connectionsRef, {
            'id': connectionId!,
            'fromUserId': viewerId,
            'toUserId': targetUserId,
            'fromUserName': safeViewerName!,
            'toUserName': safeTargetName!,
            'fromUserImageUrl': (viewerAvatarUrl?.trim() ?? ''),
            'toUserImageUrl': (targetAvatarUrl?.trim() ?? ''),
            'status': ConnectionStatus.accepted.value,
            'createdAt': Timestamp.fromDate(now),
            'updatedAt': Timestamp.fromDate(now),
            'respondedAt': Timestamp.fromDate(now),
          });
          debugPrint(
              '✅ Created accepted connection for mutual follow: $connectionId');
        } else if (existingConnection!.exists) {
          // Update existing connection to accepted if not already
          final existingData =
              existingConnection!.data() as Map<String, dynamic>?;
          if (existingData?['status'] != ConnectionStatus.accepted.value) {
            txn.update(connectionsRef, {
              'status': ConnectionStatus.accepted.value,
              'updatedAt': FieldValue.serverTimestamp(),
              'respondedAt': FieldValue.serverTimestamp(),
            });
          }
        }
      }
    });

    if (follow) {
      try {
        await NotificationService().createNotification(
          userId: targetUserId,
          type: NotificationType.profileFollow,
          title: 'New follower',
          message: '$viewerName started following you.',
          data: {
            'followerId': viewerId,
            'followerName': viewerName,
          },
        );
      } catch (e) {
        debugPrint(
            'PublicProfileService: failed to send follow notification: $e');
      }
    }
  }

  Future<void> notifyFollowersOfUpdate({
    required String profileUserId,
    required String title,
    required String message,
    Map<String, dynamic>? data,
  }) async {
    try {
      final snapshot =
          await _firestore.collection('public_profiles').doc(profileUserId).get();
      final followers =
          _extractConnectionList(snapshot.data()?['followers']).toList();
      if (followers.isEmpty) return;

      final notificationService = NotificationService();
      for (final follower in followers) {
        final followerId = follower['userId']?.toString();
        if (followerId == null || followerId.isEmpty) continue;
        await notificationService.createNotification(
          userId: followerId,
          type: NotificationType.profileUpdate,
          title: title,
          message: message,
          data: {
            'profileUserId': profileUserId,
            ...?data,
          },
        );
      }
    } catch (e) {
      debugPrint(
          'PublicProfileService: failed to notify followers about update: $e');
    }
  }

  Future<Set<String>> getFollowingUserIds(String userId) async {
    try {
      final snap =
          await _firestore.collection('public_profiles').doc(userId).get();
      final following =
          _extractConnectionList(snap.data()?['following']).toList();
      final ids = <String>{};
      for (final entry in following) {
        final id = entry['userId']?.toString();
        if (id != null && id.isNotEmpty) {
          ids.add(id);
        }
      }
      return ids;
    } catch (e) {
      debugPrint('PublicProfileService: failed to load following for $userId: $e');
      return <String>{};
    }
  }

  Future<void> addProfileReview({
    required String profileUserId,
    required String reviewerId,
    required ReviewEntry review,
  }) async {
    final reviewData = {
      'id': review.id,
      'authorId': reviewerId,
      'authorName': review.authorName,
      'authorAvatarUrl': review.authorAvatarUrl,
      'rating': review.rating,
      'comment': review.comment,
      'relationship': review.relationship,
      'createdAt': Timestamp.fromDate(review.createdAt),
    };

    await _firestore.collection('public_profiles').doc(profileUserId).set(
      {
        'reviews': FieldValue.arrayUnion([reviewData]),
        'reviewsCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Map<String, dynamic> _associationToMap(AssociationCardData association) {
    return {
      'id': association.id,
      'title': association.title,
      'subtitle': association.subtitle,
      'role': association.role,
      'imageUrl': association.imageUrl,
      'tags': association.tags,
      'location': association.location,
      'status': association.status,
      'description': association.description,
      'since': association.since != null
          ? Timestamp.fromDate(association.since!)
          : null,
      'ownerName': association.ownerName,
      'ownerId': association.ownerId,
    }..removeWhere((_, value) => value == null);
  }

  Map<String, dynamic> _connectionToMap(ProfileConnection connection) {
    return {
      'userId': connection.userId,
      'name': connection.name,
      'avatarUrl': connection.avatarUrl,
      'isFollowing': connection.isFollowing,
    };
  }

  Map<String, dynamic> _serializeMatchmaking(MatchmakingShowcase data) {
    return {
      'tagline': data.tagline,
      'about': data.about,
      'images': data.images,
      'age': data.age,
      'city': data.city,
      'sports': data.sports,
      'seeking': data.seeking,
      'distanceKm': data.distanceKm,
      'distanceLink': data.distanceLink,
      'featuredTeam':
          data.featuredTeam != null ? _associationToMap(data.featuredTeam!) : null,
      'featuredVenue': data.featuredVenue != null
          ? _associationToMap(data.featuredVenue!)
          : null,
      'featuredCoach': data.featuredCoach != null
          ? _associationToMap(data.featuredCoach!)
          : null,
      'featuredTournament': data.featuredTournament != null
          ? _associationToMap(data.featuredTournament!)
          : null,
      'allowMessagesFromFriendsOnly': data.allowMessagesFromFriendsOnly,
    }..removeWhere((_, value) => value == null);
  }

  Map<String, dynamic> _contactLinksToMap(List<ContactLink> links) {
    final map = <String, dynamic>{};
    for (final link in links) {
      final key = (link.key ?? link.label).toLowerCase().replaceAll(' ', '');
      final url = link.url.trim();
      if (url.isEmpty) continue;
      map[key] = url;
    }
    return map;
  }

  ProfileIdentity _parseIdentity(
    Map<String, dynamic>? map,
    ProfileIdentity fallback,
    String userId,
  ) {
    if (map == null) return fallback;
    return ProfileIdentity(
      userId: userId,
      fullName: map['fullName'] as String? ?? fallback.fullName,
      role: map['role'] as String? ?? fallback.role,
      tagline: map['tagline'] as String? ?? fallback.tagline,
      city: map['city'] as String? ?? fallback.city,
      age: _intFrom(map['age']) ?? fallback.age,
      profilePictureUrl:
          map['profilePictureUrl'] as String? ?? fallback.profilePictureUrl,
      badges: _parseStringList(map['badges']) ?? fallback.badges,
      coverMediaUrl: map['coverMediaUrl'] as String? ?? fallback.coverMediaUrl,
      isVerified: map['isVerified'] as bool? ?? fallback.isVerified,
    );
  }

  ProfileAboutData _parseAbout(
    Map<String, dynamic>? map,
    ProfileAboutData fallback,
  ) {
    if (map == null) return fallback;
    return ProfileAboutData(
      bio: map['bio'] as String? ?? fallback.bio,
      sports: _parseStringList(map['sports']) ?? fallback.sports,
      position: map['position'] as String? ?? fallback.position,
      availability: map['availability'] as String? ?? fallback.availability,
      highlights: _parseStringList(map['highlights']) ?? fallback.highlights,
      attributes: _parseStringMap(map['attributes']) ?? fallback.attributes,
      statusMessage: map['statusMessage'] as String? ?? fallback.statusMessage,
    );
  }

  SkillPerformanceSummary _parseSkillPerformance(
    Map<String, dynamic>? map,
    SkillPerformanceSummary fallback,
  ) {
    if (map == null) return fallback;
    return SkillPerformanceSummary(
      overallRating:
          _doubleFrom(map['overallRating']) ?? fallback.overallRating,
      skillMetrics:
          _parseSkillMetrics(map['metrics']) ?? fallback.skillMetrics,
      recentTrends:
          _parseTrendPoints(map['trends']) ?? fallback.recentTrends,
      achievements:
          _parseAchievementHighlights(map['achievements']) ??
              fallback.achievements,
    );
  }

  List<SkillMetric>? _parseSkillMetrics(dynamic value) {
    if (value is! List) return null;
    final metrics = <SkillMetric>[];
    for (final item in value) {
      if (item is! Map) continue;
      final map = Map<String, dynamic>.from(item);
      final name = map['name']?.toString() ?? '';
      if (name.isEmpty) continue;
      final score = _doubleFrom(map['score']) ?? 0;
      final maxScore = _doubleFrom(map['maxScore']) ?? 100;
      final description = map['description']?.toString() ?? '';
      final icon = _iconFromString(map['icon']?.toString());
      metrics.add(
        SkillMetric(
          name: name,
          score: score,
          maxScore: maxScore,
          description: description,
          icon: icon,
        ),
      );
    }
    return metrics.isEmpty ? null : metrics;
  }

  List<PerformanceTrendPoint>? _parseTrendPoints(dynamic value) {
    if (value is! List) return null;
    final trends = <PerformanceTrendPoint>[];
    for (final item in value) {
      if (item is! Map) continue;
      final map = Map<String, dynamic>.from(item);
      final label = map['label']?.toString() ?? '';
      final numericValue = _doubleFrom(map['value']);
      if (label.isEmpty || numericValue == null) continue;
      trends.add(
        PerformanceTrendPoint(
          label: label,
          value: numericValue,
        ),
      );
    }
    return trends.isEmpty ? null : trends;
  }

  List<AchievementHighlight>? _parseAchievementHighlights(dynamic value) {
    if (value is! List) return null;
    final achievements = <AchievementHighlight>[];
    for (final item in value) {
      if (item is! Map) continue;
      final map = Map<String, dynamic>.from(item);
      final title = map['title']?.toString() ?? '';
      if (title.isEmpty) continue;
      final subtitle = map['subtitle']?.toString() ?? '';
      final icon = _iconFromString(map['icon']?.toString());
      final date = _parseDate(map['date']) ?? DateTime.now();
      achievements.add(
        AchievementHighlight(
          title: title,
          subtitle: subtitle,
          icon: icon,
          date: date,
        ),
      );
    }
    return achievements.isEmpty ? null : achievements;
  }

  List<AssociationCardData>? _parseAssociationsList(dynamic value) {
    if (value is! List) return null;
    final associations = <AssociationCardData>[];
    for (final item in value) {
      final association = _parseAssociation(item);
      if (association != null) {
        associations.add(association);
      }
    }
    return associations.isEmpty ? null : associations;
  }

  List<Map<String, dynamic>> _extractConnectionList(dynamic value) {
    if (value is List) {
      return value
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }
    return <Map<String, dynamic>>[];
  }

  AssociationCardData? _parseAssociation(dynamic value) {
    if (value is! Map) return null;
    final map = Map<String, dynamic>.from(value);
    final id = map['id']?.toString();
    final title = map['title']?.toString();
    if (id == null || id.isEmpty || title == null || title.isEmpty) {
      return null;
    }
    final tags = _parseStringList(map['tags']) ?? const <String>[];
    return AssociationCardData(
      id: id,
      title: title,
      subtitle: map['subtitle']?.toString() ?? '',
      role: map['role']?.toString() ?? '',
      imageUrl: map['imageUrl']?.toString() ?? '',
      tags: tags,
      location: map['location']?.toString(),
      status: map['status']?.toString(),
      description: map['description']?.toString(),
      since: _parseDate(map['since']),
      ownerName: map['ownerName']?.toString(),
      ownerId: map['ownerId']?.toString(),
    );
  }

  List<ProfileConnection>? _parseConnections(dynamic value) {
    if (value is! List) return null;
    final connections = <ProfileConnection>[];
    for (final item in value) {
      if (item is! Map) continue;
      final map = Map<String, dynamic>.from(item);
      final userId =
          map['userId']?.toString() ?? map['uid']?.toString();
      final name =
          map['name']?.toString() ?? map['fullName']?.toString();
      if (userId == null || userId.isEmpty || name == null || name.isEmpty) {
        continue;
      }
      connections.add(
        ProfileConnection(
          userId: userId,
          name: name,
          avatarUrl: map['avatarUrl']?.toString() ??
              map['profilePictureUrl']?.toString() ??
              '',
          isFollowing: map['isFollowing'] as bool? ?? false,
        ),
      );
    }
    return connections.isEmpty ? null : connections;
  }

  List<ReviewEntry>? _parseReviews(dynamic value) {
    if (value is! List) return null;
    final reviews = <ReviewEntry>[];
    for (final item in value) {
      if (item is! Map) continue;
      final map = Map<String, dynamic>.from(item);
      final authorName = map['authorName']?.toString() ?? '';
      if (authorName.isEmpty) continue;
      reviews.add(
        ReviewEntry(
          id: map['id']?.toString() ??
              '${authorName}_${map['createdAt'] ?? DateTime.now().millisecondsSinceEpoch}',
          authorName: authorName,
          authorAvatarUrl:
              map['authorAvatarUrl']?.toString() ?? '',
          rating: _doubleFrom(map['rating']) ?? 0,
          comment: map['comment']?.toString() ?? '',
          relationship: map['relationship']?.toString() ?? '',
          createdAt: _parseDate(map['createdAt']) ?? DateTime.now(),
        ),
      );
    }
    return reviews.isEmpty ? null : reviews;
  }

  ContactPreferences _parseContactPreferences(
    Map<String, dynamic>? map,
    ContactPreferences fallback,
  ) {
    if (map == null) return fallback;
    return ContactPreferences(
      primaryActionLabel:
          map['primaryActionLabel'] as String? ?? fallback.primaryActionLabel,
      links: _parseContactLinks(map['links']) ?? fallback.links,
      allowMessagesFromFriendsOnly:
          map['allowMessagesFromFriendsOnly'] as bool? ??
              fallback.allowMessagesFromFriendsOnly,
    );
  }

  List<ContactLink>? _parseContactLinks(dynamic value) {
    if (value == null) return null;

    Iterable<ContactLink> mapEntries(Map valueMap) sync* {
      for (final entry in valueMap.entries) {
        final key = entry.key.toString().toLowerCase();
        final url = entry.value?.toString().trim();
        if (url == null || url.isEmpty) continue;
        final meta = _socialLinkDirectory[key];
        yield ContactLink(
          key: key,
          label: meta?.label ?? entry.key.toString(),
          icon: meta?.icon ?? _contactIconFromString(key),
          url: url,
        );
      }
    }

    final links = <ContactLink>[];
    if (value is Map) {
      links.addAll(mapEntries(value));
    } else if (value is List) {
      for (final item in value) {
        if (item is! Map) continue;
        final map = Map<String, dynamic>.from(item);
        final rawUrl = map['url']?.toString();
        if (rawUrl == null || rawUrl.trim().isEmpty) continue;
        final key = map['key']?.toString().toLowerCase();
        final iconKey =
            map['icon']?.toString().toLowerCase() ?? key ?? map['label']?.toString().toLowerCase();
        final meta = iconKey != null ? _socialLinkDirectory[iconKey] : null;
        final label = (map['label']?.toString().maybeIfNotEmpty() ??
                meta?.label ??
                key ??
                iconKey ??
                'Link')
            .toString();
        links.add(
          ContactLink(
            key: key ?? iconKey,
            label: label,
            icon: meta?.icon ?? _contactIconFromString(iconKey),
            url: rawUrl.trim(),
          ),
        );
      }
    } else {
      return null;
    }

    return links.isEmpty ? null : links;
  }

  Map<String, List<AssociationCardData>>? _parseAvailableAssociations(
      dynamic value) {
    if (value is! Map) return null;
    final result = <String, List<AssociationCardData>>{};
    value.forEach((key, entries) {
      final parsed = _parseAssociationsList(entries);
      if (parsed != null && parsed.isNotEmpty) {
        result[key.toString()] = parsed;
      }
    });
    return result.isEmpty ? null : result;
  }

  MatchmakingShowcase _parseMatchmaking(
    Map<String, dynamic>? map,
    MatchmakingShowcase fallback,
  ) {
    if (map == null) return fallback;
    return MatchmakingShowcase(
      tagline: map['tagline']?.toString() ?? fallback.tagline,
      about: map['about']?.toString() ?? fallback.about,
      images:
          _parseStringList(map['images']) ?? List<String>.from(fallback.images),
      age: _intFrom(map['age']) ?? fallback.age,
      city: map['city']?.toString() ?? fallback.city,
      sports:
          _parseStringList(map['sports']) ?? List<String>.from(fallback.sports),
      seeking: _parseStringList(map['seeking']) ??
          List<String>.from(fallback.seeking),
      distanceKm: _doubleFrom(map['distanceKm']) ?? fallback.distanceKm,
      distanceLink: map['distanceLink']?.toString() ?? fallback.distanceLink,
      featuredTeam:
          _parseAssociation(map['featuredTeam']) ?? fallback.featuredTeam,
      featuredVenue:
          _parseAssociation(map['featuredVenue']) ?? fallback.featuredVenue,
      featuredCoach:
          _parseAssociation(map['featuredCoach']) ?? fallback.featuredCoach,
      featuredTournament: _parseAssociation(map['featuredTournament']) ??
          fallback.featuredTournament,
      allowMessagesFromFriendsOnly:
          map['allowMessagesFromFriendsOnly'] as bool? ??
              fallback.allowMessagesFromFriendsOnly,
    );
  }

  List<String>? _parseStringList(dynamic value) {
    if (value == null) return null;
    if (value is List) {
      final list = value
          .whereType<dynamic>()
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList();
      return list.isEmpty ? null : list;
    }
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) return null;
      return [trimmed];
    }
    return null;
  }

  Map<String, String>? _parseStringMap(dynamic value) {
    if (value is! Map) return null;
    final map = <String, String>{};
    value.forEach((key, raw) {
      final k = key?.toString();
      final v = raw?.toString();
      if (k == null || k.isEmpty || v == null) return;
      map[k] = v;
    });
    return map.isEmpty ? null : map;
  }

  double? _doubleFrom(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    if (value is String) {
      final cleaned = value.replaceAll(',', '');
      return double.tryParse(cleaned);
    }
    return null;
  }

  int? _intFrom(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is num) return value.toInt();
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized.endsWith('k')) {
        final base =
            double.tryParse(normalized.substring(0, normalized.length - 1));
        if (base != null) return (base * 1000).round();
      }
      if (normalized.endsWith('m')) {
        final base =
            double.tryParse(normalized.substring(0, normalized.length - 1));
        if (base != null) return (base * 1000000).round();
      }
      final digitsOnly = normalized.replaceAll(RegExp(r'[^0-9]'), '');
      if (digitsOnly.isEmpty) return null;
      return int.tryParse(digitsOnly);
    }
    return null;
  }

  int? _extractCountFromStats(dynamic stats, List<String> labels) {
    if (stats is! List) return null;
    for (final item in stats) {
      if (item is! Map) continue;
      final map = Map<String, dynamic>.from(item);
      final label = map['label']?.toString().toLowerCase();
      if (label == null) continue;
      if (labels.any((candidate) => candidate.toLowerCase() == label)) {
        final count = _intFrom(map['value']);
        if (count != null) return count;
      }
    }
    return null;
  }

  IconData _iconFromString(String? iconName) {
    switch (iconName?.toLowerCase()) {
      case 'article':
      case 'article_outlined':
      case 'posts':
        return Icons.article_outlined;
      case 'link':
      case 'link_rounded':
        return Icons.link_rounded;
      case 'favorite':
      case 'favorite_outline':
        return Icons.favorite_outline;
      case 'groups':
      case 'groups_3_outlined':
      case 'people_alt':
        return Icons.groups_3_outlined;
      case 'flash_on':
        return Icons.flash_on;
      case 'remove_red_eye':
      case 'vision':
        return Icons.remove_red_eye;
      case 'sports_handball':
        return Icons.sports_handball;
      case 'speed':
        return Icons.speed;
      case 'emoji_events':
        return Icons.emoji_events;
      case 'shield_moon':
        return Icons.shield_moon;
      default:
        return Icons.circle;
    }
  }

  IconData _contactIconFromString(String? iconName) {
    if (iconName == null) return Icons.link;
    final key = iconName.toLowerCase();
    final predefined = _socialLinkDirectory[key];
    if (predefined != null) {
      return predefined.icon;
    }
    switch (key) {
      case 'camera':
      case 'camera_alt_outlined':
        return Icons.camera_alt_outlined;
      case 'youtube':
      case 'play':
        return Icons.play_circle_outline;
      case 'website':
      case 'public':
        return Icons.public;
      case 'facebook':
        return Icons.facebook;
      case 'twitter':
        return Icons.alternate_email;
      case 'linkedin':
        return Icons.work_outline;
      case 'telegram':
        return Icons.send;
      case 'whatsapp':
        return Icons.chat_bubble_outline;
      case 'email':
        return Icons.email_outlined;
      case 'phone':
        return Icons.phone;
      default:
        return Icons.link;
    }
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  List<ProfileStat> _buildStatsFromCounts(
    int posts,
    int matches,
    int following,
    int followers,
  ) {
    return [
      ProfileStat(
        label: 'Posts',
        value: posts.toString(),
        icon: Icons.article_outlined,
      ),
      ProfileStat(
        label: 'Swipe matches',
        value: matches.toString(),
        icon: Icons.link_rounded,
      ),
      ProfileStat(
        label: 'Following',
        value: following.toString(),
        icon: Icons.favorite_outline,
      ),
      ProfileStat(
        label: 'Followers',
        value: followers.toString(),
        icon: Icons.groups_3_outlined,
      ),
    ];
  }
}

class _SocialLinkMeta {
  const _SocialLinkMeta(this.label, this.icon);

  final String label;
  final IconData icon;
}

extension _NullableStringUtils on String? {
  String? maybeIfNotEmpty() {
    if (this == null) return null;
    final trimmed = this!.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}


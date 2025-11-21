import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../models/models.dart';
import 'community_notification_service.dart';
import '../../../core/utils/stream_debounce.dart';

class CommunityPostPage {
  final List<CommunityPost> posts;
  final DocumentSnapshot<Map<String, dynamic>>? lastDocument;
  final bool hasMore;

  const CommunityPostPage({
    required this.posts,
    required this.lastDocument,
    required this.hasMore,
  });
}

/// Service for managing community posts, comments, and interactions
class CommunityService {
  static FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection references
  static const String _postsCollection = 'community_posts';
  static const String _commentsCollection = 'comments';
  static const String _likesCollection = 'likes';
  static const String _notificationsCollection = 'notifications';
  static const String _usersCollection = 'users';

  /// Get current user ID
  static String? get _currentUserId => _auth.currentUser?.uid;

  @visibleForTesting
  static void overrideFirebase({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) {
    if (firestore != null) _firestore = firestore;
    if (auth != null) _auth = auth;
  }

  @visibleForTesting
  static void reset() {
    if (Firebase.apps.isEmpty) {
      return;
    }

    _firestore = FirebaseFirestore.instance;
    _auth = FirebaseAuth.instance;
  }

  // ==================== POST OPERATIONS ====================

  /// Create a new community post
  static Future<String> createPost({
    required String content,
    List<String> images = const [],
    List<String> tags = const [],
    required String authorNickname,
    String? authorProfilePicture,
    String? postId,
  }) async {
    try {
      final userId = _currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      final userDoc =
          await _firestore.collection(_usersCollection).doc(userId).get();
      final userData = userDoc.data();
      if (userData != null && userData['communityPostingBlocked'] == true) {
        throw Exception('Posting disabled by admin due to policy violations');
      }

      final now = DateTime.now();
      final postsRef = _firestore.collection(_postsCollection);
      final postRef = postId != null ? postsRef.doc(postId) : postsRef.doc();
      final normalizedTags = tags
          .map((tag) => tag.trim().toLowerCase())
          .where((tag) => tag.isNotEmpty)
          .toSet()
          .toList();

      final post = CommunityPost(
        id: postRef.id,
        authorId: userId,
        authorNickname: authorNickname,
        authorProfilePicture: authorProfilePicture,
        content: content,
        images: images,
        tags: normalizedTags,
        createdAt: now,
        updatedAt: now,
        metadata: <String, dynamic>{
          'status': 'published',
        },
      );

      final sanitizedUsername = authorNickname
          .trim()
          .toLowerCase()
          .replaceAll(RegExp(r'\s+'), '');

      await postRef.set({
        ...post.toFirestore(),
        'score': 0,
        'upvotes': 0,
        'downvotes': 0,
        'hotScore': 0,
        'risingScore': 0,
        'saveCount': 0,
        'nsfw': false,
        'spoiler': false,
        'sensitive': false,
        'locked': false,
        'archived': false,
        'isPinned': false,
        'authorDisplayName': authorNickname,
        'authorUsername': sanitizedUsername.isEmpty ? 'player' : sanitizedUsername,
        'media': images
            .map((url) => {
                  'type': 'image',
                  'url': url,
                  'thumbnailUrl': url,
                  'isUploaded': true,
                  'isUploading': false,
                })
            .toList(),
        'lastActivityAt': Timestamp.fromDate(now),
        'userVote': 'none',
        'isSaved': false,
        'reportsCount': 0,
        'awardTypes': <String>[],
        'awardCounts': <String, int>{},
        'moderatorIds': <String>[],
      }, SetOptions(merge: true));

      if (kDebugMode) {
        debugPrint('✅ Community post created: ${post.id}');
      }

      return post.id;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error creating community post: $e');
      }
      throw Exception('Failed to create post: $e');
    }
  }

  /// Update existing posts and comments when a user changes their profile media.
  static Future<void> updateUserProfileMedia({
    required String userId,
    String? nickname,
    String? profilePictureUrl,
  }) async {
    final trimmedName = nickname?.trim();
    final postUpdates = <String, dynamic>{};
    final commentUpdates = <String, dynamic>{};

    if (trimmedName != null && trimmedName.isNotEmpty) {
      postUpdates['authorNickname'] = trimmedName;
      commentUpdates['authorNickname'] = trimmedName;
      commentUpdates['authorName'] = trimmedName;
    }

    if (profilePictureUrl != null && profilePictureUrl.isNotEmpty) {
      postUpdates['authorProfilePicture'] = profilePictureUrl;
      commentUpdates['authorProfilePicture'] = profilePictureUrl;
    }

    if (postUpdates.isEmpty && commentUpdates.isEmpty) return;

    try {
      if (postUpdates.isNotEmpty) {
        final postsSnapshot = await _firestore
            .collection(_postsCollection)
            .where('authorId', isEqualTo: userId)
            .get();

        await _applyBatchedUpdates(
          postsSnapshot.docs,
          (batch, doc) => batch.update(doc.reference, postUpdates),
        );
      }

      if (commentUpdates.isNotEmpty) {
        final commentsSnapshot = await _firestore
            .collectionGroup(_commentsCollection)
            .where('authorId', isEqualTo: userId)
            .get();

        await _applyBatchedUpdates(
          commentsSnapshot.docs,
          (batch, doc) => batch.update(doc.reference, commentUpdates),
        );
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint(
          '⚠️ CommunityService: failed to propagate profile media update for $userId: $e',
        );
        debugPrint('$stackTrace');
      }
    }
  }

  /// Get community posts with pagination
  static Future<CommunityPostPage> fetchPostsPage({
    int limit = 20,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
    List<String>? tags,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _firestore
          .collection(_postsCollection)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (tags != null && tags.isNotEmpty) {
        query = query.where(
          'tags',
          arrayContainsAny:
              tags.take(10).map((tag) => tag.trim().toLowerCase()).toList(),
        );
      }

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final snapshot = await query.get();
      final posts =
          snapshot.docs.map((doc) => CommunityPost.fromFirestore(doc)).toList();

      return CommunityPostPage(
        posts: posts,
        lastDocument:
            snapshot.docs.isNotEmpty ? snapshot.docs.last : startAfter,
        hasMore: snapshot.docs.length == limit,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error fetching community posts: $e');
      }
      throw Exception('Failed to fetch posts: $e');
    }
  }

  /// Get a specific post by ID
  static Future<CommunityPost?> getPost(String postId) async {
    try {
      final doc =
          await _firestore.collection(_postsCollection).doc(postId).get();
      if (doc.exists) {
        return CommunityPost.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error fetching post: $e');
      }
      throw Exception('Failed to fetch post: $e');
    }
  }

  /// Get posts by a specific user
  static Future<List<CommunityPost>> getUserPosts(
    String userId, {
    int limit = 20,
  }) async {
    try {
      final snapshot = await _firestore
          .collection(_postsCollection)
          .where('authorId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => CommunityPost.fromFirestore(doc))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error fetching user posts: $e');
      }
      throw Exception('Failed to fetch user posts: $e');
    }
  }

  /// Stream posts authored by a specific user, ordered by latest first.
  static Stream<List<CommunityPost>> getUserPostsStream(
    String userId, {
    int? limit,
  }) {
    Query<Map<String, dynamic>> query = _firestore
        .collection(_postsCollection)
        .where('authorId', isEqualTo: userId)
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true);

    if (limit != null && limit > 0) {
      query = query.limit(limit);
    }

    return query
        .snapshots()
        .debounceTime(const Duration(milliseconds: 300))
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => CommunityPost.fromFirestore(doc))
              .toList(),
        );
  }

  /// Update post content
  static Future<void> updatePost(String postId, String content) async {
    try {
      final userId = _currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      await _firestore.collection(_postsCollection).doc(postId).update({
        'content': content,
        'updatedAt': Timestamp.now(),
      });

      if (kDebugMode) {
        debugPrint('✅ Post updated: $postId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error updating post: $e');
      }
      throw Exception('Failed to update post: $e');
    }
  }

  /// Delete a post (soft delete)
  static Future<void> deletePost(String postId) async {
    try {
      final userId = _currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      await _firestore.collection(_postsCollection).doc(postId).update({
        'isActive': false,
        'updatedAt': Timestamp.now(),
      });

      if (kDebugMode) {
        debugPrint('✅ Post deleted: $postId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error deleting post: $e');
      }
      throw Exception('Failed to delete post: $e');
    }
  }

  // ==================== COMMENT OPERATIONS ====================

  /// Add a comment to a post
  static Future<String> addComment({
    required String postId,
    required String content,
    required String authorNickname,
    String? authorProfilePicture,
    String? parentCommentId,
  }) async {
    try {
      final userId = _currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      final now = DateTime.now();
      final commentRef = _firestore
          .collection(_postsCollection)
          .doc(postId)
          .collection(_commentsCollection)
          .doc();

      final comment = CommunityComment(
        id: commentRef.id,
        postId: postId,
        authorId: userId,
        authorName: authorNickname, // Using nickname as name
        authorNickname: authorNickname,
        authorProfilePicture: authorProfilePicture,
        content: content,
        createdAt: now,
        updatedAt: now,
        parentCommentId: parentCommentId,
      );

      // Use batch to update both comment and post counts
      final batch = _firestore.batch();

      // Add comment
      batch.set(commentRef, comment.toFirestore());

      // Update post comment count
      final postRef = _firestore.collection(_postsCollection).doc(postId);
      batch.update(postRef, {
        'commentsCount': FieldValue.increment(1),
      });

      // If it's a reply, update parent comment reply count
      if (parentCommentId != null) {
        final parentCommentRef = _firestore
            .collection(_postsCollection)
            .doc(postId)
            .collection(_commentsCollection)
            .doc(parentCommentId);
        batch.update(parentCommentRef, {
          'repliesCount': FieldValue.increment(1),
        });
      }

      await batch.commit();

      // Send notification to post owner
      try {
        final post = await getPost(postId);
        if (post != null) {
          await CommunityNotificationService.createCommentNotification(
            postId: postId,
            postAuthorId: post.authorId,
            commenterName: authorNickname,
            commentContent: content,
            postOwnerId: post.authorId,
            fromUserId: userId,
            fromUserNickname: authorNickname,
            fromUserProfilePicture: authorProfilePicture,
            commentId: comment.id,
            parentCommentId: parentCommentId,
          );
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('⚠️ Failed to send comment notification: $e');
        }
      }

      if (kDebugMode) {
        debugPrint('✅ Comment added: ${comment.id}');
      }

      return comment.id;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error adding comment: $e');
      }
      throw Exception('Failed to add comment: $e');
    }
  }

  /// Get comments for a post
  static Future<List<CommunityComment>> getComments(String postId,
      {int limit = 50}) async {
    try {
      final snapshot = await _firestore
          .collection(_postsCollection)
          .doc(postId)
          .collection(_commentsCollection)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: false)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => CommunityComment.fromFirestore(doc))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error fetching comments: $e');
      }
      throw Exception('Failed to fetch comments: $e');
    }
  }

  /// Get replies for a comment
  static Future<List<CommunityComment>> getReplies(
      String postId, String commentId,
      {int limit = 20}) async {
    try {
      final snapshot = await _firestore
          .collection(_postsCollection)
          .doc(postId)
          .collection(_commentsCollection)
          .where('parentCommentId', isEqualTo: commentId)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: false)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => CommunityComment.fromFirestore(doc))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error fetching replies: $e');
      }
      throw Exception('Failed to fetch replies: $e');
    }
  }

  // ==================== LIKE/DISLIKE OPERATIONS ====================

  /// Toggle like/dislike on a post
  static Future<UserLikeStatus> toggleLike(
      String postId, bool isLike, String userNickname) async {
    try {
      final userId = _currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      final likeRef = _firestore
          .collection(_postsCollection)
          .doc(postId)
          .collection(_likesCollection)
          .doc(userId);

      final likeDoc = await likeRef.get();
      final batch = _firestore.batch();
      final postRef = _firestore.collection(_postsCollection).doc(postId);

      if (likeDoc.exists) {
        // User has already liked/disliked
        final existingLike = CommunityLike.fromFirestore(likeDoc);

        if (existingLike.isLike == isLike) {
          // Same action - remove the like/dislike
          batch.delete(likeRef);
          batch.update(postRef, {
            isLike ? 'likesCount' : 'dislikesCount': FieldValue.increment(-1),
          });

          return UserLikeStatus();
        } else {
          // Different action - update the like/dislike
          final updatedLike = existingLike.copyWith(isLike: isLike);
          batch.set(likeRef, updatedLike.toFirestore());
          batch.update(postRef, {
            'likesCount': FieldValue.increment(isLike ? 1 : -1),
            'dislikesCount': FieldValue.increment(isLike ? -1 : 1),
          });

          return UserLikeStatus(
            hasLiked: isLike,
            hasDisliked: !isLike,
            likeId: updatedLike.id,
          );
        }
      } else {
        // New like/dislike
        final newLike = CommunityLike(
          id: userId,
          postId: postId,
          userId: userId,
          userNickname: userNickname,
          isLike: isLike,
          createdAt: DateTime.now(),
        );

        batch.set(likeRef, newLike.toFirestore());
        batch.update(postRef, {
          isLike ? 'likesCount' : 'dislikesCount': FieldValue.increment(1),
        });

        await batch.commit();

        // Send notification to post owner
        try {
          final post = await getPost(postId);
          if (post != null) {
            await CommunityNotificationService.createLikeNotification(
              postId: postId,
              postAuthorId: post.authorId,
              likerName: userNickname,
              isLike: isLike,
              postOwnerId: post.authorId,
              fromUserId: userId,
              fromUserNickname: userNickname,
              fromUserProfilePicture: null, // TODO: Get from user profile
            );
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('⚠️ Failed to send like notification: $e');
          }
        }

        return UserLikeStatus(
          hasLiked: isLike,
          hasDisliked: !isLike,
          likeId: newLike.id,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error toggling like: $e');
      }
      throw Exception('Failed to toggle like: $e');
    }
  }

  /// Get user's like status for a post
  static Future<UserLikeStatus> getUserLikeStatus(String postId) async {
    try {
      final userId = _currentUserId;
      if (userId == null) return const UserLikeStatus();

      final likeDoc = await _firestore
          .collection(_postsCollection)
          .doc(postId)
          .collection(_likesCollection)
          .doc(userId)
          .get();

      if (likeDoc.exists) {
        final like = CommunityLike.fromFirestore(likeDoc);
        return UserLikeStatus(
          hasLiked: like.isLike,
          hasDisliked: !like.isLike,
          likeId: like.id,
        );
      }

      return const UserLikeStatus();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting user like status: $e');
      }
      return const UserLikeStatus();
    }
  }

  // ==================== MODERATION OPERATIONS ====================

  static Stream<List<CommunityPost>> getFlaggedPostsStream() {
    return _firestore
        .collection(_postsCollection)
        .where('isFlagged', isEqualTo: true)
        .where('isActive', isEqualTo: true)
        .orderBy('flaggedAt', descending: true)
        .snapshots()
        .debounceTime(const Duration(milliseconds: 300))
        .map((snapshot) => snapshot.docs
            .map((doc) => CommunityPost.fromFirestore(doc))
            .toList());
  }

  static Future<void> flagPost({
    required String postId,
    required String userId,
    String? reason,
  }) async {
    try {
      await _firestore.collection(_postsCollection).doc(postId).update({
        'isFlagged': true,
        'flaggedBy': FieldValue.arrayUnion([userId]),
        'flaggedReason': reason,
        'flaggedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error flagging post $postId: $e');
      }
      rethrow;
    }
  }

  static Future<void> unflagPost(String postId) async {
    try {
      await _firestore.collection(_postsCollection).doc(postId).update({
        'isFlagged': false,
        'flaggedBy': <String>[],
        'flaggedReason': FieldValue.delete(),
        'flaggedAt': FieldValue.delete(),
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error unflagging post $postId: $e');
      }
      rethrow;
    }
  }

  static Future<void> adminRemovePost({
    required String postId,
    required String adminId,
    String? note,
  }) async {
    try {
      final doc =
          await _firestore.collection(_postsCollection).doc(postId).get();
      final existingMetadata = <String, dynamic>{};
      final rawMetadata = doc.data()?['metadata'];
      if (rawMetadata is Map) {
        existingMetadata.addAll(Map<String, dynamic>.from(rawMetadata));
      }

      existingMetadata['status'] = 'removed';
      existingMetadata['moderation'] = <String, dynamic>{
        'removedBy': adminId,
        'removedAt': FieldValue.serverTimestamp(),
        if (note != null && note.isNotEmpty) 'note': note,
      };

      await _firestore.collection(_postsCollection).doc(postId).update({
        'isActive': false,
        'metadata': existingMetadata,
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error removing post $postId by admin: $e');
      }
      rethrow;
    }
  }

  static Future<void> warnUser({
    required String userId,
    required String adminId,
    String? reason,
    bool blockPosting = true,
  }) async {
    try {
      final updates = <String, dynamic>{
        'communityWarningsCount': FieldValue.increment(1),
      };

      if (blockPosting) {
        updates.addAll({
          'communityPostingBlocked': true,
          'communityBlockedReason':
              reason ?? 'Flagged for community guidelines violation',
          'communityBlockedBy': adminId,
          'communityBlockedAt': FieldValue.serverTimestamp(),
        });
      }

      await _firestore.collection(_usersCollection).doc(userId).set(
            updates,
            SetOptions(merge: true),
          );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error warning user $userId: $e');
      }
      rethrow;
    }
  }

  static Future<void> setUserPostingBlocked({
    required String userId,
    required bool blocked,
    String? adminId,
    String? reason,
  }) async {
    try {
      final updates = <String, dynamic>{
        'communityPostingBlocked': blocked,
      };

      if (blocked) {
        updates.addAll({
          'communityBlockedBy': adminId,
          'communityBlockedReason': reason,
          'communityBlockedAt': FieldValue.serverTimestamp(),
        });
      } else {
        updates.addAll({
          'communityBlockedBy': FieldValue.delete(),
          'communityBlockedReason': FieldValue.delete(),
          'communityBlockedAt': FieldValue.delete(),
        });
      }

      await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .set(updates, SetOptions(merge: true));
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error updating posting block for user $userId: $e');
      }
      rethrow;
    }
  }

  // ==================== STREAM OPERATIONS ====================

  /// Stream of community posts
  static Stream<List<CommunityPost>> getPostsStream({int limit = 20}) {
    return _firestore
        .collection(_postsCollection)
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .debounceTime(const Duration(milliseconds: 300))
        .map((snapshot) => snapshot.docs
            .map((doc) => CommunityPost.fromFirestore(doc))
            .toList());
  }

  /// Stream of comments for a post
  static Stream<List<CommunityComment>> getCommentsStream(String postId,
      {int limit = 50}) {
    return _firestore
        .collection(_postsCollection)
        .doc(postId)
        .collection(_commentsCollection)
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: false)
        .limit(limit)
        .snapshots()
        .debounceTime(const Duration(milliseconds: 200))
        .map((snapshot) => snapshot.docs
            .map((doc) => CommunityComment.fromFirestore(doc))
            .toList());
  }

  static Future<void> _applyBatchedUpdates(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    void Function(
      WriteBatch batch,
      QueryDocumentSnapshot<Map<String, dynamic>> doc,
    )
        update,
  ) async {
    if (docs.isEmpty) return;
    const chunkSize = 400;

    for (var i = 0; i < docs.length; i += chunkSize) {
      final batch = _firestore.batch();
      final end = min(i + chunkSize, docs.length);
      for (var j = i; j < end; j++) {
        update(batch, docs[j]);
      }
      await batch.commit();
    }
  }
}

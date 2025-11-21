import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../../modules/chat/models/chat_message.dart';
import '../../../modules/chat/services/chat_service.dart';
import '../models/feed_comment.dart';
import '../models/feed_post.dart';
import '../models/user_post_state.dart';

class FeedInteractionService {
  FeedInteractionService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    ChatService? chatService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _chatService = chatService ?? ChatService();

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final ChatService _chatService;

  static const _postsCollection = 'community_posts';
  static const _commentsCollection = 'community_comments';

  CollectionReference<Map<String, dynamic>> get _postsRef =>
      _firestore.collection(_postsCollection);

  CollectionReference<Map<String, dynamic>> get _commentsRef =>
      _firestore.collection(_commentsCollection);

  CollectionReference<Map<String, dynamic>> _userStateRef(String userId) =>
      _firestore.collection('user_post_states').doc(userId).collection('posts');

  User _requireUser() {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'not-authenticated',
        message: 'User must be signed in to perform this action.',
      );
    }
    return user;
  }

  Future<Map<String, UserPostState>> fetchUserStates(
    List<String> postIds,
  ) async {
    final user = _auth.currentUser;
    if (user == null || postIds.isEmpty) return const {};

    final ref = _userStateRef(user.uid);
    final Map<String, UserPostState> results = {};
    const chunkSize = 10;

    for (var i = 0; i < postIds.length; i += chunkSize) {
      final chunk = postIds.sublist(
        i,
        min(i + chunkSize, postIds.length),
      );
      final snapshot =
          await ref.where('postId', whereIn: chunk).limit(chunkSize).get();
      for (final doc in snapshot.docs) {
        final data = doc.data();
        results[doc.id] = UserPostState.fromJson({
          ...data,
          'postId': doc.id,
        });
      }
    }

    return results;
  }

  Future<FeedPost> toggleVote(
    FeedPost post,
    UserVoteValue targetVote,
  ) async {
    final user = _requireUser();

    return _firestore.runTransaction((transaction) async {
      final postRef = _postsRef.doc(post.id);
      final postSnap = await transaction.get(postRef);
      if (!postSnap.exists) {
        throw StateError('Post ${post.id} not found');
      }
      final data = postSnap.data()!;

      int upvotes =
          (data['upvotes'] as num?)?.toInt() ?? (data['likesCount'] as num?)?.toInt() ?? post.upvotes;
      int downvotes =
          (data['downvotes'] as num?)?.toInt() ?? (data['dislikesCount'] as num?)?.toInt() ?? post.downvotes;
      int score = (data['score'] as num?)?.toInt() ?? post.score;

      final userStateRef = _userStateRef(user.uid).doc(post.id);
      final userStateSnap = await transaction.get(userStateRef);

      UserPostState currentState = userStateSnap.exists
          ? UserPostState.fromJson({
              ...userStateSnap.data()!,
              'postId': post.id,
              'userId': user.uid,
            })
          : UserPostState.initial(post.id, user.uid);

      final previousVote = currentState.vote;
      var nextVote = targetVote;

      if (previousVote == targetVote) {
        nextVote = UserVoteValue.none;
      }

      if (previousVote == UserVoteValue.upvote) {
        upvotes = max(0, upvotes - 1);
      } else if (previousVote == UserVoteValue.downvote) {
        downvotes = max(0, downvotes - 1);
      }

      if (nextVote == UserVoteValue.upvote) {
        upvotes += 1;
      } else if (nextVote == UserVoteValue.downvote) {
        downvotes += 1;
      }

      score = upvotes - downvotes;

      transaction.update(postRef, {
        'upvotes': upvotes,
        'likesCount': upvotes,
        'downvotes': downvotes,
        'dislikesCount': downvotes,
        'score': score,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final updatedState = currentState.copyWith(
        vote: nextVote,
        updatedAt: DateTime.now(),
      );

      transaction.set(
        userStateRef,
        updatedState.toJson(),
        SetOptions(merge: true),
      );

      return post.copyWith(
        upvotes: upvotes,
        downvotes: downvotes,
        score: score,
        userVote: nextVote,
      );
    });
  }

  Future<FeedPost> toggleSave(FeedPost post) async {
    final user = _requireUser();

    return _firestore.runTransaction((transaction) async {
      final postRef = _postsRef.doc(post.id);
      final postSnap = await transaction.get(postRef);
      if (!postSnap.exists) {
        throw StateError('Post ${post.id} not found');
      }

      final data = postSnap.data()!;
      int saveCount =
          (data['saveCount'] as num?)?.toInt() ?? (data['savesCount'] as num?)?.toInt() ?? post.saveCount;

      final userStateRef = _userStateRef(user.uid).doc(post.id);
      final userStateSnap = await transaction.get(userStateRef);

      UserPostState currentState = userStateSnap.exists
          ? UserPostState.fromJson({
              ...userStateSnap.data()!,
              'postId': post.id,
              'userId': user.uid,
            })
          : UserPostState.initial(post.id, user.uid);

      final isCurrentlySaved = currentState.saved;
      final nextSaved = !isCurrentlySaved;

      saveCount = max(0, saveCount + (nextSaved ? 1 : -1));

      transaction.update(postRef, {
        'saveCount': saveCount,
        'savesCount': saveCount,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final updatedState = currentState.copyWith(
        saved: nextSaved,
        savedAt: nextSaved ? DateTime.now() : null,
        updatedAt: DateTime.now(),
      );

      transaction.set(
        userStateRef,
        updatedState.toJson(),
        SetOptions(merge: true),
      );

      return post.copyWith(
        saveCount: saveCount,
        isSaved: nextSaved,
      );
    });
  }

  Future<void> incrementShareCount(String postId) async {
    final postRef = _postsRef.doc(postId);
    await postRef.update({
      'shareCount': FieldValue.increment(1),
      'sharesCount': FieldValue.increment(1),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> sharePost({
    required FeedPost post,
    required String connectionUserId,
  }) async {
    final user = _requireUser();
    final chatRoom =
        await _chatService.getOrCreateDirectChat(connectionUserId);
    if (chatRoom == null) {
      throw StateError('Unable to create chat with selected connection');
    }

    // Create SharedEntity for post
    final postEntity = SharedEntity(
      type: EntityType.post,
      id: post.id,
      title: post.title ?? post.body ?? 'Post',
      imageUrl: post.media.isNotEmpty ? post.media.first.url : null,
      subtitle: post.authorDisplayName,
      metadata: {
        'postId': post.id,
        'authorId': post.authorId,
        'authorName': post.authorDisplayName,
        'authorAvatar': post.authorAvatarUrl,
        'body': post.body ?? '',
        'mediaCount': post.media.length,
        'media': post.media.map((m) => {
          'url': m.url,
          'type': m.type.toString(),
        }).toList(),
        'tags': post.tags,
        'createdAt': post.createdAt.toIso8601String(),
      },
    );

    await _chatService.sendEntityMessage(
      chatId: chatRoom.id,
      entity: postEntity,
    );

    await incrementShareCount(post.id);
  }

  Future<List<FeedComment>> fetchComments(
    String postId, {
    int limit = 100,
  }) async {
    debugPrint(
      '[FeedInteractionService] fetchComments(postId: $postId, limit: $limit)',
    );
    final snapshot = await _commentsRef
        .where('postId', isEqualTo: postId)
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: false)
        .limit(limit)
        .get();
    debugPrint(
      '[FeedInteractionService] fetchComments raw docs type: '
      '${snapshot.docs.runtimeType} count: ${snapshot.docs.length}',
    );
    final comments = snapshot.docs
        .map(
          (doc) => FeedComment.fromJson({
            ...doc.data(),
            'id': doc.id,
          }),
        )
        .toList();
    debugPrint(
      '[FeedInteractionService] fetchComments mapped list type: '
      '${comments.runtimeType} length: ${comments.length}',
    );
    return List<FeedComment>.from(comments);
  }

  Stream<List<FeedComment>> watchComments(
    String postId, {
    int limit = 100,
  }) {
    return _commentsRef
        .where('postId', isEqualTo: postId)
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: false)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) {
            debugPrint(
              '[FeedInteractionService] watchComments(postId: $postId) snapshot '
              'count: ${snapshot.docs.length} type: ${snapshot.docs.runtimeType}',
            );
            final comments = snapshot.docs
                .map(
                  (doc) => FeedComment.fromJson({
                    ...doc.data(),
                    'id': doc.id,
                  }),
                )
                .toList();
            debugPrint(
              '[FeedInteractionService] watchComments mapped list type: '
              '${comments.runtimeType} length: ${comments.length}',
            );
            return List<FeedComment>.from(comments);
          },
        );
  }

  Future<void> addComment({
    required FeedPost post,
    required String content,
    String? parentId,
  }) async {
    final user = _requireUser();
    final now = DateTime.now();

    final commentRef = _commentsRef.doc();

    final commentData = {
      'id': commentRef.id,
      'postId': post.id,
      'authorId': user.uid,
      'authorDisplayName': user.displayName ?? 'Player',
      'authorUsername': (user.email ?? user.uid).split('@').first,
      'authorProfilePicture': user.photoURL,
      'content': content,
      'body': content,
      'parentCommentId': parentId,
      'parentId': parentId,
      'createdAt': now,
      'updatedAt': now,
      'isActive': true,
      'repliesCount': 0,
      'replyCount': 0,
      'upvotes': 0,
      'downvotes': 0,
    };

    final batch = _firestore.batch();
    batch.set(commentRef, commentData);
    batch.update(
      _postsRef.doc(post.id),
      {
        'commentCount': FieldValue.increment(1),
        'commentsCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
        'lastCommentAuthorName':
            user.displayName ?? user.email ?? 'Player',
        'lastActivityAt': FieldValue.serverTimestamp(),
      },
    );

    if (parentId != null) {
      batch.update(
        _commentsRef.doc(parentId),
        {
          'replyCount': FieldValue.increment(1),
          'repliesCount': FieldValue.increment(1),
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );
    }

    await batch.commit();
  }
}


import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/feed_comment.dart';
import '../models/feed_filters.dart';
import '../models/feed_post.dart';
import '../models/user_post_state.dart';
import '../services/feed_cache_service.dart';
import '../services/feed_interaction_service.dart';
import '../services/firestore_feed_service.dart';

class FeedRepository {
  FeedRepository({
    required FirestoreFeedService feedService,
    required FeedCacheService cacheService,
    required FeedInteractionService interactionService,
  })  : _feedService = feedService,
        _cacheService = cacheService,
        _interactionService = interactionService;

  final FirestoreFeedService _feedService;
  final FeedCacheService _cacheService;
  final FeedInteractionService _interactionService;

  Future<void> initialize() async {
    await _cacheService.init();
  }

  Stream<List<FeedPost>> watchFeed({
    required FeedFilter filter,
    int limit = 20,
  }) {
    return _feedService.watchFeed(filter: filter, limit: limit);
  }

  Future<FeedPage> fetchFeedPage({
    required FeedFilter filter,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
    int limit = 20,
  }) async {
    final page = await _feedService.fetchFeedPage(
      filter: filter,
      startAfter: startAfter,
      limit: limit,
    );

    await _cacheService.cachePosts(filter: filter, posts: page.posts);

    return page;
  }

  List<FeedPost> loadCachedFeed(FeedFilter filter) {
    return _cacheService.getCachedPosts(filter);
  }

  bool isCacheStale(FeedFilter filter) {
    return _cacheService.isStale(filter);
  }

  Stream<FeedPost?> watchPost(String postId) {
    return _feedService.watchPost(postId);
  }

  Future<FeedPost?> getPost(String postId) {
    return _feedService.getPost(postId);
  }

  Future<Map<String, UserPostState>> fetchUserStates(
    List<FeedPost> posts,
  ) async {
    if (posts.isEmpty) return const {};
    return _interactionService
        .fetchUserStates(posts.map((post) => post.id).toList());
  }

  Future<List<FeedPost>> attachUserStates(List<FeedPost> posts) async {
    if (posts.isEmpty) return posts;
    try {
      final states = await fetchUserStates(posts);
      if (states.isEmpty) return posts;
      return posts.map((post) {
        final userState = states[post.id];
        if (userState == null) {
          return post;
        }
        final vote = userState.vote;
        final saved = userState.saved;
        return post.copyWith(
          userVote: vote,
          isSaved: saved,
        );
      }).toList();
    } catch (_) {
      return posts;
    }
  }

  Future<FeedPost> toggleVote(
    FeedPost post,
    UserVoteValue targetVote,
  ) {
    return _interactionService.toggleVote(post, targetVote);
  }

  Future<FeedPost> toggleSave(FeedPost post) {
    return _interactionService.toggleSave(post);
  }

  Future<void> sharePost({
    required FeedPost post,
    required String connectionUserId,
  }) {
    return _interactionService.sharePost(
      post: post,
      connectionUserId: connectionUserId,
    );
  }

  Future<void> addComment({
    required FeedPost post,
    required String content,
    String? parentId,
  }) {
    return _interactionService.addComment(
      post: post,
      content: content,
      parentId: parentId,
    );
  }

  Future<List<FeedComment>> fetchComments(
    String postId, {
    int limit = 100,
  }) {
    return _interactionService.fetchComments(postId, limit: limit);
  }

  Stream<List<FeedComment>> watchComments(
    String postId, {
    int limit = 100,
  }) {
    return _interactionService.watchComments(postId, limit: limit);
  }

  Future<void> clearCache() => _cacheService.clear();
}


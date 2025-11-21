import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/feed_comment.dart';
import '../models/feed_filters.dart';
import '../models/feed_post.dart';
import '../models/user_post_state.dart';
import '../repositories/feed_repository.dart';
import '../services/feed_cache_service.dart';
import '../services/feed_interaction_service.dart';
import '../services/firestore_feed_service.dart';
import 'feed_state.dart';

final feedCacheServiceProvider = Provider<FeedCacheService>(
  (ref) => FeedCacheService(),
  name: 'feedCacheServiceProvider',
);

final feedInteractionServiceProvider = Provider<FeedInteractionService>(
  (ref) => FeedInteractionService(),
  name: 'feedInteractionServiceProvider',
);

final firestoreFeedServiceProvider = Provider<FirestoreFeedService>(
  (ref) => FirestoreFeedService(),
  name: 'firestoreFeedServiceProvider',
);

final feedRepositoryProvider = Provider<FeedRepository>(
  (ref) {
    final feedService = ref.watch(firestoreFeedServiceProvider);
    final cacheService = ref.watch(feedCacheServiceProvider);
    final interactionService = ref.watch(feedInteractionServiceProvider);
    return FeedRepository(
      feedService: feedService,
      cacheService: cacheService,
      interactionService: interactionService,
    );
  },
  name: 'feedRepositoryProvider',
);

final feedControllerProvider =
    StateNotifierProvider<FeedController, FeedState>(
  (ref) {
    final repository = ref.watch(feedRepositoryProvider);
    final controller = FeedController(repository, ref);
    unawaited(controller.initialize());
    return controller;
  },
  name: 'feedControllerProvider',
);

class FeedController extends StateNotifier<FeedState> {
  FeedController(this._repository, this._ref) : super(const FeedState());

  final FeedRepository _repository;
  final Ref _ref;

  StreamSubscription<List<FeedPost>>? _feedSubscription;
  bool _isFetching = false;

  Future<void> initialize({bool forceRefresh = false}) async {
    if (state.initialized && !forceRefresh) return;
    await _repository.initialize();

    final cachedPosts =
        await _repository.attachUserStates(_repository.loadCachedFeed(state.filter));
    final isCacheStale = _repository.isCacheStale(state.filter);

    if (cachedPosts.isNotEmpty && (!forceRefresh || isCacheStale == false)) {
      state = state.copyWith(
        posts: cachedPosts,
        initialized: true,
        fromCache: true,
        hasMore: true,
      );
    }

    await _subscribeToFeed(force: forceRefresh);
    await refresh(silent: cachedPosts.isNotEmpty && !forceRefresh);
  }

  Future<void> refresh({bool silent = false}) async {
    if (_isFetching) return;
    _isFetching = true;
    state = state.copyWith(
      isLoading: !silent,
      isRefreshing: true,
      isLoadingMore: false,
      errorMessage: null,
    );

    try {
      final page = await _repository.fetchFeedPage(
        filter: state.filter,
        startAfter: null,
      );
      final postsWithState = await _repository.attachUserStates(page.posts);
      state = state.copyWith(
        posts: postsWithState,
        lastDocument: page.lastDocument,
        hasMore: page.hasMore,
        isLoading: false,
        isRefreshing: false,
        errorMessage: null,
        initialized: true,
        fromCache: false,
      );
    } catch (err) {
      state = state.copyWith(
        isLoading: false,
        isRefreshing: false,
        errorMessage: err.toString(),
      );
    } finally {
      _isFetching = false;
    }
  }

  Future<void> fetchNextPage() async {
    if (_isFetching || !state.hasMore || state.lastDocument == null) {
      return;
    }
    _isFetching = true;
    state = state.copyWith(isLoadingMore: true);
    try {
      final page = await _repository.fetchFeedPage(
        filter: state.filter,
        startAfter: state.lastDocument,
      );
      final postsWithState = await _repository.attachUserStates(page.posts);
      final mergedPosts = _mergePosts(state.posts, postsWithState);
      state = state.copyWith(
        posts: mergedPosts,
        lastDocument: page.lastDocument,
        hasMore: page.hasMore,
        errorMessage: null,
        isLoadingMore: false,
      );
    } catch (err) {
      state = state.copyWith(
        errorMessage: err.toString(),
        isLoadingMore: false,
      );
    } finally {
      _isFetching = false;
    }
  }

  Future<void> updateFilter(FeedFilter filter) async {
    if (filter == state.filter) return;
    await _feedSubscription?.cancel();
    state = state.copyWith(
      filter: filter,
      posts: const [],
      lastDocument: null,
      hasMore: true,
      isLoading: true,
      isLoadingMore: false,
      errorMessage: null,
      initialized: false,
    );
    await initialize(forceRefresh: true);
  }

  Future<void> _subscribeToFeed({bool force = false}) async {
    await _feedSubscription?.cancel();
    state = state.copyWith(isStreaming: true);
    _feedSubscription = _repository.watchFeed(filter: state.filter).listen(
      (posts) async {
        final postsWithState = await _repository.attachUserStates(posts);
        _handleFeedSnapshot(postsWithState);
      },
      onError: (error, stackTrace) {
        state = state.copyWith(
          errorMessage: error.toString(),
          isStreaming: false,
        );
      },
    );
  }

  void _handleFeedSnapshot(List<FeedPost> snapshotPosts) {
    if (snapshotPosts.isEmpty && state.posts.isEmpty) {
      state = state.copyWith(isStreaming: false);
      return;
    }

    final merged = _mergePosts(state.posts, snapshotPosts);
    state = state.copyWith(
      posts: merged,
      isStreaming: false,
      initialized: true,
    );
  }

  Future<void> toggleVote(
    FeedPost post, {
    required UserVoteValue vote,
  }) async {
    try {
      final updatedPost = await _repository.toggleVote(post, vote);
      _replacePost(updatedPost);
    } catch (error) {
      state = state.copyWith(errorMessage: error.toString());
    }
  }

  Future<void> toggleSave(FeedPost post) async {
    try {
      final updatedPost = await _repository.toggleSave(post);
      _replacePost(updatedPost);
    } catch (error) {
      state = state.copyWith(errorMessage: error.toString());
    }
  }

  Future<void> sharePost({
    required FeedPost post,
    required String connectionUserId,
  }) async {
    await _repository.sharePost(
      post: post,
      connectionUserId: connectionUserId,
    );
    _replacePost(
      post.copyWith(shareCount: post.shareCount + 1),
    );
  }
  Stream<List<FeedComment>> watchComments(
    String postId, {
    int limit = 100,
  }) {
    return _repository.watchComments(postId, limit: limit);
  }

  Future<void> addComment({
    required FeedPost post,
    required String content,
    String? parentId,
  }) async {
    await _repository.addComment(
      post: post,
      content: content,
      parentId: parentId,
    );
    _replacePost(
      post.copyWith(commentCount: post.commentCount + 1),
    );
  }

  void _replacePost(FeedPost updatedPost) {
    final updatedPosts = state.posts.map((post) {
      if (post.id == updatedPost.id) {
        return updatedPost;
      }
      return post;
    }).toList();
    state = state.copyWith(posts: updatedPosts);
  }

  List<FeedPost> _mergePosts(
    List<FeedPost> current,
    List<FeedPost> incoming,
  ) {
    final Map<String, FeedPost> mapped = {
      for (final post in current) post.id: post,
    };

    for (final post in incoming) {
      mapped[post.id] = post;
    }

    final mergedList = mapped.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return mergedList;
  }

  @override
  void dispose() {
    _feedSubscription?.cancel();
    super.dispose();
  }
}


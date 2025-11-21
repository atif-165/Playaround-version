import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/feed_filters.dart';
import '../models/feed_post.dart';

class FeedState {
  const FeedState({
    this.posts = const <FeedPost>[],
    this.filter = FeedFilter.defaultFilter,
    this.isLoading = false,
    this.isRefreshing = false,
    this.isLoadingMore = false,
    this.isStreaming = false,
    this.hasMore = true,
    this.errorMessage,
    this.lastDocument,
    this.initialized = false,
    this.fromCache = false,
  });

  final List<FeedPost> posts;
  final FeedFilter filter;
  final bool isLoading;
  final bool isRefreshing;
  final bool isLoadingMore;
  final bool isStreaming;
  final bool hasMore;
  final String? errorMessage;
  final DocumentSnapshot<Map<String, dynamic>>? lastDocument;
  final bool initialized;
  final bool fromCache;

  bool get hasError => errorMessage != null && errorMessage!.isNotEmpty;

  FeedState copyWith({
    List<FeedPost>? posts,
    FeedFilter? filter,
    bool? isLoading,
    bool? isRefreshing,
    bool? isLoadingMore,
    bool? isStreaming,
    bool? hasMore,
    String? errorMessage,
    DocumentSnapshot<Map<String, dynamic>>? lastDocument,
    bool? initialized,
    bool? fromCache,
  }) {
    return FeedState(
      posts: posts ?? List<FeedPost>.from(this.posts),
      filter: filter ?? this.filter,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isStreaming: isStreaming ?? this.isStreaming,
      hasMore: hasMore ?? this.hasMore,
      errorMessage: errorMessage ?? this.errorMessage,
      lastDocument: lastDocument ?? this.lastDocument,
      initialized: initialized ?? this.initialized,
      fromCache: fromCache ?? this.fromCache,
    );
  }
}


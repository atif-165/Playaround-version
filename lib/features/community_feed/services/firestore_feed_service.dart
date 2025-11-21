import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/feed_filters.dart';
import '../models/feed_post.dart';

class FeedPage {
  FeedPage({
    required this.posts,
    required this.lastDocument,
    required this.hasMore,
  });

  final List<FeedPost> posts;
  final DocumentSnapshot<Map<String, dynamic>>? lastDocument;
  final bool hasMore;
}

class FirestoreFeedService {
  FirestoreFeedService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  static const _postsCollection = 'community_posts';

  CollectionReference<Map<String, dynamic>> get _postsRef =>
      _firestore.collection(_postsCollection);

  Stream<List<FeedPost>> watchFeed({
    required FeedFilter filter,
    int limit = 20,
  }) {
    final query = _buildFeedQuery(filter, limit: limit);
    return query.snapshots().map(
          (snapshot) =>
              snapshot.docs.map((doc) => _mapPost(doc)).whereType<FeedPost>().toList(),
        );
  }

  Future<FeedPage> fetchFeedPage({
    required FeedFilter filter,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
    int limit = 20,
  }) async {
    var query = _buildFeedQuery(filter, limit: limit);

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    final snapshot = await query.get();
    final posts = snapshot.docs.map(_mapPost).whereType<FeedPost>().toList();

    return FeedPage(
      posts: posts,
      lastDocument: snapshot.docs.isNotEmpty ? snapshot.docs.last : startAfter,
      hasMore: snapshot.docs.length == limit,
    );
  }

  Stream<FeedPost?> watchPost(String postId) {
    return _postsRef.doc(postId).snapshots().map(
          (doc) => doc.exists ? _mapPost(doc) : null,
        );
  }

  Future<FeedPost?> getPost(String postId) async {
    final doc = await _postsRef.doc(postId).get();
    if (!doc.exists) return null;
    return _mapPost(doc);
  }

  Query<Map<String, dynamic>> _buildFeedQuery(
    FeedFilter filter, {
    required int limit,
  }) {
    var query = _postsRef.where('isActive', isEqualTo: true);

    if (!filter.includeNsfw) {
      query = query.where('nsfw', isEqualTo: false);
    }
    if (!filter.includeSpoilers) {
      query = query.where('spoiler', isEqualTo: false);
    }
    if (filter.authorId != null) {
      query = query.where('authorId', isEqualTo: filter.authorId);
    }
    if (filter.sports.isNotEmpty) {
      query = query.where('tags', arrayContainsAny: filter.sports.take(10).toList());
    }

    switch (filter.sort) {
      case FeedSort.newest:
        query = query.orderBy('createdAt', descending: true);
        break;
      case FeedSort.top:
        query = query.orderBy('score', descending: true).orderBy(
              'createdAt',
              descending: true,
            );
        break;
      case FeedSort.hot:
        query = query.orderBy('hotScore', descending: true).orderBy(
              'createdAt',
              descending: true,
            );
        break;
      case FeedSort.rising:
        query = query.orderBy('risingScore', descending: true).orderBy(
              'createdAt',
              descending: true,
            );
        break;
    }

    final rangeStart = _timeRangeStart(filter);
    if (rangeStart != null) {
      query = query.where('createdAt', isGreaterThan: rangeStart);
    }

    return query.limit(limit);
  }

  Timestamp? _timeRangeStart(FeedFilter filter) {
    if (filter.sort == FeedSort.newest) {
      return null;
    }

    final now = DateTime.now();
    late DateTime start;

    switch (filter.timeRange) {
      case FeedTimeRange.day:
        start = now.subtract(const Duration(days: 1));
        break;
      case FeedTimeRange.week:
        start = now.subtract(const Duration(days: 7));
        break;
      case FeedTimeRange.month:
        start = DateTime(now.year, now.month - 1, now.day, now.hour);
        break;
      case FeedTimeRange.year:
        start = DateTime(now.year - 1, now.month, now.day, now.hour);
        break;
      case FeedTimeRange.all:
        return null;
    }

    return Timestamp.fromDate(start);
  }

  FeedPost? _mapPost(DocumentSnapshot<Map<String, dynamic>> doc) {
    try {
      final data = doc.data();
      if (data == null) return null;
      return FeedPost.fromJson({
        ...data,
        'id': doc.id,
      });
    } catch (e, stack) {
      debugPrint('🔥 Failed to map FeedPost ${doc.id}: $e\n$stack');
      return null;
    }
  }
}


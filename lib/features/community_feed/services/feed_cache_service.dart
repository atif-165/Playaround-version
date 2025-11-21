import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import '../models/feed_filters.dart';
import '../models/feed_post.dart';

class FeedCacheService {
  FeedCacheService({
    HiveInterface? hive,
  }) : _hive = hive ?? Hive;

  static const _boxName = 'community_feed_cache_v1';
  static const _timestampKey = 'cachedAt';
  static const _postsKey = 'posts';

  final HiveInterface _hive;

  Box<Map>? _box;

  Future<void> init() async {
    if (_box != null && _box!.isOpen) return;
    if (!_hive.isBoxOpen(_boxName)) {
      _box = await _hive.openBox<Map>(_boxName);
    } else {
      _box = _hive.box<Map>(_boxName);
    }
  }

  Future<void> cachePosts({
    required FeedFilter filter,
    required List<FeedPost> posts,
  }) async {
    await init();
    final key = _filterKey(filter);
    final payload = {
      _timestampKey: DateTime.now().toIso8601String(),
      _postsKey: posts.map((post) => post.toJson()).toList(),
    };
    await _box?.put(key, Map<String, dynamic>.from(payload));
  }

  List<FeedPost> getCachedPosts(FeedFilter filter) {
    if (_box == null || !_box!.isOpen) return const [];
    final key = _filterKey(filter);
    final payload = _box!.get(key);
    if (payload == null) return const [];
    final posts = payload[_postsKey];
    if (posts is! List) return const [];
    return posts
        .map((dynamic json) => FeedPost.fromJson(
              Map<String, dynamic>.from(json as Map),
            ))
        .toList();
  }

  bool isStale(
    FeedFilter filter, {
    Duration ttl = const Duration(minutes: 10),
  }) {
    if (_box == null || !_box!.isOpen) return true;
    final key = _filterKey(filter);
    final payload = _box!.get(key);
    if (payload == null) return true;
    final cachedAtRaw = payload[_timestampKey];
    if (cachedAtRaw is! String) return true;
    final cachedAt = DateTime.tryParse(cachedAtRaw);
    if (cachedAt == null) return true;
    return DateTime.now().difference(cachedAt) > ttl;
  }

  Future<void> clear() async {
    if (_box == null || !_box!.isOpen) return;
    await _box!.clear();
  }

  String _filterKey(FeedFilter filter) {
    final json = filter.toJson();
    final normalized = Map<String, dynamic>.from(json)
      ..removeWhere((key, value) => value == null);
    return base64Url.encode(utf8.encode(jsonEncode(normalized)));
  }
}


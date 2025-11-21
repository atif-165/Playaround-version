import 'dart:async';

import 'package:async/async.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Supported Firestore collections to cache locally.
enum FirestoreCacheCollection {
  users,
  tournaments,
  bookings,
}

extension FirestoreCacheCollectionX on FirestoreCacheCollection {
  String get boxName {
    switch (this) {
      case FirestoreCacheCollection.users:
        return 'firestore_cache_users';
      case FirestoreCacheCollection.tournaments:
        return 'firestore_cache_tournaments';
      case FirestoreCacheCollection.bookings:
        return 'firestore_cache_bookings';
    }
  }
}

/// Local cache layer on top of Firestore using Hive for persistence.
///
/// The cache stores normalized versions of Firestore documents and reconstructs
/// the expected Firestore data types (e.g., [Timestamp], [GeoPoint],
/// [DocumentReference]) when reading them back.
class FirestoreCacheService {
  FirestoreCacheService._();

  static final FirestoreCacheService instance = FirestoreCacheService._();

  static const String _metadataKey = '__meta__';
  static const Duration _defaultTtl = Duration(minutes: 10);

  bool _initialized = false;
  final Map<FirestoreCacheCollection, Box<dynamic>> _boxes = {};
  final _initLock = AsyncMemoizer<void>();

  Future<void> init() {
    return _initLock.runOnce(() async {
      if (_initialized) return;

      try {
        // Attempt to initialize Hive if it hasn't been initialized elsewhere.
        await Hive.initFlutter();
      } catch (_) {
        // Ignore errors caused by Hive being already initialized.
      }

      for (final collection in FirestoreCacheCollection.values) {
        final name = collection.boxName;
        if (Hive.isBoxOpen(name)) {
          _boxes[collection] = Hive.box<dynamic>(name);
        } else {
          _boxes[collection] = await Hive.openBox<dynamic>(name);
        }
      }

      _initialized = true;
    });
  }

  Future<void> cacheDocument({
    required FirestoreCacheCollection collection,
    required String docId,
    required Map<String, dynamic> data,
  }) async {
    await init();
    final box = _boxes[collection];
    if (box == null) return;

    final normalized = _normalize(data);
    await box.put(
      docId,
      {
        'data': normalized,
        'updatedAt': DateTime.now().toIso8601String(),
      },
    );
    await _updateCollectionMetadata(box);
  }

  Future<void> cacheDocuments({
    required FirestoreCacheCollection collection,
    required Map<String, Map<String, dynamic>> documents,
  }) async {
    if (documents.isEmpty) return;
    await init();
    final box = _boxes[collection];
    if (box == null) return;

    final nowIso = DateTime.now().toIso8601String();
    final entries = <String, Map<String, dynamic>>{};
    documents.forEach((key, value) {
      entries[key] = {
        'data': _normalize(value),
        'updatedAt': nowIso,
      };
    });
    await box.putAll(entries);
    await _updateCollectionMetadata(box);
  }

  Future<Map<String, dynamic>?> getDocument({
    required FirestoreCacheCollection collection,
    required String docId,
    Duration? maxAge,
  }) async {
    await init();
    final box = _boxes[collection];
    if (box == null) return null;

    final raw = box.get(docId);
    if (raw is! Map) return null;

    final updatedAt = _parseDateTime(raw['updatedAt'] as String?);
    if (updatedAt == null) return null;

    if (_isExpired(updatedAt, maxAge ?? _defaultTtl)) {
      await box.delete(docId);
      return null;
    }

    final data = raw['data'];
    if (data is! Map) return null;

    return Map<String, dynamic>.from(_denormalize(data));
  }

  Future<List<Map<String, dynamic>>> getCollectionDocuments({
    required FirestoreCacheCollection collection,
    Duration? maxAge,
  }) async {
    await init();
    final box = _boxes[collection];
    if (box == null) return [];

    final metadata = box.get(_metadataKey) as Map<dynamic, dynamic>?;
    if (metadata != null) {
      final updatedAt = _parseDateTime(metadata['updatedAt'] as String?);
      if (updatedAt != null && _isExpired(updatedAt, maxAge ?? _defaultTtl)) {
        await box.clear();
        return [];
      }
    }

    final results = <Map<String, dynamic>>[];
    for (final key in box.keys) {
      if (key == _metadataKey) continue;
      final raw = box.get(key);
      if (raw is! Map) continue;
      final updatedAt = _parseDateTime(raw['updatedAt'] as String?);
      if (updatedAt == null || _isExpired(updatedAt, maxAge ?? _defaultTtl)) {
        continue;
      }
      final data = raw['data'];
      if (data is! Map) continue;
      results.add(Map<String, dynamic>.from(_denormalize(data)));
    }

    return results;
  }

  Future<void> mergeDocument({
    required FirestoreCacheCollection collection,
    required String docId,
    required Map<String, dynamic> updates,
  }) async {
    await init();
    final box = _boxes[collection];
    if (box == null) return;

    final current = await getDocument(
      collection: collection,
      docId: docId,
      maxAge: const Duration(days: 30),
    );

    final merged = <String, dynamic>{};
    if (current != null) {
      merged.addAll(current);
    }
    merged.addAll(updates);

    await cacheDocument(
      collection: collection,
      docId: docId,
      data: merged,
    );
  }

  Future<void> removeDocument({
    required FirestoreCacheCollection collection,
    required String docId,
  }) async {
    await init();
    final box = _boxes[collection];
    if (box == null) return;
    await box.delete(docId);
  }

  Future<void> clearCollection(FirestoreCacheCollection collection) async {
    await init();
    final box = _boxes[collection];
    if (box == null) return;
    await box.clear();
  }

  Future<void> dispose() async {
    for (final box in _boxes.values) {
      await box.close();
    }
    _boxes.clear();
    _initialized = false;
  }

  Future<void> _updateCollectionMetadata(Box<dynamic> box) async {
    await box.put(_metadataKey, {
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  bool _isExpired(DateTime updatedAt, Duration maxAge) {
    return DateTime.now().difference(updatedAt) > maxAge;
  }

  DateTime? _parseDateTime(String? input) {
    if (input == null) return null;
    return DateTime.tryParse(input);
  }

  dynamic _normalize(dynamic value) {
    if (value is Timestamp) {
      return {
        '__type': 'ts',
        'seconds': value.seconds,
        'nanoseconds': value.nanoseconds,
      };
    }
    if (value is DateTime) {
      return {
        '__type': 'dt',
        'value': value.toIso8601String(),
      };
    }
    if (value is GeoPoint) {
      return {
        '__type': 'geo',
        'lat': value.latitude,
        'lng': value.longitude,
      };
    }
    if (value is DocumentReference) {
      return {
        '__type': 'ref',
        'path': value.path,
      };
    }
    if (value is Iterable) {
      return value.map(_normalize).toList();
    }
    if (value is Map) {
      final mapped = <String, dynamic>{};
      value.forEach((key, dynamic val) {
        mapped[key.toString()] = _normalize(val);
      });
      return mapped;
    }
    return value;
  }

  dynamic _denormalize(dynamic value) {
    if (value is Map && value.containsKey('__type')) {
      switch (value['__type']) {
        case 'ts':
          final seconds = value['seconds'] as int? ?? 0;
          final nanoseconds = value['nanoseconds'] as int? ?? 0;
          return Timestamp(seconds, nanoseconds);
        case 'dt':
          final raw = value['value'] as String?;
          return raw != null ? DateTime.tryParse(raw) ?? DateTime.now() : null;
        case 'geo':
          final lat = (value['lat'] as num?)?.toDouble() ?? 0.0;
          final lng = (value['lng'] as num?)?.toDouble() ?? 0.0;
          return GeoPoint(lat, lng);
        case 'ref':
          final path = value['path'] as String?;
          if (path == null) return null;
          return FirebaseFirestore.instance.doc(path);
        default:
          return value;
      }
    }

    if (value is Map) {
      final mapped = <String, dynamic>{};
      value.forEach((key, dynamic val) {
        mapped[key.toString()] = _denormalize(val);
      });
      return mapped;
    }

    if (value is Iterable) {
      return value.map(_denormalize).toList();
    }

    return value;
  }
}

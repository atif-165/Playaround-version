import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../datasources/firestore_booking_data_source.dart';
import '../datasources/firestore_matchmaking_data_source.dart';
import '../datasources/mock_data_source.dart';
import '../local/sync_manager.dart';
import '../models/booking_model.dart' as data;
import '../models/listing_model.dart';
import '../../services/firestore_cache_service.dart';
import '../../core/utils/stream_debounce.dart';

typedef PushNotifier = Future<void> Function(
  String userId,
  String title,
  String message,
);

class BookingRepository {
  BookingRepository({
    MockDataSource? mockDataSource,
    FirestoreBookingDataSource? bookingDataSource,
    FirestoreMatchmakingDataSource? listingDataSource,
    SyncManager? syncManager,
    FirebaseFirestore? firestore,
    PushNotifier? pushNotifier,
    FirestoreCacheService? cacheService,
  })  : _mockDataSource = mockDataSource ?? MockDataSource(),
        _bookingDataSource = bookingDataSource ?? FirestoreBookingDataSource(),
        _listingDataSource =
            listingDataSource ?? FirestoreMatchmakingDataSource(),
        _syncManager = syncManager ?? SyncManager.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _pushNotifier = pushNotifier ??
            ((userId, title, message) async {
              if (kDebugMode) {
                debugPrint('📣 Push mock to $userId: $title -> $message');
              }
            }),
        _cacheService = cacheService ?? FirestoreCacheService.instance;

  final MockDataSource _mockDataSource;
  final FirestoreBookingDataSource _bookingDataSource;
  final FirestoreMatchmakingDataSource _listingDataSource;
  final SyncManager _syncManager;
  final FirebaseFirestore _firestore;
  final PushNotifier _pushNotifier;
  final FirestoreCacheService _cacheService;
  final _uuid = const Uuid();

  Future<List<data.BookingModel>> _loadCachedBookings({
    String? userId,
    String? providerId,
  }) async {
    final cachedDocs = await _cacheService.getCollectionDocuments(
      collection: FirestoreCacheCollection.bookings,
      maxAge: const Duration(minutes: 5),
    );

    final filtered = cachedDocs.where((doc) {
      if (userId != null && doc['userId'] != userId) {
        return false;
      }
      if (providerId != null && doc['providerId'] != providerId) {
        return false;
      }
      return true;
    });

    return filtered
        .map(
            (doc) => data.BookingModel.fromJson(Map<String, dynamic>.from(doc)))
        .toList();
  }

  void _cacheBookings(List<data.BookingModel> bookings) {
    if (bookings.isEmpty) return;
    final documents = <String, Map<String, dynamic>>{};
    for (final booking in bookings) {
      documents[booking.id] = booking.toJson();
    }
    unawaited(_cacheService.cacheDocuments(
      collection: FirestoreCacheCollection.bookings,
      documents: documents,
    ));
  }

  Future<void> init() async {
    await _syncManager.init();
    await _cacheService.init();
  }

  Future<List<ListingModel>> loadListings(
      {bool prioritizeRemote = true}) async {
    if (prioritizeRemote) {
      try {
        final listings = await _listingDataSource.fetchListings();
        if (listings.isNotEmpty) {
          unawaited(_syncManager.cacheListings(listings));
          return listings;
        }
      } catch (error, stack) {
        if (kDebugMode) {
          debugPrint('🧾 BookingRepository.loadListings remote failed: $error');
          debugPrint(stack.toString());
        }
      }
    }

    final cached = _syncManager.getCachedListings();
    if (cached.isNotEmpty) {
      return cached;
    }

    final mockListings = await _mockDataSource.loadListings();
    unawaited(_syncManager.cacheListings(mockListings));
    return mockListings;
  }

  Future<data.BookingModel> createBooking({
    required String userId,
    required String providerId,
    required String listingId,
    required String sport,
    required DateTime startTime,
    required DateTime endTime,
    List<PriceComponent> priceComponents = const [],
    Map<String, dynamic> extras = const {},
    String? notes,
  }) async {
    final subtotal = priceComponents.fold<double>(
        0, (sum, component) => sum + component.amount);
    final booking = data.BookingModel(
      id: _uuid.v4(),
      userId: userId,
      providerId: providerId,
      listingId: listingId,
      sport: sport,
      startTime: startTime,
      endTime: endTime,
      status: data.BookingStatusType.confirmed,
      priceComponents: priceComponents,
      extras: extras,
      subtotal: subtotal,
      total: subtotal,
      notes: notes,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _syncManager.enqueueBooking(booking);

    try {
      await _bookingDataSource.saveBooking(booking);
      await _syncManager.markBookingSynced(booking.id, booking);
    } catch (error) {
      if (kDebugMode) {
        debugPrint('⚠️ BookingRepository.createBooking remote failure: $error');
      }
    }

    _cacheBookings([booking]);

    return booking;
  }

  Stream<List<data.BookingModel>> watchBookingsForUser(String userId) async* {
    final cached = await _loadCachedBookings(userId: userId);
    if (cached.isNotEmpty) {
      yield cached;
    } else {
      final syncCached = _syncManager.getCachedBookingsForUser(userId);
      if (syncCached.isNotEmpty) {
        yield syncCached;
      }
    }

    try {
      await for (final bookings in _bookingDataSource
          .watchBookingsForUser(userId)
          .debounceTime(const Duration(milliseconds: 350))) {
        await _syncManager.cacheBookings(bookings);
        _cacheBookings(bookings);
        yield bookings;
      }
    } catch (error, stack) {
      if (kDebugMode) {
        debugPrint('🧾 BookingRepository.watchBookingsForUser failed: $error');
        debugPrint(stack.toString());
      }
      final fallback = await _loadCachedBookings(userId: userId);
      if (fallback.isNotEmpty) {
        yield fallback;
        return;
      }
      final syncCached = _syncManager.getCachedBookingsForUser(userId);
      if (syncCached.isNotEmpty) {
        yield syncCached;
      } else {
        rethrow;
      }
    }
  }

  Stream<List<data.BookingModel>> watchBookingsForProvider(
      String providerId) async* {
    final cached = await _loadCachedBookings(providerId: providerId);
    if (cached.isNotEmpty) {
      yield cached;
    } else {
      final syncCached = _syncManager.getCachedBookingsForProvider(providerId);
      if (syncCached.isNotEmpty) {
        yield syncCached;
      }
    }

    try {
      await for (final bookings in _bookingDataSource
          .watchBookingsForProvider(providerId)
          .debounceTime(const Duration(milliseconds: 350))) {
        await _syncManager.cacheBookings(bookings);
        _cacheBookings(bookings);
        yield bookings;
      }
    } catch (error, stack) {
      if (kDebugMode) {
        debugPrint(
            '🧾 BookingRepository.watchBookingsForProvider failed: $error');
        debugPrint(stack.toString());
      }
      final fallback = await _loadCachedBookings(providerId: providerId);
      if (fallback.isNotEmpty) {
        yield fallback;
        return;
      }
      final syncCached = _syncManager.getCachedBookingsForProvider(providerId);
      if (syncCached.isNotEmpty) {
        yield syncCached;
      } else {
        rethrow;
      }
    }
  }

  Future<data.BookingModel?> fetchBooking(String bookingId) async {
    try {
      final cached = await _cacheService.getDocument(
        collection: FirestoreCacheCollection.bookings,
        docId: bookingId,
        maxAge: const Duration(minutes: 5),
      );
      if (cached != null) {
        return data.BookingModel.fromJson(Map<String, dynamic>.from(cached));
      }

      final booking = await _bookingDataSource.fetchBookingById(bookingId);
      if (booking != null) {
        await _syncManager.cacheBookings([booking]);
        _cacheBookings([booking]);
        return booking;
      }
    } catch (error, stack) {
      if (kDebugMode) {
        debugPrint('🧾 BookingRepository.fetchBooking failed: $error');
        debugPrint(stack.toString());
      }
    }
    final fallback = await _cacheService.getDocument(
      collection: FirestoreCacheCollection.bookings,
      docId: bookingId,
      maxAge: const Duration(hours: 1),
    );
    if (fallback != null) {
      return data.BookingModel.fromJson(Map<String, dynamic>.from(fallback));
    }
    return _syncManager.getCachedBooking(bookingId);
  }

  Future<void> cancelBooking({
    required data.BookingModel booking,
    String reason = 'Cancelled by user',
  }) async {
    final updated = booking.copyWith(
      status: data.BookingStatusType.cancelled,
      cancellationReason: reason,
      updatedAt: DateTime.now(),
    );
    await _syncManager.markBookingSynced(updated.id, updated);
    _cacheBookings([updated]);

    try {
      await _bookingDataSource.updateBookingStatus(
        bookingId: updated.id,
        status: data.BookingStatusType.cancelled,
        cancellationReason: reason,
      );
      await _restoreListingAvailability(updated);
      await _pushNotifier(
        booking.providerId,
        'Booking cancelled',
        'Booking ${updated.id} has been cancelled.',
      );
    } catch (error) {
      if (kDebugMode) {
        debugPrint('⚠️ BookingRepository.cancelBooking remote failure: $error');
      }
    }
  }

  Future<void> syncPendingBookings() async {
    await _syncManager.syncBookings((booking) async {
      await _bookingDataSource.saveBooking(booking);
      _cacheBookings([booking]);
    });
  }

  Future<List<data.BookingModel>> loadCachedBookingsForUser(
      String userId) async {
    final cached = await _loadCachedBookings(userId: userId);
    if (cached.isNotEmpty) {
      return cached;
    }
    return _syncManager.getCachedBookingsForUser(userId);
  }

  Future<List<data.BookingModel>> loadCachedBookingsForProvider(
      String providerId) async {
    final cached = await _loadCachedBookings(providerId: providerId);
    if (cached.isNotEmpty) {
      return cached;
    }
    return _syncManager.getCachedBookingsForProvider(providerId);
  }

  data.BookingModel? getCachedBooking(String bookingId) {
    return _syncManager.getCachedBooking(bookingId);
  }

  Future<void> _restoreListingAvailability(data.BookingModel booking) async {
    try {
      final listingRef =
          _firestore.collection('listings').doc(booking.listingId);
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(listingRef);
        if (!snapshot.exists) return;
        final data = snapshot.data() as Map<String, dynamic>;
        final availability =
            Map<String, dynamic>.from(data['availability'] ?? {});
        final dateKey = booking.startTime.toIso8601String().split('T').first;
        final slots = (availability[dateKey] as List<dynamic>? ?? []).toSet();
        slots.add(
            '${booking.startTime.toIso8601String()}-${booking.endTime.toIso8601String()}');
        availability[dateKey] = slots.toList();
        transaction.update(listingRef, {
          'availability': availability,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
    } catch (error) {
      if (kDebugMode) {
        debugPrint(
            '⚠️ Failed to restore availability for listing ${booking.listingId}: $error');
      }
    }
  }
}

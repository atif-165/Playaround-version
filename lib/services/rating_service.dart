import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/rating_model.dart';
import '../models/booking_model.dart';
import '../models/listing_model.dart';
import '../models/notification_model.dart';
import 'notification_service.dart';

/// Service for managing ratings and reviews
class RatingService {
  static final RatingService _instance = RatingService._internal();
  factory RatingService() => _instance;
  RatingService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final NotificationService _notificationService = NotificationService();

  // Collection names
  static const String _ratingsCollection = 'ratings';
  static const String _ratingStatsCollection = 'rating_stats';
  static const String _pendingRatingsCollection = 'pending_ratings';

  /// Create a new rating
  Future<void> createRating({
    required String bookingId,
    required String ratedEntityId,
    required RatingType ratingType,
    required int stars,
    String? feedback,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User must be authenticated to create rating');
      }

      // Validate star rating
      if (stars < 1 || stars > 5) {
        throw Exception('Star rating must be between 1 and 5');
      }

      // Check if rating already exists for this booking and entity
      final existingRating = await _getRatingByBookingAndEntity(
        bookingId,
        ratedEntityId,
        user.uid,
      );

      if (existingRating != null) {
        throw Exception('Rating already exists for this booking');
      }

      // Create rating document ID
      final ratingId = '${ratingType.value}_${ratedEntityId}_$bookingId';

      final rating = RatingModel(
        id: ratingId,
        bookingId: bookingId,
        ratedEntityId: ratedEntityId,
        ratingType: ratingType,
        ratedBy: user.uid,
        ratedByName: user.displayName ?? 'Anonymous',
        ratedByProfilePicture: user.photoURL,
        stars: stars,
        feedback: feedback?.trim(),
        timestamp: DateTime.now(),
      );

      // Use batch write to ensure consistency
      final batch = _firestore.batch();

      // Add rating
      batch.set(
        _firestore.collection(_ratingsCollection).doc(ratingId),
        rating.toFirestore(),
      );

      // Update rating stats
      await _updateRatingStats(ratedEntityId, ratingType, stars, batch);

      // Mark pending rating as completed if exists
      await _completePendingRating(bookingId, user.uid, ratedEntityId, batch);

      // Commit batch
      await batch.commit();

      // Send notification to the rated entity
      await _sendRatingNotification(rating);

      if (kDebugMode) {
        debugPrint(
            '✅ RatingService: Created rating for $ratingType $ratedEntityId with $stars stars');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ RatingService: Error creating rating: $e');
      }
      rethrow;
    }
  }

  /// Get ratings for a specific entity
  Stream<List<RatingModel>> getRatingsForEntity(
    String entityId,
    RatingType ratingType, {
    int limit = 20,
  }) {
    try {
      return _firestore
          .collection(_ratingsCollection)
          .where('ratedEntityId', isEqualTo: entityId)
          .where('ratingType', isEqualTo: ratingType.value)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => RatingModel.fromFirestore(doc))
            .toList();
      }).asBroadcastStream();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ RatingService: Error getting ratings for entity: $e');
      }
      throw Exception('Failed to get ratings: $e');
    }
  }

  /// Get rating statistics for an entity
  Future<RatingStats> getRatingStats(
      String entityId, RatingType ratingType) async {
    try {
      final doc = await _firestore
          .collection(_ratingStatsCollection)
          .doc(entityId)
          .get();

      if (doc.exists) {
        return RatingStats.fromFirestore(doc);
      } else {
        // Return empty stats if no ratings exist
        return RatingStats.empty(entityId, ratingType);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ RatingService: Error getting rating stats: $e');
      }
      throw Exception('Failed to get rating stats: $e');
    }
  }

  /// Get rating statistics stream for real-time updates
  Stream<RatingStats> getRatingStatsStream(
      String entityId, RatingType ratingType) {
    try {
      return _firestore
          .collection(_ratingStatsCollection)
          .doc(entityId)
          .snapshots()
          .map((doc) {
        if (doc.exists) {
          return RatingStats.fromFirestore(doc);
        } else {
          return RatingStats.empty(entityId, ratingType);
        }
      }).asBroadcastStream();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ RatingService: Error getting rating stats stream: $e');
      }
      throw Exception('Failed to get rating stats stream: $e');
    }
  }

  /// Get pending ratings for a user
  Stream<List<PendingRatingModel>> getPendingRatingsForUser(String userId) {
    try {
      return _firestore
          .collection(_pendingRatingsCollection)
          .where('userId', isEqualTo: userId)
          .where('isCompleted', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => PendingRatingModel.fromFirestore(doc))
            .toList();
      }).asBroadcastStream();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ RatingService: Error getting pending ratings: $e');
      }
      throw Exception('Failed to get pending ratings: $e');
    }
  }

  /// Create pending rating requests after booking completion
  Future<void> createPendingRatings(BookingModel booking) async {
    try {
      final batch = _firestore.batch();

      // Create pending rating for user to rate the coach/venue
      if (booking.listingType == ListingType.coach) {
        final pendingRatingId =
            '${booking.userId}_${booking.ownerId}_${booking.id}';
        final pendingRating = PendingRatingModel(
          id: pendingRatingId,
          bookingId: booking.id,
          userId: booking.userId,
          ratedEntityId: booking.ownerId,
          ratingType: RatingType.coach,
          entityName: booking.ownerName,
          bookingDate: booking.selectedDate,
          createdAt: DateTime.now(),
          isCompleted: false,
        );

        batch.set(
          _firestore.collection(_pendingRatingsCollection).doc(pendingRatingId),
          pendingRating.toFirestore(),
        );
      } else if (booking.listingType == ListingType.venue) {
        final pendingRatingId =
            '${booking.userId}_venue_${booking.listingId}_${booking.id}';
        final pendingRating = PendingRatingModel(
          id: pendingRatingId,
          bookingId: booking.id,
          userId: booking.userId,
          ratedEntityId: booking.listingId,
          ratingType: RatingType.venue,
          entityName: booking.listingTitle,
          bookingDate: booking.selectedDate,
          createdAt: DateTime.now(),
          isCompleted: false,
        );

        batch.set(
          _firestore.collection(_pendingRatingsCollection).doc(pendingRatingId),
          pendingRating.toFirestore(),
        );
      }

      // Create pending rating for coach/venue owner to rate the player
      final ownerPendingRatingId =
          '${booking.ownerId}_${booking.userId}_${booking.id}';
      final ownerPendingRating = PendingRatingModel(
        id: ownerPendingRatingId,
        bookingId: booking.id,
        userId: booking.ownerId,
        ratedEntityId: booking.userId,
        ratingType: RatingType.player,
        entityName: booking.userName,
        bookingDate: booking.selectedDate,
        createdAt: DateTime.now(),
        isCompleted: false,
      );

      batch.set(
        _firestore
            .collection(_pendingRatingsCollection)
            .doc(ownerPendingRatingId),
        ownerPendingRating.toFirestore(),
      );

      await batch.commit();

      if (kDebugMode) {
        debugPrint(
            '✅ RatingService: Created pending ratings for booking ${booking.id}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ RatingService: Error creating pending ratings: $e');
      }
      rethrow;
    }
  }

  /// Check if user has rated a specific booking
  Future<bool> hasUserRatedBooking(
      String bookingId, String userId, String entityId) async {
    try {
      final rating =
          await _getRatingByBookingAndEntity(bookingId, entityId, userId);
      return rating != null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ RatingService: Error checking if user rated booking: $e');
      }
      return false;
    }
  }

  /// Private helper methods

  Future<RatingModel?> _getRatingByBookingAndEntity(
    String bookingId,
    String entityId,
    String userId,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection(_ratingsCollection)
          .where('bookingId', isEqualTo: bookingId)
          .where('ratedEntityId', isEqualTo: entityId)
          .where('ratedBy', isEqualTo: userId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return RatingModel.fromFirestore(querySnapshot.docs.first);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            '❌ RatingService: Error getting rating by booking and entity: $e');
      }
      return null;
    }
  }

  Future<void> _updateRatingStats(
    String entityId,
    RatingType ratingType,
    int newStars,
    WriteBatch batch,
  ) async {
    try {
      final statsDoc =
          _firestore.collection(_ratingStatsCollection).doc(entityId);
      final statsSnapshot = await statsDoc.get();

      RatingStats stats;
      if (statsSnapshot.exists) {
        stats = RatingStats.fromFirestore(statsSnapshot);
      } else {
        stats = RatingStats.empty(entityId, ratingType);
      }

      final updatedStats = stats.updateWithNewRating(newStars);
      batch.set(statsDoc, updatedStats.toFirestore());
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ RatingService: Error updating rating stats: $e');
      }
      rethrow;
    }
  }

  Future<void> _completePendingRating(
    String bookingId,
    String userId,
    String entityId,
    WriteBatch batch,
  ) async {
    try {
      final pendingRatingId = '${userId}_${entityId}_$bookingId';
      final pendingDoc =
          _firestore.collection(_pendingRatingsCollection).doc(pendingRatingId);

      batch.update(pendingDoc, {'isCompleted': true});
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ RatingService: Error completing pending rating: $e');
      }
      // Don't rethrow as this is not critical
    }
  }

  /// Send notification when a rating is received
  Future<void> _sendRatingNotification(RatingModel rating) async {
    try {
      String title;
      String message;

      switch (rating.ratingType) {
        case RatingType.coach:
          title = 'New Rating Received!';
          message =
              '${rating.ratedByName} rated your coaching ${rating.stars} stars';
          break;
        case RatingType.player:
          title = 'New Rating Received!';
          message = '${rating.ratedByName} rated you ${rating.stars} stars';
          break;
        case RatingType.venue:
          title = 'New Venue Rating!';
          message =
              '${rating.ratedByName} rated your venue ${rating.stars} stars';
          break;
      }

      if (rating.feedback != null && rating.feedback!.isNotEmpty) {
        message += ': "${rating.feedback}"';
      }

      final notification = NotificationModel(
        id: 'rating_${rating.id}',
        userId: rating.ratedEntityId,
        type: NotificationType.ratingReceived,
        title: title,
        message: message,
        data: {
          'ratingId': rating.id,
          'ratingType': rating.ratingType.value,
          'stars': rating.stars,
          'ratedBy': rating.ratedBy,
          'ratedByName': rating.ratedByName,
        },
        createdAt: DateTime.now(),
      );

      await _notificationService.sendNotification(notification);

      if (kDebugMode) {
        debugPrint(
            '✅ RatingService: Sent rating notification to ${rating.ratedEntityId}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ RatingService: Failed to send rating notification: $e');
      }
      // Don't rethrow as notifications are not critical
    }
  }

  /// Send notification for pending rating requests
  Future<void> sendPendingRatingNotifications(
      List<PendingRatingModel> pendingRatings) async {
    try {
      for (final pendingRating in pendingRatings) {
        final notification = NotificationModel(
          id: 'pending_rating_${pendingRating.id}',
          userId: pendingRating.userId,
          type: NotificationType.ratingRequest,
          title: 'Rate Your Experience',
          message:
              'Please rate your experience with ${pendingRating.entityName}',
          data: {
            'pendingRatingId': pendingRating.id,
            'entityId': pendingRating.ratedEntityId,
            'entityName': pendingRating.entityName,
            'ratingType': pendingRating.ratingType.value,
            'bookingId': pendingRating.bookingId,
          },
          createdAt: DateTime.now(),
        );

        await _notificationService.sendNotification(notification);
      }

      if (kDebugMode) {
        debugPrint(
            '✅ RatingService: Sent ${pendingRatings.length} pending rating notifications');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            '⚠️ RatingService: Failed to send pending rating notifications: $e');
      }
      // Don't rethrow as notifications are not critical
    }
  }
}

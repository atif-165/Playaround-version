import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../../models/listing_model.dart';

/// Service class for managing listings (coaches and venues) in Firestore
class ListingService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  static const String _listingsCollection = 'listings';

  ListingService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  /// Create a new listing
  Future<String> createListing({
    required ListingType type,
    required String title,
    required SportType sportType,
    required String description,
    required double hourlyRate,
    required List<String> availableDays,
    required List<TimeSlot> availableTimeSlots,
    required String location,
    String? gpsCoordinates,
    List<String> photos = const [],
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final now = DateTime.now();
      final listingId = _firestore.collection(_listingsCollection).doc().id;

      final listing = ListingModel(
        id: listingId,
        ownerId: user.uid,
        ownerName: user.displayName ?? 'Unknown User',
        ownerProfilePicture: user.photoURL,
        type: type,
        title: title,
        sportType: sportType,
        description: description,
        hourlyRate: hourlyRate,
        availableDays: availableDays,
        availableTimeSlots: availableTimeSlots,
        location: location,
        gpsCoordinates: gpsCoordinates,
        photos: photos,
        createdAt: now,
        updatedAt: now,
        metadata: metadata,
      );

      await _firestore
          .collection(_listingsCollection)
          .doc(listingId)
          .set(listing.toFirestore());

      if (kDebugMode) {
        debugPrint('✅ ListingService: Created listing with ID: $listingId');
      }

      return listingId;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ ListingService: Error creating listing: $e');
      }
      throw Exception('Failed to create listing: $e');
    }
  }

  /// Get listing by ID
  Future<ListingModel?> getListing(String listingId) async {
    try {
      final doc =
          await _firestore.collection(_listingsCollection).doc(listingId).get();

      if (doc.exists) {
        return ListingModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ ListingService: Error getting listing: $e');
      }
      throw Exception('Failed to get listing: $e');
    }
  }

  /// Get all active listings
  Stream<List<ListingModel>> getActiveListings({
    SportType? sportType,
    ListingType? listingType,
    int limit = 20,
  }) {
    try {
      Query query = _firestore
          .collection(_listingsCollection)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true);

      if (sportType != null) {
        query = query.where('sportType', isEqualTo: sportType.displayName);
      }

      if (listingType != null) {
        query = query.where('type', isEqualTo: listingType.value);
      }

      query = query.limit(limit);

      return query.snapshots().map((snapshot) {
        return snapshot.docs
            .map((doc) => ListingModel.fromFirestore(doc))
            .toList();
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ ListingService: Error getting active listings: $e');
      }
      throw Exception('Failed to get active listings: $e');
    }
  }

  /// Get listings by owner
  Stream<List<ListingModel>> getListingsByOwner(String ownerId) {
    try {
      return _firestore
          .collection(_listingsCollection)
          .where('ownerId', isEqualTo: ownerId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => ListingModel.fromFirestore(doc))
            .toList();
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ ListingService: Error getting listings by owner: $e');
      }
      throw Exception('Failed to get listings by owner: $e');
    }
  }

  /// Update listing
  Future<void> updateListing({
    required String listingId,
    String? title,
    String? description,
    double? hourlyRate,
    List<String>? availableDays,
    List<TimeSlot>? availableTimeSlots,
    String? location,
    String? gpsCoordinates,
    List<String>? photos,
    bool? isActive,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final listing = await getListing(listingId);
      if (listing == null) throw Exception('Listing not found');

      if (listing.ownerId != user.uid) {
        throw Exception('Only listing owner can update the listing');
      }

      final updateData = <String, dynamic>{
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      };

      if (title != null) updateData['title'] = title;
      if (description != null) updateData['description'] = description;
      if (hourlyRate != null) updateData['hourlyRate'] = hourlyRate;
      if (availableDays != null) updateData['availableDays'] = availableDays;
      if (availableTimeSlots != null) {
        updateData['availableTimeSlots'] =
            availableTimeSlots.map((slot) => slot.toMap()).toList();
      }
      if (location != null) updateData['location'] = location;
      if (gpsCoordinates != null) updateData['gpsCoordinates'] = gpsCoordinates;
      if (photos != null) updateData['photos'] = photos;
      if (isActive != null) updateData['isActive'] = isActive;
      if (metadata != null) updateData['metadata'] = metadata;

      await _firestore
          .collection(_listingsCollection)
          .doc(listingId)
          .update(updateData);

      if (kDebugMode) {
        debugPrint('✅ ListingService: Updated listing: $listingId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ ListingService: Error updating listing: $e');
      }
      throw Exception('Failed to update listing: $e');
    }
  }

  /// Delete listing (soft delete by setting isActive to false)
  Future<void> deleteListing(String listingId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final listing = await getListing(listingId);
      if (listing == null) throw Exception('Listing not found');

      if (listing.ownerId != user.uid) {
        throw Exception('Only listing owner can delete the listing');
      }

      await _firestore.collection(_listingsCollection).doc(listingId).update({
        'isActive': false,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      if (kDebugMode) {
        debugPrint('✅ ListingService: Deleted listing: $listingId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ ListingService: Error deleting listing: $e');
      }
      throw Exception('Failed to delete listing: $e');
    }
  }

  /// Update listing rating after a booking is completed
  Future<void> updateListingRating(String listingId, double newRating) async {
    try {
      final listing = await getListing(listingId);
      if (listing == null) throw Exception('Listing not found');

      // Calculate new average rating
      final totalRatings = listing.totalBookings;
      final currentTotal = listing.averageRating * totalRatings;
      final newTotal = currentTotal + newRating;
      final newAverage = newTotal / (totalRatings + 1);

      await _firestore.collection(_listingsCollection).doc(listingId).update({
        'averageRating': newAverage,
        'totalBookings': FieldValue.increment(1),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      if (kDebugMode) {
        debugPrint('✅ ListingService: Updated rating for listing: $listingId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ ListingService: Error updating listing rating: $e');
      }
      throw Exception('Failed to update listing rating: $e');
    }
  }

  /// Search listings by title or description
  Future<List<ListingModel>> searchListings(String searchTerm) async {
    try {
      // Note: This is a basic search. For production, consider using Algolia or similar
      final titleQuery = await _firestore
          .collection(_listingsCollection)
          .where('isActive', isEqualTo: true)
          .orderBy('title')
          .startAt([searchTerm]).endAt(['$searchTerm\uf8ff']).get();

      final results = titleQuery.docs
          .map((doc) => ListingModel.fromFirestore(doc))
          .toList();

      return results;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ ListingService: Error searching listings: $e');
      }
      throw Exception('Failed to search listings: $e');
    }
  }
}

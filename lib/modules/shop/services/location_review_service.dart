import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/location_review.dart';

class LocationReviewService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String _collection = 'location_reviews';

  String get currentUserId => _auth.currentUser?.uid ?? '';

  /// Add a new review
  Future<String> addReview(LocationReview review) async {
    try {
      final docRef =
          await _firestore.collection(_collection).add(review.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to add review: $e');
    }
  }

  /// Get reviews for a specific location
  Future<List<LocationReview>> getLocationReviews(String locationId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('locationId', isEqualTo: locationId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => LocationReview.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch reviews: $e');
    }
  }

  /// Get stream of reviews for real-time updates
  Stream<List<LocationReview>> getLocationReviewsStream(String locationId) {
    return _firestore
        .collection(_collection)
        .where('locationId', isEqualTo: locationId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => LocationReview.fromFirestore(doc))
            .toList());
  }

  /// Update a review
  Future<void> updateReview(String reviewId, LocationReview review) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(reviewId)
          .update(review.toMap());
    } catch (e) {
      throw Exception('Failed to update review: $e');
    }
  }

  /// Delete a review
  Future<void> deleteReview(String reviewId) async {
    try {
      await _firestore.collection(_collection).doc(reviewId).delete();
    } catch (e) {
      throw Exception('Failed to delete review: $e');
    }
  }

  /// Check if user has already reviewed this location
  Future<bool> hasUserReviewed(String locationId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('locationId', isEqualTo: locationId)
          .where('userId', isEqualTo: currentUserId)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Get user's review for a location
  Future<LocationReview?> getUserReview(String locationId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('locationId', isEqualTo: locationId)
          .where('userId', isEqualTo: currentUserId)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return LocationReview.fromFirestore(snapshot.docs.first);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Calculate average rating for a location
  Future<double> getAverageRating(String locationId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('locationId', isEqualTo: locationId)
          .get();

      if (snapshot.docs.isEmpty) return 0.0;

      double totalRating = 0.0;
      for (var doc in snapshot.docs) {
        final data = doc.data();
        totalRating += (data['rating'] ?? 0.0).toDouble();
      }

      return totalRating / snapshot.docs.length;
    } catch (e) {
      return 0.0;
    }
  }

  /// Get review count for a location
  Future<int> getReviewCount(String locationId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('locationId', isEqualTo: locationId)
          .get();

      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }
}

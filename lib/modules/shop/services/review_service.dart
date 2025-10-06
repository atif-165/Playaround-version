import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/review.dart';

/// Service for managing reviews and ratings
class ReviewService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _reviewsCollection = 'reviews';

  /// Add review for product
  static Future<String> addProductReview({
    required String userId,
    required String userName,
    required String userImage,
    required String productId,
    required double rating,
    required String comment,
    List<String> images = const [],
  }) async {
    try {
      final review = Review(
        id: '', // Will be set by Firestore
        userId: userId,
        userName: userName,
        userImage: userImage,
        productId: productId,
        rating: rating,
        comment: comment,
        images: images,
        createdAt: DateTime.now(),
        isVerified: false, // Can be verified based on purchase history
        helpfulCount: 0,
        helpfulUsers: const [],
      );

      final docRef = await _firestore
          .collection(_reviewsCollection)
          .add(review.toMap());

      // Update product rating
      await _updateProductRating(productId);

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to add product review: $e');
    }
  }

  /// Add review for shop
  static Future<String> addShopReview({
    required String userId,
    required String userName,
    required String userImage,
    required String shopId,
    required double rating,
    required String comment,
    List<String> images = const [],
  }) async {
    try {
      final review = Review(
        id: '', // Will be set by Firestore
        userId: userId,
        userName: userName,
        userImage: userImage,
        shopId: shopId,
        rating: rating,
        comment: comment,
        images: images,
        createdAt: DateTime.now(),
        isVerified: false,
        helpfulCount: 0,
        helpfulUsers: const [],
      );

      final docRef = await _firestore
          .collection(_reviewsCollection)
          .add(review.toMap());

      // Update shop rating
      await _updateShopRating(shopId);

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to add shop review: $e');
    }
  }

  /// Get product reviews
  static Future<List<Review>> getProductReviews(String productId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_reviewsCollection)
          .where('productId', isEqualTo: productId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => Review.fromDoc(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch product reviews: $e');
    }
  }

  /// Get shop reviews
  static Future<List<Review>> getShopReviews(String shopId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_reviewsCollection)
          .where('shopId', isEqualTo: shopId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => Review.fromDoc(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch shop reviews: $e');
    }
  }

  /// Get user reviews
  static Future<List<Review>> getUserReviews(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_reviewsCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => Review.fromDoc(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch user reviews: $e');
    }
  }

  /// Get review summary for product
  static Future<ReviewSummary> getProductReviewSummary(String productId) async {
    try {
      final reviews = await getProductReviews(productId);
      return ReviewSummary.fromReviews(reviews);
    } catch (e) {
      throw Exception('Failed to get product review summary: $e');
    }
  }

  /// Get review summary for shop
  static Future<ReviewSummary> getShopReviewSummary(String shopId) async {
    try {
      final reviews = await getShopReviews(shopId);
      return ReviewSummary.fromReviews(reviews);
    } catch (e) {
      throw Exception('Failed to get shop review summary: $e');
    }
  }

  /// Mark review as helpful
  static Future<void> markReviewHelpful(String reviewId, String userId) async {
    try {
      final reviewDoc = await _firestore
          .collection(_reviewsCollection)
          .doc(reviewId)
          .get();

      if (!reviewDoc.exists) throw Exception('Review not found');

      final review = Review.fromDoc(reviewDoc);
      final helpfulUsers = List<String>.from(review.helpfulUsers);

      if (helpfulUsers.contains(userId)) {
        // Remove from helpful
        helpfulUsers.remove(userId);
      } else {
        // Add to helpful
        helpfulUsers.add(userId);
      }

      await _firestore
          .collection(_reviewsCollection)
          .doc(reviewId)
          .update({
        'helpfulCount': helpfulUsers.length,
        'helpfulUsers': helpfulUsers,
      });
    } catch (e) {
      throw Exception('Failed to mark review as helpful: $e');
    }
  }

  /// Delete review
  static Future<void> deleteReview(String reviewId) async {
    try {
      final reviewDoc = await _firestore
          .collection(_reviewsCollection)
          .doc(reviewId)
          .get();

      if (!reviewDoc.exists) throw Exception('Review not found');

      final review = Review.fromDoc(reviewDoc);

      // Delete the review
      await _firestore
          .collection(_reviewsCollection)
          .doc(reviewId)
          .delete();

      // Update ratings for product or shop
      if (review.productId != null) {
        await _updateProductRating(review.productId!);
      }
      if (review.shopId != null) {
        await _updateShopRating(review.shopId!);
      }
    } catch (e) {
      throw Exception('Failed to delete review: $e');
    }
  }

  /// Update product rating based on reviews
  static Future<void> _updateProductRating(String productId) async {
    try {
      final reviews = await getProductReviews(productId);
      
      if (reviews.isEmpty) return;

      double totalRating = 0.0;
      for (var review in reviews) {
        totalRating += review.rating;
      }

      final averageRating = totalRating / reviews.length;

      await _firestore
          .collection('products')
          .doc(productId)
          .update({
        'rating': averageRating,
        'reviewCount': reviews.length,
      });
    } catch (e) {
      throw Exception('Failed to update product rating: $e');
    }
  }

  /// Update shop rating based on reviews
  static Future<void> _updateShopRating(String shopId) async {
    try {
      final reviews = await getShopReviews(shopId);
      
      if (reviews.isEmpty) return;

      double totalRating = 0.0;
      for (var review in reviews) {
        totalRating += review.rating;
      }

      final averageRating = totalRating / reviews.length;

      await _firestore
          .collection('shops')
          .doc(shopId)
          .update({
        'rating': averageRating,
        'reviewCount': reviews.length,
      });
    } catch (e) {
      throw Exception('Failed to update shop rating: $e');
    }
  }

  /// Get recent reviews
  static Future<List<Review>> getRecentReviews({int limit = 20}) async {
    try {
      final querySnapshot = await _firestore
          .collection(_reviewsCollection)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => Review.fromDoc(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch recent reviews: $e');
    }
  }

  /// Get top-rated reviews
  static Future<List<Review>> getTopRatedReviews({int limit = 20}) async {
    try {
      final querySnapshot = await _firestore
          .collection(_reviewsCollection)
          .where('rating', isGreaterThanOrEqualTo: 4.0)
          .orderBy('rating', descending: true)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => Review.fromDoc(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch top-rated reviews: $e');
    }
  }

  /// Check if user can review product
  static Future<bool> canUserReviewProduct(String userId, String productId) async {
    try {
      // Check if user has purchased this product
      final ordersSnapshot = await _firestore
          .collection('orders')
          .where('userId', isEqualTo: userId)
          .where('items', arrayContains: {'productId': productId})
          .get();

      if (ordersSnapshot.docs.isEmpty) return false;

      // Check if user has already reviewed this product
      final reviewSnapshot = await _firestore
          .collection(_reviewsCollection)
          .where('userId', isEqualTo: userId)
          .where('productId', isEqualTo: productId)
          .get();

      return reviewSnapshot.docs.isEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Check if user can review shop
  static Future<bool> canUserReviewShop(String userId, String shopId) async {
    try {
      // Check if user has ordered from this shop
      final ordersSnapshot = await _firestore
          .collection('orders')
          .where('userId', isEqualTo: userId)
          .where('shopId', isEqualTo: shopId)
          .get();

      if (ordersSnapshot.docs.isEmpty) return false;

      // Check if user has already reviewed this shop
      final reviewSnapshot = await _firestore
          .collection(_reviewsCollection)
          .where('userId', isEqualTo: userId)
          .where('shopId', isEqualTo: shopId)
          .get();

      return reviewSnapshot.docs.isEmpty;
    } catch (e) {
      return false;
    }
  }
}

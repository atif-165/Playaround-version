import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/review.dart';
import 'order_service.dart';

/// Thin wrapper around product reviews, to keep a dedicated entrypoint for UI.
class ReviewService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> _reviewsCol(String productId) =>
      _db.collection('products').doc(productId).collection('reviews');

  Stream<List<Review>> watchReviews(String productId) {
    return _reviewsCol(productId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((s) => s.docs.map(Review.fromDoc).toList());
  }

  Future<List<Review>> getReviews(String productId) async {
    final snap = await _reviewsCol(productId).orderBy('timestamp', descending: true).get();
    return snap.docs.map(Review.fromDoc).toList();
  }

  /// Verify if user can review the product (must have purchased it)
  Future<bool> canUserReviewProduct(String productId, String userId) async {
    // Delegate to OrderService: check if current (or given) user has product in orders
    final orderService = OrderService();
    // If userId != current uid, impersonation is not allowed; still rely on current session
    if (_auth.currentUser == null || _auth.currentUser!.uid != userId) return false;
    return orderService.hasPurchasedProduct(productId);
  }

  Future<void> addReview({required String productId, required int rating, required String comment}) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw StateError('User not authenticated');
    await _reviewsCol(productId).add({
      'userId': uid,
      'rating': rating,
      'comment': comment,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}


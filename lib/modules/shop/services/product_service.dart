import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/product.dart';
import '../models/review.dart';

class ProductService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  CollectionReference<Map<String, dynamic>> get _products => _db.collection('products');

  Future<List<Product>> listProducts({String? category, String? query}) async {
    Query<Map<String, dynamic>> q = _products.orderBy('createdAt', descending: true);
    if (category != null && category.isNotEmpty) {
      q = q.where('category', isEqualTo: category);
    }
    final snap = await q.get();
    var items = snap.docs.map(Product.fromDoc).toList();
    if (query != null && query.trim().isNotEmpty) {
      final ql = query.toLowerCase();
      items = items
          .where((p) => p.title.toLowerCase().contains(ql) || p.description.toLowerCase().contains(ql))
          .toList();
    }
    return items;
  }

  Future<Product?> getProduct(String id) async {
    final doc = await _products.doc(id).get();
    if (!doc.exists) return null;
    return Product.fromDoc(doc);
  }

  Future<List<Product>> listByOwner(String ownerId) async {
    final snap = await _products.where('ownerId', isEqualTo: ownerId).orderBy('createdAt', descending: true).get();
    return snap.docs.map(Product.fromDoc).toList();
  }

  Future<String> addProduct(Product p) async {
    final data = p.toMap();
    data['createdAt'] = FieldValue.serverTimestamp();
    final doc = await _products.add(data);
    return doc.id;
  }

  Future<void> updateProduct(String id, Map<String, dynamic> data) async {
    await _products.doc(id).update(data);
  }

  Future<void> deleteProduct(String id) async {
    await _products.doc(id).delete();
  }

  // Reviews subcollection
  CollectionReference<Map<String, dynamic>> _reviews(String productId) =>
      _products.doc(productId).collection('reviews');

  Future<List<Review>> getReviews(String productId) async {
    final snap = await _reviews(productId).orderBy('timestamp', descending: true).get();
    return snap.docs.map(Review.fromDoc).toList();
  }

  Future<void> addReview(String productId, Review r) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw StateError('User not authenticated');
    }
    await _reviews(productId).add({
      'userId': uid,
      'rating': r.rating,
      'comment': r.comment,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // Additional methods for enhanced shop functionality
  Future<List<Product>> getAllProducts() async {
    final snap = await _products.get();
    return snap.docs.map(Product.fromDoc).toList();
  }

  Future<List<Product>> getFeaturedProducts() async {
    final snap = await _products.where('isFeatured', isEqualTo: true).get();
    return snap.docs.map(Product.fromDoc).toList();
  }

  Future<List<Product>> getExclusiveProducts() async {
    final snap = await _products.where('isExclusive', isEqualTo: true).get();
    return snap.docs.map(Product.fromDoc).toList();
  }

  Future<List<Product>> getProductsOnSale() async {
    final snap = await _products.where('originalPrice', isGreaterThan: 0).get();
    return snap.docs.map(Product.fromDoc).toList();
  }

  Future<List<Product>> searchProducts(String query) async {
    final snap = await _products
        .where('title', isGreaterThanOrEqualTo: query)
        .where('title', isLessThan: '${query}z')
        .get();
    return snap.docs.map(Product.fromDoc).toList();
  }

  Future<List<Product>> getRelatedProducts(String productId) async {
    // Get the current product to find related products by category
    final product = await getProduct(productId);
    if (product == null) return [];
    
    final snap = await _products
        .where('category', isEqualTo: product.category)
        .where('id', isNotEqualTo: productId)
        .limit(4)
        .get();
    return snap.docs.map(Product.fromDoc).toList();
  }
}


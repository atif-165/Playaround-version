import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/shop.dart';
import '../models/product.dart';

/// Service for managing partner shops and vendors
class ShopService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _shopsCollection = 'shops';
  static const String _productsCollection = 'products';

  /// Get all active shops
  static Future<List<Shop>> getAllShops() async {
    try {
      final querySnapshot = await _firestore
          .collection(_shopsCollection)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => Shop.fromDoc(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch shops: $e');
    }
  }

  /// Get shops by category
  static Future<List<Shop>> getShopsByCategory(String category) async {
    try {
      final querySnapshot = await _firestore
          .collection(_shopsCollection)
          .where('isActive', isEqualTo: true)
          .where('categories', arrayContains: category)
          .orderBy('rating', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => Shop.fromDoc(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch shops by category: $e');
    }
  }

  /// Get local shops by city
  static Future<List<Shop>> getLocalShops(String city) async {
    try {
      final querySnapshot = await _firestore
          .collection(_shopsCollection)
          .where('isActive', isEqualTo: true)
          .where('isLocal', isEqualTo: true)
          .where('city', isEqualTo: city)
          .orderBy('rating', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => Shop.fromDoc(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch local shops: $e');
    }
  }

  /// Get online shops
  static Future<List<Shop>> getOnlineShops() async {
    try {
      final querySnapshot = await _firestore
          .collection(_shopsCollection)
          .where('isActive', isEqualTo: true)
          .where('isOnline', isEqualTo: true)
          .orderBy('rating', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => Shop.fromDoc(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch online shops: $e');
    }
  }

  /// Get shop by ID
  static Future<Shop?> getShopById(String shopId) async {
    try {
      final doc = await _firestore
          .collection(_shopsCollection)
          .doc(shopId)
          .get();

      if (doc.exists) {
        return Shop.fromDoc(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch shop: $e');
    }
  }

  /// Get products by shop
  static Future<List<Product>> getProductsByShop(String shopId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_productsCollection)
          .where('shopId', isEqualTo: shopId)
          .where('isAvailable', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => Product.fromDoc(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch shop products: $e');
    }
  }

  /// Get featured products from all shops
  static Future<List<Product>> getFeaturedProducts() async {
    try {
      final querySnapshot = await _firestore
          .collection(_productsCollection)
          .where('isFeatured', isEqualTo: true)
          .where('isAvailable', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(20)
          .get();

      return querySnapshot.docs
          .map((doc) => Product.fromDoc(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch featured products: $e');
    }
  }

  /// Get exclusive products
  static Future<List<Product>> getExclusiveProducts() async {
    try {
      final querySnapshot = await _firestore
          .collection(_productsCollection)
          .where('isExclusive', isEqualTo: true)
          .where('isAvailable', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(20)
          .get();

      return querySnapshot.docs
          .map((doc) => Product.fromDoc(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch exclusive products: $e');
    }
  }

  /// Search shops by name or description
  static Future<List<Shop>> searchShops(String query) async {
    try {
      final querySnapshot = await _firestore
          .collection(_shopsCollection)
          .where('isActive', isEqualTo: true)
          .get();

      return querySnapshot.docs
          .map((doc) => Shop.fromDoc(doc))
          .where((shop) =>
              shop.name.toLowerCase().contains(query.toLowerCase()) ||
              shop.description.toLowerCase().contains(query.toLowerCase()) ||
              shop.categories.any((category) =>
                  category.toLowerCase().contains(query.toLowerCase())))
          .toList();
    } catch (e) {
      throw Exception('Failed to search shops: $e');
    }
  }

  /// Get top-rated shops
  static Future<List<Shop>> getTopRatedShops({int limit = 10}) async {
    try {
      final querySnapshot = await _firestore
          .collection(_shopsCollection)
          .where('isActive', isEqualTo: true)
          .where('rating', isGreaterThan: 4.0)
          .orderBy('rating', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => Shop.fromDoc(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch top-rated shops: $e');
    }
  }

  /// Get verified shops
  static Future<List<Shop>> getVerifiedShops() async {
    try {
      final querySnapshot = await _firestore
          .collection(_shopsCollection)
          .where('isActive', isEqualTo: true)
          .where('isVerified', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => Shop.fromDoc(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch verified shops: $e');
    }
  }

  /// Create a new shop (for admin/vendor registration)
  static Future<String> createShop(Shop shop) async {
    try {
      final docRef = await _firestore
          .collection(_shopsCollection)
          .add(shop.toMap());

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create shop: $e');
    }
  }

  /// Update shop information
  static Future<void> updateShop(String shopId, Map<String, dynamic> updates) async {
    try {
      await _firestore
          .collection(_shopsCollection)
          .doc(shopId)
          .update(updates);
    } catch (e) {
      throw Exception('Failed to update shop: $e');
    }
  }

  /// Update shop rating (called when reviews are added)
  static Future<void> updateShopRating(String shopId) async {
    try {
      // Get all reviews for this shop
      final reviewsSnapshot = await _firestore
          .collection('reviews')
          .where('shopId', isEqualTo: shopId)
          .get();

      if (reviewsSnapshot.docs.isEmpty) return;

      double totalRating = 0.0;
      int reviewCount = 0;

      for (var doc in reviewsSnapshot.docs) {
        final data = doc.data();
        totalRating += (data['rating'] ?? 0.0) as double;
        reviewCount++;
      }

      final averageRating = totalRating / reviewCount;

      await _firestore
          .collection(_shopsCollection)
          .doc(shopId)
          .update({
        'rating': averageRating,
        'reviewCount': reviewCount,
      });
    } catch (e) {
      throw Exception('Failed to update shop rating: $e');
    }
  }

  /// Get shop statistics
  static Future<Map<String, dynamic>> getShopStats(String shopId) async {
    try {
      final shop = await getShopById(shopId);
      if (shop == null) throw Exception('Shop not found');

      final productsSnapshot = await _firestore
          .collection(_productsCollection)
          .where('shopId', isEqualTo: shopId)
          .get();

      final ordersSnapshot = await _firestore
          .collection('orders')
          .where('shopId', isEqualTo: shopId)
          .get();

      return {
        'shop': shop,
        'totalProducts': productsSnapshot.docs.length,
        'totalOrders': ordersSnapshot.docs.length,
        'totalRevenue': ordersSnapshot.docs.fold(0.0, (total, doc) {
          final data = doc.data();
          return total + (data['totalAmount'] ?? 0.0);
        }),
      };
    } catch (e) {
      throw Exception('Failed to fetch shop stats: $e');
    }
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/order.dart';

class OrderService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _orders => _db.collection('orders');

  String get _uid => _auth.currentUser?.uid ?? (throw StateError('User not authenticated'));

  Future<String> placeOrder(List<OrderItem> items, double totalAmount) async {
    // Create order and mirror purchases for review gating
    final userId = _uid;
    final batch = _db.batch();
    final orderRef = _orders.doc();
    batch.set(orderRef, {
      'userId': userId,
      'items': items.map((e) => e.toMap()).toList(),
      'totalAmount': totalAmount,
      'orderDate': FieldValue.serverTimestamp(),
    });

    // Mirror each product into users/{uid}/purchases/{productId}
    for (final it in items) {
      final purRef = _db.collection('users').doc(userId).collection('purchases').doc(it.productId);
      batch.set(purRef, {
        'productId': it.productId,
        'count': FieldValue.increment(it.quantity),
        'lastPurchasedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    await batch.commit();
    return orderRef.id;
  }

  Future<List<OrderModel>> myOrders() async {
    final snap = await _orders.where('userId', isEqualTo: _uid).orderBy('orderDate', descending: true).get();
    return snap.docs.map(OrderModel.fromDoc).toList();
  }

  /// Check if current user has purchased a specific product
  Future<bool> hasPurchasedProduct(String productId) async {
    // Query all orders for current user and scan items for the product
    final snap = await _orders
        .where('userId', isEqualTo: _uid)
        .get();
    for (final doc in snap.docs) {
      final data = doc.data();
      final items = (data['items'] as List<dynamic>? ?? [])
          .map((e) => OrderItem.fromMap(e as Map<String, dynamic>))
          .toList();
      for (final item in items) {
        if (item.productId == productId && item.quantity > 0) {
          return true;
        }
      }
    }
    return false;
  }
}


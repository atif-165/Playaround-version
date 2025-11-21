import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/order.dart' as order_model;
import '../models/order_item.dart';

class OrderService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _orders =>
      _db.collection('orders');

  String get _uid =>
      _auth.currentUser?.uid ?? (throw StateError('User not authenticated'));

  Future<String> placeOrder(List<OrderItem> items, double totalAmount) async {
    final userId = _uid;
    if (items.isEmpty) {
      throw StateError('No items in cart');
    }

    final orderRef = _orders.doc();
    final productsCollection = _db.collection('products');
    final userPurchases =
        _db.collection('users').doc(userId).collection('purchases');

    await _db.runTransaction((transaction) async {
      for (final item in items) {
        final productRef = productsCollection.doc(item.productId);
        final productSnap = await transaction.get(productRef);
        if (!productSnap.exists) {
          throw StateError('Product ${item.productName} no longer exists');
        }

        final data = productSnap.data() ?? {};
        final currentStock = (data['stock'] ?? 0) as int;
        if (currentStock < item.quantity) {
          throw StateError('Insufficient stock for ${item.productName}');
        }

        final newStock = currentStock - item.quantity;
        transaction.update(productRef, {
          'stock': newStock,
          'isAvailable': newStock > 0,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        transaction.set(
          userPurchases.doc(item.productId),
          {
            'productId': item.productId,
            'count': FieldValue.increment(item.quantity),
            'lastPurchasedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }

      transaction.set(orderRef, {
        'userId': userId,
        'items': items.map((e) => e.toMap()).toList(),
        'totalAmount': totalAmount,
        'subtotal': totalAmount,
        'tax': 0.0,
        'shipping': 0.0,
        'discount': 0.0,
        'status': order_model.OrderStatus.processing.name,
        'paymentStatus': order_model.PaymentStatus.paid.name,
        'deliveryType': order_model.DeliveryType.home.name,
        'shippingAddress': const {},
        'paymentMethod': const {'type': 'mock'},
        'orderDate': FieldValue.serverTimestamp(),
        'metadata': {
          'source': 'emulator_checkout',
        },
        'shopId': 'multi',
        'shopName': 'PlayAround Shop',
      });
    });

    return orderRef.id;
  }

  Future<List<order_model.Order>> myOrders() async {
    final snap = await _orders
        .where('userId', isEqualTo: _uid)
        .orderBy('orderDate', descending: true)
        .get();
    return snap.docs.map(order_model.Order.fromDoc).toList();
  }

  Stream<List<order_model.Order>> allOrdersStream() {
    return _orders.orderBy('orderDate', descending: true).snapshots().map(
          (snapshot) => snapshot.docs.map(order_model.Order.fromDoc).toList(),
        );
  }

  Future<void> updateOrderStatus(
      String orderId, order_model.OrderStatus status) async {
    await _orders.doc(orderId).update({
      'status': status.name,
      'metadata.lastStatusUpdate': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updatePaymentStatus(
      String orderId, order_model.PaymentStatus status) async {
    await _orders.doc(orderId).update({
      'paymentStatus': status.name,
      'metadata.lastPaymentUpdate': FieldValue.serverTimestamp(),
    });
  }

  /// Check if current user has purchased a specific product
  Future<bool> hasPurchasedProduct(String productId) async {
    // Query all orders for current user and scan items for the product
    final snap = await _orders.where('userId', isEqualTo: _uid).get();
    for (final doc in snap.docs) {
      final data = doc.data();
      final items = (data['items'] as List<dynamic>? ?? [])
          .map((e) => OrderItem.fromDoc(e as Map<String, dynamic>))
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

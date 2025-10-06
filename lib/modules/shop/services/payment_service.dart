import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order.dart' as order_model;
import '../models/cart.dart';

/// Service for handling payments and orders
class PaymentService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _ordersCollection = 'orders';
  static const String _paymentsCollection = 'payments';

  /// Create order from cart
  static Future<String> createOrder({
    required String userId,
    required List<CartItem> cartItems,
    required order_model.ShippingAddress shippingAddress,
    required order_model.PaymentMethod paymentMethod,
    required order_model.DeliveryType deliveryType,
    String? notes,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // Group items by shop
      final itemsByShop = <String, List<CartItem>>{};
      for (var item in cartItems) {
        if (!itemsByShop.containsKey(item.shopId)) {
          itemsByShop[item.shopId] = [];
        }
        itemsByShop[item.shopId]!.add(item);
      }

      // Create separate orders for each shop
      final orderIds = <String>[];
      
      for (var entry in itemsByShop.entries) {
        final shopId = entry.key;
        final shopItems = entry.value;
        
        // Get shop name
        final shopDoc = await _firestore
            .collection('shops')
            .doc(shopId)
            .get();
        final shopName = shopDoc.data()?['name'] ?? 'Unknown Shop';

        // Calculate totals
        final subtotal = shopItems.fold(0.0, (total, item) => total + item.totalPrice);
        final tax = subtotal * 0.18; // 18% GST
        final shipping = deliveryType == order_model.DeliveryType.home ? 50.0 : 0.0;
        final discount = 0.0; // Can be calculated based on promotions
        final totalAmount = subtotal + tax + shipping - discount;

        // Create order items
        final orderItems = shopItems.map((item) => order_model.OrderItem(
          productId: item.productId,
          productName: item.productName,
          productImage: item.productImage,
          price: item.price,
          quantity: item.quantity,
          size: item.size,
          color: item.color,
        )).toList();

        // Create order
        final order = order_model.Order(
          id: '', // Will be set by Firestore
          userId: userId,
          shopId: shopId,
          shopName: shopName,
          items: orderItems,
          subtotal: subtotal,
          tax: tax,
          shipping: shipping,
          discount: discount,
          totalAmount: totalAmount,
          status: order_model.OrderStatus.pending,
          paymentStatus: order_model.PaymentStatus.pending,
          deliveryType: deliveryType,
          shippingAddress: shippingAddress,
          paymentMethod: paymentMethod,
          orderDate: DateTime.now(),
          notes: notes,
          metadata: metadata ?? {},
        );

        // Save order to Firestore
        final docRef = await _firestore
            .collection(_ordersCollection)
            .add(order.toMap());
        
        orderIds.add(docRef.id);
      }

      return orderIds.join(','); // Return comma-separated order IDs
    } catch (e) {
      throw Exception('Failed to create order: $e');
    }
  }

  /// Process payment
  static Future<Map<String, dynamic>> processPayment({
    required String orderId,
    required double amount,
    required order_model.PaymentMethod paymentMethod,
    Map<String, dynamic>? paymentData,
  }) async {
    try {
      // In a real implementation, this would integrate with payment gateways
      // like Razorpay, Stripe, etc.
      
      // For now, simulate payment processing
      await Future.delayed(const Duration(seconds: 2));

      // Simulate payment success (90% success rate)
      final isSuccess = DateTime.now().millisecond % 10 != 0;

      if (isSuccess) {
        // Update order status
        await _firestore
            .collection(_ordersCollection)
            .doc(orderId)
            .update({
          'status': order_model.OrderStatus.confirmed.name,
          'paymentStatus': order_model.PaymentStatus.paid.name,
          'metadata.paymentId': 'PAY_${DateTime.now().millisecondsSinceEpoch}',
          'metadata.paymentMethod': paymentMethod.type,
          'metadata.paymentData': paymentData ?? {},
        });

        // Create payment record
        await _firestore
            .collection(_paymentsCollection)
            .add({
          'orderId': orderId,
          'amount': amount,
          'paymentMethod': paymentMethod.toMap(),
          'status': 'success',
          'transactionId': 'TXN_${DateTime.now().millisecondsSinceEpoch}',
          'createdAt': Timestamp.fromDate(DateTime.now()),
          'paymentData': paymentData ?? {},
        });

        return {
          'success': true,
          'transactionId': 'TXN_${DateTime.now().millisecondsSinceEpoch}',
          'message': 'Payment successful',
        };
      } else {
        // Update order status for failed payment
        await _firestore
            .collection(_ordersCollection)
            .doc(orderId)
            .update({
          'paymentStatus': order_model.PaymentStatus.failed.name,
          'metadata.paymentError': 'Payment failed',
        });

        return {
          'success': false,
          'message': 'Payment failed. Please try again.',
        };
      }
    } catch (e) {
      throw Exception('Failed to process payment: $e');
    }
  }

  /// Get user orders
  static Future<List<order_model.Order>> getUserOrders(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_ordersCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('orderDate', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => order_model.Order.fromDoc(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch user orders: $e');
    }
  }

  /// Get order by ID
  static Future<order_model.Order?> getOrderById(String orderId) async {
    try {
      final doc = await _firestore
          .collection(_ordersCollection)
          .doc(orderId)
          .get();

      if (doc.exists) {
        return order_model.Order.fromDoc(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch order: $e');
    }
  }

  /// Update order status
  static Future<void> updateOrderStatus({
    required String orderId,
    required order_model.OrderStatus status,
    String? trackingNumber,
    String? notes,
  }) async {
    try {
      final updates = <String, dynamic>{
        'status': status.name,
      };

      if (trackingNumber != null) {
        updates['trackingNumber'] = trackingNumber;
      }

      if (notes != null) {
        updates['notes'] = notes;
      }

      if (status == order_model.OrderStatus.shipped) {
        updates['deliveryDate'] = Timestamp.fromDate(
          DateTime.now().add(const Duration(days: 3)),
        );
      }

      await _firestore
          .collection(_ordersCollection)
          .doc(orderId)
          .update(updates);
    } catch (e) {
      throw Exception('Failed to update order status: $e');
    }
  }

  /// Cancel order
  static Future<void> cancelOrder(String orderId) async {
    try {
      await _firestore
          .collection(_ordersCollection)
          .doc(orderId)
          .update({
        'status': order_model.OrderStatus.cancelled.name,
        'metadata.cancelledAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Failed to cancel order: $e');
    }
  }

  /// Get order statistics
  static Future<Map<String, dynamic>> getOrderStats(String userId) async {
    try {
      final ordersSnapshot = await _firestore
          .collection(_ordersCollection)
          .where('userId', isEqualTo: userId)
          .get();

      final orders = ordersSnapshot.docs
          .map((doc) => order_model.Order.fromDoc(doc))
          .toList();

      final totalOrders = orders.length;
      final totalSpent = orders.fold(0.0, (total, order) => total + order.totalAmount);
      final pendingOrders = orders.where((order) => 
          order.status == order_model.OrderStatus.pending || 
          order.status == order_model.OrderStatus.confirmed ||
          order.status == order_model.OrderStatus.processing).length;
      final deliveredOrders = orders.where((order) => 
          order.status == order_model.OrderStatus.delivered).length;

      return {
        'totalOrders': totalOrders,
        'totalSpent': totalSpent,
        'pendingOrders': pendingOrders,
        'deliveredOrders': deliveredOrders,
        'averageOrderValue': totalOrders > 0 ? totalSpent / totalOrders : 0.0,
      };
    } catch (e) {
      throw Exception('Failed to get order stats: $e');
    }
  }

  /// Get payment methods
  static List<Map<String, dynamic>> getAvailablePaymentMethods() {
    return [
      {
        'type': 'card',
        'name': 'Credit/Debit Card',
        'icon': '💳',
        'enabled': true,
      },
      {
        'type': 'upi',
        'name': 'UPI',
        'icon': '📱',
        'enabled': true,
      },
      {
        'type': 'wallet',
        'name': 'Digital Wallet',
        'icon': '💰',
        'enabled': true,
      },
      {
        'type': 'netbanking',
        'name': 'Net Banking',
        'icon': '🏦',
        'enabled': true,
      },
      {
        'type': 'cod',
        'name': 'Cash on Delivery',
        'icon': '💵',
        'enabled': true,
      },
    ];
  }
}
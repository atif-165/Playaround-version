import 'package:cloud_firestore/cloud_firestore.dart';

class OrderItem {
  final String productId;
  final int quantity;
  final double priceAtPurchase;

  OrderItem({
    required this.productId,
    required this.quantity,
    required this.priceAtPurchase,
  });

  Map<String, dynamic> toMap() => {
        'productId': productId,
        'quantity': quantity,
        'priceAtPurchase': priceAtPurchase,
      };

  factory OrderItem.fromMap(Map<String, dynamic> data) => OrderItem(
        productId: (data['productId'] ?? '') as String,
        quantity: (data['quantity'] ?? 1) as int,
        priceAtPurchase: (data['priceAtPurchase'] is int)
            ? (data['priceAtPurchase'] as int).toDouble()
            : (data['priceAtPurchase'] ?? 0.0) as double,
      );
}

class OrderModel {
  final String id;
  final String userId;
  final List<OrderItem> items;
  final double totalAmount;
  final DateTime orderDate;

  OrderModel({
    required this.id,
    required this.userId,
    required this.items,
    required this.totalAmount,
    required this.orderDate,
  });

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'items': items.map((e) => e.toMap()).toList(),
        'totalAmount': totalAmount,
        'orderDate': Timestamp.fromDate(orderDate),
      };

  factory OrderModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final items = (data['items'] as List?)?.map((e) => OrderItem.fromMap((e as Map).cast<String, dynamic>())).toList() ?? [];
    final total = (data['totalAmount'] is int)
        ? (data['totalAmount'] as int).toDouble()
        : (data['totalAmount'] ?? 0.0) as double;
    return OrderModel(
      id: doc.id,
      userId: (data['userId'] ?? '') as String,
      items: items,
      totalAmount: total,
      orderDate: (data['orderDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}


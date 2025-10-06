import 'package:cloud_firestore/cloud_firestore.dart';

/// Cart item model
class CartItem {
  final String id;
  final String productId;
  final String shopId;
  final String productName;
  final String productImage;
  final double price;
  final int quantity;
  final String size;
  final String color;
  final bool isAvailable;
  final DateTime addedAt;

  CartItem({
    required this.id,
    required this.productId,
    required this.shopId,
    required this.productName,
    required this.productImage,
    required this.price,
    required this.quantity,
    required this.size,
    required this.color,
    required this.isAvailable,
    required this.addedAt,
  });

  factory CartItem.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return CartItem(
      id: doc.id,
      productId: (data['productId'] ?? '') as String,
      shopId: (data['shopId'] ?? '') as String,
      productName: (data['productName'] ?? '') as String,
      productImage: (data['productImage'] ?? '') as String,
      price: (data['price'] is int)
          ? (data['price'] as int).toDouble()
          : (data['price'] ?? 0.0) as double,
      quantity: (data['quantity'] ?? 1) as int,
      size: (data['size'] ?? '') as String,
      color: (data['color'] ?? '') as String,
      isAvailable: (data['isAvailable'] ?? true) as bool,
      addedAt: (data['addedAt'] is Timestamp)
          ? (data['addedAt'] as Timestamp).toDate()
          : DateTime.tryParse(data['addedAt']?.toString() ?? '') ??
              DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  factory CartItem.fromMap(Map<String, dynamic> data) {
    return CartItem(
      id: (data['id'] ?? '') as String,
      productId: (data['productId'] ?? '') as String,
      shopId: (data['shopId'] ?? '') as String,
      productName: (data['productName'] ?? '') as String,
      productImage: (data['productImage'] ?? '') as String,
      price: (data['price'] is int)
          ? (data['price'] as int).toDouble()
          : (data['price'] ?? 0.0) as double,
      quantity: (data['quantity'] ?? 1) as int,
      size: (data['size'] ?? '') as String,
      color: (data['color'] ?? '') as String,
      isAvailable: (data['isAvailable'] ?? true) as bool,
      addedAt: (data['addedAt'] is Timestamp)
          ? (data['addedAt'] as Timestamp).toDate()
          : DateTime.tryParse(data['addedAt']?.toString() ?? '') ??
              DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  Map<String, dynamic> toMap() => {
        'productId': productId,
        'shopId': shopId,
        'productName': productName,
        'productImage': productImage,
        'price': price,
        'quantity': quantity,
        'size': size,
        'color': color,
        'isAvailable': isAvailable,
        'addedAt': Timestamp.fromDate(addedAt),
      };

  CartItem copyWith({
    int? quantity,
    String? size,
    String? color,
    bool? isAvailable,
  }) {
    return CartItem(
      id: id,
      productId: productId,
      shopId: shopId,
      productName: productName,
      productImage: productImage,
      price: price,
      quantity: quantity ?? this.quantity,
      size: size ?? this.size,
      color: color ?? this.color,
      isAvailable: isAvailable ?? this.isAvailable,
      addedAt: addedAt,
    );
  }

  double get totalPrice => price * quantity;
}

/// Shopping cart model
class ShoppingCart {
  final String userId;
  final List<CartItem> items;
  final DateTime lastUpdated;

  ShoppingCart({
    required this.userId,
    required this.items,
    required this.lastUpdated,
  });

  factory ShoppingCart.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final itemsData = data['items'] as List? ?? [];
    
    return ShoppingCart(
      userId: (data['userId'] ?? '') as String,
      items: itemsData.map((item) => CartItem.fromMap(item as Map<String, dynamic>)).toList(),
      lastUpdated: (data['lastUpdated'] is Timestamp)
          ? (data['lastUpdated'] as Timestamp).toDate()
          : DateTime.tryParse(data['lastUpdated']?.toString() ?? '') ??
              DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'items': items.map((item) => item.toMap()).toList(),
        'lastUpdated': Timestamp.fromDate(lastUpdated),
      };

  double get totalAmount => items.fold(0.0, (total, item) => total + item.totalPrice);
  
  int get totalItems => items.fold(0, (total, item) => total + item.quantity);
  
  List<String> get shopIds => items.map((item) => item.shopId).toSet().toList();
  
  Map<String, List<CartItem>> get itemsByShop {
    Map<String, List<CartItem>> grouped = {};
    for (var item in items) {
      if (!grouped.containsKey(item.shopId)) {
        grouped[item.shopId] = [];
      }
      grouped[item.shopId]!.add(item);
    }
    return grouped;
  }
}

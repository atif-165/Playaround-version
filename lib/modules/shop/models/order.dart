import 'package:cloud_firestore/cloud_firestore.dart';

/// Order status enum
enum OrderStatus {
  pending,
  confirmed,
  processing,
  shipped,
  delivered,
  cancelled,
  returned,
  refunded,
}

/// Payment status enum
enum PaymentStatus {
  pending,
  paid,
  failed,
  refunded,
  partiallyRefunded,
}

/// Delivery type enum
enum DeliveryType {
  home,
  pickup,
  store,
}

/// Order model
class Order {
  final String id;
  final String userId;
  final String shopId;
  final String shopName;
  final List<OrderItem> items;
  final double subtotal;
  final double tax;
  final double shipping;
  final double discount;
  final double totalAmount;
  final OrderStatus status;
  final PaymentStatus paymentStatus;
  final DeliveryType deliveryType;
  final ShippingAddress shippingAddress;
  final PaymentMethod paymentMethod;
  final DateTime orderDate;
  final DateTime? deliveryDate;
  final String? trackingNumber;
  final String? notes;
  final Map<String, dynamic> metadata;

  Order({
    required this.id,
    required this.userId,
    required this.shopId,
    required this.shopName,
    required this.items,
    required this.subtotal,
    required this.tax,
    required this.shipping,
    required this.discount,
    required this.totalAmount,
    required this.status,
    required this.paymentStatus,
    required this.deliveryType,
    required this.shippingAddress,
    required this.paymentMethod,
    required this.orderDate,
    this.deliveryDate,
    this.trackingNumber,
    this.notes,
    required this.metadata,
  });

  factory Order.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Order(
      id: doc.id,
      userId: (data['userId'] ?? '') as String,
      shopId: (data['shopId'] ?? '') as String,
      shopName: (data['shopName'] ?? '') as String,
      items: (data['items'] as List?)
              ?.map((item) => OrderItem.fromMap(item))
              .toList() ??
          [],
      subtotal: (data['subtotal'] ?? 0.0) as double,
      tax: (data['tax'] ?? 0.0) as double,
      shipping: (data['shipping'] ?? 0.0) as double,
      discount: (data['discount'] ?? 0.0) as double,
      totalAmount: (data['totalAmount'] ?? 0.0) as double,
      status: OrderStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => OrderStatus.pending,
      ),
      paymentStatus: PaymentStatus.values.firstWhere(
        (e) => e.name == data['paymentStatus'],
        orElse: () => PaymentStatus.pending,
      ),
      deliveryType: DeliveryType.values.firstWhere(
        (e) => e.name == data['deliveryType'],
        orElse: () => DeliveryType.home,
      ),
      shippingAddress: ShippingAddress.fromMap(data['shippingAddress'] ?? {}),
      paymentMethod: PaymentMethod.fromMap(data['paymentMethod'] ?? {}),
      orderDate: (data['orderDate'] is Timestamp)
          ? (data['orderDate'] as Timestamp).toDate()
          : DateTime.tryParse(data['orderDate']?.toString() ?? '') ??
              DateTime.fromMillisecondsSinceEpoch(0),
      deliveryDate: data['deliveryDate'] != null
          ? (data['deliveryDate'] is Timestamp)
              ? (data['deliveryDate'] as Timestamp).toDate()
              : DateTime.tryParse(data['deliveryDate']?.toString() ?? '')
          : null,
      trackingNumber: data['trackingNumber'] as String?,
      notes: data['notes'] as String?,
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'shopId': shopId,
        'shopName': shopName,
        'items': items.map((item) => item.toMap()).toList(),
        'subtotal': subtotal,
        'tax': tax,
        'shipping': shipping,
        'discount': discount,
        'totalAmount': totalAmount,
        'status': status.name,
        'paymentStatus': paymentStatus.name,
        'deliveryType': deliveryType.name,
        'shippingAddress': shippingAddress.toMap(),
        'paymentMethod': paymentMethod.toMap(),
        'orderDate': Timestamp.fromDate(orderDate),
        'deliveryDate':
            deliveryDate != null ? Timestamp.fromDate(deliveryDate!) : null,
        'trackingNumber': trackingNumber,
        'notes': notes,
        'metadata': metadata,
      };

  Order copyWith({
    OrderStatus? status,
    PaymentStatus? paymentStatus,
    DateTime? deliveryDate,
    String? trackingNumber,
    String? notes,
  }) {
    return Order(
      id: id,
      userId: userId,
      shopId: shopId,
      shopName: shopName,
      items: items,
      subtotal: subtotal,
      tax: tax,
      shipping: shipping,
      discount: discount,
      totalAmount: totalAmount,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      deliveryType: deliveryType,
      shippingAddress: shippingAddress,
      paymentMethod: paymentMethod,
      orderDate: orderDate,
      deliveryDate: deliveryDate ?? this.deliveryDate,
      trackingNumber: trackingNumber ?? this.trackingNumber,
      notes: notes ?? this.notes,
      metadata: metadata,
    );
  }
}

/// Order item model
class OrderItem {
  final String productId;
  final String productName;
  final String productImage;
  final double price;
  final int quantity;
  final String size;
  final String color;

  OrderItem({
    required this.productId,
    required this.productName,
    required this.productImage,
    required this.price,
    required this.quantity,
    required this.size,
    required this.color,
  });

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      productId: (map['productId'] ?? '') as String,
      productName: (map['productName'] ?? '') as String,
      productImage: (map['productImage'] ?? '') as String,
      price: (map['price'] ?? 0.0) as double,
      quantity: (map['quantity'] ?? 1) as int,
      size: (map['size'] ?? '') as String,
      color: (map['color'] ?? '') as String,
    );
  }

  Map<String, dynamic> toMap() => {
        'productId': productId,
        'productName': productName,
        'productImage': productImage,
        'price': price,
        'quantity': quantity,
        'size': size,
        'color': color,
      };

  double get totalPrice => price * quantity;
}

/// Shipping address model
class ShippingAddress {
  final String fullName;
  final String address;
  final String city;
  final String state;
  final String pincode;
  final String country;
  final String phoneNumber;
  final String? landmark;

  ShippingAddress({
    required this.fullName,
    required this.address,
    required this.city,
    required this.state,
    required this.pincode,
    required this.country,
    required this.phoneNumber,
    this.landmark,
  });

  factory ShippingAddress.fromMap(Map<String, dynamic> map) {
    return ShippingAddress(
      fullName: (map['fullName'] ?? '') as String,
      address: (map['address'] ?? '') as String,
      city: (map['city'] ?? '') as String,
      state: (map['state'] ?? '') as String,
      pincode: (map['pincode'] ?? '') as String,
      country: (map['country'] ?? '') as String,
      phoneNumber: (map['phoneNumber'] ?? '') as String,
      landmark: map['landmark'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'fullName': fullName,
        'address': address,
        'city': city,
        'state': state,
        'pincode': pincode,
        'country': country,
        'phoneNumber': phoneNumber,
        'landmark': landmark,
      };
}

/// Payment method model
class PaymentMethod {
  final String type; // 'card', 'upi', 'wallet', 'netbanking', 'cod'
  final String? cardLast4;
  final String? upiId;
  final String? walletName;
  final String? bankName;

  PaymentMethod({
    required this.type,
    this.cardLast4,
    this.upiId,
    this.walletName,
    this.bankName,
  });

  factory PaymentMethod.fromMap(Map<String, dynamic> map) {
    return PaymentMethod(
      type: (map['type'] ?? '') as String,
      cardLast4: map['cardLast4'] as String?,
      upiId: map['upiId'] as String?,
      walletName: map['walletName'] as String?,
      bankName: map['bankName'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'type': type,
        'cardLast4': cardLast4,
        'upiId': upiId,
        'walletName': walletName,
        'bankName': bankName,
      };
}

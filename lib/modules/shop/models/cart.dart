class CartItem {
  final String id; // cartItemId
  final String productId;
  final int quantity;

  CartItem({
    required this.id,
    required this.productId,
    required this.quantity,
  });

  Map<String, dynamic> toMap() => {
        'productId': productId,
        'quantity': quantity,
      };

  factory CartItem.fromMap(String id, Map<String, dynamic> data) => CartItem(
        id: id,
        productId: (data['productId'] ?? '') as String,
        quantity: (data['quantity'] ?? 1) as int,
      );
}


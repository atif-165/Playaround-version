import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/cart.dart';
import '../models/product.dart';

/// Service for managing shopping cart
class CartService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _cartCollection = 'carts';

  /// Get user's cart
  static Future<ShoppingCart?> getCart(String userId) async {
    try {
      final doc = await _firestore
          .collection(_cartCollection)
          .doc(userId)
          .get();

      if (doc.exists) {
        return ShoppingCart.fromDoc(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch cart: $e');
    }
  }

  /// Add item to cart
  static Future<void> addToCart({
    required String userId,
    required Product product,
    required int quantity,
    String size = '',
    String color = '',
  }) async {
    try {
      final cart = await getCart(userId);
      final cartItems = cart?.items ?? [];

      // Check if item already exists in cart
      final existingItemIndex = cartItems.indexWhere(
        (item) => item.productId == product.id && 
                  item.size == size && 
                  item.color == color,
      );

      if (existingItemIndex != -1) {
        // Update quantity of existing item
        cartItems[existingItemIndex] = cartItems[existingItemIndex].copyWith(
          quantity: cartItems[existingItemIndex].quantity + quantity,
        );
      } else {
        // Add new item to cart
        final cartItem = CartItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          productId: product.id,
          shopId: product.shopId,
          productName: product.title,
          productImage: product.images.isNotEmpty ? product.images.first : '',
          price: product.price,
          quantity: quantity,
          size: size,
          color: color,
          isAvailable: product.isAvailable && product.stock > 0,
          addedAt: DateTime.now(),
        );
        cartItems.add(cartItem);
      }

      // Save cart to Firestore
      await _firestore
          .collection(_cartCollection)
          .doc(userId)
          .set({
        'userId': userId,
        'items': cartItems.map((item) => item.toMap()).toList(),
        'lastUpdated': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Failed to add item to cart: $e');
    }
  }

  /// Update cart item quantity
  static Future<void> updateCartItemQuantity({
    required String userId,
    required String cartItemId,
    required int quantity,
  }) async {
    try {
      final cart = await getCart(userId);
      if (cart == null) throw Exception('Cart not found');

      final cartItems = List<CartItem>.from(cart.items);
      final itemIndex = cartItems.indexWhere((item) => item.id == cartItemId);

      if (itemIndex == -1) throw Exception('Item not found in cart');

      if (quantity <= 0) {
        cartItems.removeAt(itemIndex);
      } else {
        cartItems[itemIndex] = cartItems[itemIndex].copyWith(quantity: quantity);
      }

      await _firestore
          .collection(_cartCollection)
          .doc(userId)
          .set({
        'userId': userId,
        'items': cartItems.map((item) => item.toMap()).toList(),
        'lastUpdated': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Failed to update cart item: $e');
    }
  }

  /// Remove item from cart
  static Future<void> removeFromCart({
    required String userId,
    required String cartItemId,
  }) async {
    try {
      final cart = await getCart(userId);
      if (cart == null) throw Exception('Cart not found');

      final cartItems = cart.items.where((item) => item.id != cartItemId).toList();

      await _firestore
          .collection(_cartCollection)
          .doc(userId)
          .set({
        'userId': userId,
        'items': cartItems.map((item) => item.toMap()).toList(),
        'lastUpdated': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Failed to remove item from cart: $e');
    }
  }

  /// Clear entire cart
  static Future<void> clearCart(String userId) async {
    try {
      await _firestore
          .collection(_cartCollection)
          .doc(userId)
          .delete();
    } catch (e) {
      throw Exception('Failed to clear cart: $e');
    }
  }

  /// Get cart item count
  static Future<int> getCartItemCount(String userId) async {
    try {
      final cart = await getCart(userId);
      return cart?.totalItems ?? 0;
    } catch (e) {
      throw Exception('Failed to get cart count: $e');
    }
  }

  /// Check if product is in cart
  static Future<bool> isProductInCart({
    required String userId,
    required String productId,
    String size = '',
    String color = '',
  }) async {
    try {
      final cart = await getCart(userId);
      if (cart == null) return false;

      return cart.items.any((item) =>
          item.productId == productId &&
          item.size == size &&
          item.color == color);
    } catch (e) {
      throw Exception('Failed to check cart status: $e');
    }
  }

  /// Get cart items
  static Future<List<CartItem>> getCartItems(String userId) async {
    try {
      final cart = await getCart(userId);
      return cart?.items ?? [];
    } catch (e) {
      throw Exception('Failed to get cart items: $e');
    }
  }

  /// Get cart items by shop
  static Future<Map<String, List<CartItem>>> getCartItemsByShop(String userId) async {
    try {
      final cart = await getCart(userId);
      if (cart == null) return {};

      return cart.itemsByShop;
    } catch (e) {
      throw Exception('Failed to get cart items by shop: $e');
    }
  }

  /// Validate cart items (check availability)
  static Future<List<CartItem>> validateCartItems(String userId) async {
    try {
      final cart = await getCart(userId);
      if (cart == null) return [];

      final validatedItems = <CartItem>[];
      
      for (var item in cart.items) {
        // Check product availability
        final productDoc = await _firestore
            .collection('products')
            .doc(item.productId)
            .get();

        if (productDoc.exists) {
          final productData = productDoc.data()!;
          final isAvailable = productData['isAvailable'] as bool? ?? false;
          final stock = productData['stock'] as int? ?? 0;

          validatedItems.add(item.copyWith(
            isAvailable: isAvailable && stock >= item.quantity,
          ));
        }
      }

      // Update cart with validated items
      await _firestore
          .collection(_cartCollection)
          .doc(userId)
          .set({
        'userId': userId,
        'items': validatedItems.map((item) => item.toMap()).toList(),
        'lastUpdated': Timestamp.fromDate(DateTime.now()),
      });

      return validatedItems;
    } catch (e) {
      throw Exception('Failed to validate cart items: $e');
    }
  }

  /// Get cart summary
  static Future<Map<String, dynamic>> getCartSummary(String userId) async {
    try {
      final cart = await getCart(userId);
      if (cart == null) {
        return {
          'totalItems': 0,
          'totalAmount': 0.0,
          'shopCount': 0,
          'items': <CartItem>[],
        };
      }

      return {
        'totalItems': cart.totalItems,
        'totalAmount': cart.totalAmount,
        'shopCount': cart.shopIds.length,
        'items': cart.items,
        'itemsByShop': cart.itemsByShop,
      };
    } catch (e) {
      throw Exception('Failed to get cart summary: $e');
    }
  }
}

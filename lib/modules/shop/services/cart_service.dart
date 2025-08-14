import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/cart.dart';

class CartService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> _cartCol(String uid) =>
      _db.collection('users').doc(uid).collection('cart');

  String get _uid {
    final u = _auth.currentUser;
    if (u == null) {
      throw StateError('User not authenticated');
    }
    return u.uid;
  }

  /// Live stream of cart item count (sum of quantities) for current user
  Stream<int> watchCartCount() {
    return _cartCol(_uid).snapshots().map((snapshot) {
      int total = 0;
      for (final d in snapshot.docs) {
        final data = d.data();
        final q = data['quantity'];
        if (q is int) total += q;
      }
      return total;
    });
  }

  Future<List<CartItem>> getCartItems({String? uid}) async {
    final userId = uid ?? _uid;
    final snap = await _cartCol(userId).get();
    return snap.docs
        .map((d) => CartItem.fromMap(d.id, d.data()))
        .toList();
  }

  Future<void> addToCart(String productId, {int quantity = 1}) async {
    final ref = _cartCol(_uid).doc(productId); // use productId as doc id for idempotency
    await _db.runTransaction((txn) async {
      final doc = await txn.get(ref);
      if (doc.exists) {
        final current = (doc.data() as Map<String, dynamic>)['quantity'] ?? 0;
        txn.update(ref, {'quantity': (current as int) + quantity});
      } else {
        txn.set(ref, {'productId': productId, 'quantity': quantity});
      }
    });
  }

  Future<void> updateQuantity(String productId, int quantity) async {
    final ref = _cartCol(_uid).doc(productId);
    if (quantity <= 0) {
      await ref.delete();
    } else {
      await ref.update({'quantity': quantity});
    }
  }

  Future<void> removeFromCart(String productId) async {
    await _cartCol(_uid).doc(productId).delete();
  }

  Future<void> clearCart() async {
    final items = await getCartItems();
    for (final item in items) {
      await _cartCol(_uid).doc(item.id).delete();
    }
  }
}


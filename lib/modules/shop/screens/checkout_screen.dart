import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/order_service.dart';
import '../models/order_item.dart';
import '../services/cart_service.dart';

class CheckoutScreen extends StatefulWidget {
  final double total;
  const CheckoutScreen({super.key, required this.total});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _orders = OrderService();

  Future<void> _placeOrder() async {
    // For simplicity, we fetch cart items and create order items with priceAtPurchase resolved at confirmation page.
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final items = await CartService.getCartItems(userId);
    final orderItems = items.map((e) => OrderItem(
      productId: e.productId,
      productName: e.productName,
      price: e.price,
      quantity: e.quantity,
      imageUrl: e.productImage,
    )).toList();
    await _orders.placeOrder(orderItems, widget.total);
    await CartService.clearCart(userId);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order placed')));
    if (Navigator.canPop(context)) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Confirm Order')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Total amount: ${widget.total.toStringAsFixed(2)}'),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _placeOrder,
              icon: const Icon(Icons.check),
              label: const Text('Place Order'),
            )
          ],
        ),
      ),
    );
  }
}


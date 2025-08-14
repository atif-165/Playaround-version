import 'package:flutter/material.dart';
import '../services/order_service.dart';
import '../models/order.dart';
import '../services/cart_service.dart';

class CheckoutScreen extends StatefulWidget {
  final double total;
  const CheckoutScreen({super.key, required this.total});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _orders = OrderService();
  final _cart = CartService();

  Future<void> _placeOrder() async {
    // For simplicity, we fetch cart items and create order items with priceAtPurchase resolved at confirmation page.
    final items = await _cart.getCartItems();
    final orderItems = items.map((e) => OrderItem(productId: e.productId, quantity: e.quantity, priceAtPurchase: 0)).toList();
    await _orders.placeOrder(orderItems, widget.total);
    await _cart.clearCart();
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


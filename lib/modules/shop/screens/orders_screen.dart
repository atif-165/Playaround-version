import 'package:flutter/material.dart';
import '../services/order_service.dart';
import '../models/order.dart' as order_model;

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final _orders = OrderService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Orders')),
      body: FutureBuilder<List<order_model.Order>>(
        future: _orders.myOrders(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snapshot.data ?? [];
          if (items.isEmpty) return const Center(child: Text('No orders yet'));
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final o = items[i];
              return ListTile(
                title: Text('Order ${o.id.substring(0, 6)}'),
                subtitle: Text('${o.items.length} items • ${o.totalAmount.toStringAsFixed(2)}'),
                trailing: Text(o.orderDate.toLocal().toString().split('.').first),
              );
            },
          );
        },
      ),
    );
  }
}


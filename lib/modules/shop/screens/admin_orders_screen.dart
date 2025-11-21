import 'package:flutter/material.dart';

import '../models/order.dart';
import '../services/order_service.dart';

class AdminOrdersScreen extends StatelessWidget {
  AdminOrdersScreen({super.key});

  final OrderService _orderService = OrderService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Orders')),
      body: StreamBuilder<List<Order>>(
        stream: _orderService.allOrdersStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
                child: Text('Failed to load orders: ${snapshot.error}'));
          }
          final orders = snapshot.data ?? [];
          if (orders.isEmpty) {
            return const Center(child: Text('No orders yet'));
          }
          return ListView.separated(
            itemCount: orders.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final order = orders[index];
              return ListTile(
                title: Text(
                    'Order ${order.id.substring(0, 6)} • \$${order.totalAmount.toStringAsFixed(2)}'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('User: ${order.userId}'),
                    Text('Items: ${order.items.length}'),
                    Row(
                      children: [
                        const Text('Status: '),
                        DropdownButton<OrderStatus>(
                          value: order.status,
                          onChanged: (status) {
                            if (status != null) {
                              _orderService.updateOrderStatus(order.id, status);
                            }
                          },
                          items: OrderStatus.values
                              .map(
                                (status) => DropdownMenuItem(
                                  value: status,
                                  child: Text(status.name),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ),
                  ],
                ),
                trailing:
                    Text(order.orderDate.toLocal().toString().split('.').first),
              );
            },
          );
        },
      ),
    );
  }
}

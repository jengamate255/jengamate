import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:jengamate/config/app_routes.dart';
import 'package:jengamate/models/order_model.dart';
import 'package:jengamate/models/enums/order_enums.dart';
import 'package:intl/intl.dart';

class OrderListItem extends StatelessWidget {
  final OrderModel order;

  const OrderListItem({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'en_TZ', symbol: 'TSh ');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      elevation: 2.0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order #${order.orderNumber ?? order.id}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16.0,
                  ),
                ),
                Chip(
                  label: Text(order.status.displayName),
                  backgroundColor: _getStatusColor(order.status),
                  labelStyle: const TextStyle(color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 8.0),
            Text('Customer: ${order.customerName}'),
            const SizedBox(height: 4.0),
            Text('Date: ${DateFormat.yMMMd().format(order.createdAt)}'),
            const SizedBox(height: 8.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total: ${currencyFormat.format(order.totalAmount)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16.0,
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    context.go(AppRouteBuilders.orderDetailsPath(order.id ?? ''));
                  },
                  child: const Text('View Details'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.processing:
        return Colors.blue;
      case OrderStatus.shipped:
        return Colors.teal;
      case OrderStatus.delivered:
        return Colors.green;
      case OrderStatus.cancelled:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

import 'package:flutter/material.dart';
import 'package:jengamate/models/order_model.dart';
import 'package:jengamate/utils/theme.dart';

class OrderCard extends StatelessWidget {
  final Order order;

  const OrderCard({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final isDelivered = order.status == 'DELIVERED';
    final statusColor = isDelivered ? AppTheme.completedColor : AppTheme.pendingColor;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Header
          Container(
            color: statusColor,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order #${order.id}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  order.type,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),

          // Body
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(order.status, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 12),
                _buildInfoRow(Icons.person_outline, order.customerName),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.email_outlined, order.customerEmail),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.phone_outlined, order.customerPhone),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Amount', style: TextStyle(color: AppTheme.subTextColor)),
                    Text(order.totalAmount, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                 const SizedBox(height: 8),
                 Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Payment Method', style: TextStyle(color: AppTheme.subTextColor)),
                    Text(order.paymentMethod, style: const TextStyle(fontWeight: FontWeight.w500)),
                  ],
                ),
                const SizedBox(height: 16),
                if (!isDelivered)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(onPressed: () {}, child: const Text('PAY NOW')),
                  ),
              ],
            ),
          ),

          // Footer
          Container(
            color: Colors.grey.shade100,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(order.date, style: const TextStyle(color: AppTheme.subTextColor, fontSize: 12)),
                Text('Handled by ${order.handler}', style: const TextStyle(color: AppTheme.subTextColor, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.subTextColor),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(color: AppTheme.subTextColor)),
      ],
    );
  }
}

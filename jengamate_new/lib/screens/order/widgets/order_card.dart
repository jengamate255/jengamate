import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:jengamate/models/order_model.dart';
import 'package:jengamate/models/order_status.dart';
import 'package:jengamate/utils/theme.dart';
import 'package:jengamate/screens/order/order_details_screen.dart';
// import 'package:jengamate/screens/order/widgets/payment_dialog.dart'; // TODO: This file is missing, causing build errors.

class OrderCard extends StatelessWidget {
  final OrderModel order;

  const OrderCard({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(order.status);
    final DateFormat formatter = DateFormat('yyyy-MM-dd HH:mm');

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OrderDetailsScreen(orderId: order.id ?? ''),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              color: statusColor,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Order #${order.id?.substring(0, 6) ?? ''}...',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16),
                  ),
                  Text(
                    'Standard', // Default type since OrderModel doesn't have typeDisplayName
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w500),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        order.status.toString().split('.').last.toUpperCase(),
                        style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 14),
                      ),
                      Text(
                        'Updated: ${formatter.format(order.updatedAt)}',
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.subTextColor),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(Icons.person_outline,
                      'Buyer: ${order.customerId.substring(0, 8)}...'),
                  const SizedBox(height: 8),
                  _buildInfoRow(Icons.store_outlined,
                      'Supplier: ${order.supplierId?.substring(0, 8) ?? 'N/A'}...'),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Amount',
                          style: TextStyle(color: AppTheme.subTextColor)),
                      Text(
                        NumberFormat.currency(symbol: 'TSh ', decimalDigits: 2)
                            .format(order.totalAmount),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (order.status != OrderStatus.delivered &&
                      order.status != OrderStatus.cancelled)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          // TODO: Re-implement payment dialog. The original PaymentDialog file is missing.
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Payment functionality is currently unavailable.'),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('MAKE PAYMENT'),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.subTextColor),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text,
              style: const TextStyle(fontSize: 14, color: AppTheme.textColor)),
        ),
      ],
    );
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return AppTheme.pendingColor;
      case OrderStatus.confirmed:
      case OrderStatus.processing:
        return AppTheme.infoColor;
      case OrderStatus.shipped:
        return AppTheme.primaryColor;
      case OrderStatus.delivered:
      case OrderStatus.completed:
        return AppTheme.completedColor;
      case OrderStatus.cancelled:
      case OrderStatus.refunded:
        return AppTheme.errorColor;
      default:
        return Colors.grey;
    }
  }
}

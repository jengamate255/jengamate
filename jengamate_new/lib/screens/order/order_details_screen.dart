import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:jengamate/models/order_model.dart';
import 'package:jengamate/models/payment_model.dart';
import 'package:jengamate/services/database_service.dart';
import 'package:jengamate/models/enums/order_enums.dart';
import 'package:jengamate/models/enums/payment_enums.dart';
import 'payment_screen.dart';
import 'package:jengamate/ui/design_system/layout/adaptive_padding.dart';
import 'package:jengamate/ui/design_system/tokens/spacing.dart';
import 'package:jengamate/ui/design_system/components/jm_card.dart';

class OrderDetailsScreen extends StatefulWidget {
  final String orderId;

  const OrderDetailsScreen({Key? key, required this.orderId}) : super(key: key);

  @override
  _OrderDetailsScreenState createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  final DatabaseService _databaseService = DatabaseService();
  late Future<OrderModel?> _orderFuture;
  late Stream<List<PaymentModel>> _paymentsStream;

  @override
  void initState() {
    super.initState();
    _loadOrder();
    _paymentsStream = _databaseService.streamOrderPayments(widget.orderId);
  }

  void _loadOrder() {
    setState(() {
      _orderFuture = _databaseService.getOrder(widget.orderId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Details'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: FutureBuilder<OrderModel?>(
        future: _orderFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final order = snapshot.data;
          if (order == null) {
            return const Center(child: Text('Order not found'));
          }

          return AdaptivePadding(
            child: _buildOrderDetails(order),
          );
        },
      ),
    );
  }

  Widget _buildOrderDetails(OrderModel order) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildOrderHeader(order),
          const SizedBox(height: JMSpacing.lg),
          _buildOrderItems(order),
          const SizedBox(height: JMSpacing.lg),
          _buildPaymentSummary(order),
          const SizedBox(height: JMSpacing.lg),
          _buildPaymentHistory(),
          const SizedBox(height: JMSpacing.lg),
          _buildActionButtons(order),
        ],
      ),
    );
  }

  Widget _buildOrderHeader(OrderModel order) {
    return JMCard(
      child: Padding(
        padding: const EdgeInsets.all(JMSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order #${order.id.substring(0, 8)}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                _buildStatusChip(order.status),
              ],
            ),
            const SizedBox(height: JMSpacing.sm),
            Text(
              'Created: ${DateFormat('MMM dd, yyyy HH:mm').format(order.createdAt)}',
              style: const TextStyle(color: Colors.grey),
            ),
            if (order.expectedDeliveryDate != null) ...[
              const SizedBox(height: JMSpacing.xs),
              Text(
                'Expected Delivery: ${DateFormat('MMM dd, yyyy').format(order.expectedDeliveryDate!)}',
                style: const TextStyle(color: Colors.grey),
              ),
            ],
            if (order.notes != null && order.notes!.isNotEmpty) ...[
              const SizedBox(height: JMSpacing.sm),
              Text(
                'Notes: ${order.notes}',
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(OrderStatus status) {
    Color color;
    switch (status) {
      case OrderStatus.pending:
        color = Colors.orange;
        break;
      case OrderStatus.confirmed:
        color = Colors.blue;
        break;
      case OrderStatus.processing:
        color = Colors.purple;
        break;
      case OrderStatus.shipped:
        color = Colors.indigo;
        break;
      case OrderStatus.delivered:
        color = Colors.green;
        break;
      case OrderStatus.cancelled:
        color = Colors.red;
        break;
      case OrderStatus.refunded:
        color = Colors.grey;
        break;
      case OrderStatus.completed:
        color = Colors.green;
        break;
      case OrderStatus.fullyPaid:
        color = Colors.green;
        break;
      case OrderStatus.pendingPayment:
        color = Colors.orange;
        break;
      default:
        color = Colors.grey;
        break;
    }

    return Chip(
      label: Text(
        status.toString().split('.').last.toUpperCase(),
        style: const TextStyle(color: Colors.white),
      ),
      backgroundColor: color,
    );
  }

  Widget _buildOrderItems(OrderModel order) {
    return JMCard(
      child: Padding(
        padding: const EdgeInsets.all(JMSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Order Items',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: JMSpacing.md),
            // This would typically show actual items
            // For now, showing a placeholder
            ListTile(
              title: const Text('Order Items'),
              subtitle: Text('Total: \$${order.totalAmount.toStringAsFixed(2)}'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentSummary(OrderModel order) {
    return StreamBuilder<List<PaymentModel>>(
      stream: _paymentsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final payments = snapshot.data ?? [];
        final verifiedPayments = payments
            .where((p) => p.status == PaymentStatus.verified)
            .toList();
        
        final totalPaid = verifiedPayments.fold(
          0.0,
          (sum, payment) => sum + payment.amount,
        );
        
        final remaining = order.totalAmount - totalPaid;

        return JMCard(
          child: Padding(
            padding: const EdgeInsets.all(JMSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Payment Summary',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: JMSpacing.md),
                _buildPaymentRow('Total Amount', order.totalAmount),
                _buildPaymentRow('Paid Amount', totalPaid),
                _buildPaymentRow('Remaining Amount', remaining),
                const SizedBox(height: JMSpacing.sm),
                LinearProgressIndicator(
                  value: totalPaid / order.totalAmount,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    remaining <= 0 ? Colors.green : Colors.orange,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPaymentRow(String label, double amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: JMSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            '\$${amount.toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentHistory() {
    return JMCard(
      child: Padding(
        padding: const EdgeInsets.all(JMSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Payment History',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: JMSpacing.md),
            StreamBuilder<List<PaymentModel>>(
              stream: _paymentsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final payments = snapshot.data ?? [];
                if (payments.isEmpty) {
                  return const Text('No payments yet');
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: payments.length,
                  itemBuilder: (context, index) {
                    final payment = payments[index];
                    return _buildPaymentItem(payment);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentItem(PaymentModel payment) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: _getPaymentStatusColor(payment.status),
        child: Icon(
          _getPaymentStatusIcon(payment.status),
          color: Colors.white,
          size: 20,
        ),
      ),
      title: Text(
        '\$${payment.amount.toStringAsFixed(2)}',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Status: ${payment.status.name}'),
          Text(
            'Date: ${DateFormat('MMM dd, yyyy HH:mm').format(payment.createdAt)}',
          ),
          if (payment.notes != null && payment.notes!.isNotEmpty)
            Text('Notes: ${payment.notes}'),
        ],
      ),
      trailing: payment.status == PaymentStatus.pending
          ? const Icon(Icons.pending, color: Colors.orange)
          : payment.status == PaymentStatus.verified
              ? const Icon(Icons.check_circle, color: Colors.green)
              : const Icon(Icons.error, color: Colors.red),
    );
  }

  Color _getPaymentStatusColor(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.pending:
        return Colors.orange;
      case PaymentStatus.verified:
        return Colors.green;
      case PaymentStatus.rejected:
        return Colors.red;
      case PaymentStatus.cancelled:
        return Colors.grey;
      case PaymentStatus.processing:
        return Colors.blue;
      case PaymentStatus.completed:
        return Colors.green;
      case PaymentStatus.failed:
        return Colors.red;
      case PaymentStatus.refunded:
        return Colors.grey;
      case PaymentStatus.partiallyRefunded:
        return Colors.grey;
      case PaymentStatus.awaitingVerification:
        return Colors.orange;
      case PaymentStatus.verificationFailed:
        return Colors.red;
      case PaymentStatus.disputed:
        return Colors.red;
      case PaymentStatus.chargeback:
        return Colors.red;
      case PaymentStatus.expired:
        return Colors.grey;
      case PaymentStatus.authorized:
        return Colors.blue;
      case PaymentStatus.captured:
        return Colors.green;
      case PaymentStatus.voided:
        return Colors.grey;
      case PaymentStatus.settled:
        return Colors.green;
      case PaymentStatus.unsettled:
        return Colors.orange;
      case PaymentStatus.onHold:
        return Colors.orange;
      case PaymentStatus.unknown:
        return Colors.grey;
      default:
        return Colors.orange; // e.g., timeout or any new status
    }
  }

  IconData _getPaymentStatusIcon(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.pending:
        return Icons.pending;
      case PaymentStatus.verified:
        return Icons.check;
      case PaymentStatus.rejected:
        return Icons.close;
      case PaymentStatus.cancelled:
        return Icons.cancel;
      case PaymentStatus.processing:
        return Icons.hourglass_empty;
      case PaymentStatus.completed:
        return Icons.check_circle;
      case PaymentStatus.failed:
        return Icons.error;
      case PaymentStatus.refunded:
        return Icons.undo;
      case PaymentStatus.partiallyRefunded:
        return Icons.undo;
      case PaymentStatus.awaitingVerification:
        return Icons.pending;
      case PaymentStatus.verificationFailed:
        return Icons.error;
      case PaymentStatus.disputed:
        return Icons.report;
      case PaymentStatus.chargeback:
        return Icons.report;
      case PaymentStatus.expired:
        return Icons.timer_off;
      case PaymentStatus.authorized:
        return Icons.lock;
      case PaymentStatus.captured:
        return Icons.check_circle;
      case PaymentStatus.voided:
        return Icons.cancel;
      case PaymentStatus.settled:
        return Icons.check_circle;
      case PaymentStatus.unsettled:
        return Icons.pending;
      case PaymentStatus.onHold:
        return Icons.pause;
      case PaymentStatus.unknown:
        return Icons.help;
      default:
        return Icons.timer_off; // e.g., timeout or any new status
    }
  }

  Widget _buildActionButtons(OrderModel order) {
    return StreamBuilder<List<PaymentModel>>(
      stream: _paymentsStream,
      builder: (context, snapshot) {
        final payments = snapshot.data ?? [];
        final verifiedPayments = payments
            .where((p) => p.status == PaymentStatus.verified)
            .toList();
        
        final totalPaid = verifiedPayments.fold(
          0.0,
          (sum, payment) => sum + payment.amount,
        );
        
        final remaining = order.totalAmount - totalPaid;

        return Column(
          children: [
            if (remaining > 0)
              ElevatedButton(
                onPressed: () => _navigateToPayment(order),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: Text(
                  'Make Payment (\$${remaining.toStringAsFixed(2)} remaining)',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            const SizedBox(height: 12),
            if (order.status == OrderStatus.pending)
              OutlinedButton(
                onPressed: () => _cancelOrder(order),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text('Cancel Order'),
              ),
          ],
        );
      },
    );
  }

  void _navigateToPayment(OrderModel order) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentScreen(orderId: order.id),
      ),
    ).then((_) {
      _loadOrder(); // Refresh order data
    });
  }

  void _cancelOrder(OrderModel order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Order'),
        content: const Text('Are you sure you want to cancel this order?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () async {
              try {
                final updatedOrder = order.copyWith(
                  status: OrderStatus.cancelled,
                );
                await _databaseService.updateOrder(updatedOrder);
                Navigator.pop(context);
                _loadOrder();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to cancel order: $e')),
                );
              }
            },
            child: const Text('Yes'),
          ),
        ],
      ),
    );
  }
}
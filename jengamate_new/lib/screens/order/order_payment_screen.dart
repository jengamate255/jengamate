import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jengamate/models/payment_model.dart';
import 'package:jengamate/services/auth_service.dart';
import '../../models/order_model.dart';
import 'package:jengamate/services/payment_service.dart';
import 'package:jengamate/services/order_service.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/error_display.dart';
import 'package:jengamate/ui/design_system/layout/adaptive_padding.dart';
import 'package:jengamate/ui/design_system/tokens/spacing.dart';
import 'package:jengamate/ui/design_system/components/jm_card.dart';

class OrderPaymentScreen extends StatefulWidget {
  final String orderId;

  const OrderPaymentScreen({Key? key, required this.orderId}) : super(key: key);

  @override
  _OrderPaymentScreenState createState() => _OrderPaymentScreenState();
}

class _OrderPaymentScreenState extends State<OrderPaymentScreen> {
  late PaymentService _paymentService;
  late OrderService _orderService;
  late AuthService _authService;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _paymentService = Provider.of<PaymentService>(context, listen: false);
    _orderService = Provider.of<OrderService>(context, listen: false);
    _authService = Provider.of<AuthService>(context, listen: false);
  }

  Future<void> _handlePayment(OrderModel order) async {
    setState(() {
      _isProcessing = true;
    });

    try {
      final user = _authService.currentUser;
      if (user == null) {
        throw Exception('You must be logged in to pay.');
      }

      final amountToPay = order.totalAmount - (order.amountPaid ?? 0.0);
      if (amountToPay <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This order is already fully paid.')),
        );
        return;
      }

      if (order.id == null) {
        throw Exception('Order ID is missing.');
      }
      final paymentUrl = await _paymentService.initiatePayment(
        order.id!,
        amountToPay,
        user.uid,
      );

      // In a real app, you would open the paymentUrl in a webview or browser.
      // For this simulation, we'll immediately process the payment.
      final paymentId = Uri.parse(paymentUrl).queryParameters['paymentId'];
      if (paymentId != null) {
        await _paymentService.processPayment(paymentId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment successful!')),
        );
      } else {
        throw Exception('Failed to get payment ID from simulated URL.');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment failed: $e')),
      );
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Payment'),
      ),
      body: StreamBuilder<OrderModel>(
        stream: _orderService.getOrder(widget.orderId),
        builder: (context, orderSnapshot) {
          if (orderSnapshot.connectionState == ConnectionState.waiting) {
            return const LoadingIndicator();
          }
          if (orderSnapshot.hasError) {
            return ErrorDisplay(message: 'Error: ${orderSnapshot.error}');
          }
          if (!orderSnapshot.hasData) {
            return const ErrorDisplay(message: 'Order not found.');
          }

          final order = orderSnapshot.data!;

          return AdaptivePadding(
            child: Column(
              children: [
                _buildOrderSummary(order),
                const SizedBox(height: JMSpacing.lg),
                Expanded(child: _buildPaymentHistory(order.id ?? '')),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: StreamBuilder<OrderModel>(
        stream: _orderService.getOrder(widget.orderId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const SizedBox.shrink();
          final order = snapshot.data!;
          final remainingBalance = order.totalAmount - (order.amountPaid ?? 0.0);
          if (remainingBalance > 0 && !_isProcessing) {
            return Padding(
              padding: const EdgeInsets.all(JMSpacing.md),
              child: ElevatedButton(
                onPressed: () => _handlePayment(order),
                child: Text('Pay Now (TSh ${remainingBalance.toStringAsFixed(2)})'),
              ),
            );
          } else if (_isProcessing) {
            return const Padding(
              padding: EdgeInsets.all(JMSpacing.md),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildOrderSummary(OrderModel order) {
    final remainingBalance = order.totalAmount - (order.amountPaid ?? 0.0);
    return JMCard(
      child: Padding(
        padding: const EdgeInsets.all(JMSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Order ID: ${order.id}', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: JMSpacing.xs),
            Text('Total Amount: TSh ${order.totalAmount.toStringAsFixed(2)}', style: Theme.of(context).textTheme.titleLarge),
            Text('Amount Paid: TSh ${(order.amountPaid ?? 0.0).toStringAsFixed(2)}', style: Theme.of(context).textTheme.titleMedium),
            Text('Remaining Balance: TSh ${remainingBalance.toStringAsFixed(2)}', style: Theme.of(context).textTheme.titleMedium),
            Text('Status: ${order.status.name}', style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentHistory(String orderId) {
    return StreamBuilder<List<PaymentModel>>(
      stream: _paymentService.getPaymentsForOrder(orderId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingIndicator();
        }
        if (snapshot.hasError) {
          return ErrorDisplay(message: 'Error: ${snapshot.error}');
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No payment history.'));
        }

        final payments = snapshot.data!;
        return ListView.builder(
          itemCount: payments.length,
          itemBuilder: (context, index) {
            final payment = payments[index];
            return JMCard(
              margin: const EdgeInsets.only(bottom: JMSpacing.sm),
              child: ListTile(
                title: Text('Amount: TSh ${payment.amount.toStringAsFixed(2)}'),
                subtitle: Text('Status: ${payment.status} | Method: ${payment.paymentMethod}'),
                trailing: Text(payment.createdAt.toLocal().toString().split(' ')[0]),
              ),
            );
          },
        );
      },
    );
  }
}
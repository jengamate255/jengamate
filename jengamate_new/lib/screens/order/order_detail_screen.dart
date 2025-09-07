import 'package:flutter/material.dart';
import 'package:jengamate/models/payment_model.dart';
import 'package:jengamate/models/product_model.dart';
import 'package:jengamate/services/database_service.dart';
import 'package:jengamate/services/order_service.dart';
import 'package:provider/provider.dart';
import 'package:jengamate/services/payment_service.dart';
import 'package:jengamate/models/enums/order_enums.dart';
import '../../models/order_model.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/error_display.dart';
import '../chat/chat_screen.dart';
import 'package:jengamate/services/auth_service.dart';
import 'package:jengamate/services/invoice_service.dart';
import 'package:jengamate/ui/design_system/layout/adaptive_padding.dart';
import 'package:jengamate/ui/design_system/tokens/spacing.dart';
import 'package:jengamate/ui/design_system/components/jm_card.dart';
import 'package:jengamate/screens/order/invoice_details_screen.dart';

class OrderDetailScreen extends StatefulWidget {
  final String orderId;

  const OrderDetailScreen({Key? key, required this.orderId}) : super(key: key);

  @override
  _OrderDetailScreenState createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  late OrderService _orderService;
  late PaymentService _paymentService;
  late DatabaseService _databaseService;
  late AuthService _authService;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _orderService = Provider.of<OrderService>(context, listen: false);
    _paymentService = Provider.of<PaymentService>(context, listen: false);
    _databaseService = Provider.of<DatabaseService>(context, listen: false);
    _authService = Provider.of<AuthService>(context, listen: false);
    _currentUserId = _authService.currentUser?.uid;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Details'),
      ),
      body: StreamBuilder<OrderModel?>(
        stream: _orderService.getOrder(widget.orderId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingIndicator();
          }
          if (snapshot.hasError) {
            return ErrorDisplay(message: 'Error: ${snapshot.error}');
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return const ErrorDisplay(message: 'Order not found.');
          }

          final order = snapshot.data!;
          final isCurrentUserBuyer = order.customerId == _currentUserId;

          return SingleChildScrollView(
            child: AdaptivePadding(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildOrderSummary(context, order),
                  const SizedBox(height: JMSpacing.lg),
                  _buildProductDetails(context, order),
                  const SizedBox(height: JMSpacing.lg),
                  _buildPaymentHistory(context, order),
                  const SizedBox(height: JMSpacing.lg),
                  if (isCurrentUserBuyer)
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final invoiceService = Provider.of<InvoiceService>(context, listen: false);
                          try {
                            // Show loading indicator
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (BuildContext context) {
                                return const Center(child: CircularProgressIndicator());
                              },
                            );
                            
                            // Check if invoice exists for this order
                            final invoice = await invoiceService.getInvoiceByOrderId(order.id ?? '');
                            
                            // Close loading dialog
                            Navigator.of(context).pop();
                            
                            if (invoice != null) {
                              // Navigate to invoice details
                              if (!mounted) return;
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => InvoiceDetailsScreen(orderId: order.id ?? ''),
                                ),
                              );
                            } else {
                              // If no invoice exists, show a message
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('No invoice found for this order.')),
                              );
                            }
                          } catch (e) {
                            // Close loading dialog if there's an error
                            if (mounted) {
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error loading invoice: $e')),
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.receipt_long),
                        label: const Text('View Invoice'),
                      ),
                    ),
                  const SizedBox(height: JMSpacing.md),
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatScreen(
                              orderId: widget.orderId,
                              currentUserId: _currentUserId ?? '',
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.chat),
                      label: const Text('Open Order Chat'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOrderSummary(BuildContext context, OrderModel order) {
    return JMCard(
      child: Padding(
        padding: const EdgeInsets.all(JMSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Order ID: ${order.id}', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: JMSpacing.sm),
            Text('Status: ${order.status.name.toUpperCase()}', style: TextStyle(color: order.status.color, fontWeight: FontWeight.bold)),
            const SizedBox(height: JMSpacing.sm),
            Text('Total: \$${order.totalAmount.toStringAsFixed(2)}'),
            Text('Amount Paid: \$${(order.amountPaid ?? 0.0).toStringAsFixed(2)}'),
            Text('Amount Due: \$${order.amountDue.toStringAsFixed(2)}'),
            const SizedBox(height: JMSpacing.sm),
            Text('Created: ${order.createdAt.toLocal()}'),
          ],
        ),
      ),
    );
  }

  Widget _buildProductDetails(BuildContext context, OrderModel order) {
    final productIds = order.items.map((item) => item.productId).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Products', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: JMSpacing.sm),
        FutureBuilder<List<ProductModel>>(
          future: _databaseService.getProductsByIds(productIds),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const LoadingIndicator();
            }
            if (snapshot.hasError) {
              return const ErrorDisplay(message: 'Could not load products.');
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Text('No products found for this order.');
            }

            final products = snapshot.data!;
            final productMap = {for (var p in products) p.id: p};

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: order.items.length,
              itemBuilder: (context, index) {
                final item = order.items[index];
                final product = productMap[item.productId];
                return JMCard(
                  margin: const EdgeInsets.only(bottom: JMSpacing.sm),
                  child: ListTile(
                    title: Text(product?.name ?? 'Unknown Product'),
                    subtitle: Text('Quantity: ${item.quantity}'),
                    trailing: Text('\$${item.price.toStringAsFixed(2)} each'),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildPaymentHistory(BuildContext context, OrderModel order) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Payment History', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: JMSpacing.sm),
        StreamBuilder<List<PaymentModel>>(
          stream: _paymentService.getPaymentsForOrder(order.id ?? ''),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const LoadingIndicator();
            }
            if (snapshot.hasError) {
              return const ErrorDisplay(message: 'Could not load payment history.');
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Text('No payments made yet.');
            }

            final payments = snapshot.data!;
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: payments.length,
              itemBuilder: (context, index) {
                final payment = payments[index];
                return JMCard(
                  margin: const EdgeInsets.only(bottom: JMSpacing.sm),
                  child: ListTile(
                    title: Text('Payment: \$${payment.amount.toStringAsFixed(2)}'),
                    subtitle: Text('Status: ${payment.status}'),
                    trailing: Text(payment.createdAt.toLocal().toString()),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}

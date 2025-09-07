import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:jengamate/models/order_model.dart';
import 'package:jengamate/models/payment_model.dart';
import 'package:jengamate/models/invoice_model.dart';
import 'package:jengamate/services/order_service.dart';
import 'package:jengamate/services/console_error_handler.dart';
import 'package:jengamate/models/enums/order_enums.dart';
import 'package:jengamate/models/enums/payment_enums.dart';
import 'payment_screen.dart';
import 'package:jengamate/ui/design_system/layout/adaptive_padding.dart';
import 'package:jengamate/ui/design_system/tokens/spacing.dart';
import 'package:jengamate/ui/design_system/components/jm_card.dart';
import 'package:jengamate/config/app_routes.dart';
import 'package:jengamate/services/invoice_service.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

class OrderDetailsScreen extends StatefulWidget {
  final String orderId;

  const OrderDetailsScreen({Key? key, required this.orderId}) : super(key: key);

  @override
  _OrderDetailsScreenState createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  late final OrderService _orderService;
  late Future<OrderModel?> _orderFuture;
  late Stream<List<PaymentModel>> _paymentsStream;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _orderService = Provider.of<OrderService>(context, listen: false);
    _loadOrder();
    _paymentsStream = _orderService.streamOrderPayments(widget.orderId);
  }

  void _loadOrder() {
    setState(() {
      _orderFuture = _orderService.getOrderWithItems(widget.orderId);
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
                  'Order #${order.id != null && order.id!.length >= 8 ? order.id!.substring(0, 8) : order.id ?? ''}',
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order Items (${order.items.length})',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                // Removed total amount display from order items to reduce redundancy
              ],
            ),
            const SizedBox(height: JMSpacing.md),
            if (order.items.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(JMSpacing.lg),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.inventory, size: 48, color: Colors.grey),
                      const SizedBox(height: JMSpacing.md),
                      Text(
                        'No items found in this order',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: JMSpacing.sm),
                      Text(
                        'Attempting to populate items from associated quotation...',
                        style: const TextStyle(
                          color: Colors.blue,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: order.items.length,
                itemBuilder: (context, index) {
                  final item = order.items[index];
                  final lineTotal = item.quantity * item.price;

                  return Container(
                    margin: EdgeInsets.only(
                      bottom: index < order.items.length - 1 ? JMSpacing.sm : 0,
                    ),
                    padding: const EdgeInsets.all(JMSpacing.sm),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Product Icon (placeholder)
                        CircleAvatar(
                          backgroundColor: Colors.blue.shade100,
                          radius: 20,
                          child: Text(
                            item.productName.isNotEmpty
                                ? item.productName[0].toUpperCase()
                                : 'P',
                            style: const TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: JMSpacing.md),
                        // Product Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.productName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Quantity: ${item.quantity}',
                                      style: TextStyle(
                                        color: Colors.grey.shade700,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  // Removed individual item price to reduce redundancy
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Line Total (removed to reduce price display redundancy)
                      ],
                    ),
                  );
                },
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
            .where((p) =>
                p.status == PaymentStatus.verified ||
                p.status == PaymentStatus.completed ||
                p.status == PaymentStatus.settled)
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
            'TSH ${amount.toStringAsFixed(2)}',
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
        'TSH ${payment.amount.toStringAsFixed(2)}',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Status: ${payment.status.name}'),
          Text(
            'Date: ${DateFormat('MMM dd, yyyy HH:mm').format(payment.createdAt)}',
          ),
        ],
      ),
      trailing: payment.status == PaymentStatus.pending
          ? const Icon(Icons.pending, color: Colors.orange)
          : payment.status == PaymentStatus.verified ||
                  payment.status == PaymentStatus.completed
              ? const Icon(Icons.check_circle, color: Colors.green)
              : const Icon(Icons.error, color: Colors.red),
    );
  }

  Color _getPaymentStatusColor(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.pending:
        return Colors.orange;
      case PaymentStatus.verified:
      case PaymentStatus.completed:
      case PaymentStatus.captured:
      case PaymentStatus.settled:
        return Colors.green;
      case PaymentStatus.rejected:
      case PaymentStatus.cancelled:
      case PaymentStatus.failed:
        return Colors.red;
      case PaymentStatus.processing:
        return Colors.blue;
      default:
        return Colors.grey;
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
            .where((p) =>
                p.status == PaymentStatus.verified ||
                p.status == PaymentStatus.completed ||
                p.status == PaymentStatus.settled)
            .toList();

        final totalPaid = verifiedPayments.fold(
          0.0,
          (sum, payment) => sum + payment.amount,
        );

        final remaining = order.totalAmount - totalPaid;

        return Column(
          children: [
            ElevatedButton(
              onPressed: () => _navigateToInvoice(order),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text(
                'View Invoice',
                style: TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 12),
            if (remaining > 0)
              ElevatedButton(
                onPressed: () => _navigateToPayment(order),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: Text(
                  'Make Payment (TSH ${remaining.toStringAsFixed(2)} remaining)',
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

  void _navigateToInvoice(OrderModel order) async {
    final invoiceService = Provider.of<InvoiceService>(context, listen: false);
    try {
      final orderId = order.id;
      if (orderId == null) {
        print('❌ ERROR: Order ID is null');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order ID is missing.')),
        );
        return;
      }

      print('🔍 Checking for existing invoice for order: $orderId');

      // First, try to get existing invoice
      InvoiceModel? invoice = await invoiceService.getInvoiceByOrderId(orderId);

      // If no invoice exists, create one automatically
      if (invoice == null) {
        print('📄 No invoice found, creating new invoice...');
        final createdInvoice = await _createInvoiceForOrder(order);
        if (createdInvoice == null) {
          print('❌ ERROR: _createInvoiceForOrder returned null');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Failed to create invoice for this order.')),
          );
          return;
        }

        // Ensure we have the ID from the created invoice
        final invoiceId = createdInvoice.id;
        print('📋 Created invoice ID: $invoiceId');
        if (invoiceId == null || invoiceId.isEmpty) {
          print('❌ ERROR: Invoice created but ID is null or empty');
          print('   Invoice object: ${createdInvoice.toString()}');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'Invoice created but ID is missing. Please refresh and try again.')),
          );
          return;
        }

        print('✅ Navigating to invoice: $invoiceId');
        if (mounted) {
          context.push(AppRouteBuilders.invoiceDetailsPath(invoiceId));
        }
      } else {
        // Invoice already exists, ensure it has a valid ID
        final invoiceId = invoice.id;
        print('📋 Found existing invoice ID: $invoiceId');
        if (invoiceId == null || invoiceId.isEmpty) {
          print('❌ ERROR: Existing invoice found but ID is null or empty');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invoice found but ID is invalid.')),
          );
          return;
        }

        print('✅ Navigating to existing invoice: $invoiceId');
        if (mounted) {
          context.push(AppRouteBuilders.invoiceDetailsPath(invoiceId));
        }
      }
    } catch (e) {
      print('❌ ERROR in _navigateToInvoice: $e');
      print('   Stack trace: ${StackTrace.current}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to retrieve invoice: $e')),
      );
    }
  }

  Future<InvoiceModel?> _createInvoiceForOrder(OrderModel order) async {
    final invoiceService = Provider.of<InvoiceService>(context, listen: false);

    try {
      // Create invoice item using total amount from payment summary
      ConsoleErrorHandler.logInfo(
          'Creating invoice using total amount from payment summary: ${order.totalAmount}');

      // Ensure we have a valid total amount
      final totalAmount = order.totalAmount > 0
          ? order.totalAmount
          : 1000.0; // Fallback to 1000.0 if 0

      // Create invoice items from order items or use total as fallback
      final invoiceItems = order.items.isNotEmpty
          // Use actual order items if available
          ? order.items
              .map((item) => InvoiceItem(
                    id: '',
                    description: item.productName.isNotEmpty
                        ? item.productName
                        : 'Order Item',
                    quantity: item.quantity,
                    unitPrice: item.price,
                    productId: item.productId,
                  ))
              .toList()
          // Fallback to single total item
          : [
              InvoiceItem(
                id: '',
                description: 'Order Services - Total Amount',
                quantity: 1,
                unitPrice: totalAmount,
                productId: null,
              ),
            ];

      ConsoleErrorHandler.logInfo(
          'Invoice created with ${invoiceItems.length} items, total: $totalAmount');

      // Create the invoice
      final invoice = InvoiceModel(
        id: '',
        orderId: order.id!,
        invoiceNumber:
            'INV-${order.id != null && order.id!.length >= 8 ? order.id!.substring(0, 8).toUpperCase() : order.id!.toUpperCase()}',
        customerId: order.customerId,
        customerName: order.customerName,
        customerEmail: order.customerEmail,
        customerPhone: order.customerPhone,
        customerAddress: order.deliveryAddress,
        issueDate: DateTime.now(),
        dueDate: DateTime.now().add(const Duration(days: 30)),
        items: invoiceItems,
        taxRate: 0, // No tax
        discountAmount: 0, // No discount
        status: 'sent',
        paymentTerms: 30,
        notes: order.notes ?? 'Thank you for your business!',
      );

      // Save the invoice
      final createdInvoice = await invoiceService.createInvoice(invoice);
      print('Created invoice ID: ${createdInvoice.id}');
      print('Created invoice orderId: ${createdInvoice.orderId}');
      return createdInvoice;
    } catch (e) {
      print('Error creating invoice: $e');
      return null;
    }
  }

  void _navigateToPayment(OrderModel order) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentScreen(orderId: order.id ?? ''),
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
                await _orderService.updateOrder(updatedOrder);
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

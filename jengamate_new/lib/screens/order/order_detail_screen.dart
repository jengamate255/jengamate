import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jengamate/services/payment_service.dart';
import '../../models/order_model.dart';

import '../../widgets/loading_indicator.dart';
import '../../widgets/error_display.dart';
import '../chat/chat_screen.dart'; // Import the ChatScreen
import '../../services/auth_service.dart'; // Assuming you have an Auth Service to get current user
import 'package:jengamate/ui/design_system/layout/adaptive_padding.dart';
import 'package:jengamate/ui/design_system/tokens/spacing.dart';
import 'package:jengamate/ui/design_system/components/jm_card.dart';

class OrderDetailScreen extends StatefulWidget {
  final String orderId;

  const OrderDetailScreen({Key? key, required this.orderId}) : super(key: key);

  @override
  _OrderDetailScreenState createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  late PaymentService _paymentService;
  late AuthService _authService; // Assuming AuthService to get current user
  String? _currentUserId; // To store the current user's ID
  String? _otherUserId; // To store the other participant's ID in chat

  @override
  void initState() {
    super.initState();
    _paymentService = Provider.of<PaymentService>(context, listen: false);
    _authService = Provider.of<AuthService>(context, listen: false);
    _getCurrentUserAndOtherUser();
  }

  void _getCurrentUserAndOtherUser() async {
    // In a real application, you would fetch the current user's ID
    // and determine the 'otherUserId' based on the order's buyerId and supplierId.
    // For this example, we'll use placeholders.
    _currentUserId = _authService.currentUser?.uid; // Get current user ID from AuthService
    // Logic to determine otherUserId based on order.buyerId and order.supplierId
    // For now, a placeholder.
    _otherUserId = 'placeholder_other_user_id'; // Replace with actual logic
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Details'),
      ),
      body: StreamBuilder<OrderModel>(
        stream: _paymentService.getOrderPaymentDetails(widget.orderId),
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
          final bool isOrderLocked = order.isLocked;

          return SingleChildScrollView(
            child: AdaptivePadding(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Order ID: ${order.id}', style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: JMSpacing.xs),
                  Text('Buyer ID: ${order.buyerId}'),
                  Text('Supplier ID: ${order.supplierId}'),
                  Text('Total Amount: \$${order.totalAmount.toStringAsFixed(2)}'),
                  Text('Status: ${order.statusDisplayName}'),
                  Text('Type: ${order.typeDisplayName}'),
                  Text('Currency: ${order.currency}'),
                  Text('Quotation ID: ${order.quotationId ?? 'N/A'}'),
                  Text('RFQ ID: ${order.rfqId ?? 'N/A'}'),
                  Text('Is Locked: ${isOrderLocked ? 'Yes' : 'No'}'),
                  Text('Created At: ${order.createdAt.toLocal()}'),
                  Text('Updated At: ${order.updatedAt.toLocal()}'),

                  const SizedBox(height: JMSpacing.lg),
                  Text('Order Details (Editable when unlocked):', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: JMSpacing.sm),

                  // Example of fields that would be locked
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Product Name (Example)',
                      enabled: !isOrderLocked,
                      border: const OutlineInputBorder(),
                    ),
                    readOnly: isOrderLocked,
                    controller: TextEditingController(text: 'Example Product'), // Replace with actual product data
                  ),
                  const SizedBox(height: JMSpacing.md),
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Quantity (Example)',
                      enabled: !isOrderLocked,
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    readOnly: isOrderLocked,
                    controller: TextEditingController(text: '10'), // Replace with actual quantity
                  ),
                  const SizedBox(height: JMSpacing.md),
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Price Per Unit (Example)',
                      enabled: !isOrderLocked,
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    readOnly: isOrderLocked,
                    controller: TextEditingController(text: '100.00'), // Replace with actual price
                  ),
                  const SizedBox(height: JMSpacing.lg),

                  if (isOrderLocked)
                    Center(
                      child: Text(
                        'This order is locked as payment has been confirmed. No further modifications are allowed.',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ),
                
                  // Display payment proofs if available
                  if (order.paymentProofs != null && order.paymentProofs!.isNotEmpty) ...[
                    const SizedBox(height: JMSpacing.lg),
                    Text('Payment Records:', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: JMSpacing.sm),
                    ...order.paymentProofs!.map((proof) {
                      final rawTs = proof['timestamp'] ?? proof['uploadedAt'];
                      DateTime timestamp;
                      if (rawTs is DateTime) {
                        timestamp = rawTs;
                      } else if (rawTs is String) {
                        timestamp = DateTime.tryParse(rawTs) ?? order.createdAt;
                      } else {
                        try {
                          // Handle Firestore Timestamp without direct import types
                          // by checking for common map structure { _seconds, _nanoseconds }
                          if (rawTs is Map && rawTs.containsKey('_seconds')) {
                            final seconds = rawTs['_seconds'];
                            if (seconds is int) {
                              timestamp = DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
                            } else {
                              timestamp = order.createdAt;
                            }
                          } else {
                            // Fallback for Timestamp if cloud_firestore is in scope elsewhere
                            timestamp = (rawTs as dynamic)?.toDate?.call() ?? order.createdAt;
                          }
                        } catch (_) {
                          timestamp = order.createdAt;
                        }
                      }
                      final amountVal = proof['amount'];
                      final double amount = amountVal is num
                          ? amountVal.toDouble()
                          : double.tryParse(amountVal?.toString() ?? '') ?? 0.0;
                      return JMCard(
                        margin: const EdgeInsets.only(bottom: JMSpacing.sm),
                        child: Padding(
                          padding: const EdgeInsets.all(JMSpacing.md),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Amount: \$${amount.toStringAsFixed(2)}'),
                              Text('Method: ${proof['method'] ?? 'N/A'}'),
                              Text('Date: ${timestamp.toLocal().toIso8601String().split('T').first}'),
                              Text('Time: ${timestamp.toLocal().hour.toString().padLeft(2, '0')}:${timestamp.toLocal().minute.toString().padLeft(2, '0')}'),
                              if (proof['imageUrl'] != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: JMSpacing.sm),
                                  child: Image.network(
                                    proof['imageUrl'],
                                    height: 100,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => const Text('Image not available'),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ],

                  const SizedBox(height: JMSpacing.lg),
                  // Chat Button Integration (visible to relevant users)
                  // In a real app, you'd check user roles (engineer/supplier) and participation in the order
                  if (_currentUserId != null && _otherUserId != null) // Only show if user IDs are determined
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatScreen(
                                orderId: widget.orderId,
                                currentUserId: _currentUserId!,
                                // The ChatScreen needs to be updated to accept a receiverId or handle it internally.
                                // For now, it uses the stream based on orderId.
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.chat),
                        label: const Text('Open Order Chat'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                          textStyle: const TextStyle(fontSize: 18),
                        ),
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
}
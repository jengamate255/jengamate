import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../models/order_model.dart';
import 'package:jengamate/services/payment_service.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/error_display.dart';
import 'package:image_picker/image_picker.dart';
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
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _amountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _paymentService = Provider.of<PaymentService>(context, listen: false);
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      // In a real app, you would upload this image to Firebase Storage
      // and get a downloadable URL. For this example, we'll just use a placeholder.
      final String imageUrl = 'gs://your-firebase-project.appspot.com/payment_proofs/${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      // For demonstration, we'll assume a successful upload and use a dummy URL
      // You would replace this with actual Firebase Storage upload logic
      // Example:
      // final ref = firebase_storage.FirebaseStorage.instance.ref().child('payment_proofs/${image.name}');
      // await ref.putFile(File(image.path));
      // final imageUrl = await ref.getDownloadURL();

      _uploadPaymentProof(imageUrl);
    }
  }

  Future<void> _uploadPaymentProof(String imageUrl) async {
    if (_amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the payment amount.')),
      );
      return;
    }

    final double amount = double.tryParse(_amountController.text) ?? 0.0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid payment amount.')),
      );
      return;
    }

    try {
      await _paymentService.uploadPaymentProof(
        widget.orderId,
        {
          'amount': amount,
          'imageUrl': imageUrl,
          'method': 'Bank Transfer/M-Pesa', // Example method
        },
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment proof uploaded successfully!')),
      );
      _amountController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload payment proof: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Payment'),
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

          return SingleChildScrollView(
            child: AdaptivePadding(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Order ID: ${order.id}', style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: JMSpacing.xs),
                  Text('Total Order Amount: TSh ${order.totalAmount.toStringAsFixed(2)}', style: Theme.of(context).textTheme.titleLarge),
                  Text('Amount Paid: TSh ${order.amountPaid?.toStringAsFixed(2) ?? '0.00'}', style: Theme.of(context).textTheme.titleMedium),
                  Text('Remaining Balance: TSh ${(order.totalAmount - (order.amountPaid ?? 0.0)).toStringAsFixed(2)}', style: Theme.of(context).textTheme.titleMedium),
                  Text('Status: ${order.statusDisplayName}', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: JMSpacing.lg),
                  
                  Text('Upload Payment Proof:', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: JMSpacing.sm),
                  TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Amount Paid',
                      border: OutlineInputBorder(),
                      prefixText: 'TSh ',
                    ),
                  ),
                  const SizedBox(height: JMSpacing.md),
                  ElevatedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Upload Payment Screenshot'),
                  ),
                  const SizedBox(height: JMSpacing.lg),

                  if (order.paymentProofs != null && order.paymentProofs!.isNotEmpty) ...[
                    Text('Payment Records:', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: JMSpacing.sm),
                    ...order.paymentProofs!.map((proof) {
                      final rawTs = proof['timestamp'] ?? proof['uploadedAt'];
                      DateTime timestamp;
                      if (rawTs is Timestamp) {
                        timestamp = rawTs.toDate();
                      } else if (rawTs is String) {
                        timestamp = DateTime.tryParse(rawTs) ?? order.createdAt;
                      } else if (rawTs is DateTime) {
                        timestamp = rawTs;
                      } else {
                        timestamp = order.createdAt;
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
                              Text('Amount: TSh ${amount.toStringAsFixed(2)}'),
                              Text('Method: ${proof['method'] ?? 'N/A'}'),
                              Text('Date: ${timestamp.toLocal().toIso8601String().split('T').first}'),
                              Text('Time: ${timestamp.toLocal().hour}:${timestamp.toLocal().minute.toString().padLeft(2, '0')}'),
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
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
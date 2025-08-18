import 'package:flutter/material.dart';
import 'package:jengamate/models/order_model.dart';
import 'package:jengamate/models/payment_model.dart';
import 'package:intl/intl.dart';

class PaymentHistoryScreen extends StatelessWidget {
  final OrderModel order;

  const PaymentHistoryScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final payments = (order.paymentProofs ?? [])
        .map((p) => PaymentModel.fromMap(p))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment History'),
      ),
      body: ListView.builder(
        itemCount: payments.length,
        itemBuilder: (context, index) {
          final payment = payments[index];
          return Card(
            margin: const EdgeInsets.all(8.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Amount: ${NumberFormat.currency(symbol: 'TSh ').format(payment.amount)}',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text('Date: ${DateFormat.yMd().format(payment.createdAt)}'),
                  Text('Method: ${payment.method.name}'),
                  if (payment.referenceNumber != null)
                    Text('Reference: ${payment.referenceNumber}'),
                  if (payment.proofUrl != null)
                    TextButton(
                      onPressed: () {
                        // TODO: Implement view proof of payment
                      },
                      child: const Text('View Proof of Payment'),
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
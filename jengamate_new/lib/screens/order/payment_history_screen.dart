import 'package:flutter/material.dart';
import 'package:jengamate/models/payment_model.dart';
import 'package:intl/intl.dart';
import 'package:jengamate/services/database_service.dart';
import 'package:jengamate/services/auth_service.dart';

class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    final userId = _authService.currentUser?.uid;

    if (userId == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Payment History'),
        ),
        body: const Center(
          child: Text('User not authenticated.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment History'),
      ),
      body: StreamBuilder<List<PaymentModel>>(
        stream: _databaseService.streamPayments(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No payment history found.'));
          }

          final payments = snapshot.data!;
          return ListView.builder(
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
                      Text(
                          'Date: ${DateFormat.yMd().format(payment.createdAt)}'),
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
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:jengamate/models/payment_model.dart';
import 'package:intl/intl.dart';
import 'package:jengamate/services/database_service.dart';
import 'package:jengamate/services/auth_service.dart';
import 'package:jengamate/screens/payment/payment_details_screen.dart'; // Import the new screen
import 'package:url_launcher/url_launcher.dart'; // Import url_launcher
import 'package:jengamate/services/console_error_handler.dart'; // Import ConsoleErrorHandler
import 'package:provider/provider.dart';
import 'package:jengamate/services/user_state_provider.dart'; // Import Provider
import 'package:jengamate/models/user_model.dart'; // Import UserModel
import 'package:jengamate/services/payment_service.dart'; // Keep this for later if needed, otherwise remove

class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final AuthService _authService = AuthService();

  Future<void> _downloadPaymentProof(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      ConsoleErrorHandler.report('Could not launch $url', StackTrace.current);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open payment proof.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = _authService.currentUser?.uid;
    final currentUser = context.watch<UserModel?>(); // Access the current user
    final isAdmin = currentUser?.role == UserRole.admin;

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
                      Text('Method: ${payment.paymentMethod}'),
                      if (payment.transactionId != null)
                        Text('Reference: ${payment.transactionId}'),
                      if (payment.paymentProofUrl != null) ...[
                        if (isAdmin)
                          TextButton(
                            onPressed: () => _downloadPaymentProof(payment.paymentProofUrl!),
                            child: const Text('Download Proof of Payment'),
                          ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PaymentDetailsScreen(
                                    paymentId: payment.id), // Navigate to details screen
                              ),
                            );
                          },
                          child: const Text('View Details'),
                        ),
                      ],
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

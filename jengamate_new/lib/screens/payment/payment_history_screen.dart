import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:jengamate/models/payment_model.dart';
import 'package:jengamate/models/user_model.dart';
import 'package:jengamate/models/enums/user_role.dart'; // Explicitly import UserRole
import 'package:jengamate/services/payment_service.dart';
import 'package:provider/provider.dart';
import 'package:jengamate/services/user_state_provider.dart';
import 'dart:html' as html;
import 'package:url_launcher/url_launcher.dart';

class PaymentHistoryScreen extends StatefulWidget {
  final String? userId; // Optional: to view a specific user's payments
  const PaymentHistoryScreen({Key? key, this.userId}) : super(key: key);

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  late PaymentService _paymentService;

  @override
  void initState() {
    super.initState();
    _paymentService = PaymentService();
  }

  // Function to download payment proof
  void _downloadPaymentProof(String url) async {
    if (kIsWeb) {
      html.AnchorElement anchorElement = html.AnchorElement(href: url);
      anchorElement.download = url.split('/').last;
      anchorElement.click();
    } else {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch $url')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userState = Provider.of<UserStateProvider>(context);
    final currentUser = userState.currentUser;
    final bool isAdmin = currentUser?.role == UserRole.admin;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.userId != null
            ? 'Payments for ${widget.userId!.substring(0, 8)}...'
            : 'Payment History'),
      ),
      body: StreamBuilder<List<PaymentModel>>(
        stream: widget.userId != null
            ? _paymentService.streamUserPayments(widget.userId!)
            : _paymentService.streamAllPayments(), // Use streamAllPayments when userId is null
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
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Amount: ${NumberFormat.currency(symbol: 'TSh ', decimalDigits: 2).format(payment.amount)}',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text('Method: ${payment.paymentMethod}'),
                      Text('Status: ${payment.status.name}'),
                      Text(
                          'Date: ${DateFormat('yyyy-MM-dd HH:mm').format(payment.createdAt)}'),
                      if (payment.paymentProofUrl != null && isAdmin)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: ElevatedButton.icon(
                            onPressed: () =>
                                _downloadPaymentProof(payment.paymentProofUrl!),
                            icon: const Icon(Icons.download),
                            label: const Text('Download Proof'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              foregroundColor: Theme.of(context).colorScheme.onPrimary,
                            ),
                          ),
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

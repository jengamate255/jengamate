import 'package:flutter/material.dart';

class InvoiceDetailsScreen extends StatelessWidget {
  final String orderId;

  const InvoiceDetailsScreen({Key? key, required this.orderId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoice Details'),
      ),
      body: Center(
        child: Text('Invoice for Order ID: $orderId'),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:jengamate/models/invoice_model.dart';

class EditInvoiceScreen extends StatefulWidget {
  final InvoiceModel invoice;

  const EditInvoiceScreen({Key? key, required this.invoice}) : super(key: key);

  @override
  State<EditInvoiceScreen> createState() => _EditInvoiceScreenState();
}

class _EditInvoiceScreenState extends State<EditInvoiceScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Invoice ${widget.invoice.invoiceNumber}'),
      ),
      body: const Center(
        child: Text('Edit Invoice Form will go here'),
      ),
    );
  }
}

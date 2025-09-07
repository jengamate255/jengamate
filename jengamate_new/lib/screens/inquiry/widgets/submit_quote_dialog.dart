import 'package:jengamate/models/inquiry.dart';
import 'package:flutter/material.dart';
import 'package:jengamate/models/quote_model.dart';
import 'package:jengamate/services/database_service.dart';
import 'package:jengamate/models/user_model.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SubmitQuoteDialog extends StatefulWidget {
  final Inquiry inquiry;

  const SubmitQuoteDialog({super.key, required this.inquiry});

  @override
  State<SubmitQuoteDialog> createState() => _SubmitQuoteDialogState();
}

class _SubmitQuoteDialogState extends State<SubmitQuoteDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _detailsController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = Provider.of<UserModel?>(context);
    final dbService = DatabaseService();

    return AlertDialog(
      title: const Text('Submit Quote'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _amountController,
              decoration:
                  const InputDecoration(labelText: 'Quote Amount (TSH)'),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a quote amount';
                }
                if (double.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
                return null;
              },
            ),
            TextFormField(
              controller: _detailsController,
              decoration: const InputDecoration(labelText: 'Quote Details'),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter quote details';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              if (currentUser == null) {
                // Handle case where user is not logged in
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content:
                          Text('You must be logged in to submit a quote.')),
                );
                return;
              }

              final newQuote = QuoteModel(
                id: FirebaseFirestore.instance.collection('quotes').doc().id,
                rfqId: widget.inquiry.uid,
                supplierId: currentUser.uid,
                price: double.parse(_amountController.text),
                notes: _detailsController.text,
                deliveryDate: DateTime.now().add(const Duration(days: 7)),
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              );

              await dbService.createQuote(newQuote);

              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Quote submitted successfully!')),
                );
              }
            }
          },
          child: const Text('Submit Quote'),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:jengamate/models/quote_model.dart';
import 'package:jengamate/services/database_service.dart';

class QuoteSubmissionForm extends StatefulWidget {
  final String rfqId;

  const QuoteSubmissionForm({super.key, required this.rfqId});

  @override
  State<QuoteSubmissionForm> createState() => _QuoteSubmissionFormState();
}

class _QuoteSubmissionFormState extends State<QuoteSubmissionForm> {
  final _formKey = GlobalKey<FormState>();
  final _dbService = DatabaseService();

  double _price = 0.0;
  DateTime _deliveryDate = DateTime.now();
  String _notes = '';

  void _submitQuote() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final newQuote = QuoteModel(
        id: '',
        rfqId: widget.rfqId,
        supplierId: '', // This will be replaced with the actual supplier ID
        price: _price,
        deliveryDate: _deliveryDate,
        notes: _notes,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      _dbService.createQuote(newQuote).then((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Quote submitted successfully')),
        );
        Navigator.pop(context);
      }).catchError((error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting quote: $error')),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          TextFormField(
            decoration: const InputDecoration(labelText: 'Price'),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a price';
              }
              return null;
            },
            onSaved: (value) => _price = double.parse(value!),
          ),
          const SizedBox(height: 16),
          TextFormField(
            decoration: const InputDecoration(labelText: 'Notes'),
            onSaved: (value) => _notes = value!,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _submitQuote,
            child: const Text('Submit Quote'),
          ),
        ],
      ),
    );
  }
}
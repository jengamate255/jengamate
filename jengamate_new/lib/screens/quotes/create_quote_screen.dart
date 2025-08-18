import 'package:flutter/material.dart';
import 'package:jengamate/models/quote_model.dart';
import 'package:jengamate/models/rfq_model.dart';
import 'package:jengamate/services/database_service.dart';

class CreateQuoteScreen extends StatefulWidget {
  final RFQModel rfq;

  const CreateQuoteScreen({super.key, required this.rfq});

  @override
  State<CreateQuoteScreen> createState() => _CreateQuoteScreenState();
}

class _CreateQuoteScreenState extends State<CreateQuoteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _priceController = TextEditingController();
  final _notesController = TextEditingController();
  final dbService = DatabaseService();

  @override
  void dispose() {
    _priceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submitQuote() {
    if (_formKey.currentState!.validate()) {
      final quote = QuoteModel(
        id: '', // Will be set by Firestore
        rfqId: widget.rfq.id,
        supplierId: '', // Will be set from the current user
        price: double.tryParse(_priceController.text) ?? 0.0,
        notes: _notesController.text,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      dbService.createQuote(quote).then((_) {
        dbService.updateRFQStatus(widget.rfq.id, 'Responded');
        Navigator.of(context).pop();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Quote'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'Price'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a price';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(labelText: 'Notes'),
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitQuote,
                child: const Text('Submit Quote'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

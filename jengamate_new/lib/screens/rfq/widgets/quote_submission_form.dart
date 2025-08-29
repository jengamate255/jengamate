import 'package:flutter/material.dart';
import 'package:jengamate/models/quote_model.dart';
import 'package:jengamate/services/database_service.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import FirebaseAuth
import 'package:provider/provider.dart'; // Import Provider
import 'package:jengamate/services/auth_service.dart'; // Import AuthService
import 'package:jengamate/utils/logger.dart'; // Import Logger

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

  void _submitQuote() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final authService = Provider.of<AuthService>(context, listen: false);
      final currentUser = authService.currentUser;

      // Enhanced error checking and logging
      Logger.log('Starting quote submission process...');
      Logger.log('Current user: $currentUser');
      Logger.log('Current user UID: ${currentUser?.uid}');
      
      if (currentUser == null) {
        Logger.logError('Quote submission failed: User not authenticated', 'No current user', StackTrace.current);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: Please log in to submit a quote.')),
        );
        return;
      }

      if (currentUser.uid.isEmpty) {
        Logger.logError('Quote submission failed: User ID is empty', 'Empty UID', StackTrace.current);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: User ID is missing. Please try logging out and back in.')),
        );
        return;
      }

      Logger.log('Creating quote with supplierId: ${currentUser.uid}');
      final newQuote = QuoteModel(
        id: '',
        rfqId: widget.rfqId,
        supplierId: currentUser.uid, // Use the actual supplier ID
        price: _price,
        deliveryDate: _deliveryDate,
        notes: _notes,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Log the quote data before saving
      Logger.log('Quote data to be saved: ${newQuote.toMap()}');

      try {
        await _dbService.createQuote(newQuote);
        Logger.log('Quote created successfully in database');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Quote submitted successfully')),
        );
        Navigator.pop(context);
      } catch (error) {
        Logger.logError('Failed to create quote', error, StackTrace.current);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting quote: $error')),
        );
      }
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
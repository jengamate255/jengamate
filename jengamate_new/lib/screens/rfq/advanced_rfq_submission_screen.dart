import 'package:flutter/material.dart';
import 'package:jengamate/models/rfq_model.dart';
import 'package:jengamate/services/database_service.dart';

class AdvancedRfqSubmissionScreen extends StatefulWidget {
  const AdvancedRfqSubmissionScreen({super.key});

  @override
  State<AdvancedRfqSubmissionScreen> createState() =>
      _AdvancedRfqSubmissionScreenState();
}

class _AdvancedRfqSubmissionScreenState
    extends State<AdvancedRfqSubmissionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dbService = DatabaseService();

  String _productName = '';
  String _customerName = '';
  String _customerEmail = '';
  String _customerPhone = '';
  String _deliveryAddress = '';
  String _additionalNotes = '';
  int _quantity = 0;

  @override
  void initState() {
    super.initState();
  }

  void _submitRfq() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final newRfq = RFQModel(
        id: '', // Firestore will generate this
        userId: '', // TODO: Replace with actual user ID
        productId: '', // TODO: This needs to be provided, perhaps from a product selection screen
        productName: _productName,
        customerName: _customerName,
        customerEmail: _customerEmail,
        customerPhone: _customerPhone,
        deliveryAddress: _deliveryAddress,
        additionalNotes: _additionalNotes,
        quantity: _quantity,
      );

      try {
        await _dbService.createRFQ(newRfq);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('RFQ submitted successfully')),
        );
        Navigator.pop(context);
      } catch (error) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting RFQ: $error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Submit RFQ'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            TextFormField(
              decoration: const InputDecoration(labelText: 'Product Name'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a product name';
                }
                return null;
              },
              onSaved: (value) => _productName = value!,
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Full Name'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your full name';
                }
                return null;
              },
              onSaved: (value) => _customerName = value!,
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty || !value.contains('@')) {
                  return 'Please enter a valid email';
                }
                return null;
              },
              onSaved: (value) => _customerEmail = value!,
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Phone Number'),
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your phone number';
                }
                return null;
              },
              onSaved: (value) => _customerPhone = value!,
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Delivery Address'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a delivery address';
                }
                return null;
              },
              onSaved: (value) => _deliveryAddress = value!,
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Quantity'),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a quantity';
                }
                if (int.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
                return null;
              },
              onSaved: (value) => _quantity = int.parse(value!),
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Additional Notes (Optional)'),
              onSaved: (value) => _additionalNotes = value ?? '',
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _submitRfq,
              child: const Text('Submit RFQ'),
            ),
          ],
        ),
      ),
    );
  }
}
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
        // Show detailed success confirmation dialog
        await _showSuccessDialog();
        Navigator.pop(context);
      } catch (error) {
        if (!mounted) return;
        // Show detailed error dialog
        await _showErrorDialog(error.toString());
      }
    }
  }

  Future<void> _showSuccessDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          icon: const Icon(
            Icons.check_circle,
            color: Colors.green,
            size: 48,
          ),
          title: const Text(
            'RFQ Submitted Successfully!',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your Request for Quote has been submitted successfully.',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                const Text(
                  'RFQ Details:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                _buildDetailRow('Product:', _productName),
                _buildDetailRow('Quantity:', _quantity.toString()),
                _buildDetailRow('Customer:', _customerName),
                _buildDetailRow('Email:', _customerEmail),
                _buildDetailRow('Phone:', _customerPhone),
                if (_deliveryAddress.isNotEmpty)
                  _buildDetailRow('Delivery Address:', _deliveryAddress),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue.shade600, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'What happens next?',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '• Suppliers will review your RFQ\n'
                        '• You\'ll receive quotes via email and app notifications\n'
                        '• Compare quotes and select the best offer\n'
                        '• Track your RFQ status in the dashboard',
                        style: TextStyle(color: Colors.blue.shade700),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('View My RFQs'),
              onPressed: () {
                Navigator.of(context).pop();
                // TODO: Navigate to user's RFQ list
              },
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showErrorDialog(String error) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          icon: const Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 48,
          ),
          title: const Text(
            'RFQ Submission Failed',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'We encountered an error while submitting your RFQ. Please try again.',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Error Details:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        error.length > 200 ? '${error.substring(0, 200)}...' : error,
                        style: TextStyle(color: Colors.red.shade700, fontSize: 14),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.lightbulb_outline, color: Colors.blue.shade600, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Suggestions:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '• Check your internet connection\n'
                        '• Verify all required fields are filled\n'
                        '• Try refreshing the page\n'
                        '• Contact support if the problem persists',
                        style: TextStyle(color: Colors.blue.shade700),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Contact Support'),
              onPressed: () {
                Navigator.of(context).pop();
                // TODO: Navigate to support/help screen
              },
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Try Again'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
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
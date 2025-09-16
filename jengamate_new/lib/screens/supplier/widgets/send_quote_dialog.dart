import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:jengamate/services/user_state_provider.dart';
import 'package:jengamate/models/product_interaction_model.dart';
import 'package:jengamate/models/user_model.dart';
import 'package:jengamate/services/product_interaction_service.dart';
import 'package:jengamate/services/database_service.dart'; // Assuming DatabaseService has updateRFQStatus

class SendQuoteDialog extends StatefulWidget {
  final RFQTrackingModel rfq;

  const SendQuoteDialog({Key? key, required this.rfq}) : super(key: key);

  @override
  State<SendQuoteDialog> createState() => _SendQuoteDialogState();
}

class _SendQuoteDialogState extends State<SendQuoteDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _quoteAmountController = TextEditingController();
  final TextEditingController _deliveryDateController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  DateTime? _selectedDeliveryDate;
  bool _isLoading = false;
  final ProductInteractionService _interactionService = ProductInteractionService();
  final DatabaseService _databaseService = DatabaseService();

  @override
  void initState() {
    super.initState();
    _quoteAmountController.text = '0.00';
  }

  @override
  void dispose() {
    _quoteAmountController.dispose();
    _deliveryDateController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDeliveryDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null && picked != _selectedDeliveryDate) {
      setState(() {
        _selectedDeliveryDate = picked;
        _deliveryDateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _submitQuote() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = Provider.of<UserStateProvider>(context).currentUser;
      if (currentUser == null) {
        throw Exception('User not logged in.');
      }

      final quoteAmount = double.parse(_quoteAmountController.text);

      await _interactionService.recordQuote(
        rfqId: widget.rfq.rfqId,
        supplierId: currentUser?.uid ?? '',
        quoteAmount: quoteAmount,
        estimatedDeliveryDate: _selectedDeliveryDate,
        notes: _notesController.text,
      );
      // Also update the RFQ status to 'quoted'
      await _databaseService.updateRFQStatus(widget.rfq.rfqId, 'quoted');

      if (!mounted) return;
      Navigator.of(context).pop(true); // Indicate success
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send quote: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Send Quote'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _quoteAmountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Quote Amount',
                  prefixText: 'TSh ',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a quote amount';
                  }
                  if (double.tryParse(value) == null || double.parse(value) <= 0) {
                    return 'Please enter a valid positive amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _deliveryDateController,
                readOnly: true,
                onTap: _pickDate,
                decoration: const InputDecoration(
                  labelText: 'Estimated Delivery Date',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select an estimated delivery date';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Additional Notes (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submitQuote,
          child: _isLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text('Send Quote'),
        ),
      ],
    );
  }
}

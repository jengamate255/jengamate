import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jengamate/services/user_state_provider.dart';
import 'package:intl/intl.dart';
import 'package:jengamate/models/user_model.dart';
import 'package:jengamate/services/payment_service.dart';
import 'package:jengamate/services/console_error_handler.dart';
import 'package:jengamate/ui/design_system/tokens/spacing.dart'; // Import JMSpacing
import 'package:jengamate/ui/design_system/tokens/typography.dart'; // Import JMTypography
import 'package:file_picker/file_picker.dart'; // For file picking
import 'package:firebase_storage/firebase_storage.dart'; // For image upload

class PaymentDialog extends StatefulWidget {
  final String orderId;
  final double totalAmount;
  final double paidAmount;

  const PaymentDialog({
    Key? key,
    required this.orderId,
    required this.totalAmount,
    required this.paidAmount,
  }) : super(key: key);

  @override
  State<PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<PaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();
  String? _selectedPaymentMethod;
  PlatformFile? _pickedFile; // For storing the picked file
  bool _isLoading = false;
  final PaymentService _paymentService = PaymentService();
  final FirebaseStorage _storage = FirebaseStorage.instance;
  // Removed: final DatabaseService _dbService = DatabaseService();

  double get _remainingAmount => widget.totalAmount - widget.paidAmount;

  @override
  void initState() {
    super.initState();
    _amountController.text = _remainingAmount.toStringAsFixed(2);
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );

    if (result != null) {
      setState(() {
        _pickedFile = result.files.first;
      });
    }
  }

  Future<String?> _uploadFile(PlatformFile file, String userId) async {
    try {
      final ref = _storage.ref().child(
          'payment_proofs/$userId/${widget.orderId}/${DateTime.now().millisecondsSinceEpoch}_${file.name}');
      UploadTask uploadTask = ref.putData(file.bytes!); // Use putData for web
      TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      ConsoleErrorHandler.logError('Error uploading payment proof', e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading payment proof: $e')),
      );
      return null;
    }
  }

  Future<void> _submitPayment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_selectedPaymentMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a payment method.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String? proofUrl;
      if (_pickedFile != null) {
        final currentUser = Provider.of<UserStateProvider>(context).currentUser;
        if (currentUser == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User not logged in.')),
          );
          return;
        }
        proofUrl = await _uploadFile(_pickedFile!, currentUser?.uid);
        if (proofUrl == null) {
          setState(() => _isLoading = false);
          return;
        }
      }

      final double amount = double.parse(_amountController.text);
      await _paymentService.createPaymentWithProof(
        orderId: widget.orderId,
        userId: currentUser?.uid,
        amount: amount,
        paymentMethod: _selectedPaymentMethod!,
        transactionId: 'txn_${DateTime.now().millisecondsSinceEpoch}',
        proofBytes: _pickedFile != null ? await _pickedFile!.readAsBytes() : null,
        proofFileName: _pickedFile?.name,
      );

      if (!mounted) return;
      Navigator.of(context).pop(true); // Indicate success
    } catch (e) {
      ConsoleErrorHandler.logError('Error submitting payment', e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting payment: $e')),
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
    final currencyFormat = NumberFormat.currency(symbol: 'TSh ', decimalDigits: 2);

    return AlertDialog(
      title: Text('Record Payment', style: JMTypography.heading2), // Corrected usage
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  'Order ID: ${widget.orderId.substring(0, 8)}...',
                  style: JMTypography.body
              ),
              const SizedBox(height: JMSpacing.xxs),
              Text(
                  'Total Amount: ${currencyFormat.format(widget.totalAmount)}',
                  style: JMTypography.body
              ),
              const SizedBox(height: JMSpacing.xxs),
              Text(
                  'Paid Amount: ${currencyFormat.format(widget.paidAmount)}',
                  style: JMTypography.body
              ),
              const SizedBox(height: JMSpacing.xxs),
              Text(
                  'Remaining Amount: ${currencyFormat.format(_remainingAmount)}',
                  style: JMTypography.bodyBold.copyWith(color: Colors.red)
              ),
              const SizedBox(height: JMSpacing.md),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Amount to Pay',
                  border: OutlineInputBorder(),
                  prefixText: 'TSh ',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an amount';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return 'Please enter a valid amount';
                  }
                  if (amount > _remainingAmount) {
                    return 'Amount exceeds remaining balance';
                  }
                  return null;
                },
              ),
              const SizedBox(height: JMSpacing.md),
              DropdownButtonFormField<String>(
                value: _selectedPaymentMethod,
                decoration: const InputDecoration(
                  labelText: 'Payment Method',
                  border: OutlineInputBorder(),
                ),
                items: ['Bank Transfer', 'M-Pesa', 'Tigo Pesa', 'Airtel Money']
                    .map((method) => DropdownMenuItem(value: method, child: Text(method)))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedPaymentMethod = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Please select a payment method';
                  }
                  return null;
                },
              ),
              const SizedBox(height: JMSpacing.md),
              ElevatedButton.icon(
                onPressed: _pickFile,
                icon: const Icon(Icons.upload_file),
                label: Text(_pickedFile != null ? _pickedFile!.name : 'Upload Proof of Payment'),
              ),
              if (_pickedFile != null)
                Padding(
                  padding: const EdgeInsets.only(top: JMSpacing.sm),
                  child: Text('Selected file: ${_pickedFile!.name}'),
                ),
              const SizedBox(height: JMSpacing.lg),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false), // Indicate cancellation
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submitPayment,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Record Payment'),
        ),
      ],
    );
  }
}

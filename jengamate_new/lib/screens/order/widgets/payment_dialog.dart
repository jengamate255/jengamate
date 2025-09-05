import 'package:flutter/material.dart';
import 'package:jengamate/services/database_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:jengamate/models/order_model.dart';
import 'package:jengamate/models/enums/order_enums.dart';

class PaymentDialog extends StatefulWidget {
  final String orderId;
  const PaymentDialog({super.key, required this.orderId});

  @override
  State<PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<PaymentDialog> {
  final TextEditingController _referenceController = TextEditingController();
  final DatabaseService _dbService = DatabaseService();
  PlatformFile? _pickedFile;

  @override
  void dispose() {
    _referenceController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      withData: true,
    );
    if (result != null) {
      setState(() {
        _pickedFile = result.files.first;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Bank Transfer Details'),
      content: SingleChildScrollView(
        child: ListBody(
          children: <Widget>[
            const Text(
              'Please transfer the total amount to the following bank account:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text('Bank Name: Equity Bank'),
            const Text('Account Name: JengaMate Ltd'),
            const Text('Account Number: 1234567890'),
            const SizedBox(height: 16),
            FutureBuilder<OrderModel?>(
              future: _dbService.getOrderByID(widget.orderId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError || !snapshot.hasData) {
                  return const Center(
                      child: Text('Error loading order details.'));
                }
                final order = snapshot.data!;
                return Text(
                  'Total Amount: ${order.totalAmount}',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                );
              },
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _referenceController,
              decoration: const InputDecoration(
                labelText: 'Bank Transfer Reference (Optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _pickFile,
              icon: const Icon(Icons.attach_file),
              label: const Text('Upload Proof of Payment'),
            ),
            if (_pickedFile != null)
              Text('File selected: ${_pickedFile!.name}'),
            // TODO: Add support for multiple file uploads
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('Cancel'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        ElevatedButton(
          child: const Text('I Have Completed the Transfer'),
          onPressed: () async {
            String? proofOfPaymentUrl;
            if (_pickedFile != null) {
              final bytes = _pickedFile!.bytes;
              if (bytes == null) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text(
                            'Failed to read file bytes. Please try again.')),
                  );
                }
                return;
              } else {
                proofOfPaymentUrl = await _dbService.uploadFile(
                  bytes,
                  'proof_of_payment/${widget.orderId}/${_pickedFile!.name}',
                );
              }
            }

            final currentOrder = await _dbService.getOrderByID(widget.orderId);
            if (currentOrder != null) {
              final updatedOrder = currentOrder.copyWith(
                metadata: {
                  ...(currentOrder.metadata ?? {}),
                  'paymentMethod': 'Bank Transfer',
                  'bankTransferReference': _referenceController.text.trim(),
                },
                status: OrderStatus.processing,
                paymentProofs: [
                  ...((currentOrder.paymentProofs) ?? []),
                  if (proofOfPaymentUrl != null)
                    {
                      'url': proofOfPaymentUrl,
                      'uploadedAt': DateTime.now().toIso8601String(),
                      'fileName': _pickedFile?.name,
                    },
                ],
              );
              await _dbService.updateOrder(updatedOrder);
            }

            if (mounted) {
              Navigator.of(context).pop();
            }
          },
        ),
      ],
    );
  }
}

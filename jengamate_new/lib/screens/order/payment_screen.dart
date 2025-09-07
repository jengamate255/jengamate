import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:jengamate/models/payment_model.dart';
import 'package:jengamate/services/auth_service.dart';
import 'package:jengamate/services/payment_service.dart';
import 'package:jengamate/services/supabase_storage_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:jengamate/models/enums/payment_enums.dart';
import 'package:jengamate/utils/logger.dart'; // Import Logger

class PaymentScreen extends StatefulWidget {
  final String orderId;

  const PaymentScreen({Key? key, required this.orderId}) : super(key: key);

  @override
  _PaymentScreenState createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final AuthService _authService = AuthService();
  final PaymentService _paymentService = PaymentService();
  // Use Supabase for storing payment proof images
  final SupabaseStorageService _storageService = SupabaseStorageService(
    supabaseClient: Supabase.instance.client,
    bucket: 'payment_proofs',
  );

  @override
  void initState() {
    super.initState();
    _initializeSupabaseAuth();
  }

  Future<void> _initializeSupabaseAuth() async {
    final firebaseUser = _authService.currentUser;
    if (firebaseUser != null) {
      final idToken = await firebaseUser.getIdToken();
      if (idToken != null) {
        try {
          await _authService.signInSupabaseWithFirebaseToken(idToken);
        } catch (e) {
          Logger.logError('Failed to sign in Supabase with Firebase token', e);
        }
      }
    }
  }

  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  List<XFile> _paymentProofs = [];
  PaymentMethod _selectedMethod = PaymentMethod.bankTransfer;
  bool _isLoading = false;

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _paymentProofs.add(pickedFile);
      });
    }
  }

  Future<void> _takePhoto() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      setState(() {
        _paymentProofs.add(pickedFile);
      });
    }
  }

  void _removePaymentProof(int index) {
    setState(() {
      _paymentProofs.removeAt(index);
    });
  }

  Future<void> _submitPayment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Get user ID from Firebase (always available if user is logged in)
      final firebaseUser = _authService.currentUser;
      if (firebaseUser == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please log in to make payment')),
          );
        }
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final userId = firebaseUser.uid; // Use Firebase user ID
      String? proofUrl;

      // Handle payment proof upload (optional if Supabase not authenticated)
      if (_paymentProofs.isNotEmpty) {
        try {
          final supabaseUser = Supabase.instance.client.auth.currentUser;
          if (supabaseUser == null) {
            // Attempt to re-initialize Supabase auth
            await _initializeSupabaseAuth();
          }

          // Check if Supabase auth worked
          final currentSupabaseUser = Supabase.instance.client.auth.currentUser;
          if (currentSupabaseUser != null) {
            // Upload payment proof to Supabase
            final proofFile = _paymentProofs.first;
            final proofBytes = await proofFile.readAsBytes();
            proofUrl = await _storageService.uploadFile(
              fileName: proofFile.name,
              folder: widget.orderId,
              bytes: proofBytes,
            );
          } else {
            // Supabase not authenticated - skip upload and log warning
            Logger.logError(
                'Payment proof upload skipped - Supabase not authenticated');
            proofUrl = null; // Payment can proceed without proof
          }
        } catch (storageError) {
          // Log but don't block payment submission
          Logger.logError(
              'Payment proof upload failed, continuing without proof: $storageError');
          proofUrl = null;
        }
      }

      // Create payment with or without proof URL
      final payment = PaymentModel(
        id: '',
        orderId: widget.orderId,
        userId: userId,
        amount: double.parse(_amountController.text),
        status: PaymentStatus.pending,
        paymentMethod: _selectedMethod.name,
        transactionId: null,
        paymentProofUrl: proofUrl,
        createdAt: DateTime.now(),
        completedAt: null,
        metadata: {
          'notes': _notesController.text,
          if (proofUrl == null && _paymentProofs.isNotEmpty)
            'payment_proof_skipped': 'Supabase authentication failed',
        },
      );

      final paymentId = await _paymentService.createPayment(payment);
      Logger.log('Payment created with ID: $paymentId');

      if (mounted) {
        String successMessage;
        if (proofUrl != null) {
          successMessage = 'Payment submitted successfully with proof';
        } else if (_paymentProofs.isNotEmpty) {
          successMessage =
              'Payment submitted successfully (proof upload skipped)';
        } else {
          successMessage = 'Payment submitted successfully';
        }

        Navigator.pop(context, successMessage); // Pass the message back
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit payment: $e')),
        );
      }
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
    return Scaffold(
      appBar: AppBar(
        title: Text('Make Payment'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildOrderInfo(),
              const SizedBox(height: 20),
              _buildPaymentForm(),
              const SizedBox(height: 20),
              _buildPaymentProofSection(),
              const SizedBox(height: 30),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderInfo() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ListTile(
              title: Text('Order ID'),
              subtitle: Text(widget.orderId.substring(0, 8)),
            ),
            const Divider(),
            ListTile(
              title: Text('Payment Instructions'),
              subtitle: Text(
                'Please make payment to the following account:\n'
                'Bank: Example Bank\n'
                'Account: 1234567890\n'
                'Name: JengaMate Ltd\n'
                'Reference: Order-${widget.orderId.substring(0, 8)}',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentForm() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Payment Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Amount',
                prefixText: 'TSh ',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter amount';
                }
                final amount = double.tryParse(value);
                if (amount == null || amount <= 0) {
                  return 'Please enter valid amount';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<PaymentMethod>(
              value: _selectedMethod,
              decoration: const InputDecoration(
                labelText: 'Payment Method',
                border: OutlineInputBorder(),
              ),
              items: PaymentMethod.values.map((method) {
                return DropdownMenuItem(
                  value: method,
                  child: Text(method.name),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedMethod = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (Optional)',
                border: OutlineInputBorder(),
                hintText: 'Add any additional information about your payment',
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentProofSection() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Payment Proof',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'Please upload a screenshot or photo of your payment confirmation',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Choose from Gallery'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _takePhoto,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Take Photo'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_paymentProofs.isNotEmpty)
              FutureBuilder<Uint8List?>(
                future: _paymentProofs.first.readAsBytes(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return Container(
                      height: 200,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: kIsWeb
                            ? Image.memory(
                                snapshot.data!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                              )
                            : Image.file(
                                File(_paymentProofs.first.path),
                                fit: BoxFit.cover,
                                width: double.infinity,
                              ),
                      ),
                    );
                  } else if (snapshot.hasError) {
                    return Container(
                      height: 200,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.red),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error, color: Colors.red, size: 48),
                            SizedBox(height: 8),
                            Text('Failed to load image'),
                          ],
                        ),
                      ),
                    );
                  }
                  return Container(
                    height: 200,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(child: CircularProgressIndicator()),
                  );
                },
              )
            else
              Container(
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.cloud_upload, size: 48, color: Colors.grey),
                      SizedBox(height: 8),
                      Text('No image selected'),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submitPayment,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text(
                'Submit Payment',
                style: TextStyle(fontSize: 16),
              ),
      ),
    );
  }
}

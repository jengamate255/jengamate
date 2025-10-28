import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:jengamate/services/auth_service.dart';
import 'package:jengamate/services/payment_service.dart';
import 'package:jengamate/models/enums/payment_enums.dart';
import 'package:jengamate/utils/logger.dart';
import 'package:jengamate/utils/string_utils.dart';
import 'dart:io';

class PaymentScreen extends StatefulWidget {
  final String orderId;

  const PaymentScreen({Key? key, required this.orderId}) : super(key: key);

  @override
  _PaymentScreenState createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final AuthService _authService = AuthService();
  final PaymentService _paymentService = PaymentService();

  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _transactionIdController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Pre-populate with dummy transaction ID for testing
    _generateDummyTransactionId();

    // Debug order ID to help identify issues
    _debugOrderId();
  }

  XFile? _selectedProofFile;
  Uint8List? _proofBytes;
  PaymentMethod _selectedMethod = PaymentMethod.bankTransfer;
  bool _isLoading = false;
  bool _isProcessing = false;
  String? _processingStatus;
  double _processingProgress = 0.0;

  @override
  void dispose() {
    _amountController.dispose();
    _transactionIdController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  /// Validate UUID format (temporarily bypassed)
  // bool _isValidUUID(String value) {
  //   if (value.isEmpty) return false;

  //   // UUID v4 regex pattern
  //   final uuidRegex = RegExp(
  //     r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
  //     caseSensitive: false,
  //   );

  //   return uuidRegex.hasMatch(value);
  // }

  /// Check if payment proof storage is properly configured
  /// This helps debug storage issues
  Future<void> _checkStorageConfiguration() async {
    try {
      // This would be used for debugging storage bucket configuration
      // For now, we'll rely on the payment service to handle storage
      Logger.log('Payment proof storage: Using Supabase storage bucket "payment_proofs"');
    } catch (e) {
      Logger.logError('Storage configuration check failed', e, StackTrace.current);
    }
  }

  // Ensure the storage check runs once for debugging during init
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkStorageConfiguration();
  }

  /// Debug method to log order ID information
  void _debugOrderId() {
    Logger.log('PaymentScreen Debug - Order ID: ${widget.orderId}');
    Logger.log('PaymentScreen Debug - Order ID Length: ${widget.orderId.length}');
    Logger.log('PaymentScreen Debug - Order ID Pattern: ${widget.orderId.contains(RegExp(r'^[A-Za-z0-9]{28}$')) ? 'Firebase User ID' : 'Other Format'}');

    // Check if it's a valid UUID using PaymentService static method
    final isValid = PaymentService.isValidUUID(widget.orderId);
    Logger.log('PaymentScreen Debug - Is Valid UUID: $isValid');
  }

  /// Generate dummy transaction ID for testing payment proof functionality
  void _generateDummyTransactionId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomSuffix = (timestamp % 10000).toString().padLeft(4, '0');
    final dummyId = 'TXN_TEST_$randomSuffix';
    _transactionIdController.text = dummyId;
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        if (kIsWeb) {
          _proofBytes = await pickedFile.readAsBytes();
        }
        setState(() {
          _selectedProofFile = pickedFile;
        });
        Logger.log('Payment proof selected from gallery: ${pickedFile.name}');
      }
    } catch (e, stackTrace) {
      Logger.logError('Failed to pick image', e, stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to select image: $e')),
        );
      }
    }
  }

  Future<void> _takePhoto() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        if (kIsWeb) {
          _proofBytes = await pickedFile.readAsBytes();
        }
        setState(() {
          _selectedProofFile = pickedFile;
        });
        Logger.log('Payment proof captured from camera: ${pickedFile.name}');
      }
    } catch (e, stackTrace) {
      Logger.logError('Failed to take photo', e, stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to take photo: $e')),
        );
      }
    }
  }

  Future<void> _clearProof() async {
    setState(() {
      _selectedProofFile = null;
      _proofBytes = null;
    });
  }

  Future<void> _submitPayment() async {
    // Temporarily bypass form validation
    // if (!_formKey.currentState!.validate()) {
    //   return;
    // }

    // Remove local UUID validation - let PaymentService handle it with RPC lookup
    // The PaymentService will attempt RPC lookup for non-UUID order IDs

              // Payment proof is optional but recommended for verification
              // We'll still attempt to upload it if provided

    setState(() {
      _isProcessing = true;
      _processingStatus = 'Initializing payment...';
      _processingProgress = 0.1;
    });

    try {
      // Get authenticated user
      final firebaseUser = _authService.currentUser;
      if (firebaseUser == null) {
        throw Exception('User authentication required');
      }

      final userId = firebaseUser.uid;
      final amount = double.tryParse(_amountController.text) ?? 0.0;
      // Prefer server-generated transaction id; pass empty string to let server backfill
      final transactionId = _transactionIdController.text.trim().isNotEmpty
          ? _transactionIdController.text.trim()
          : '';

      setState(() {
        _processingStatus = 'Uploading payment proof to server...';
        _processingProgress = 0.3;
      });

      // Use the robust payment service with improved error handling
      final paymentResult = await _paymentService.createPaymentWithProof(
        orderId: widget.orderId,
        userId: userId,
        amount: amount,
        paymentMethod: _selectedMethod,
        transactionId: transactionId,
        notes: _notesController.text.trim().isNotEmpty ? _notesController.text : null,
        proofBytes: kIsWeb ? _proofBytes : null,
        proofFile: !kIsWeb && _selectedProofFile != null ? File(_selectedProofFile!.path) : null,
        proofFileName: _selectedProofFile?.name,
        maxRetries: 3,
      );

      setState(() {
        _processingStatus = 'Processing payment...';
        _processingProgress = 0.8;
      });

      if (!paymentResult.success) {
        // Handle different error types with specific user messages
        String errorMessage;
        Color snackBarColor = Colors.red;

        switch (paymentResult.error) {
          case PaymentError.proofUploadFailed:
            errorMessage = 'Payment proof upload to server failed. Payment recorded without proof. You can upload proof later.';
            snackBarColor = Colors.orange;
            break;
          case PaymentError.validationFailed:
            // Check if it's a UUID validation error
            if (paymentResult.message?.contains('Firebase user ID detected') ?? false) {
              errorMessage = 'Navigation error: Please go back to the order details page and click "Make Payment" from there.';
              snackBarColor = Colors.orange;
            } else if (paymentResult.message?.contains('Invalid order ID format') ?? false) {
              errorMessage = 'Invalid order format. Please contact support or try again.';
              snackBarColor = Colors.red;
            } else {
              errorMessage = 'Payment validation failed. Please check your input details.';
            }
            break;
          case PaymentError.databaseError:
            // Check if it's a UUID database error
            if (paymentResult.message?.contains('invalid input syntax for type uuid') ?? false) {
              errorMessage = 'Order data format error. Please contact support.';
              snackBarColor = Colors.red;
            } else {
              errorMessage = 'Database error occurred. Please contact support if this persists.';
            }
            break;
          case PaymentError.orderNotFound:
            errorMessage = 'Order not found. Please refresh and try again.';
            break;
          case PaymentError.userNotFound:
            errorMessage = 'User authentication error. Please log out and log back in.';
            break;
          default:
            errorMessage = paymentResult.message ?? 'An unexpected error occurred';
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: snackBarColor,
              duration: const Duration(seconds: 8),
              action: paymentResult.error == PaymentError.proofUploadFailed
                  ? SnackBarAction(
                      label: 'Retry',
                      textColor: Colors.white,
                      onPressed: _submitPayment,
                    )
                  : null,
            ),
          );
        }

        // Log the error for monitoring
        Logger.logError('Payment submission failed', paymentResult.message, StackTrace.current);
        return;
      }

      setState(() {
        _processingStatus = 'Payment completed successfully!';
        _processingProgress = 1.0;
      });

      // Show success message
      if (mounted) {
        String successMessage;
        if (paymentResult.proofUrl != null) {
          successMessage = 'Payment submitted successfully with proof stored on server';
        } else {
          successMessage = 'Payment submitted successfully';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(successMessage),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );

        // Navigate back after a short delay
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          Navigator.pop(context, successMessage);
        }
      }

    } catch (e, stackTrace) {
      Logger.logError('Unexpected error during payment submission', e, stackTrace);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An unexpected error occurred: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 8),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _submitPayment,
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _processingStatus = null;
          _processingProgress = 0.0;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Make Payment'),
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
            const Text(
              'Order Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ListTile(
              title: const Text('Order ID'),
              subtitle: Text(safePrefix(widget.orderId, 8)),
            ),
            const Divider(),
            ListTile(
              title: const Text('Payment Instructions'),
              subtitle: Text(
                'Please make payment to the following account:\n'
                'Bank: Example Bank\n'
                'Account: 1234567890\n'
                'Name: JengaMate Ltd\n'
                'Reference: Order-${safePrefix(widget.orderId, 8)}',
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
                labelText: 'Amount (TSh)',
                prefixText: 'TSh ',
                border: OutlineInputBorder(),
                hintText: 'Enter the payment amount',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                // Temporarily bypass amount validation
                // if (value == null || value.isEmpty) {
                //   return 'Please enter amount';
                // }
                // final amount = double.tryParse(value);
                // if (amount == null || amount <= 0) {
                //   return 'Please enter a valid amount greater than 0';
                // }
                // if (amount > 10000000) {
                //   return 'Amount cannot exceed TSh 10,000,000';
                // }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _transactionIdController,
                    decoration: const InputDecoration(
                      labelText: 'Transaction ID/Reference (Dummy data pre-filled)',
                      border: OutlineInputBorder(),
                      hintText: 'Transaction reference for payment proof testing',
                    ),
                    validator: (value) {
                      // Temporarily bypass transaction ID validation
                      // if (value == null || value.trim().isEmpty) {
                      //   return 'Please enter transaction ID';
                      // }
                      // if (value.trim().length < 3) {
                      //   return 'Transaction ID must be at least 3 characters';
                      // }
                      // Allow dummy test transaction IDs
                      // if (value.trim().startsWith('TXN_TEST_')) {
                      //   return null; // Valid dummy ID
                      // }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _generateDummyTransactionId,
                  icon: const Icon(Icons.refresh),
                  label: const Text('New ID'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade100,
                    foregroundColor: Colors.blue.shade800,
                  ),
                ),
              ],
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
                  child: Text(_getPaymentMethodDisplayName(method)),
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

  String _getPaymentMethodDisplayName(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.bankTransfer:
        return 'Bank Transfer';
      case PaymentMethod.mobileMoney:
        return 'Mobile Money';
      case PaymentMethod.cash:
        return 'Cash Payment';
      default:
        return method.name;
    }
  }

  Widget _buildPaymentProofSection() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Payment Proof (Optional - Stored on Server)',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: const Text(
                    'Server Storage',
                    style: TextStyle(color: Colors.orange, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Upload a clear screenshot or photo of your payment confirmation. Files are securely stored on our servers for verification. Supported formats: JPEG, PNG, WebP, PDF (max 10MB)',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 16),
            if (_selectedProofFile != null || _proofBytes != null) ...[
              // Selected file preview
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedProofFile?.name ?? 'Payment proof selected',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            _proofBytes != null
                                ? '${(_proofBytes!.length / 1024).round()} KB'
                                : 'File ready for upload',
                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _clearProof,
                      icon: const Icon(Icons.clear, color: Colors.red),
                      tooltip: 'Remove proof',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            // File selection buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isProcessing ? null : _pickImage,
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Choose File'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isProcessing ? null : _takePhoto,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Take Photo'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Processing indicator
            if (_isProcessing && _processingStatus != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _processingStatus!,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(value: _processingProgress),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: (_isLoading || _isProcessing) ? null : _submitPayment,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isProcessing
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _processingStatus ?? 'Processing...',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.payment),
                  SizedBox(width: 8),
                  Text(
                    'Submit Payment',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
      ),
    );
  }
}

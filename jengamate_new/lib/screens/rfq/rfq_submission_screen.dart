import 'package:flutter/material.dart';
import 'package:jengamate/utils/logger.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:jengamate/services/database_service.dart';
import 'package:provider/provider.dart';
import 'package:jengamate/utils/validators.dart';
import 'package:jengamate/models/rfq_model.dart';
import 'package:jengamate/utils/responsive.dart';

import 'package:jengamate/utils/logger.dart';
import 'package:jengamate/services/notification_service.dart';
import 'package:jengamate/services/supplier_matching_service.dart';
import 'package:jengamate/services/product_interaction_service.dart';
import 'package:jengamate/models/user_model.dart';
import 'package:jengamate/models/product_model.dart';

class RFQSubmissionScreen extends StatefulWidget {
  final String productId;
  final String productName;

  const RFQSubmissionScreen({
    super.key,
    required this.productId,
    required this.productName,
  });

  @override
  State<RFQSubmissionScreen> createState() => _RFQSubmissionScreenState();
}

class _RFQSubmissionScreenState extends State<RFQSubmissionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _customerNameController = TextEditingController();
  final _customerEmailController = TextEditingController();
  final _customerPhoneController = TextEditingController();
  final _deliveryAddressController = TextEditingController();
  final _additionalNotesController = TextEditingController();
  final _quantityController = TextEditingController();
  List<String> _attachments = [];

  final DatabaseService _databaseService = DatabaseService();
  final ProductInteractionService _interactionService = ProductInteractionService();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final currentUser = Provider.of<UserModel?>(context, listen: false);
    if (currentUser != null) {
      final user = await _databaseService.getUser(currentUser.uid);
      if (user != null) {
        if (mounted) {
          setState(() {
            _customerNameController.text = user.displayName;
            _customerEmailController.text = user.email ?? '';
            _customerPhoneController.text = user.phoneNumber ?? '';
            _deliveryAddressController.text = user.address ?? '';
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _customerEmailController.dispose();
    _customerPhoneController.dispose();
    _deliveryAddressController.dispose();
    _additionalNotesController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  void _submitRFQ() async {
    if (_formKey.currentState!.validate()) {
      final currentUser = Provider.of<UserModel?>(context, listen: false);
      final now = DateTime.now();
      final rfq = RFQModel(
        id: FirebaseFirestore.instance.collection('rfqs').doc().id,
        productId: widget.productId,
        productName: widget.productName,
        userId: currentUser?.uid ?? '',
        customerName: _customerNameController.text,
        customerEmail: _customerEmailController.text,
        customerPhone: _customerPhoneController.text,
        deliveryAddress: _deliveryAddressController.text,
        additionalNotes: _additionalNotesController.text,
        status: 'Pending',
        quantity: int.tryParse(_quantityController.text) ?? 0,
        attachments: _attachments,
        createdAt: now,
        updatedAt: now,
      );

      await _databaseService.addRFQ(rfq);

      // Track RFQ creation with detailed information
      if (currentUser != null) {
        try {
          // Get product details for tracking
          final product = await _databaseService.getProduct(widget.productId);
          if (product != null) {
            await _interactionService.trackRFQCreation(
              rfqId: rfq.id,
              product: product,
              engineer: currentUser,
              rfqDetails: {
                'customerName': rfq.customerName,
                'customerEmail': rfq.customerEmail,
                'customerPhone': rfq.customerPhone,
                'deliveryAddress': rfq.deliveryAddress,
                'additionalNotes': rfq.additionalNotes,
                'attachments': rfq.attachments,
              },
              quantity: rfq.quantity,
              budgetRange: null, // Add budget range field if needed
            );
          }
        } catch (e) {
          Logger.logError('Error tracking RFQ creation', e, StackTrace.current);
        }
      }

      // After submitting RFQ, find matching suppliers and notify them (for now, just log)
      final supplierMatchingService = SupplierMatchingService();
      final notificationService = NotificationService();
      final matchedSuppliers =
          await supplierMatchingService.findMatchingSuppliers(rfq);

      if (matchedSuppliers.isNotEmpty) {
        Logger.log(
            'Found ${matchedSuppliers.length} matched suppliers for RFQ ID: ${rfq.id}');
        for (var supplier in matchedSuppliers) {
          await notificationService.sendNewRfqNotification(rfq, supplier);
        }
      } else {
        Logger.log('No suppliers found for RFQ ID: ${rfq.id}');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('RFQ submitted successfully!')),
        );
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Submit RFQ'),
      ),
      body: Center(
        child: Padding(
          padding: Responsive.isMobile(context)
              ? const EdgeInsets.all(16.0)
              : const EdgeInsets.symmetric(horizontal: 100, vertical: 32),
          child: SizedBox(
            width: Responsive.isMobile(context) ? double.infinity : 600,
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.all(16.0),
                    children: [
                      TextFormField(
                        controller: _customerNameController,
                        decoration: const InputDecoration(
                          labelText: 'Customer Name',
                          border: OutlineInputBorder(),
                        ),
                        validator: Validators.validateName,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _customerEmailController,
                        decoration: const InputDecoration(
                          labelText: 'Customer Email',
                          border: OutlineInputBorder(),
                        ),
                        validator: Validators.validateEmail,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _customerPhoneController,
                        decoration: const InputDecoration(
                          labelText: 'Customer Phone',
                          border: OutlineInputBorder(),
                        ),
                        validator: Validators.validatePhoneNumber,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _deliveryAddressController,
                        decoration: const InputDecoration(
                          labelText: 'Delivery Address',
                          border: OutlineInputBorder(),
                        ),
                        validator: Validators.validateAddress,
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _quantityController,
                        decoration: const InputDecoration(
                          labelText: 'Quantity',
                          border: OutlineInputBorder(),
                        ),
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
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _additionalNotesController,
                        decoration: const InputDecoration(
                          labelText: 'Additional Notes',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () async {
                          // Implement attachment picking logic
                        },
                        child: const Text('Add Attachments'),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _submitRFQ,
                        child: const Text('Submit RFQ'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

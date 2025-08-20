import 'package:flutter/material.dart';
import 'package:jengamate/models/product.dart';
import 'package:jengamate/screens/inquiry/widgets/product_form_card.dart';
import 'package:jengamate/models/inquiry_model.dart';
import 'package:jengamate/services/database_service.dart';
import 'package:jengamate/widgets/custom_text_field.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jengamate/ui/design_system/layout/adaptive_padding.dart';
import 'package:jengamate/ui/design_system/tokens/spacing.dart';

import '../../models/user_model.dart';

class NewInquiryScreen extends StatefulWidget {
  const NewInquiryScreen({super.key});

  @override
  State<NewInquiryScreen> createState() => _NewInquiryScreenState();
}

class _NewInquiryScreenState extends State<NewInquiryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _projectNameController = TextEditingController();
  final _deliveryAddressController = TextEditingController();
  final _timelineController = TextEditingController();
  final _expectedDeliveryDateController = TextEditingController();

  List<Product> _products = [Product()]; // Start with one product form
  bool _transportNeeded = false;

  void _addProduct() {
    setState(() {
      _products.add(Product());
    });
  }

  void _removeProduct(int index) {
    setState(() {
      if (_products.length > 1) {
        _products.removeAt(index);
      }
    });
  }

  Future<void> _submitInquiry() async {
    if (_formKey.currentState!.validate()) {
      // Show a loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      try {
        final currentUser = context.read<UserModel?>();
        if (currentUser == null) {
          throw Exception('User not logged in');
        }

        final inquiry = InquiryModel(
          id: '',
          userId: currentUser.uid,
          title: _projectNameController.text, // Added title
          products: _products
              .map((p) => {
                    'type': p.type,
                    'thickness': p.thickness,
                    'color': p.color,
                    'length': p.length,
                    'quantity': p.quantity,
                    'remarks': p.remarks,
                    'drawings': p.drawings,
                  })
              .toList(),
          projectInfo: {
            'projectName': _projectNameController.text,
            'deliveryAddress': _deliveryAddressController.text,
            'timeline': _timelineController.text,
            'expectedDeliveryDate': _expectedDeliveryDateController.text,
            'transportNeeded': _transportNeeded,
          },
          attachments: [],
          status: 'Pending',
          createdAt: Timestamp.now(),
        );

        final dbService = DatabaseService();

        await dbService.addInquiry(inquiry);

        // Hide loading indicator
        Navigator.of(context).pop();

        // Go back to the previous screen
        Navigator.of(context).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Inquiry Submitted Successfully!')),
        );
      } catch (e) {
        // Hide loading indicator
        Navigator.of(context).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Inquiry'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: AdaptivePadding(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Project Details Section
                Text(
                  'Project Details',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: JMSpacing.md),
                CustomTextField(
                  controller: _projectNameController,
                  labelText: 'Project Name',
                  validator: (value) => value!.isEmpty ? 'Please enter a project name' : null,
                ),
                const SizedBox(height: JMSpacing.md),
                CustomTextField(
                  controller: _deliveryAddressController,
                  labelText: 'Delivery Address',
                  validator: (value) => value!.isEmpty ? 'Please enter a delivery address' : null,
                ),
                const SizedBox(height: JMSpacing.md),
                CustomTextField(
                  controller: _timelineController,
                  labelText: 'Required Timeline (e.g., 2 weeks)',
                  validator: (value) => value!.isEmpty ? 'Please enter a timeline' : null,
                ),
                const SizedBox(height: JMSpacing.md),
                CustomTextField(
                  controller: _expectedDeliveryDateController,
                  labelText: 'Expected Delivery Date (e.g., 2025-02-15)',
                  validator: (value) => value!.isEmpty ? 'Please enter expected delivery date' : null,
                ),
                const SizedBox(height: JMSpacing.md),
                CheckboxListTile(
                  title: const Text('Transport Needed'),
                  subtitle: const Text('Check if you need transportation services'),
                  value: _transportNeeded,
                  onChanged: (value) {
                    setState(() {
                      _transportNeeded = value ?? false;
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                const SizedBox(height: JMSpacing.lg),

                // Products Section
                Text(
                  'Products',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: JMSpacing.md),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _products.length,
                  itemBuilder: (context, index) {
                    return ProductFormCard(
                      key: ValueKey(_products[index]), // Important for state management
                      product: _products[index],
                      onRemove: () => _removeProduct(index),
                      isRemovable: _products.length > 1,
                    );
                  },
                ),
                const SizedBox(height: JMSpacing.md),
                TextButton.icon(
                  onPressed: _addProduct,
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('Add Another Product'),
                ),
                const SizedBox(height: JMSpacing.xl),

                // Submit Button
                ElevatedButton(
                  onPressed: _submitInquiry,
                  child: const Text('Submit Inquiry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

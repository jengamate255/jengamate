import 'package:flutter/material.dart';
import 'package:jengamate/models/inquiry.dart';
import 'package:jengamate/services/database_service.dart';
import 'package:provider/provider.dart';
import 'package:jengamate/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jengamate/ui/design_system/layout/adaptive_padding.dart';
import 'package:jengamate/ui/design_system/tokens/spacing.dart';
import 'package:jengamate/ui/design_system/components/jm_card.dart';

class InquirySubmissionScreen extends StatefulWidget {
  const InquirySubmissionScreen({super.key});

  @override
  State<InquirySubmissionScreen> createState() =>
      _InquirySubmissionScreenState();
}

class _InquirySubmissionScreenState extends State<InquirySubmissionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _projectNameController = TextEditingController();
  final _deliveryAddressController = TextEditingController();
  final _expectedDeliveryDateController = TextEditingController();
  bool _transportNeeded = false;
  List<Map<String, dynamic>> _products = [];
  List<String> _attachments = [];

  @override
  void dispose() {
    _projectNameController.dispose();
    _deliveryAddressController.dispose();
    _expectedDeliveryDateController.dispose();
    super.dispose();
  }

  void _addProduct() {
    setState(() {
      _products.add({
        'type': '',
        'thickness': '',
        'color': '',
        'length': '',
        'quantity': '',
        'remarks': '',
        'drawings': [],
      });
    });
  }

  void _submitInquiry() async {
    if (_formKey.currentState!.validate()) {
      final currentUser = Provider.of<UserModel?>(context, listen: false);
      final now = Timestamp.now();
      final inquiry = Inquiry(
        uid: FirebaseFirestore.instance.collection('inquiries').doc().id,
        userId: currentUser?.uid ?? '',
        userName: currentUser?.displayName ?? '',
        userEmail: currentUser?.email ?? '',
        subject: _projectNameController.text,
        description: '',
        category: 'quotation',
        priority: 'medium',
        status: 'open',
        createdAt: now.toDate(),
        updatedAt: now.toDate(),
        tags: const ['quotation'],
        projectInfo: {
          'projectName': _projectNameController.text,
          'deliveryAddress': _deliveryAddressController.text,
          'expectedDeliveryDate': _expectedDeliveryDateController.text,
          'transportNeeded': _transportNeeded,
        },
        products: const [],
        metadata: null,
      );

      await DatabaseService().addInquiry(inquiry);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Submit Inquiry'),
      ),
      body: AdaptivePadding(
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              ..._buildProjectInfoFields(),
              const SizedBox(height: JMSpacing.md),
              ..._buildProductList(),
              const SizedBox(height: JMSpacing.md),
              ElevatedButton.icon(
                onPressed: _addProduct,
                icon: const Icon(Icons.add),
                label: const Text('Add Product'),
              ),
              const SizedBox(height: JMSpacing.lg),
              ElevatedButton(
                onPressed: _submitInquiry,
                child: const Text('Submit Inquiry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildProjectInfoFields() {
    return [
      TextFormField(
        controller: _projectNameController,
        decoration: const InputDecoration(
          labelText: 'Project Name',
          border: OutlineInputBorder(),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter a project name';
          }
          return null;
        },
      ),
      const SizedBox(height: JMSpacing.md),
      TextFormField(
        controller: _deliveryAddressController,
        decoration: const InputDecoration(
          labelText: 'Delivery Address',
          border: OutlineInputBorder(),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter a delivery address';
          }
          return null;
        },
      ),
      const SizedBox(height: JMSpacing.md),
      TextFormField(
        controller: _expectedDeliveryDateController,
        decoration: const InputDecoration(
          labelText: 'Expected Delivery Date',
          border: OutlineInputBorder(),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter an expected delivery date';
          }
          return null;
        },
      ),
      const SizedBox(height: JMSpacing.md),
      CheckboxListTile(
        title: const Text('Transport Needed'),
        value: _transportNeeded,
        onChanged: (value) {
          setState(() {
            _transportNeeded = value!;
          });
        },
      ),
    ];
  }

  List<Widget> _buildProductList() {
    return _products.asMap().entries.map((entry) {
      int index = entry.key;
      Map<String, dynamic> product = entry.value;
      return JMCard(
        margin: const EdgeInsets.only(bottom: JMSpacing.md),
        child: Padding(
          padding: const EdgeInsets.all(JMSpacing.md),
          child: Column(
            children: [
              TextFormField(
                initialValue: product['type'],
                decoration: const InputDecoration(
                  labelText: 'Product Type',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  _products[index]['type'] = value;
                },
              ),
              const SizedBox(height: JMSpacing.md),
              TextFormField(
                initialValue: product['thickness'],
                decoration: const InputDecoration(
                  labelText: 'Thickness',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  _products[index]['thickness'] = value;
                },
              ),
              const SizedBox(height: JMSpacing.md),
              TextFormField(
                initialValue: product['color'],
                decoration: const InputDecoration(
                  labelText: 'Color',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  _products[index]['color'] = value;
                },
              ),
              const SizedBox(height: JMSpacing.md),
              TextFormField(
                initialValue: product['length'],
                decoration: const InputDecoration(
                  labelText: 'Length',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  _products[index]['length'] = value;
                },
              ),
              const SizedBox(height: JMSpacing.md),
              TextFormField(
                initialValue: product['quantity'],
                decoration: const InputDecoration(
                  labelText: 'Quantity',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  _products[index]['quantity'] = value;
                },
              ),
              const SizedBox(height: JMSpacing.md),
              TextFormField(
                initialValue: product['remarks'],
                decoration: const InputDecoration(
                  labelText: 'Remarks',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  _products[index]['remarks'] = value;
                },
              ),
              const SizedBox(height: JMSpacing.md),
              ElevatedButton.icon(
                onPressed: () {
                  // Implement drawing upload logic
                },
                icon: const Icon(Icons.upload_file),
                label: const Text('Upload Drawings'),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }
}

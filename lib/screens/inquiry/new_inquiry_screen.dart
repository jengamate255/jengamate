import 'package:flutter/material.dart';
import 'package:jengamate/models/product_model.dart';
import 'package:jengamate/screens/inquiry/widgets/product_form_card.dart';
import 'package:jengamate/models/inquiry_model.dart';
import 'package:jengamate/services/database_service.dart';
import 'package:jengamate/widgets/custom_text_field.dart';

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

  List<Product> _products = [Product()]; // Start with one product form

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
        final inquiry = Inquiry(
          projectName: _projectNameController.text,
          deliveryAddress: _deliveryAddressController.text,
          timeline: _timelineController.text,
          products: _products,
          status: 'Pending',
          createdAt: DateTime.now(),
        );

        final dbService = DatabaseService();

        // Upload drawings and update product URLs
        for (var product in inquiry.products) {
          if (product.technicalDrawing != null) {
            product.drawingUrl = await dbService.uploadDrawing(product.technicalDrawing!);
          }
        }

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
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Project Details Section
              Text(
                'Project Details',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _projectNameController,
                labelText: 'Project Name',
                validator: (value) => value!.isEmpty ? 'Please enter a project name' : null,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _deliveryAddressController,
                labelText: 'Delivery Address',
                 validator: (value) => value!.isEmpty ? 'Please enter a delivery address' : null,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _timelineController,
                labelText: 'Required Timeline (e.g., 2 weeks)',
                 validator: (value) => value!.isEmpty ? 'Please enter a timeline' : null,
              ),
              const SizedBox(height: 24),

              // Products Section
              Text(
                'Products',
                 style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
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
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: _addProduct,
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Add Another Product'),
              ),
              const SizedBox(height: 32),

              // Submit Button
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
}

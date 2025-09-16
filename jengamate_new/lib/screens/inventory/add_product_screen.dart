import 'package:flutter/material.dart';
import 'package:jengamate/ui/design_system/tokens/spacing.dart';
import 'package:jengamate/ui/design_system/tokens/typography.dart';
import 'package:jengamate/models/product_model.dart';
import 'package:jengamate/services/product_service.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({Key? key}) : super(key: key);

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _stockController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController();

  final ProductService _productService = ProductService();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _categoryController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  void _submitForm() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
      });

      final newProduct = ProductModel(
        id: ' ', // Supabase will generate this
        name: _nameController.text,
        description: _descriptionController.text,
        price: double.parse(_priceController.text),
        stock: int.parse(_stockController.text),
        categoryId: _categoryController.text, // Assuming category maps to categoryId
        imageUrl: _imageUrlController.text,
        supplierId: 'placeholder_supplier_id', // TODO: Replace with actual supplier ID
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      try {
        await _productService.addProduct(newProduct);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Product ${newProduct.name} added successfully!')),
        );
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add product: $e')),
        );
      } finally {
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
        title: const Text('Add New Product'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(JMSpacing.md),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Product Information', style: JMTypography.heading2),
              const SizedBox(height: JMSpacing.md),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Product Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a product name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: JMSpacing.sm),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
              const SizedBox(height: JMSpacing.sm),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'Price'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a price';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: JMSpacing.sm),
              TextFormField(
                controller: _stockController,
                decoration: const InputDecoration(labelText: 'Stock Quantity'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a stock quantity';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Please enter a valid integer';
                  }
                  return null;
                },
              ),
              const SizedBox(height: JMSpacing.sm),
              TextFormField(
                controller: _categoryController,
                decoration: const InputDecoration(labelText: 'Category'),
              ),
              const SizedBox(height: JMSpacing.sm),
              TextFormField(
                controller: _imageUrlController,
                decoration: const InputDecoration(labelText: 'Image URL'),
              ),
              const SizedBox(height: JMSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitForm,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Add Product'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

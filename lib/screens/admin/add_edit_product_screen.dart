import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jengamate/models/listing_product_model.dart';
import 'package:jengamate/services/database_service.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http; // Import http package
import 'dart:typed_data'; // Add this import
import 'package:file_picker/file_picker.dart'; // Import file_picker package
// Import kIsWeb

import '../../models/user_model.dart';
import 'package:jengamate/models/enums/user_role.dart';

class AddEditProductScreen extends StatefulWidget {
  final ListingProduct? product;

  const AddEditProductScreen({super.key, this.product});

  @override
  State<AddEditProductScreen> createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends State<AddEditProductScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TabController _tabController;
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _typeController = TextEditingController();
  final _thicknessController = TextEditingController();
  final _colorController = TextEditingController();
  final _dimensionsController = TextEditingController();
  final _availabilityController = TextEditingController();
  final _serviceProviderController = TextEditingController();
  final _stockController = TextEditingController();
  final _statusController = TextEditingController();

  final DatabaseService _databaseService = DatabaseService();

  XFile? _pickedImage; // Changed type to XFile?
  String? _technicalDrawingUrl; // To store existing drawing URL
  PlatformFile? _pickedTechnicalDrawing; // To store new picked drawing file

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    if (widget.product != null) {
      _nameController.text = widget.product!.name;
      _priceController.text = widget.product!.price.toString();
      _descriptionController.text = widget.product!.description;
      _typeController.text = widget.product!.type;
      _thicknessController.text = widget.product!.thickness;
      _colorController.text = widget.product!.color;
      _dimensionsController.text = widget.product!.dimensions;
      _availabilityController.text = widget.product!.availability;
      _serviceProviderController.text = widget.product!.serviceProvider;
      _stockController.text = widget.product!.isActive ? 'active' : 'inactive';
      _statusController.text = widget.product!.isActive ? 'active' : 'inactive';

      if (widget.product!.imageUrl.isNotEmpty) {
        _loadImageFromUrl(widget.product!.imageUrl);
      }
      // Assuming technical drawing URL is part of specifications or a separate field
      _technicalDrawingUrl = widget
          .product!.drawingUrl; // Assuming drawingUrl exists in ListingProduct
    }
  }

  // Helper function to load image from URL and set _pickedImage
  Future<void> _loadImageFromUrl(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        setState(() {
          _pickedImage = XFile.fromData(bytes, name: url.split('/').last);
        });
      } else {
        print('Failed to load image from URL: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading image from URL: $e');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _typeController.dispose();
    _thicknessController.dispose();
    _colorController.dispose();
    _dimensionsController.dispose();
    _availabilityController.dispose();
    _serviceProviderController.dispose();
    _stockController.dispose();
    _statusController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final image = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (image == null) return;
    setState(() {
      _pickedImage = image;
    });
  }

  Future<void> _pickTechnicalDrawing() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );
    if (result == null) return;

    setState(() {
      _pickedTechnicalDrawing =
          result.files.first; // Use result.files.first for web
      _technicalDrawingUrl = null; // Clear existing URL if a new file is picked
    });
  }

  // Method to remove technical drawing
  void _removeTechnicalDrawing() {
    setState(() {
      _pickedTechnicalDrawing = null;
      _technicalDrawingUrl = null;
    });
  }

  void _saveProduct() async {
    if (_formKey.currentState!.validate()) {
      String imageUrl = widget.product?.images.isNotEmpty == true
          ? widget.product!.images.first
          : '';
      String? drawingUrl = widget.product?.drawingUrl;

      if (_pickedImage != null) {
        // Upload the image and get the URL
        imageUrl = await _databaseService.uploadDrawing(_pickedImage!.path);
      }

      if (_pickedTechnicalDrawing != null) {
        // Upload technical drawing and get the URL
        drawingUrl =
            await _databaseService.uploadDrawing(_pickedTechnicalDrawing!.path);
      }

      final currentUser = Provider.of<UserModel?>(context, listen: false);
      final now = DateTime.now();

      final product = ListingProduct(
        id: widget.product?.id ??
            FirebaseFirestore.instance.collection('products').doc().id,
        name: _nameController.text,
        description: _descriptionController.text,
        price: double.tryParse(_priceController.text) ?? 0.0,
        categoryId: 'default', // TODO: Add category selection
        supplierId: currentUser?.uid ?? '',
        images: [imageUrl],
        createdAt: widget.product?.createdAt ?? now,
        updatedAt: now,
        type: _typeController.text,
        thickness: _thicknessController.text,
        color: _colorController.text,
        dimensions: _dimensionsController.text,
        availability: _availabilityController.text,
        serviceProvider: _serviceProviderController.text,
        drawingUrl: drawingUrl,
        specifications: {},
      );

      if (widget.product == null) {
        await _databaseService.createListingProduct(product);
      } else {
        await _databaseService.updateListingProduct(product);
      }

      Navigator.of(context).pop();
    }
  }

  Future<bool> _isValidImageUrl(String url) async {
    try {
      final response = await http.head(Uri.parse(url));
      return response.statusCode == 200 &&
          response.headers['content-type']!.startsWith('image/');
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = Provider.of<UserModel?>(context);

    if (currentUser == null ||
        (currentUser.role != UserRole.admin &&
            currentUser.role != UserRole.supplier)) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.product == null ? 'Add Product' : 'Edit Product'),
        ),
        body: const Center(
          child: Text('You do not have permission to view this page.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // Remove default back button
        title: const Text('Edit Product'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Basic Info'),
            Tab(text: 'Color Variations'),
            Tab(text: 'Pricing & Inventory'),
            Tab(text: 'Shipping'),
            Tab(text: 'SEO Settings'),
          ],
        ),
        actions: [
          ElevatedButton.icon(
            onPressed: _saveProduct,
            icon: const Icon(Icons.save),
            label: const Text('Update Product'),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  Theme.of(context).primaryColor, // Use primary color
              foregroundColor: Colors.white, // White text
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
            },
            icon: const Icon(Icons.cancel),
            label: const Text('Cancel'),
            style: OutlinedButton.styleFrom(
              foregroundColor:
                  Theme.of(context).colorScheme.error, // Use error color
              side: BorderSide(
                  color: Theme.of(context).colorScheme.error), // Red border
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Basic Info Tab
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  _buildTextField(_nameController, 'Product Name',
                      'Please enter a product name'),
                  _buildTextField(_descriptionController, 'Description',
                      'Please enter a description',
                      maxLines: 3),
                  const SizedBox(height: 16),
                  Text(
                    'Product Images',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _pickImage,
                    child: const Text('Choose Files'),
                  ),
                  if (widget.product != null &&
                      widget.product!.imageUrl.isNotEmpty &&
                      _pickedImage == null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        children: [
                          Image.network(
                            widget.product!.imageUrl,
                            height: 60,
                            width: 60,
                            fit: BoxFit.cover,
                          ),
                          const SizedBox(width: 8),
                          Text(
                              '1 existing'), // Placeholder for existing image count
                        ],
                      ),
                    )
                  else if (_pickedImage != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        children: [
                          FutureBuilder<Uint8List>(
                            future: _pickedImage!.readAsBytes(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                      ConnectionState.done &&
                                  snapshot.hasData) {
                                return Image.memory(snapshot.data!,
                                    height: 60, width: 60, fit: BoxFit.cover);
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                          const SizedBox(width: 8),
                          Text(
                              '1 new, 0 existing'), // Placeholder for new image count
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),
                  Text(
                    'Technical Drawing (PDF/Image)',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _pickTechnicalDrawing,
                    child: const Text('Choose File'),
                  ),
                  if (_technicalDrawingUrl != null ||
                      _pickedTechnicalDrawing != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        children: [
                          Text(
                            _pickedTechnicalDrawing?.name ??
                                _technicalDrawingUrl!
                                    .split('/')
                                    .last
                                    .split('?')
                                    .first,
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: _removeTechnicalDrawing,
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),
                  Text(
                    'Configure Product Details',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  _buildTextField(
                      _typeController, 'Type', 'Please enter a type'),
                  _buildTextField(_thicknessController, 'Thickness',
                      'Please enter thickness'),
                  _buildTextField(
                      _colorController, 'Color', 'Please enter color'),
                  _buildTextField(_dimensionsController, 'Dimensions',
                      'Please enter dimensions'),
                  _buildTextField(_availabilityController, 'Availability',
                      'Please enter availability'),
                  _buildTextField(_serviceProviderController,
                      'Service Provider', 'Please enter a service provider'),
                  _buildTextField(
                      _stockController, 'Stock', 'Please enter stock',
                      keyboardType: TextInputType.number),
                  _buildTextField(
                      _statusController, 'Status', 'Please enter status'),
                ],
              ),
            ),
          ),
          // Other tabs (empty for now)
          Container(),
          Container(),
          Container(),
          Container(),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String labelText,
      String validationMessage,
      {TextInputType? keyboardType, int? maxLines}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: labelText,
          border: const OutlineInputBorder(),
        ),
        keyboardType: keyboardType,
        maxLines: maxLines ?? 1,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return validationMessage;
          }
          return null;
        },
      ),
    );
  }
}

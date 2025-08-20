import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:jengamate/models/product_model.dart';
import 'package:jengamate/services/database_service.dart';
import 'package:jengamate/services/hybrid_storage_service.dart';
import 'package:jengamate/services/storage_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:jengamate/models/user_model.dart';
import 'package:jengamate/models/enums/user_role.dart';
import 'package:jengamate/utils/responsive.dart';
import 'package:jengamate/models/category_model.dart';

class AddEditProductScreen extends StatefulWidget {
  final ProductModel? product;

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
  final _thicknessController = TextEditingController();
  final _colorController = TextEditingController();
  final _dimensionsController = TextEditingController();
  final _brandController = TextEditingController();
  final _stockController = TextEditingController();
  final _statusController = TextEditingController();

  final DatabaseService _databaseService = DatabaseService();
      final HybridStorageService _storageService = HybridStorageService(
    firebaseStorageService: StorageService(),
    supabaseClient: Supabase.instance.client,
  );


  XFile? _pickedImage;
  String? _videoUrl;
  PlatformFile? _pickedVideo;

  List<CategoryModel?> _categories = [];
  List<CategoryModel?> _subCategories = [];
  String? _selectedCategoryId;
  String? _selectedSubCategoryId;
  String? _selectedGauge;
  String? _selectedProfile;
  String? _selectedBrand;
  List<ProductVariant> _variants = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchCategories();
    if (widget.product != null) {
      _nameController.text = widget.product!.name;
      _priceController.text = widget.product!.price.toString();
      _descriptionController.text = widget.product!.description;
      _selectedProfile = widget.product!.type;
      if (_selectedProfile != null && !['it4', 'it5'].contains(_selectedProfile)) {
        _selectedProfile = null;
      }
      _selectedGauge = widget.product!.thickness;
      if (_selectedGauge != null &&
          !['30g', '28g', '26g', '24g'].contains(_selectedGauge)) {
        _selectedGauge = null;
      }
      _colorController.text = widget.product!.color;
      _dimensionsController.text = widget.product!.dimensions;
      _selectedBrand = widget.product!.serviceProvider;
      if (_selectedBrand != null &&
          !['Kinglion', 'Alaf'].contains(_selectedBrand)) {
        _selectedBrand = null;
      }
      _stockController.text = widget.product!.stock.toString();
      _statusController.text = widget.product!.isActive ? 'active' : 'inactive';

      if (widget.product!.imageUrl.isNotEmpty) {
        _loadImageFromUrl(widget.product!.imageUrl);
      }
      _videoUrl = widget.product!.videoUrl;
      _variants = List.from(widget.product!.variants);

      // Set initial category and fetch sub-categories
      _selectedCategoryId = widget.product!.categoryId;
      if (_selectedCategoryId != null && _selectedCategoryId!.isNotEmpty) {
        _fetchSubCategories(_selectedCategoryId!,
            initialSubCategoryId: widget.product!.subCategoryId);
      }
    }
  }

  Future<void> _fetchCategories() async {
    try {
      final categories = await _databaseService.getCategories().first;
      if (mounted) {
        setState(() {
          _categories = categories;
          // Initialize selection for edit mode
          final prod = widget.product;
          if (prod != null) {
            // Reset selections first
            _selectedCategoryId = null;
            _selectedSubCategoryId = null;
            _subCategories = [];

            // If subCategoryId is set, prefer deriving from it
            if (prod.subCategoryId != null && prod.subCategoryId!.isNotEmpty) {
              final sub = _categories.cast<CategoryModel?>().firstWhere(
                (c) => c?.id == prod.subCategoryId,
                orElse: () => null,
              );
              if (sub != null && sub.parentId != null) {
                // Verify parent exists and is a root category
                final parent = _categories.cast<CategoryModel?>().firstWhere(
                  (c) => c?.id == sub.parentId && c?.parentId == null,
                  orElse: () => null,
                );
                if (parent != null) {
                  _selectedCategoryId = parent.id;
                  _fetchSubCategories(_selectedCategoryId!, initialSubCategoryId: sub.id);
                }
              }
            } else if (prod.categoryId.isNotEmpty) {
              // Ensure we select a root if categoryId points to a child
              final found = _categories.cast<CategoryModel?>().firstWhere(
                (c) => c?.id == prod.categoryId,
                orElse: () => null,
              );
              if (found != null) {
                if (found.parentId != null) {
                  // This is a subcategory, find its parent
                  final parent = _categories.cast<CategoryModel?>().firstWhere(
                    (c) => c?.id == found.parentId && c?.parentId == null,
                    orElse: () => null,
                  );
                  if (parent != null) {
                    _selectedCategoryId = parent.id;
                    _fetchSubCategories(_selectedCategoryId!);
                  }
                } else {
                  // This is already a root category
                  _selectedCategoryId = found.id;
                  _fetchSubCategories(_selectedCategoryId!);
                }
              }
            }
          }
        });
      }
    } catch (e) {
      print("Error fetching categories: $e");
      // Reset state on error
      if (mounted) {
        setState(() {
          _categories = [];
          _selectedCategoryId = null;
          _selectedSubCategoryId = null;
          _subCategories = [];
        });
      }
    }
  }

  Future<void> _fetchSubCategories(String parentId,
      {String? initialSubCategoryId}) async {
    try {
      final subCategories = await _databaseService.getSubCategories(parentId).first;
      if (mounted) {
        setState(() {
          _subCategories = subCategories;
          if (initialSubCategoryId != null) {
            final subCategory = _subCategories.firstWhere(
              (sc) => sc!.id == initialSubCategoryId,
              orElse: () => null,
            );
            if (subCategory != null) {
              _selectedSubCategoryId = subCategory.id;
            }
          }
        });
      }
    } catch (e) {
      print("Error fetching sub-categories: $e");
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load image.')),
        );
      }
    } catch (e) {
      print('Error loading image from URL: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An error occurred while loading the image.')),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _thicknessController.dispose();
    _colorController.dispose();
    _dimensionsController.dispose();
    _brandController.dispose();
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

  Future<void> _pickVideo() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.video,
    );
    if (result == null) return;

    setState(() {
      _pickedVideo = result.files.first;
      _videoUrl = null;
    });
  }

  void _removeVideo() {
    setState(() {
      _pickedVideo = null;
      _videoUrl = null;
    });
  }

  Future<void> _saveProduct() async {
    if (_formKey.currentState!.validate()) {
      final user = Provider.of<UserModel?>(context, listen: false);
      if (user == null) { // Simplified check as role check is below
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You must be logged in to perform this action.')),
        );
        return;
      }

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      try {
        String? imageUrl = widget.product?.imageUrl;
        if (_pickedImage != null) {
          final String fileName = _pickedImage!.name;
          final bytes = await _pickedImage!.readAsBytes();

          imageUrl = await _storageService.uploadImage(
            fileName: fileName,
            folder: 'product_images',
            bytes: bytes,
          );
        }

        if (imageUrl == null) {
          throw Exception('Image could not be uploaded or found.');
        }

        final productData = ProductModel(
          id: widget.product?.id ?? FirebaseFirestore.instance.collection('products').doc().id,
          name: _nameController.text,
          price: double.tryParse(_priceController.text) ?? 0.0,
          description: _descriptionController.text,
          imageUrl: imageUrl,
          categoryId: _selectedCategoryId ?? '',
          subCategoryId: _selectedSubCategoryId,
          supplierId: user.uid,
          type: _selectedProfile ?? '',
          thickness: _selectedGauge ?? '',
          color: _colorController.text,
          dimensions: _dimensionsController.text,
          stock: int.tryParse(_stockController.text) ?? 0,
          serviceProvider: _selectedBrand ?? '',
          isActive: _statusController.text.toLowerCase() == 'active',
          variants: _variants,
          createdAt: widget.product?.createdAt ?? DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await _databaseService.addOrUpdateProduct(productData);

        if (mounted) {
          Navigator.of(context).pop(); // Dismiss loading indicator
          Navigator.of(context).pop(); // Go back to the previous screen
        }
      } catch (e) {
        debugPrint('Error saving product: $e');
        if (mounted) {
          Navigator.of(context).pop(); // Dismiss loading indicator
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error saving product: ${e.toString()}')),
          );
        }
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserModel?>(context);

    if (user == null || (user.role != UserRole.admin && user.role != UserRole.supplier)) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.product == null ? 'Add Product' : 'Edit Product'),
        ),
        body: const Center(
          child: Text('You do not have permission to view this page.'),
        ),
      );
    }
    return _buildContent(context);
  }

  Widget _buildContent(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // Remove default back button
        title: const Text('Edit Product'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Basic Info'),
            Tab(text: 'Specifications'),
            Tab(text: 'Variants'),
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
                  _buildCategoryDropdown(),
                  const SizedBox(height: 16),
                  if (_selectedCategoryId != null) _buildSubCategoryDropdown(),
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
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(Icons.error, size: 60);
                            },
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
                    'Product Video',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _pickVideo,
                    child: const Text('Choose Video'),
                  ),
                  if (_videoUrl != null || _pickedVideo != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _pickedVideo?.name ??
                                  (_videoUrl?.split('/').last.split('?').first ?? ''),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: _removeVideo,
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
                  _buildProfileDropdown(),
                  _buildGaugeDropdown(),
                  _buildTextField(
                      _colorController, 'Color', 'Please enter color'),
                  _buildTextField(_dimensionsController, 'Dimensions',
                      'Please enter dimensions'),
                  _buildBrandDropdown(),
                  _buildTextField(
                      _stockController, 'Stock', 'Please enter stock',
                      keyboardType: TextInputType.number),
                  _buildTextField(
                      _statusController, 'Status', 'Please enter status'),
                ],
              ),
            ),
          ),
          // Specifications Tab
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView(
              children: [
                Text('Product Specifications', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                // Add your specification fields here
                // For example:
                // _buildTextField(_materialController, 'Material', 'Please enter material'),
                // _buildTextField(_weightController, 'Weight', 'Please enter weight', keyboardType: TextInputType.number),
                // You can add more fields as needed based on your product model
              ],
            ),
          ),
          _buildVariantsTab(),
        ],
      ),
    );
  }

  Widget _buildVariantsTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _variants.length,
              itemBuilder: (context, index) {
                final variant = _variants[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  child: ListTile(
                    title: Text('Variant ${index + 1}'),
                    subtitle: Text(
                        '${variant.thickness}, ${variant.color}, ${variant.dimensions}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () {
                        setState(() {
                          _variants.removeAt(index);
                        });
                      },
                    ),
                  ),
                );
              },
            ),
          ),
          ElevatedButton(
            onPressed: _addVariant,
            child: const Text('Add Variant'),
          ),
        ],
      ),
    );
  }

  void _addVariant() {
    final _variantFormKey = GlobalKey<FormState>();
    final _thicknessController = TextEditingController();
    final _colorController = TextEditingController();
    final _dimensionsController = TextEditingController();
    final _priceController = TextEditingController();
    final _stockController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Variant'),
        content: Form(
          key: _variantFormKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTextField(_thicknessController, 'Thickness', 'Please enter thickness'),
                _buildTextField(_colorController, 'Color', 'Please enter color'),
                _buildTextField(_dimensionsController, 'Dimensions', 'Please enter dimensions'),
                _buildTextField(_priceController, 'Price', 'Please enter a price', keyboardType: TextInputType.number),
                _buildTextField(_stockController, 'Stock', 'Please enter stock', keyboardType: TextInputType.number),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_variantFormKey.currentState!.validate()) {
                final newVariant = ProductVariant(
                  id: FirebaseFirestore.instance.collection('products').doc().collection('variants').doc().id,
                  thickness: _thicknessController.text,
                  color: _colorController.text,
                  dimensions: _dimensionsController.text,
                  price: double.tryParse(_priceController.text) ?? 0.0,
                  stock: int.tryParse(_stockController.text) ?? 0,
                );
                setState(() {
                  _variants.add(newVariant);
                });
                Navigator.of(context).pop();
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    // Get root categories only
    final rootCategories = _categories
        .where((c) => c != null && c!.parentId == null)
        .toList();

    // Validate that selected category exists in root categories
    String? validatedSelectedCategoryId = _selectedCategoryId;
    if (_selectedCategoryId != null) {
      final exists = rootCategories.any((c) => c?.id == _selectedCategoryId);
      if (!exists) {
        validatedSelectedCategoryId = null;
      }
    }

    return DropdownButtonFormField<String>(
      value: validatedSelectedCategoryId,
      decoration: const InputDecoration(
        labelText: 'Category',
        border: OutlineInputBorder(),
      ),
      items: rootCategories.map((CategoryModel? category) {
        return DropdownMenuItem(
          value: category!.id,
          child: Text(category.name),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedCategoryId = value;
          _selectedSubCategoryId = null;
          _subCategories = [];
          if (_selectedCategoryId != null) {
            _fetchSubCategories(_selectedCategoryId!);
          }
        });
      },
      validator: (value) => value == null ? 'Please select a category' : null,
    );
  }

  Widget _buildSubCategoryDropdown() {
    // Validate that selected subcategory exists in current subcategories
    String? validatedSelectedSubCategoryId = _selectedSubCategoryId;
    if (_selectedSubCategoryId != null) {
      final exists = _subCategories.any((c) => c?.id == _selectedSubCategoryId);
      if (!exists) {
        validatedSelectedSubCategoryId = null;
      }
    }

    return DropdownButtonFormField<String>(
      value: validatedSelectedSubCategoryId,
      decoration: const InputDecoration(
        labelText: 'Sub Category',
        border: OutlineInputBorder(),
      ),
      items: _subCategories
          .where((c) => c != null)
          .map((CategoryModel? c) => DropdownMenuItem(
                value: c!.id,
                child: Text(c.name),
              ))
          .toList(),
      onChanged: (value) {
        setState(() {
          _selectedSubCategoryId = value;
        });
      },
    );
  }

  Widget _buildBrandDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedBrand,
      decoration: const InputDecoration(
        labelText: 'Brand',
        border: OutlineInputBorder(),
      ),
      items: ['Kinglion', 'Alaf'].map((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
      onChanged: (newValue) {
        setState(() {
          _selectedBrand = newValue;
        });
      },
      validator: (value) => value == null ? 'Please select a brand' : null,
    );
  }
  
    Widget _buildGaugeDropdown() {
      return DropdownButtonFormField<String>(
        value: _selectedGauge,
        decoration: const InputDecoration(
          labelText: 'Gauge',
          border: OutlineInputBorder(),
        ),
        items: ['30g', '28g', '26g', '24g'].map((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }).toList(),
        onChanged: (newValue) {
          setState(() {
            _selectedGauge = newValue;
          });
        },
        validator: (value) => value == null ? 'Please select a gauge' : null,
      );
    }

  Widget _buildProfileDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedProfile,
      decoration: const InputDecoration(
        labelText: 'Profile',
        border: OutlineInputBorder(),
      ),
      items: ['it4', 'it5'].map((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
      onChanged: (newValue) {
        setState(() {
          _selectedProfile = newValue;
        });
      },
      validator: (value) => value == null ? 'Please select a profile' : null,
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
          if (keyboardType == TextInputType.number &&
              double.tryParse(value) == null) {
            return 'Please enter a valid number';
          }
          return null;
        },
      ),
    );
  }
}

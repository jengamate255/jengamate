import 'package:flutter/material.dart';
import 'package:jengamate/services/database_service.dart';
import 'package:jengamate/models/product_model.dart';

class ProductSelectionScreen extends StatefulWidget {
  const ProductSelectionScreen({Key? key}) : super(key: key);

  @override
  State<ProductSelectionScreen> createState() => _ProductSelectionScreenState();
}

class _ProductSelectionScreenState extends State<ProductSelectionScreen> {
  final DatabaseService _dbService = DatabaseService();
  List<ProductModel> _products = [];
  bool _isLoading = true;
  String? _searchQuery;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
    });
    try {
      _products = await _dbService.getAllProducts();
    } catch (e) {
      // Handle error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load products: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<ProductModel> get _filteredProducts {
    if (_searchQuery == null || _searchQuery!.isEmpty) {
      return _products;
    }
    return _products.where((product) => product.name.toLowerCase().contains(_searchQuery!.toLowerCase())).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Product'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Search Products',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredProducts.isEmpty
                    ? const Center(child: Text('No products found'))
                    : ListView.builder(
                        itemCount: _filteredProducts.length,
                        itemBuilder: (context, index) {
                          final product = _filteredProducts[index];
                          return ListTile(
                            title: Text(product.name),
                            subtitle: Text(product.description),
                            onTap: () {
                              Navigator.pop(context, {
                                'productId': product.id,
                                'productName': product.name,
                              });
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

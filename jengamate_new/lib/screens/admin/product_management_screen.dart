import 'package:flutter/material.dart';
import 'package:jengamate/models/product_model.dart';
import 'package:jengamate/screens/admin/add_edit_product_screen.dart';
import 'package:jengamate/screens/admin/widgets/product_card.dart';
import 'package:jengamate/services/database_service.dart';
import 'package:provider/provider.dart';

import '../../models/user_model.dart';
import 'package:jengamate/models/enums/user_role.dart';

class ProductManagementScreen extends StatefulWidget {
  const ProductManagementScreen({super.key});

  @override
  State<ProductManagementScreen> createState() =>
      _ProductManagementScreenState();
}

class _ProductManagementScreenState extends State<ProductManagementScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final Set<String> _selectedProducts = {};
  String _searchQuery = '';
  String _sortOption = 'name';

  @override
  Widget build(BuildContext context) {
    final currentUser = Provider.of<UserModel?>(context);

    if (currentUser == null ||
        (currentUser.role != UserRole.admin &&
            currentUser.role != UserRole.supplier)) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Product Management'),
        ),
        body: const Center(
          child: Text('You do not have permission to view this page.'),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const AddEditProductScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search products...',
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
                const SizedBox(width: 8.0),
                DropdownButton<String>(
                  value: _sortOption,
                  items: const [
                    DropdownMenuItem(value: 'name', child: Text('Name')),
                    DropdownMenuItem(value: 'priceAsc', child: Text('Price Asc')),
                    DropdownMenuItem(value: 'priceDesc', child: Text('Price Desc')),
                    DropdownMenuItem(value: 'newest', child: Text('Newest')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _sortOption = value!;
                    });
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<ProductModel>>(
              stream: _databaseService.streamProducts(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No products found.'));
          }

          var products = snapshot.data!;

          products = products.where((product) {
            return _searchQuery.isEmpty ||
                product.name.toLowerCase().contains(_searchQuery.toLowerCase());
          }).toList();

          products.sort((a, b) {
            switch (_sortOption) {
              case 'name':
                return a.name.compareTo(b.name);
              case 'priceAsc':
                return a.price.compareTo(b.price);
              case 'priceDesc':
                return b.price.compareTo(a.price);
              default:
                return 0;
            }
          });

          return Column(
            children: [
              if (_selectedProducts.isNotEmpty)
                Container(
                  color: Colors.grey[200],
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${_selectedProducts.length} selected'),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Delete Products'),
                              content: Text(
                                  'Are you sure you want to delete ${_selectedProducts.length} products?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text('Cancel'),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    final productsToDelete = products
                                        .where((p) => _selectedProducts.contains(p.id))
                                        .toList();
                                    _databaseService.deleteProducts(productsToDelete);
                                    setState(() {
                                      _selectedProducts.clear();
                                    });
                                    Navigator.of(context).pop();
                                  },
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: ListView.builder(
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return ProductCard(
                      product: product,
                      onEdit: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) =>
                                AddEditProductScreen(product: product),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
          ),
        ],
      ),
    );
  }
}

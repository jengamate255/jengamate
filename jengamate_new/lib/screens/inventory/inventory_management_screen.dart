import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jengamate/services/user_state_provider.dart';
import 'package:jengamate/models/product_model.dart';
import 'package:jengamate/services/database_service.dart';
import 'package:jengamate/ui/design_system/layout/adaptive_padding.dart';
import 'package:jengamate/ui/design_system/tokens/spacing.dart';
import 'package:jengamate/ui/design_system/components/jm_card.dart';
import 'package:jengamate/models/user_model.dart';
import 'package:intl/intl.dart';
import 'package:jengamate/screens/inventory/add_product_screen.dart'; // Import the new screen
import 'package:jengamate/screens/inventory/edit_product_screen.dart'; // Import the new screen
import 'package:jengamate/screens/inventory/product_details_screen.dart'; // Import the new screen
import 'package:csv/csv.dart'; // Import csv
import 'dart:html' as html; // Import dart:html for web downloads
import 'dart:convert'; // Import dart:convert for utf8

class InventoryManagementScreen extends StatefulWidget {
  const InventoryManagementScreen({super.key});

  @override
  State<InventoryManagementScreen> createState() =>
      _InventoryManagementScreenState();
}

class _InventoryManagementScreenState extends State<InventoryManagementScreen> {
  final DatabaseService _dbService = DatabaseService();
  String _searchQuery = '';
  String _selectedCategory = 'all';
  String _selectedStatus = 'all';
  bool _showLowStock = false;

  @override
  Widget build(BuildContext context) {
    final userState = Provider.of<UserStateProvider>(context);
    final currentUser = userState.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory Management'),
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _addNewProduct(),
            tooltip: 'Add Product',
          ),
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: () => _exportInventory(),
            tooltip: 'Export Inventory',
          ),
        ],
      ),
      body: AdaptivePadding(
        child: Column(
          children: [
            _buildSearchAndFilters(),
            const SizedBox(height: JMSpacing.md),
            _buildInventorySummary(currentUser?.uid ?? ''),
            const SizedBox(height: JMSpacing.md),
            Expanded(
              child: _buildProductList(currentUser?.uid ?? ''),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return JMCard(
      child: Padding(
        padding: const EdgeInsets.all(JMSpacing.md),
        child: Column(
          children: [
            TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Search products...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
              ),
            ),
            const SizedBox(height: JMSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _buildFilterChip(
                    label: 'All Categories',
                    isSelected: _selectedCategory == 'all',
                    onTap: () => setState(() => _selectedCategory = 'all'),
                  ),
                ),
                const SizedBox(width: JMSpacing.sm),
                Expanded(
                  child: _buildFilterChip(
                    label: 'Electronics',
                    isSelected: _selectedCategory == 'electronics',
                    onTap: () =>
                        setState(() => _selectedCategory = 'electronics'),
                  ),
                ),
                const SizedBox(width: JMSpacing.sm),
                Expanded(
                  child: _buildFilterChip(
                    label: 'Clothing',
                    isSelected: _selectedCategory == 'clothing',
                    onTap: () => setState(() => _selectedCategory = 'clothing'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: JMSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: _buildFilterChip(
                    label: 'All Status',
                    isSelected: _selectedStatus == 'all',
                    onTap: () => setState(() => _selectedStatus = 'all'),
                  ),
                ),
                const SizedBox(width: JMSpacing.sm),
                Expanded(
                  child: _buildFilterChip(
                    label: 'In Stock',
                    isSelected: _selectedStatus == 'in_stock',
                    onTap: () => setState(() => _selectedStatus = 'in_stock'),
                  ),
                ),
                const SizedBox(width: JMSpacing.sm),
                Expanded(
                  child: _buildFilterChip(
                    label: 'Low Stock',
                    isSelected: _showLowStock,
                    onTap: () => setState(() => _showLowStock = !_showLowStock),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: JMSpacing.sm, vertical: JMSpacing.sm),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).primaryColor
              : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildInventorySummary(String userId) {
    return StreamBuilder<List<ProductModel>>(
      stream: _dbService.streamProducts(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const JMCard(
            child: Padding(
              padding: EdgeInsets.all(JMSpacing.lg),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final products = snapshot.data!;
        final totalProducts = products.length;
        final inStockProducts =
            products.where((product) => product.stock > 0).length;
        final lowStockProducts = products
            .where((product) => product.stock <= 10 && product.stock > 0)
            .length;
        final outOfStockProducts =
            products.where((product) => product.stock == 0).length;
        final totalValue = products.fold(
            0.0, (sum, product) => sum + (product.price * product.stock));

        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    title: 'Total Products',
                    value: totalProducts.toString(),
                    icon: Icons.inventory,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: JMSpacing.md),
                Expanded(
                  child: _buildSummaryCard(
                    title: 'In Stock',
                    value: inStockProducts.toString(),
                    icon: Icons.check_circle,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: JMSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    title: 'Low Stock',
                    value: lowStockProducts.toString(),
                    icon: Icons.warning,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: JMSpacing.md),
                Expanded(
                  child: _buildSummaryCard(
                    title: 'Out of Stock',
                    value: outOfStockProducts.toString(),
                    icon: Icons.cancel,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: JMSpacing.md),
            JMCard(
              child: Padding(
                padding: const EdgeInsets.all(JMSpacing.md),
                child: Row(
                  children: [
                    Icon(
                      Icons.attach_money,
                      color: Colors.green,
                      size: 24,
                    ),
                    const SizedBox(width: JMSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Inventory Value',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            'TSh ${NumberFormat('#,##0').format(totalValue)}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return JMCard(
      child: Padding(
        padding: const EdgeInsets.all(JMSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 24),
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: JMSpacing.sm),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductList(String userId) {
    return StreamBuilder<List<ProductModel>>(
      stream: _dbService.streamProducts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text('No products found.'),
          );
        }

        var products = snapshot.data!;

        // Apply filters
        if (_searchQuery.isNotEmpty) {
          products = products
              .where((product) =>
                  product.name
                      .toLowerCase()
                      .contains(_searchQuery.toLowerCase()) ||
                  product.description
                      .toLowerCase()
                      .contains(_searchQuery.toLowerCase()))
              .toList();
        }

        if (_selectedCategory != 'all') {
          products = products
              .where((product) => product.categoryId == _selectedCategory)
              .toList();
        }

        if (_selectedStatus == 'in_stock') {
          products = products.where((product) => product.stock > 0).toList();
        }

        if (_showLowStock) {
          products = products
              .where((product) => product.stock <= 10 && product.stock > 0)
              .toList();
        }

        return ListView.separated(
          itemCount: products.length,
          separatorBuilder: (_, __) => const SizedBox(height: JMSpacing.sm),
          itemBuilder: (context, index) {
            final product = products[index];
            return _buildProductCard(product);
          },
        );
      },
    );
  }

  Widget _buildProductCard(ProductModel product) {
    return JMCard(
      child: Padding(
        padding: const EdgeInsets.all(JMSpacing.md),
        child: Row(
          children: [
            // Product Image
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey.shade200,
              ),
              child: product.imageUrl.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        product.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.inventory,
                            color: Colors.grey.shade400,
                            size: 30,
                          );
                        },
                      ),
                    )
                  : Icon(
                      Icons.inventory,
                      color: Colors.grey.shade400,
                      size: 30,
                    ),
            ),
            const SizedBox(width: JMSpacing.md),
            // Product Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: JMSpacing.sm),
                  Text(
                    product.description,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: JMSpacing.sm),
                  Row(
                    children: [
                      Text(
                        'TSh ${NumberFormat('#,##0').format(product.price)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(width: JMSpacing.md),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStockColor(product.stock),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${product.stock} in stock',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Actions
            PopupMenuButton<String>(
              onSelected: (value) => _handleProductAction(value, product),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit),
                      SizedBox(width: 8),
                      Text('Edit Product'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'stock',
                  child: Row(
                    children: [
                      Icon(Icons.inventory_2),
                      SizedBox(width: 8),
                      Text('Update Stock'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'view',
                  child: Row(
                    children: [
                      Icon(Icons.visibility),
                      SizedBox(width: 8),
                      Text('View Details'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete),
                      SizedBox(width: 8),
                      Text('Delete Product'),
                    ],
                  ),
                ),
              ],
              child: const Icon(Icons.more_vert),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStockColor(int stockQuantity) {
    if (stockQuantity == 0) {
      return Colors.red;
    } else if (stockQuantity <= 10) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }

  void _addNewProduct() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddProductScreen(),
      ),
    );
  }

  void _exportInventory() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Exporting inventory...'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );

    // Fetch products
    final List<ProductModel> products = await _dbService.streamProducts().first;

    if (products.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No products to export.')),
      );
      return;
    }

    // Prepare data for CSV
    List<List<dynamic>> csvData = [
      [
        'ID',
        'Name',
        'Description',
        'Price',
        'Stock',
        'Category',
        'SKU',
        'Supplier',
        'Weight',
        'Length',
        'Width',
        'Height',
        'Is Available',
        'Image URL',
        'Created At',
        'Updated At',
      ],
    ];

    for (var product in products) {
      csvData.add([
        product.id,
        product.name,
        product.description,
        product.price,
        product.stock,
        product.categoryId,
        product.sku,
        product.supplier,
        product.weight,
        product.length,
        product.width,
        product.height,
        product.isAvailable,
        product.imageUrl,
        product.createdAt.toIso8601String(),
        product.updatedAt.toIso8601String(),
      ]);
    }

    // Convert to CSV string
    String csvString = const ListToCsvConverter().convert(csvData);

    // Create a Blob and initiate download
    final bytes = utf8.encode(csvString);
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute('download', 'inventory_export_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv')
      ..click();
    html.Url.revokeObjectUrl(url);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Inventory exported successfully!'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _handleProductAction(String action, ProductModel product) {
    switch (action) {
      case 'edit':
        _editProduct(product);
        break;
      case 'stock':
        _updateStock(product);
        break;
      case 'view':
        _viewProductDetails(product);
        break;
      case 'delete':
        _deleteProduct(product);
        break;
    }
  }

  void _editProduct(ProductModel product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProductScreen(product: product),
      ),
    );
  }

  void _updateStock(ProductModel product) {
    final TextEditingController stockController =
        TextEditingController(text: product.stock.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update Stock for ${product.name}'),
        content: TextField(
          controller: stockController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'New Stock Quantity',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final int? newStock = int.tryParse(stockController.text);
              if (newStock != null && newStock >= 0) {
                await _dbService.updateProduct(product.id, {'stock': newStock});
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Stock updated for ${product.name}')),
                );
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Invalid stock quantity')),
                );
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _viewProductDetails(ProductModel product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailsScreen(product: product),
      ),
    );
  }

  void _deleteProduct(ProductModel product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete ${product.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _dbService.deleteProduct(product.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Product ${product.name} deleted successfully!')),
                );
                Navigator.pop(context, true);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to delete product: $e')),
                );
                Navigator.pop(context, false);
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

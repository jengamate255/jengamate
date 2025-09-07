import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jengamate/models/product_model.dart';
import 'package:jengamate/services/database_service.dart';
import 'package:jengamate/ui/design_system/layout/adaptive_padding.dart';
import 'package:jengamate/ui/design_system/tokens/spacing.dart';
import 'package:jengamate/ui/design_system/components/jm_card.dart';
import 'package:jengamate/models/user_model.dart';
import 'package:intl/intl.dart';

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
    final currentUser = Provider.of<UserModel?>(context);

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
            horizontal: JMSpacing.sm, vertical: JMSpacing.xs),
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
              child: product.imageUrl != null
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
                  const SizedBox(height: JMSpacing.xs),
                  Text(
                    product.description,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: JMSpacing.xs),
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
    // TODO: Navigate to add product screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Add product feature coming soon!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _exportInventory() {
    // TODO: Export inventory to Excel/CSV
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Exporting inventory...'),
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
    // TODO: Navigate to edit product screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Editing product: ${product.name}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _updateStock(ProductModel product) {
    // TODO: Show stock update dialog
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Updating stock for: ${product.name}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _viewProductDetails(ProductModel product) {
    // TODO: Navigate to product details screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Viewing details for: ${product.name}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _deleteProduct(ProductModel product) {
    // TODO: Show delete confirmation dialog
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Deleting product: ${product.name}'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

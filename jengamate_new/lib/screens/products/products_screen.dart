import 'package:flutter/material.dart';
import 'package:jengamate/models/product_model.dart';
import 'package:jengamate/models/category_model.dart';
import 'package:jengamate/screens/products/widgets/product_card.dart';
import 'package:jengamate/services/database_service.dart';
import 'package:jengamate/ui/design_system/components/responsive_wrapper.dart';
import 'package:jengamate/ui/design_system/tokens/spacing.dart';
import 'package:jengamate/utils/responsive.dart';
import 'package:provider/provider.dart';
import 'package:jengamate/services/user_state_provider.dart';
import 'package:jengamate/ui/design_system/components/jm_skeleton.dart';
import 'package:jengamate/ui/design_system/components/jm_card.dart';

import '../../models/user_model.dart';
import 'package:jengamate/models/enums/user_role.dart';
import '../admin/add_edit_product_screen.dart';
import 'widgets/filter_dialog.dart';
import 'widgets/sort_dialog.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final DatabaseService _dbService = DatabaseService();
  String _searchQuery = '';
  bool _isHotFilter = false;
  double? _minPrice;
  double? _maxPrice;
  String? _selectedCategory;
  String _sortOption = 'name';

  @override
  Widget build(BuildContext context) {
    final userState = Provider.of<UserStateProvider>(context);
    final currentUser = userState.currentUser;

    final screenSize = MediaQuery.of(context).size;
    final isMobile = screenSize.width < 600;
    final isTablet = screenSize.width >= 600 && screenSize.width < 1200;
    final isDesktop = screenSize.width >= 1200;

    // Calculate responsive grid columns
    final crossAxisCount = isDesktop ? 6 : (isTablet ? 4 : 2);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        centerTitle: true,
        actions: [
          if (!isMobile) ...[
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () => _showSearchDialog(context),
              tooltip: 'Search',
            ),
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: () => _showFilterDialog(context),
              tooltip: 'Filter',
            ),
            IconButton(
              icon: const Icon(Icons.sort),
              onPressed: () => _showSortDialog(context),
              tooltip: 'Sort',
            ),
          ],
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Header section
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 16 : 24,
                vertical: 16,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Marketplace',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                        ),
                      ),
                      if (Navigator.of(context).canPop() && isMobile)
                        IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                    ],
                  ),
                  if (isMobile) ...[
                    const SizedBox(height: 16),
                    // Mobile search bar
                    TextField(
                      controller: TextEditingController(text: _searchQuery),
                      decoration: InputDecoration(
                        hintText: 'Search products...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                        contentPadding: const EdgeInsets.symmetric(vertical: 12.0),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    // Mobile filter and sort buttons
                    Row(
                      children: [
                        Expanded(
                          child: TextButton.icon(
                            onPressed: () => _showFilterDialog(context),
                            icon: const Icon(Icons.filter_list),
                            label: const Text('Filter'),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextButton.icon(
                            onPressed: () => _showSortDialog(context),
                            icon: const Icon(Icons.sort),
                            label: const Text('Sort'),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Categories Section
            StreamBuilder<List<CategoryModel>>(
              stream: _dbService.streamCategories(),
              builder: (context, categorySnapshot) {
                if (categorySnapshot.connectionState == ConnectionState.waiting) {
                  return Container(
                    height: 60,
                    margin: EdgeInsets.symmetric(
                      horizontal: isMobile ? 16 : 24,
                      vertical: 8,
                    ),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: 6,
                      itemBuilder: (context, index) => Container(
                        margin: const EdgeInsets.only(right: 8),
                        width: 80,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  );
                }
                if (categorySnapshot.hasError || !categorySnapshot.hasData) {
                  return const SizedBox.shrink();
                }

                final categories = categorySnapshot.data!;
                return Container(
                  height: 60,
                  margin: EdgeInsets.symmetric(
                    horizontal: isMobile ? 16 : 24,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      // All Categories option
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: const Text('All'),
                          selected: _selectedCategory == null,
                          onSelected: (selected) {
                            setState(() {
                              _selectedCategory = null;
                            });
                          },
                          backgroundColor: Colors.grey[100],
                          selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          checkmarkColor: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      // Category chips in horizontal scroll
                      Expanded(
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: categories.map((category) {
                            final isSelected = _selectedCategory == category.uid;
                            return Container(
                              margin: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                label: Text(category.name),
                                selected: isSelected,
                                onSelected: (selected) {
                                  setState(() {
                                    _selectedCategory = selected ? category.uid : null;
                                  });
                                },
                                backgroundColor: Colors.grey[100],
                                selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                checkmarkColor: Theme.of(context).colorScheme.primary,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            // Products Grid - takes remaining space
            Expanded(
              child: StreamBuilder<List<ProductModel>>(
                stream: _dbService.streamProducts(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return _buildLoadingGrid(crossAxisCount);
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Colors.red[300],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Error loading products',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            snapshot.error.toString(),
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No products found',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Check back later for new products',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  var products = snapshot.data!;

                  // Apply filters
                  final filteredProducts = products.where((product) {
                    final searchMatch = _searchQuery.isEmpty ||
                        product.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                        product.description?.toLowerCase().contains(_searchQuery.toLowerCase()) == true;
                    final hotMatch = !_isHotFilter || product.isHot;
                    final minPriceMatch = _minPrice == null || product.price >= _minPrice!;
                    final maxPriceMatch = _maxPrice == null || product.price <= _maxPrice!;
                    final categoryMatch = _selectedCategory == null || product.categoryId == _selectedCategory;
                    return searchMatch && hotMatch && minPriceMatch && maxPriceMatch && categoryMatch;
                  }).toList();

                  // Apply sorting
                  filteredProducts.sort((a, b) {
                    switch (_sortOption) {
                      case 'name':
                        return a.name.compareTo(b.name);
                      case 'price_asc':
                        return a.price.compareTo(b.price);
                      case 'price_desc':
                        return b.price.compareTo(a.price);
                      case 'newest':
                        return b.createdAt.compareTo(a.createdAt);
                      case 'oldest':
                        return a.createdAt.compareTo(b.createdAt);
                      default:
                        return 0;
                    }
                  });

                  return GridView.builder(
                    padding: EdgeInsets.all(isMobile ? 16 : 24),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      childAspectRatio: isDesktop ? 0.65 : (isTablet ? 0.7 : 0.8),
                      mainAxisSpacing: isMobile ? 12 : 16,
                      crossAxisSpacing: isMobile ? 12 : 16,
                    ),
                    itemCount: filteredProducts.length,
                    itemBuilder: (context, index) {
                      return ProductCard(product: filteredProducts[index]);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: (currentUser?.role == UserRole.admin ||
              currentUser?.role == UserRole.supplier)
          ? FloatingActionButton.extended(
              heroTag: "addProductButton",
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const AddEditProductScreen(),
                  ),
                );
              },
              label: const Text('Add New Product'),
              icon: const Icon(Icons.add),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildLoadingGrid(int crossAxisCount) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 0.8,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
      ),
      itemCount: crossAxisCount * 4, // Show 4 rows of loading items
      itemBuilder: (context, index) => JMCard(
        child: Column(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 12),
            JMSkeleton(height: 16, width: 120),
            const SizedBox(height: 8),
            JMSkeleton(height: 14, width: 80),
          ],
        ),
      ),
    );
  }

  void _showSearchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Products'),
        content: TextField(
          controller: TextEditingController(text: _searchQuery),
          decoration: const InputDecoration(
            hintText: 'Enter product name...',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (value) => _searchQuery = value,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {});
              Navigator.of(context).pop();
            },
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog(BuildContext context) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => FilterDialog(
        initialIsHot: _isHotFilter,
        initialMinPrice: _minPrice,
        initialMaxPrice: _maxPrice,
        initialCategory: _selectedCategory,
      ),
    );
    if (result != null) {
      setState(() {
        _isHotFilter = result['isHot'] ?? false;
        _minPrice = result['minPrice'];
        _maxPrice = result['maxPrice'];
        _selectedCategory = result['category'];
      });
    }
  }

  void _showSortDialog(BuildContext context) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => SortDialog(initialSortOption: _sortOption),
    );
    if (result != null) {
      setState(() {
        _sortOption = result;
      });
    }
  }
}
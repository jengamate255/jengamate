import 'package:flutter/material.dart';
import 'package:jengamate/models/product_model.dart';
import 'package:jengamate/models/category_model.dart';
import 'package:jengamate/screens/products/widgets/product_card.dart';
import 'package:jengamate/services/database_service.dart';
import 'package:jengamate/ui/design_system/components/responsive_wrapper.dart';
import 'package:jengamate/ui/design_system/tokens/spacing.dart';
import 'package:jengamate/utils/responsive.dart';
import 'package:provider/provider.dart';
import 'package:jengamate/ui/design_system/components/jm_skeleton.dart';
import 'package:jengamate/ui/design_system/components/jm_card.dart';

import '../../models/user_model.dart';
import 'package:jengamate/models/enums/user_role.dart';
import '../admin/add_edit_product_screen.dart';
import '../categories/category_form_screen.dart';
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
    final currentUser = Provider.of<UserModel?>(context);
    return ResponsiveScaffold(
      appBar: AppBar(
        title: const Text('Products'),
      ),
      body: Padding(
        padding: Responsive.getResponsivePadding(context),
        child: Column(
          children: [
            const SizedBox(height: JMSpacing.md),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Marketplace',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                if (Navigator.of(context).canPop())
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
              ],
            ),
            const SizedBox(height: JMSpacing.md),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: TextEditingController(text: _searchQuery),
                    decoration: InputDecoration(
                      hintText: 'Search products...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[200],
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 14.0),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),
                const SizedBox(width: JMSpacing.sm),
                TextButton.icon(
                  onPressed: () async {
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
                  },
                  icon: const Icon(Icons.filter_list),
                  label: const Text('Filter'),
                ),
                TextButton.icon(
                  onPressed: () async {
                    final result = await showDialog<String>(
                      context: context,
                      builder: (context) =>
                          SortDialog(initialSortOption: _sortOption),
                    );
                    if (result != null) {
                      setState(() {
                        _sortOption = result;
                      });
                    }
                  },
                  icon: const Icon(Icons.sort),
                  label: const Text('Sort'),
                ),
              ],
            ),
            const SizedBox(height: JMSpacing.md),
            // Categories Section
            StreamBuilder<List<CategoryModel>>(
              stream: _dbService.streamCategories(),
              builder: (context, categorySnapshot) {
                if (categorySnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return SizedBox(
                    height: 40,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: 4,
                      itemBuilder: (context, index) => Container(
                        margin: const EdgeInsets.only(right: JMSpacing.sm),
                        width: 80,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(JMSpacing.sm),
                        ),
                      ),
                    ),
                  );
                }
                if (categorySnapshot.hasError || !categorySnapshot.hasData) {
                  return const SizedBox();
                }

                final categories = categorySnapshot.data!;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: JMSpacing.xs),
                      child: Text(
                        'Categories',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                    ),
                    const SizedBox(height: JMSpacing.sm),
                    SizedBox(
                      height: 50,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: EdgeInsets.zero,
                        children: [
                          // All Categories option
                          Container(
                            margin: const EdgeInsets.only(right: JMSpacing.sm),
                            child: FilterChip(
                              label: const Text('All'),
                              selected: _selectedCategory == null,
                              onSelected: (selected) {
                                setState(() {
                                  _selectedCategory = null;
                                });
                                // Trigger a rebuild of the product grid
                                setState(() {});
                              },
                              backgroundColor: Colors.grey[100],
                              selectedColor: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withValues(alpha: 0.1),
                              checkmarkColor:
                                  Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          // Category chips
                          ...categories.map((category) {
                            final isSelected =
                                _selectedCategory == category.uid;
                            return Container(
                              margin:
                                  const EdgeInsets.only(right: JMSpacing.sm),
                              child: FilterChip(
                                label: Text(category.name),
                                selected: isSelected,
                                onSelected: (selected) {
                                  setState(() {
                                    _selectedCategory =
                                        selected ? category.uid : null;
                                  });
                                  // Trigger a rebuild of the product grid
                                  setState(() {});
                                },
                                backgroundColor: Colors.grey[100],
                                selectedColor: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withValues(alpha: 0.1),
                                checkmarkColor:
                                    Theme.of(context).colorScheme.primary,
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(height: JMSpacing.md),
                  ],
                );
              },
            ),
            Expanded(
              child: StreamBuilder<List<ProductModel>>(
                stream: _dbService.streamProducts(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return GridView.builder(
                      padding: const EdgeInsets.all(JMSpacing.md),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: ResponsiveLayout.getGridCrossAxisCount(
                          context,
                          mobile: 2,
                          tablet: 3,
                          desktop: 4,
                          largeDesktop: 5,
                        ),
                        childAspectRatio: 0.75,
                        mainAxisSpacing: JMSpacing.md,
                        crossAxisSpacing: JMSpacing.md,
                      ),
                      itemCount: ResponsiveLayout.getGridCrossAxisCount(
                            context,
                            mobile: 2,
                            tablet: 3,
                            desktop: 4,
                            largeDesktop: 5,
                          ) *
                          2,
                      itemBuilder: (context, index) => const JMCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            JMSkeleton(height: 140),
                            SizedBox(height: JMSpacing.sm),
                            JMSkeleton(height: 16, width: 120),
                            SizedBox(height: JMSpacing.xs),
                            JMSkeleton(height: 16, width: 80),
                          ],
                        ),
                      ),
                    );
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No products found.'));
                  }

                  var products = snapshot.data!;

                  final filteredProducts = products.where((product) {
                    final searchMatch = _searchQuery.isEmpty ||
                        product.name
                            .toLowerCase()
                            .contains(_searchQuery.toLowerCase());
                    final hotMatch = !_isHotFilter || product.isHot;
                    final minPriceMatch =
                        _minPrice == null || product.price >= _minPrice!;
                    final maxPriceMatch =
                        _maxPrice == null || product.price <= _maxPrice!;
                    final categoryMatch = _selectedCategory == null ||
                        product.categoryId == _selectedCategory;
                    return searchMatch &&
                        hotMatch &&
                        minPriceMatch &&
                        maxPriceMatch &&
                        categoryMatch;
                  }).toList();

                  filteredProducts.sort((a, b) {
                    switch (_sortOption) {
                      case 'name':
                        return a.name.compareTo(b.name);
                      case 'price_asc':
                        return a.price.compareTo(b.price);
                      case 'price_desc':
                        return b.price.compareTo(a.price);
                      default:
                        return 0;
                    }
                  });

                  return GridView.builder(
                    padding: const EdgeInsets.all(JMSpacing.md),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: ResponsiveLayout.getGridCrossAxisCount(
                        context,
                        mobile: 2,
                        tablet: 3,
                        desktop: 4,
                        largeDesktop: 5,
                      ),
                      childAspectRatio: 0.75,
                      mainAxisSpacing: JMSpacing.md,
                      crossAxisSpacing: JMSpacing.md,
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
}

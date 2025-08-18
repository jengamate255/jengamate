import 'package:flutter/material.dart';
import 'package:jengamate/models/product_model.dart';
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
          Expanded(
            child: StreamBuilder<List<ProductModel>>(
              stream: _dbService.streamProducts(
                categoryId: _selectedCategory,
              ),
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
                    ) * 2,
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
                      product.name.toLowerCase().contains(_searchQuery.toLowerCase());
                                    final hotMatch = !_isHotFilter || product.isHot;
                  final minPriceMatch = _minPrice == null || product.price >= _minPrice!;
                  final maxPriceMatch = _maxPrice == null || product.price <= _maxPrice!;
                  return searchMatch && hotMatch && minPriceMatch && maxPriceMatch;
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

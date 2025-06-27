import 'package:flutter/material.dart';
import 'package:jengamate/models/listing_product_model.dart';
import 'package:jengamate/screens/products/widgets/product_card.dart';
import 'package:jengamate/services/database_service.dart';

class ProductsScreen extends StatelessWidget {
  const ProductsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final DatabaseService dbService = DatabaseService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          // Filter and Sort buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.filter_list),
                  label: const Text('Filter'),
                  onPressed: () {},
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  icon: const Icon(Icons.sort),
                  label: const Text('Sort'),
                  onPressed: () {},
                ),
              ],
            ),
          ),

          // Product Grid
          Expanded(
            child: StreamBuilder<List<ListingProduct>>(
              stream: dbService.getProductsStream(),
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

                final products = snapshot.data!;

                return GridView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: products.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.65,
                  ),
                  itemBuilder: (context, index) {
                    return ProductCard(product: products[index]);
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

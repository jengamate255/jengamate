import 'package:flutter/material.dart';
import 'package:jengamate/models/listing_product_model.dart';
import 'package:jengamate/utils/theme.dart';

class ProductCard extends StatelessWidget {
  final ListingProduct product;

  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Image with 'Hot' badge
          Stack(
            children: [
              Image.network(
                product.imageUrl,
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
                // Placeholder for loading and error states
                loadingBuilder: (context, child, progress) {
                  return progress == null ? child : const Center(child: CircularProgressIndicator());
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 120,
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.image_not_supported, color: Colors.grey, size: 40),
                  );
                },
              ),
              if (product.isHot)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('Hot', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ),
            ],
          ),

          // Product Details
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  product.price,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text('Available: ${product.availability}', style: Theme.of(context).textTheme.bodySmall),
                const Divider(height: 16),
                Row(
                  children: [
                    const Icon(Icons.storefront, size: 16, color: AppTheme.subTextColor),
                    const SizedBox(width: 4),
                    Text(product.serviceProvider, style: Theme.of(context).textTheme.bodySmall),
                    const Spacer(),
                    const Icon(Icons.verified, size: 16, color: AppTheme.primaryColor),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

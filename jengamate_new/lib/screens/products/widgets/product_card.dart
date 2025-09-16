import 'package:flutter/material.dart';
import 'package:jengamate/models/product_model.dart';
import 'package:jengamate/screens/products/product_details_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:jengamate/utils/logger.dart';

class ProductCard extends StatelessWidget {
  final ProductModel product;

  const ProductCard({
    super.key,
    required this.product,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isMobile = screenSize.width < 600;
    final isTablet = screenSize.width >= 600 && screenSize.width < 1200;
    final isDesktop = screenSize.width >= 1200;

    // Responsive text sizes
    final titleFontSize = isDesktop ? 16.0 : (isTablet ? 15.0 : 14.0);
    final priceFontSize = isDesktop ? 18.0 : (isTablet ? 17.0 : 16.0);
    final statusFontSize = isDesktop ? 13.0 : (isTablet ? 12.0 : 11.0);

    return Card(
      elevation: isDesktop ? 4 : (isTablet ? 2 : 0),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
        side: BorderSide(color: Colors.grey.shade300, width: isDesktop ? 1.5 : 1),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailsScreen(product: product),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Product Image Section - Responsive height
            Expanded(
              child: Stack(
                children: [
                  Hero(
                    tag: 'product-image-${product.id}',
                    child: (product.imageUrl.isEmpty || product.imageUrl == '')
                        ? Container(
                            color: Colors.grey[100],
                            child: Center(
                              child: Icon(
                                Icons.inventory_2_outlined,
                                color: Colors.grey[400],
                                size: isMobile ? 32 : 40,
                              ),
                            ),
                          )
                        : CachedNetworkImage(
                            imageUrl: product.imageUrl,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            placeholder: (context, url) => Container(
                              color: Colors.grey[100],
                              child: Center(
                                child: Icon(
                                  Icons.image,
                                  color: Colors.grey[300],
                                  size: isMobile ? 32 : 40,
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) {
                              // Only log error for non-empty URLs to reduce spam
                              if (url.isNotEmpty) {
                                Logger.log('Image load failed for product ${product.id}: $error');

                                // Check if it's an encoding error and provide more specific feedback
                                if (error.toString().contains('EncodingError') ||
                                    error.toString().contains('cannot be decoded')) {
                                  Logger.log('Image encoding error for product ${product.id} - URL may be corrupted or invalid: $url');
                                }
                              }
                              return Container(
                                color: Colors.grey[100],
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.broken_image_outlined,
                                        color: Colors.grey[400],
                                        size: isMobile ? 24 : 32,
                                      ),
                                      if (!isMobile) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          'Image unavailable',
                                          style: TextStyle(
                                            color: Colors.grey[500],
                                            fontSize: 10,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),

                  // Hot product badge
                  if (product.isHot)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 6 : 8,
                          vertical: isMobile ? 2 : 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.local_fire_department,
                              color: Colors.white,
                              size: isMobile ? 12 : 14,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              'HOT',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: isMobile ? 10 : 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Category indicator
                  if (product.categoryId != null)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 6 : 8,
                          vertical: isMobile ? 2 : 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _getCategoryName(product.categoryId!),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isMobile ? 9 : 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Product Info Section - Responsive padding
            Padding(
              padding: EdgeInsets.all(isMobile ? 12 : (isTablet ? 14 : 16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Name
                  Text(
                    product.name,
                    maxLines: isDesktop ? 3 : 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: titleFontSize,
                      height: 1.2,
                    ),
                  ),

                  SizedBox(height: isMobile ? 6 : 8),

                  // Product Description (if available and space allows)
                  if (product.description != null && product.description!.isNotEmpty && isDesktop)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        product.description!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                          height: 1.3,
                        ),
                      ),
                    ),

                  // Price and Status Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Price
                      Expanded(
                        child: Text(
                          'TSh ${product.price.toStringAsFixed(0)}',
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: priceFontSize,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      // Stock Status
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 6 : 8,
                          vertical: isMobile ? 2 : 3,
                        ),
                        decoration: BoxDecoration(
                          color: product.stock > 0
                              ? Colors.green.withOpacity(0.1)
                              : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              product.stock > 0 ? Icons.check_circle : Icons.cancel,
                              color: product.stock > 0
                                  ? Colors.green.shade700
                                  : Colors.red.shade700,
                              size: isMobile ? 12 : 14,
                            ),
                            if (!isMobile) ...[
                              const SizedBox(width: 4),
                              Text(
                                product.stock > 0 ? '${product.stock}' : 'Out',
                                style: TextStyle(
                                  color: product.stock > 0
                                      ? Colors.green.shade700
                                      : Colors.red.shade700,
                                  fontSize: statusFontSize,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Additional info for larger screens
                  if (isDesktop && product.createdAt != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Added ${_formatDate(product.createdAt!)}',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 10,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getCategoryName(String categoryId) {
    // This would ideally come from a category service/cache
    // For now, return a shortened version
    return categoryId.length > 10 ? categoryId.substring(0, 10) + '...' : categoryId;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks week${weeks > 1 ? 's' : ''} ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months month${months > 1 ? 's' : ''} ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years year${years > 1 ? 's' : ''} ago';
    }
  }
}

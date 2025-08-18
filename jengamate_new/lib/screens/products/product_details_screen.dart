import 'package:flutter/material.dart';
import 'package:jengamate/models/product_model.dart';
import 'package:jengamate/utils/theme.dart';
import 'package:jengamate/services/database_service.dart'; // Import DatabaseService
import 'package:jengamate/models/user_model.dart'; // Import UserModel
import 'package:provider/provider.dart'; // Import Provider
import 'package:jengamate/models/enums/user_role.dart'; // Import UserRole
import 'package:go_router/go_router.dart';
import 'package:jengamate/config/app_routes.dart';
import 'package:jengamate/ui/design_system/layout/adaptive_padding.dart';
import 'package:jengamate/ui/design_system/tokens/spacing.dart';
import 'package:jengamate/ui/design_system/components/jm_card.dart';

class ProductDetailsScreen extends StatefulWidget {
  final ProductModel product;

  const ProductDetailsScreen({super.key, required this.product});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = Provider.of<UserModel?>(context);
    final dbService = DatabaseService();

    // Determine which image URLs to use
    final List<String> imageUrls =
        widget.product.variants.isNotEmpty && widget.product.variants.first.imageUrls.isNotEmpty
            ? widget.product.variants.first.imageUrls
            : [widget.product.imageUrl];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product.name),
        actions: [
          if (currentUser?.role == UserRole.admin ||
              currentUser?.role == UserRole.supplier)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                context.push(AppRoutes.addEditProduct, extra: widget.product);
              },
            ),
          if (currentUser?.role == UserRole.admin ||
              currentUser?.role == UserRole.supplier)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () async {
                final bool? confirmDelete = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Product'),
                    content: Text(
                        'Are you sure you want to delete ${widget.product.name}?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );

                if (confirmDelete == true) {
                  try {
                    await dbService.addOrUpdateProduct(
                        widget.product.copyWith(isDeleted: true));
                    if (context.mounted) {
                      context.pop(); // Go back after deletion
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error deleting product: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                }
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: AdaptivePadding(
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imageUrls.isNotEmpty)
              JMCard(
                child: Column(
                  children: [
                    SizedBox(
                      height: 240,
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: imageUrls.length,
                        onPageChanged: (index) {
                          setState(() {
                            _currentPage = index;
                          });
                        },
                        itemBuilder: (context, index) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(8.0),
                            child: Image.network(
                              imageUrls[index],
                              width: double.infinity,
                              height: 240,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                      width: double.infinity,
                                      height: 240,
                                      color: Colors.grey,
                                      child: const Icon(Icons.broken_image)),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: JMSpacing.sm),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        imageUrls.length,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          margin: const EdgeInsets.symmetric(horizontal: 4.0),
                          height: 8.0,
                          width: _currentPage == index ? 24.0 : 8.0,
                          decoration: BoxDecoration(
                            color: _currentPage == index
                                ? AppTheme.primaryColor
                                : Colors.grey,
                            borderRadius: BorderRadius.circular(4.0),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: JMSpacing.lg),
            Text(
              widget.product.name,
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: JMSpacing.sm),
            Text(
              'TSH ${widget.product.price.toStringAsFixed(2)}',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(color: AppTheme.primaryColor),
            ),
            const SizedBox(height: JMSpacing.lg),
            Text(
              widget.product.description,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: JMSpacing.xl),
            Text(
              'Product Details',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: JMSpacing.lg),
            JMCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow('Type', widget.product.type),
                  _buildDetailRow('Thickness', widget.product.thickness),
                  _buildDetailRow('Color', widget.product.color),
                  _buildDetailRow('Dimensions', widget.product.dimensions),
                  _buildDetailRow(
                      'Stock', widget.product.stock > 0 ? '${widget.product.stock} available' : 'Out of Stock'),
                  _buildDetailRow('Service Provider', widget.product.serviceProvider),
                ],
              ),
            ),
            if (widget.product.isHot)
              Padding(
                padding: const EdgeInsets.only(top: JMSpacing.sm),
                child: Text('🔥 Hot Deal!',
                    style: TextStyle(
                        color: Colors.red, fontWeight: FontWeight.bold)),
              ),
            const SizedBox(height: JMSpacing.xl),

            // Removed Reviews Section to match screenshot
            // Row(
            //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
            //   children: [
            //     Text(
            //       'Customer Reviews',
            //       style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            //     ),
            //     if (currentUser != null) // Only show submit button if user is logged in
            //       ElevatedButton(
            //         onPressed: () {
            //           showDialog(
            //             context: context,
            //             builder: (context) => SubmitReviewDialog(productId: product.id),
            //           );
            //         },
            //         child: const Text('Submit Review'),
            //       ),
            //   ],
            // ),
            // const SizedBox(height: 16),
            // StreamBuilder<List<ReviewModel>>(
            //   stream: dbService.getProductReviews(product.id),
            //   builder: (context, snapshot) {
            //     if (snapshot.connectionState == ConnectionState.waiting) {
            //       return const Center(child: CircularProgressIndicator());
            //     }
            //     if (snapshot.hasError) {
            //       return Center(child: Text('Error loading reviews: ${snapshot.error}'));
            //     }
            //     if (!snapshot.hasData || snapshot.data!.isEmpty) {
            //       return const Center(child: Text('No reviews yet. Be the first to review!'));
            //     }
            //
            //     final reviews = snapshot.data!;
            //     return ListView.builder(
            //       shrinkWrap: true,
            //       physics: const NeverScrollableScrollPhysics(),
            //       itemCount: reviews.length,
            //       itemBuilder: (context, index) {
            //         final review = reviews[index];
            //         return FutureBuilder<UserModel?>(
            //           future: dbService.getUser(review.userId),
            //           builder: (context, userSnapshot) {
            //             if (userSnapshot.connectionState == ConnectionState.waiting) {
            //               return const ListTile(title: Text('Loading review...'));
            //             }
            //             if (userSnapshot.hasError) {
            //               return const ListTile(title: Text('Error loading user for review'));
            //             }
            //             final reviewUser = userSnapshot.data;
            //             final reviewerName = reviewUser?.name ?? 'Anonymous';
            //
            //             return Card(
            //               margin: const EdgeInsets.only(bottom: 8.0),
            //               child: Padding(
            //                 padding: const EdgeInsets.all(16.0),
            //                 child: Column(
            //                   crossAxisAlignment: CrossAxisAlignment.start,
            //                   children: [
            //                     Row(
            //                       children: [
            //                         Text(reviewerName, style: const TextStyle(fontWeight: FontWeight.bold)),
            //                         const SizedBox(width: 8),
            //                         Row(
            //                           children: List.generate(5, (starIndex) {
            //                             return Icon(
            //                               starIndex < review.rating ? Icons.star : Icons.star_border,
            //                               color: Colors.amber,
            //                               size: 16,
            //                             );
            //                           }),
            //                         ),
            //                       ],
            //                     ),
            //                     const SizedBox(height: 8),
            //                     Text(review.comment),
            //                     const SizedBox(height: 4),
            //                     Text(
            //                       DateFormat('MMM dd, yyyy').format(review.timestamp),
            //                       style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            //                     ),
            //                   ],
            //                 ),
            //               ),
            //             );
            //           },
            //         );
            //       },
            //     );
            //   },
            // ),
            if (currentUser?.role == UserRole.engineer)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: JMSpacing.lg),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        context.go(AppRoutes.inquirySubmission,
                            extra: {'productId': widget.product.id});
                      },
                      child: const Text('Make Inquiry'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        final path = AppRouteBuilders.rfqSubmissionPath(
                          productId: widget.product.id,
                          productName: widget.product.name,
                        );
                        context.go(path);
                      },
                      child: const Text('Request for Quotation'),
                    ),
                  ],
                ),
              ),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: JMSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120, // Adjust width as needed for alignment
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}

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
import 'package:jengamate/services/product_interaction_service.dart';
import 'package:video_player/video_player.dart';

class ProductDetailsScreen extends StatefulWidget {
  final ProductModel product;

  const ProductDetailsScreen({super.key, required this.product});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  late PageController _pageController;
  int _currentPage = 0;
  VideoPlayerController? _videoController;
  List<(String, String)> _mediaItems = [];
  final ProductInteractionService _interactionService = ProductInteractionService();

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _buildMediaList();
    _initializeVideo();
    _trackProductView();
  }

  /// Track product view when screen loads
  void _trackProductView() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = Provider.of<UserModel?>(context, listen: false);
      if (user != null) {
        _interactionService.trackProductInteraction(
          product: widget.product,
          user: user,
          interactionType: 'view',
          additionalContext: {
            'screen': 'product_details',
            'timestamp': DateTime.now().toIso8601String(),
          },
        );
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  void _buildMediaList() {
    final List<String> allImages = [];

    // Add product images
    if (widget.product.imageUrls.isNotEmpty) {
      allImages.addAll(widget.product.imageUrls);
    } else if (widget.product.imageUrl.isNotEmpty) {
      allImages.add(widget.product.imageUrl);
    }

    // Add variant images
    for (final variant in widget.product.variants) {
      allImages.addAll(variant.imageUrls);
    }

    // Remove duplicates
    final uniqueImages = allImages.toSet().toList();

    _mediaItems = [];

    // Add video first if available (as requested)
    if (widget.product.videoUrl != null && widget.product.videoUrl!.isNotEmpty) {
      _mediaItems.add(('video', widget.product.videoUrl!));
    }

    // Add images
    for (final imageUrl in uniqueImages) {
      _mediaItems.add(('image', imageUrl));
    }
  }

  void _initializeVideo() {
    if (widget.product.videoUrl != null && widget.product.videoUrl!.isNotEmpty) {
      _videoController = VideoPlayerController.networkUrl(Uri.parse(widget.product.videoUrl!))
        ..initialize().then((_) {
          if (mounted) {
            setState(() {});
            // Auto-play if video is the first item and currently visible
            if (_currentPage == 0 && _mediaItems.isNotEmpty && _mediaItems[0].$1 == 'video') {
              _videoController?.play();
            }
          }
        })
        ..setLooping(true) // Loop video as requested
        ..setVolume(0.0); // Mute by default as requested
    }
  }

  void _onPageChanged(int index) {
    // For multi-panel carousel, index represents the selected media item
    if (_mediaItems.length <= 1) return;

    setState(() {
      _currentPage = index;
    });

    // Handle video autoplay when visible
    if (_mediaItems.isNotEmpty && index < _mediaItems.length) {
      final (type, _) = _mediaItems[index];
      if (type == 'video' && _videoController != null) {
        if (_videoController!.value.isInitialized) {
          _videoController!.play();
        }
      } else {
        // Pause video when not visible
        _videoController?.pause();
      }
    }

    // Auto-scroll to the correct page in the carousel if needed
    if (_mediaItems.length > 3) {
      final targetPage = (index / 3).floor();
      final currentCarouselPage = _pageController.hasClients
          ? (_pageController.page ?? 0).round()
          : 0;

      if (targetPage != currentCarouselPage) {
        _pageController.animateToPage(
          targetPage,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = Provider.of<UserModel?>(context);
    final dbService = DatabaseService();

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
            if (_mediaItems.isNotEmpty)
              JMCard(
                child: Column(
                  children: [
                    // Multi-panel carousel view
                    SizedBox(
                      height: 200, // Reduced height for multi-panel view
                      child: _mediaItems.length == 1
                          ? _buildSingleMediaPanel()
                          : _buildMultiPanelCarousel(),
                    ),
                    const SizedBox(height: JMSpacing.sm),
                    // Page indicators
                    if (_mediaItems.length > 1)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          _mediaItems.length,
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
                        _trackInquiryClick();
                        context.go(AppRoutes.inquirySubmission,
                            extra: {'productId': widget.product.id});
                      },
                      child: const Text('Make Inquiry'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        _trackRFQClick();
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

  Widget _buildSingleMediaPanel() {
    final (type, url) = _mediaItems[0];
    return ClipRRect(
      borderRadius: BorderRadius.circular(8.0),
      child: type == 'video'
          ? _buildVideoPanel(url)
          : _buildImagePanel(url),
    );
  }

  Widget _buildMultiPanelCarousel() {
    return PageView.builder(
      controller: _pageController,
      onPageChanged: _onPageChanged,
      itemCount: (_mediaItems.length / 3).ceil(), // Show 3 panels per page
      itemBuilder: (context, pageIndex) {
        return _buildMediaPanelPage(pageIndex);
      },
    );
  }

  Widget _buildMediaPanelPage(int pageIndex) {
    final startIndex = pageIndex * 3;
    final endIndex = (startIndex + 3).clamp(0, _mediaItems.length);
    final pageItems = _mediaItems.sublist(startIndex, endIndex);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Row(
        children: [
          for (int i = 0; i < pageItems.length; i++)
            Expanded(
              child: Container(
                margin: EdgeInsets.only(
                  left: i > 0 ? 4.0 : 0,
                  right: i < pageItems.length - 1 ? 4.0 : 0,
                ),
                child: _buildMediaPanelItem(pageItems[i], startIndex + i),
              ),
            ),
          // Fill remaining space if less than 3 items
          for (int i = pageItems.length; i < 3; i++)
            Expanded(
              child: Container(
                margin: EdgeInsets.only(left: i > 0 ? 4.0 : 0),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Center(
                  child: Icon(
                    Icons.add_photo_alternate_outlined,
                    color: Colors.grey.shade400,
                    size: 32,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMediaPanelItem((String, String) mediaItem, int globalIndex) {
    final (type, url) = mediaItem;
    final isSelected = globalIndex == _currentPage;

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentPage = globalIndex;
        });
        _onPageChanged(globalIndex);
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
            width: isSelected ? 2.0 : 1.0,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6.0),
          child: Stack(
            fit: StackFit.expand,
            children: [
              type == 'video'
                  ? Container(
                      color: Colors.black,
                      child: _videoController != null && _videoController!.value.isInitialized
                          ? VideoPlayer(_videoController!)
                          : const Center(
                              child: Icon(Icons.video_library, color: Colors.white, size: 32),
                            ),
                    )
                  : Image.network(
                      url,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey.shade200,
                        child: const Center(
                          child: Icon(Icons.broken_image, size: 32),
                        ),
                      ),
                    ),
              // Media type indicator
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        type == 'video' ? Icons.play_circle_filled : Icons.image,
                        color: Colors.white,
                        size: 12,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        type == 'video' ? 'VIDEO' : 'IMAGE',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Selection overlay
              if (isSelected)
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6.0),
                    color: AppTheme.primaryColor.withOpacity(0.2),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.check_circle,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVideoPanel(String url) {
    if (_videoController == null || !_videoController!.value.isInitialized) {
      return Container(
        width: double.infinity,
        height: 300,
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        // Toggle play/pause on tap
        if (_videoController!.value.isPlaying) {
          _videoController!.pause();
        } else {
          _videoController!.play();
        }
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          VideoPlayer(_videoController!),
          // Play/pause overlay
          Center(
            child: AnimatedOpacity(
              opacity: _videoController!.value.isPlaying ? 0.0 : 0.8,
              duration: const Duration(milliseconds: 300),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _videoController!.value.isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
          ),
          // Mute/unmute button in top right
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: () {
                final currentVolume = _videoController!.value.volume;
                _videoController!.setVolume(currentVolume > 0 ? 0.0 : 1.0);
                setState(() {});
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _videoController!.value.volume > 0 ? Icons.volume_up : Icons.volume_off,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePanel(String url) {
    return Image.network(
      url,
      width: double.infinity,
      height: 300,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Container(
        width: double.infinity,
        height: 300,
        color: Colors.grey.shade200,
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.broken_image, size: 48, color: Colors.grey),
            SizedBox(height: 8),
            Text('Failed to load image', style: TextStyle(color: Colors.grey)),
          ],
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

  /// Track inquiry button click
  void _trackInquiryClick() {
    final user = Provider.of<UserModel?>(context, listen: false);
    if (user != null) {
      _interactionService.trackProductInteraction(
        product: widget.product,
        user: user,
        interactionType: 'inquiry_click',
        additionalContext: {
          'screen': 'product_details',
          'action': 'make_inquiry',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    }
  }

  /// Track RFQ button click
  void _trackRFQClick() {
    final user = Provider.of<UserModel?>(context, listen: false);
    if (user != null) {
      _interactionService.trackProductInteraction(
        product: widget.product,
        user: user,
        interactionType: 'rfq_click',
        additionalContext: {
          'screen': 'product_details',
          'action': 'request_quotation',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    }
  }
}

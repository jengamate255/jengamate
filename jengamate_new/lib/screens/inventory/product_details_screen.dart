import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:jengamate/models/product_model.dart';
import 'package:jengamate/ui/design_system/components/jm_card.dart';
import 'package:jengamate/ui/design_system/tokens/spacing.dart';
import 'package:jengamate/ui/design_system/tokens/typography.dart';

class ProductDetailsScreen extends StatefulWidget {
  final ProductModel product;

  const ProductDetailsScreen({Key? key, required this.product}) : super(key: key);

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  final NumberFormat _currencyFormat = NumberFormat.currency(symbol: 'TSH ', decimalDigits: 2);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product.name),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(JMSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.product.imageUrl.isNotEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: JMSpacing.md),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      widget.product.imageUrl,
                      height: 200,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.broken_image, size: 100),
                    ),
                  ),
                ),
              ),
            JMCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.product.name,
                    style: JMTypography.headingL.copyWith(
                        color: Theme.of(context).textTheme.bodyLarge?.color),
                  ),
                  const SizedBox(height: JMSpacing.sm),
                  Text(
                    widget.product.description,
                    style: JMTypography.body.copyWith(
                        color: Theme.of(context).textTheme.bodyMedium?.color),
                  ),
                  const SizedBox(height: JMSpacing.md),
                  Divider(color: Theme.of(context).dividerColor),
                  const SizedBox(height: JMSpacing.md),
                  _buildDetailRow(
                      context, 'Price', _currencyFormat.format(widget.product.price)),
                  _buildDetailRow(context, 'Stock', widget.product.stock.toString()),
                  _buildDetailRow(context, 'Category', widget.product.category),
                  _buildDetailRow(
                      context, 'SKU', widget.product.sku.isNotEmpty ? widget.product.sku : 'N/A'),
                  _buildDetailRow(context, 'Supplier',
                      widget.product.supplier.isNotEmpty ? widget.product.supplier : 'N/A'),
                  _buildDetailRow(
                      context, 'Weight', '${widget.product.weight} kg'),
                  _buildDetailRow(context, 'Dimensions',
                      '${widget.product.length}x${widget.product.width}x${widget.product.height} cm'),
                  _buildDetailRow(
                      context, 'Availability', widget.product.isAvailable ? 'In Stock' : 'Out of Stock'),
                  _buildDetailRow(
                      context,
                      'Created At',
                      DateFormat('MMM d, yyyy h:mm a')
                          .format(widget.product.createdAt)),
                  _buildDetailRow(
                      context,
                      'Last Updated',
                      DateFormat('MMM d, yyyy h:mm a')
                          .format(widget.product.updatedAt)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: JMSpacing.xxs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$label:',
            style: JMTypography.bodyStrong.copyWith(
                color: Theme.of(context).textTheme.bodyLarge?.color),
          ),
          Text(
            value,
            style: JMTypography.body.copyWith(
                color: Theme.of(context).textTheme.bodyMedium?.color),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:jengamate/models/product_model.dart';
import 'package:jengamate/widgets/custom_text_field.dart';

class ProductFormCard extends StatefulWidget {
  final Product product;
  final VoidCallback onRemove;
  final bool isRemovable;

  const ProductFormCard({
    super.key,
    required this.product,
    required this.onRemove,
    this.isRemovable = false,
  });

  @override
  State<ProductFormCard> createState() => _ProductFormCardState();
}

class _ProductFormCardState extends State<ProductFormCard> {
  final _typeController = TextEditingController();
  final _thicknessController = TextEditingController();
  final _colorController = TextEditingController();
  final _dimensionsController = TextEditingController();
  final _quantityController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _typeController.text = widget.product.type;
    _thicknessController.text = widget.product.thickness;
    _colorController.text = widget.product.color;
    _dimensionsController.text = widget.product.dimensions;
    _quantityController.text = widget.product.quantity.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Product Details',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                if (widget.isRemovable)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: widget.onRemove,
                  ),
              ],
            ),
            const Divider(height: 24),
            CustomTextField(
              controller: _typeController,
              labelText: 'Product Type (e.g., Roofing Sheet)',
              onChanged: (value) => widget.product.type = value,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    controller: _thicknessController,
                    labelText: 'Thickness (e.g., 0.4mm)',
                     onChanged: (value) => widget.product.thickness = value,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: CustomTextField(
                    controller: _colorController,
                    labelText: 'Color',
                     onChanged: (value) => widget.product.color = value,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
             Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    controller: _dimensionsController,
                    labelText: 'Dimensions (e.g., 12ft)',
                     onChanged: (value) => widget.product.dimensions = value,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: CustomTextField(
                    controller: _quantityController,
                    labelText: 'Quantity',
                    keyboardType: TextInputType.number,
                     onChanged: (value) => widget.product.quantity = int.tryParse(value) ?? 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                TextButton.icon(
                  onPressed: () async {
                    final ImagePicker picker = ImagePicker();
                    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                    if (image != null) {
                      setState(() {
                        widget.product.technicalDrawing = image;
                      });
                    }
                  },
                  icon: const Icon(Icons.attach_file),
                  label: const Text('Attach Technical Drawing'),
                ),
                const SizedBox(width: 8),
                if (widget.product.technicalDrawing != null)
                  Expanded(
                    child: Text(
                      widget.product.technicalDrawing!.name,
                      style: const TextStyle(fontStyle: FontStyle.italic),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

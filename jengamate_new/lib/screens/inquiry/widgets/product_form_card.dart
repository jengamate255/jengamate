import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:jengamate/models/product.dart';

class ProductFormCard extends StatefulWidget {
  final Product product;
  final bool isRemovable;
  final VoidCallback? onRemove;
  final ValueChanged<Product>? onChanged;

  const ProductFormCard({
    super.key,
    required this.product,
    this.isRemovable = false,
    this.onRemove,
    this.onChanged,
  });

  @override
  State<ProductFormCard> createState() => _ProductFormCardState();
}

class _ProductFormCardState extends State<ProductFormCard> {
  final _typeController = TextEditingController();
  final _thicknessController = TextEditingController();
  final _colorController = TextEditingController();
  final _lengthController = TextEditingController();
  final _quantityController = TextEditingController();
  final _remarksController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _typeController.text = widget.product.type;
    _thicknessController.text = widget.product.thickness;
    _colorController.text = widget.product.color;
    _lengthController.text = widget.product.length;
    _quantityController.text = widget.product.quantity;
    _remarksController.text = widget.product.remarks;
  }

  @override
  void dispose() {
    _typeController.dispose();
    _thicknessController.dispose();
    _colorController.dispose();
    _lengthController.dispose();
    _quantityController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  void _updateProduct() {
    widget.onChanged?.call(
      Product(
        type: _typeController.text,
        thickness: _thicknessController.text,
        color: _colorController.text,
        length: _lengthController.text,
        quantity: _quantityController.text,
        remarks: _remarksController.text,
        drawings: widget.product.drawings,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Product Details',
                    style: Theme.of(context).textTheme.titleMedium),
                if (widget.isRemovable)
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline,
                        color: Colors.red),
                    onPressed: widget.onRemove,
                  ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _typeController,
              decoration: const InputDecoration(labelText: 'Product Type'),
              onChanged: (value) => _updateProduct(),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _thicknessController,
              decoration: const InputDecoration(labelText: 'Thickness'),
              onChanged: (value) => _updateProduct(),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _colorController,
              decoration: const InputDecoration(labelText: 'Color'),
              onChanged: (value) => _updateProduct(),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _lengthController,
              decoration: const InputDecoration(labelText: 'Length'),
              onChanged: (value) => _updateProduct(),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _quantityController,
              decoration: const InputDecoration(labelText: 'Quantity'),
              onChanged: (value) => _updateProduct(),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _remarksController,
              decoration: const InputDecoration(labelText: 'Remarks'),
              onChanged: (value) => _updateProduct(),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                TextButton.icon(
                  onPressed: () async {
                    final ImagePicker picker = ImagePicker();
                    final XFile? image =
                        await picker.pickImage(source: ImageSource.gallery);
                    if (image != null) {
                      setState(() {
                        widget.product.drawings.add(image.path);
                      });
                    }
                  },
                  icon: const Icon(Icons.attach_file),
                  label: const Text('Attach Drawing'),
                ),
                const SizedBox(width: 8),
                if (widget.product.drawings.isNotEmpty)
                  Expanded(
                    child: Text(
                      widget.product.drawings.join(', '),
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

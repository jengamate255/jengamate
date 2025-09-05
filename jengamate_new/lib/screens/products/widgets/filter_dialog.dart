import 'package:flutter/material.dart';
import 'package:jengamate/models/category_model.dart';
import 'package:jengamate/services/database_service.dart';

class FilterDialog extends StatefulWidget {
  final bool initialIsHot;
  final double? initialMinPrice;
  final double? initialMaxPrice;
  final String? initialCategory;

  const FilterDialog({
    super.key,
    required this.initialIsHot,
    this.initialMinPrice,
    this.initialMaxPrice,
    this.initialCategory,
  });

  @override
  State<FilterDialog> createState() => _FilterDialogState();
}

class _FilterDialogState extends State<FilterDialog> {
  late bool _isHot;
  late TextEditingController _minPriceController;
  late TextEditingController _maxPriceController;
  String? _selectedCategory;

  final DatabaseService _dbService = DatabaseService();

  @override
  void initState() {
    super.initState();
    _isHot = widget.initialIsHot;
    _minPriceController =
        TextEditingController(text: widget.initialMinPrice?.toString() ?? '');
    _maxPriceController =
        TextEditingController(text: widget.initialMaxPrice?.toString() ?? '');
    _selectedCategory = widget.initialCategory;
  }

  @override
  void dispose() {
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Filter Products'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SwitchListTile(
            title: const Text('Hot Deals'),
            value: _isHot,
            onChanged: (value) {
              setState(() {
                _isHot = value;
              });
            },
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _minPriceController,
            decoration: const InputDecoration(
              labelText: 'Min Price',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _maxPriceController,
            decoration: const InputDecoration(
              labelText: 'Max Price',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          StreamBuilder<List<CategoryModel>>(
            stream: _dbService.streamCategories(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
              }
              if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Text('No categories found.');
              }

              final categories = snapshot.data!;

              // Validate selected category exists in current categories
              String? validatedSelectedCategory = _selectedCategory;
              if (_selectedCategory != null) {
                final exists = categories.any((c) => c.id == _selectedCategory);
                if (!exists) {
                  validatedSelectedCategory = null;
                }
              }

              return DropdownButtonFormField<String>(
                value: validatedSelectedCategory,
                hint: const Text('Select Category'),
                items: categories.map((category) {
                  return DropdownMenuItem<String>(
                    value: category.id,
                    child: Text(category.name),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _selectedCategory = newValue;
                  });
                },
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
              );
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final minPrice = double.tryParse(_minPriceController.text);
            final maxPrice = double.tryParse(_maxPriceController.text);
            Navigator.of(context).pop({
              'isHot': _isHot,
              'minPrice': minPrice,
              'maxPrice': maxPrice,
              'category': _selectedCategory,
            });
          },
          child: const Text('Apply'),
        ),
      ],
    );
  }
}

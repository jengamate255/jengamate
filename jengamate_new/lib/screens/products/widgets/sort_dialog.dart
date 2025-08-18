import 'package:flutter/material.dart';

class SortDialog extends StatefulWidget {
  final String initialSortOption;

  const SortDialog({super.key, required this.initialSortOption});

  @override
  State<SortDialog> createState() => _SortDialogState();
}

class _SortDialogState extends State<SortDialog> {
  late String _selectedSortOption;

  @override
  void initState() {
    super.initState();
    _selectedSortOption = widget.initialSortOption;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Sort by'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RadioListTile<String>(
            title: const Text('Name (A-Z)'),
            value: 'name_asc',
            groupValue: _selectedSortOption,
            onChanged: (value) {
              setState(() {
                _selectedSortOption = value!;
              });
            },
          ),
          RadioListTile<String>(
            title: const Text('Name (Z-A)'),
            value: 'name_desc',
            groupValue: _selectedSortOption,
            onChanged: (value) {
              setState(() {
                _selectedSortOption = value!;
              });
            },
          ),
          RadioListTile<String>(
            title: const Text('Price (Low-High)'),
            value: 'price_asc',
            groupValue: _selectedSortOption,
            onChanged: (value) {
              setState(() {
                _selectedSortOption = value!;
              });
            },
          ),
          RadioListTile<String>(
            title: const Text('Price (High-Low)'),
            value: 'price_desc',
            groupValue: _selectedSortOption,
            onChanged: (value) {
              setState(() {
                _selectedSortOption = value!;
              });
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(_selectedSortOption);
          },
          child: const Text('Apply'),
        ),
      ],
    );
  }
} 
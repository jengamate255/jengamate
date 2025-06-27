import 'package:flutter/material.dart';
import 'package:jengamate/models/category_model.dart';
import 'package:jengamate/screens/categories/widgets/category_card.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock data for the category list
    final List<Category> categories = [
      Category(name: 'Building Materials', icon: Icons.foundation),
      Category(name: 'Roofing', icon: Icons.roofing),
      Category(name: 'Electrical', icon: Icons.electrical_services),
      Category(name: 'Plumbing', icon: Icons.plumbing),
      Category(name: 'Paints & Finishes', icon: Icons.format_paint),
      Category(name: 'Tools & Equipment', icon: Icons.build),
      Category(name: 'Safety Gear', icon: Icons.security),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16.0),
        itemCount: categories.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          return CategoryCard(category: categories[index]);
        },
      ),
    );
  }
}

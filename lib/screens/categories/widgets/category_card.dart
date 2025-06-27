import 'package:flutter/material.dart';
import 'package:jengamate/models/category_model.dart';
import 'package:jengamate/utils/theme.dart';

class CategoryCard extends StatelessWidget {
  final Category category;

  const CategoryCard({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(category.icon, size: 28, color: AppTheme.primaryColor),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  category.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: AppTheme.subTextColor),
            ],
          ),
        ),
      ),
    );
  }
}

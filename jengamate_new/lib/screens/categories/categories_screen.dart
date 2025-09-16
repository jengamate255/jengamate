import 'package:flutter/material.dart';
import 'package:jengamate/models/category_model.dart';
import 'package:jengamate/screens/categories/widgets/category_card.dart';
import 'package:jengamate/services/database_service.dart';
import 'package:provider/provider.dart';
import 'package:jengamate/services/user_state_provider.dart';
import 'package:jengamate/screens/categories/category_form_screen.dart'; // Import the new form screen
import 'package:jengamate/ui/design_system/tokens/spacing.dart';
import 'package:jengamate/utils/responsive.dart';
import 'package:jengamate/ui/design_system/components/jm_card.dart';
import 'package:jengamate/ui/design_system/components/jm_skeleton.dart';

import '../../models/user_model.dart';
import 'package:jengamate/models/enums/user_role.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final DatabaseService dbService = DatabaseService();
    final currentUser = context.watch<UserModel?>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
      ),
      body: StreamBuilder<List<CategoryModel>>(
        stream: dbService.streamCategories(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Padding(
              padding: Responsive.getResponsivePadding(context),
              child: ListView.separated(
                itemCount: 6,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: JMSpacing.md),
                itemBuilder: (context, index) => const JMCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      JMSkeleton(height: 18, width: 160),
                      SizedBox(height: JMSpacing.xxs), // Changed from JMSpacing.xs
                      JMSkeleton(height: 14, width: 240),
                    ],
                  ),
                ),
              ),
            );
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No categories found.'));
          }

          final categories = snapshot.data!;

          return Padding(
            padding: Responsive.getResponsivePadding(context),
            child: ListView.separated(
              padding: const EdgeInsets.only(
                  top: JMSpacing.md, bottom: JMSpacing.md),
              itemCount: categories.length,
              separatorBuilder: (_, __) => const SizedBox(height: JMSpacing.md),
              itemBuilder: (context, index) {
                final category = categories[index];
                return GestureDetector(
                  onTap: () {
                    if (currentUser?.role == UserRole.admin) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              CategoryFormScreen(category: category),
                        ),
                      );
                    }
                  },
                  child: CategoryCard(category: category),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: currentUser?.role == UserRole.admin
          ? FloatingActionButton(
              heroTag: "addCategoryButton", // Unique tag for this button
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CategoryFormScreen(),
                  ),
                );
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}

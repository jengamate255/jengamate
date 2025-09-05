import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:jengamate/models/user_model.dart';
import 'package:jengamate/models/enums/user_role.dart';
import 'package:jengamate/config/app_routes.dart';

class NavigationHelper {
  // App Bar Actions for consistent navigation
  static List<Widget> buildAppBarActions(
      BuildContext context, UserModel? user) {
    return [
      // Notifications button
      IconButton(
        icon: const Icon(Icons.notifications_outlined),
        onPressed: () {
          context.go(AppRoutes.notifications);
        },
        tooltip: 'Notifications',
      ),
      // Chat button
      IconButton(
        icon: const Icon(Icons.chat_outlined),
        onPressed: () {
          context.go(AppRoutes.chatList);
        },
        tooltip: 'Chat',
      ),
      // Profile menu
      PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert),
        onSelected: (value) {
          switch (value) {
            case 'profile':
              context.go(AppRoutes.profile);
              break;
            case 'settings':
              // TODO: Navigate to settings
              break;
            case 'logout':
              // TODO: Implement logout
              break;
          }
        },
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'profile',
            child: Row(
              children: [
                Icon(Icons.person),
                SizedBox(width: 8),
                Text('Profile'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'settings',
            child: Row(
              children: [
                Icon(Icons.settings),
                SizedBox(width: 8),
                Text('Settings'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'logout',
            child: Row(
              children: [
                Icon(Icons.logout),
                SizedBox(width: 8),
                Text('Logout'),
              ],
            ),
          ),
        ],
      ),
    ];
  }

  // Quick Action Buttons Widget
  static Widget buildQuickActionButtons(BuildContext context, UserModel? user) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Actions',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              if (user?.role == UserRole.admin ||
                  user?.role == UserRole.supplier)
                _buildQuickActionButton(
                  context,
                  'Add Product',
                  Icons.add_shopping_cart,
                  () {
                    Navigator.of(context).pop();
                    context.go(AppRoutes.products);
                  },
                ),
              if (user?.role == UserRole.admin)
                _buildQuickActionButton(
                  context,
                  'Add Category',
                  Icons.category,
                  () {
                    Navigator.of(context).pop();
                    context.go(AppRoutes.categories);
                  },
                ),
              if (user?.role == UserRole.engineer ||
                  user?.role == UserRole.admin)
                _buildQuickActionButton(
                  context,
                  'New Inquiry',
                  Icons.receipt_long,
                  () {
                    Navigator.of(context).pop();
                    context.go(AppRoutes.newInquiry);
                  },
                ),
              _buildQuickActionButton(
                context,
                'Chat',
                Icons.chat,
                () {
                  Navigator.of(context).pop();
                  context.go(AppRoutes.chatList);
                },
              ),
              _buildQuickActionButton(
                context,
                'Notifications',
                Icons.notifications,
                () {
                  Navigator.of(context).pop();
                  context.go(AppRoutes.notifications);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Individual Quick Action Button
  static Widget _buildQuickActionButton(
    BuildContext context,
    String label,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 100,
        height: 80,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  // Floating Action Button based on context
  static Widget? buildFloatingActionButton(
    BuildContext context,
    UserModel? user,
    String currentScreen,
  ) {
    switch (currentScreen) {
      case 'Products':
        if (user?.role == UserRole.admin || user?.role == UserRole.supplier) {
          return FloatingActionButton(
            heroTag: "addProduct",
            onPressed: () {
              context.go(AppRoutes.products);
            },
            child: const Icon(Icons.add),
          );
        }
        break;
      case 'Categories':
        if (user?.role == UserRole.admin) {
          return FloatingActionButton(
            heroTag: "addCategory",
            onPressed: () {
              context.go(AppRoutes.categories);
            },
            child: const Icon(Icons.add),
          );
        }
        break;
      case 'Inquiries':
        if (user?.role == UserRole.engineer || user?.role == UserRole.admin) {
          return FloatingActionButton(
            heroTag: "newInquiry",
            onPressed: () {
              context.go(AppRoutes.newInquiry);
            },
            child: const Icon(Icons.add),
          );
        }
        break;
    }
    return null;
  }

  // Show Quick Actions Menu
  static void showQuickActionsMenu(BuildContext context, UserModel? user) {
    showModalBottomSheet(
      context: context,
      builder: (context) => buildQuickActionButtons(context, user),
    );
  }

  // Navigation Speed Dial for complex actions
  static Widget buildSpeedDial(BuildContext context, UserModel? user) {
    return FloatingActionButton(
      heroTag: "speedDial",
      onPressed: () {
        showQuickActionsMenu(context, user);
      },
      child: const Icon(Icons.add),
    );
  }
}

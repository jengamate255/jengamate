import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:jengamate/services/auth_service.dart';
import 'package:jengamate/models/user_model.dart';
import 'package:jengamate/models/enums/user_role.dart';
import 'package:jengamate/screens/dashboard/dashboard_tab_screen.dart';
import 'package:jengamate/screens/inquiry/inquiry_screen.dart';
import 'package:jengamate/screens/products/products_screen.dart';
import 'package:jengamate/screens/profile/profile_screen.dart';
import 'package:jengamate/screens/admin/admin_tools_screen.dart';
import 'package:jengamate/screens/supplier/supplier_rfq_dashboard.dart';
import 'package:jengamate/screens/admin/product_management_screen.dart';
import 'package:jengamate/screens/order/orders_screen.dart';
import 'package:jengamate/screens/invoices/invoices_screen.dart';
import 'package:jengamate/widgets/app_drawer.dart';
import 'package:jengamate/widgets/navigation_helper.dart';
import 'package:jengamate/utils/responsive.dart';
import 'package:jengamate/ui/design_system/layout/adaptive_padding.dart';
import 'package:jengamate/ui/design_system/tokens/spacing.dart';
import 'package:provider/provider.dart';
import 'package:jengamate/config/app_routes.dart';
import 'package:jengamate/services/theme_service.dart';

// Using ResponsiveUtils instead of custom ScreenType enum

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    print("DashboardScreen: Build method started.");
    final user = Provider.of<UserModel?>(context);

    if (user == null) {
      print("DashboardScreen: User is null, showing loading indicator.");
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    print("DashboardScreen: User found with role: ${user.role}");

    final Map<String, Widget> allScreens = {
      'Dashboard': const DashboardTabScreen(),
      'Products': const ProductsScreen(),
      'Inquiries': const InquiryScreen(),
      'RFQs': const SupplierRFQDashboard(),
      'Orders': const OrdersScreen(),
      'Invoices': const InvoicesScreen(),
      'Profile': const ProfileScreen(),
      'Admin Tools': const AdminToolsScreen(),
    };

    final Map<String, IconData> allIcons = {
      'Dashboard': Icons.dashboard_outlined,
      'Products': Icons.shopping_bag_outlined,
      'Inquiries': Icons.receipt_long_outlined,
      'RFQs': Icons.request_quote_outlined,
      'Orders': Icons.shopping_cart_outlined,
      'Invoices': Icons.receipt_outlined,
      'Profile': Icons.person_outline,
      'Admin Tools': Icons.admin_panel_settings_outlined,
    };

    final Map<String, IconData> allActiveIcons = {
      'Dashboard': Icons.dashboard,
      'Products': Icons.shopping_bag,
      'Inquiries': Icons.receipt_long,
      'RFQs': Icons.request_quote,
      'Orders': Icons.shopping_cart,
      'Invoices': Icons.receipt,
      'Profile': Icons.person,
      'Admin Tools': Icons.admin_panel_settings,
    };

    List<String> allowedScreenKeys = [];
    if (user.role == UserRole.admin) {
      allowedScreenKeys = [
        'Dashboard',
        'Products',
        'Inquiries',
        'Orders',
        'Invoices',
        'Profile',
      ];
    } else if (user.role == UserRole.supplier) {
      allowedScreenKeys = [
        'Dashboard',
        'Products',
        'RFQs',
        'Orders',
        'Profile'
      ];
    } else {
      // engineer
      allowedScreenKeys = [
        'Dashboard',
        'Products',
        'Inquiries',
        'Orders',
        'Profile'
      ];
    }

    final List<Widget> _screens =
        allowedScreenKeys.map((key) => allScreens[key]!).toList();
    final List<BottomNavigationBarItem> _navItems =
        allowedScreenKeys.map((key) {
      return BottomNavigationBarItem(
        icon: Icon(allIcons[key]),
        activeIcon: Icon(allActiveIcons[key]),
        label: key,
      );
    }).toList();

    // Ensure _selectedIndex is valid
    if (_selectedIndex >= _screens.length) {
      _selectedIndex = 0;
    }
    print("DashboardScreen: About to build the UI.");

    // Responsive layout using new responsive system
    if (Responsive.isMobile(context)) {
      // Mobile layout with BottomNavigationBar
      return Scaffold(
        appBar: AppBar(
          title: Text(allowedScreenKeys[_selectedIndex]),
          actions: [
            // Theme toggle
            Consumer<ThemeService>(
              builder: (context, themeService, _) => IconButton(
                tooltip: themeService.isDarkMode
                    ? 'Switch to light mode'
                    : 'Switch to dark mode',
                icon: Icon(
                  themeService.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                  size: Responsive.getResponsiveIconSize(context),
                ),
                onPressed: () => context.read<ThemeService>().toggleTheme(),
              ),
            ),
            // Profile menu
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) async {
                switch (value) {
                  case 'profile':
                    context.go(AppRoutes.profile);
                    break;
                  case 'settings':
                    context.go(AppRoutes.settings);
                    break;
                  case 'logout':
                    await NavigationHelper.logout(context);
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'profile', child: Text('Profile')),
                const PopupMenuItem(value: 'settings', child: Text('Settings')),
                const PopupMenuItem(value: 'logout', child: Text('Logout')),
              ],
            ),
          ],
        ),
        body: IndexedStack(
          index: _selectedIndex,
          children: _screens,
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          items: _navItems,
          type: BottomNavigationBarType.fixed,
        ),
        floatingActionButton:
            _buildFloatingActionButton(user, allowedScreenKeys),
        drawer: AppDrawer(user: user),
      );
    } else {
      // Desktop layout with NavigationRail
      return Scaffold(
        appBar: AppBar(
          title: Text(
            allowedScreenKeys[_selectedIndex],
            style: TextStyle(
              fontSize: Responsive.getResponsiveFontSize(context,
                  mobile: 18, tablet: 20, desktop: 22),
            ),
          ),
          leading: Builder(
            builder: (context) => IconButton(
              icon: Icon(
                Icons.menu,
                size: Responsive.getResponsiveIconSize(context),
              ),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            ),
          ),
          actions: [
            // Theme toggle
            Consumer<ThemeService>(
              builder: (context, themeService, _) => IconButton(
                tooltip: themeService.isDarkMode
                    ? 'Switch to light mode'
                    : 'Switch to dark mode',
                icon: Icon(
                  themeService.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                  size: Responsive.getResponsiveIconSize(context),
                ),
                onPressed: () => context.read<ThemeService>().toggleTheme(),
              ),
            ),
            // Notifications button
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () {
                context.go(AppRoutes.notifications);
              },
            ),
            // Chat button
            IconButton(
              icon: const Icon(Icons.chat_outlined),
              onPressed: () {
                context.go(AppRoutes.chatList);
              },
            ),
            // Profile menu
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) async {
                switch (value) {
                  case 'profile':
                    context.go(AppRoutes.profile);
                    break;
                  case 'settings':
                    context.go(AppRoutes.settings);
                    break;
                  case 'logout':
                    // TODO: Fix NavigationHelper import issue
                    // await NavigationHelper.logout(context);
                    await AuthService().signOut();
                    if (context.mounted) {
                      context.go('/login');
                    }
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'profile', child: Text('Profile')),
                const PopupMenuItem(value: 'settings', child: Text('Settings')),
                const PopupMenuItem(value: 'logout', child: Text('Logout')),
              ],
            ),
          ],
        ),
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              labelType: NavigationRailLabelType.all,
              minWidth: Responsive.isDesktop(context) ? 80 : 60,
              minExtendedWidth: Responsive.isDesktop(context) ? 200 : 160,
              destinations: _navItems.map((item) {
                return NavigationRailDestination(
                  icon: Icon(
                    (item.icon as Icon).icon,
                    size: Responsive.getResponsiveIconSize(context),
                  ),
                  selectedIcon: Icon(
                    (item.activeIcon as Icon).icon,
                    size: Responsive.getResponsiveIconSize(context),
                  ),
                  label: Text(
                    item.label!,
                    style: TextStyle(
                      fontSize: Responsive.getResponsiveFontSize(context,
                          mobile: 12, tablet: 14, desktop: 16),
                    ),
                  ),
                );
              }).toList(),
            ),
            const VerticalDivider(thickness: 1, width: 1),
            Expanded(
              child: IndexedStack(
                index: _selectedIndex,
                children: _screens,
              ),
            ),
          ],
        ),
        floatingActionButton:
            _buildFloatingActionButton(user, allowedScreenKeys),
      );
    }
  }

  Widget _buildFloatingActionButton(
      UserModel user, List<String> allowedScreenKeys) {
    // Different FAB based on current screen and user role
    switch (allowedScreenKeys[_selectedIndex]) {
      case 'Products':
        if (user.role == UserRole.admin || user.role == UserRole.supplier) {
          return FloatingActionButton(
            heroTag: "addProduct",
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ProductManagementScreen(),
                ),
              );
            },
            child: const Icon(Icons.add),
          );
        }
        break;
      case 'Orders':
        return FloatingActionButton(
          heroTag: "createOrder",
          onPressed: () {
            context.go(AppRoutes.newInquiry);
          },
          child: const Icon(Icons.add_shopping_cart),
        );

      case 'Suppliers':
        if (user.role == UserRole.admin) {
          return FloatingActionButton(
            heroTag: "addSupplier",
            onPressed: () {
              // TODO: Add supplier dialog
            },
            child: const Icon(Icons.add),
          );
        }
        break;
    }
    return const SizedBox.shrink();
  }

  void _showQuickActionsMenu(BuildContext context, UserModel user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(Responsive.getResponsiveBorderRadius(context)),
        ),
      ),
      builder: (context) => AdaptivePadding(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: JMSpacing.sm),
            Wrap(
              spacing: JMSpacing.md,
              runSpacing: JMSpacing.md,
              children: [
                if (user.role == UserRole.admin ||
                    user.role == UserRole.supplier)
                  _buildQuickActionButton(
                    context,
                    'Add Product',
                    Icons.add_shopping_cart,
                    () {
                      Navigator.pop(context);
                      context.go(AppRoutes.products);
                    },
                  ),
                if (user.role == UserRole.admin)
                  _buildQuickActionButton(
                    context,
                    'Add Category',
                    Icons.category,
                    () {
                      Navigator.pop(context);
                      context.go(AppRoutes.categories);
                    },
                  ),
                if (user.role == UserRole.engineer ||
                    user.role == UserRole.admin)
                  _buildQuickActionButton(
                    context,
                    'New Inquiry',
                    Icons.receipt_long,
                    () {
                      Navigator.pop(context);
                      context.go(AppRoutes.newInquiry);
                    },
                  ),
                _buildQuickActionButton(
                  context,
                  'Chat',
                  Icons.chat,
                  () {
                    Navigator.pop(context);
                    context.go(AppRoutes.chatList);
                  },
                ),
                _buildQuickActionButton(
                  context,
                  'Notifications',
                  Icons.notifications,
                  () {
                    Navigator.pop(context);
                    context.go(AppRoutes.notifications);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton(
    BuildContext context,
    String label,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(JMSpacing.sm),
      child: Container(
        width: Responsive.isDesktop(context) ? 140 : 100,
        height: Responsive.isDesktop(context) ? 120 : 80,
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).dividerColor),
          borderRadius: BorderRadius.circular(JMSpacing.sm),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: Responsive.isDesktop(context) ? 32 : 24,
            ),
            const SizedBox(height: JMSpacing.sm),
            Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:jengamate/utils/logger.dart';
import 'package:jengamate/services/auth_service.dart';
import 'package:jengamate/models/user_model.dart';
import 'package:jengamate/models/enums/user_role.dart';
import 'package:jengamate/screens/dashboard/dashboard_tab_screen.dart';
import 'package:jengamate/screens/inquiry/inquiry_screen.dart';
import 'package:jengamate/screens/products/products_screen.dart';
import 'package:jengamate/screens/admin/admin_tools_screen.dart';
import 'package:jengamate/screens/supplier/supplier_rfq_dashboard.dart';
import 'package:jengamate/screens/order/orders_screen.dart';
import 'package:jengamate/screens/invoices/invoices_screen.dart';
import 'package:jengamate/screens/admin/payment_approval_screen.dart';
import 'package:jengamate/widgets/app_drawer.dart';
import 'package:jengamate/utils/responsive.dart';
import 'package:provider/provider.dart';
import 'package:jengamate/config/app_routes.dart';
import 'package:jengamate/services/theme_service.dart';
import 'package:jengamate/services/user_state_provider.dart';
import 'package:jengamate/screens/profile/profile_screen.dart';

// Using ResponsiveUtils instead of custom ScreenType enum

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  bool _hasRedirected = false;

  // Static screen configurations - moved outside build method to prevent recreation
  static final Map<String, Widget> _allScreens = {
    'Dashboard': DashboardTabScreen(),
    'Products': ProductsScreen(),
    'Inquiries': InquiryScreen(),
    'RFQs': SupplierRFQDashboard(),
    'Orders': OrdersScreen(),
    'Invoices': InvoicesScreen(),
    'Payment Approval': PaymentApprovalScreen(),
    'Profile': const ProfileScreen(),
    'Admin Tools': AdminToolsScreen(),
  };

  static const Map<String, IconData> _allIcons = {
    'Dashboard': Icons.dashboard_outlined,
    'Products': Icons.shopping_bag_outlined,
    'Inquiries': Icons.receipt_long_outlined,
    'RFQs': Icons.request_quote_outlined,
    'Orders': Icons.shopping_cart_outlined,
    'Invoices': Icons.receipt_outlined,
    'Profile': Icons.person_outline,
    'Payment Approval': Icons.payment_outlined,
    'Admin Tools': Icons.admin_panel_settings_outlined,
  };

  static const Map<String, IconData> _allActiveIcons = {
    'Dashboard': Icons.dashboard,
    'Products': Icons.shopping_bag,
    'Inquiries': Icons.receipt_long,
    'RFQs': Icons.request_quote,
    'Orders': Icons.shopping_cart,
    'Invoices': Icons.receipt,
    'Profile': Icons.person,
    'Payment Approval': Icons.payment,
    'Admin Tools': Icons.admin_panel_settings,
  };

  @override
  Widget build(BuildContext context) {
    // Reduce log spam - only log on significant rebuilds
    final userState = Provider.of<UserStateProvider>(context);

    if (userState.isLoading) {
      // Reduce log spam for loading state
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (userState.currentUser == null) {
      Logger.log('DashboardScreen: No user found, redirecting to login');
      if (!_hasRedirected) {
        _hasRedirected = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            context.go('/login');
          }
        });
      }
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final user = userState.currentUser!;
    // Logger.log('DashboardScreen: User found with role: ${user.role}'); // Commented out to reduce log spam

    List<String> allowedScreenKeys = [];
    if (user.role == UserRole.admin) {
      allowedScreenKeys = [
        'Dashboard',
        'Products',
        'Inquiries',
        'Orders',
        'Invoices',
        'Payment Approval',
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
        allowedScreenKeys.map((key) => _allScreens[key]!).toList();
    final List<BottomNavigationBarItem> _navItems =
        allowedScreenKeys.map((key) {
      return BottomNavigationBarItem(
        icon: Icon(_allIcons[key]),
        activeIcon: Icon(_allActiveIcons[key]),
        label: key,
      );
    }).toList();

    // Ensure _selectedIndex is valid
    if (_selectedIndex >= _screens.length) {
      _selectedIndex = 0;
    }
    // Logger.log('DashboardScreen: About to build the UI'); // Commented out to reduce log spam

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
            _buildFloatingActionButton(context, user, allowedScreenKeys),
        drawer: AppDrawer(user: user),
      );
  }

  Widget _buildFloatingActionButton(BuildContext context, UserModel user, List<String> allowedScreenKeys) {
    // Build floating action button based on current screen and user role
    final currentScreen = allowedScreenKeys[_selectedIndex];
    final uniqueId = DateTime.now().millisecondsSinceEpoch.toString();

    if (currentScreen == 'Orders' && user.role == UserRole.admin) {
      return FloatingActionButton(
        heroTag: "createOrderAdmin_$uniqueId",
        onPressed: () {
          // Navigate to create order screen
          context.go(AppRoutes.orders);
        },
        child: const Icon(Icons.add),
        tooltip: 'Create Order',
      );
    }

    if (currentScreen == 'Inquiries' && user.role == UserRole.engineer) {
      return FloatingActionButton(
        heroTag: "createInquiry_$uniqueId",
        onPressed: () {
          context.go(AppRoutes.newInquiry);
        },
        child: const Icon(Icons.add),
        tooltip: 'New Inquiry',
      );
    }

    // Default floating action button
    return FloatingActionButton(
      heroTag: "defaultFAB_$uniqueId",
      onPressed: () {
        // Default action
      },
      child: const Icon(Icons.help_outline),
      tooltip: 'Help',
    );
  }
}

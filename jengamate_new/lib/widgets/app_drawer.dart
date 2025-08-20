import 'package:flutter/material.dart';
import 'package:jengamate/models/user_model.dart';
import 'package:go_router/go_router.dart';
import 'package:jengamate/models/enums/user_role.dart';
import 'package:jengamate/config/app_routes.dart';
import 'package:jengamate/utils/theme.dart';
import 'package:jengamate/utils/responsive.dart';
import 'package:jengamate/services/auth_service.dart';
import 'package:jengamate/widgets/navigation_helper.dart';

class AppDrawer extends StatelessWidget {
  final UserModel? user;

  const AppDrawer({super.key, this.user});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: Responsive.getResponsiveDrawerWidth(context),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Drawer header with user info
          DrawerHeader(
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: Responsive.getResponsiveAvatarSize(context) / 2,
                  backgroundColor: Colors.white,
                  child: Text(
                    user?.displayName.substring(0, 1).toUpperCase() ?? 'U',
                    style: TextStyle(
                      fontSize: Responsive.getResponsiveFontSize(context,
                          mobile: 20, tablet: 24, desktop: 28),
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
                SizedBox(height: Responsive.getResponsiveSpacing(context) / 2),
                Text(
                  user?.displayName ?? 'User',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: Responsive.getResponsiveFontSize(context,
                        mobile: 16, tablet: 18, desktop: 20),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  user?.email ?? '',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: Responsive.getResponsiveFontSize(context,
                        mobile: 12, tablet: 14, desktop: 16),
                  ),
                ),
                SizedBox(height: Responsive.getResponsiveSpacing(context) / 4),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: Responsive.getResponsiveSpacing(context) / 2,
                    vertical: Responsive.getResponsiveSpacing(context) / 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(
                        Responsive.getResponsiveBorderRadius(context)),
                  ),
                  child: Text(
                    _getRoleDisplayName(user?.role),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: Responsive.getResponsiveFontSize(context,
                          mobile: 10, tablet: 12, desktop: 14),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Main navigation items
          _buildDrawerItem(
            context,
            icon: Icons.dashboard,
            title: 'Dashboard',
            onTap: () {
              context.go(AppRoutes.dashboard);
            },
          ),

          if (user?.role == UserRole.admin || user?.role == UserRole.supplier)
            _buildDrawerItem(
              context,
              icon: Icons.shopping_bag,
              title: 'Products',
              onTap: () {
                context.go(AppRoutes.products);
              },
            ),

          if (user?.role == UserRole.engineer || user?.role == UserRole.admin)
            _buildDrawerItem(
              context,
              icon: Icons.receipt_long,
              title: 'Inquiries',
              onTap: () {
                context.go(AppRoutes.inquiries);
              },
            ),

          if (user?.role == UserRole.admin || user?.role == UserRole.supplier)
            _buildDrawerItem(
              context,
              icon: Icons.manage_search,
              title: 'RFQ Management',
              onTap: () {
                context.go(AppRoutes.rfqManagement);
              },
            ),

          // if (user?.role == UserRole.engineer)
          //   _buildDrawerItem(
          //     context,
          //     icon: Icons.add_box,
          //     title: 'Submit RFQ',
          //     onTap: () {
          //       context.go(AppRoutes.rfqSubmission);
          //     },
          //   ),
          _buildDrawerItem(
            context,
            icon: Icons.list_alt,
            title: 'My RFQs',
            onTap: () {
              context.go(AppRoutes.rfqList);
            },
          ),

          if (user?.role == UserRole.engineer)
            _buildDrawerItem(
              context,
              icon: Icons.shopping_bag,
              title: 'Products',
              onTap: () {
                context.go(AppRoutes.products);
              },
            ),

          const Divider(),

          // Communication section
          _buildDrawerItem(
            context,
            icon: Icons.chat,
            title: 'Chat',
            onTap: () {
              context.go(AppRoutes.chatList);
            },
          ),

          _buildDrawerItem(
            context,
            icon: Icons.notifications,
            title: 'Notifications',
            onTap: () {
              context.go(AppRoutes.notifications);
            },
          ),

          const Divider(),

          // Admin section
          if (user?.role == UserRole.admin)
            Column(
              children: [
                _buildDrawerItem(
                  context,
                  icon: Icons.admin_panel_settings,
                  title: 'Admin Tools',
                  onTap: () {
                    context.go(AppRoutes.adminTools);
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.analytics,
                  title: 'Analytics',
                  onTap: () {
                    context.go(AppRoutes.analytics);
                  },
                ),
                const Divider(),
              ],
            ),

          // Account section
          _buildDrawerItem(
            context,
            icon: Icons.person,
            title: 'Profile',
            onTap: () {
              context.go(AppRoutes.profile);
            },
          ),

          _buildDrawerItem(
            context,
            icon: Icons.settings,
            title: 'Settings',
            onTap: () {
              context.go(AppRoutes.settings);
            },
          ),
          _buildDrawerItem(
            context,
            icon: Icons.help_outline,
            title: 'Help & Support',
            onTap: () {
              context.go(AppRoutes.help);
            },
          ),

          const Divider(),

          // Logout
          _buildDrawerItem(
            context,
            icon: Icons.logout,
            title: 'Logout',
            onTap: () async {
              Navigator.pop(context); // Close drawer first
              await NavigationHelper.logout(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryColor),
      title: Text(title),
      onTap: onTap,
    );
  }

  String _getRoleDisplayName(UserRole? role) {
    switch (role) {
      case UserRole.admin:
        return 'Administrator';
      case UserRole.supplier:
        return 'Supplier';
      case UserRole.engineer:
        return 'Engineer';
      default:
        return 'User';
    }
  }
}

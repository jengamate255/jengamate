import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:jengamate/screens/profile/widgets/menu_group.dart';
import 'package:jengamate/screens/profile/widgets/profile_header.dart';
import 'package:jengamate/screens/profile/widgets/profile_menu_item.dart';
import 'package:jengamate/utils/theme.dart';
import 'package:jengamate/models/user_model.dart';
import 'package:jengamate/models/enums/user_role.dart';
import 'package:provider/provider.dart';
import 'package:jengamate/services/user_state_provider.dart';
import 'package:jengamate/config/app_routes.dart';
import 'package:jengamate/screens/profile/edit_profile_screen.dart';
import 'package:jengamate/widgets/navigation_helper.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userState = Provider.of<UserStateProvider>(context);
    final currentUser = userState.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              context.go(AppRoutes.settings);
            },
            tooltip: 'Settings',
          ),
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              context.go(AppRoutes.help);
            },
            tooltip: 'Help',
          ),
        ],
      ),
      body: currentUser == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const ProfileHeader(),
                  const SizedBox(height: 24),

                  // My Account section
                  MenuGroup(
                    title: 'My Account',
                    children: [
                      ProfileMenuItem(
                        icon: Icons.person_outline,
                        title: 'Edit Profile',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  EditProfileScreen(user: currentUser),
                            ),
                          );
                        },
                      ),
                      ProfileMenuItem(
                        icon: Icons.lock_outline,
                        title: 'Change Password',
                        onTap: () {
                          context.go(AppRoutes.changePassword);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Services section based on role
                  if (currentUser.role == UserRole.admin)
                    MenuGroup(
                      title: 'Admin Services',
                      children: [
                        ProfileMenuItem(
                          icon: Icons.admin_panel_settings_outlined,
                          title: 'Admin Tools',
                          onTap: () => context.go(AppRoutes.adminTools),
                        ),
                        ProfileMenuItem(
                          icon: Icons.analytics_outlined,
                          title: 'Analytics',
                          onTap: () {
                            context.go(AppRoutes.analytics);
                          },
                        ),
                        ProfileMenuItem(
                          icon: Icons.category,
                          title: 'Categories',
                          onTap: () {
                            context.go(AppRoutes.categories);
                          },
                        ),
                      ],
                    )
                  else if (currentUser.role == UserRole.engineer)
                    MenuGroup(
                      title: 'Engineer Services',
                      children: [
                        ProfileMenuItem(
                          icon: Icons.monetization_on_outlined,
                          title: 'My Commissions',
                          subtitle: 'View your commission history',
                          iconColor: Colors.green.shade600,
                          onTap: () {
                            context.go(AppRoutes.commission);
                          },
                        ),
                        ProfileMenuItem(
                          icon: Icons.account_balance_wallet_outlined,
                          title: 'Withdrawals',
                          subtitle: 'Manage your withdrawals',
                          iconColor: Colors.blue.shade600,
                          onTap: () {
                            context.go(AppRoutes.withdrawals);
                          },
                        ),
                        ProfileMenuItem(
                          icon: Icons.receipt_long,
                          title: 'My Inquiries',
                          onTap: () {
                            context.go(AppRoutes.inquiries);
                          },
                        ),
                      ],
                    )
                  else if (currentUser.role == UserRole.supplier)
                    MenuGroup(
                      title: 'Supplier Services',
                      children: [
                        ProfileMenuItem(
                          icon: Icons.inventory_outlined,
                          title: 'My Products',
                          subtitle: 'Manage your product listings',
                          onTap: () {
                            context.go(AppRoutes.products);
                          },
                        ),
                        ProfileMenuItem(
                          icon: Icons.receipt_long_outlined,
                          title: 'RFQs',
                          subtitle: 'Respond to requests for quotes',
                          onTap: () {
                            context.go(AppRoutes.rfqList);
                          },
                        ),
                      ],
                    ),

                  const SizedBox(height: 16),

                  // Support section
                  MenuGroup(
                    title: 'Support & Settings',
                    children: [
                      ProfileMenuItem(
                        icon: Icons.notifications_outlined,
                        title: 'Notifications',
                        onTap: () {
                          context.go(AppRoutes.notifications);
                        },
                      ),
                      ProfileMenuItem(
                        icon: Icons.chat_outlined,
                        title: 'Chat Support',
                        onTap: () {
                          context.go(AppRoutes.chatList);
                        },
                      ),
                      ProfileMenuItem(
                        icon: Icons.help_outline_rounded,
                        title: 'Help & Support',
                        onTap: () {
                          context.go(AppRoutes.help);
                        },
                      ),
                      ProfileMenuItem(
                        icon: Icons.headset_mic_outlined,
                        title: 'Contact Support',
                        onTap: () async {
                          const phoneNumber = '+1234567890';
                          final whatsappUri = Uri.parse('https://wa.me/$phoneNumber');
                          if (await canLaunchUrl(whatsappUri)) {
                            await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
                          } else {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Could not launch WhatsApp'),
                                ),
                              );
                            }
                          }
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Footer
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    child: const Column(
                      children: [
                        Text(
                          'Version 1.0.0',
                          style: TextStyle(
                            color: Color(0xFF666666),
                            fontSize: 12,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '© 2025 JengaMate. All rights reserved.',
                          style: TextStyle(
                            color: Color(0xFF666666),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

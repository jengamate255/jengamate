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

                  // Quick Action Buttons
                  if (currentUser.role == UserRole.admin ||
                      currentUser.role == UserRole.supplier)
                    Container(
                      margin: const EdgeInsets.only(bottom: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Quick Actions',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    context.go(AppRoutes.products);
                                  },
                                  icon: const Icon(Icons.shopping_bag),
                                  label: const Text('View Products'),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              if (currentUser.role == UserRole.admin)
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      context.go(AppRoutes.categories);
                                    },
                                    icon: const Icon(Icons.category),
                                    label: const Text('Categories'),
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),

                  if (currentUser.role == UserRole.engineer)
                    Container(
                      margin: const EdgeInsets.only(bottom: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Quick Actions',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    context.go(AppRoutes.inquiries);
                                  },
                                  icon: const Icon(Icons.receipt_long),
                                  label: const Text('My Inquiries'),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    context.go(AppRoutes.newInquiry);
                                  },
                                  icon: const Icon(Icons.add),
                                  label: const Text('New Inquiry'),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

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

                  // Admin section
                  if (currentUser.role == UserRole.admin)
                    MenuGroup(
                      title: 'Admin',
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
                      ],
                    ),

                  // Engineer section
                  if (currentUser.role == UserRole.engineer)
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
                      ],
                    ),

                  // Supplier section
                  if (currentUser.role == UserRole.supplier)
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
                            context.go(AppRoutes.rfqs);
                          },
                        ),
                      ],
                    ),

                  const SizedBox(height: 16),

                  // General section
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
                          const phoneNumber = '+1234567890'; // Replace with actual support number
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
      ),
    );
  }
}






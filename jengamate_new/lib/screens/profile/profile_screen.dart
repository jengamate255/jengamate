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

import 'package:jengamate/config/app_routes.dart';
import 'package:jengamate/screens/profile/edit_profile_screen.dart';
import 'package:jengamate/widgets/navigation_helper.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = Provider.of<UserModel?>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        centerTitle: true,
        actions: [
          // Settings button
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              context.go(AppRoutes.settings);
            },
            tooltip: 'Settings',
          ),
          // Help button
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
                      ProfileMenuItem(
                        icon: Icons.security,
                        title: 'Security Settings',
                        onTap: () {
                          context.go(AppRoutes.security);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
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
                  const SizedBox(height: 16),
                  MenuGroup(
                    title: 'Priority Services',
                    children: [
                      ProfileMenuItem(
                        icon: Icons.star_border_rounded,
                        title: 'Priority Services',
                        iconColor: Colors.orange.shade600,
                        onTap: () {
                          context.go(AppRoutes.prioritySupport);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  MenuGroup(
                    title: 'Personal Information',
                    children: [
                      ProfileMenuItem(
                          icon: Icons.person_outline,
                          title: 'My Profile',
                          onTap: () {}),
                      if (currentUser.address != null &&
                          currentUser.address!.isNotEmpty)
                        ProfileMenuItem(
                          icon: Icons.home_outlined,
                          title: 'Address',
                          subtitle: currentUser.address,
                          onTap: () {},
                        ),
                      if (currentUser.phoneNumber != null &&
                          currentUser.phoneNumber!.isNotEmpty)
                        ProfileMenuItem(
                          icon: Icons.phone_outlined,
                          title: 'Phone Number',
                          subtitle: currentUser.phoneNumber,
                          onTap: () {},
                        ),
                      const Divider(height: 1, indent: 56),
                      ProfileMenuItem(
                          icon: Icons.work_outline_rounded,
                          title: 'Professional Details',
                          onTap: () {}),
                      /* if (currentUser.companyName != null &&
                          currentUser.companyName!.isNotEmpty)
                        ProfileMenuItem(
                          icon: Icons.business_outlined,
                          title: 'Company Name',
                          subtitle: currentUser.companyName,
                          onTap: () {},
                        ), */
                    ],
                  ),
                  const SizedBox(height: 16),
                  MenuGroup(
                    title: 'Account Settings',
                    children: [
                      ProfileMenuItem(
                        icon: Icons.notifications_outlined,
                        title: 'Notification Preferences',
                        onTap: () {
                          context.go(AppRoutes.notifications);
                        },
                      ),
                      ProfileMenuItem(
                        icon: Icons.chat_outlined,
                        title: 'Chat',
                        onTap: () {
                          context.go(AppRoutes.chatList);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  MenuGroup(
                    title: 'Support',
                    children: [
                      ProfileMenuItem(
                        icon: Icons.help_outline_rounded,
                        title: 'Help Center',
                        onTap: () {
                          context.go(AppRoutes.help);
                        },
                      ),
                      const Divider(height: 1, indent: 56),
                      ProfileMenuItem(
                        icon: Icons.headset_mic_outlined,
                        title: 'Contact Support',
                        onTap: () {
                          context.go(AppRoutes.help);
                        },
                      ),
                      const Divider(height: 1, indent: 56),
                      ProfileMenuItem(
                        icon: Icons.chat_bubble_outline_rounded,
                        title: 'Chat on WhatsApp',
                        onTap: () {
                          // Open WhatsApp chat
                          final Uri whatsappUri = Uri(
                            scheme: 'https',
                            host: 'wa.me',
                            path: '254700123456', // Replace with actual support number
                          );
                          try {
                            launchUrl(whatsappUri);
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Could not open WhatsApp')),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24.0),
                    child: Text('Version 1.0.0',
                        style: TextStyle(color: AppTheme.subTextColor)),
                  ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        heroTag: "profileFAB",
        onPressed: () {
          NavigationHelper.showQuickActionsMenu(context, currentUser);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

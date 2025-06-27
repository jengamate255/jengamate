import 'package:flutter/material.dart';
import 'package:jengamate/screens/profile/widgets/menu_group.dart';
import 'package:jengamate/screens/profile/widgets/profile_header.dart';
import 'package:jengamate/screens/profile/widgets/profile_menu_item.dart';
import 'package:jengamate/utils/theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: [
              const ProfileHeader(),

              // Priority Services
              Card(
                margin: EdgeInsets.zero,
                child: ProfileMenuItem(
                  icon: Icons.star_border_rounded,
                  title: 'Priority Services',
                  iconColor: Colors.orange.shade600,
                  onTap: () {},
                ),
              ),

              // Personal Information
              MenuGroup(
                title: 'Personal Information',
                children: [
                  ProfileMenuItem(icon: Icons.person_outline, title: 'My Profile', onTap: () {}),
                  const Divider(height: 1, indent: 56),
                  ProfileMenuItem(icon: Icons.work_outline_rounded, title: 'Professional Details', onTap: () {}),
                ],
              ),

              // Account Settings
              MenuGroup(
                title: 'Account Settings',
                children: [
                  ProfileMenuItem(icon: Icons.notifications_outlined, title: 'Notification Preferences', onTap: () {}),
                ],
              ),

              // Support
              MenuGroup(
                title: 'Support',
                children: [
                  ProfileMenuItem(icon: Icons.help_outline_rounded, title: 'Help Center', onTap: () {}),
                  const Divider(height: 1, indent: 56),
                  ProfileMenuItem(icon: Icons.headset_mic_outlined, title: 'Contact Support', onTap: () {}),
                   const Divider(height: 1, indent: 56),
                  ProfileMenuItem(icon: Icons.chat_bubble_outline_rounded, title: 'Chat on WhatsApp', onTap: () {}),
                ],
              ),

              // Version
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24.0),
                child: Text('Version 1.0.0', style: TextStyle(color: AppTheme.subTextColor)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

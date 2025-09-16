import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:jengamate/services/user_state_provider.dart';
import 'package:jengamate/config/app_routes.dart';
import 'package:jengamate/services/theme_service.dart';
import 'package:jengamate/services/notification_service.dart';
import 'package:jengamate/widgets/navigation_helper.dart';

import 'package:jengamate/ui/design_system/layout/adaptive_padding.dart';
import 'package:jengamate/ui/design_system/tokens/spacing.dart';
import 'package:jengamate/ui/design_system/components/jm_card.dart';


class SettingsScreen extends StatefulWidget {
    const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final themeService = Provider.of<ThemeService>(context, listen: false);
    final notificationService =
        Provider.of<NotificationService>(context, listen: false);

    setState(() {
      _darkModeEnabled = themeService.isDarkMode;
      _notificationsEnabled = notificationService.notificationsEnabled;
    });
  }

  Future<void> _handleLogout() async {
    setState(() => _isLoading = true);

    try {
      await NavigationHelper.logout(context);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    final notificationService = Provider.of<NotificationService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        elevation: 0,
      ),
      body: AdaptivePadding(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(JMSpacing.md),
                children: [
                  _buildSectionHeader('Preferences'),
                  _buildSettingsCard(
                    children: [
                      SwitchListTile(
                        title: const Text('Dark Mode'),
                        subtitle: const Text('Use dark theme across the app'),
                        value: _darkModeEnabled,
                        onChanged: (value) {
                          setState(() => _darkModeEnabled = value);
                          themeService.toggleTheme();
                        },
                      ),
                      SwitchListTile(
                        title: const Text('Push Notifications'),
                        subtitle: const Text('Receive order and message updates'),
                        value: _notificationsEnabled,
                        onChanged: (value) async {
                          setState(() => _notificationsEnabled = value);
                          await notificationService
                              .setNotificationsEnabled(value);
                        },
                      ),
                    ],
                  ),
                  _buildSectionHeader('Account'),
                  _buildSettingsCard(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.person_outline),
                        title: const Text('Edit Profile'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          context.go(AppRoutes.profile);
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.lock_outline),
                        title: const Text('Change Password'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          context.go(AppRoutes.changePassword);
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.verified_outlined),
                        title: const Text('Identity Verification'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          context.go(AppRoutes.identityVerification);
                        },
                      ),
                    ],
                  ),
                  _buildSectionHeader('Support'),
                  _buildSettingsCard(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.help_outline),
                        title: const Text('Help & Support'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          context.go(AppRoutes.help);
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.info_outline),
                        title: const Text('About'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          _showAboutDialog();
                        },
                      ),
                    ],
                  ),
                  _buildSectionHeader('Account Actions'),
                  _buildSettingsCard(
                    children: [
                      ListTile(
                        leading: Icon(Icons.logout, color: Theme.of(context).colorScheme.error),
                        title: Text('Logout',
                            style: TextStyle(color: Theme.of(context).colorScheme.error)),
                        onTap: _handleLogout,
                      ),
                    ],
                  ),
                ],
            )),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(JMSpacing.md, JMSpacing.xl, JMSpacing.md, JMSpacing.sm),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildSettingsCard({required List<Widget> children}) {
    return JMCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: children,
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About JengaMate'),
        content: const Text(
          'JengaMate is a comprehensive construction materials marketplace '
          'connecting suppliers and buyers in the construction industry.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

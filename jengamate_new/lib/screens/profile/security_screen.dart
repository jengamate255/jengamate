import 'package:flutter/material.dart';
import 'package:jengamate/config/app_routes.dart';

import 'package:go_router/go_router.dart';

class SecurityScreen extends StatefulWidget {
    const SecurityScreen({super.key});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  bool _twoFactorEnabled = false;
  bool _biometricEnabled = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSecuritySettings();
  }

  Future<void> _loadSecuritySettings() async {
    // Load security settings from preferences or backend
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Security Settings'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                _buildSectionHeader('Account Security'),
                _buildSecuritySettings(),
                _buildSectionHeader('Login & Recovery'),
                _buildLoginSettings(),
                _buildSectionHeader('Active Sessions'),
                _buildSessionSettings(),
              ],
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildSecuritySettings() {
    return Card(
      child: Column(
        children: [
          SwitchListTile(
            title: const Text('Two-Factor Authentication'),
            subtitle: const Text('Add an extra layer of security'),
            value: _twoFactorEnabled,
            onChanged: _toggleTwoFactor,
          ),
          SwitchListTile(
            title: const Text('Biometric Authentication'),
            subtitle: const Text('Use fingerprint or face recognition'),
            value: _biometricEnabled,
            onChanged: _toggleBiometric,
          ),
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('Change Password'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(AppRoutes.changePassword),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginSettings() {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.email_outlined),
            title: const Text('Email Recovery'),
            subtitle: const Text('Manage email recovery options'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showEmailRecovery(),
          ),
          ListTile(
            leading: const Icon(Icons.phone_outlined),
            title: const Text('Phone Recovery'),
            subtitle: const Text('Add phone number for recovery'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showPhoneRecovery(),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionSettings() {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.devices),
            title: const Text('Active Devices'),
            subtitle: const Text('Manage your active sessions'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showActiveSessions(),
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout from all devices'),
            style: ListTileStyle.drawer,
            onTap: () => _logoutAllDevices(),
          ),
        ],
      ),
    );
  }

  void _toggleTwoFactor(bool value) {
    setState(() => _twoFactorEnabled = value);
    // Implement two-factor authentication logic
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(value ? '2FA enabled' : '2FA disabled'),
      ),
    );
  }

  void _toggleBiometric(bool value) {
    setState(() => _biometricEnabled = value);
    // Implement biometric authentication logic
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(value ? 'Biometric auth enabled' : 'Biometric auth disabled'),
      ),
    );
  }

  void _showEmailRecovery() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Email Recovery'),
        content: const Text('Email recovery settings will be available soon.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showPhoneRecovery() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Phone Recovery'),
        content: const Text('Phone recovery settings will be available soon.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showActiveSessions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Active Sessions'),
        content: const Text('Active session management will be available soon.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _logoutAllDevices() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout All Devices'),
        content: const Text(
          'This will log you out from all devices. You will need to login again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout All', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Implement logout from all devices
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Logged out from all devices')),
      );
    }
  }
}

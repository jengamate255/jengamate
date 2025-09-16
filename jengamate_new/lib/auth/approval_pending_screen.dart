import 'package:flutter/material.dart';
import 'package:jengamate/services/auth_service.dart';
import 'package:jengamate/utils/theme.dart';
import 'package:provider/provider.dart';
import 'package:jengamate/services/user_state_provider.dart';

class ApprovalPendingScreen extends StatelessWidget {
  const ApprovalPendingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.pending_actions,
                size: 100,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(height: 30),
              const Text(
                'Account Pending Approval',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              const Text(
                'Your account is currently under review by our administrators. '
                'You will receive a notification once your account is approved.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              const CircularProgressIndicator(),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                onPressed: () async {
                  await Provider.of<AuthService>(context, listen: false).signOut();
                },
                icon: const Icon(Icons.logout),
                label: const Text('Sign Out'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 15,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
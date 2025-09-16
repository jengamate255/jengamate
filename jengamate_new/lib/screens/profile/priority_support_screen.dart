import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:jengamate/config/app_routes.dart';
import 'package:provider/provider.dart';
import 'package:jengamate/services/user_state_provider.dart';
import 'package:jengamate/models/user_model.dart';

import 'package:url_launcher/url_launcher.dart';

class PrioritySupportScreen extends StatelessWidget {
  const PrioritySupportScreen({super.key});

  Future<void> _launchUrl(Uri url) async {
    if (!await launchUrl(url)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    final userState = Provider.of<UserStateProvider>(context);
    final user = userState.currentUser;
    final isVerified = user?.isVerified ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Priority Support'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isVerified ? Icons.verified : Icons.warning,
                          color: isVerified ? Colors.green : Colors.orange,
                          size: 32,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            isVerified ? 'Verified Account' : 'Account Not Verified',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isVerified
                          ? 'You have access to priority support with faster response times.'
                          : 'Complete identity verification to unlock priority support.',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            const Text(
              'Priority Support Features',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            _buildFeatureCard(
              icon: Icons.speed,
              title: 'Faster Response',
              description: 'Get responses within 2 hours instead of 24 hours',
              enabled: isVerified,
            ),
            
            _buildFeatureCard(
              icon: Icons.phone,
              title: 'Direct Phone Support',
              description: 'Access to dedicated support phone line',
              enabled: isVerified,
            ),
            
            _buildFeatureCard(
              icon: Icons.video_call,
              title: 'Video Call Support',
              description: 'Schedule video calls with support team',
              enabled: isVerified,
            ),
            
            _buildFeatureCard(
              icon: Icons.priority_high,
              title: 'Priority Queue',
              description: 'Your tickets are handled first',
              enabled: isVerified,
            ),
            
            const SizedBox(height: 32),
            
            if (isVerified) ...[
              Center(
                child: ElevatedButton.icon(
                  onPressed: () {
                    final Uri emailLaunchUri = Uri(
                      scheme: 'mailto',
                      path: 'priority-support@jengamate.com',
                      query: 'subject=Priority Support Request&body=Please describe your issue here.',
                    );
                    _launchUrl(emailLaunchUri);
                  },
                  icon: const Icon(Icons.email),
                  label: const Text('Contact Priority Support'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ] else ...[
              Center(
                child: ElevatedButton.icon(
                  onPressed: () {
                    context.go(AppRoutes.identityVerification);
                  },
                  icon: const Icon(Icons.verified_user),
                  label: const Text('Verify Account'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
    required bool enabled,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Card(
        elevation: enabled ? 2 : 0,
        color: enabled ? null : Colors.grey[100],
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(
                icon,
                size: 32,
                color: enabled ? Colors.blue : Colors.grey,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: enabled ? Colors.black : Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: enabled ? Colors.grey[600] : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              if (enabled)
                const Icon(Icons.check_circle, color: Colors.green)
              else
                const Icon(Icons.lock, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 20),
          const Text(
            'How can we help you?',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 30),
          
          // Priority Services
          _buildHelpCard(
            context,
            icon: Icons.priority_high,
            title: 'Priority Services',
            subtitle: 'Get priority support for urgent issues',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PriorityServicesScreen()),
              );
            },
          ),
          
          const SizedBox(height: 16),
          
          // Help Center
          _buildHelpCard(
            context,
            icon: Icons.help_outline,
            title: 'Help Center',
            subtitle: 'Browse FAQs and guides',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HelpCenterScreen()),
              );
            },
          ),
          
          const SizedBox(height: 16),
          
          // Contact Support
          _buildHelpCard(
            context,
            icon: Icons.contact_support,
            title: 'Contact Support',
            subtitle: 'Get in touch with our support team',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ContactSupportScreen()),
              );
            },
          ),
          
          const SizedBox(height: 16),
          
          // WhatsApp Chat
          _buildHelpCard(
            context,
            icon: Icons.chat,
            title: 'WhatsApp Chat',
            subtitle: 'Chat with us on WhatsApp',
            onTap: () {
              _showWhatsAppInfo(context);
            },
          ),
          
          const SizedBox(height: 16),
          
          // Email Support
          _buildHelpCard(
            context,
            icon: Icons.email,
            title: 'Email Support',
            subtitle: 'Send us an email',
            onTap: () {
              _showEmailInfo(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHelpCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                icon,
                size: 40,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  void _showWhatsAppInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('WhatsApp Support'),
        content: const Text(
          'Contact us on WhatsApp:\n+255 700 000 000\n\nAvailable 24/7 for urgent queries',
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

  void _showEmailInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Email Support'),
        content: const Text(
          'Send us an email:\nsupport@jengamate.com\n\nResponse within 24 hours',
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

// Placeholder screens for navigation
class PriorityServicesScreen extends StatelessWidget {
  const PriorityServicesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Priority Services'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: const Center(
        child: Text('Priority Services - Coming Soon'),
      ),
    );
  }
}

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help Center'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: const Center(
        child: Text('Help Center - Coming Soon'),
      ),
    );
  }
}

class ContactSupportScreen extends StatelessWidget {
  const ContactSupportScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contact Support'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: const Center(
        child: Text('Contact Support - Coming Soon'),
      ),
    );
  }
}
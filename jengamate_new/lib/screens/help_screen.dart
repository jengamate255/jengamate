import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:jengamate/ui/design_system/components/responsive_wrapper.dart' hide AdaptivePadding;
import 'package:jengamate/ui/design_system/layout/adaptive_padding.dart';
import 'package:jengamate/ui/design_system/tokens/spacing.dart';
import 'package:jengamate/ui/design_system/components/jm_card.dart';
import 'package:jengamate/ui/design_system/components/jm_button.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  Future<void> _launchEmail(BuildContext context) async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'support@jengamate.com',
      query: 'subject=Support Request&body=Please describe your issue here.',
    );

    if (!await launchUrl(emailLaunchUri)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not launch email client.'),
          ),
        );
      }
    }
  }

  Future<void> _launchWhatsApp(BuildContext context) async {
    final Uri whatsappUri = Uri.parse('https://wa.me/254700000000?text=Hello, I need help with JengaMate');

    if (!await launchUrl(whatsappUri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not launch WhatsApp.'),
          ),
        );
      }
    }
  }

  Future<void> _launchPhone(BuildContext context) async {
    final Uri phoneUri = Uri.parse('tel:+254700000000');

    if (!await launchUrl(phoneUri)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not launch phone dialer.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
      ),
      body: AdaptivePadding(
        child: ListView(
          padding: const EdgeInsets.all(JMSpacing.md),
          children: [
            Text(
              'Frequently Asked Questions',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: JMSpacing.md),
            const _FaqItem(
              question: 'How do I reset my password?',
              answer:
                  'To reset your password, go to the login screen and tap on "Forgot Password". You will receive an email with instructions on how to reset it.',
            ),
            const _FaqItem(
              question: 'How do I update my profile information?',
              answer:
                  'You can update your profile information by navigating to the "Profile" tab and tapping the "Edit Profile" button.',
            ),
            const _FaqItem(
              question: 'How do I submit an RFQ (Request for Quotation)?',
              answer:
                  'To submit an RFQ, browse products and tap "Request Quote" on any product. Fill in your requirements and submit. Suppliers will respond with quotations.',
            ),
            const _FaqItem(
              question: 'How do I track my orders?',
              answer:
                  'You can track your orders by going to the Dashboard and viewing the "My Orders" section. Each order shows its current status and delivery information.',
            ),
            const _FaqItem(
              question: 'How do I communicate with suppliers?',
              answer:
                  'Use the built-in chat feature to communicate with suppliers. You can access chat from the main menu or directly from order/inquiry details.',
            ),
            const _FaqItem(
              question: 'What payment methods are accepted?',
              answer:
                  'We accept various payment methods including mobile money (M-Pesa), bank transfers, and credit/debit cards. Payment options are shown during checkout.',
            ),
            const _FaqItem(
              question: 'How can I contact customer support?',
              answer:
                  'You can contact our support team through email, WhatsApp, or phone using the contact options below. We are available 24/7 to assist you.',
            ),
            const SizedBox(height: JMSpacing.xl),
            Text(
              'Contact Support',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: JMSpacing.md),
            JMCard(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.email, color: Colors.blue),
                    title: const Text('Email Support'),
                    subtitle: const Text('support@jengamate.com'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _launchEmail(context),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.phone, color: Colors.green),
                    title: const Text('Phone Support'),
                    subtitle: const Text('+254 700 000 000'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _launchPhone(context),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.chat, color: Colors.green),
                    title: const Text('WhatsApp Support'),
                    subtitle: const Text('Chat with us on WhatsApp'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _launchWhatsApp(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: JMSpacing.lg),
            JMCard(
              child: Padding(
                padding: const EdgeInsets.all(JMSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Support Hours',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: JMSpacing.sm),
                    const Text('Monday - Friday: 8:00 AM - 6:00 PM EAT'),
                    const Text('Saturday: 9:00 AM - 4:00 PM EAT'),
                    const Text('Sunday: Emergency support only'),
                    const SizedBox(height: JMSpacing.md),
                    Text(
                      'Average Response Time',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: JMSpacing.sm),
                    const Text('Email: Within 2-4 hours'),
                    const Text('WhatsApp: Within 30 minutes'),
                    const Text('Phone: Immediate'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FaqItem extends StatelessWidget {
  final String question;
  final String answer;

  const _FaqItem({
    required this.question,
    required this.answer,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: JMSpacing.md),
      child: JMCard(
        padding: EdgeInsets.zero,
        child: ExpansionTile(
          title: Text(
            question,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.all(JMSpacing.md),
              child: Text(
                answer,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
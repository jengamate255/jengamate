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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not launch email client.'),
        ),
      );
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
              question: 'How can I contact customer support?',
              answer:
                  'You can contact our support team by tapping the "Contact Support" button below. We are available 24/7 to assist you.',
            ),
            const SizedBox(height: 24),
            const SizedBox(height: JMSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: JMButton(
                onPressed: () => _launchEmail(context),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.email),
                    SizedBox(width: 8),
                    Text('Contact Support'),
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
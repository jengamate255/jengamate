import 'package:flutter/material.dart';
import 'package:jengamate/models/notification_model.dart';
import 'package:jengamate/models/email_template.dart'; // Import EmailTemplate
import 'package:jengamate/models/email_template_type.dart'; // Import EmailTemplateType
import 'package:jengamate/services/database_service.dart';
import 'package:jengamate/services/email_service.dart'; // Import EmailService
import 'package:jengamate/ui/design_system/layout/adaptive_padding.dart';
import 'package:jengamate/ui/design_system/tokens/spacing.dart';
import 'package:jengamate/ui/design_system/components/jm_card.dart';
import 'package:intl/intl.dart';
import 'package:jengamate/screens/notifications/create_email_template_screen.dart'; // Import the new screen
import 'package:jengamate/screens/notifications/edit_email_template_screen.dart'; // Import the new screen
import 'package:jengamate/screens/notifications/preview_email_template_screen.dart'; // Import the new screen
import 'package:jengamate/screens/notifications/all_notifications_screen.dart'; // Import the new screen

class EmailNotificationsScreen extends StatefulWidget {
  const EmailNotificationsScreen({super.key});

  @override
  State<EmailNotificationsScreen> createState() =>
      _EmailNotificationsScreenState();
}

class _EmailNotificationsScreenState extends State<EmailNotificationsScreen> {
  final DatabaseService _dbService = DatabaseService();
  final EmailService _emailService = EmailService(); // Instantiate EmailService
  bool _orderConfirmations = true;
  bool _shippingUpdates = true;
  bool _paymentConfirmations = true;
  bool _deliveryUpdates = true;
  bool _promotionalEmails = false;
  bool _weeklyReports = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Email Notifications'),
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 0,
      ),
      body: AdaptivePadding(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildNotificationSettings(),
              const SizedBox(height: JMSpacing.lg),
              _buildEmailTemplates(),
              const SizedBox(height: JMSpacing.lg),
              _buildNotificationHistory(),
              const SizedBox(height: JMSpacing.lg),
              _buildTestEmailSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationSettings() {
    return JMCard(
      child: Padding(
        padding: const EdgeInsets.all(JMSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Notification Settings',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: JMSpacing.md),
            _buildNotificationOption(
              'Order Confirmations',
              'Send email when orders are confirmed',
              _orderConfirmations,
              (value) => setState(() => _orderConfirmations = value),
              Icons.check_circle,
            ),
            _buildNotificationOption(
              'Shipping Updates',
              'Notify customers when orders are shipped',
              _shippingUpdates,
              (value) => setState(() => _shippingUpdates = value),
              Icons.local_shipping,
            ),
            _buildNotificationOption(
              'Payment Confirmations',
              'Send receipts when payments are received',
              _paymentConfirmations,
              (value) => setState(() => _paymentConfirmations = value),
              Icons.payment,
            ),
            _buildNotificationOption(
              'Delivery Updates',
              'Notify when orders are delivered',
              _deliveryUpdates,
              (value) => setState(() => _deliveryUpdates = value),
              Icons.delivery_dining,
            ),
            _buildNotificationOption(
              'Promotional Emails',
              'Send marketing and promotional content',
              _promotionalEmails,
              (value) => setState(() => _promotionalEmails = value),
              Icons.campaign,
            ),
            _buildNotificationOption(
              'Weekly Reports',
              'Send weekly sales and performance reports',
              _weeklyReports,
              (value) => setState(() => _weeklyReports = value),
              Icons.analytics,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationOption(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: JMSpacing.sm),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).primaryColor, size: 24),
          const SizedBox(width: JMSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Theme.of(context).primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildEmailTemplates() {
    return JMCard(
      child: Padding(
        padding: const EdgeInsets.all(JMSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Email Templates',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () => _createNewTemplate(),
                  child: const Text('Create New'),
                ),
              ],
            ),
            const SizedBox(height: JMSpacing.md),
            StreamBuilder<List<EmailTemplate>>(
              stream: _emailService.streamEmailTemplates(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No email templates found.'));
                }
                final templates = snapshot.data!;
                return Column(
                  children: templates
                      .map((template) => _buildTemplateItem(template))
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplateItem(
    EmailTemplate template,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: JMSpacing.sm),
      padding: const EdgeInsets.all(JMSpacing.sm),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(Icons.email, color: Theme.of(context).primaryColor, size: 20),
          ),
          const SizedBox(width: JMSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  template.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  template.subject,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) => _handleTemplateAction(value, template),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit),
                    SizedBox(width: 8),
                    Text('Edit Template'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'preview',
                child: Row(
                  children: [
                    Icon(Icons.preview),
                    SizedBox(width: 8),
                    Text('Preview'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'duplicate',
                child: Row(
                  children: [
                    Icon(Icons.copy),
                    SizedBox(width: 8),
                    Text('Duplicate'),
                  ],
                ),
              ),
            ],
            child: const Icon(Icons.more_vert),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationHistory() {
    return JMCard(
      child: Padding(
        padding: const EdgeInsets.all(JMSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Notifications',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () => _viewAllNotifications(),
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: JMSpacing.md),
            StreamBuilder<List<NotificationModel>>(
              stream: _dbService.getNotifications(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final notifications = snapshot.data!;
                final recentNotifications = notifications.take(5).toList();

                if (recentNotifications.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(JMSpacing.lg),
                      child: Text('No recent notifications'),
                    ),
                  );
                }

                return Column(
                  children: recentNotifications
                      .map((notification) =>
                          _buildNotificationItem(notification))
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationItem(NotificationModel notification) {
    return Container(
      margin: const EdgeInsets.only(bottom: JMSpacing.sm),
      padding: const EdgeInsets.all(JMSpacing.sm),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _getNotificationColor(notification.type).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              _getNotificationIcon(notification.type),
              color: _getNotificationColor(notification.type),
              size: 20,
            ),
          ),
          const SizedBox(width: JMSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification.title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  notification.message,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  DateFormat('MMM dd, yyyy HH:mm')
                      .format(notification.createdAt),
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: notification.isRead ? Colors.grey.shade200 : Colors.blue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              notification.isRead ? 'Read' : 'New',
              style: TextStyle(
                color:
                    notification.isRead ? Colors.grey.shade600 : Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestEmailSection() {
    return JMCard(
      child: Padding(
        padding: const EdgeInsets.all(JMSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Test Email Notifications',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: JMSpacing.md),
            const Text(
              'Send test emails to verify your notification settings and templates.',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: JMSpacing.md),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _sendTestEmail('order_confirmation'),
                    icon: const Icon(Icons.email),
                    label: const Text('Test Order Confirmation'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: JMSpacing.sm),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _sendTestEmail('shipping_update'),
                    icon: const Icon(Icons.local_shipping),
                    label: const Text('Test Shipping Update'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: JMSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _sendTestEmail('payment_receipt'),
                    icon: const Icon(Icons.receipt),
                    label: const Text('Test Payment Receipt'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: JMSpacing.sm),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _sendTestEmail('delivery_confirmation'),
                    icon: const Icon(Icons.delivery_dining),
                    label: const Text('Test Delivery Confirmation'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods
  Color _getNotificationColor(String type) {
    switch (type) {
      case 'order_confirmation':
        return Colors.green;
      case 'shipping_update':
        return Colors.blue;
      case 'payment_receipt':
        return Colors.orange;
      case 'delivery_confirmation':
        return Colors.purple;
      case 'promotional':
        return Colors.pink;
      default:
        return Colors.grey;
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'order_confirmation':
        return Icons.check_circle;
      case 'shipping_update':
        return Icons.local_shipping;
      case 'payment_receipt':
        return Icons.receipt;
      case 'delivery_confirmation':
        return Icons.delivery_dining;
      case 'promotional':
        return Icons.campaign;
      default:
        return Icons.notifications;
    }
  }

  void _createNewTemplate() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateEmailTemplateScreen(),
      ),
    );
  }

  void _handleTemplateAction(String action, EmailTemplate template) {
    switch (action) {
      case 'edit':
        _editTemplate(template);
        break;
      case 'preview':
        _previewTemplate(template);
        break;
      case 'duplicate':
        _duplicateTemplate(template);
        break;
    }
  }

  void _editTemplate(EmailTemplate template) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditEmailTemplateScreen(template: template),
      ),
    );
  }

  void _previewTemplate(EmailTemplate template) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PreviewEmailTemplateScreen(template: template),
      ),
    );
  }

  void _duplicateTemplate(EmailTemplate template) async {
    final newTemplate = template.copyWith(
      id: '', // Firestore will generate a new ID
      name: '${template.name} (Copy)',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      await _emailService.createEmailTemplate(newTemplate);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Template \'${template.name}\' duplicated successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error duplicating template: $e')),
      );
    }
  }

  void _viewAllNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AllNotificationsScreen(),
      ),
    );
  }

  void _sendTestEmail(String emailType) async {
    try {
      final EmailTemplateType type = EmailTemplateType.values.firstWhere(
        (e) => e.toString().split('.').last == emailType,
        orElse: () => EmailTemplateType.other, // Default or handle error
      );
      await _emailService.sendTestEmail(type, "test@example.com"); // Replace with actual recipient
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Test $emailType email sent successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending test $emailType email: $e')),
      );
    }
  }
}


import 'package:flutter/material.dart';
import 'package:jengamate/services/admin_notification_service.dart';

class NotificationDemoScreen extends StatefulWidget {
  const NotificationDemoScreen({Key? key}) : super(key: key);

  @override
  _NotificationDemoScreenState createState() => _NotificationDemoScreenState();
}

class _NotificationDemoScreenState extends State<NotificationDemoScreen> {
  final AdminNotificationService _notificationService = AdminNotificationService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Demo'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Real-Time Notification System Demo',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Click the buttons below to create different types of notifications and test the real-time system.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 32),

            // User Activity Notifications
            _buildSectionHeader('User Activity'),
            _buildDemoButton(
              'New User Registration',
              'Simulate 5 new user registrations',
              Icons.person_add,
              Colors.blue,
              () => _createUserRegistrationNotification(),
            ),
            _buildDemoButton(
              'Bulk User Registration',
              'Simulate high user activity (10+ users)',
              Icons.group_add,
              Colors.blue,
              () => _createBulkUserNotification(),
            ),

            const SizedBox(height: 32),

            // Order & Payment Notifications
            _buildSectionHeader('Orders & Payments'),
            _buildDemoButton(
              'New Order Alert',
              'Simulate new order creation',
              Icons.shopping_cart,
              Colors.green,
              () => _createOrderNotification(),
            ),
            _buildDemoButton(
              'Large Order Alert',
              'Simulate order over \$10,000',
              Icons.attach_money,
              Colors.green,
              () => _createLargeOrderNotification(),
            ),
            _buildDemoButton(
              'Payment Failure',
              'Simulate payment processing failure',
              Icons.payment,
              Colors.red,
              () => _createPaymentFailureNotification(),
            ),

            const SizedBox(height: 32),

            // Content & Moderation
            _buildSectionHeader('Content Moderation'),
            _buildDemoButton(
              'Content Report',
              'Simulate new content report',
              Icons.flag,
              Colors.orange,
              () => _createContentReportNotification(),
            ),
            _buildDemoButton(
              'Urgent Content Report',
              'Simulate urgent content with keywords',
              Icons.warning,
              Colors.red,
              () => _createUrgentContentNotification(),
            ),

            const SizedBox(height: 32),

            // System Health
            _buildSectionHeader('System Health'),
            _buildDemoButton(
              'System Health Alert',
              'Simulate system health issue',
              Icons.health_and_safety,
              Colors.red,
              () => _createSystemHealthNotification(),
            ),
            _buildDemoButton(
              'Performance Alert',
              'Simulate slow response time',
              Icons.speed,
              Colors.orange,
              () => _createPerformanceNotification(),
            ),

            const SizedBox(height: 32),

            // Security & Critical
            _buildSectionHeader('Security & Critical'),
            _buildDemoButton(
              'Security Alert',
              'Simulate security incident',
              Icons.security,
              Colors.red,
              () => _createSecurityNotification(),
            ),
            _buildDemoButton(
              'Maintenance Notice',
              'Simulate system maintenance',
              Icons.build,
              Colors.blue,
              () => _createMaintenanceNotification(),
            ),

            const SizedBox(height: 32),

            // Information
            _buildSectionHeader('Information'),
            _buildDemoButton(
              'Success Notification',
              'Simulate successful operation',
              Icons.check_circle,
              Colors.green,
              () => _createSuccessNotification(),
            ),
            _buildDemoButton(
              'General Info',
              'Simulate general information',
              Icons.info,
              Colors.blue,
              () => _createInfoNotification(),
            ),

            const SizedBox(height: 48),

            // How it works section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'How the Notification System Works',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildHowItWorksItem(
                      'Real-Time Monitoring',
                      'The system continuously monitors user activity, orders, payments, and system health.',
                    ),
                    _buildHowItWorksItem(
                      'Smart Triggers',
                      'Automatic notifications are created based on predefined thresholds and conditions.',
                    ),
                    _buildHowItWorksItem(
                      'Priority Levels',
                      'Notifications are categorized by priority (Low, Medium, High, Critical) for appropriate handling.',
                    ),
                    _buildHowItWorksItem(
                      'Admin Dashboard',
                      'Real-time updates appear in the admin dashboard with badges and banners.',
                    ),
                    _buildHowItWorksItem(
                      'Mobile Responsive',
                      'Notifications work seamlessly across desktop, tablet, and mobile devices.',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.blue,
        ),
      ),
    );
  }

  Widget _buildDemoButton(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildHowItWorksItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Demo notification creation methods
  Future<void> _createUserRegistrationNotification() async {
    await _notificationService.createNotification(
      title: 'New User Registration',
      message: '5 new users have registered in the last hour',
      type: NotificationType.info,
      priority: NotificationPriority.medium,
      category: 'user_activity',
      broadcastToAllAdmins: true,
    );
    _showSuccessSnackBar('User registration notification created!');
  }

  Future<void> _createBulkUserNotification() async {
    await _notificationService.createNotification(
      title: 'High User Registration Activity',
      message: '12 new users registered in the last hour - above normal threshold',
      type: NotificationType.info,
      priority: NotificationPriority.medium,
      category: 'user_activity',
      broadcastToAllAdmins: true,
    );
    _showSuccessSnackBar('Bulk user registration notification created!');
  }

  Future<void> _createOrderNotification() async {
    await _notificationService.createNotification(
      title: 'New Order Created',
      message: 'Order #ORD-2024-001 has been created and requires processing',
      type: NotificationType.info,
      priority: NotificationPriority.medium,
      category: 'order_activity',
      data: {'orderId': 'ORD-2024-001', 'amount': 2500},
      broadcastToAllAdmins: true,
    );
    _showSuccessSnackBar('Order notification created!');
  }

  Future<void> _createLargeOrderNotification() async {
    await _notificationService.createNotification(
      title: 'Large Order Alert',
      message: 'Order #ORD-2024-002 for \$15,000 requires immediate attention',
      type: NotificationType.warning,
      priority: NotificationPriority.high,
      category: 'large_order',
      data: {'orderId': 'ORD-2024-002', 'amount': 15000},
      broadcastToAllAdmins: true,
    );
    _showSuccessSnackBar('Large order notification created!');
  }

  Future<void> _createPaymentFailureNotification() async {
    await _notificationService.createNotification(
      title: 'Payment Processing Failed',
      message: 'Payment for Order #ORD-2024-003 failed. Customer needs assistance.',
      type: NotificationType.warning,
      priority: NotificationPriority.high,
      category: 'payment_failure',
      data: {'orderId': 'ORD-2024-003', 'amount': 1200},
      broadcastToAllAdmins: true,
    );
    _showSuccessSnackBar('Payment failure notification created!');
  }

  Future<void> _createContentReportNotification() async {
    await _notificationService.createNotification(
      title: 'Content Report Submitted',
      message: 'New content report requires moderation review',
      type: NotificationType.warning,
      priority: NotificationPriority.medium,
      category: 'content_moderation',
      broadcastToAllAdmins: true,
    );
    _showSuccessSnackBar('Content report notification created!');
  }

  Future<void> _createUrgentContentNotification() async {
    await _notificationService.createNotification(
      title: 'Urgent Content Report',
      message: 'Content report contains urgent keywords: "harassment", "threat". Immediate review required.',
      type: NotificationType.critical,
      priority: NotificationPriority.critical,
      category: 'urgent_content',
      broadcastToAllAdmins: true,
    );
    _showSuccessSnackBar('Urgent content notification created!');
  }

  Future<void> _createSystemHealthNotification() async {
    await _notificationService.createNotification(
      title: 'System Health Critical',
      message: 'Database connection lost. System is experiencing critical errors.',
      type: NotificationType.critical,
      priority: NotificationPriority.critical,
      category: 'system_health',
      broadcastToAllAdmins: true,
    );
    _showSuccessSnackBar('System health notification created!');
  }

  Future<void> _createPerformanceNotification() async {
    await _notificationService.createNotification(
      title: 'Performance Degradation',
      message: 'System response time is 8.5 seconds, which is above the 5-second threshold',
      type: NotificationType.warning,
      priority: NotificationPriority.medium,
      category: 'performance',
      data: {'responseTime': 8500},
      broadcastToAllAdmins: true,
    );
    _showSuccessSnackBar('Performance notification created!');
  }

  Future<void> _createSecurityNotification() async {
    await _notificationService.createNotification(
      title: 'Security Incident Detected',
      message: 'Multiple failed login attempts detected from IP 192.168.1.100',
      type: NotificationType.critical,
      priority: NotificationPriority.critical,
      category: 'security',
      data: {'ipAddress': '192.168.1.100', 'attempts': 15},
      broadcastToAllAdmins: true,
    );
    _showSuccessSnackBar('Security notification created!');
  }

  Future<void> _createMaintenanceNotification() async {
    await _notificationService.createNotification(
      title: 'Scheduled Maintenance',
      message: 'System maintenance scheduled for tonight at 2:00 AM. Expected downtime: 30 minutes.',
      type: NotificationType.info,
      priority: NotificationPriority.low,
      category: 'maintenance',
      broadcastToAllAdmins: true,
    );
    _showSuccessSnackBar('Maintenance notification created!');
  }

  Future<void> _createSuccessNotification() async {
    await _notificationService.createNotification(
      title: 'Backup Completed Successfully',
      message: 'Daily system backup completed successfully at 3:00 AM',
      type: NotificationType.success,
      priority: NotificationPriority.low,
      category: 'system_backup',
      broadcastToAllAdmins: true,
    );
    _showSuccessSnackBar('Success notification created!');
  }

  Future<void> _createInfoNotification() async {
    await _notificationService.createNotification(
      title: 'New Feature Released',
      message: 'Enhanced notification system is now live with real-time updates',
      type: NotificationType.info,
      priority: NotificationPriority.low,
      category: 'feature_update',
      broadcastToAllAdmins: true,
    );
    _showSuccessSnackBar('Info notification created!');
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:jengamate/models/notification_model.dart';
import 'package:jengamate/services/database_service.dart';
import 'package:jengamate/ui/design_system/layout/adaptive_padding.dart';
import 'package:jengamate/ui/design_system/tokens/spacing.dart';
import 'package:intl/intl.dart';

class AllNotificationsScreen extends StatefulWidget {
  const AllNotificationsScreen({Key? key}) : super(key: key);

  @override
  State<AllNotificationsScreen> createState() => _AllNotificationsScreenState();
}

class _AllNotificationsScreenState extends State<AllNotificationsScreen> {
  final DatabaseService _dbService = DatabaseService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Notifications'),
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 0,
      ),
      body: AdaptivePadding(
        child: StreamBuilder<List<NotificationModel>>(
          stream: _dbService.getNotifications(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                child: Text('No notifications found.'),
              );
            }

            final notifications = snapshot.data!;

            return ListView.separated(
              itemCount: notifications.length,
              separatorBuilder: (_, __) => const SizedBox(height: JMSpacing.sm),
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return _buildNotificationItem(notification);
              },
            );
          },
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
              color: _getNotificationColor(notification.type).withOpacity(0.1),
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
                  DateFormat('MMM dd, yyyy HH:mm').format(notification.createdAt),
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
}

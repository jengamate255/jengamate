import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:jengamate/models/notification_model.dart';
import 'package:jengamate/models/user_model.dart';
import 'package:jengamate/services/database_service.dart';
import 'package:jengamate/services/notification_service.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late Stream<List<NotificationModel>> _notificationsStream;
  final DatabaseService _databaseService = DatabaseService();
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    final user = Provider.of<UserModel?>(context, listen: false);
    if (user != null) {
      _notificationsStream = _databaseService.streamUserNotifications(user.uid);
    } else {
      _notificationsStream = Stream.value([]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: StreamBuilder<List<NotificationModel>>(
        stream: _notificationsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'You have no notifications.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          final notifications = snapshot.data!;

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                elevation: 2,
                child: ListTile(
                  leading: Icon(
                    Icons.notifications,
                    color: notification.isRead
                        ? Colors.grey
                        : Theme.of(context).primaryColor,
                  ),
                  title: Text(
                    notification.title,
                    style: TextStyle(
                      fontWeight: notification.isRead
                          ? FontWeight.normal
                          : FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(notification.message),
                  trailing: Text(
                    timeago.format(notification.createdAt),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  onTap: () {
                    if (!notification.isRead) {
                      _notificationService.markNotificationAsRead(notification.id);
                    }

                    if (notification.type == 'rfq' && notification.relatedId != null) {
                      context.go('/rfqs/${notification.relatedId}');
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
} 
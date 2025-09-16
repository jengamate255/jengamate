import 'package:flutter/material.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final List<Map<String, dynamic>> _notifications = [
    {
      'id': '1',
      'title': 'New User Registration',
      'message': '5 new users registered in the last hour',
      'type': 'info',
      'timestamp': DateTime.now().subtract(const Duration(minutes: 30)),
      'isRead': false,
    },
    {
      'id': '2',
      'title': 'Document Verification Pending',
      'message': '12 documents awaiting verification',
      'type': 'warning',
      'timestamp': DateTime.now().subtract(const Duration(hours: 2)),
      'isRead': false,
    },
    {
      'id': '3',
      'title': 'System Health Alert',
      'message': 'Database response time is above normal',
      'type': 'error',
      'timestamp': DateTime.now().subtract(const Duration(hours: 4)),
      'isRead': true,
    },
    {
      'id': '4',
      'title': 'RFQ Created',
      'message': 'New RFQ from Premium Customer #1234',
      'type': 'info',
      'timestamp': DateTime.now().subtract(const Duration(hours: 6)),
      'isRead': true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'mark_all_read':
                  _markAllAsRead();
                  break;
                case 'clear_all':
                  _clearAllNotifications();
                  break;
                case 'refresh':
                  _refreshNotifications();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'mark_all_read',
                child: Row(
                  children: [
                    Icon(Icons.mark_email_read, size: 20),
                    SizedBox(width: 8),
                    Text('Mark All Read'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear_all',
                child: Row(
                  children: [
                    Icon(Icons.clear_all, size: 20),
                    SizedBox(width: 8),
                    Text('Clear All'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'refresh',
                child: Row(
                  children: [
                    Icon(Icons.refresh, size: 20),
                    SizedBox(width: 8),
                    Text('Refresh'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter tabs
          _buildFilterTabs(isMobile),
          Expanded(
            child: _notifications.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
                  itemCount: _notifications.length,
                  itemBuilder: (context, index) {
                    final notification = _notifications[index];
                    return _buildNotificationCard(notification, isMobile);
                  },
                ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: "createNotification",
        onPressed: _createTestNotification,
        tooltip: 'Create Test Notification',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFilterTabs(bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12.0 : 16.0,
        vertical: 8.0,
      ),
      child: Row(
        children: [
          _buildFilterChip('All', _notifications.length, true),
          const SizedBox(width: 8),
          _buildFilterChip('Unread', _notifications.where((n) => !n['isRead']).length, false),
          const SizedBox(width: 8),
          _buildFilterChip('Critical', _notifications.where((n) => n['type'] == 'critical').length, false),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, int count, bool isSelected) {
    return FilterChip(
      label: Text('$label ($count)'),
      selected: isSelected,
      onSelected: (selected) {
        // TODO: Implement filtering logic
        setState(() {
          // Update filter state
        });
      },
      backgroundColor: isSelected ? Theme.of(context).primaryColor.withOpacity(0.1) : null,
      selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No notifications',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You\'re all caught up!',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification, bool isMobile) {
    final Color typeColor = _getTypeColor(notification['type']);
    final IconData typeIcon = _getTypeIcon(notification['type']);

    return Card(
      margin: EdgeInsets.only(bottom: isMobile ? 8.0 : 12.0),
      elevation: notification['isRead'] ? 1 : 3,
      child: InkWell(
        onTap: () => _markAsRead(notification['id']),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: typeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  typeIcon,
                  color: typeColor,
                  size: isMobile ? 20 : 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification['title'],
                            style: TextStyle(
                              fontWeight: notification['isRead']
                                ? FontWeight.normal
                                : FontWeight.bold,
                              fontSize: isMobile ? 14 : 16,
                            ),
                          ),
                        ),
                        if (!notification['isRead'])
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification['message'],
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: isMobile ? 12 : 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatTimestamp(notification['timestamp']),
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: isMobile ? 10 : 12,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.more_vert,
                  size: isMobile ? 18 : 20,
                ),
                onPressed: () => _showNotificationActions(notification),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'error':
        return Colors.red;
      case 'warning':
        return Colors.orange;
      case 'info':
        return Colors.blue;
      case 'success':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'error':
        return Icons.error;
      case 'warning':
        return Icons.warning;
      case 'info':
        return Icons.info;
      case 'success':
        return Icons.check_circle;
      default:
        return Icons.notifications;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  void _markAsRead(String id) {
    setState(() {
      final notification = _notifications.firstWhere((n) => n['id'] == id);
      notification['isRead'] = true;
    });
  }

  void _markAllAsRead() {
    setState(() {
      for (var notification in _notifications) {
        notification['isRead'] = true;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All notifications marked as read'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showNotificationActions(Map<String, dynamic> notification) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.check),
            title: const Text('Mark as Read'),
            onTap: () {
              Navigator.of(context).pop();
              _markAsRead(notification['id']);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete),
            title: const Text('Delete'),
            onTap: () {
              Navigator.of(context).pop();
              _deleteNotification(notification['id']);
            },
          ),
        ],
      ),
    );
  }

  void _deleteNotification(String id) {
    setState(() {
      _notifications.removeWhere((n) => n['id'] == id);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Notification deleted'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _clearAllNotifications() {
    setState(() {
      _notifications.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All notifications cleared'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _refreshNotifications() {
    // Simulate refresh by recreating sample notifications
    setState(() {
      _notifications = [
        {
          'id': '1',
          'title': 'New User Registration',
          'message': '5 new users registered in the last hour',
          'type': 'info',
          'timestamp': DateTime.now().subtract(const Duration(minutes: 30)),
          'isRead': false,
        },
        {
          'id': '2',
          'title': 'System Health Check',
          'message': 'All systems are running normally',
          'type': 'success',
          'timestamp': DateTime.now().subtract(const Duration(hours: 1)),
          'isRead': true,
        },
        {
          'id': '3',
          'title': 'Payment Processed',
          'message': 'Payment of \$500 has been successfully processed',
          'type': 'info',
          'timestamp': DateTime.now().subtract(const Duration(hours: 2)),
          'isRead': false,
        },
      ];
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Notifications refreshed'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _createTestNotification() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Test Notification'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('This will create a test notification for demonstration purposes.'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _addTestNotification();
              },
              child: const Text('Create Notification'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _addTestNotification() {
    final newNotification = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'title': 'Test Notification',
      'message': 'This is a test notification created at ${DateTime.now().toString()}',
      'type': 'info',
      'timestamp': DateTime.now(),
      'isRead': false,
    };

    setState(() {
      _notifications.insert(0, newNotification);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Test notification created'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}

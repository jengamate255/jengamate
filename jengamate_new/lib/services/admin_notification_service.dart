import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';
import 'package:jengamate/utils/logger.dart';

enum NotificationType {
  info,
  warning,
  error,
  success,
  critical
}

enum NotificationPriority {
  low,
  medium,
  high,
  critical
}

class AdminNotification {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final NotificationPriority priority;
  final DateTime timestamp;
  final Map<String, dynamic>? data;
  final String? actionUrl;
  final bool isRead;
  final String? userId;
  final String? category;

  const AdminNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.priority,
    required this.timestamp,
    this.data,
    this.actionUrl,
    this.isRead = false,
    this.userId,
    this.category,
  });

  factory AdminNotification.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AdminNotification(
      id: doc.id,
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      type: NotificationType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => NotificationType.info,
      ),
      priority: NotificationPriority.values.firstWhere(
        (e) => e.name == data['priority'],
        orElse: () => NotificationPriority.medium,
      ),
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      data: data['data'],
      actionUrl: data['actionUrl'],
      isRead: data['isRead'] ?? false,
      userId: data['userId'],
      category: data['category'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'message': message,
      'type': type.name,
      'priority': priority.name,
      'timestamp': Timestamp.fromDate(timestamp),
      'data': data,
      'actionUrl': actionUrl,
      'isRead': isRead,
      'userId': userId,
      'category': category,
    };
  }

  Color getTypeColor() {
    switch (type) {
      case NotificationType.error:
      case NotificationType.critical:
        return Colors.red;
      case NotificationType.warning:
        return Colors.orange;
      case NotificationType.success:
        return Colors.green;
      case NotificationType.info:
        return Colors.blue;
    }
  }

  IconData getTypeIcon() {
    switch (type) {
      case NotificationType.error:
      case NotificationType.critical:
        return Icons.error;
      case NotificationType.warning:
        return Icons.warning;
      case NotificationType.success:
        return Icons.check_circle;
      case NotificationType.info:
        return Icons.info;
    }
  }

  bool get isCritical => priority == NotificationPriority.critical || type == NotificationType.critical;
}

class AdminNotificationService {
  static final AdminNotificationService _instance = AdminNotificationService._internal();
  factory AdminNotificationService() => _instance;

  AdminNotificationService._internal() {
    _initializeStreams();
  }

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Streams for real-time notifications
  final BehaviorSubject<List<AdminNotification>> _notificationsStream = BehaviorSubject.seeded([]);
  final BehaviorSubject<int> _unreadCountStream = BehaviorSubject.seeded(0);
  final BehaviorSubject<List<AdminNotification>> _criticalAlertsStream = BehaviorSubject.seeded([]);

  StreamSubscription<QuerySnapshot>? _notificationsSubscription;
  StreamSubscription<QuerySnapshot>? _systemEventsSubscription;

  // Getters for streams
  Stream<List<AdminNotification>> get notificationsStream => _notificationsStream.stream;
  Stream<int> get unreadCountStream => _unreadCountStream.stream;
  Stream<List<AdminNotification>> get criticalAlertsStream => _criticalAlertsStream.stream;

  void _initializeStreams() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    // Listen to user-specific notifications with error handling
    try {
      _notificationsSubscription = _firestore
          .collection('admin_notifications')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(100)
          .snapshots()
          .listen(
            _handleNotificationsUpdate,
            onError: (error) {
              Logger.logError('Failed to listen to notifications stream', error);
              // Emit empty list to prevent infinite reloading
              _notificationsStream.add([]);
              _unreadCountStream.add(0);
            },
          );
    } catch (e) {
      Logger.logError('Error setting up notifications stream', e);
      // Emit empty list to prevent infinite reloading
      _notificationsStream.add([]);
      _unreadCountStream.add(0);
    }

    // Listen to system-wide critical alerts with error handling
    try {
      _systemEventsSubscription = _firestore
          .collection('system_events')
          .where('priority', isEqualTo: 'critical')
          .where('timestamp', isGreaterThan: Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 24))))
          .snapshots()
          .listen(
            _handleSystemEventsUpdate,
            onError: (error) {
              Logger.logError('Failed to listen to system events stream', error);
              // Emit empty list to prevent infinite reloading
              _criticalAlertsStream.add([]);
            },
          );
    } catch (e) {
      Logger.logError('Error setting up system events stream', e);
      // Emit empty list to prevent infinite reloading
      _criticalAlertsStream.add([]);
    }
  }

  void _handleNotificationsUpdate(QuerySnapshot snapshot) {
    try {
      final notifications = snapshot.docs
          .map((doc) => AdminNotification.fromFirestore(doc))
          .toList();

      _notificationsStream.add(notifications);
      _unreadCountStream.add(notifications.where((n) => !n.isRead).length);
    } catch (e) {
      Logger.logError('Error processing notifications update', e);
      // Emit empty list to prevent infinite reloading
      _notificationsStream.add([]);
      _unreadCountStream.add(0);
    }
  }

  void _handleSystemEventsUpdate(QuerySnapshot snapshot) {
    try {
      final criticalAlerts = snapshot.docs
          .map((doc) => AdminNotification.fromFirestore(doc))
          .where((notification) => notification.isCritical)
          .toList();

      _criticalAlertsStream.add(criticalAlerts);
    } catch (e) {
      Logger.logError('Error processing system events update', e);
      // Emit empty list to prevent infinite reloading
      _criticalAlertsStream.add([]);
    }
  }

  // Create notification
  Future<String> createNotification({
    required String title,
    required String message,
    required NotificationType type,
    NotificationPriority priority = NotificationPriority.medium,
    Map<String, dynamic>? data,
    String? actionUrl,
    String? category,
    bool broadcastToAllAdmins = false,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      final notificationId = _firestore.collection('admin_notifications').doc().id;

      final notification = AdminNotification(
        id: notificationId,
        title: title,
        message: message,
        type: type,
        priority: priority,
        timestamp: DateTime.now(),
        data: data,
        actionUrl: actionUrl,
        category: category,
        userId: broadcastToAllAdmins ? null : userId,
      );

      if (broadcastToAllAdmins) {
        // Get all admin users and create notification for each
        final adminUsers = await _firestore
            .collection('users')
            .where('role', isEqualTo: 'admin')
            .get();

        final batch = _firestore.batch();
        for (var adminUser in adminUsers.docs) {
          final userNotification = AdminNotification(
            id: '${notificationId}_${adminUser.id}',
            title: title,
            message: message,
            type: type,
            priority: priority,
            timestamp: DateTime.now(),
            data: data,
            actionUrl: actionUrl,
            category: category,
            userId: adminUser.id,
          );

          final docRef = _firestore.collection('admin_notifications').doc(userNotification.id);
          batch.set(docRef, userNotification.toFirestore());
        }
        await batch.commit();
      } else {
        await _firestore
            .collection('admin_notifications')
            .doc(notificationId)
            .set(notification.toFirestore());
      }

      Logger.log('Admin notification created: $title');
      return notificationId;
    } catch (e, stackTrace) {
      Logger.logError('Failed to create admin notification', e, stackTrace);
      rethrow;
    }
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore
          .collection('admin_notifications')
          .doc(notificationId)
          .update({'isRead': true});

      Logger.log('Notification marked as read: $notificationId');
    } catch (e, stackTrace) {
      Logger.logError('Failed to mark notification as read', e, stackTrace);
      rethrow;
    }
  }

  // Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      final batch = _firestore.batch();
      final unreadNotifications = await _firestore
          .collection('admin_notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      for (var doc in unreadNotifications.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
      Logger.log('All notifications marked as read for user: $userId');
    } catch (e, stackTrace) {
      Logger.logError('Failed to mark all notifications as read', e, stackTrace);
      rethrow;
    }
  }

  // Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore
          .collection('admin_notifications')
          .doc(notificationId)
          .delete();

      Logger.log('Notification deleted: $notificationId');
    } catch (e, stackTrace) {
      Logger.logError('Failed to delete notification', e, stackTrace);
      rethrow;
    }
  }

  // Auto-generate notifications based on system events
  Future<void> checkAndCreateSystemAlerts() async {
    try {
      await _checkUserRegistrations();
      await _checkPaymentIssues();
      await _checkContentModeration();
      await _checkSystemHealth();
      await _checkRFQActivity();
    } catch (e, stackTrace) {
      Logger.logError('Failed to check and create system alerts', e, stackTrace);
    }
  }

  Future<void> _checkUserRegistrations() async {
    try {
      // Check for new user registrations in the last hour
      final oneHourAgo = DateTime.now().subtract(const Duration(hours: 1));
      final recentUsers = await _firestore
          .collection('users')
          .where('createdAt', isGreaterThan: Timestamp.fromDate(oneHourAgo))
          .get();

      if (recentUsers.docs.length >= 5) {
        await createNotification(
          title: 'High User Registration Activity',
          message: '${recentUsers.docs.length} new users registered in the last hour',
          type: NotificationType.info,
          priority: NotificationPriority.medium,
          category: 'user_activity',
          broadcastToAllAdmins: true,
        );
      }
    } catch (e) {
      Logger.logError('Failed to check user registrations', e, StackTrace.current);
    }
  }

  Future<void> _checkPaymentIssues() async {
    try {
      // Check for pending payments or failed transactions
      final pendingPayments = await _firestore
          .collection('payments')
          .where('status', isEqualTo: 'pending')
          .where('createdAt', isLessThan: Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 24))))
          .get();

      if (pendingPayments.docs.length > 10) {
        await createNotification(
          title: 'Payment Issues Detected',
          message: '${pendingPayments.docs.length} payments have been pending for over 24 hours',
          type: NotificationType.warning,
          priority: NotificationPriority.high,
          category: 'payment',
          broadcastToAllAdmins: true,
        );
      }
    } catch (e) {
      Logger.logError('Failed to check payment issues', e, StackTrace.current);
    }
  }

  Future<void> _checkContentModeration() async {
    try {
      // Check for flagged content that needs moderation
      final flaggedContent = await _firestore
          .collection('content_reports')
          .where('status', isEqualTo: 'pending')
          .get();

      if (flaggedContent.docs.length > 20) {
        await createNotification(
          title: 'Content Moderation Backlog',
          message: '${flaggedContent.docs.length} pieces of content are waiting for moderation',
          type: NotificationType.warning,
          priority: NotificationPriority.high,
          category: 'content_moderation',
          broadcastToAllAdmins: true,
        );
      }
    } catch (e) {
      Logger.logError('Failed to check content moderation', e, StackTrace.current);
    }
  }

  Future<void> _checkSystemHealth() async {
    try {
      // Check system health metrics
      final systemHealth = await _firestore
          .collection('system_health')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (systemHealth.docs.isNotEmpty) {
        final health = systemHealth.docs.first.data();
        final status = health['status'] as String?;

        if (status == 'error' || status == 'critical') {
          await createNotification(
            title: 'System Health Alert',
            message: 'System health status: ${status?.toUpperCase()}',
            type: NotificationType.critical,
            priority: NotificationPriority.critical,
            category: 'system_health',
            data: health,
            broadcastToAllAdmins: true,
          );
        }
      }
    } catch (e) {
      Logger.logError('Failed to check system health', e, StackTrace.current);
    }
  }

  Future<void> _checkRFQActivity() async {
    try {
      // Check for high RFQ activity
      final oneHourAgo = DateTime.now().subtract(const Duration(hours: 1));
      final recentRFQs = await _firestore
          .collection('rfqs')
          .where('createdAt', isGreaterThan: Timestamp.fromDate(oneHourAgo))
          .get();

      if (recentRFQs.docs.length >= 10) {
        await createNotification(
          title: 'High RFQ Activity',
          message: '${recentRFQs.docs.length} new RFQs created in the last hour',
          type: NotificationType.info,
          priority: NotificationPriority.medium,
          category: 'rfq_activity',
          broadcastToAllAdmins: true,
        );
      }
    } catch (e) {
      Logger.logError('Failed to check RFQ activity', e, StackTrace.current);
    }
  }

  // Cleanup old notifications
  Future<void> cleanupOldNotifications({int daysOld = 30}) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));
      final oldNotifications = await _firestore
          .collection('admin_notifications')
          .where('timestamp', isLessThan: Timestamp.fromDate(cutoffDate))
          .where('isRead', isEqualTo: true)
          .get();

      final batch = _firestore.batch();
      for (var doc in oldNotifications.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      Logger.log('Cleaned up ${oldNotifications.docs.length} old notifications');
    } catch (e, stackTrace) {
      Logger.logError('Failed to cleanup old notifications', e, stackTrace);
    }
  }

  // Dispose resources
  void dispose() {
    _notificationsSubscription?.cancel();
    _systemEventsSubscription?.cancel();
    _notificationsStream.close();
    _unreadCountStream.close();
    _criticalAlertsStream.close();
  }
}

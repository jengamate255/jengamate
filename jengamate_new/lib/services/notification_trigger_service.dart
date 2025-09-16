import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jengamate/services/admin_notification_service.dart';
import 'package:jengamate/utils/logger.dart';

class NotificationTriggerService {
  static final NotificationTriggerService _instance = NotificationTriggerService._internal();
  factory NotificationTriggerService() => _instance;

  NotificationTriggerService._internal() {
    _initializeTriggers();
  }

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AdminNotificationService _notificationService = AdminNotificationService();

  // Stream subscriptions for monitoring
  StreamSubscription<QuerySnapshot>? _userRegistrationSubscription;
  StreamSubscription<QuerySnapshot>? _orderSubscription;
  StreamSubscription<QuerySnapshot>? _paymentSubscription;
  StreamSubscription<QuerySnapshot>? _contentReportSubscription;

  Timer? _periodicHealthCheckTimer;
  Timer? _periodicCleanupTimer;

  void _initializeTriggers() {
    _setupUserRegistrationMonitoring();
    _setupOrderMonitoring();
    _setupPaymentMonitoring();
    _setupContentReportMonitoring();
    _startPeriodicTasks();
  }

  void _setupUserRegistrationMonitoring() {
    // Monitor new user registrations
    _userRegistrationSubscription = _firestore
        .collection('users')
        .where('createdAt', isGreaterThan: Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 24))))
        .snapshots()
        .listen(_handleUserRegistration);

    Logger.log('User registration monitoring started');
  }

  void _setupOrderMonitoring() {
    // Monitor new orders
    _orderSubscription = _firestore
        .collection('orders')
        .where('createdAt', isGreaterThan: Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 24))))
        .snapshots()
        .listen(_handleOrderActivity);

    Logger.log('Order monitoring started');
  }

  void _setupPaymentMonitoring() {
    // Monitor payment activities
    _paymentSubscription = _firestore
        .collection('payments')
        .where('createdAt', isGreaterThan: Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 24))))
        .snapshots()
        .listen(_handlePaymentActivity);

    Logger.log('Payment monitoring started');
  }

  void _setupContentReportMonitoring() {
    // Monitor content reports
    _contentReportSubscription = _firestore
        .collection('content_reports')
        .where('createdAt', isGreaterThan: Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 24))))
        .snapshots()
        .listen(_handleContentReportActivity);

    Logger.log('Content report monitoring started');
  }

  void _startPeriodicTasks() {
    // Health check every 30 minutes
    _periodicHealthCheckTimer = Timer.periodic(const Duration(minutes: 30), (_) {
      _performHealthCheck();
    });

    // Cleanup old notifications weekly
    _periodicCleanupTimer = Timer.periodic(const Duration(days: 7), (_) {
      _notificationService.cleanupOldNotifications();
    });

    Logger.log('Periodic tasks started');
  }

  Future<void> _handleUserRegistration(QuerySnapshot snapshot) async {
    try {
      final recentUsers = snapshot.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
        return createdAt != null &&
               createdAt.isAfter(DateTime.now().subtract(const Duration(hours: 1)));
      }).toList();

      if (recentUsers.length >= 5) {
        await _notificationService.createNotification(
          title: 'High User Registration Activity',
          message: '${recentUsers.length} new users registered in the last hour',
          type: NotificationType.info,
          priority: NotificationPriority.medium,
          category: 'user_activity',
          broadcastToAllAdmins: true,
        );
      }
    } catch (e) {
      Logger.logError('Error handling user registration', e, StackTrace.current);
    }
  }

  Future<void> _handleOrderActivity(QuerySnapshot snapshot) async {
    try {
      final recentOrders = snapshot.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
        return createdAt != null &&
               createdAt.isAfter(DateTime.now().subtract(const Duration(hours: 1)));
      }).toList();

      if (recentOrders.length >= 10) {
        await _notificationService.createNotification(
          title: 'High Order Activity',
          message: '${recentOrders.length} new orders created in the last hour',
          type: NotificationType.info,
          priority: NotificationPriority.medium,
          category: 'order_activity',
          broadcastToAllAdmins: true,
        );
      }

      // Check for large orders
      for (var doc in recentOrders) {
        final data = doc.data() as Map<String, dynamic>;
        final amount = data['totalAmount'] as num?;
        if (amount != null && amount > 10000) { // Orders over $10,000
          await _notificationService.createNotification(
            title: 'Large Order Alert',
            message: 'Order #${doc.id} with amount \$${amount.toStringAsFixed(2)} requires attention',
            type: NotificationType.warning,
            priority: NotificationPriority.high,
            category: 'large_order',
            data: {'orderId': doc.id, 'amount': amount},
            broadcastToAllAdmins: true,
          );
        }
      }
    } catch (e) {
      Logger.logError('Error handling order activity', e, StackTrace.current);
    }
  }

  Future<void> _handlePaymentActivity(QuerySnapshot snapshot) async {
    try {
      final failedPayments = snapshot.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return data['status'] == 'failed';
      }).toList();

      if (failedPayments.length > 5) {
        await _notificationService.createNotification(
          title: 'Payment Failures Detected',
          message: '${failedPayments.length} payments have failed recently',
          type: NotificationType.warning,
          priority: NotificationPriority.high,
          category: 'payment_failure',
          broadcastToAllAdmins: true,
        );
      }

      // Check for pending payments older than 24 hours
      final pendingPayments = snapshot.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
        return data['status'] == 'pending' &&
               createdAt != null &&
               createdAt.isBefore(DateTime.now().subtract(const Duration(hours: 24)));
      }).toList();

      if (pendingPayments.length > 10) {
        await _notificationService.createNotification(
          title: 'Pending Payments Alert',
          message: '${pendingPayments.length} payments have been pending for over 24 hours',
          type: NotificationType.warning,
          priority: NotificationPriority.medium,
          category: 'pending_payments',
          broadcastToAllAdmins: true,
        );
      }
    } catch (e) {
      Logger.logError('Error handling payment activity', e, StackTrace.current);
    }
  }

  Future<void> _handleContentReportActivity(QuerySnapshot snapshot) async {
    try {
      final pendingReports = snapshot.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return data['status'] == 'pending';
      }).toList();

      if (pendingReports.length > 20) {
        await _notificationService.createNotification(
          title: 'Content Moderation Backlog',
          message: '${pendingReports.length} content reports are waiting for moderation',
          type: NotificationType.warning,
          priority: NotificationPriority.high,
          category: 'content_moderation',
          broadcastToAllAdmins: true,
        );
      }

      // Check for urgent content reports (e.g., containing certain keywords)
      for (var doc in pendingReports) {
        final data = doc.data() as Map<String, dynamic>;
        final description = data['description'] as String? ?? '';
        final urgentKeywords = ['harassment', 'threat', 'violence', 'illegal'];

        if (urgentKeywords.any((keyword) =>
            description.toLowerCase().contains(keyword))) {
          await _notificationService.createNotification(
            title: 'Urgent Content Report',
            message: 'Content report #${doc.id} contains urgent keywords and needs immediate attention',
            type: NotificationType.critical,
            priority: NotificationPriority.critical,
            category: 'urgent_content',
            data: {'reportId': doc.id, 'description': description},
            broadcastToAllAdmins: true,
          );
        }
      }
    } catch (e) {
      Logger.logError('Error handling content report activity', e, StackTrace.current);
    }
  }

  Future<void> _performHealthCheck() async {
    try {
      // Check system health metrics
      final systemHealthDoc = await _firestore
          .collection('system_health')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (systemHealthDoc.docs.isNotEmpty) {
        final health = systemHealthDoc.docs.first.data();
        final status = health['status'] as String?;
        final responseTime = health['responseTime'] as num?;

        // Alert if system is unhealthy
        if (status == 'error' || status == 'critical') {
          await _notificationService.createNotification(
            title: 'System Health Critical',
            message: 'System status: ${status?.toUpperCase()}. Immediate attention required.',
            type: NotificationType.critical,
            priority: NotificationPriority.critical,
            category: 'system_health',
            data: health,
            broadcastToAllAdmins: true,
          );
        }

        // Alert if response time is too slow
        if (responseTime != null && responseTime > 5000) { // Over 5 seconds
          await _notificationService.createNotification(
            title: 'System Performance Issue',
            message: 'System response time is ${responseTime}ms, which is above normal threshold',
            type: NotificationType.warning,
            priority: NotificationPriority.medium,
            category: 'performance',
            data: {'responseTime': responseTime},
            broadcastToAllAdmins: true,
          );
        }
      }

      // Check database connection
      await _checkDatabaseHealth();

    } catch (e) {
      Logger.logError('Error performing health check', e, StackTrace.current);
    }
  }

  Future<void> _checkDatabaseHealth() async {
    try {
      // Simple query to test database connectivity
      final testQuery = await _firestore
          .collection('system_health')
          .limit(1)
          .get();

      // If we get here without error, database is healthy
      Logger.log('Database health check passed');
    } catch (e) {
      await _notificationService.createNotification(
        title: 'Database Connection Issue',
        message: 'Unable to connect to database: ${e.toString()}',
        type: NotificationType.critical,
        priority: NotificationPriority.critical,
        category: 'database',
        broadcastToAllAdmins: true,
      );
      Logger.logError('Database health check failed', e, StackTrace.current);
    }
  }

  // Manual trigger methods for testing or specific events
  Future<void> triggerSecurityAlert(String details) async {
    await _notificationService.createNotification(
      title: 'Security Alert',
      message: 'Security incident detected: $details',
      type: NotificationType.critical,
      priority: NotificationPriority.critical,
      category: 'security',
      data: {'details': details, 'timestamp': DateTime.now()},
      broadcastToAllAdmins: true,
    );
  }

  Future<void> triggerMaintenanceAlert(String message) async {
    await _notificationService.createNotification(
      title: 'Maintenance Alert',
      message: message,
      type: NotificationType.info,
      priority: NotificationPriority.medium,
      category: 'maintenance',
      broadcastToAllAdmins: true,
    );
  }

  // Cleanup method
  void dispose() {
    _userRegistrationSubscription?.cancel();
    _orderSubscription?.cancel();
    _paymentSubscription?.cancel();
    _contentReportSubscription?.cancel();
    _periodicHealthCheckTimer?.cancel();
    _periodicCleanupTimer?.cancel();

    Logger.log('Notification trigger service disposed');
  }
}

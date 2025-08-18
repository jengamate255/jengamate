import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:jengamate/models/rfq_model.dart';
import 'package:jengamate/models/user_model.dart';
import 'package:jengamate/services/database_service.dart';
import 'package:jengamate/utils/logger.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jengamate/models/notification_model.dart';
import 'package:jengamate/models/rfq_model.dart';
import 'package:jengamate/models/user_model.dart';
import 'package:jengamate/services/database_service.dart';
import 'package:jengamate/utils/logger.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationService {
  static NotificationService? _instance;
  final FlutterLocalNotificationsPlugin _notificationsPlugin = 
      FlutterLocalNotificationsPlugin();
  
  factory NotificationService() {
    _instance ??= NotificationService._internal();
    return _instance!;
  }
  
  final DatabaseService _databaseService = DatabaseService();

  NotificationService._internal();
  
  Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
    );
    
    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap
      },
    );
  }
  
  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'your_channel_id',
      'your_channel_name',
      channelDescription: 'your_channel_description',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
    );
    
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    
    await _notificationsPlugin.show(
      0,
      title,
      body,
      platformChannelSpecifics,
      payload: payload,
    );
  }
  
  Future<void> requestPermission() async {
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _notificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
    }
  }
  
  Future<void> scheduleNotification({
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'your_channel_id',
      'your_channel_name',
      channelDescription: 'your_channel_description',
      importance: Importance.max,
      priority: Priority.high,
    );
    
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    
    // Convert DateTime to TZDateTime for zonedSchedule
    final tz.TZDateTime scheduledTZDate = tz.TZDateTime.from(
      scheduledDate,
      tz.local,
    );
    
    await _notificationsPlugin.zonedSchedule(
      0,
      title,
      body,
      scheduledTZDate,
      platformChannelSpecifics,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: payload,
    );
  }
  
  Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }
  
  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }

  bool get notificationsEnabled => true; // Default value, can be updated based on permission

  Future<void> setNotificationsEnabled(bool enabled) async {
    // Implementation would depend on your notification permission system
    // For now, this is a placeholder that can be extended
  }

  Future<void> sendNewRfqNotification(
      RFQModel rfq, UserModel supplier) async {
    try {
      final notification = NotificationModel(
        id: FirebaseFirestore.instance.collection('notifications').doc().id,
        userId: supplier.uid,
        title: 'New RFQ Received',
        message:
            'You have a new RFQ for ${rfq.productName} from ${rfq.customerName}.',
        type: 'rfq',
        relatedId: rfq.id,
        createdAt: DateTime.now(),
        timestamp: DateTime.now(),
      );

      await _databaseService.createNotification(notification);

      // Also send a local push notification
      await showNotification(
        title: notification.title,
        body: notification.message,
        payload: 'rfq/${rfq.id}',
      );
    } catch (e, s) {
      Logger.logError('Error sending RFQ notification', e, s);
    }
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e, s) {
      Logger.logError('Error marking notification as read', e, s);
    }
  }
}
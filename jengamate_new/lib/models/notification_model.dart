// import 'package:cloud_firestore/cloud_firestore.dart'; // Removed Firebase dependency

class NotificationModel {
  final String uid;
  final String title;
  final String message;
  final String type;
  final String? userId;
  final String? orderId;
  final String? relatedId;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? readAt;
  final Map<String, dynamic>? metadata;

  NotificationModel({
    required this.uid,
    required this.title,
    required this.message,
    required this.type,
    this.userId,
    this.orderId,
    this.relatedId,
    required this.isRead,
    required this.createdAt,
    this.readAt,
    this.metadata,
  });

  factory NotificationModel.fromFirestore(Map<String, dynamic> data, {required String docId}) {
    return NotificationModel(
      uid: docId,
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      type: data['type'] ?? '',
      userId: data['userId'],
      orderId: data['orderId'],
      relatedId: data['relatedId'],
      isRead: data['isRead'] ?? false,
      createdAt: (data['createdAt'] is String) ? DateTime.parse(data['createdAt']) : DateTime.now(),
      readAt: (data['readAt'] is String) ? DateTime.parse(data['readAt']) : null,
      metadata: data['metadata'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'message': message,
      'type': type,
      'userId': userId,
      'orderId': orderId,
      'relatedId': relatedId,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
      'readAt': readAt?.toIso8601String(),
      'metadata': metadata,
    };
  }

  NotificationModel copyWith({
    String? uid,
    String? title,
    String? message,
    String? type,
    String? userId,
    String? orderId,
    String? relatedId,
    bool? isRead,
    DateTime? createdAt,
    DateTime? readAt,
    Map<String, dynamic>? metadata,
  }) {
    return NotificationModel(
      uid: uid ?? this.uid,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      userId: userId ?? this.userId,
      orderId: orderId ?? this.orderId,
      relatedId: relatedId ?? this.relatedId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
      metadata: metadata ?? this.metadata,
    );
  }
}

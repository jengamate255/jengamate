import 'package:cloud_firestore/cloud_firestore.dart';

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

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      uid: doc.id,
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      type: data['type'] ?? '',
      userId: data['userId'],
      orderId: data['orderId'],
      relatedId: data['relatedId'],
      isRead: data['isRead'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      readAt: data['readAt'] != null
          ? (data['readAt'] as Timestamp).toDate()
          : null,
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
      'createdAt': Timestamp.fromDate(createdAt),
      'readAt': readAt != null ? Timestamp.fromDate(readAt!) : null,
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

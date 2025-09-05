import 'package:cloud_firestore/cloud_firestore.dart';

class AuditLogModel {
  final String uid;
  final String actorId;
  final String actorName;
  final String action;
  final String targetType; // 'USER', 'ORDER', 'PRODUCT', 'SYSTEM', etc.
  final String targetId;
  final String targetName;
  final DateTime timestamp;
  final String details;
  final Map<String, dynamic>? metadata;
  final String? ipAddress;
  final String? userAgent;

  AuditLogModel({
    required this.uid,
    required this.actorId,
    required this.actorName,
    required this.action,
    required this.targetType,
    required this.targetId,
    required this.targetName,
    required this.timestamp,
    required this.details,
    this.metadata,
    this.ipAddress,
    this.userAgent,
  });

  factory AuditLogModel.fromMap(Map<String, dynamic> map) {
    return AuditLogModel(
      uid: map['uid'] ?? '',
      actorId: map['actorId'] ?? '',
      actorName: map['actorName'] ?? '',
      action: map['action'] ?? '',
      targetType: map['targetType'] ?? '',
      targetId: map['targetId'] ?? '',
      targetName: map['targetName'] ?? '',
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      details: map['details'] ?? '',
      metadata: map['metadata'] as Map<String, dynamic>?,
      ipAddress: map['ipAddress'],
      userAgent: map['userAgent'],
    );
  }

  factory AuditLogModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AuditLogModel.fromMap(data);
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'actorId': actorId,
      'actorName': actorName,
      'action': action,
      'targetType': targetType,
      'targetId': targetId,
      'targetName': targetName,
      'timestamp': Timestamp.fromDate(timestamp),
      'details': details,
      'metadata': metadata,
      'ipAddress': ipAddress,
      'userAgent': userAgent,
    };
  }

  Map<String, dynamic> toFirestore() {
    return toMap();
  }

  AuditLogModel copyWith({
    String? uid,
    String? actorId,
    String? actorName,
    String? action,
    String? targetType,
    String? targetId,
    String? targetName,
    DateTime? timestamp,
    String? details,
    Map<String, dynamic>? metadata,
    String? ipAddress,
    String? userAgent,
  }) {
    return AuditLogModel(
      uid: uid ?? this.uid,
      actorId: actorId ?? this.actorId,
      actorName: actorName ?? this.actorName,
      action: action ?? this.action,
      targetType: targetType ?? this.targetType,
      targetId: targetId ?? this.targetId,
      targetName: targetName ?? this.targetName,
      timestamp: timestamp ?? this.timestamp,
      details: details ?? this.details,
      metadata: metadata ?? this.metadata,
      ipAddress: ipAddress ?? this.ipAddress,
      userAgent: userAgent ?? this.userAgent,
    );
  }

  // Helper methods for common audit actions
  static AuditLogModel login({
    required String userId,
    required String userName,
    required String email,
    String? ipAddress,
    String? userAgent,
  }) {
    return AuditLogModel(
      uid: '',
      actorId: userId,
      actorName: userName,
      action: 'LOGIN',
      targetType: 'USER',
      targetId: userId,
      targetName: userName,
      timestamp: DateTime.now(),
      details: 'User logged into the system',
      metadata: {'email': email, 'loginMethod': 'email'},
      ipAddress: ipAddress,
      userAgent: userAgent,
    );
  }

  static AuditLogModel logout({
    required String userId,
    required String userName,
  }) {
    return AuditLogModel(
      uid: '',
      actorId: userId,
      actorName: userName,
      action: 'LOGOUT',
      targetType: 'USER',
      targetId: userId,
      targetName: userName,
      timestamp: DateTime.now(),
      details: 'User logged out of the system',
    );
  }

  static AuditLogModel createOrder({
    required String userId,
    required String userName,
    required String orderId,
    required double amount,
  }) {
    return AuditLogModel(
      uid: '',
      actorId: userId,
      actorName: userName,
      action: 'CREATE_ORDER',
      targetType: 'ORDER',
      targetId: orderId,
      targetName: 'Order #$orderId',
      timestamp: DateTime.now(),
      details: 'Created new order',
      metadata: {'amount': amount},
    );
  }

  static AuditLogModel updateOrderStatus({
    required String userId,
    required String userName,
    required String orderId,
    required String oldStatus,
    required String newStatus,
  }) {
    return AuditLogModel(
      uid: '',
      actorId: userId,
      actorName: userName,
      action: 'UPDATE_ORDER_STATUS',
      targetType: 'ORDER',
      targetId: orderId,
      targetName: 'Order #$orderId',
      timestamp: DateTime.now(),
      details: 'Updated order status from $oldStatus to $newStatus',
      metadata: {'oldStatus': oldStatus, 'newStatus': newStatus},
    );
  }

  // Computed properties
  String get formattedTimestamp {
    return '${timestamp.day}/${timestamp.month}/${timestamp.year} ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
  }

  bool get isRecent {
    return DateTime.now().difference(timestamp).inHours < 24;
  }

  String get actionDisplayName {
    switch (action) {
      case 'LOGIN':
        return 'User Login';
      case 'LOGOUT':
        return 'User Logout';
      case 'CREATE_ORDER':
        return 'Order Created';
      case 'UPDATE_ORDER_STATUS':
        return 'Order Status Updated';
      case 'CREATE_USER':
        return 'User Created';
      case 'UPDATE_USER':
        return 'User Updated';
      case 'DELETE_USER':
        return 'User Deleted';
      case 'CREATE_PRODUCT':
        return 'Product Created';
      case 'UPDATE_PRODUCT':
        return 'Product Updated';
      case 'DELETE_PRODUCT':
        return 'Product Deleted';
      default:
        return action.replaceAll('_', ' ').toLowerCase();
    }
  }
}

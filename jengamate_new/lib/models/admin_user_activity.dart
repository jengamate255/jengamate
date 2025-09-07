import 'package:cloud_firestore/cloud_firestore.dart';

class AdminUserActivity {
  final String id;
  final String userId;
  final String action;
  final DateTime timestamp;
  final String ipAddress;
  final String userAgent;
  final Map<String, dynamic>? metadata;

  AdminUserActivity({
    required this.id,
    required this.userId,
    required this.action,
    required this.timestamp,
    required this.ipAddress,
    required this.userAgent,
    this.metadata,
  });

  factory AdminUserActivity.fromMap(Map<String, dynamic> map) {
    return AdminUserActivity(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      action: map['action'] ?? '',
      timestamp: map['timestamp'] is Timestamp
          ? map['timestamp'].toDate()
          : DateTime.now(),
      ipAddress: map['ipAddress'] ?? '',
      userAgent: map['userAgent'] ?? '',
      metadata: map['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'action': action,
      'timestamp': Timestamp.fromDate(timestamp),
      'ipAddress': ipAddress,
      'userAgent': userAgent,
      'metadata': metadata,
    };
  }
}

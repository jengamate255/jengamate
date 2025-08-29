import 'package:cloud_firestore/cloud_firestore.dart';

class AdminUserActivity {
  final String id;
  final String userId;
  final String action;
  final DateTime timestamp;
  final String ipAddress;
  final String userAgent;
  final Map<String, dynamic> metadata;

  AdminUserActivity({
    required this.id,
    required this.userId,
    required this.action,
    required this.timestamp,
    required this.ipAddress,
    required this.userAgent,
    required this.metadata,
  });

  factory AdminUserActivity.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AdminUserActivity(
      id: doc.id,
      userId: data['userId'] ?? '',
      action: data['action'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      ipAddress: data['ipAddress'] ?? '',
      userAgent: data['userAgent'] ?? '',
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'action': action,
      'timestamp': Timestamp.fromDate(timestamp),
      'ipAddress': ipAddress,
      'userAgent': userAgent,
      'metadata': metadata,
    };
  }

  AdminUserActivity copyWith({
    String? id,
    String? userId,
    String? action,
    DateTime? timestamp,
    String? ipAddress,
    String? userAgent,
    Map<String, dynamic>? metadata,
  }) {
    return AdminUserActivity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      action: action ?? this.action,
      timestamp: timestamp ?? this.timestamp,
      ipAddress: ipAddress ?? this.ipAddress,
      userAgent: userAgent ?? this.userAgent,
      metadata: metadata ?? this.metadata,
    );
  }
}
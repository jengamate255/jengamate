import 'package:cloud_firestore/cloud_firestore.dart';

class AuditLogModel {
  final String id;
  final String actorId;
  final String actorName;
  final String targetUserId;
  final String targetUserName;
  final String action;
  final Timestamp timestamp;
  final Map<String, dynamic>? details;

  AuditLogModel({
    required this.id,
    required this.actorId,
    required this.actorName,
    required this.targetUserId,
    required this.targetUserName,
    required this.action,
    required this.timestamp,
    this.details,
  });

  factory AuditLogModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AuditLogModel(
      id: doc.id,
      actorId: data['actorId'] ?? '',
      actorName: data['actorName'] ?? '',
      targetUserId: data['targetUserId'] ?? '',
      targetUserName: data['targetUserName'] ?? '',
      action: data['action'] ?? '',
      timestamp: data['timestamp'] ?? Timestamp.now(),
      details: data['details'] != null ? Map<String, dynamic>.from(data['details']) : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'actorId': actorId,
      'actorName': actorName,
      'targetUserId': targetUserId,
      'targetUserName': targetUserName,
      'action': action,
      'timestamp': timestamp,
      if (details != null) 'details': details,
    };
  }
}

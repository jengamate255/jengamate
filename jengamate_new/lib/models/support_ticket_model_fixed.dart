import 'package:cloud_firestore/cloud_firestore.dart';

class SupportTicketModel {
  final String id;
  final String userId;
  final String subject;
  final String description;
  final String status;
  final String priority;
  final DateTime createdAt;
  final DateTime? resolvedAt;

  SupportTicketModel({
    required this.id,
    required this.userId,
    required this.subject,
    required this.description,
    required this.status,
    required this.priority,
    required this.createdAt,
    this.resolvedAt,
  });

  factory SupportTicketModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SupportTicketModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      subject: data['subject'] ?? '',
      description: data['description'] ?? '',
      status: data['status'] ?? 'open',
      priority: data['priority'] ?? 'medium',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      resolvedAt: data['resolvedAt'] != null
          ? (data['resolvedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'subject': subject,
      'description': description,
      'status': status,
      'priority': priority,
      'createdAt': Timestamp.fromDate(createdAt),
      'resolvedAt': resolvedAt != null ? Timestamp.fromDate(resolvedAt!) : null,
    };
  }
}

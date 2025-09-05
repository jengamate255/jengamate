import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SupportTicket {
  final String uid;
  final String userId;
  final String userName;
  final String userEmail;
  final String subject;
  final String description;
  final String
      category; // 'technical', 'billing', 'account', 'feature_request', 'bug_report', 'general'
  final String priority; // 'low', 'medium', 'high', 'urgent'
  final String
      status; // 'open', 'in_progress', 'waiting_for_user', 'resolved', 'closed'
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? resolvedAt;
  final String? assignedTo;
  final String? assignedToName;
  final String? resolution;
  final List<String> tags;
  final Map<String, dynamic>? metadata;

  SupportTicket({
    required this.uid,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.subject,
    required this.description,
    required this.category,
    required this.priority,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.resolvedAt,
    this.assignedTo,
    this.assignedToName,
    this.resolution,
    required this.tags,
    this.metadata,
  });

  factory SupportTicket.fromMap(Map<String, dynamic> map) {
    return SupportTicket(
      uid: map['uid'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userEmail: map['userEmail'] ?? '',
      subject: map['subject'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? 'general',
      priority: map['priority'] ?? 'medium',
      status: map['status'] ?? 'open',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
      resolvedAt: map['resolvedAt'] != null
          ? (map['resolvedAt'] as Timestamp).toDate()
          : null,
      assignedTo: map['assignedTo'],
      assignedToName: map['assignedToName'],
      resolution: map['resolution'],
      tags: List<String>.from(map['tags'] ?? []),
      metadata: map['metadata'] as Map<String, dynamic>?,
    );
  }

  factory SupportTicket.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SupportTicket.fromMap(data);
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'subject': subject,
      'description': description,
      'category': category,
      'priority': priority,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'resolvedAt': resolvedAt != null ? Timestamp.fromDate(resolvedAt!) : null,
      'assignedTo': assignedTo,
      'assignedToName': assignedToName,
      'resolution': resolution,
      'tags': tags,
      'metadata': metadata,
    };
  }

  Map<String, dynamic> toFirestore() {
    return toMap();
  }

  SupportTicket copyWith({
    String? uid,
    String? userId,
    String? userName,
    String? userEmail,
    String? subject,
    String? description,
    String? category,
    String? priority,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? resolvedAt,
    String? assignedTo,
    String? assignedToName,
    String? resolution,
    List<String>? tags,
    Map<String, dynamic>? metadata,
  }) {
    return SupportTicket(
      uid: uid ?? this.uid,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      subject: subject ?? this.subject,
      description: description ?? this.description,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      assignedTo: assignedTo ?? this.assignedTo,
      assignedToName: assignedToName ?? this.assignedToName,
      resolution: resolution ?? this.resolution,
      tags: tags ?? this.tags,
      metadata: metadata ?? this.metadata,
    );
  }

  // Computed properties
  bool get isOpen => status == 'open';
  bool get isInProgress => status == 'in_progress';
  bool get isResolved => status == 'resolved';
  bool get isClosed => status == 'closed';
  bool get isWaitingForUser => status == 'waiting_for_user';

  bool get isUrgent => priority == 'urgent';
  bool get isHighPriority => priority == 'high';

  String get statusDisplayName {
    switch (status) {
      case 'open':
        return 'Open';
      case 'in_progress':
        return 'In Progress';
      case 'waiting_for_user':
        return 'Waiting for User';
      case 'resolved':
        return 'Resolved';
      case 'closed':
        return 'Closed';
      default:
        return 'Unknown';
    }
  }

  String get priorityDisplayName {
    switch (priority) {
      case 'low':
        return 'Low';
      case 'medium':
        return 'Medium';
      case 'high':
        return 'High';
      case 'urgent':
        return 'Urgent';
      default:
        return 'Unknown';
    }
  }

  String get categoryDisplayName {
    switch (category) {
      case 'technical':
        return 'Technical Issue';
      case 'billing':
        return 'Billing';
      case 'account':
        return 'Account';
      case 'feature_request':
        return 'Feature Request';
      case 'bug_report':
        return 'Bug Report';
      case 'general':
        return 'General';
      default:
        return category.replaceAll('_', ' ').toLowerCase();
    }
  }

  Color get statusColor {
    switch (status) {
      case 'open':
        return Colors.red;
      case 'in_progress':
        return Colors.orange;
      case 'waiting_for_user':
        return Colors.yellow;
      case 'resolved':
        return Colors.green;
      case 'closed':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  Color get priorityColor {
    switch (priority) {
      case 'low':
        return Colors.green;
      case 'medium':
        return Colors.yellow;
      case 'high':
        return Colors.orange;
      case 'urgent':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Helper methods
  Duration get timeToResolution {
    if (resolvedAt == null) return Duration.zero;
    return resolvedAt!.difference(createdAt);
  }

  bool get isOverdue {
    if (isResolved || isClosed) return false;

    final daysOpen = DateTime.now().difference(createdAt).inDays;
    switch (priority) {
      case 'urgent':
        return daysOpen > 1;
      case 'high':
        return daysOpen > 3;
      case 'medium':
        return daysOpen > 7;
      case 'low':
        return daysOpen > 14;
      default:
        return false;
    }
  }

  // Static factory methods for common ticket types
  static SupportTicket createTechnicalIssue({
    required String userId,
    required String userName,
    required String userEmail,
    required String subject,
    required String description,
    String priority = 'medium',
  }) {
    return SupportTicket(
      uid: '',
      userId: userId,
      userName: userName,
      userEmail: userEmail,
      subject: subject,
      description: description,
      category: 'technical',
      priority: priority,
      status: 'open',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      tags: ['technical'],
    );
  }

  static SupportTicket createBillingIssue({
    required String userId,
    required String userName,
    required String userEmail,
    required String subject,
    required String description,
  }) {
    return SupportTicket(
      uid: '',
      userId: userId,
      userName: userName,
      userEmail: userEmail,
      subject: subject,
      description: description,
      category: 'billing',
      priority: 'high',
      status: 'open',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      tags: ['billing'],
    );
  }
}

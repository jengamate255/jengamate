import 'package:cloud_firestore/cloud_firestore.dart';

class ContentReport {
  final String uid;
  final String contentType; // 'product', 'user', 'review', 'inquiry', etc.
  final String contentId;
  final String reportedBy;
  final String reporterName;
  final String reason;
  final String description;
  final String severity; // 'low', 'medium', 'high', 'critical'
  final String status; // 'pending', 'reviewed', 'resolved', 'dismissed'
  final DateTime createdAt;
  final DateTime? reviewedAt;
  final String? reviewedBy;
  final String? resolution;
  final Map<String, dynamic> content;
  final Map<String, dynamic>? metadata;

  ContentReport({
    required this.uid,
    required this.contentType,
    required this.contentId,
    required this.reportedBy,
    required this.reporterName,
    required this.reason,
    required this.description,
    required this.severity,
    required this.status,
    required this.createdAt,
    this.reviewedAt,
    this.reviewedBy,
    this.resolution,
    required this.content,
    this.metadata,
  });

  factory ContentReport.fromMap(Map<String, dynamic> map) {
    return ContentReport(
      uid: map['uid'] ?? '',
      contentType: map['contentType'] ?? 'unknown',
      contentId: map['contentId'] ?? '',
      reportedBy: map['reportedBy'] ?? '',
      reporterName: map['reporterName'] ?? 'Unknown User',
      reason: map['reason'] ?? 'No reason provided',
      description: map['description'] ?? '',
      severity: map['severity'] ?? 'low',
      status: map['status'] ?? 'pending',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      reviewedAt: map['reviewedAt'] != null
          ? (map['reviewedAt'] as Timestamp).toDate()
          : null,
      reviewedBy: map['reviewedBy'],
      resolution: map['resolution'],
      content: map['content'] ?? {},
      metadata: map['metadata'] as Map<String, dynamic>?,
    );
  }

  factory ContentReport.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ContentReport.fromMap(data);
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'contentType': contentType,
      'contentId': contentId,
      'reportedBy': reportedBy,
      'reporterName': reporterName,
      'reason': reason,
      'description': description,
      'severity': severity,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'reviewedAt': reviewedAt != null ? Timestamp.fromDate(reviewedAt!) : null,
      'reviewedBy': reviewedBy,
      'resolution': resolution,
      'content': content,
      'metadata': metadata,
    };
  }

  Map<String, dynamic> toFirestore() {
    return toMap();
  }

  ContentReport copyWith({
    String? uid,
    String? contentType,
    String? contentId,
    String? reportedBy,
    String? reporterName,
    String? reason,
    String? description,
    String? severity,
    String? status,
    DateTime? createdAt,
    DateTime? reviewedAt,
    String? reviewedBy,
    String? resolution,
    Map<String, dynamic>? content,
    Map<String, dynamic>? metadata,
  }) {
    return ContentReport(
      uid: uid ?? this.uid,
      contentType: contentType ?? this.contentType,
      contentId: contentId ?? this.contentId,
      reportedBy: reportedBy ?? this.reportedBy,
      reporterName: reporterName ?? this.reporterName,
      reason: reason ?? this.reason,
      description: description ?? this.description,
      severity: severity ?? this.severity,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      resolution: resolution ?? this.resolution,
      content: content ?? this.content,
      metadata: metadata ?? this.metadata,
    );
  }

  bool get isResolved => status == 'resolved';
  bool get isPending => status == 'pending';
  bool get isDismissed => status == 'dismissed';
  bool get isReviewed => status == 'reviewed';

  String get statusDisplayName {
    switch (status) {
      case 'pending':
        return 'Pending Review';
      case 'reviewed':
        return 'Under Review';
      case 'resolved':
        return 'Resolved';
      case 'dismissed':
        return 'Dismissed';
      default:
        return 'Unknown';
    }
  }

  String get severityDisplayName {
    switch (severity) {
      case 'low':
        return 'Low';
      case 'medium':
        return 'Medium';
      case 'high':
        return 'High';
      case 'critical':
        return 'Critical';
      default:
        return 'Unknown';
    }
  }
}

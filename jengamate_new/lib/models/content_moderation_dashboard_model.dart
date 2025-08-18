class ContentModerationModel {
  final String id;
  final String contentType; // product, review, message, profile, inquiry
  final String contentId;
  final String reportedBy;
  final String reporterName;
  final String reason;
  final String description;
  final String severity; // low, medium, high, critical
  final String status; // pending, approved, rejected
  final DateTime createdAt;
  final DateTime? reviewedAt;
  final String? reviewedBy;
  final String? reviewerName;
  final String? reviewNotes;
  final Map<String, dynamic> content;

  ContentModerationModel({
    required this.id,
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
    this.reviewerName,
    this.reviewNotes,
    required this.content,
  });
}


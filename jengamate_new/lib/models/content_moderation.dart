// import 'package:cloud_firestore/cloud_firestore.dart'; // Removed Firebase dependency

class ContentModeration {
  final String id;
  final String title;
  final String authorId;
  final String authorName;
  final String contentType; // e.g., post, comment, review, profile, project, portfolio
  final String status; // e.g., pending, approved, rejected, flagged
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? moderatedBy;
  final String? rejectionReason;
  final String? flaggedReason;
  final String content;
  final List<String> mediaUrls;
  final List<String> tags;

  ContentModeration({
    required this.id,
    required this.title,
    required this.authorId,
    required this.authorName,
    required this.contentType,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.moderatedBy,
    required this.rejectionReason,
    required this.flaggedReason,
    required this.content,
    required this.mediaUrls,
    required this.tags,
  });

  factory ContentModeration.fromFirestore(Map<String, dynamic> data, {required String docId}) {
    return ContentModeration(
      id: docId,
      title: (data['title'] ?? '').toString(),
      authorId: (data['authorId'] ?? '').toString(),
      authorName: (data['authorName'] ?? '').toString(),
      contentType: (data['contentType'] ?? 'post').toString(),
      status: (data['status'] ?? 'pending').toString(),
      createdAt: (data['createdAt'] is String) ? DateTime.parse(data['createdAt']) : null,
      updatedAt: (data['updatedAt'] is String) ? DateTime.parse(data['updatedAt']) : null,
      moderatedBy: (data['moderatedBy'] as String?),
      rejectionReason: (data['rejectionReason'] as String?),
      flaggedReason: (data['flaggedReason'] as String?),
      content: (data['content'] ?? '').toString(),
      mediaUrls: ((data['mediaUrls'] as List?) ?? [])
          .map((e) => e.toString())
          .toList(),
      tags: ((data['tags'] as List?) ?? [])
          .map((e) => e.toString())
          .toList(),
    );
  }
}

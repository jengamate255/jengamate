import 'package:cloud_firestore/cloud_firestore.dart';

enum ContentType {
  product,
  review,
  profile,
}

class ModerationItem {
  final String id;
  final String contentId;
  final ContentType contentType;
  final String content;
  final String userId;
  final String status;
  final Timestamp createdAt;

  ModerationItem({
    required this.id,
    required this.contentId,
    required this.contentType,
    required this.content,
    required this.userId,
    required this.status,
    required this.createdAt,
  });

  factory ModerationItem.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ModerationItem(
      id: doc.id,
      contentId: data['contentId'],
      contentType: ContentType.values.firstWhere(
          (e) => e.toString() == 'ContentType.${data['contentType']}'),
      content: data['content'],
      userId: data['userId'],
      status: data['status'],
      createdAt: data['createdAt'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'contentId': contentId,
      'contentType': contentType.toString().split('.').last,
      'content': content,
      'userId': userId,
      'status': status,
      'createdAt': createdAt,
    };
  }
}
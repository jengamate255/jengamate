import 'package:cloud_firestore/cloud_firestore.dart';

class InquiryModel {
  final String uid;
  final String userId;
  final String userName;
  final String title;
  final String description;
  final String category;
  final String status;
  final String priority;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? metadata;

  InquiryModel({
    required this.uid,
    required this.userId,
    required this.userName,
    required this.title,
    required this.description,
    required this.category,
    required this.status,
    required this.priority,
    required this.createdAt,
    required this.updatedAt,
    this.metadata,
  });

  factory InquiryModel.fromMap(Map<String, dynamic> map) {
    if (map['userId'] == null || map['title'] == null) {
      throw Exception('Inquiry data is incomplete - missing required userId or title fields');
    }
    return InquiryModel(
      uid: map['uid'] ?? '',
      userId: map['userId'],
      userName: map['userName'] ?? '',
      title: map['title'],
      description: map['description'] ?? '',
      category: map['category'] ?? '',
      status: map['status'] ?? 'pending',
      priority: map['priority'] ?? 'medium',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
      metadata: map['metadata'] as Map<String, dynamic>?,
    );
  }

  factory InquiryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return InquiryModel.fromMap(data);
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'userId': userId,
      'userName': userName,
      'title': title,
      'description': description,
      'category': category,
      'status': status,
      'priority': priority,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'metadata': metadata,
    };
  }

  Map<String, dynamic> toFirestore() {
    return toMap();
  }

  InquiryModel copyWith({
    String? uid,
    String? userId,
    String? userName,
    String? title,
    String? description,
    String? category,
    String? status,
    String? priority,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return InquiryModel(
      uid: uid ?? this.uid,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
    );
  }
}

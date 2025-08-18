import 'package:cloud_firestore/cloud_firestore.dart';

class InquiryModel {
  final String id;
  final String userId;
  final String title;
  final List<Map<String, dynamic>> products;
  final Map<String, dynamic> projectInfo;
  final List<String> attachments;
  final String status;
  final Timestamp createdAt;

  InquiryModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.products,
    required this.projectInfo,
    required this.attachments,
    required this.status,
    required this.createdAt,
  });

  factory InquiryModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return InquiryModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      products: List<Map<String, dynamic>>.from(data['products'] ?? []),
      projectInfo: Map<String, dynamic>.from(data['projectInfo'] ?? {}),
      attachments: List<String>.from(data['attachments'] ?? []),
      status: data['status'] ?? 'Pending',
      createdAt: data['createdAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'products': products,
      'projectInfo': projectInfo,
      'attachments': attachments,
      'status': status,
      'createdAt': createdAt,
    };
  }
}

// Backward compatibility: many screens refer to `Inquiry` type
typedef Inquiry = InquiryModel;

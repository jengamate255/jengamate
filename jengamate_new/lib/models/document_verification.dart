import 'package:cloud_firestore/cloud_firestore.dart';

class DocumentVerification {
  final String id;
  final String userId;
  final String userName;
  final String userEmail;
  final String documentType; // e.g., license, certificate
  final String status; // pending, verified, rejected
  final DateTime submittedAt;
  final DateTime? reviewedAt;
  final String? reviewedBy;
  final String? rejectionReason;
  final String? documentUrl;

  const DocumentVerification({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.documentType,
    required this.status,
    required this.submittedAt,
    this.reviewedAt,
    this.reviewedBy,
    this.rejectionReason,
    this.documentUrl,
  });

  factory DocumentVerification.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return DocumentVerification(
      id: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userEmail: data['userEmail'] ?? '',
      documentType: data['documentType'] ?? 'unknown',
      status: data['status'] ?? 'pending',
      submittedAt: (data['submittedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      reviewedAt: (data['reviewedAt'] as Timestamp?)?.toDate(),
      reviewedBy: data['reviewedBy'],
      rejectionReason: data['rejectionReason'],
      documentUrl: data['documentUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'documentType': documentType,
      'status': status,
      'submittedAt': Timestamp.fromDate(submittedAt),
      if (reviewedAt != null) 'reviewedAt': Timestamp.fromDate(reviewedAt!),
      'reviewedBy': reviewedBy,
      'rejectionReason': rejectionReason,
      'documentUrl': documentUrl,
    };
  }
}

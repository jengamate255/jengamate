// import 'package:cloud_firestore/cloud_firestore.dart'; // Removed Firebase dependency

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

  factory DocumentVerification.fromFirestore(Map<String, dynamic> data, {required String docId}) {
    return DocumentVerification(
      id: docId,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userEmail: data['userEmail'] ?? '',
      documentType: data['documentType'] ?? 'unknown',
      status: data['status'] ?? 'pending',
      submittedAt: (data['submittedAt'] is String) ? DateTime.parse(data['submittedAt']) : _parseOptionalDateTime(data['submittedAt']) ?? DateTime.now(),
      reviewedAt: (data['reviewedAt'] is String) ? DateTime.parse(data['reviewedAt']) : null,
      reviewedBy: data['reviewedBy'],
      rejectionReason: data['rejectionReason'],
      documentUrl: data['documentUrl'],
    );
  }

  factory DocumentVerification.fromMap(Map<String, dynamic> data, String documentId) {
    return DocumentVerification(
      id: documentId,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userEmail: data['userEmail'] ?? '',
      documentType: data['documentType'] ?? 'unknown',
      status: data['status'] ?? 'pending',
      submittedAt: (data['submittedAt'] is String) ? DateTime.parse(data['submittedAt']) : _parseOptionalDateTime(data['submittedAt']) ?? DateTime.now(),
      reviewedAt: (data['reviewedAt'] is String) ? DateTime.parse(data['reviewedAt']) : null,
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
      'submittedAt': submittedAt.toIso8601String(),
      if (reviewedAt != null) 'reviewedAt': reviewedAt!.toIso8601String(),
      'reviewedBy': reviewedBy,
      'rejectionReason': rejectionReason,
      'documentUrl': documentUrl,
    };
  }

  DocumentVerification copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userEmail,
    String? documentType,
    String? status,
    DateTime? submittedAt,
    DateTime? reviewedAt,
    String? reviewedBy,
    String? rejectionReason,
    String? documentUrl,
  }) {
    return DocumentVerification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      documentType: documentType ?? this.documentType,
      status: status ?? this.status,
      submittedAt: submittedAt ?? this.submittedAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      documentUrl: documentUrl ?? this.documentUrl,
    );
  }

  // Helper method to parse timestamps safely from Firestore
  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is String) {
      return DateTime.parse(value);
    }
    if (value is DateTime) {
      return value;
    }
    // Handle Firestore Timestamp
    if (value.runtimeType.toString().contains('Timestamp')) {
      try {
        return value.toDate(); // This is the key fix!
      } catch (e) {
        print('Error converting Timestamp to DateTime: $e');
        return DateTime.now();
      }
    }
    return DateTime.now();
  }

  // Helper method to parse optional timestamps safely from Firestore
  static DateTime? _parseOptionalDateTime(dynamic value) {
    if (value == null) return null;
    if (value is String) {
      return DateTime.tryParse(value);
    }
    if (value is DateTime) {
      return value;
    }
    // Handle Firestore Timestamp
    if (value.runtimeType.toString().contains('Timestamp')) {
      try {
        return value.toDate();
      } catch (e) {
        print('Error converting Timestamp to DateTime: $e');
        return null;
      }
    }
    return null;
  }
}

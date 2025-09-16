// import 'package:cloud_firestore/cloud_firestore.dart'; // Removed Firebase dependency

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
      createdAt: (map['createdAt'] is String) ? DateTime.parse(map['createdAt']) : _parseOptionalDateTime(map['createdAt']) ?? DateTime.now(),
      updatedAt: (map['updatedAt'] is String) ? DateTime.parse(map['updatedAt']) : _parseOptionalDateTime(map['updatedAt']) ?? DateTime.now(),
      metadata: map['metadata'] as Map<String, dynamic>?,
    );
  }

  factory InquiryModel.fromFirestore(Map<String, dynamic> data, {required String docId}) {
    return InquiryModel.fromMap({
      ...data,
      'uid': docId,
    });
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
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
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

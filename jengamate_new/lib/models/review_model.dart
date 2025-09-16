// import 'package:cloud_firestore/cloud_firestore.dart'; // Removed Firebase dependency

class ReviewModel {
  final String id;
  final String productId;
  final String userId;
  final String userName;
  final double rating;
  final String comment;
  final DateTime createdAt;
  final DateTime timestamp;

  ReviewModel({
    required this.id,
    this.productId = '',
    this.userId = '',
    this.userName = '',
    this.rating = 0.0,
    this.comment = '',
    DateTime? createdAt,
    DateTime? timestamp,
  })  : createdAt = createdAt ?? DateTime.now(),
        timestamp = timestamp ?? (createdAt ?? DateTime.now());

  factory ReviewModel.fromMap(Map<String, dynamic> data, String id) {
    return ReviewModel(
      id: id,
      productId: data['productId'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      rating: (data['rating'] ?? 0).toDouble(),
      comment: data['comment'] ?? '',
      createdAt: (data['createdAt'] is String) ? DateTime.parse(data['createdAt']) : _parseOptionalDateTime(data['createdAt']) ?? DateTime.now(),
      timestamp: (data['timestamp'] is String) ? DateTime.parse(data['timestamp']) : _parseOptionalDateTime(data['timestamp']) ?? DateTime.now(),
    );
  }

  factory ReviewModel.fromFirestore(Map<String, dynamic> data, {required String docId}) {
    return ReviewModel.fromMap(data, docId);
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'userId': userId,
      'userName': userName,
      'rating': rating,
      'comment': comment,
      'createdAt': createdAt.toIso8601String(),
      'timestamp': timestamp.toIso8601String(),
    };
  }
  ReviewModel copyWith({
    String? id,
    String? productId,
    String? userId,
    String? userName,
    double? rating,
    String? comment,
    DateTime? createdAt,
    DateTime? timestamp,
  }) {
    return ReviewModel(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
      timestamp: timestamp ?? this.timestamp,
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
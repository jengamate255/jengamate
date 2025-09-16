// import 'package:cloud_firestore/cloud_firestore.dart'; // Removed Firebase dependency

class FAQItem {
  final String uid;
  final String question;
  final String answer;
  final String category;
  final int order;
  final bool isPopular;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;

  FAQItem({
    required this.uid,
    required this.question,
    required this.answer,
    required this.category,
    required this.order,
    this.isPopular = false,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
  });

  factory FAQItem.fromMap(Map<String, dynamic> map) {
    return FAQItem(
      uid: map['uid'] ?? '',
      question: map['question'] ?? '',
      answer: map['answer'] ?? '',
      category: map['category'] ?? 'general',
      order: map['order'] ?? 0,
      isPopular: map['isPopular'] ?? false,
      createdAt: (map['createdAt'] is String) ? DateTime.parse(map['createdAt']) : _parseOptionalDateTime(map['createdAt']) ?? DateTime.now(),
      updatedAt: (map['updatedAt'] is String) ? DateTime.parse(map['updatedAt']) : _parseOptionalDateTime(map['updatedAt']) ?? DateTime.now(),
      createdBy: map['createdBy'],
    );
  }

  factory FAQItem.fromFirestore(Map<String, dynamic> data, {required String docId}) {
    return FAQItem.fromMap({
      ...data,
      'uid': docId,
    });
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'question': question,
      'answer': answer,
      'category': category,
      'order': order,
      'isPopular': isPopular,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'createdBy': createdBy,
    };
  }

  Map<String, dynamic> toFirestore() {
    return toMap();
  }

  FAQItem copyWith({
    String? uid,
    String? question,
    String? answer,
    String? category,
    int? order,
    bool? isPopular,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
  }) {
    return FAQItem(
      uid: uid ?? this.uid,
      question: question ?? this.question,
      answer: answer ?? this.answer,
      category: category ?? this.category,
      order: order ?? this.order,
      isPopular: isPopular ?? this.isPopular,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
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

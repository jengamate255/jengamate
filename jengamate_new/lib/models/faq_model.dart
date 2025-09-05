import 'package:cloud_firestore/cloud_firestore.dart';

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
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
      createdBy: map['createdBy'],
    );
  }

  factory FAQItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FAQItem.fromMap(data);
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'question': question,
      'answer': answer,
      'category': category,
      'order': order,
      'isPopular': isPopular,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
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
}

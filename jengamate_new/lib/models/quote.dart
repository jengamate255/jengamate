import 'package:cloud_firestore/cloud_firestore.dart';

class Quote {
  final String id;
  final String inquiryId;
  final String supplierId;
  final String supplierName;
  final double price;
  final String description;
  final DateTime createdAt;
  final bool isAccepted;

  Quote({
    required this.id,
    required this.inquiryId,
    required this.supplierId,
    required this.supplierName,
    required this.price,
    required this.description,
    required this.createdAt,
    this.isAccepted = false,
  });

  factory Quote.fromMap(Map<String, dynamic> data, String id) {
    return Quote(
      id: id,
      inquiryId: data['inquiryId'] ?? '',
      supplierId: data['supplierId'] ?? '',
      supplierName: data['supplierName'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      description: data['description'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      isAccepted: data['isAccepted'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'inquiryId': inquiryId,
      'supplierId': supplierId,
      'supplierName': supplierName,
      'price': price,
      'description': description,
      'createdAt': Timestamp.fromDate(createdAt),
      'isAccepted': isAccepted,
    };
  }

  factory Quote.fromFirestore(DocumentSnapshot doc) {
    return Quote.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }
}
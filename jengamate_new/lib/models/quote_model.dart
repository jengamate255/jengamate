import 'package:cloud_firestore/cloud_firestore.dart';

class QuoteModel {
  final String id;
  final String rfqId;
  final String? supplierId;
  final double price;
  final String notes;
  final DateTime? deliveryDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  QuoteModel({
    required this.id,
    required this.rfqId,
    this.supplierId,
    required this.price,
    this.notes = '',
    this.deliveryDate,
    required this.createdAt,
    required this.updatedAt,
  });

  // Add uid getter for compatibility
  String get uid => id;

  factory QuoteModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return QuoteModel(
      id: doc.id,
      rfqId: data['rfqId'] ?? '',
      supplierId: data['supplierId'] as String?,
      price: (data['price'] ?? 0.0).toDouble(),
      notes: data['notes'] ?? '',
      deliveryDate: (data['deliveryDate'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  factory QuoteModel.fromMap(Map<String, dynamic> map, String id) {
    return QuoteModel(
      id: id,
      rfqId: map['rfqId'] ?? '',
      supplierId: map['supplierId'] as String?,
      price: (map['price'] ?? 0.0).toDouble(),
      notes: map['notes'] ?? '',
      deliveryDate: map['deliveryDate']?.toDate(),
      createdAt: map['createdAt']?.toDate() ?? DateTime.now(),
      updatedAt: map['updatedAt']?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'rfqId': rfqId,
      'supplierId': supplierId,
      'price': price,
      'notes': notes,
      'deliveryDate':
          deliveryDate != null ? Timestamp.fromDate(deliveryDate!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}

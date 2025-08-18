import 'package:cloud_firestore/cloud_firestore.dart';

class Quotation {
  final String id;
  final String inquiryId;
  final String engineerId;
  final String supplierId;
  final List<Map<String, dynamic>> products;
  final double totalAmount;
  final double commissionAmount; // Hidden from engineer
  final String status; // e.g., 'pending_review', 'confirmed', 'rejected', 'modification_requested'
  final DateTime createdAt;
  final DateTime updatedAt;

  Quotation({
    required this.id,
    required this.inquiryId,
    required this.engineerId,
    required this.supplierId,
    required this.products,
    required this.totalAmount,
    required this.commissionAmount,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Quotation.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Quotation(
      id: doc.id,
      inquiryId: data['inquiryId'] ?? '',
      engineerId: data['engineerId'] ?? '',
      supplierId: data['supplierId'] ?? '',
      products: List<Map<String, dynamic>>.from(data['products'] ?? []),
      totalAmount: (data['totalAmount'] ?? 0.0).toDouble(),
      commissionAmount: (data['commissionAmount'] ?? 0.0).toDouble(),
      status: data['status'] ?? 'pending_review',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'inquiryId': inquiryId,
      'engineerId': engineerId,
      'supplierId': supplierId,
      'products': products,
      'totalAmount': totalAmount,
      'commissionAmount': commissionAmount,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
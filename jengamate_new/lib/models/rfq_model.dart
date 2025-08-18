import 'package:cloud_firestore/cloud_firestore.dart';

class RFQModel {
  final String id;
  final String userId;
  final String productId;
  final String productName;
  final String customerName;
  final String customerEmail;
  final String customerPhone;
  final String deliveryAddress;
  final String additionalNotes;
  final String status;
  final int quantity;
  final List<String> attachments;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? inquiryId;
  final String? preferredPaymentTerms;
  final String? vendorId;

  RFQModel({
    required this.id,
    this.userId = '',
    required this.productId,
    required this.productName,
    this.inquiryId,
    this.preferredPaymentTerms,
    this.vendorId,
    required this.customerName,
    required this.customerEmail,
    required this.customerPhone,
    required this.deliveryAddress,
    this.additionalNotes = '',
    this.status = 'Pending',
    required this.quantity,
    this.attachments = const [],
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory RFQModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return RFQModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      productId: data['productId'] ?? '',
      productName: data['productName'] ?? '',
      customerName: data['customerName'] ?? '',
      customerEmail: data['customerEmail'] ?? '',
      customerPhone: data['customerPhone'] ?? '',
      deliveryAddress: data['deliveryAddress'] ?? '',
      additionalNotes: data['additionalNotes'] ?? '',
      status: data['status'] ?? 'Pending',
      quantity: data['quantity'] ?? 0,
      attachments: List<String>.from(data['attachments'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      inquiryId: data['inquiryId'],
      preferredPaymentTerms: data['preferredPaymentTerms'],
      vendorId: data['vendorId'],
    );
  }

  factory RFQModel.fromMap(Map<String, dynamic> data, String id) {
    return RFQModel(
      id: id,
      userId: data['userId'] ?? '',
      productId: data['productId'] ?? '',
      productName: data['productName'] ?? '',
      customerName: data['customerName'] ?? '',
      customerEmail: data['customerEmail'] ?? '',
      customerPhone: data['customerPhone'] ?? '',
      deliveryAddress: data['deliveryAddress'] ?? '',
      additionalNotes: data['additionalNotes'] ?? '',
      status: data['status'] ?? 'Pending',
      quantity: data['quantity'] ?? 0,
      attachments: List<String>.from(data['attachments'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      inquiryId: data['inquiryId'],
      preferredPaymentTerms: data['preferredPaymentTerms'],
      vendorId: data['vendorId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'productId': productId,
      'productName': productName,
      'customerName': customerName,
      'customerEmail': customerEmail,
      'customerPhone': customerPhone,
      'deliveryAddress': deliveryAddress,
      'additionalNotes': additionalNotes,
      'status': status,
      'quantity': quantity,
      'attachments': attachments,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'inquiryId': inquiryId,
      'preferredPaymentTerms': preferredPaymentTerms,
      'vendorId': vendorId,
    };
  }
}

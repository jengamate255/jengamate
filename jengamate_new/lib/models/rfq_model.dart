// import 'package:cloud_firestore/cloud_firestore.dart'; // Removed Firebase dependency

class RFQModel {
  final String id;
  final String? userId;
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
    this.userId,
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

  factory RFQModel.fromFirestore(Map<String, dynamic> data, {required String docId}) {
    return RFQModel(
      id: docId,
      userId: data['userId'],
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
      createdAt: (data['createdAt'] is String) ? DateTime.parse(data['createdAt']) : _parseOptionalDateTime(data['createdAt']) ?? DateTime.now(),
      updatedAt: (data['updatedAt'] is String) ? DateTime.parse(data['updatedAt']) : _parseOptionalDateTime(data['updatedAt']) ?? DateTime.now(),
      inquiryId: data['inquiryId'],
      preferredPaymentTerms: data['preferredPaymentTerms'],
      vendorId: data['vendorId'],
    );
  }

  factory RFQModel.fromMap(Map<String, dynamic> data, String id) {
    return RFQModel(
      id: id,
      userId: data['userId'],
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
      createdAt: (data['createdAt'] is String) ? DateTime.parse(data['createdAt']) : _parseOptionalDateTime(data['createdAt']) ?? DateTime.now(),
      updatedAt: (data['updatedAt'] is String) ? DateTime.parse(data['updatedAt']) : _parseOptionalDateTime(data['updatedAt']) ?? DateTime.now(),
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
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'inquiryId': inquiryId,
      'preferredPaymentTerms': preferredPaymentTerms,
      'vendorId': vendorId,
    };
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

// import 'package:cloud_firestore/cloud_firestore.dart'; // Removed Firebase dependency

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

  factory Quotation.fromFirestore(Map<String, dynamic> data, {required String docId}) {
    return Quotation(
      id: docId,
      inquiryId: data['inquiryId'] ?? '',
      engineerId: data['engineerId'] ?? '',
      supplierId: data['supplierId'] ?? '',
      products: List<Map<String, dynamic>>.from(data['products'] ?? []),
      totalAmount: (data['totalAmount'] ?? 0.0).toDouble(),
      commissionAmount: (data['commissionAmount'] ?? 0.0).toDouble(),
      status: data['status'] ?? 'pending_review',
      createdAt: (data['createdAt'] is String) ? DateTime.parse(data['createdAt']) : _parseOptionalDateTime(data['createdAt']) ?? DateTime.now(),
      updatedAt: (data['updatedAt'] is String) ? DateTime.parse(data['updatedAt']) : _parseOptionalDateTime(data['updatedAt']) ?? DateTime.now(),
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
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
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
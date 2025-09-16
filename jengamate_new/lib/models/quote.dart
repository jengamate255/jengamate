// import 'package:cloud_firestore/cloud_firestore.dart'; // Removed Firebase dependency

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
      createdAt: (data['createdAt'] is String) ? DateTime.parse(data['createdAt']) : _parseOptionalDateTime(data['createdAt']) ?? DateTime.now(),
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
      'createdAt': createdAt.toIso8601String(),
      'isAccepted': isAccepted,
    };
  }

  factory Quote.fromFirestore(Map<String, dynamic> data, {required String docId}) {
    return Quote.fromMap(data, docId);
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
// import 'package:cloud_firestore/cloud_firestore.dart'; // Removed Firebase dependency

class ReferralModel {
  final String id;
  final String referrerId;
  final String referredUserId;
  final double bonusAmount;
  final DateTime createdAt;
  final String status; // e.g., 'pending', 'completed', 'cancelled'

  ReferralModel({
    required this.id,
    required this.referrerId,
    required this.referredUserId,
    required this.bonusAmount,
    DateTime? createdAt,
    this.status = 'pending',
  }) : createdAt = createdAt ?? DateTime.now();

  factory ReferralModel.fromFirestore(Map<String, dynamic> data, {required String docId}) {
    return ReferralModel(
      id: docId,
      referrerId: data['referrerId'] ?? '',
      referredUserId: data['referredUserId'] ?? '',
      bonusAmount: (data['bonusAmount'] ?? 0.0).toDouble(),
      createdAt: (data['createdAt'] is String) ? DateTime.parse(data['createdAt']) : _parseOptionalDateTime(data['createdAt']) ?? DateTime.now(),
      status: data['status'] ?? 'pending',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'referrerId': referrerId,
      'referredUserId': referredUserId,
      'bonusAmount': bonusAmount,
      'createdAt': createdAt.toIso8601String(),
      'status': status,
    };
  }

  ReferralModel copyWith({
    String? id,
    String? referrerId,
    String? referredUserId,
    double? bonusAmount,
    DateTime? createdAt,
    String? status,
  }) {
    return ReferralModel(
      id: id ?? this.id,
      referrerId: referrerId ?? this.referrerId,
      referredUserId: referredUserId ?? this.referredUserId,
      bonusAmount: bonusAmount ?? this.bonusAmount,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
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
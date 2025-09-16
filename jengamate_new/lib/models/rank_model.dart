// import 'package:cloud_firestore/cloud_firestore.dart'; // Removed Firebase dependency

class RankModel {
  final String id;
  final String name;
  final int minimumReferrals;
  final double commissionRate;
  final DateTime createdAt;
  final DateTime updatedAt;

  RankModel({
    required this.id,
    required this.name,
    required this.minimumReferrals,
    required this.commissionRate,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory RankModel.fromFirestore(Map<String, dynamic> data, {required String docId}) {
    return RankModel(
      id: docId,
      name: data['name'] ?? '',
      minimumReferrals: data['minimumReferrals'] ?? 0,
      commissionRate: (data['commissionRate'] ?? 0.0).toDouble(),
      createdAt: (data['createdAt'] is String) ? DateTime.parse(data['createdAt']) : _parseOptionalDateTime(data['createdAt']) ?? DateTime.now(),
      updatedAt: (data['updatedAt'] is String) ? DateTime.parse(data['updatedAt']) : _parseOptionalDateTime(data['updatedAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'minimumReferrals': minimumReferrals,
      'commissionRate': commissionRate,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  RankModel copyWith({
    String? id,
    String? name,
    int? minimumReferrals,
    double? commissionRate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RankModel(
      id: id ?? this.id,
      name: name ?? this.name,
      minimumReferrals: minimumReferrals ?? this.minimumReferrals,
      commissionRate: commissionRate ?? this.commissionRate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
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
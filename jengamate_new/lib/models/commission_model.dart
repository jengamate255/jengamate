// import 'package:cloud_firestore/cloud_firestore.dart'; // Removed Firebase dependency

class CommissionModel {
  final String id;
  final String userId;
  final double total;
  final double direct;
  final double referral;
  final double active;
  final DateTime updatedAt;
  final String status;
  final double minPayoutThreshold;
  final DateTime createdAt;
  final Map<String, dynamic>? metadata;

  CommissionModel({
    required this.id,
    required this.userId,
    required this.total,
    required this.direct,
    required this.referral,
    required this.active,
    required this.updatedAt,
    this.status = 'Pending',
    this.minPayoutThreshold = 0.0,
    DateTime? createdAt,
    this.metadata,
  }) : createdAt = createdAt ?? DateTime.now();

  // Add uid getter for compatibility
  String get uid => id;

  factory CommissionModel.fromFirestore(Map<String, dynamic> data, String docId) {
    return CommissionModel.fromMap(data, docId);
  }

  factory CommissionModel.fromMap(Map<String, dynamic> data, String id) {
    return CommissionModel(
      id: id,
      userId: data['userId'] ?? '',
      total: (data['total'] ?? 0).toDouble(),
      direct: (data['direct'] ?? 0).toDouble(),
      referral: (data['referral'] ?? 0).toDouble(),
      active: (data['active'] ?? 0).toDouble(),
      updatedAt: (data['updatedAt'] is String) ? DateTime.parse(data['updatedAt']) : _parseOptionalDateTime(data['updatedAt']) ?? DateTime.now(),
      status: data['status'] ?? 'Pending',
      minPayoutThreshold: (data['minPayoutThreshold'] ?? 0).toDouble(),
      createdAt: (data['createdAt'] is String) ? DateTime.parse(data['createdAt']) : _parseOptionalDateTime(data['createdAt']) ?? DateTime.now(),
      metadata: data['metadata'] is Map
          ? Map<String, dynamic>.from(data['metadata'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'total': total,
      'direct': direct,
      'referral': referral,
      'active': active,
      'updatedAt': updatedAt.toIso8601String(),
      'status': status,
      'minPayoutThreshold': minPayoutThreshold,
      'createdAt': createdAt.toIso8601String(),
      'metadata': metadata,
    };
  }

  CommissionModel copyWith({
    String? id,
    String? userId,
    double? total,
    double? direct,
    double? referral,
    double? active,
    DateTime? updatedAt,
    String? status,
    double? minPayoutThreshold,
    DateTime? createdAt,
    Map<String, dynamic>? metadata,
  }) {
    return CommissionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      total: total ?? this.total,
      direct: direct ?? this.direct,
      referral: referral ?? this.referral,
      active: active ?? this.active,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
      minPayoutThreshold: minPayoutThreshold ?? this.minPayoutThreshold,
      createdAt: createdAt ?? this.createdAt,
      metadata: metadata ?? this.metadata,
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

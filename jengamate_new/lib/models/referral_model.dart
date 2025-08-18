import 'package:cloud_firestore/cloud_firestore.dart';

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

  factory ReferralModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ReferralModel(
      id: doc.id,
      referrerId: data['referrerId'] ?? '',
      referredUserId: data['referredUserId'] ?? '',
      bonusAmount: (data['bonusAmount'] ?? 0.0).toDouble(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: data['status'] ?? 'pending',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'referrerId': referrerId,
      'referredUserId': referredUserId,
      'bonusAmount': bonusAmount,
      'createdAt': Timestamp.fromDate(createdAt),
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
}
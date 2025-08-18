import 'package:cloud_firestore/cloud_firestore.dart';

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

  factory RankModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return RankModel(
      id: doc.id,
      name: data['name'] ?? '',
      minimumReferrals: data['minimumReferrals'] ?? 0,
      commissionRate: data['commissionRate'] ?? 0.0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'minimumReferrals': minimumReferrals,
      'commissionRate': commissionRate,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
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
}
import 'package:cloud_firestore/cloud_firestore.dart';

class CommissionModel {
  final double total;
  final double direct;
  final double referral;
  final double active;

  CommissionModel({
    required this.total,
    required this.direct,
    required this.referral,
    required this.active,
  });

  factory CommissionModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return CommissionModel(
      total: (data['total'] ?? 0).toDouble(),
      direct: (data['direct'] ?? 0).toDouble(),
      referral: (data['referral'] ?? 0).toDouble(),
      active: (data['active'] ?? 0).toDouble(),
    );
  }
}

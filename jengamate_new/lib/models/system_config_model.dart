import 'package:cloud_firestore/cloud_firestore.dart';

class SystemConfig {
  final double commissionRate;
  final double minimumWithdrawal;
  final int maxRfqsPerDay;
  final bool requireApprovalForNewUsers;

  SystemConfig({
    required this.commissionRate,
    required this.minimumWithdrawal,
    required this.maxRfqsPerDay,
    required this.requireApprovalForNewUsers,
  });

  factory SystemConfig.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return SystemConfig(
      commissionRate: data['commissionRate'] ?? 0.0,
      minimumWithdrawal: data['minimumWithdrawal'] ?? 0.0,
      maxRfqsPerDay: data['maxRfqsPerDay'] ?? 0,
      requireApprovalForNewUsers: data['requireApprovalForNewUsers'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'commissionRate': commissionRate,
      'minimumWithdrawal': minimumWithdrawal,
      'maxRfqsPerDay': maxRfqsPerDay,
      'requireApprovalForNewUsers': requireApprovalForNewUsers,
    };
  }
}
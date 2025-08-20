import 'package:cloud_firestore/cloud_firestore.dart';

class SystemConfig {
  final double commissionRate;
  final double minimumWithdrawal;
  final int maxRfqsPerDay;
  final bool requireApprovalForNewUsers;
  final double? referralBonus;
  final double? maxOrderValue;
  final String? maintenanceMessage;
  final bool? enableReferralProgram;
  final bool? enableNotifications;
  final bool? enableAutoApproval;
  final bool? maintenanceMode;

  SystemConfig({
    required this.commissionRate,
    required this.minimumWithdrawal,
    required this.maxRfqsPerDay,
    required this.requireApprovalForNewUsers,
    this.referralBonus,
    this.maxOrderValue,
    this.maintenanceMessage,
    this.enableReferralProgram,
    this.enableNotifications,
    this.enableAutoApproval,
    this.maintenanceMode,
  });

  factory SystemConfig.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return SystemConfig(
      commissionRate: data['commissionRate'] ?? 0.0,
      minimumWithdrawal: data['minimumWithdrawal'] ?? 0.0,
      maxRfqsPerDay: data['maxRfqsPerDay'] ?? 0,
      requireApprovalForNewUsers: data['requireApprovalForNewUsers'] ?? false,
      referralBonus: data['referralBonus']?.toDouble(),
      maxOrderValue: data['maxOrderValue']?.toDouble(),
      maintenanceMessage: data['maintenanceMessage'],
      enableReferralProgram: data['enableReferralProgram'],
      enableNotifications: data['enableNotifications'],
      enableAutoApproval: data['enableAutoApproval'],
      maintenanceMode: data['maintenanceMode'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'commissionRate': commissionRate,
      'minimumWithdrawal': minimumWithdrawal,
      'maxRfqsPerDay': maxRfqsPerDay,
      'requireApprovalForNewUsers': requireApprovalForNewUsers,
      'referralBonus': referralBonus,
      'maxOrderValue': maxOrderValue,
      'maintenanceMessage': maintenanceMessage,
      'enableReferralProgram': enableReferralProgram,
      'enableNotifications': enableNotifications,
      'enableAutoApproval': enableAutoApproval,
      'maintenanceMode': maintenanceMode,
    };
  }
}
import 'package:cloud_firestore/cloud_firestore.dart';

class SystemConfig {
  final String uid;
  final double commissionRate;
  final double minimumWithdrawal;
  final int maxRfqsPerDay;
  final bool requireApprovalForNewUsers;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? metadata;

  SystemConfig({
    required this.uid,
    required this.commissionRate,
    required this.minimumWithdrawal,
    required this.maxRfqsPerDay,
    required this.requireApprovalForNewUsers,
    required this.createdAt,
    required this.updatedAt,
    this.metadata,
  });

  factory SystemConfig.fromMap(Map<String, dynamic> map) {
    return SystemConfig(
      uid: map['uid'] ?? '',
      commissionRate: (map['commissionRate'] ?? 0.0).toDouble(),
      minimumWithdrawal: (map['minimumWithdrawal'] ?? 0.0).toDouble(),
      maxRfqsPerDay: (map['maxRfqsPerDay'] ?? 10).toInt(),
      requireApprovalForNewUsers: map['requireApprovalForNewUsers'] ?? false,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
      metadata: map['metadata'] as Map<String, dynamic>?,
    );
  }

  factory SystemConfig.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SystemConfig.fromMap(data);
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'commissionRate': commissionRate,
      'minimumWithdrawal': minimumWithdrawal,
      'maxRfqsPerDay': maxRfqsPerDay,
      'requireApprovalForNewUsers': requireApprovalForNewUsers,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'metadata': metadata,
    };
  }

  Map<String, dynamic> toFirestore() {
    return toMap();
  }

  SystemConfig copyWith({
    String? uid,
    double? commissionRate,
    double? minimumWithdrawal,
    int? maxRfqsPerDay,
    bool? requireApprovalForNewUsers,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return SystemConfig(
      uid: uid ?? this.uid,
      commissionRate: commissionRate ?? this.commissionRate,
      minimumWithdrawal: minimumWithdrawal ?? this.minimumWithdrawal,
      maxRfqsPerDay: maxRfqsPerDay ?? this.maxRfqsPerDay,
      requireApprovalForNewUsers:
          requireApprovalForNewUsers ?? this.requireApprovalForNewUsers,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
    );
  }
}

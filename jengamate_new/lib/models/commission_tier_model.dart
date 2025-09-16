// import 'package:cloud_firestore/cloud_firestore.dart'; // Removed Firebase dependency

class CommissionTier {
  final String uid;
  final String name;
  final String description;
  final double minSalesVolume;
  final double maxSalesVolume;
  final double commissionRate;
  final double bonusRate;
  final int minReferrals;
  final int maxReferrals;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? metadata;

  CommissionTier({
    required this.uid,
    required this.name,
    required this.description,
    required this.minSalesVolume,
    required this.maxSalesVolume,
    required this.commissionRate,
    required this.bonusRate,
    required this.minReferrals,
    required this.maxReferrals,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.metadata,
  });

  factory CommissionTier.fromMap(Map<String, dynamic> map) {
    return CommissionTier(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      minSalesVolume: (map['minSalesVolume'] ?? 0.0).toDouble(),
      maxSalesVolume: (map['maxSalesVolume'] ?? 0.0).toDouble(),
      commissionRate: (map['commissionRate'] ?? 0.0).toDouble(),
      bonusRate: (map['bonusRate'] ?? 0.0).toDouble(),
      minReferrals: (map['minReferrals'] ?? 0).toInt(),
      maxReferrals: (map['maxReferrals'] ?? 0).toInt(),
      isActive: map['isActive'] ?? true,
      createdAt: (map['createdAt'] is String) ? DateTime.parse(map['createdAt']) : _parseOptionalDateTime(map['createdAt']) ?? DateTime.now(),
      updatedAt: (map['updatedAt'] is String) ? DateTime.parse(map['updatedAt']) : _parseOptionalDateTime(map['updatedAt']) ?? DateTime.now(),
      metadata: map['metadata'] as Map<String, dynamic>?,
    );
  }

  factory CommissionTier.fromFirestore(Map<String, dynamic> data, {required String docId}) {
    return CommissionTier.fromMap({
      ...data,
      'uid': docId,
    });
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'description': description,
      'minSalesVolume': minSalesVolume,
      'maxSalesVolume': maxSalesVolume,
      'commissionRate': commissionRate,
      'bonusRate': bonusRate,
      'minReferrals': minReferrals,
      'maxReferrals': maxReferrals,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'metadata': metadata,
    };
  }

  Map<String, dynamic> toFirestore() {
    return toMap();
  }

  CommissionTier copyWith({
    String? uid,
    String? name,
    String? description,
    double? minSalesVolume,
    double? maxSalesVolume,
    double? commissionRate,
    double? bonusRate,
    int? minReferrals,
    int? maxReferrals,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return CommissionTier(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      description: description ?? this.description,
      minSalesVolume: minSalesVolume ?? this.minSalesVolume,
      maxSalesVolume: maxSalesVolume ?? this.maxSalesVolume,
      commissionRate: commissionRate ?? this.commissionRate,
      bonusRate: bonusRate ?? this.bonusRate,
      minReferrals: minReferrals ?? this.minReferrals,
      maxReferrals: maxReferrals ?? this.maxReferrals,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  // Computed properties
  double get totalCommissionRate => commissionRate + bonusRate;

  // Backward-compatibility accessors for legacy UI
  String get id => uid;
  int get level {
    // Derive a level from name if possible, otherwise 1
    final lower = name.toLowerCase();
    if (lower.contains('platinum')) return 4;
    if (lower.contains('gold')) return 3;
    if (lower.contains('silver')) return 2;
    if (lower.contains('bronze')) return 1;
    return 1;
  }

  double get minSales => minSalesVolume;
  double get maxSales => maxSalesVolume == 0 ? double.infinity : maxSalesVolume;
  double get bonusAmount => 0;
  List<String> get requirements => const [];
  List<String> get benefits => const [];
  String get color => '#CD7F32';

  String get salesVolumeRange {
    if (maxSalesVolume == 0) {
      return 'TZS ${minSalesVolume.toStringAsFixed(0)}+';
    }
    return 'TZS ${minSalesVolume.toStringAsFixed(0)} - ${maxSalesVolume.toStringAsFixed(0)}';
  }

  String get referralRange {
    if (maxReferrals == 0) {
      return '${minReferrals}+';
    }
    return '$minReferrals - $maxReferrals';
  }

  String get commissionRateDisplay =>
      '${(commissionRate * 100).toStringAsFixed(1)}%';

  String get bonusRateDisplay => '${(bonusRate * 100).toStringAsFixed(1)}%';

  String get totalRateDisplay =>
      '${(totalCommissionRate * 100).toStringAsFixed(1)}%';

  // Helper methods
  bool isEligibleForUser(double salesVolume, int referralCount) {
    final salesEligible = salesVolume >= minSalesVolume &&
        (maxSalesVolume == 0 || salesVolume <= maxSalesVolume);
    final referralsEligible = referralCount >= minReferrals &&
        (maxReferrals == 0 || referralCount <= maxReferrals);
    return salesEligible && referralsEligible && isActive;
  }

  double calculateCommission(double salesAmount, int referralCount) {
    if (!isActive) return 0.0;

    double commission = 0.0;

    // Base commission on sales volume
    if (salesAmount >= minSalesVolume) {
      commission += salesAmount * commissionRate;
    }

    // Bonus commission on referrals
    if (referralCount >= minReferrals) {
      final eligibleReferrals = maxReferrals == 0
          ? referralCount
          : referralCount.clamp(0, maxReferrals);
      commission +=
          salesAmount * bonusRate * (eligibleReferrals / minReferrals);
    }

    return commission;
  }

  // Static factory methods for common tiers
  static CommissionTier bronze() {
    return CommissionTier(
      uid: '',
      name: 'Bronze',
      description: 'Entry level commission tier',
      minSalesVolume: 0,
      maxSalesVolume: 1000000, // TZS 1M
      commissionRate: 0.05, // 5%
      bonusRate: 0.01, // 1%
      minReferrals: 0,
      maxReferrals: 5,
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  static CommissionTier silver() {
    return CommissionTier(
      uid: '',
      name: 'Silver',
      description: 'Mid level commission tier',
      minSalesVolume: 1000000, // TZS 1M
      maxSalesVolume: 5000000, // TZS 5M
      commissionRate: 0.08, // 8%
      bonusRate: 0.02, // 2%
      minReferrals: 5,
      maxReferrals: 15,
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  static CommissionTier gold() {
    return CommissionTier(
      uid: '',
      name: 'Gold',
      description: 'High level commission tier',
      minSalesVolume: 5000000, // TZS 5M
      maxSalesVolume: 15000000, // TZS 15M
      commissionRate: 0.12, // 12%
      bonusRate: 0.03, // 3%
      minReferrals: 15,
      maxReferrals: 30,
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  static CommissionTier platinum() {
    return CommissionTier(
      uid: '',
      name: 'Platinum',
      description: 'Top level commission tier',
      minSalesVolume: 15000000, // TZS 15M
      maxSalesVolume: 0, // Unlimited
      commissionRate: 0.15, // 15%
      bonusRate: 0.05, // 5%
      minReferrals: 30,
      maxReferrals: 0, // Unlimited
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
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

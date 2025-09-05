import 'package:cloud_firestore/cloud_firestore.dart';

class CommissionTier {
  final String id;
  final String name;
  final int level;
  final double minSales;
  final double maxSales;
  final double commissionRate;
  final double bonusAmount;
  final List<String> requirements;
  final List<String> benefits;
  final String color;
  final bool isActive;

  CommissionTier({
    required this.id,
    required this.name,
    required this.level,
    required this.minSales,
    required this.maxSales,
    required this.commissionRate,
    required this.bonusAmount,
    required this.requirements,
    required this.benefits,
    required this.color,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'level': level,
      'minSales': minSales,
      'maxSales': maxSales,
      'commissionRate': commissionRate,
      'bonusAmount': bonusAmount,
      'requirements': requirements,
      'benefits': benefits,
      'color': color,
      'isActive': isActive,
    };
  }

  factory CommissionTier.fromMap(Map<String, dynamic> map) {
    return CommissionTier(
      id: map['id'] ?? '',
      name: map['name'] ?? 'Unknown Tier',
      level: map['level'] ?? 1,
      minSales: (map['minSales'] ?? 0.0).toDouble(),
      maxSales: (map['maxSales'] ?? 0.0).toDouble(),
      commissionRate: (map['commissionRate'] ?? 0.0).toDouble(),
      bonusAmount: (map['bonusAmount'] ?? 0.0).toDouble(),
      requirements: List<String>.from(map['requirements'] ?? []),
      benefits: List<String>.from(map['benefits'] ?? []),
      color: map['color'] ?? '#CD7F32',
      isActive: map['isActive'] ?? true,
    );
  }

  factory CommissionTier.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CommissionTier.fromMap(data);
  }

  CommissionTier copyWith({
    String? id,
    String? name,
    int? level,
    double? minSales,
    double? maxSales,
    double? commissionRate,
    double? bonusAmount,
    List<String>? requirements,
    List<String>? benefits,
    String? color,
    bool? isActive,
  }) {
    return CommissionTier(
      id: id ?? this.id,
      name: name ?? this.name,
      level: level ?? this.level,
      minSales: minSales ?? this.minSales,
      maxSales: maxSales ?? this.maxSales,
      commissionRate: commissionRate ?? this.commissionRate,
      bonusAmount: bonusAmount ?? this.bonusAmount,
      requirements: requirements ?? this.requirements,
      benefits: benefits ?? this.benefits,
      color: color ?? this.color,
      isActive: isActive ?? this.isActive,
    );
  }
}

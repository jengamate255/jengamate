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
  bool isActive;

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

  factory CommissionTier.fromJson(Map<String, dynamic> json) {
    return CommissionTier(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      level: json['level'] ?? 0,
      minSales: (json['minSales'] ?? 0).toDouble(),
      maxSales: (json['maxSales'] ?? 0).toDouble(),
      commissionRate: (json['commissionRate'] ?? 0).toDouble(),
      bonusAmount: (json['bonusAmount'] ?? 0).toDouble(),
      requirements: List<String>.from(json['requirements'] ?? []),
      benefits: List<String>.from(json['benefits'] ?? []),
      color: json['color'] ?? '#000000',
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
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

  @override
  String toString() {
    return 'CommissionTier(id: $id, name: $name, level: $level, commissionRate: $commissionRate)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CommissionTier && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

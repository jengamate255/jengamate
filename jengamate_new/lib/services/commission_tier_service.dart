import 'package:jengamate/models/user_model.dart';
import 'package:jengamate/models/order_model.dart';
import 'package:jengamate/models/quotation_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CommissionTier {
  final String? id; // Firestore document id
  final String role; // 'engineer' | 'supplier'
  final String name; // bronze/silver/gold/platinum
  final String badgeText;
  final String badgeColor; // name key for UI tint
  final int minProducts;
  final double minTotalValue;
  final double ratePercent; // e.g., 0.02 => 2%
  final int order; // sort order

  CommissionTier({
    this.id,
    required this.role,
    required this.name,
    required this.badgeText,
    required this.badgeColor,
    required this.minProducts,
    required this.minTotalValue,
    required this.ratePercent,
    this.order = 0,
  });

  Map<String, dynamic> toMap() => {
        'role': role,
        'name': name,
        'badgeText': badgeText,
        'badgeColor': badgeColor,
        'minProducts': minProducts,
        'minTotalValue': minTotalValue,
        'ratePercent': ratePercent,
        'order': order,
        'updatedAt': FieldValue.serverTimestamp(),
      };

  factory CommissionTier.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return CommissionTier(
      id: doc.id,
      role: (d['role'] ?? 'engineer') as String,
      name: (d['name'] ?? '') as String,
      badgeText: (d['badgeText'] ?? '') as String,
      badgeColor: (d['badgeColor'] ?? 'bronze') as String,
      minProducts: (d['minProducts'] ?? 0) as int,
      minTotalValue: (d['minTotalValue'] ?? 0.0).toDouble(),
      ratePercent: (d['ratePercent'] ?? 0.02).toDouble(),
      order: (d['order'] ?? 0) as int,
    );
  }
}

class CommissionTierService {
  static const String _collection = 'commission_tiers';
  final FirebaseFirestore _db;

  CommissionTierService({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  // Commission tiers for engineers based on products bought
  static final List<CommissionTier> engineerTiers = [
    CommissionTier(
      role: 'engineer',
      name: 'bronze',
      badgeText: 'Bronze Engineer',
      badgeColor: 'bronze',
      minProducts: 5,
      minTotalValue: 1000.0,
      ratePercent: 0.02,
      order: 1,
    ),
    CommissionTier(
      role: 'engineer',
      name: 'silver',
      badgeText: 'Silver Engineer',
      badgeColor: 'silver',
      minProducts: 15,
      minTotalValue: 5000.0,
      ratePercent: 0.04,
      order: 2,
    ),
    CommissionTier(
      role: 'engineer',
      name: 'gold',
      badgeText: 'Gold Engineer',
      badgeColor: 'gold',
      minProducts: 30,
      minTotalValue: 15000.0,
      ratePercent: 0.06,
      order: 3,
    ),
    CommissionTier(
      role: 'engineer',
      name: 'platinum',
      badgeText: 'Platinum Engineer',
      badgeColor: 'platinum',
      minProducts: 50,
      minTotalValue: 30000.0,
      ratePercent: 0.08,
      order: 4,
    ),
  ];

  // Commission tiers for suppliers based on products sold
  static final List<CommissionTier> supplierTiers = [
    CommissionTier(
      role: 'supplier',
      name: 'bronze',
      badgeText: 'Bronze Supplier',
      badgeColor: 'bronze',
      minProducts: 10,
      minTotalValue: 2000.0,
      ratePercent: 0.015,
      order: 1,
    ),
    CommissionTier(
      role: 'supplier',
      name: 'silver',
      badgeText: 'Silver Supplier',
      badgeColor: 'silver',
      minProducts: 25,
      minTotalValue: 10000.0,
      ratePercent: 0.03,
      order: 2,
    ),
    CommissionTier(
      role: 'supplier',
      name: 'gold',
      badgeText: 'Gold Supplier',
      badgeColor: 'gold',
      minProducts: 50,
      minTotalValue: 30000.0,
      ratePercent: 0.045,
      order: 3,
    ),
    CommissionTier(
      role: 'supplier',
      name: 'platinum',
      badgeText: 'Platinum Supplier',
      badgeColor: 'platinum',
      minProducts: 100,
      minTotalValue: 75000.0,
      ratePercent: 0.06,
      order: 4,
    ),
  ];

  /// Firestore: Stream tiers for a role, ordered by `order` then `minTotalValue`.
  Stream<List<CommissionTier>> streamTiers(String role) {
    return _db
        .collection(_collection)
        .where('role', isEqualTo: role)
        .orderBy('order')
        .orderBy('minTotalValue')
        .snapshots()
        .map((s) => s.docs.map((d) => CommissionTier.fromDoc(d)).toList());
  }

  /// Firestore: Get tiers once for a role
  Future<List<CommissionTier>> getTiers(String role) async {
    final snap = await _db
        .collection(_collection)
        .where('role', isEqualTo: role)
        .orderBy('order')
        .orderBy('minTotalValue')
        .get();
    return snap.docs.map((d) => CommissionTier.fromDoc(d)).toList();
  }

  /// Create a tier
  Future<String> createTier(CommissionTier tier) async {
    final ref = await _db.collection(_collection).add({
      ...tier.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  /// Update a tier
  Future<void> updateTier(CommissionTier tier) async {
    if (tier.id == null) throw ArgumentError('Tier id is required for update');
    await _db.collection(_collection).doc(tier.id).update(tier.toMap());
  }

  /// Delete a tier
  Future<void> deleteTier(String id) async {
    await _db.collection(_collection).doc(id).delete();
  }

  /// Seed default tiers to Firestore if none exist for a role
  Future<void> seedDefaultsIfEmpty() async {
    for (final role in ['engineer', 'supplier']) {
      final existing = await getTiers(role);
      if (existing.isEmpty) {
        final defaults = role == 'engineer' ? engineerTiers : supplierTiers;
        for (final t in defaults) {
          await createTier(t);
        }
      }
    }
  }

  /// Determines the commission tier for an engineer based on products bought
  static CommissionTier? getEngineerTier(UserModel user, List<OrderModel> orders) {
    int totalProducts = orders.length;
    double totalValue = 0.0;
    
    // Calculate total value from orders where user is the buyer
    for (var order in orders) {
      totalValue += order.totalAmount;
    }
    
    // Find the highest tier the user qualifies for
    CommissionTier? currentTier;
    for (var tier in engineerTiers) {
      if (totalProducts >= tier.minProducts && totalValue >= tier.minTotalValue) {
        currentTier = tier;
      }
    }
    
    return currentTier;
  }

  /// Determines the commission tier for a supplier based on products sold
  static CommissionTier? getSupplierTier(UserModel user, List<Quotation> quotations) {
    int totalProducts = 0;
    double totalValue = 0.0;
    
    // Calculate from quotations where user is the supplier
    for (var quotation in quotations) {
      totalProducts += quotation.products.length;
      totalValue += quotation.totalAmount;
    }
    
    // Find the highest tier the user qualifies for
    CommissionTier? currentTier;
    for (var tier in supplierTiers) {
      if (totalProducts >= tier.minProducts && totalValue >= tier.minTotalValue) {
        currentTier = tier;
      }
    }
    
    return currentTier;
  }

  /// Given an amount and role, find the applicable tier by minTotalValue and return its rate.
  double rateForAmount(double amount, String role, List<CommissionTier> tiers) {
    CommissionTier? current;
    for (final t in tiers) {
      if (amount >= t.minTotalValue) current = t;
    }
    return current?.ratePercent ?? 0.0;
  }

  /// Given an amount and role, return the applicable tier by thresholds (or null).
  CommissionTier? findTierForAmount(double amount, String role, List<CommissionTier> tiers) {
    CommissionTier? current;
    for (final t in tiers) {
      if (amount >= t.minTotalValue) current = t;
    }
    return current;
  }
}

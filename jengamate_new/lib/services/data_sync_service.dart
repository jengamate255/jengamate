import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jengamate/services/commission_tier_service.dart';
import 'package:jengamate/services/role_service.dart';
import 'package:jengamate/utils/logger.dart';
import 'package:jengamate/models/category_model.dart';
import 'package:jengamate/models/commission_tier_model.dart';

class DataSyncService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collections
  static const String _commissionTiersCollection = 'commission_tiers';
  static const String _categoriesCollection = 'categories';
  static const String _systemConfigCollection = 'system_config';
  static const String _auditLogsCollection = 'audit_logs';

  /// Syncs all dummy data with the database
  Future<void> syncAllData() async {
    try {
      Logger.log('Starting data synchronization...');
      
      await Future.wait([
        _syncCommissionTiers(),
        _syncCategories(),
        _syncSystemConfig(),
        _syncRolePermissions(),
      ]);
      
      Logger.log('Data synchronization completed successfully');
    } catch (e, s) {
      Logger.logError('Error during data synchronization', e, s);
      rethrow;
    }
  }

  /// Syncs commission tiers data
  Future<void> _syncCommissionTiers() async {
    try {
      Logger.log('Syncing commission tiers...');
      
      // Sync engineer tiers
      for (final tier in CommissionTierService.engineerTiers) {
        await _syncCommissionTier(tier);
      }
      
      // Sync supplier tiers
      for (final tier in CommissionTierService.supplierTiers) {
        await _syncCommissionTier(tier);
      }
      
      Logger.log('Commission tiers synced successfully');
    } catch (e, s) {
      Logger.logError('Error syncing commission tiers', e, s);
      rethrow;
    }
  }

  /// Syncs a single commission tier
  Future<void> _syncCommissionTier(CommissionTier tier) async {
    try {
      final docRef = _firestore
          .collection(_commissionTiersCollection)
          .doc('${tier.role}_${tier.name}');
      
      final existingDoc = await docRef.get();
      
      if (!existingDoc.exists) {
        // Create new tier
        await docRef.set(tier.toMap());
        Logger.log('Created commission tier: ${tier.role}_${tier.name}');
      } else {
        // Update existing tier if data has changed
        final existingData = existingDoc.data();
        if (existingData != null && _hasTierChanged(tier, existingData)) {
          await docRef.update(tier.toMap());
          Logger.log('Updated commission tier: ${tier.role}_${tier.name}');
        }
      }
    } catch (e, s) {
      Logger.logError('Error syncing commission tier ${tier.role}_${tier.name}', e, s);
      rethrow;
    }
  }

  /// Checks if a commission tier has changed
  bool _hasTierChanged(CommissionTier tier, Map<String, dynamic> existingData) {
    return existingData['minProducts'] != tier.minProducts ||
           existingData['minTotalValue'] != tier.minTotalValue ||
           existingData['ratePercent'] != tier.ratePercent ||
           existingData['badgeText'] != tier.badgeText ||
           existingData['badgeColor'] != tier.badgeColor ||
           existingData['order'] != tier.order;
  }

  /// Syncs categories data
  Future<void> _syncCategories() async {
    try {
      Logger.log('Syncing categories...');
      
      final defaultCategories = [
        {'name': 'Electronics', 'description': 'Electronic devices and components'},
        {'name': 'Construction', 'description': 'Construction materials and tools'},
        {'name': 'Automotive', 'description': 'Automotive parts and accessories'},
        {'name': 'Industrial', 'description': 'Industrial equipment and supplies'},
        {'name': 'Agriculture', 'description': 'Agricultural tools and equipment'},
        {'name': 'Healthcare', 'description': 'Medical and healthcare equipment'},
        {'name': 'Textiles', 'description': 'Textile materials and products'},
        {'name': 'Food & Beverage', 'description': 'Food processing and beverage equipment'},
      ];

      for (final categoryData in defaultCategories) {
        await _syncCategory(categoryData);
      }
      
      Logger.log('Categories synced successfully');
    } catch (e, s) {
      Logger.logError('Error syncing categories', e, s);
      rethrow;
    }
  }

  /// Syncs a single category
  Future<void> _syncCategory(Map<String, dynamic> categoryData) async {
    try {
      final categoryName = categoryData['name'] as String;
      final docRef = _firestore
          .collection(_categoriesCollection)
          .doc(categoryName.toLowerCase().replaceAll(' ', '_'));
      
      final existingDoc = await docRef.get();
      
      if (!existingDoc.exists) {
        await docRef.set({
          'name': categoryData['name'],
          'description': categoryData['description'],
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'isActive': true,
        });
        Logger.log('Created category: ${categoryData['name']}');
      }
    } catch (e, s) {
      Logger.logError('Error syncing category ${categoryData['name']}', e, s);
      rethrow;
    }
  }

  /// Syncs system configuration data
  Future<void> _syncSystemConfig() async {
    try {
      Logger.log('Syncing system configuration...');
      
      final systemConfig = {
        'order_statuses': [
          'PENDING',
          'PROCESSING', 
          'SHIPPED',
          'DELIVERED',
          'CANCELLED',
          'REFUNDED'
        ],
        'inquiry_statuses': [
          'PENDING',
          'IN_PROGRESS',
          'RESOLVED',
          'CLOSED'
        ],
        'priorities': [
          'LOW',
          'MEDIUM',
          'HIGH',
          'URGENT'
        ],
        'content_types': [
          'product',
          'review',
          'message',
          'profile',
          'inquiry'
        ],
        'severity_levels': [
          'low',
          'medium',
          'high',
          'critical'
        ],
        'rfq_statuses': [
          'Pending',
          'Approved',
          'Rejected',
          'Processing',
          'Completed'
        ],
        'rfq_types': [
          'Standard',
          'Bid',
          'Catalog',
          'Marketplace'
        ],
        'last_sync': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection(_systemConfigCollection)
          .doc('app_config')
          .set(systemConfig, SetOptions(merge: true));
      
      Logger.log('System configuration synced successfully');
    } catch (e, s) {
      Logger.logError('Error syncing system configuration', e, s);
      rethrow;
    }
  }

  /// Syncs role permissions data
  Future<void> _syncRolePermissions() async {
    try {
      Logger.log('Syncing role permissions...');
      
      final rolePermissions = RoleService.rolePermissions;
      
      for (final entry in rolePermissions.entries) {
        final roleName = entry.key;
        final permissions = entry.value;
        
        await _firestore
            .collection('role_permissions')
            .doc(roleName)
            .set(permissions, SetOptions(merge: true));
      }
      
      Logger.log('Role permissions synced successfully');
    } catch (e, s) {
      Logger.logError('Error syncing role permissions', e, s);
      rethrow;
    }
  }

  /// Gets system configuration from database
  Future<Map<String, dynamic>?> getSystemConfig() async {
    try {
      final doc = await _firestore
          .collection(_systemConfigCollection)
          .doc('app_config')
          .get();
      
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e, s) {
      Logger.logError('Error getting system config', e, s);
      return null;
    }
  }

  /// Gets categories from database
  Future<List<CategoryModel>> getCategories() async {
    try {
      final snapshot = await _firestore
          .collection(_categoriesCollection)
          .where('isActive', isEqualTo: true)
          .orderBy('name')
          .get();
      
      return snapshot.docs
          .map((doc) => CategoryModel.fromFirestore(doc))
          .toList();
    } catch (e, s) {
      Logger.logError('Error getting categories', e, s);
      return [];
    }
  }

  /// Gets commission tiers from database
  Future<List<CommissionTier>> getCommissionTiers(String role) async {
    try {
      final snapshot = await _firestore
          .collection(_commissionTiersCollection)
          .where('role', isEqualTo: role)
          .orderBy('order')
          .orderBy('minTotalValue')
          .get();
      
      return snapshot.docs
          .map((doc) => CommissionTier.fromDoc(doc))
          .toList();
    } catch (e, s) {
      Logger.logError('Error getting commission tiers for role $role', e, s);
      return [];
    }
  }

  /// Checks if data sync is needed
  Future<bool> isSyncNeeded() async {
    try {
      final configDoc = await _firestore
          .collection(_systemConfigCollection)
          .doc('app_config')
          .get();
      
      if (!configDoc.exists) return true;
      
      final lastSync = configDoc.data()?['last_sync'] as Timestamp?;
      if (lastSync == null) return true;
      
      // Check if sync is older than 24 hours
      final now = Timestamp.now();
      final difference = now.toDate().difference(lastSync.toDate());
      return difference.inHours > 24;
    } catch (e, s) {
      Logger.logError('Error checking sync status', e, s);
      return true;
    }
  }

  /// Forces a data sync regardless of last sync time
  Future<void> forceSync() async {
    try {
      Logger.log('Forcing data synchronization...');
      await syncAllData();
      Logger.log('Force sync completed successfully');
    } catch (e, s) {
      Logger.logError('Error during force sync', e, s);
      rethrow;
    }
  }
}
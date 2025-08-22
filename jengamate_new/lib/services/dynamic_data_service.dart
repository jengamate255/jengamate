import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jengamate/services/data_sync_service.dart';
import 'package:jengamate/utils/logger.dart';

class DynamicDataService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DataSyncService _dataSyncService = DataSyncService();

  // Cache for frequently accessed data
  Map<String, dynamic> _systemConfigCache = {};
  List<String> _orderStatusesCache = [];
  List<String> _inquiryStatusesCache = [];
  List<String> _prioritiesCache = [];
  List<String> _contentTypesCache = [];
  List<String> _severityLevelsCache = [];
  List<String> _rfqStatusesCache = [];
  List<String> _rfqTypesCache = [];

  bool _isInitialized = false;

  /// Initializes the service and loads initial data
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      Logger.log('Initializing DynamicDataService...');
      
      // Check if sync is needed and perform if necessary
      if (await _dataSyncService.isSyncNeeded()) {
        await _dataSyncService.syncAllData();
      }
      
      // Load system configuration
      await _loadSystemConfig();
      
      _isInitialized = true;
      Logger.log('DynamicDataService initialized successfully');
    } catch (e, s) {
      Logger.logError('Error initializing DynamicDataService', e, s);
      rethrow;
    }
  }

  /// Loads system configuration from database
  Future<void> _loadSystemConfig() async {
    try {
      final config = await _dataSyncService.getSystemConfig();
      if (config != null) {
        _systemConfigCache = config;
        _orderStatusesCache = List<String>.from(config['order_statuses'] ?? []);
        _inquiryStatusesCache = List<String>.from(config['inquiry_statuses'] ?? []);
        _prioritiesCache = List<String>.from(config['priorities'] ?? []);
        _contentTypesCache = List<String>.from(config['content_types'] ?? []);
        _severityLevelsCache = List<String>.from(config['severity_levels'] ?? []);
        _rfqStatusesCache = List<String>.from(config['rfq_statuses'] ?? []);
        _rfqTypesCache = List<String>.from(config['rfq_types'] ?? []);
      }
    } catch (e, s) {
      Logger.logError('Error loading system config', e, s);
    }
  }

  /// Refreshes the data cache
  Future<void> refreshData() async {
    try {
      await _loadSystemConfig();
      Logger.log('Data cache refreshed successfully');
    } catch (e, s) {
      Logger.logError('Error refreshing data cache', e, s);
    }
  }

  /// Gets order statuses from database
  List<String> getOrderStatuses() {
    if (!_isInitialized) {
      // Fallback to default values if not initialized
      return ['all', 'PENDING', 'PROCESSING', 'SHIPPED', 'DELIVERED', 'CANCELLED', 'REFUNDED'];
    }
    return ['all', ..._orderStatusesCache];
  }

  /// Gets inquiry statuses from database
  List<String> getInquiryStatuses() {
    if (!_isInitialized) {
      return ['all', 'PENDING', 'IN_PROGRESS', 'RESOLVED', 'CLOSED'];
    }
    return ['all', ..._inquiryStatusesCache];
  }

  /// Gets priorities from database
  List<String> getPriorities() {
    if (!_isInitialized) {
      return ['all', 'LOW', 'MEDIUM', 'HIGH', 'URGENT'];
    }
    return ['all', ..._prioritiesCache];
  }

  /// Gets content types from database
  List<String> getContentTypes() {
    if (!_isInitialized) {
      return ['all', 'product', 'review', 'message', 'profile', 'inquiry'];
    }
    return ['all', ..._contentTypesCache];
  }

  /// Gets severity levels from database
  List<String> getSeverityLevels() {
    if (!_isInitialized) {
      return ['all', 'low', 'medium', 'high', 'critical'];
    }
    return ['all', ..._severityLevelsCache];
  }

  /// Gets RFQ statuses from database
  List<String> getRfqStatuses() {
    if (!_isInitialized) {
      return ['All', 'Pending', 'Approved', 'Rejected', 'Processing', 'Completed'];
    }
    return ['All', ..._rfqStatusesCache];
  }

  /// Gets RFQ types from database
  List<String> getRfqTypes() {
    if (!_isInitialized) {
      return ['All', 'Standard', 'Bid', 'Catalog', 'Marketplace'];
    }
    return ['All', ..._rfqTypesCache];
  }

  /// Gets categories from database
  Future<List<Map<String, dynamic>>> getCategories() async {
    try {
      final categories = await _dataSyncService.getCategories();
      return categories.map((cat) => {
        'id': cat.id,
        'name': cat.name,
        'description': cat.description,
        'isActive': cat.isActive,
      }).toList();
    } catch (e, s) {
      Logger.logError('Error getting categories', e, s);
      return [];
    }
  }

  /// Gets commission tiers for a specific role from database
  Future<List<Map<String, dynamic>>> getCommissionTiers(String role) async {
    try {
      final tiers = await _dataSyncService.getCommissionTiers(role);
      return tiers.map((tier) => tier.toMap()).toList();
    } catch (e, s) {
      Logger.logError('Error getting commission tiers for role $role', e, s);
      return [];
    }
  }

  /// Gets role permissions from database
  Future<Map<String, dynamic>?> getRolePermissions(String role) async {
    try {
      final doc = await _firestore
          .collection('role_permissions')
          .doc(role)
          .get();
      
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e, s) {
      Logger.logError('Error getting role permissions for role $role', e, s);
      return null;
    }
  }

  /// Gets all available roles from database
  Future<List<String>> getAvailableRoles() async {
    try {
      final snapshot = await _firestore
          .collection('role_permissions')
          .get();
      
      return snapshot.docs.map((doc) => doc.id).toList();
    } catch (e, s) {
      Logger.logError('Error getting available roles', e, s);
      return ['user', 'admin', 'supplier', 'engineer'];
    }
  }

  /// Gets system configuration as a map
  Map<String, dynamic> getSystemConfig() {
    return Map.from(_systemConfigCache);
  }

  /// Checks if a specific status is valid
  bool isValidOrderStatus(String status) {
    return _orderStatusesCache.contains(status);
  }

  bool isValidInquiryStatus(String status) {
    return _inquiryStatusesCache.contains(status);
  }

  bool isValidPriority(String priority) {
    return _prioritiesCache.contains(priority);
  }

  bool isValidContentType(String contentType) {
    return _contentTypesCache.contains(contentType);
  }

  bool isValidSeverityLevel(String severity) {
    return _severityLevelsCache.contains(severity);
  }

  bool isValidRfqStatus(String status) {
    return _rfqStatusesCache.contains(status);
  }

  bool isValidRfqType(String type) {
    return _rfqTypesCache.contains(type);
  }

  /// Gets the next valid status in a workflow
  String? getNextStatus(String currentStatus, String type) {
    try {
      List<String> statuses;
      switch (type.toLowerCase()) {
        case 'order':
          statuses = _orderStatusesCache;
          break;
        case 'inquiry':
          statuses = _inquiryStatusesCache;
          break;
        case 'rfq':
          statuses = _rfqStatusesCache;
          break;
        default:
          return null;
      }

      final currentIndex = statuses.indexOf(currentStatus);
      if (currentIndex >= 0 && currentIndex < statuses.length - 1) {
        return statuses[currentIndex + 1];
      }
      return null;
    } catch (e, s) {
      Logger.logError('Error getting next status', e, s);
      return null;
    }
  }

  /// Gets the previous valid status in a workflow
  String? getPreviousStatus(String currentStatus, String type) {
    try {
      List<String> statuses;
      switch (type.toLowerCase()) {
        case 'order':
          statuses = _orderStatusesCache;
          break;
        case 'inquiry':
          statuses = _inquiryStatusesCache;
          break;
        case 'rfq':
          statuses = _rfqStatusesCache;
          break;
        default:
          return null;
      }

      final currentIndex = statuses.indexOf(currentStatus);
      if (currentIndex > 0) {
        return statuses[currentIndex - 1];
      }
      return null;
    } catch (e, s) {
      Logger.logError('Error getting previous status', e, s);
      return null;
    }
  }

  /// Forces a data refresh and sync
  Future<void> forceRefresh() async {
    try {
      await _dataSyncService.forceSync();
      await refreshData();
      Logger.log('Force refresh completed successfully');
    } catch (e, s) {
      Logger.logError('Error during force refresh', e, s);
      rethrow;
    }
  }
}
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jengamate/models/inquiry.dart';
import 'package:jengamate/models/user_model.dart';
import 'package:jengamate/models/audit_log_model.dart';
import 'package:jengamate/services/database_service.dart';
import 'package:jengamate/models/admin_user_activity.dart';
import 'package:jengamate/services/offline_cache_service.dart';
import 'package:jengamate/models/order_model.dart';
import 'package:jengamate/models/commission_model.dart';
import 'package:jengamate/models/content_report_model.dart';
import 'package:jengamate/models/rfq_model.dart';
import 'package:jengamate/models/document_verification.dart';
import 'package:jengamate/models/enums/order_enums.dart';
import 'package:jengamate/models/enums/user_role.dart';
import 'package:jengamate/utils/logger.dart'; // Added
import 'package:jengamate/services/document_verification_service.dart'; // Added

class AdminAnalyticsService {
  final DatabaseService _dbService = DatabaseService();
  final OfflineCacheService _cacheService = OfflineCacheService();
  final DocumentVerificationService _documentVerificationService = DocumentVerificationService(); // Added

  // System Health - basic status check
  Stream<Map<String, dynamic>> getSystemHealth() {
    return Stream.periodic(const Duration(seconds: 30), (int count) {
      // Simulate system health check
      return {
        'status': 'healthy',
        'lastUpdated': DateTime.now(),
        'databaseStatus': 'healthy',
        'databaseResponseTime': '50ms',
        'authStatus': 'healthy',
        'authResponseTime': '30ms',
        'storageStatus': 'healthy',
        'storageUsage': '2.5GB',
        'apiStatus': 'healthy',
        'apiResponseTime': '45ms',
      };
    });
  }

  // Dashboard Stats - key metrics
  Stream<Map<String, dynamic>> getDashboardStats() async* {
    final now = DateTime.now();
    final cacheKey = 'dashboard_stats_${now.year}-${now.month}-${now.day}';
    Map<String, dynamic>? cachedStats = _cacheService.getData(cacheKey);

    if (cachedStats != null) {
      yield cachedStats;
      Logger.log('Dashboard stats loaded from cache.');
    }

    await for (final _ in Stream.periodic(const Duration(seconds: 5))) {
      try {
        final totalUsers = await _dbService.streamTotalUsersCount().first;
        final totalOrders = await _dbService.streamTotalOrdersCount().first;
        final pendingDocuments = (await _dbService
                .streamAllInquiries()
                .first)
            .where((inquiry) => inquiry.status == 'pending')
            .length; // Placeholder: use DocumentVerificationService for real count
        final activeRFQs = (await _dbService.streamAllRFQs().first)
            .where((rfq) => rfq.status == 'active' || rfq.status == 'open')
            .length; // Placeholder: use RFQService if available
        final flaggedContent = (await _dbService.getContentReports())
            .where((report) => report.status == 'pending')
            .length; // Placeholder: use ContentModerationService

        final stats = {
          'totalUsers': totalUsers,
          'totalOrders': totalOrders,
          'pendingDocuments': pendingDocuments,
          'activeRFQs': activeRFQs,
          'flaggedContent': flaggedContent,
        };

        _cacheService.saveData(cacheKey, stats);
        yield stats;
        Logger.log('Dashboard stats fetched from network and cached.');
      } catch (e) {
        Logger.logError('Error fetching dashboard stats', e);
        yield cachedStats ?? {}; // Yield cached data or empty map on error
      }
    }
  }

  // Revenue Report - detailed breakdown
  Stream<Map<String, dynamic>> getRevenueReport({int days = 30}) async* {
    final cacheKey = 'revenue_report_$days';
    Map<String, dynamic>? cachedReport = _cacheService.getData(cacheKey);

    if (cachedReport != null) {
      yield cachedReport;
      Logger.log('Revenue report loaded from cache.');
    }

    await for (final _ in Stream.periodic(const Duration(minutes: 5))) { // Update every 5 minutes
      try {
        final cutoff = DateTime.now().subtract(Duration(days: days));
        final orders = await _dbService.getOrders(null).first;
        final relevantOrders = orders.where((order) => order.createdAt.isAfter(cutoff)).toList();

        double totalRevenue = 0;
        Map<String, double> revenueByDay = {};
        Map<String, double> revenueByProduct = {};

        for (var order in relevantOrders) {
          if (order.status == OrderStatus.completed) {
            totalRevenue += order.totalAmount;

            // Revenue by day
            final dayKey = DateTime(order.createdAt.year, order.createdAt.month, order.createdAt.day).toIso8601String().split('T').first;
            revenueByDay[dayKey] = (revenueByDay[dayKey] ?? 0) + order.totalAmount;

            // Revenue by product
            for (var item in order.items) {
              revenueByProduct[item.productId] = (revenueByProduct[item.productId] ?? 0) + item.totalPrice;
            }
          }
        }

        final report = {
          'totalRevenue': totalRevenue,
          'revenueByDay': revenueByDay,
          'revenueByProduct': revenueByProduct,
          'reportGeneratedAt': DateTime.now().toIso8601String(),
        };

        _cacheService.saveData(cacheKey, report);
        yield report;
        Logger.log('Revenue report fetched from network and cached.');
      } catch (e) {
        Logger.logError('Error fetching revenue report', e);
        yield cachedReport ?? {}; // Yield cached data or empty map on error
      }
    }
  }

  // Recent Activity - combined activity stream
  Stream<List<Map<String, dynamic>>> getRecentActivity({int limit = 10}) {
    return Stream.periodic(const Duration(seconds: 10), (int count) {
      // Simulate recent activity from various sources
      final now = DateTime.now();
      final activities = [
        {
          'type': 'user_registered',
          'description': 'New user John Doe registered',
          'timestamp': now,
        },
        {
          'type': 'document_uploaded',
          'description': 'Document uploaded by Jane Smith',
          'timestamp': now.subtract(const Duration(minutes: 5)),
        },
        {
          'type': 'rfq_created',
          'description': 'New RFQ for steel beams created',
          'timestamp': now.subtract(const Duration(minutes: 15)),
        },
        {
          'type': 'content_flagged',
          'description': 'Content flagged for review',
          'timestamp': now.subtract(const Duration(hours: 1)),
        },
        {
          'type': 'login',
          'description': 'Admin login from IP 192.168.1.100',
          'timestamp': now.subtract(const Duration(hours: 2)),
        },
      ];

      return activities.take(limit).toList();
    });
  }

  // Document Analytics - for DocumentVerificationScreen
  Stream<Map<String, dynamic>> getDocumentAnalytics() {
    return _documentVerificationService.getDocumentAnalytics();
  }

  // User Analytics - for UserManagementScreen
  Stream<Map<String, dynamic>> getUserAnalytics() async* {
    while (true) {
      final cacheKey = 'user_analytics_daily';
      Map<String, dynamic>? cachedAnalytics = _cacheService.getData(cacheKey);

      if (cachedAnalytics != null) {
        yield cachedAnalytics;
        Logger.log('User analytics loaded from cache.');
      } else {
        try {
          final totalUsers = await _dbService.streamTotalUsersCount().first;
          final newUsersToday = await _dbService.streamNewUsersCount(days: 1).first;
          final allUsers = await _dbService.streamAllUsers().first;

          int activeUsers = 0;
          int suspendedUsers = 0;
          int verificationPending = 0;
          int engineersCount = 0;
          int suppliersCount = 0;

          for (var user in allUsers) {
            // Placeholder for active users logic (e.g., last login within 30 days)
            // For now, let's just count users with a specific role.
            if (user.role == UserRole.engineer) {
              engineersCount++;
            } else if (user.role == UserRole.supplier) {
              suppliersCount++;
            }

            // Assuming 'isApproved' can be used for suspension logic and identityVerificationSubmitted for pending
            if (!user.isApproved) {
              suspendedUsers++;
            }
            if (user.identityVerificationSubmitted && !user.identityVerificationApproved) {
              verificationPending++;
            }
          }

          final analytics = {
            'totalUsers': totalUsers,
            'activeUsers': activeUsers, // Needs proper implementation
            'newUsersToday': newUsersToday,
            'suspendedUsers': suspendedUsers,
            'verificationPending': verificationPending,
            'engineersCount': engineersCount,
            'suppliersCount': suppliersCount,
          };

          _cacheService.saveData(cacheKey, analytics);
          yield analytics;
          Logger.log('User analytics fetched from network and cached.');
        } catch (e) {
          Logger.logError('Error fetching user analytics', e);
          yield {};
        }
      }

      await Future.delayed(const Duration(seconds: 30));
    }
  }

  // Content Analytics - for ContentModerationScreen
  Stream<Map<String, dynamic>> getContentAnalytics() async* {
    while (true) {
      final cacheKey = 'content_analytics_daily';
      Map<String, dynamic>? cachedAnalytics = _cacheService.getData(cacheKey);

      if (cachedAnalytics != null) {
        yield cachedAnalytics;
        Logger.log('Content analytics loaded from cache.');
      } else {
        try {
          final allContentReports = await _dbService.getContentReports();
          final totalContent = allContentReports.length;
          final flaggedContent = allContentReports.where((report) => report.status == 'pending').length;
          final reportedContent = allContentReports.where((report) => report.status == 'reported').length;
          final underReview = allContentReports.where((report) => report.status == 'under_review').length;

          // Placeholders for autoModerated and manualReviews
          final autoModerated = 0;
          final manualReviews = 0;

          final analytics = {
            'totalContent': totalContent,
            'flaggedContent': flaggedContent,
            'reportedContent': reportedContent,
            'underReview': underReview,
            'autoModerated': autoModerated,
            'manualReviews': manualReviews,
          };

          _cacheService.saveData(cacheKey, analytics);
          yield analytics;
          Logger.log('Content analytics fetched from network and cached.');
        } catch (e) {
          Logger.logError('Error fetching content analytics', e);
          yield {};
        }
      }

      await Future.delayed(const Duration(seconds: 30));
    }
  }

  // Product Performance Report
  Stream<Map<String, dynamic>> getProductPerformanceReport({int days = 30}) async* {
    final cacheKey = 'product_performance_report_$days';
    Map<String, dynamic>? cachedReport = _cacheService.getData(cacheKey);

    if (cachedReport != null) {
      yield cachedReport;
      Logger.log('Product performance report loaded from cache.');
    }

    await for (final _ in Stream.periodic(const Duration(minutes: 5))) { // Update every 5 minutes
      try {
        final cutoff = DateTime.now().subtract(Duration(days: days));
        final products = await _dbService.getAllProducts(); // Assuming getAllProducts fetches all products
        final orders = await _dbService.getOrders(null).first; // Assuming getOrders gets all orders

        Map<String, int> productViews = {}; // Placeholder for product views, needs separate tracking
        Map<String, double> productRevenue = {};
        Map<String, int> productOrders = {};

        for (var product in products) {
          productRevenue[product.id] = 0.0;
          productOrders[product.id] = 0;
        }

        for (var order in orders) {
          if (order.createdAt.isAfter(cutoff) && order.status == OrderStatus.completed) {
            for (var item in order.items) {
              productRevenue[item.productId] = (productRevenue[item.productId] ?? 0.0) + item.totalPrice;
              productOrders[item.productId] = (productOrders[item.productId] ?? 0) + item.quantity;
            }
          }
        }

        // Combine product data with calculated metrics
        List<Map<String, dynamic>> productPerformance = products.map((product) => {
          'productId': product.id,
          'productName': product.name,
          'category': product.category,
          'totalRevenue': productRevenue[product.id] ?? 0.0,
          'totalOrders': productOrders[product.id] ?? 0,
          'totalViews': productViews[product.id] ?? 0, // Placeholder
        }).toList();

        productPerformance.sort((a, b) => (b['totalRevenue'] as double).compareTo(a['totalRevenue'] as double));

        final report = {
          'productPerformance': productPerformance,
          'reportGeneratedAt': DateTime.now().toIso8601String(),
        };

        _cacheService.saveData(cacheKey, report);
        yield report;
        Logger.log('Product performance report fetched from network and cached.');
      } catch (e) {
        Logger.logError('Error fetching product performance report', e);
        yield cachedReport ?? {};
      }
    }
  }

  // Commission Report
  Stream<Map<String, dynamic>> getCommissionReport({int days = 30}) async* {
    final cacheKey = 'commission_report_$days';
    Map<String, dynamic>? cachedReport = _cacheService.getData(cacheKey);

    if (cachedReport != null) {
      yield cachedReport;
      Logger.log('Commission report loaded from cache.');
    }

    await for (final _ in Stream.periodic(const Duration(minutes: 5))) { // Update every 5 minutes
      try {
        final cutoff = DateTime.now().subtract(Duration(days: days));
        final commissions = await _dbService.streamAllCommissions().first; // Assuming streamAllCommissions fetches all commissions

        double totalCommissionsEarned = 0.0;
        double totalCommissionsPaid = 0.0;
        double totalCommissionsPending = 0.0;
        Map<String, double> commissionsByUser = {};

        for (var commission in commissions) {
          if (commission.createdAt.isAfter(cutoff)) {
            totalCommissionsEarned += commission.total;

            if (commission.status == 'paid') {
              totalCommissionsPaid += commission.total;
            } else if (commission.status == 'pending') {
              totalCommissionsPending += commission.total;
            }
            commissionsByUser[commission.userId] = (commissionsByUser[commission.userId] ?? 0.0) + commission.total;
          }
        }

        final report = {
          'totalCommissionsEarned': totalCommissionsEarned,
          'totalCommissionsPaid': totalCommissionsPaid,
          'totalCommissionsPending': totalCommissionsPending,
          'commissionsByUser': commissionsByUser,
          'reportGeneratedAt': DateTime.now().toIso8601String(),
        };

        _cacheService.saveData(cacheKey, report);
        yield report;
        Logger.log('Commission report fetched from network and cached.');
      } catch (e) {
        Logger.logError('Error fetching commission report', e);
        yield cachedReport ?? {};
      }
    }
  }

  // User Activities - used by multiple screens
  Stream<List<AdminUserActivity>> getUserActivities(
      {String? userId, int limit = 50}) {
    return Stream.periodic(const Duration(seconds: 30), (int count) {
      // Simulate user activity stream
      final now = DateTime.now();
      final activities = List.generate(limit, (index) {
        return AdminUserActivity(
          id: 'activity_${index}',
          userId: userId ?? 'user_${index}',
          action: [
            'login',
            'document_upload',
            'rfq_created',
            'content_posted'
          ][index % 4],
          timestamp: now.subtract(Duration(minutes: index)),
          ipAddress: '192.168.1.${100 + index}',
          userAgent: 'Mozilla/5.0...',
          metadata: {'test_key': 'test_value'}, // Added metadata
        );
      });
      return activities;
    }).map((list) => list.take(limit).toList());
  }

  // Log User Activity - used by multiple screens
  Future<void> logUserActivity({
    required String userId,
    required String action,
    String? description,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final log = AuditLogModel(
        uid: '',
        actorId: userId,
        actorName: 'Admin', // Default actor name for analytics service
        action: action,
        targetType: 'SYSTEM',
        targetId: userId,
        targetName: userId,
        timestamp: DateTime.now(),
        details: description ?? '',
        metadata: metadata ?? {},
      );
      await _dbService.createAuditLog(log);
    } catch (e) {
      print('Failed to log user activity: $e');
    }
  }

  // Export Documents to CSV - for DocumentVerificationScreen
  Future<List<String>> exportDocumentsToCSV() async {
    // Simulate CSV export
    return [
      'Document ID,User ID,Status,Upload Date,File Type',
      'DOC001,user123,pending,2025-09-01,PDF',
      'DOC002,user456,verified,2025-09-02,JPG',
      'DOC003,user789,rejected,2025-09-03,PNG',
    ];
  }

  // Export Users to CSV - for UserManagementScreen
  Future<List<String>> exportUsersToCSV() async {
    // Simulate CSV export
    return [
      'User ID,Name,Email,Role,Status,Created Date',
      'USER001,John Doe,john@example.com,engineer,active,2025-08-01',
      'USER002,Jane Smith,jane@example.com,supplier,verified,2025-08-02',
      'USER003,Bob Johnson,bob@example.com,admin,suspended,2025-08-03',
    ];
  }

  // Export Content to CSV - for ContentModerationScreen
  Future<List<String>> exportContentToCSV() async {
    // Simulate CSV export
    return [
      'Content ID,Type,User ID,Status,Flagged Date,Reason',
      'CONTENT001,post,user123,approved,2025-09-01,spam',
      'CONTENT002,image,user456,under_review,2025-09-02,offensive',
      'CONTENT003,comment,user789,rejected,2025-09-03,duplicate',
    ];
  }

  // Additional analytics methods can be added here
  Stream<int> getTotalRevenue() {
    return _dbService
        .streamTotalSalesAmountTSH()
        .map((amount) => amount.round());
  }

  Future<Map<String, dynamic>> getAdminAnalytics() {
    return _dbService.getAdminAnalytics();
  }
}

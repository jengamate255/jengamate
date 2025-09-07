import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jengamate/models/inquiry.dart';
import 'package:jengamate/models/user_model.dart';
import 'package:jengamate/models/audit_log_model.dart';
import 'package:jengamate/services/database_service.dart';
import 'package:jengamate/models/admin_user_activity.dart';

class AdminAnalyticsService {
  final DatabaseService _dbService = DatabaseService();

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
    // Use existing database service methods
    final usersStream = _dbService.streamTotalUsersCount();
    final ordersStream = _dbService.streamTotalOrdersCount();

    await for (final _ in Stream.periodic(const Duration(seconds: 5))) {
      try {
        final users = await usersStream.first;
        final orders = await ordersStream.first;

        yield {
          'totalUsers': users,
          'totalOrders': orders,
          'pendingDocuments': 12, // Placeholder - implement actual count
          'activeRFQs': 8, // Placeholder - implement actual count
          'flaggedContent': 3, // Placeholder - implement actual count
        };
      } catch (e) {
        yield {
          'totalUsers': 0,
          'totalOrders': 0,
          'pendingDocuments': 0,
          'activeRFQs': 0,
          'flaggedContent': 0,
        };
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
    return Stream.periodic(const Duration(seconds: 30), (int count) {
      return {
        'totalDocuments': 150,
        'pendingVerification': 23,
        'verifiedDocuments': 127,
        'rejectionRate': '8.5%',
        'averageVerificationTime': '2.3 hours',
      };
    });
  }

  // User Analytics - for UserManagementScreen
  Stream<Map<String, dynamic>> getUserAnalytics() {
    return Stream.periodic(const Duration(seconds: 30), (int count) {
      return {
        'totalUsers': 456,
        'activeUsers': 234,
        'newUsersToday': 12,
        'suspendedUsers': 5,
        'verificationPending': 34,
        'engineersCount': 89,
        'suppliersCount': 67,
      };
    });
  }

  // Content Analytics - for ContentModerationScreen
  Stream<Map<String, dynamic>> getContentAnalytics() {
    return Stream.periodic(const Duration(seconds: 30), (int count) {
      return {
        'totalContent': 2456,
        'flaggedContent': 23,
        'reportedContent': 15,
        'underReview': 8,
        'autoModerated': 1234,
        'manualReviews': 89,
      };
    });
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

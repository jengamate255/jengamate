import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:jengamate/models/admin_user_activity.dart';
import 'package:jengamate/models/enhanced_user.dart';

class AdminAnalyticsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // User Activity Tracking
  Future<void> logUserActivity({
    required String userId,
    required String action,
    required String ipAddress,
    required String userAgent,
    Map<String, dynamic> metadata = const {},
  }) async {
    try {
      final activity = AdminUserActivity(
        id: '',
        userId: userId,
        action: action,
        timestamp: DateTime.now(),
        ipAddress: ipAddress,
        userAgent: userAgent,
        metadata: metadata,
      );

      await _firestore
          .collection('user_activities')
          .add(activity.toFirestore());
    } catch (e) {
      print('Error logging user activity: $e');
    }
  }

  // Get user activities with pagination
  Stream<List<AdminUserActivity>> getUserActivities({
    required String userId,
    int limit = 50,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    Query query = _firestore
        .collection('user_activities')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true);

    if (startDate != null) {
      query = query.where('timestamp', isGreaterThanOrEqualTo: startDate);
    }

    if (endDate != null) {
      query = query.where('timestamp', isLessThanOrEqualTo: endDate);
    }

    return query.limit(limit).snapshots().map((snapshot) => snapshot.docs
        .map((doc) => AdminUserActivity.fromFirestore(doc))
        .toList());
  }

  // Get user statistics
  Future<Map<String, dynamic>> getUserStats(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final user = EnhancedUser.fromFirestore(userDoc);

      // Get activity count
      final activityCount = await _firestore
          .collection('user_activities')
          .where('userId', isEqualTo: userId)
          .count()
          .get();

      // Get last login
      final lastLogin = await _firestore
          .collection('user_activities')
          .where('userId', isEqualTo: userId)
          .where('action', isEqualTo: 'login')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      // Get transaction count (if applicable)
      final transactionCount = await _firestore
          .collection('transactions')
          .where('userId', isEqualTo: userId)
          .count()
          .get();

      return {
        'user': user,
        'totalActivities': activityCount.count ?? 0,
        'lastLogin': lastLogin.docs.isNotEmpty
            ? (lastLogin.docs.first.data()['timestamp'] as Timestamp).toDate()
            : null,
        'totalTransactions': transactionCount.count ?? 0,
      };
    } catch (e) {
      print('Error getting user stats: $e');
      return {};
    }
  }

  // Get user analytics for dashboard
  Stream<Map<String, dynamic>> getUserAnalytics({
    DateTime? startDate,
    DateTime? endDate,
  }) {
    Query userQuery = _firestore.collection('users');

    return userQuery.snapshots().asyncMap((snapshot) async {
      final users =
          snapshot.docs.map((doc) => EnhancedUser.fromFirestore(doc)).toList();

      // Filter by date range if provided
      if (startDate != null || endDate != null) {
        users.retainWhere((user) {
          final createdAt = user.createdAt;
          if (createdAt == null) return false;

          if (startDate != null && createdAt.isBefore(startDate)) return false;
          if (endDate != null && createdAt.isAfter(endDate)) return false;
          return true;
        });
      }

      // Calculate metrics
      final totalUsers = users.length;
      final activeUsers = users.where((u) => u.isActive).length;
      final suspendedUsers = users.where((u) => !u.isActive).length;
      final pendingUsers =
          users.where((u) => u.roles.contains('pending')).length;

      final roleCounts = {
        'admin': users.where((u) => u.roles.contains('admin')).length,
        'supplier': users.where((u) => u.roles.contains('supplier')).length,
        'engineer': users.where((u) => u.roles.contains('engineer')).length,
      };

      // Get registration trends
      final registrationTrends = _calculateRegistrationTrends(users);

      return {
        'totalUsers': totalUsers,
        'activeUsers': activeUsers,
        'suspendedUsers': suspendedUsers,
        'pendingUsers': pendingUsers,
        'roleCounts': roleCounts,
        'registrationTrends': registrationTrends,
        'users': users,
      };
    });
  }

  List<Map<String, dynamic>> _calculateRegistrationTrends(
      List<EnhancedUser> users) {
    final trends = <String, int>{};

    for (final user in users) {
      if (user.createdAt != null) {
        final dateKey = DateFormat('yyyy-MM-dd').format(user.createdAt!);
        trends[dateKey] = (trends[dateKey] ?? 0) + 1;
      }
    }

    return trends.entries.map((e) => {'date': e.key, 'count': e.value}).toList()
      ..sort((a, b) => (a['date'] as String).compareTo(b['date'] as String));
  }

  // Export users to CSV format
  Future<String> exportUsersToCSV({
    List<String>? userIds,
    Map<String, dynamic>? filters,
  }) async {
    try {
      Query query = _firestore.collection('users');

      if (userIds != null && userIds.isNotEmpty) {
        query = query.where(FieldPath.documentId, whereIn: userIds);
      }

      final snapshot = await query.get();
      final users =
          snapshot.docs.map((doc) => EnhancedUser.fromFirestore(doc)).toList();

      // Apply additional filters
      if (filters != null) {
        users.retainWhere((user) {
          if (filters['role'] != null && !user.roles.contains(filters['role']))
            return false;
          if (filters['status'] != null &&
              !user.roles.contains(filters['status'])) return false;
          if (filters['isActive'] != null &&
              user.isActive != filters['isActive']) return false;
          return true;
        });
      }

      // Generate CSV
      final csvBuffer = StringBuffer();

      // Header
      csvBuffer.writeln(
          'ID,Name,Email,Phone,Role,Status,IsActive,CreatedAt,LastLogin');

      // Data
      for (final user in users) {
        csvBuffer.writeln(
          '${user.uid},${user.displayName},${user.email},${user.phoneNumber},${user.roles.join(',')},active,${user.isActive},${user.createdAt},${user.lastLoginAt}',
        );
      }

      return csvBuffer.toString();
    } catch (e) {
      print('Error exporting users to CSV: $e');
      return '';
    }

    // Placeholder for getSystemHealth
    Stream<Map<String, dynamic>> getSystemHealth() {
      return Stream.value({
        'cpuUsage': 25.0,
        'memoryUsage': 40.0,
        'diskUsage': 60.0,
        'networkTraffic': 10.0,
        'serverStatus': 'Operational',
      });
    }

    // Placeholder for getDashboardStats
    Stream<Map<String, dynamic>> getDashboardStats() {
      return Stream.value({
        'totalOrders': 1200,
        'pendingOrders': 150,
        'completedOrders': 900,
        'totalRevenue': 150000.00,
        'newUsersToday': 25,
      });
    }

    // Placeholder for getRecentActivity
    Stream<List<AdminUserActivity>> getRecentActivity({int limit = 5}) {
      return _firestore
          .collection('user_activities')
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => AdminUserActivity.fromFirestore(doc))
              .toList());
    }
  }
}

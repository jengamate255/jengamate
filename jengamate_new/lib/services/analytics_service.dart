import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jengamate/models/order_model.dart';
import 'package:jengamate/models/enums/order_enums.dart';
import 'package:jengamate/models/product_model.dart';
import 'package:jengamate/models/user_model.dart';
import 'package:jengamate/utils/logger.dart';
import 'package:intl/intl.dart';

class AnalyticsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Revenue Analytics
  Future<Map<String, dynamic>> getRevenueAnalytics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final now = DateTime.now();
      final start = startDate ?? DateTime(now.year, now.month, 1);
      final end = endDate ?? now;

      final ordersSnapshot = await _firestore
          .collection('orders')
          .where('createdAt', isGreaterThanOrEqualTo: start)
          .where('createdAt', isLessThanOrEqualTo: end)
          .get();

      double totalRevenue = 0.0;
      double platformCommission = 0.0;
      Map<String, double> revenueByCategory = {};
      Map<String, double> revenueByPaymentMethod = {};

      for (var doc in ordersSnapshot.docs) {
        try {
          final order = OrderModel.fromFirestore((doc.data() as Map<String, dynamic>), docId: doc.id);
          if (order.status == OrderStatus.completed) {
            totalRevenue += order.totalAmount;
            platformCommission += order.totalAmount * 0.1; // 10 platform fee

            // Revenue by category
            for (var item in order.items) {
              final productSnapshot = await _firestore
                  .collection('products')
                  .doc(item.productId)
                  .get();
              if (productSnapshot.exists) {
                final product = ProductModel.fromFirestore(productSnapshot);
                final category = product.category ?? 'Uncategorized';
                final itemRevenue = item.price * item.quantity;
                revenueByCategory[category] =
                    (revenueByCategory[category] ?? 0) + itemRevenue;
              }
            }

            // Revenue by payment method
            final paymentMethod = order.paymentMethod ?? 'Unknown';
            revenueByPaymentMethod[paymentMethod] =
                (revenueByPaymentMethod[paymentMethod] ?? 0) +
                    order.totalAmount;
          }
        } catch (e) {
          Logger.logError('Error processing order for revenue analytics', e);
          continue;
        }
      }

      return {
        'totalRevenue': totalRevenue,
        'platformCommission': platformCommission,
        'revenueByCategory': revenueByCategory,
        'revenueByPaymentMethod': revenueByPaymentMethod,
        'averageOrderValue': ordersSnapshot.docs.isEmpty
            ? 0
            : totalRevenue / ordersSnapshot.docs.length,
      };
    } catch (e, s) {
      Logger.logError('Failed to get revenue analytics', e, s);
      return {};
    }
  }
  Future<Map<String, dynamic>> getUserBehaviorAnalytics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final now = DateTime.now();
      final start = startDate ?? DateTime(now.year, now.month, 1);
      final end = endDate ?? now;

      // Get all users
      final usersSnapshot = await _firestore.collection('users').get();

      int totalUsers = 0;
      int activeUsers = 0;
      int newUsers = 0;
      Map<String, int> userTypes = {'customer': 0, 'supplier': 0, 'admin': 0};
      double totalCustomerLifetimeValue = 0.0;

      for (var userDoc in usersSnapshot.docs) {
        try {
          final user = UserModel.fromFirestore(userDoc);
          totalUsers++;

          // Count by user type
          final userType = user.role.name; // enum is non-nullable
          userTypes[userType] = (userTypes[userType] ?? 0) + 1;

          // Check if user is new
          if (user.createdAt?.isAfter(start) == true &&
              user.createdAt?.isBefore(end) == true) {
            newUsers++;
          }

          // Check if user is active (has orders in period)
          final userOrdersSnapshot = await _firestore
              .collection('orders')
              .where('customerId', isEqualTo: user.uid)
              .where('createdAt', isGreaterThanOrEqualTo: start)
              .where('createdAt', isLessThanOrEqualTo: end)
              .get();

          if (userOrdersSnapshot.docs.isNotEmpty) {
            activeUsers++;

            // Calculate customer lifetime value
            double userRevenue = 0.0;
            for (var orderDoc in userOrdersSnapshot.docs) {
              try {
                final order = OrderModel.fromFirestore(orderDoc);
                if (order.status == OrderStatus.completed.name) {
                  userRevenue += order.totalAmount;
                }
              } catch (e) {
                Logger.logError('Error calculating user LTV', e);
                continue;
              }
            }
            totalCustomerLifetimeValue += userRevenue;
          }
        } catch (e) {
          Logger.logError('Error processing user analytics', e);
          continue;
        }
      }

      return {
        'totalUsers': totalUsers,
        'activeUsers': activeUsers,
        'newUsers': newUsers,
        'userTypes': userTypes,
        'averageCustomerLifetimeValue':
            totalUsers > 0 ? totalCustomerLifetimeValue / totalUsers : 0,
        'userEngagementRate': totalUsers > 0 ? activeUsers / totalUsers : 0,
      };
    } catch (e, s) {
      Logger.logError('Failed to get user behavior analytics', e, s);
      return {};
    }
  }

  // Order Analytics
  Future<Map<String, dynamic>> getOrderAnalytics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final now = DateTime.now();
      final start = startDate ?? DateTime(now.year, now.month, 1);
      final end = endDate ?? now;

      final ordersSnapshot = await _firestore
          .collection('orders')
          .where('createdAt', isGreaterThanOrEqualTo: start)
          .where('createdAt', isLessThanOrEqualTo: end)
          .get();

      Map<String, int> statusDistribution = {};
      Map<String, int> dailyOrders = {};
      int totalOrders = 0;
      int completedOrders = 0;
      int cancelledOrders = 0;

      for (var doc in ordersSnapshot.docs) {
        try {
          final order = OrderModel.fromFirestore((doc.data() as Map<String, dynamic>), docId: doc.id);
          totalOrders++;

          // Status distribution
          final status = order.status.toString().split('.').last;
          statusDistribution[status] = (statusDistribution[status] ?? 0) + 1;

          if (order.status == OrderStatus.completed) {
            completedOrders++;
          } else if (order.status == OrderStatus.cancelled) {
            cancelledOrders++;
          }

          // Daily orders
          final dateKey = DateFormat('yyyy-MM-dd').format(order.createdAt);
          dailyOrders[dateKey] = (dailyOrders[dateKey] ?? 0) + 1;
        } catch (e) {
          Logger.logError('Error processing order analytics', e);
          continue;
        }
      }

      return {
        'totalOrders': totalOrders,
        'completedOrders': completedOrders,
        'cancelledOrders': cancelledOrders,
        'completionRate': totalOrders > 0 ? completedOrders / totalOrders : 0,
        'cancellationRate': totalOrders > 0 ? cancelledOrders / totalOrders : 0,
        'statusDistribution': statusDistribution,
        'dailyOrders': dailyOrders,
      };
    } catch (e, s) {
      Logger.logError('Failed to get order analytics', e, s);
      return {};
    }
  }

  // Category Performance Analytics
  Future<Map<String, dynamic>> getCategoryPerformanceAnalytics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final now = DateTime.now();
      final start = startDate ?? DateTime(now.year, now.month, 1);
      final end = endDate ?? now;

      final ordersSnapshot = await _firestore
          .collection('orders')
          .where('createdAt', isGreaterThanOrEqualTo: start)
          .where('createdAt', isLessThanOrEqualTo: end)
          .get();

      Map<String, Map<String, dynamic>> categoryStats = {};

      for (var orderDoc in ordersSnapshot.docs) {
        try {
          final order = OrderModel.fromFirestore(orderDoc);
          if (order.status == OrderStatus.completed) {
            for (var item in order.items) {
              final productSnapshot = await _firestore
                  .collection('products')
                  .doc(item.productId)
                  .get();

              if (productSnapshot.exists) {
                final product = ProductModel.fromFirestore(productSnapshot);
                final category = product.category ?? 'Uncategorized';

                if (!categoryStats.containsKey(category)) {
                  categoryStats[category] = {
                    'totalRevenue': 0.0,
                    'totalOrders': 0,
                    'productCount': 0,
                  };
                }

                final itemRevenue = item.price * item.quantity;
                categoryStats[category]!['totalRevenue'] += itemRevenue;
                categoryStats[category]!['totalOrders'] += 1;
              }
            }
          }
        } catch (e) {
          Logger.logError('Error processing category analytics', e);
          continue;
        }
      }

      // Count products per category
      final productsSnapshot = await _firestore.collection('products').get();
      for (var productDoc in productsSnapshot.docs) {
        try {
          final product = ProductModel.fromFirestore(productDoc);
          final category = product.category ?? 'Uncategorized';
          if (categoryStats.containsKey(category)) {
            categoryStats[category]!['productCount'] += 1;
          }
        } catch (e) {
          Logger.logError('Error counting products in category', e);
          continue;
        }
      }

      return categoryStats;
    } catch (e, s) {
      Logger.logError('Failed to get category performance analytics', e, s);
      return {};
    }
  }

  // Export Analytics Data
  Future<Map<String, dynamic>> getAllAnalyticsData({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final revenueData = await getRevenueAnalytics(
        startDate: startDate,
        endDate: endDate,
      );
      final userBehavior = await getUserBehaviorAnalytics(
        startDate: startDate,
        endDate: endDate,
      );
      final orderAnalytics = await getOrderAnalytics(
        startDate: startDate,
        endDate: endDate,
      );

      return {
        'revenue': revenueData,
        'userBehavior': userBehavior,
        'orderAnalytics': orderAnalytics,
        'generatedAt': DateTime.now().toIso8601String(),
      };
    } catch (e, s) {
      Logger.logError('Failed to get all analytics data', e, s);
      return {};
    }
  }
}

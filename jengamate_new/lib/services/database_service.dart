import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:jengamate/models/notification_model.dart';
import 'package:jengamate/models/rfq_model.dart';
import 'package:jengamate/models/user_model.dart';
import 'package:jengamate/models/order_model.dart';
import 'package:jengamate/models/withdrawal_model.dart';
import 'package:jengamate/models/commission_model.dart';
import 'package:jengamate/models/category_model.dart';
import 'package:jengamate/models/product_model.dart';
import 'package:jengamate/models/financial_transaction_model.dart';
import 'package:jengamate/models/commission_tier_model.dart';
import 'package:jengamate/models/rank_model.dart';
import 'package:jengamate/models/content_report_model.dart';
import 'package:jengamate/models/audit_log_model.dart';
import 'package:jengamate/models/quote_model.dart';
import 'package:jengamate/models/payment_model.dart';
import 'package:jengamate/models/chat_room_model.dart';
import 'package:jengamate/models/support_ticket_model.dart';
import 'package:jengamate/models/inquiry.dart';
import 'package:jengamate/models/system_config_model.dart';
import 'package:jengamate/models/chat_message_model.dart';
import 'package:jengamate/models/faq_model.dart';
import 'package:jengamate/models/enhanced_user.dart';
import 'package:jengamate/models/enums/order_enums.dart';
import 'package:jengamate/utils/logger.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Notification Management
  Future<void> createNotification(NotificationModel notification) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notification.uid)
          .set(notification.toFirestore());
    } catch (e) {
      Logger.logError('Error creating notification', e);
      rethrow;
    }
  }

  // Payments
  Future<void> createPayment(PaymentModel payment) async {
    try {
      final docRef = _firestore.collection('payments').doc();
      final model =
          payment.id.isEmpty ? payment.copyWith(id: docRef.id) : payment;
      await docRef.set(model.toMap());
    } catch (e) {
      Logger.logError('Error creating payment', e);
      rethrow;
    }
  }

  Stream<List<PaymentModel>> streamPayments(String userId) {
    return _firestore
        .collection('payments')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PaymentModel.fromFirestore(doc))
            .toList());
  }

  // Orders
  Stream<List<OrderModel>> getOrders(String? userId) {
    Query collection =
        _firestore.collection('orders').orderBy('createdAt', descending: true);
    if (userId != null && userId.isNotEmpty) {
      collection = _firestore
          .collection('orders')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true);
    }
    return collection.snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => OrderModel.fromFirestore(doc)).toList());
  }

  // Inquiry activity timeline (comments and status changes)
  Stream<List<Map<String, dynamic>>> streamInquiryActivities(String inquiryId) {
    return _firestore
        .collection('inquiries')
        .doc(inquiryId)
        .collection('activities')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => d.data()).toList());
  }

  Future<void> addInquiryComment({
    required String inquiryId,
    required String userId,
    required String userName,
    required String text,
  }) async {
    try {
      await _firestore
          .collection('inquiries')
          .doc(inquiryId)
          .collection('activities')
          .add({
        'type': 'comment',
        'text': text,
        'userId': userId,
        'userName': userName,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      Logger.logError('Error adding inquiry comment', e);
      rethrow;
    }
  }

  Future<void> logInquiryStatusChange({
    required String inquiryId,
    required String fromStatus,
    required String toStatus,
    required String userId,
    required String userName,
  }) async {
    try {
      await _firestore
          .collection('inquiries')
          .doc(inquiryId)
          .collection('activities')
          .add({
        'type': 'status',
        'from': fromStatus,
        'to': toStatus,
        'userId': userId,
        'userName': userName,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      Logger.logError('Error logging inquiry status change', e);
      rethrow;
    }
  }

  // Simple notification helper (writes a bare doc into notifications)
  Future<void> sendInquiryNotification({
    required String userId,
    required String title,
    required String body,
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'userId': userId,
        'title': title,
        'body': body,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      Logger.logError('Error sending inquiry notification', e);
      rethrow;
    }
  }

  // Total Sales (TSH) within the last [days] days
  Stream<double> streamTotalSalesAmountTSHWindow({int days = 7}) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return _firestore
        .collection('orders')
        .where('status', isEqualTo: OrderStatus.completed.name)
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(cutoff))
        .snapshots()
        .map((snapshot) {
      double sum = 0;
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final v = data['totalAmount'];
        if (v is num) sum += v.toDouble();
      }
      return sum;
    });
  }

  Stream<int> streamTotalOrdersCount() {
    return _firestore
        .collection('orders')
        .snapshots()
        .map((s) => s.docs.length);
  }

  Stream<int> streamPendingOrdersCount() {
    return _firestore
        .collection('orders')
        .where('status', isEqualTo: OrderStatus.pending.name)
        .snapshots()
        .map((s) => s.docs.length);
  }

  Stream<int> streamCompletedOrdersCount() {
    return _firestore
        .collection('orders')
        .where('status', isEqualTo: OrderStatus.completed.name)
        .snapshots()
        .map((s) => s.docs.length);
  }

  // Total Sales (TSH) computed from completed orders' totalAmount
  Stream<double> streamTotalSalesAmountTSH() {
    return _firestore
        .collection('orders')
        .where('status', isEqualTo: OrderStatus.completed.name)
        .snapshots()
        .map((snapshot) {
      double sum = 0;
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final v = data['totalAmount'];
        if (v is num) sum += v.toDouble();
      }
      return sum;
    });
  }

  Stream<int> streamTotalUsersCount() {
    return _firestore.collection('users').snapshots().map((s) => s.docs.length);
  }

  // New users in the last [days] days (default 7)
  Stream<int> streamNewUsersCount({int days = 7}) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return _firestore
        .collection('users')
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(cutoff))
        .snapshots()
        .map((s) => s.docs.length);
  }

  // Daily sales timeseries for the last [days] days (TSH from completed orders)
  Stream<List<double>> streamDailySalesTSH({int days = 7}) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return _firestore
        .collection('orders')
        .where('status', isEqualTo: OrderStatus.completed.name)
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(cutoff))
        .snapshots()
        .map((snapshot) {
      // Initialize array of length [days] with zeros, oldest to newest
      final List<double> series = List<double>.filled(days, 0);
      final now = DateTime.now();
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final createdAt = (data['createdAt'] is Timestamp)
            ? (data['createdAt'] as Timestamp).toDate()
            : (data['createdAt'] is DateTime)
                ? data['createdAt'] as DateTime
                : null;
        final amountNum = data['totalAmount'];
        if (createdAt == null || amountNum is! num) continue;
        final diff = now
            .difference(
                DateTime(createdAt.year, createdAt.month, createdAt.day))
            .inDays;
        // diff == 0 means today; we want index days-1 for today
        final indexFromStart = days - 1 - diff;
        if (indexFromStart >= 0 && indexFromStart < days) {
          series[indexFromStart] += amountNum.toDouble();
        }
      }
      return series;
    });
  }

  Stream<List<NotificationModel>> streamUserNotifications(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NotificationModel.fromFirestore(doc))
            .toList());
  }

  Stream<int> streamUnreadNotificationsCount(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // User Management
  Future<UserModel?> getUser(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      Logger.logError('Error getting user', e);
      rethrow;
    }
  }

  Future<void> updateUser(UserModel user) async {
    try {
      await _firestore.collection('users').doc(user.uid).update(user.toMap());
    } catch (e) {
      Logger.logError('Error updating user', e);
      rethrow;
    }
  }

  Stream<List<EnhancedUser>> streamEnhancedUsers() {
    return _firestore.collection('users').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => EnhancedUser.fromFirestore(doc)).toList());
  }

  Stream<List<UserModel>> streamAllUsers() {
    return _firestore.collection('users').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList());
  }

  Future<List<UserModel>> getUsersCreatedAfter(DateTime startDate) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('createdAt', isGreaterThanOrEqualTo: startDate)
          .get();
      return snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
    } catch (e) {
      Logger.logError('Error getting users created after date', e);
      rethrow;
    }
  }

  // RFQ Management
  Stream<List<RFQModel>> streamAllRFQs() {
    return _firestore
        .collection('rfqs')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => RFQModel.fromFirestore(doc)).toList());
  }

  Stream<List<RFQModel>> streamUserRFQs(String userId) {
    return _firestore
        .collection('rfqs')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => RFQModel.fromFirestore(doc)).toList());
  }

  Stream<List<RFQModel>> streamInquiries(String userId) {
    return _firestore
        .collection('rfqs')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => RFQModel.fromFirestore(doc)).toList());
  }

  Future<RFQModel?> getRFQ(String rfqId) async {
    try {
      final doc = await _firestore.collection('rfqs').doc(rfqId).get();
      if (doc.exists) {
        return RFQModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      Logger.logError('Error getting RFQ', e);
      rethrow;
    }
  }

  Future<void> updateRFQStatus(String rfqId, String status) async {
    try {
      await _firestore.collection('rfqs').doc(rfqId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      Logger.logError('Error updating RFQ status', e);
      rethrow;
    }
  }

  // Quote Management
  Future<void> createQuote(QuoteModel quote) async {
    try {
      await _firestore.collection('quotes').doc(quote.uid).set(quote.toMap());
    } catch (e) {
      Logger.logError('Error creating quote', e);
      rethrow;
    }
  }

  Stream<List<QuoteModel>> streamQuotesForRFQ(String rfqId) {
    return _firestore
        .collection('quotes')
        .where('rfqId', isEqualTo: rfqId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => QuoteModel.fromFirestore(doc)).toList());
  }

  // Commission Management
  Stream<List<CommissionModel>> getAllCommissions() {
    return _firestore
        .collection('commissions')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CommissionModel.fromFirestore(doc))
            .toList());
  }

  Stream<List<CommissionModel>> streamUserCommissions(String userId) {
    return _firestore
        .collection('commissions')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CommissionModel.fromFirestore(doc))
            .toList());
  }

  Future<List<CommissionModel>> getCommissionRules() async {
    try {
      final snapshot = await _firestore.collection('commission_rules').get();
      return snapshot.docs
          .map((doc) => CommissionModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      Logger.logError('Error getting commission rules', e);
      rethrow;
    }
  }

  Stream<List<CommissionModel>> streamCommissionRules() {
    return _firestore.collection('commission_rules').snapshots().map(
        (snapshot) => snapshot.docs
            .map((doc) => CommissionModel.fromFirestore(doc))
            .toList());
  }

  Future<void> deleteCommissionRecord(String id) async {
    try {
      await _firestore.collection('commissions').doc(id).delete();
    } catch (e) {
      Logger.logError('Error deleting commission record', e);
      rethrow;
    }
  }

  Stream<List<CommissionModel>> streamTrashedCommissions() {
    return _firestore
        .collection('commissions')
        .where('isDeleted', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CommissionModel.fromFirestore(doc))
            .toList());
  }

  // Category Management
  Stream<List<CategoryModel>> streamCategories() {
    return _firestore.collection('categories').orderBy('name').snapshots().map(
        (snapshot) => snapshot.docs
            .map((doc) => CategoryModel.fromFirestore(doc))
            .toList());
  }

  Future<List<CategoryModel>> getCategories() async {
    try {
      final snapshot = await _firestore.collection('categories').get();
      return snapshot.docs
          .map((doc) => CategoryModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      Logger.logError('Error getting categories', e);
      rethrow;
    }
  }

  Future<List<CategoryModel>> getSubCategories(String parentId) async {
    try {
      final snapshot = await _firestore
          .collection('categories')
          .where('parentId', isEqualTo: parentId)
          .get();
      return snapshot.docs
          .map((doc) => CategoryModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      Logger.logError('Error getting subcategories', e);
      rethrow;
    }
  }

  Future<void> addCategory(CategoryModel category) async {
    try {
      await _firestore
          .collection('categories')
          .doc(category.uid)
          .set(category.toMap());
    } catch (e) {
      Logger.logError('Error adding category', e);
      rethrow;
    }
  }

  Future<void> updateCategory(CategoryModel category) async {
    try {
      await _firestore
          .collection('categories')
          .doc(category.uid)
          .update(category.toMap());
    } catch (e) {
      Logger.logError('Error updating category', e);
      rethrow;
    }
  }

  Future<void> deleteCategory(String id) async {
    try {
      await _firestore.collection('categories').doc(id).delete();
    } catch (e) {
      Logger.logError('Error deleting category', e);
      rethrow;
    }
  }

  // Product Management
  Stream<List<ProductModel>> streamProducts() {
    return _firestore.collection('products').orderBy('name').snapshots().map(
        (snapshot) => snapshot.docs
            .map((doc) => ProductModel.fromFirestore(doc))
            .toList());
  }

  Future<List<ProductModel>> getTopSellingProducts(int limit) async {
    try {
      final snapshot = await _firestore
          .collection('products')
          .orderBy('salesCount', descending: true)
          .limit(limit)
          .get();
      return snapshot.docs
          .map((doc) => ProductModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      Logger.logError('Error getting top selling products', e);
      rethrow;
    }
  }

  Future<void> deleteProducts(List<String> productIds) async {
    try {
      final batch = _firestore.batch();
      for (final id in productIds) {
        batch.delete(_firestore.collection('products').doc(id));
      }
      await batch.commit();
    } catch (e) {
      Logger.logError('Error deleting products', e);
      rethrow;
    }
  }

  Future<String?> getProductImage(String productId) async {
    try {
      final doc = await _firestore.collection('products').doc(productId).get();
      if (doc.exists) {
        final data = doc.data();
        return data?['imageUrl'] as String?;
      }
      return null;
    } catch (e) {
      Logger.logError('Error getting product image', e);
      return null;
    }
  }

  // Withdrawal Management
  Stream<List<WithdrawalModel>> streamWithdrawals(String userId) {
    return _firestore
        .collection('withdrawals')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => WithdrawalModel.fromFirestore(doc))
            .toList());
  }

  Future<void> updateWithdrawalStatus(
      String withdrawalId, String status) async {
    try {
      await _firestore.collection('withdrawals').doc(withdrawalId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      Logger.logError('Error updating withdrawal status', e);
      rethrow;
    }
  }

  // Analytics
  Future<Map<String, dynamic>> getAdminAnalytics() async {
    try {
      final usersSnapshot = await _firestore.collection('users').get();
      final ordersSnapshot = await _firestore.collection('orders').get();
      final commissionsSnapshot =
          await _firestore.collection('commissions').get();
      final productsSnapshot = await _firestore.collection('products').get();
      final inquiriesSnapshot = await _firestore.collection('inquiries').get();

      return {
        'totalUsers': usersSnapshot.docs.length,
        'totalOrders': ordersSnapshot.docs.length,
        'totalCommissions': commissionsSnapshot.docs.length,
        'totalProducts': productsSnapshot.docs.length,
        'totalInquiries': inquiriesSnapshot.docs.length,
      };
    } catch (e) {
      Logger.logError('Error getting admin analytics', e);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getWithdrawalStats() async {
    try {
      final snapshot = await _firestore.collection('withdrawals').get();
      final withdrawals = snapshot.docs
          .map((doc) => WithdrawalModel.fromFirestore(doc))
          .toList();

      double totalAmount = 0;
      int pendingCount = 0;

      for (final withdrawal in withdrawals) {
        totalAmount += withdrawal.amount;
        if (withdrawal.status == 'pending') {
          pendingCount++;
        }
      }

      return {
        'totalAmount': totalAmount,
        'pendingCount': pendingCount,
        'totalCount': withdrawals.length,
      };
    } catch (e) {
      Logger.logError('Error getting withdrawal stats', e);
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getSalesOverTime() async {
    try {
      final snapshot = await _firestore.collection('orders').get();
      final orders =
          snapshot.docs.map((doc) => OrderModel.fromFirestore(doc)).toList();

      final salesByMonth = <String, double>{};

      for (final order in orders) {
        if (order.status == 'completed') {
          final monthKey =
              '${order.createdAt.year}-${order.createdAt.month.toString().padLeft(2, '0')}';
          salesByMonth[monthKey] =
              (salesByMonth[monthKey] ?? 0) + order.totalAmount;
        }
      }

      return salesByMonth.entries
          .map((e) => {'month': e.key, 'sales': e.value})
          .toList();
    } catch (e) {
      Logger.logError('Error getting sales over time', e);
      rethrow;
    }
  }

  Future<Map<String, int>> getOrderCountsByStatus() async {
    try {
      final snapshot = await _firestore.collection('orders').get();
      final orders =
          snapshot.docs.map((doc) => OrderModel.fromFirestore(doc)).toList();

      final statusCounts = <String, int>{};

      for (final order in orders) {
        final statusKey = order.status.name;
        statusCounts[statusKey] = (statusCounts[statusKey] ?? 0) + 1;
      }

      return statusCounts;
    } catch (e) {
      Logger.logError('Error getting order counts by status', e);
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getUserGrowthOverTime() async {
    try {
      final snapshot = await _firestore.collection('users').get();
      final users =
          snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();

      final usersByMonth = <String, int>{};

      for (final user in users) {
        if (user.createdAt != null) {
          final monthKey =
              '${user.createdAt!.year}-${user.createdAt!.month.toString().padLeft(2, '0')}';
          usersByMonth[monthKey] = (usersByMonth[monthKey] ?? 0) + 1;
        }
      }

      return usersByMonth.entries
          .map((e) => {'month': e.key, 'users': e.value})
          .toList();
    } catch (e) {
      Logger.logError('Error getting user growth over time', e);
      rethrow;
    }
  }

  Stream<List<FinancialTransactionModel>> getFinancialTransactions() {
    return _firestore
        .collection('financial_transactions')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => FinancialTransactionModel.fromFirestore(doc))
            .toList());
  }

  // Commission Tiers
  Future<List<CommissionTier>> getCommissionTiers() async {
    try {
      final snapshot = await _firestore.collection('commission_tiers').get();
      return snapshot.docs
          .map((doc) => CommissionTier.fromFirestore(doc))
          .toList();
    } catch (e) {
      Logger.logError('Error getting commission tiers', e);
      rethrow;
    }
  }

  Future<List<UserModel>> getUsersWithTierInfo() async {
    try {
      final snapshot = await _firestore.collection('users').get();
      return snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
    } catch (e) {
      Logger.logError('Error getting users with tier info', e);
      rethrow;
    }
  }

  // Content Moderation
  Future<List<ContentReport>> getContentReports({String? status}) async {
    try {
      Query query = _firestore.collection('content_reports');
      if (status != null) {
        query = query.where('status', isEqualTo: status);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => ContentReport.fromFirestore(doc))
          .toList();
    } catch (e) {
      Logger.logError('Error getting content reports', e);
      rethrow;
    }
  }

  // Audit Logs
  Future<List<AuditLogModel>> getAuditLogs() async {
    try {
      final snapshot = await _firestore
          .collection('audit_logs')
          .orderBy('timestamp', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => AuditLogModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      Logger.logError('Error getting audit logs', e);
      rethrow;
    }
  }

  Future<void> createAuditLog(AuditLogModel log) async {
    try {
      await _firestore.collection('audit_logs').doc(log.uid).set(log.toMap());
    } catch (e) {
      Logger.logError('Error creating audit log', e);
      rethrow;
    }
  }

  // Chat Management
  Stream<List<ChatRoom>> streamChatRoomsForUser(String userId) {
    return _firestore
        .collection('chat_rooms')
        .where('participants', arrayContains: userId)
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => ChatRoom.fromFirestore(doc)).toList());
  }

  // Support Tickets
  Future<List<SupportTicket>> getAllSupportTickets() async {
    try {
      final snapshot = await _firestore
          .collection('support_tickets')
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => SupportTicket.fromFirestore(doc))
          .toList();
    } catch (e) {
      Logger.logError('Error getting support tickets', e);
      rethrow;
    }
  }

  // System Configuration
  Future<SystemConfig?> getSystemConfig() async {
    try {
      final doc =
          await _firestore.collection('system_config').doc('main').get();
      if (doc.exists) {
        return SystemConfig.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      Logger.logError('Error getting system config', e);
      rethrow;
    }
  }

  Future<void> updateSystemConfig(SystemConfig config) async {
    try {
      await _firestore
          .collection('system_config')
          .doc('main')
          .set(config.toMap());
    } catch (e) {
      Logger.logError('Error updating system config', e);
      rethrow;
    }
  }

  // Additional missing methods
  Future<List<FinancialTransactionModel>> getPaginatedFinancialTransactions({
    int limit = 20,
    DocumentSnapshot? startAfter,
    String? userId,
  }) async {
    try {
      Query query = _firestore
          .collection('financial_transactions')
          .orderBy('timestamp', descending: true)
          .limit(limit);

      if (userId != null) {
        query = query.where('userId', isEqualTo: userId);
      }

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => FinancialTransactionModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      Logger.logError('Error getting paginated financial transactions', e);
      rethrow;
    }
  }

  Future<DocumentSnapshot?> getLastTransactionDocument() async {
    final snapshot = await _firestore
        .collection('financial_transactions')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return null;
    return snapshot.docs.first;
  }

  Future<List<SupportTicket>> getUserSupportTickets(String userId,
      {int limit = 50}) async {
    try {
      final snapshot = await _firestore
          .collection('support_tickets')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => SupportTicket.fromFirestore(doc))
          .toList();
    } catch (e) {
      Logger.logError('Error getting user support tickets', e);
      rethrow;
    }
  }

  Future<void> createSupportTicket(SupportTicket ticket) async {
    try {
      await _firestore
          .collection('support_tickets')
          .doc(ticket.uid)
          .set(ticket.toMap());
    } catch (e) {
      Logger.logError('Error creating support ticket', e);
      rethrow;
    }
  }

  Future<List<FAQItem>> getFAQs({String? category}) async {
    try {
      Query query = _firestore.collection('faqs').orderBy('order');
      if (category != null) {
        query = query.where('category', isEqualTo: category);
      }

      final snapshot = await query.get();
      return snapshot.docs.map((doc) => FAQItem.fromFirestore(doc)).toList();
    } catch (e) {
      Logger.logError('Error getting FAQs', e);
      rethrow;
    }
  }

  Future<void> createFAQ(FAQItem faq) async {
    try {
      await _firestore.collection('faqs').doc(faq.uid).set(faq.toMap());
    } catch (e) {
      Logger.logError('Error creating FAQ', e);
      rethrow;
    }
  }

  Future<void> requestWithdrawal(Map<String, dynamic> withdrawal) async {
    try {
      await _firestore.collection('withdrawals').add(withdrawal);
    } catch (e) {
      Logger.logError('Error requesting withdrawal', e);
      rethrow;
    }
  }

  Future<void> addOrUpdateProduct(Map<String, dynamic> product) async {
    try {
      await _firestore.collection('products').doc(product['id']).set(product);
    } catch (e) {
      Logger.logError('Error adding/updating product', e);
      rethrow;
    }
  }

  Future<void> addOrUpdateProductModel(ProductModel product) async {
    try {
      await _firestore
          .collection('products')
          .doc(product.id)
          .set(product.toMap());
    } catch (e) {
      Logger.logError('Error adding/updating product', e);
      rethrow;
    }
  }

  Future<ProductModel?> getProduct(String productId) async {
    try {
      final doc = await _firestore.collection('products').doc(productId).get();
      if (!doc.exists) return null;
      return ProductModel.fromFirestore(doc);
    } catch (e) {
      Logger.logError('Error getting product', e);
      return null;
    }
  }

  Future<List<ProductModel>> getProductsByIds(List<String> productIds) async {
    if (productIds.isEmpty) {
      return [];
    }
    try {
      final snapshot = await _firestore
          .collection('products')
          .where(FieldPath.documentId, whereIn: productIds)
          .get();
      return snapshot.docs
          .map((doc) => ProductModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      Logger.logError('Error getting products by ids', e);
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getApprovedSuppliers() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'supplier')
          .where('isApproved', isEqualTo: true)
          .get();

      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      Logger.logError('Error getting approved suppliers', e);
      rethrow;
    }
  }

  Future<void> createRFQ(Map<String, dynamic> rfq) async {
    try {
      await _firestore.collection('rfqs').add(rfq);
    } catch (e) {
      Logger.logError('Error creating RFQ', e);
      rethrow;
    }
  }

  Future<void> addRFQ(RFQModel rfq) async {
    try {
      final doc = _firestore.collection('rfqs').doc();
      final data = rfq.id.isEmpty ? rfq.toMap() : rfq.toMap();
      await doc.set({
        ...data,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      Logger.logError('Error adding RFQ', e);
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> searchUsers(String query,
      {int limit = 20}) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThanOrEqualTo: query + '\uf8ff')
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      Logger.logError('Error searching users', e);
      rethrow;
    }
  }

  Future<void> updateCommissionRules(Map<String, dynamic> rules) async {
    try {
      await _firestore.collection('commission_rules').add(rules);
    } catch (e) {
      Logger.logError('Error updating commission rules', e);
      rethrow;
    }
  }

  Stream<Map<String, dynamic>> streamOrderStats(String userId) {
    return _firestore
        .collection('orders')
        .where('customerId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final orders =
          snapshot.docs.map((doc) => OrderModel.fromFirestore(doc)).toList();
      final totalOrders = orders.length;
      final completedOrders = orders
          .where((order) => order.status == OrderStatus.completed.name)
          .length;
      final totalSpent =
          orders.fold<double>(0, (sum, order) => sum + order.totalAmount);

      return {
        'totalOrders': totalOrders,
        'completedOrders': completedOrders,
        'totalSpent': totalSpent,
      };
    });
  }

  Future<void> updateOrder(OrderModel order) async {
    try {
      await _firestore.collection('orders').doc(order.uid).set(order.toMap());
    } catch (e) {
      Logger.logError('Error updating order', e);
      rethrow;
    }
  }

  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'status': status.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      Logger.logError('Error updating order status', e);
      rethrow;
    }
  }

  Stream<List<Inquiry>> streamInquiriesForUser(String userId) {
    return _firestore
        .collection('inquiries')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) {
            try {
              final data = doc.data();
              // Skip if either description or subject is not a string when they are not null
              if ((data['description'] != null && data['description'] is! String) ||
                  (data['subject'] != null && data['subject'] is! String)) {
                Logger.logError(
                    'Inquiry data type mismatch for doc ${doc.id}: description=${data['description']?.runtimeType}, subject=${data['subject']?.runtimeType}',
                    Exception('Type mismatch'));
                return null;
              }
              return Inquiry.fromFirestore(doc);
            } catch (e, st) {
              Logger.logError(
                  'Error parsing inquiry for doc ${doc.id}: $e. Data: ${doc.data()}',
                  e,
                  st);
              return null;
            }
          })
          .whereType<Inquiry>()
          .toList();
    });
  }

  Future<void> updateInquiryFields(
      String inquiryId, Map<String, dynamic> data) async {
    try {
      if (inquiryId.isEmpty) {
        throw Exception('Cannot update inquiry: Empty inquiry ID provided');
      }
      await _firestore.collection('inquiries').doc(inquiryId).update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      Logger.logError('Error updating inquiry fields', e);
      rethrow;
    }
  }

  Future<void> updateInquiryStatus(String inquiryId, String status) async {
    print('📝 updateInquiryStatus called');
    print('   inquiryId: "$inquiryId" (length: ${inquiryId.length})');
    print('   status: "$status"');
    
    if (inquiryId.isEmpty) {
      final error = 'Cannot update inquiry status: Empty inquiry ID provided';
      print('❌ $error');
      throw Exception(error);
    }
    
    try {
      final updateData = {
        'status': status,
        if (status == 'resolved') 'resolvedAt': FieldValue.serverTimestamp(),
      };
      
      print('🔄 Updating inquiry with data: $updateData');
      await updateInquiryFields(inquiryId, updateData);
      print('✅ Successfully updated inquiry status');
    } catch (e) {
      final error = 'Error updating inquiry status: $e';
      print('❌ $error');
      Logger.logError(error, e);
      rethrow;
    }
  }

  Future<void> updateInquiryPriority(String inquiryId, String priority) async {
    try {
      await updateInquiryFields(inquiryId, {'priority': priority});
    } catch (e) {
      Logger.logError('Error updating inquiry priority', e);
      rethrow;
    }
  }

  Future<void> assignInquiry({
    required String inquiryId,
    required String? assignedTo,
    required String? assignedToName,
  }) async {
    try {
      await updateInquiryFields(inquiryId, {
        'assignedTo': assignedTo,
        'assignedToName': assignedToName,
      });
    } catch (e) {
      Logger.logError('Error assigning inquiry', e);
      rethrow;
    }
  }

  Stream<List<ChatMessage>> streamMessages(String chatRoomId) {
    return _firestore
        .collection('messages')
        .where('chatRoomId', isEqualTo: chatRoomId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatMessage.fromFirestore(doc))
            .toList());
  }

  Future<void> addMessage(ChatMessage message) async {
    try {
      final docRef = _firestore.collection('messages').doc();
      final model =
          message.uid.isEmpty ? message.copyWith(uid: docRef.id) : message;
      await docRef.set(model.toMap());
    } catch (e) {
      Logger.logError('Error adding message', e);
      rethrow;
    }
  }

  Future<ChatRoom?> getChatRoom(String roomId) async {
    try {
      final doc = await _firestore.collection('chat_rooms').doc(roomId).get();
      if (doc.exists) {
        return ChatRoom.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      Logger.logError('Error getting chat room', e);
      return null;
    }
  }

  Future<void> createChatRoom(ChatRoom room) async {
    try {
      await _firestore.collection('chat_rooms').doc(room.uid).set(room.toMap());
    } catch (e) {
      Logger.logError('Error creating chat room', e);
      rethrow;
    }
  }

  Future<void> createCommissionTier(CommissionTier tier) async {
    try {
      await _firestore
          .collection('commission_tiers')
          .doc(tier.uid)
          .set(tier.toMap());
    } catch (e) {
      Logger.logError('Error creating commission tier', e);
      rethrow;
    }
  }

  Future<void> createContentReport(ContentReport report) async {
    try {
      await _firestore
          .collection('content_reports')
          .doc(report.uid)
          .set(report.toMap());
    } catch (e) {
      Logger.logError('Error creating content report', e);
      rethrow;
    }
  }

  // Ranks
  Future<void> addRank(RankModel rank) async {
    try {
      final docRef = _firestore.collection('ranks').doc();
      final model = rank.id.isEmpty ? rank.copyWith(id: docRef.id) : rank;
      await _firestore.collection('ranks').doc(model.id).set(model.toMap());
    } catch (e) {
      Logger.logError('Error adding rank', e);
      rethrow;
    }
  }

  Future<void> updateRank(RankModel rank) async {
    try {
      await _firestore.collection('ranks').doc(rank.id).update(rank.toMap());
    } catch (e) {
      Logger.logError('Error updating rank', e);
      rethrow;
    }
  }

  // Placeholder for deleteRank
  Future<void> deleteRank(String rankId) async {
    try {
      await _firestore.collection('ranks').doc(rankId).delete();
    } catch (e) {
      Logger.logError('Error deleting rank', e);
      rethrow;
    }
  }

  Stream<List<RankModel>> streamRanks() {
    return _firestore.collection('ranks').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => RankModel.fromFirestore(doc)).toList());
  }

  // Placeholder for addReview
  Future<void> addReview(Map<String, dynamic> review) async {
    try {
      await _firestore.collection('reviews').add(review);
    } catch (e) {
      Logger.logError('Error adding review', e);
      rethrow;
    }
  }

  // Placeholder for updateModerationStatus
  Future<void> updateModerationStatus(String itemId, String status) async {
    try {
      await _firestore.collection('content_moderation').doc(itemId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      Logger.logError('Error updating moderation status', e);
      rethrow;
    }
  }

  // Placeholder for streamEnhancedUsers (already exists, but ensuring it's correct)
  // Stream<List<UserModel>> streamEnhancedUsers() {
  //   return _firestore.collection('users').snapshots().map((snapshot) =>
  //       snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList());
  // }

  Future<void> updateEnhancedUser(EnhancedUser user) async {
    try {
      await _firestore.collection('users').doc(user.uid).update(user.toMap());
    } catch (e) {
      Logger.logError('Error updating enhanced user', e);
      rethrow;
    }
  }

  Future<void> deleteUser(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).delete();
    } catch (e) {
      Logger.logError('Error deleting user', e);
      rethrow;
    }
  }

  // Placeholder for getNotifications
  Stream<List<NotificationModel>> getNotifications() {
    return _firestore.collection('notifications').snapshots().map((snapshot) =>
        snapshot.docs
            .map((doc) => NotificationModel.fromFirestore(doc))
            .toList());
  }

  // Placeholder for sendQuoteSubmissionNotification
  Future<void> sendQuoteSubmissionNotification(
      Map<String, dynamic> quote) async {
    try {
      // Implement notification logic here
      Logger.log(
          'Sending quote submission notification for quote: ${quote['id']}');
    } catch (e) {
      Logger.logError('Error sending quote submission notification', e);
      rethrow;
    }
  }

  // Placeholder for createRFQ (already exists, but ensuring it's correct)
  // Future<void> createRFQ(Map<String, dynamic> rfq) async {
  //   try {
  //     await _firestore.collection('rfqs').add(rfq);
  //   } catch (e) {
  //     Logger.logError('Error creating RFQ', e);
  //     rethrow;
  //   }
  // }

  // Placeholder for createOrder (already exists, but ensuring it's correct)
  // Future<void> createOrder(OrderModel order) async {
  //   try {
  //     await _firestore.collection('orders').doc(order.uid).set(order.toMap());
  //   } catch (e) {
  //     Logger.logError('Error creating order', e);
  //     rethrow;
  //   }
  // }

  Stream<List<AuditLogModel>> getAuditLogsStream({int limit = 50}) {
    return _firestore
        .collection('audit_logs')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AuditLogModel.fromFirestore(doc))
            .toList());
  }

  Future<Map<DateTime, double>> getSalesOverTimeMap() async {
    try {
      final data = await getSalesOverTime();
      final Map<DateTime, double> result = {};

      for (var item in data) {
        final date = DateTime.parse(item['month'] + '-01');
        result[date] = item['sales'];
      }

      return result;
    } catch (e) {
      Logger.logError('Error getting sales over time map', e);
      rethrow;
    }
  }
  // Missing methods that need to be added

  Future<OrderModel?> getOrderByID(String orderId) async {
    try {
      final doc = await _firestore.collection('orders').doc(orderId).get();
      if (doc.exists) {
        return OrderModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      Logger.logError('Error getting order by ID', e);
      return null;
    }
  }

  Future<String?> uploadFile(Uint8List bytes, String path) async {
    try {
      final storageRef = _storage.ref().child(path);
      final uploadTask = storageRef.putData(bytes);
      final snapshot = await uploadTask.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      Logger.logError('Error uploading file', e);
      return null;
    }
  }

  Future<void> addCommissionRecordValidated(CommissionModel commission) async {
    try {
      // Validate commission data before adding
      if (commission.userId.isEmpty || commission.total <= 0) {
        throw Exception('Invalid commission data');
      }

      await _firestore
          .collection('commissions')
          .doc(commission.uid)
          .set(commission.toMap());
    } catch (e) {
      Logger.logError('Error adding validated commission record', e);
      rethrow;
    }
  }

  Future<void> updateCommissionRecord(
      String commissionId, Map<String, dynamic> updates) async {
    try {
      await _firestore
          .collection('commissions')
          .doc(commissionId)
          .update(updates);
    } catch (e) {
      Logger.logError('Error updating commission record', e);
      rethrow;
    }
  }

  Stream<List<Inquiry>> streamAllInquiries() {
    return _firestore
        .collection('inquiries')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) {
            try {
              final data = doc.data();
              // Skip if either description or subject is not a string when they are not null
              if ((data['description'] != null && data['description'] is! String) ||
                  (data['subject'] != null && data['subject'] is! String)) {
                Logger.logError(
                    'Inquiry data type mismatch for doc ${doc.id}: description=${data['description']?.runtimeType}, subject=${data['subject']?.runtimeType}',
                    Exception('Type mismatch'));
                return null;
              }
              return Inquiry.fromFirestore(doc);
            } catch (e, st) {
              Logger.logError(
                  'Error parsing inquiry for doc ${doc.id}: $e. Data: ${doc.data()}',
                  e,
                  st);
              return null;
            }
          })
          .whereType<Inquiry>()
          .toList();
    });
  }

  Future<UserModel?> getCurrentUser() async {
    try {
      // This would typically get the current user from Firebase Auth
      // For now, return null as this needs to be implemented based on your auth setup
      return null;
    } catch (e) {
      Logger.logError('Error getting current user', e);
      return null;
    }
  }

  // Removed older addRFQ(Map) in favor of typed RFQModel version

  Future<void> addInquiry(Inquiry inquiry) async {
    try {
      await _firestore
          .collection('inquiries')
          .doc(inquiry.uid)
          .set(inquiry.toMap());
    } catch (e) {
      Logger.logError('Error adding inquiry', e);
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getUserReferrals(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('referrals')
          .where('referrerId', isEqualTo: userId)
          .get();

      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      Logger.logError('Error getting user referrals', e);
      return [];
    }
  }

  Future<List<UserModel>> getUsersByIds(List<String> userIds) async {
    try {
      if (userIds.isEmpty) return [];

      final snapshot = await _firestore
          .collection('users')
          .where(FieldPath.documentId,
              whereIn: userIds.take(10)) // Firestore limit
          .get();

      return snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
    } catch (e) {
      Logger.logError('Error getting users by IDs', e);
      return [];
    }
  }

  Future<String?> uploadIdentityDocumentBytes(
      Uint8List bytes, String userId) async {
    try {
      final fileName =
          '${userId}_identity_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storageRef = _storage.ref().child('identity_documents/$fileName');
      final snapshot = await storageRef.putData(bytes).whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      Logger.logError('Error uploading identity document', e);
      return null;
    }
  }

  Future<void> updateUserData(String uid, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(uid).update(data);
    } catch (e) {
      Logger.logError('Error updating user data', e);
      rethrow;
    }
  }

  // Helper alias to match older call sites
  Stream<List<QuoteModel>> streamQuotes(String rfqId) {
    return streamQuotesForRFQ(rfqId);
  }

  Future<void> rejectWithdrawal(String withdrawalId, String? reason) async {
    try {
      await _firestore.collection('withdrawals').doc(withdrawalId).update({
        'status': 'Rejected',
        if (reason != null && reason.isNotEmpty) 'rejectionReason': reason,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      Logger.logError('Error rejecting withdrawal', e);
      rethrow;
    }
  }
}

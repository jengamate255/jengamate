import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:jengamate/models/notification_model.dart';
import 'package:jengamate/models/rfq_model.dart';
import 'package:jengamate/models/user_model.dart';
import 'package:jengamate/models/order_model.dart';
import 'package:jengamate/models/invoice_model.dart';
import 'package:jengamate/models/withdrawal_model.dart';
import 'package:jengamate/models/commission_model.dart';
import 'package:jengamate/models/category_model.dart';
import 'package:jengamate/models/product_model.dart';
import 'package:jengamate/models/financial_transaction_model.dart';
import 'package:jengamate/models/commission_tier_model.dart';
import 'package:jengamate/models/content_report_model.dart';
import 'package:jengamate/models/audit_log_model.dart';
import 'package:jengamate/models/quote_model.dart';
import 'package:jengamate/models/chat_room_model.dart';
import 'package:jengamate/models/support_ticket_model.dart';
import 'package:jengamate/models/system_config_model.dart';
import 'package:jengamate/models/Inquiry_model.dart';
import 'package:jengamate/models/chat_message_model.dart';
import 'package:jengamate/models/payment_model.dart';
import 'package:jengamate/models/faq_model.dart';
import 'package:jengamate/models/enums/order_enums.dart';
import 'package:jengamate/utils/logger.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Notification Management
  Future<void> createNotification(NotificationModel notification) async {
    try {
      print('DEBUG: Creating notification: ${notification.uid}');
      print('DEBUG: Notification data: ${notification.toFirestore()}');
      await _firestore
          .collection('notifications')
          .doc(notification.uid)
          .set(notification.toFirestore());
      print('DEBUG: Notification created successfully');
    } catch (e) {
      Logger.logError('Error creating notification', e);
      rethrow;
    }
  }

  Stream<List<NotificationModel>> streamUserNotifications(String userId) {
    print('DEBUG: Streaming notifications for user: $userId');
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .handleError((error) {
      Logger.logError('Error in notifications stream', error);
    }).map((snapshot) {
      print('DEBUG: Found ${snapshot.docs.length} notifications');
      return snapshot.docs
          .map((doc) => NotificationModel.fromFirestore(doc))
          .toList();
    });
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
      print('DEBUG: Fetching user with ID: $uid');
      final doc = await _firestore.collection('users').doc(uid).get();
      print('DEBUG: User document exists: ${doc.exists}');
      if (doc.exists) {
        print('DEBUG: User data: ${doc.data()}');
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

  Stream<List<UserModel>> streamEnhancedUsers() {
    return _firestore.collection('users').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList());
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

  // Order Management
  Stream<List<OrderModel>> getOrders(String? userId) {
    try {
      Logger.log('Getting orders for user: $userId');
      Query query = _firestore.collection('orders');
      if (userId != null) {
        query = query.where('customerId', isEqualTo: userId);
      }
      return query
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
        Logger.log('Found ${snapshot.docs.length} orders');
        return snapshot.docs
            .map((doc) => OrderModel.fromFirestore(doc))
            .toList();
      });
    } catch (e) {
      Logger.logError('Error in getOrders stream', e);
      rethrow;
    }
  }

  Future<OrderModel?> getOrder(String orderId) async {
    try {
      final doc = await _firestore.collection('orders').doc(orderId).get();
      if (doc.exists) {
        return OrderModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      Logger.logError('Error getting order', e);
      rethrow;
    }
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      Logger.logError('Error updating order status', e);
      rethrow;
    }
  }

  Stream<List<PaymentModel>> streamOrderPayments(String orderId) {
    return _firestore
        .collection('payments')
        .where('orderId', isEqualTo: orderId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PaymentModel.fromFirestore(doc))
            .toList());
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

  Future<void> updateCommissionRules(List<CommissionModel> rules) async {
    try {
      final batch = _firestore.batch();
      for (final rule in rules) {
        final docRef = _firestore.collection('commission_rules').doc(rule.uid);
        batch.set(docRef, rule.toMap());
      }
      await batch.commit();
    } catch (e) {
      Logger.logError('Error updating commission rules', e);
      rethrow;
    }
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

      return {
        'totalUsers': usersSnapshot.docs.length,
        'totalOrders': ordersSnapshot.docs.length,
        'totalCommissions': commissionsSnapshot.docs.length,
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
        statusCounts[order.status] = (statusCounts[order.status] ?? 0) + 1;
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
        final monthKey =
            '${user.createdAt.year}-${user.createdAt.month.toString().padLeft(2, '0')}';
        usersByMonth[monthKey] = (usersByMonth[monthKey] ?? 0) + 1;
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

  Future<void> updateOrder(OrderModel order) async {
    try {
      await _firestore.collection('orders').doc(order.uid).set(order.toMap());
    } catch (e) {
      Logger.logError('Error updating order', e);
      rethrow;
    }
  }

  Future<void> createOrder(OrderModel order) async {
    try {
      await _firestore.collection('orders').doc(order.uid).set(order.toMap());
    } catch (e) {
      Logger.logError('Error creating order', e);
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

  Future<Map<String, dynamic>?> getProduct(String productId) async {
    try {
      final doc = await _firestore.collection('products').doc(productId).get();
      return doc.exists ? doc.data() as Map<String, dynamic> : null;
    } catch (e) {
      Logger.logError('Error getting product', e);
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getApprovedSuppliers() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'supplier')
          .where('isApproved', isEqualTo: true)
          .get();

      return snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
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

  Future<List<Map<String, dynamic>>> searchUsers(String query,
      {int limit = 20}) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThanOrEqualTo: query + '\uf8ff')
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
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

  Stream<List<Inquiry>> streamInquiriesForUser(String userId) {
    return _firestore
        .collection('inquiries')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Inquiry.fromFirestore(doc)).toList());
  }

  Future<void> createInquiry(Inquiry Inquiry) async {
    try {
      await _firestore
          .collection('inquiries')
          .doc(Inquiry.uid)
          .set(Inquiry.toMap());
    } catch (e) {
      Logger.logError('Error creating Inquiry', e);
      rethrow;
    }
  }

  Future<void> addMessage(ChatMessage message) async {
    try {
      await _firestore
          .collection('messages')
          .doc(message.uid)
          .set(message.toMap());
    } catch (e) {
      Logger.logError('Error adding message', e);
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

  Future<void> createPayment(PaymentModel payment) async {
    try {
      await _firestore
          .collection('payments')
          .doc(payment.uid)
          .set(payment.toMap());
    } catch (e) {
      Logger.logError('Error creating payment', e);
      rethrow;
    }
  }

  Future<List<PaymentModel>> getPaymentsForOrder(String orderId) async {
    try {
      final snapshot = await _firestore
          .collection('payments')
          .where('orderId', isEqualTo: orderId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => PaymentModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      Logger.logError('Error getting payments for order', e);
      rethrow;
    }
  }

  Future<String?> uploadPaymentProof(String paymentId, String filePath) async {
    try {
      // Implementation would depend on your storage solution
      // For now, return a placeholder URL
      return 'https://storage.example.com/payments/$paymentId/proof.jpg';
    } catch (e) {
      Logger.logError('Error uploading payment proof', e);
      return null;
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
}

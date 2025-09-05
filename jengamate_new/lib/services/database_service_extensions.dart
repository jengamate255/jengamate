import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jengamate/models/financial_transaction_model.dart';
import 'package:jengamate/models/support_ticket_model.dart';
import 'package:jengamate/models/faq_model.dart';
import 'package:jengamate/models/inquiry_model.dart';
import 'package:jengamate/models/chat_message_model.dart';
import 'package:jengamate/models/chat_room_model.dart';
import 'package:jengamate/models/payment_model.dart';
import 'package:jengamate/models/system_config_model.dart';
import 'package:jengamate/models/audit_log_model.dart';
import 'package:jengamate/models/commission_tier_model.dart';
import 'package:jengamate/models/content_report_model.dart';

extension DatabaseServiceExtensions on DatabaseService {
  // Financial Transactions
  Future<List<FinancialTransactionModel>> getPaginatedFinancialTransactions({
    int limit = 20,
    DocumentSnapshot? startAfter,
    String? userId,
  }) async {
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
  }

  // Support Tickets
  Future<List<SupportTicketModel>> getUserSupportTickets(String userId,
      {int limit = 50}) async {
    final snapshot = await _firestore
        .collection('support_tickets')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs
        .map((doc) => SupportTicketModel.fromFirestore(doc))
        .toList();
  }

  Future<void> createSupportTicket(SupportTicketModel ticket) async {
    await _firestore
        .collection('support_tickets')
        .doc(ticket.id)
        .set(ticket.toMap());
  }

  // FAQs
  Future<List<FAQItem>> getFAQs({String? category}) async {
    Query query = _firestore.collection('faqs').orderBy('order');

    if (category != null) {
      query = query.where('category', isEqualTo: category);
    }

    final snapshot = await query.get();
    return snapshot.docs.map((doc) => FAQItem.fromFirestore(doc)).toList();
  }

  Future<void> createFAQ(FAQItem faq) async {
    await _firestore.collection('faqs').doc(faq.id).set(faq.toMap());
  }

  // Inquiries
  Stream<List<Inquiry>> streamInquiries(String userId) {
    return _firestore
        .collection('inquiries')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Inquiry.fromFirestore(doc)).toList());
  }

  Future<void> createInquiry(Inquiry inquiry) async {
    await _firestore
        .collection('inquiries')
        .doc(inquiry.id)
        .set(inquiry.toMap());
  }

  // Chat Messages
  Future<void> addMessage(ChatMessageModel message) async {
    await _firestore
        .collection('messages')
        .doc(message.id)
        .set(message.toMap());
  }

  Stream<List<ChatMessageModel>> streamMessages(String chatRoomId) {
    return _firestore
        .collection('messages')
        .where('chatRoomId', isEqualTo: chatRoomId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatMessageModel.fromFirestore(doc))
            .toList());
  }

  // Chat Rooms
  Future<ChatRoomModel?> getChatRoom(String roomId) async {
    final doc = await _firestore.collection('chat_rooms').doc(roomId).get();
    if (doc.exists) {
      return ChatRoomModel.fromFirestore(doc);
    }
    return null;
  }

  Future<void> createChatRoom(ChatRoomModel room) async {
    await _firestore.collection('chat_rooms').doc(room.id).set(room.toMap());
  }

  // Payments
  Future<void> createPayment(PaymentModel payment) async {
    await _firestore
        .collection('payments')
        .doc(payment.id)
        .set(payment.toMap());
  }

  Future<List<PaymentModel>> getPaymentsForOrder(String orderId) async {
    final snapshot = await _firestore
        .collection('payments')
        .where('orderId', isEqualTo: orderId)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs.map((doc) => PaymentModel.fromFirestore(doc)).toList();
  }

  Future<String?> uploadPaymentProof(String paymentId, String filePath) async {
    // Implementation would depend on your storage solution
    // For now, return a placeholder URL
    return 'https://storage.example.com/payments/$paymentId/proof.jpg';
  }

  // System Configuration
  Future<SystemConfigModel?> getSystemConfig() async {
    final doc = await _firestore.collection('system_config').doc('main').get();
    if (doc.exists) {
      return SystemConfigModel.fromFirestore(doc);
    }
    return null;
  }

  Future<void> updateSystemConfig(SystemConfigModel config) async {
    await _firestore
        .collection('system_config')
        .doc('main')
        .set(config.toMap());
  }

  // Audit Logs
  Future<List<AuditLogModel>> getAuditLogs({int limit = 50}) async {
    final snapshot = await _firestore
        .collection('audit_logs')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs
        .map((doc) => AuditLogModel.fromFirestore(doc))
        .toList();
  }

  // Commission Tiers
  Future<List<CommissionTierModel>> getCommissionTiers() async {
    final snapshot =
        await _firestore.collection('commission_tiers').orderBy('level').get();

    return snapshot.docs
        .map((doc) => CommissionTierModel.fromFirestore(doc))
        .toList();
  }

  Future<void> createCommissionTier(CommissionTierModel tier) async {
    await _firestore
        .collection('commission_tiers')
        .doc(tier.id)
        .set(tier.toMap());
  }

  // Content Reports
  Future<List<ContentReportModel>> getContentReports(
      {String? status, int limit = 50}) async {
    Query query = _firestore
        .collection('content_reports')
        .orderBy('createdAt', descending: true)
        .limit(limit);

    if (status != null) {
      query = query.where('status', isEqualTo: status);
    }

    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) => ContentReportModel.fromFirestore(doc))
        .toList();
  }

  Future<void> createContentReport(ContentReportModel report) async {
    await _firestore
        .collection('content_reports')
        .doc(report.id)
        .set(report.toMap());
  }

  // User Search
  Future<List<Map<String, dynamic>>> searchUsers(String query,
      {int limit = 20}) async {
    final snapshot = await _firestore
        .collection('users')
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThanOrEqualTo: query + '\uf8ff')
        .limit(limit)
        .get();

    return snapshot.docs
        .map((doc) => doc.data() as Map<String, dynamic>)
        .toList();
  }

  // Orders
  Future<void> updateOrder(OrderModel order) async {
    await _firestore.collection('orders').doc(order.id).set(order.toMap());
  }

  Future<void> createOrder(OrderModel order) async {
    await _firestore.collection('orders').doc(order.id).set(order.toMap());
  }

  // Withdrawals
  Future<void> requestWithdrawal(Map<String, dynamic> withdrawal) async {
    await _firestore.collection('withdrawals').add(withdrawal);
  }

  // Products
  Future<void> addOrUpdateProduct(Map<String, dynamic> product) async {
    await _firestore.collection('products').doc(product['id']).set(product);
  }

  Future<Map<String, dynamic>?> getProduct(String productId) async {
    final doc = await _firestore.collection('products').doc(productId).get();
    return doc.exists ? doc.data() as Map<String, dynamic> : null;
  }

  // Suppliers
  Future<List<Map<String, dynamic>>> getApprovedSuppliers() async {
    final snapshot = await _firestore
        .collection('users')
        .where('role', isEqualTo: 'supplier')
        .where('isApproved', isEqualTo: true)
        .get();

    return snapshot.docs
        .map((doc) => doc.data() as Map<String, dynamic>)
        .toList();
  }

  // RFQ
  Future<void> createRFQ(Map<String, dynamic> rfq) async {
    await _firestore.collection('rfqs').add(rfq);
  }

  // Analytics
  Future<List<Map<String, dynamic>>> getSalesOverTime() async {
    final snapshot =
        await _firestore.collection('orders').orderBy('createdAt').get();

    return snapshot.docs
        .map((doc) => doc.data() as Map<String, dynamic>)
        .toList();
  }

  Future<Map<DateTime, double>> getSalesOverTime() async {
    final data = await getSalesOverTime();
    final Map<DateTime, double> result = {};

    for (var item in data) {
      final date = (item['createdAt'] as Timestamp).toDate();
      final day = DateTime(date.year, date.month, date.day);
      result[day] = (result[day] ?? 0) + (item['totalAmount'] ?? 0).toDouble();
    }

    return result;
  }

  // Categories
  Stream<List<CategoryModel>> getCategories() {
    return _firestore.collection('categories').orderBy('name').snapshots().map(
        (snapshot) => snapshot.docs
            .map((doc) => CategoryModel.fromFirestore(doc))
            .toList());
  }

  // Commission Rules
  Future<List<CommissionModel>> getCommissionRules() async {
    final snapshot = await _firestore
        .collection('commission_rules')
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => CommissionModel.fromFirestore(doc))
        .toList();
  }

  Future<void> updateCommissionRules(Map<String, dynamic> rules) async {
    await _firestore.collection('commission_rules').add(rules);
  }

  // Order Stats
  Stream<Map<String, dynamic>> streamOrderStats(String userId) {
    return _firestore
        .collection('orders')
        .where('customerId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final orders =
          snapshot.docs.map((doc) => OrderModel.fromFirestore(doc)).toList();
      final totalOrders = orders.length;
      final completedOrders =
          orders.where((order) => order.status == OrderStatus.completed).length;
      final totalSpent =
          orders.fold<double>(0, (sum, order) => sum + order.totalAmount);

      return {
        'totalOrders': totalOrders,
        'completedOrders': completedOrders,
        'totalSpent': totalSpent,
      };
    });
  }

  // Inquiries for User
  Stream<List<Inquiry>> streamInquiriesForUser(String userId) {
    return _firestore
        .collection('inquiries')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Inquiry.fromFirestore(doc)).toList());
  }
}

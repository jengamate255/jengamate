
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jengamate/utils/logger.dart';
import 'package:jengamate/models/category_model.dart';
import 'package:jengamate/models/chat_room_model.dart';
import 'package:jengamate/models/commission_model.dart';
import 'package:jengamate/models/content_moderation_model.dart';
import 'package:jengamate/models/enhanced_user.dart';
import 'package:jengamate/models/enums/payment_enums.dart';

import 'package:jengamate/models/financial_transaction_model.dart';
import 'package:jengamate/models/inquiry_model.dart';
import 'package:jengamate/models/message_model.dart';
import 'package:jengamate/models/order_model.dart';
import 'package:jengamate/models/payment_model.dart';
import 'package:jengamate/models/product_model.dart';
import 'package:jengamate/models/quote_model.dart';
import 'package:jengamate/models/rank_model.dart';
import 'package:jengamate/models/notification_model.dart';
import 'package:jengamate/models/referral_model.dart';
import 'package:jengamate/models/review_model.dart';
import 'package:jengamate/models/rfq_model.dart';
import 'package:jengamate/models/system_config_model.dart';
import 'package:jengamate/models/enums/order_enums.dart';
import 'package:jengamate/models/user_model.dart';
import 'package:jengamate/models/withdrawal_model.dart';
import 'package:jengamate/utils/logger.dart';


class DatabaseService {
  final FirebaseFirestore _firestore;

  DatabaseService({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;

  // Collections
  final String _usersCollection = 'users';
  final String _ordersCollection = 'orders';
  final String _paymentsCollection = 'payments';
  final String _transactionsCollection = 'financial_transactions';
  final String _messagesCollection = 'messages';
  final String _chatsCollection = 'chats';
  final String _rfqsCollection = 'rfqs';
  final String _inquiriesCollection = 'inquiries';
  final String _categoriesCollection = 'categories';
  final String _productsCollection = 'products';
  final String _quotesCollection = 'quotes';
  final String _withdrawalsCollection = 'withdrawals';
  final String _reviewsCollection = 'reviews';
  final String _userCommissionsCollection = 'user_commissions';
  final String _ranksCollection = 'ranks';
  final String _referralsCollection = 'referrals';
  final String _notificationsCollection = 'notifications';

  // Generic method for operations requiring validation
  Future<T> executeWithValidation<T>({
    required Future<T> Function() operation,
    required Future<void> Function() validation,
  }) async {
    try {
      await validation();
      return await operation();
    } catch (e) {
      // Log the validation or operation error
      Logger.logError('Operation failed: $e', e, StackTrace.current);
      rethrow; // Rethrow the exception to be handled by the caller
    }
  }

  Future<List<UserModel>> searchUsersByRole(String roleName, {int limit = 20}) async {
    try {
      final snapshot = await _firestore
          .collection(_usersCollection)
          .where('role', isEqualTo: roleName)
          .limit(limit)
          .get();
      return snapshot.docs.map((d) => UserModel.fromFirestore(d)).toList();
    } catch (e) {
      throw Exception('Failed to search users by role: $e');
    }
  }

  Future<List<UserModel>> searchUsers({required String roleName, String? nameQuery, int limit = 20}) async {
    final users = await searchUsersByRole(roleName, limit: limit);
    if (nameQuery == null || nameQuery.trim().isEmpty) return users;
    final q = nameQuery.trim().toLowerCase();
    return users.where((u) => u.displayName.toLowerCase().contains(q) || (u.email?.toLowerCase().contains(q) ?? false)).toList();
  }



  // Order Management
  Future<OrderModel> createOrder(OrderModel order) async {
    return executeWithValidation(
      operation: () async {
        final docRef =
            await _firestore.collection(_ordersCollection).add(order.toMap());
        return order.copyWith(id: docRef.id);
      },
      validation: () async {
        if (order.totalAmount <= 0) {
          throw Exception('Order total amount must be positive');
        }
        if (order.buyerId.isEmpty || order.supplierId.isEmpty) {
          throw Exception('Order must have both buyer and supplier');
        }
      },
    );
  }

  Future<ProductModel?> getProduct(String productId) async {
    try {
      final doc = await _firestore.collection('products').doc(productId).get();
      if (doc.exists) {
        return ProductModel.fromFirestore(doc);
      }
      return null;
    } catch (e, s) {
      Logger.logError('Failed to get product', e, s);
      return null;
    }
  }

  Future<OrderModel?> getOrder(String orderId) async {
    try {
      final doc =
          await _firestore.collection(_ordersCollection).doc(orderId).get();
      if (doc.exists) {
        return OrderModel.fromFirestore(doc);
      }
      return null;
    } catch (e, s) {
      Logger.logError('Failed to get user', e, s);
      return null;
    }
  }

  Future<OrderModel?> getOrderByID(String orderId) => getOrder(orderId);

  Future<String> uploadFile(Uint8List fileBytes, String path) async {
    // In a real app, this would use Firebase Storage or another cloud storage service.
    Logger.log('Simulating file upload to $path');
    await Future.delayed(const Duration(seconds: 2));
    return 'https://firebasestorage.googleapis.com/v0/b/example.appspot.com/o/files%2F$path?alt=media';
  }

  Stream<List<OrderModel>> getOrders(String? userId, {String? searchQuery, String? statusFilter}) {
    // This is a placeholder. A real implementation would fetch from Firestore.
    // Returning an empty stream to resolve compilation errors.
    return Stream.value([]);
  }

  Future<List<OrderModel>> getUserOrders(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_ordersCollection)
          .where('buyerId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();
      return querySnapshot.docs
          .map((doc) => OrderModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get user orders: $e');
    }
  }

  Future<OrderModel> updateOrder(OrderModel order) async {
    return executeWithValidation(
      operation: () async {
        await _firestore
            .collection(_ordersCollection)
            .doc(order.id)
            .update(order.toMap());
        return order;
      },
      validation: () async {
        final existingOrder = await getOrder(order.id);
        if (existingOrder == null) {
          throw Exception('Order not found');
        }
        if (existingOrder.isLocked) {
          throw Exception('Cannot update locked order');
        }
        if (order.totalAmount <= 0) {
          throw Exception('Order total amount must be positive');
        }
      },
    );
  }

  Future<void> lockOrder(String orderId) async {
    try {
      await _firestore
          .collection(_ordersCollection)
          .doc(orderId)
          .update({'isLocked': true});
    } catch (e) {
      throw Exception('Failed to lock order: $e');
    }
  }

  Future<void> unlockOrder(String orderId) async {
    try {
      await _firestore
          .collection(_ordersCollection)
          .doc(orderId)
          .update({'isLocked': false});
    } catch (e) {
      throw Exception('Failed to unlock order: $e');
    }
  }

  // Payment Management
  Future<void> validatePaymentIntegrity(PaymentModel payment) async {
    if (payment.amount <= 0) {
      throw Exception('Payment amount must be positive');
    }
    final order = await getOrder(payment.orderId);
    if (order == null) {
      throw Exception('Associated order not found');
    }
  }

  Future<PaymentModel> createPayment(PaymentModel payment) async {
    return executeWithValidation(
      operation: () async {
        final docRef = await _firestore
            .collection(_paymentsCollection)
            .add(payment.toMap());
        return payment.copyWith(id: docRef.id);
      },
      validation: () => validatePaymentIntegrity(payment),
    );
  }

  Future<PaymentModel?> getPayment(String paymentId) async {
    try {
      final doc =
          await _firestore.collection(_paymentsCollection).doc(paymentId).get();
      if (doc.exists) {
        return PaymentModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get payment: $e');
    }
  }

  Future<List<PaymentModel>> getOrderPayments(String orderId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_paymentsCollection)
          .where('orderId', isEqualTo: orderId)
          .orderBy('createdAt', descending: true)
          .get();
      return querySnapshot.docs
          .map((doc) => PaymentModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get order payments: $e');
    }
  }

  Stream<List<PaymentModel>> streamOrderPayments(String orderId) {
    // Placeholder implementation. A real implementation would listen to a stream from Firestore.
    return _firestore
        .collection(_paymentsCollection)
        .where('orderId', isEqualTo: orderId)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => PaymentModel.fromFirestore(doc)).toList());
  }

  Future<String> uploadPaymentProof(String filePath, String orderId) async {
    // Placeholder implementation. A real implementation would upload to Firebase Storage.
    Logger.log('Uploading payment proof for order $orderId from path $filePath');
    await Future.delayed(const Duration(seconds: 1)); // Simulate network delay
    return 'https://firebasestorage.googleapis.com/v0/b/example.appspot.com/o/proofs%2Fproof.jpg?alt=media';
  }

  Future<PaymentModel> updatePayment(PaymentModel payment) async {
    try {
      await _firestore
          .collection(_paymentsCollection)
          .doc(payment.id)
          .update(payment.toMap());
      return payment;
    } catch (e) {
      throw Exception('Failed to update payment: $e');
    }
  }



  Future<PaymentModel> verifyPayment(
      String paymentId, String verifiedBy) async {
    return executeWithValidation(
      operation: () async {
        final payment = await getPayment(paymentId);
        final updatedPayment = payment!.markAsVerified(verifiedBy);
        await updatePayment(updatedPayment);
        await _updateOrderStatusAfterPayment(updatedPayment.orderId);
        return updatedPayment;
      },
      validation: () async {
        final payment = await getPayment(paymentId);
        if (payment == null) {
          throw Exception('Payment not found');
        }
        if (payment.status != PaymentStatus.processing) {
          throw Exception('Payment is not in processing status');
        }
      },
    );
  }

  Future<PaymentModel> rejectPayment(String paymentId, String reason) async {
    return executeWithValidation(
      operation: () async {
        final payment = await getPayment(paymentId);
        final updatedPayment = payment!.markAsRejected(reason);
        await updatePayment(updatedPayment);
        return updatedPayment;
      },
      validation: () async {
        final payment = await getPayment(paymentId);
        if (payment == null) {
          throw Exception('Payment not found');
        }
        if (payment.status != PaymentStatus.processing) {
          throw Exception('Payment is not in processing status');
        }
      },
    );
  }

  Future<void> _updateOrderStatusAfterPayment(String orderId) async {
    try {
      final order = await getOrder(orderId);
      if (order == null) return;

      final payments = await getOrderPayments(orderId);
      final totalPaid = payments
          .where((p) => p.status == PaymentStatus.verified)
          .fold(0.0, (sum, payment) => sum + payment.amount);

      if (totalPaid >= order.totalAmount && order.status == OrderStatus.pending) {
        await this.updateOrder(order.copyWith(status: OrderStatus.completed));

        final commissionRules = await this.getCommissionRules();
        if (commissionRules != null) {
          final supplierCommissionAmount = order.totalAmount * (commissionRules.direct / 100);

          final supplierCommissionRecord = CommissionModel(
            id: '', // Firestore will generate this
            userId: order.supplierId,
            total: supplierCommissionAmount,
            direct: commissionRules.direct,
            referral: 0,
            active: 0,
            updatedAt: DateTime.now(),
            status: 'pending',
            minPayoutThreshold: commissionRules.minPayoutThreshold,
            metadata: {'orderId': orderId},
          );
          await this.addCommissionRecord(supplierCommissionRecord);
          Logger.log('Commission of $supplierCommissionAmount recorded for supplier ${order.supplierId}');
        }
      }
    } catch (e) {
      Logger.logError('Failed to update order status: $e', e, StackTrace.current);
    }
  }

  // Financial Transaction Management
  Stream<List<FinancialTransaction>> getFinancialTransactions() {
    return _firestore
        .collection(_transactionsCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => FinancialTransaction.fromFirestore(doc))
            .toList());
  }

  Future<List<FinancialTransaction>> getUserTransactions(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_transactionsCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('date', descending: true)
          .get();
      return querySnapshot.docs
          .map((doc) => FinancialTransaction.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get user transactions: $e');
    }
  }

  // Chat Management
  Future<void> addMessage(Message message) async {
    try {
      await _firestore
          .collection(_messagesCollection)
          .add(message.toFirestore());
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  Stream<List<Message>> streamMessages(String chatRoomId) {
    return _firestore
        .collection(_messagesCollection)
        .where('chatId', isEqualTo: chatRoomId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Message.fromFirestore(doc)).toList());
  }

  // User Management
  Future<void> updateUser(UserModel user) async {
    try {
      await _firestore
          .collection(_usersCollection)
          .doc(user.uid)
          .update(user.toMap());
    } catch (e, s) {
      Logger.logError('Failed to update user', e, s);
      rethrow;
    }
  }

  Future<UserModel?> getUser(String userId) async {
    try {
      final doc =
          await _firestore.collection(_usersCollection).doc(userId).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e, s) {
      Logger.logError('Failed to get user', e, s);
      return null;
    }
  }

  Future<UserModel?> getUserByEmail(String email) async {
    try {
      final querySnapshot = await _firestore
          .collection(_usersCollection)
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      if (querySnapshot.docs.isNotEmpty) {
        return UserModel.fromFirestore(querySnapshot.docs.first);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user by email: $e');
    }
  }

  Future<List<UserModel>> getUsersCreatedAfter(DateTime startDate) async {
    try {
      final querySnapshot = await _firestore
          .collection(_usersCollection)
          .where('createdAt', isGreaterThanOrEqualTo: startDate)
          .get();
      return querySnapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get users created after date: $e');
    }
  }

  Future<void> createUser(UserModel user) async {
    try {
      await _firestore
          .collection(_usersCollection)
          .doc(user.uid)
          .set(user.toMap());
    } catch (e, s) {
      Logger.logError('Failed to create user', e, s);
      rethrow;
    }
  }

  Stream<UserModel> streamUser(String userId) {
    return _firestore
        .collection(_usersCollection)
        .doc(userId)
        .snapshots()
        .map((snapshot) => UserModel.fromFirestore(snapshot));
  }

  Stream<List<EnhancedUser>> streamEnhancedUsers() {
    // Placeholder implementation that returns an empty stream.
    // TODO: Replace with actual implementation to stream users from Firestore.
    return Stream.value([]);
  }

  Future<void> updateEnhancedUser(EnhancedUser user) async {
    // Implementation for updating an enhanced user
  }

  Future<void> deleteUser(String userId) async {
    try {
      await _firestore.collection(_usersCollection).doc(userId).delete();
    } catch (e) {
      throw Exception('Failed to delete user: $e');
    }
  }

  Stream<List<UserModel>> streamAllUsers() {
    return _firestore
        .collection(_usersCollection)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList());
  }

  // RFQ Management
  Future<void> addRFQ(RFQModel rfq) async {
    try {
      await _firestore.collection(_rfqsCollection).add(rfq.toMap());
    } catch (e) {
      throw Exception('Failed to add RFQ: $e');
    }
  }

  Future<void> updateRFQStatus(String rfqId, String status) async {
    try {
      await _firestore.collection(_rfqsCollection).doc(rfqId).update({'status': status});
    } catch (e) {
      throw Exception('Failed to update RFQ status: $e');
    }
  }

  Future<void> createRFQ(RFQModel rfq) async {
    try {
      await _firestore.collection(_rfqsCollection).add(rfq.toMap());
    } catch (e) {
      throw Exception('Failed to create RFQ: $e');
    }
  }

  Stream<List<RFQModel>> streamUserRFQs(String userId) {
    return _firestore
        .collection(_rfqsCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => RFQModel.fromFirestore(doc)).toList());
  }

  Stream<List<RFQModel>> streamAllRFQs() {
    return _firestore
        .collection(_rfqsCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => RFQModel.fromFirestore(doc)).toList());
  }

  Future<RFQModel?> getRFQ(String rfqId) async {
    try {
      final doc = await _firestore.collection(_rfqsCollection).doc(rfqId).get();
      if (doc.exists) {
        return RFQModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get RFQ: $e');
    }
  }

  Future<void> updateRFQ(RFQModel rfq) async {
    try {
      await _firestore
          .collection(_rfqsCollection)
          .doc(rfq.id)
          .update(rfq.toMap());
    } catch (e) {
      throw Exception('Failed to update RFQ: $e');
    }
  }

  // Inquiry Management
  Future<void> addInquiry(InquiryModel inquiry) async {
    try {
      await _firestore.collection(_inquiriesCollection).add(inquiry.toMap());
    } catch (e) {
      throw Exception('Failed to add inquiry: $e');
    }
  }

  Stream<List<InquiryModel>> streamInquiries(String userId) {
    return _firestore
        .collection(_inquiriesCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => InquiryModel.fromFirestore(doc))
            .toList());
  }

  // Category Management
  Stream<List<CategoryModel>> getCategories() {
    // This is a placeholder. A real implementation would fetch from Firestore.
    // Returning an empty stream to resolve compilation errors.
    return Stream.value([]);
  }

  Stream<List<CategoryModel>> getSubCategories(String parentId) {
    // This is a placeholder. A real implementation would fetch from Firestore.
    // Returning an empty stream to resolve compilation errors.
    return Stream.value([]);
  }

  // Commission Management
  Stream<List<CommissionModel>> getAllCommissions() {
    // This is a placeholder. A real implementation would fetch from Firestore.
    // Returning an empty stream to resolve compilation errors.
    return Stream.value([]);
  }

  Future<void> updateCommissionRules(CommissionModel commission) async {
    // This is a placeholder. A real implementation would save to Firestore.
    // No-op to resolve compilation errors.
    await Future.delayed(const Duration(milliseconds: 100));
  }

  // Analytics
  Future<Map<DateTime, double>> getSalesOverTime() async {
    // This is a placeholder. A real implementation would fetch from Firestore.
    // Returning an empty map to resolve compilation errors.
    await Future.delayed(const Duration(milliseconds: 100)); // Simulate network delay
    return {};
  }

  Future<Map<String, int>> getOrderCountsByStatus() async {
    // This is a placeholder. A real implementation would fetch from Firestore.
    // Returning an empty map to resolve compilation errors.
    await Future.delayed(const Duration(milliseconds: 100)); // Simulate network delay
    return {};
  }

  Future<List<Map<String, dynamic>>> getTopSellingProducts(int limit) async {
    // This is a placeholder. A real implementation would fetch from Firestore.
    // Returning an empty list to resolve compilation errors.
    await Future.delayed(const Duration(milliseconds: 100)); // Simulate network delay
    return [];
  }

  // Product Management
  Future<void> addOrUpdateProduct(ProductModel product) async {
    try {
      if (product.id.isEmpty) {
        // Add new product and update its ID
        final docRef = await _firestore.collection(_productsCollection).add(product.toMap());
        await docRef.update({'id': docRef.id});
      } else {
        // Update existing product
        await _firestore.collection(_productsCollection).doc(product.id).update(product.toMap());
      }
    } catch (e) {
      throw Exception('Failed to save product: $e');
    }
  }

  // Category Management
  Future<void> addCategory(CategoryModel category) async {
    try {
      await _firestore.collection(_categoriesCollection).add(category.toMap());
    } catch (e) {
      throw Exception('Failed to add category: $e');
    }
  }

  Future<void> updateCategory(CategoryModel category) async {
    try {
      await _firestore
          .collection(_categoriesCollection)
          .doc(category.id)
          .update(category.toMap());
    } catch (e) {
      throw Exception('Failed to update category: $e');
    }
  }

  Future<void> deleteCategory(String categoryId) async {
    try {
      await _firestore.collection(_categoriesCollection).doc(categoryId).delete();
    } catch (e) {
      throw Exception('Failed to delete category: $e');
    }
  }

  Stream<List<CategoryModel>> streamCategories() {
    return _firestore
        .collection(_categoriesCollection)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CategoryModel.fromFirestore(doc))
            .toList());
  }

  // Quote Management
  Future<void> addQuote(QuoteModel quote) async {
    try {
      await _firestore.collection(_quotesCollection).add(quote.toMap());
    } catch (e) {
      throw Exception('Failed to add quote: $e');
    }
  }

  Stream<CommissionModel?> streamCommissionRules() {
    return _firestore
        .collection('config')
        .doc('commission')
        .snapshots()
        .map((doc) {
      if (doc.exists) {
        return CommissionModel.fromFirestore(doc);
      }
      return null;
    });
  }

  Future<CommissionModel?> getCommissionRules() async {
    final doc = await _firestore.collection('config').doc('commission').get();
    if (doc.exists) {
      return CommissionModel.fromFirestore(doc);
    }
    return null;
  }

  Future<void> setCommissionRules(CommissionModel rules) async {
    await _firestore.collection('config').doc('commission').set(rules.toMap());
  }

  // Content Moderation
    Future<void> addContentForModeration(ModerationItem item) async {
    try {
      await _firestore.collection('moderation_items').add(item.toMap());
    } catch (e) {
      throw Exception('Failed to add content for moderation: $e');
    }
  }



  Future<String?> getProductImage(String productId) async {
    try {
      final doc = await _firestore.collection('products').doc(productId).get();
      if (doc.exists) {
        return doc.data()?['imageUrl'] as String?;
      }
      return null;
    } catch (e) {
      Logger.logError('Error getting product image: $e', e, StackTrace.current);
      return null;
    }
  }

  Future<void> updateModerationStatus(String itemId, String status) async {
    try {
      await _firestore.collection('moderation_items').doc(itemId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update moderation status: $e');
    }
  }

  Stream<List<ModerationItem>> getModerationItems() {
    return _firestore
        .collection('moderation_items')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ModerationItem.fromFirestore(doc))
            .toList());
  }

  // Rank Management
  Future<void> addRank(RankModel rank) async {
    try {
      await _firestore.collection(_ranksCollection).add(rank.toMap());
    } catch (e) {
      throw Exception('Failed to add rank: $e');
    }
  }

  Future<void> updateRank(RankModel rank) async {
    try {
      await _firestore.collection(_ranksCollection).doc(rank.id).update(rank.toMap());
    } catch (e) {
      throw Exception('Failed to update rank: $e');
    }
  }

  Future<void> deleteRank(String rankId) async {
    try {
      await _firestore.collection(_ranksCollection).doc(rankId).delete();
    } catch (e) {
      throw Exception('Failed to delete rank: $e');
    }
  }

  Stream<List<RankModel>> streamRanks() {
    return _firestore.collection(_ranksCollection).orderBy('minimumReferrals').snapshots().map(
        (snapshot) => snapshot.docs
            .map((doc) => RankModel.fromFirestore(doc))
            .toList());
  }

  // Referral Management
  Future<void> addReferral(ReferralModel referral) async {
    try {
      await _firestore.collection(_referralsCollection).add(referral.toMap());
    } catch (e) {
      throw Exception('Failed to add referral: $e');
    }
  }

  Future<void> updateReferral(ReferralModel referral) async {
    try {
      await _firestore.collection(_referralsCollection).doc(referral.id).update(referral.toMap());
    } catch (e) {
      throw Exception('Failed to update referral: $e');
    }
  }

  Future<void> deleteReferral(String referralId) async {
    try {
      await _firestore.collection(_referralsCollection).doc(referralId).delete();
    } catch (e) {
      throw Exception('Failed to delete referral: $e');
    }
  }

  Stream<List<ReferralModel>> streamReferrals() {
    return _firestore.collection(_referralsCollection).orderBy('createdAt', descending: true).snapshots().map(
        (snapshot) => snapshot.docs
            .map((doc) => ReferralModel.fromFirestore(doc))
            .toList());
  }

  Stream<List<ReferralModel>> streamTrashedReferrals() {
    return _firestore.collection(_referralsCollection).where('status', isEqualTo: 'trashed').orderBy('createdAt', descending: true).snapshots().map(
        (snapshot) => snapshot.docs
            .map((doc) => ReferralModel.fromFirestore(doc))
            .toList());
  }

  // Identity verification methods
  Future<String> uploadIdentityDocument(Uint8List fileBytes, String userId) async {
    // This is a placeholder. In a real app, you would upload the file to secure storage
    // and return the URL. For now, we'll just return a dummy URL.
    Logger.log('Uploading identity document for user $userId...');
    // In a real implementation, you'd use a storage service like Firebase Storage or Cloudinary.
    // For example: return await _storageService.uploadFile(fileBytes, 'identity_documents/$userId');
    await Future.delayed(const Duration(seconds: 2)); // Simulate network delay
    return 'https://example.com/identity/$userId.jpg';
  }

  Future<void> updateUserData(String userId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection(_usersCollection).doc(userId).update(data);
    } catch (e) {
      throw Exception('Failed to update user data: $e');
    }
  }

  Future<void> deleteProducts(List<ProductModel> products) async {
    // Placeholder
    return Future.value();
  }

  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    // Placeholder
    return Future.value();
  }

  Stream<List<InquiryModel>> getUserInquiries(String? userId, String searchQuery) {
    // Placeholder
    return Stream.value([]);
  }

  Stream<List<InquiryModel>> streamAllInquiries() {
    return _firestore
        .collection(_inquiriesCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => InquiryModel.fromFirestore(doc))
            .toList());
  }

  Stream<Map<String, int>> streamOrderStats(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('stats')
        .doc('orders')
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        final data = snapshot.data()!;
        return {
          'pending': data['pending'] ?? 0,
          'processing': data['processing'] ?? 0,
          'shipped': data['shipped'] ?? 0,
          'delivered': data['delivered'] ?? 0,
          'cancelled': data['cancelled'] ?? 0,
        };
      } else {
        return {
          'pending': 0,
          'processing': 0,
          'shipped': 0,
          'delivered': 0,
          'cancelled': 0,
        };
      }
    });
  }

  Future<Map<String, dynamic>> getAdminAnalytics() async {
    try {
      final usersFuture = _firestore.collection(_usersCollection).count().get();
      final ordersFuture = _firestore.collection(_ordersCollection).count().get();
      final productsFuture = _firestore.collection(_productsCollection).count().get();
      final inquiriesFuture = _firestore.collection(_inquiriesCollection).count().get();

      final results = await Future.wait([
        usersFuture,
        ordersFuture,
        productsFuture,
        inquiriesFuture,
      ]);

      return {
        'totalUsers': results[0].count ?? 0,
        'totalOrders': results[1].count ?? 0,
        'totalProducts': results[2].count ?? 0,
        'totalInquiries': results[3].count ?? 0,
      };
    } catch (e, s) {
      Logger.logError('Failed to get admin analytics', e, s);
      return {};
    }
  }

  Future<Map<String, dynamic>> getWithdrawalStats() async {
    try {
      final snapshot = await _firestore.collection(_withdrawalsCollection).get();
      if (snapshot.docs.isEmpty) {
        return {
          'pending': 0,
          'approved': 0,
          'rejected': 0,
          'completed': 0,
          'totalAmount': 0.0,
        };
      }

      final stats = <String, int>{
        'pending': 0,
        'approved': 0,
        'rejected': 0,
        'completed': 0,
      };
      double totalAmount = 0.0;

      for (var doc in snapshot.docs) {
        final withdrawal = WithdrawalModel.fromFirestore(doc);
        stats[withdrawal.status] = (stats[withdrawal.status] ?? 0) + 1;
        if (withdrawal.status == 'completed') {
          totalAmount += withdrawal.amount;
        }
      }

      return {
        ...stats,
        'totalAmount': totalAmount,
      };
    } catch (e, s) {
      Logger.logError('Failed to get withdrawal stats', e, s);
      return {};
    }
  }

    Future<SystemConfig> getSystemConfig() async {
    final doc = await _firestore.collection('config').doc('system').get();
    if (doc.exists) {
      return SystemConfig.fromFirestore(doc);
    }
    // Return default config if not set
    return SystemConfig(
      commissionRate: 0.1,
      minimumWithdrawal: 50.0,
      maxRfqsPerDay: 5,
      requireApprovalForNewUsers: true,
    );
  }

    Future<void> updateSystemConfig(SystemConfig newConfig) async {
    // Placeholder
    return Future.value();
  }

  Future<void> rejectWithdrawal(String withdrawalId, String reason) async {
    // Placeholder
    return Future.value();
  }

  Stream<List<CommissionModel>> streamTrashedCommissions() {
    // Placeholder
    return Stream.value([]);
  }

    Future<void> createQuote(QuoteModel newQuote) async {
    // Placeholder
    return Future.value();
  }

  Future<void> sendQuoteSubmissionNotification(QuoteModel quote) async {
    // This is a placeholder. A real implementation would handle sending a notification.
    return Future.value();
  }

  Stream<List<ProductModel>> streamProducts({String? categoryId}) {
    Query query = _firestore.collection(_productsCollection);
    if (categoryId != null) {
      query = query.where('categoryId', isEqualTo: categoryId);
    }
    return query.snapshots().map((snapshot) => snapshot.docs
        .map((doc) => ProductModel.fromFirestore(doc))
        .toList());
  }

  Stream<List<InquiryModel>> streamInquiriesForUser(String userId) {
    return _firestore
        .collection(_inquiriesCollection)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => InquiryModel.fromFirestore(doc))
            .toList());
  }

  Stream<List<ChatRoomModel>> streamChatRoomsForUser(String userId) {
    return _firestore
        .collection(_chatsCollection)
        .where('userIds', arrayContains: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatRoomModel.fromFirestore(doc))
            .toList());
  }

  Future<List<UserModel>> getApprovedSuppliers() async {
    try {
      final snapshot = await _firestore
          .collection(_usersCollection)
          .where('role', isEqualTo: 'supplier')
          .where('isApproved', isEqualTo: true)
          .get();
      return snapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .toList();
    } catch (e, s) {
      Logger.logError('Error getting approved suppliers', e, s);
      return [];
    }
  }

  // Commission Records
  Future<void> addCommissionRecord(CommissionModel commission) async {
    await _firestore.collection(_userCommissionsCollection).add(commission.toMap());
  }

  Future<void> addCommissionRecordValidated(CommissionModel commission) async {
    // Ensure the recipient exists and is supplier or engineer
    final user = await getUser(commission.userId);
    if (user == null) {
      throw Exception('Recipient user not found');
    }
    final role = user.role;
    final allowed = role.toString().endsWith('engineer') || role.toString().endsWith('supplier');
    if (!allowed) {
      throw Exception('Only suppliers or engineers can receive commissions');
    }
    await addCommissionRecord(commission);
  }

  Stream<List<CommissionModel>> streamUserCommissions(String userId) {
    return _firestore
        .collection(_userCommissionsCollection)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CommissionModel.fromFirestore(doc))
            .toList());
  }

  Future<void> updateCommissionRecord(String commissionId, Map<String, dynamic> updates) async {
    try {
      updates['updatedAt'] = FieldValue.serverTimestamp();
      await _firestore.collection(_userCommissionsCollection).doc(commissionId).update(updates);
    } catch (e, s) {
      Logger.logError('Failed to update commission', e, s);
      rethrow;
    }
  }

  Future<void> deleteCommissionRecord(String commissionId) async {
    try {
      await _firestore.collection(_userCommissionsCollection).doc(commissionId).delete();
    } catch (e, s) {
      Logger.logError('Failed to delete commission', e, s);
      rethrow;
    }
  }

  // Withdrawals
  Stream<List<WithdrawalModel>> streamWithdrawals(String userId) {
    return _firestore
        .collection(_withdrawalsCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => WithdrawalModel.fromFirestore(doc))
            .toList());
  }

  // Quotes
  Stream<List<QuoteModel>> streamQuotes(String rfqId) {
    return _firestore
        .collection(_quotesCollection)
        .where('rfqId', isEqualTo: rfqId)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => QuoteModel.fromFirestore(doc)).toList());
  }

  // Review Management
  Future<void> addReview(ReviewModel review) async {
    try {
      await _firestore.collection(_reviewsCollection).add(review.toMap());
    } catch (e) {
      throw Exception('Failed to add review: $e');
    }
  }

  // Withdrawal Management
  Future<void> requestWithdrawal(WithdrawalModel withdrawal) async {
    try {
      await _firestore.collection(_withdrawalsCollection).add(withdrawal.toMap());
    } catch (e) {
      throw Exception('Failed to request withdrawal: $e');
    }
  }

  Future<void> updateWithdrawalStatus(String withdrawalId, String newStatus) async {
    try {
      await _firestore.collection(_withdrawalsCollection).doc(withdrawalId).update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update withdrawal status: $e');
    }
  }

  // Notification Management
  Future<void> createNotification(NotificationModel notification) async {
    try {
      await _firestore
          .collection(_notificationsCollection)
          .doc(notification.id)
          .set(notification.toMap());
    } catch (e, s) {
      Logger.logError('Error creating notification', e, s);
      throw Exception('Failed to create notification: $e');
    }
  }

  Stream<List<NotificationModel>> streamUserNotifications(String userId) {
    return _firestore
        .collection(_notificationsCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NotificationModel.fromMap(doc.data(), doc.id))
            .toList());
  }

}

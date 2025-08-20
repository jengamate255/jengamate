
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
import 'package:jengamate/models/support_ticket_model.dart';
import 'package:jengamate/models/system_config_model.dart';
import 'package:jengamate/models/enums/order_enums.dart';
import 'package:jengamate/models/user_model.dart';
import 'package:jengamate/models/withdrawal_model.dart';
import 'package:jengamate/services/notification_service.dart';
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
  final String _commissionsCollection = 'commissions';
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
        final createdOrder = order.copyWith(id: docRef.id);

        // Create audit log for order creation
        try {
          await createAuditLog(
            actorId: order.buyerId,
            actorName: 'User', // This could be enhanced to get actual user name
            targetUserId: order.buyerId,
            targetUserName: 'User',
            action: 'create',
            details: {
              'resource': 'order',
              'resourceId': docRef.id,
              'message': 'Created new order for \$${order.totalAmount.toStringAsFixed(2)}',
              'orderNumber': order.orderNumber,
              'supplierId': order.supplierId,
              'totalAmount': order.totalAmount,
            },
          );
        } catch (e) {
          // Don't fail order creation if audit logging fails
          Logger.logError('Failed to create order audit log', e, StackTrace.current);
        }

        return createdOrder;
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
        final createdPayment = payment.copyWith(id: docRef.id);

        // Create audit log for payment creation
        try {
          await createAuditLog(
            actorId: payment.userId,
            actorName: 'User', // This could be enhanced to get actual user name
            targetUserId: payment.userId,
            targetUserName: 'User',
            action: 'payment',
            details: {
              'resource': 'payment',
              'resourceId': docRef.id,
              'message': 'Payment of \$${payment.amount.toStringAsFixed(2)} processed via ${payment.method.toString().split('.').last}',
              'orderId': payment.orderId,
              'amount': payment.amount,
              'method': payment.method.toString().split('.').last,
              'status': payment.status.toString().split('.').last,
            },
          );
        } catch (e) {
          // Don't fail payment creation if audit logging fails
          Logger.logError('Failed to create payment audit log', e, StackTrace.current);
        }

        return createdPayment;
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
    try {
      return _firestore
          .collection(_usersCollection)
          .snapshots()
          .asyncMap((snapshot) async {
        final List<EnhancedUser> enhancedUsers = [];

        for (var doc in snapshot.docs) {
          try {
            final data = doc.data() as Map<String, dynamic>? ?? {};

            // Get additional user statistics for metadata
            final ordersCount = await _firestore
                .collection(_ordersCollection)
                .where('buyerId', isEqualTo: doc.id)
                .count()
                .get();

            final commissionsSnapshot = await _firestore
                .collection(_commissionsCollection)
                .where('userId', isEqualTo: doc.id)
                .get();

            double totalCommissions = 0.0;
            for (var commissionDoc in commissionsSnapshot.docs) {
              final commission = CommissionModel.fromFirestore(commissionDoc);
              totalCommissions += commission.total;
            }

            // Add statistics to metadata
            final enhancedMetadata = Map<String, dynamic>.from(data['metadata'] ?? {});
            enhancedMetadata['ordersCount'] = ordersCount.count ?? 0;
            enhancedMetadata['totalCommissions'] = totalCommissions;

            enhancedUsers.add(EnhancedUser(
              uid: doc.id,
              email: data['email'] ?? '',
              displayName: data['displayName'] ?? '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}'.trim(),
              phoneNumber: data['phoneNumber'],
              photoURL: data['photoUrl'],
              emailVerified: data['emailVerified'] ?? false,
              phoneVerified: data['phoneVerified'] ?? false,
              roles: List<String>.from(data['roles'] ?? [data['role'] ?? 'user']),
              permissions: Map<String, dynamic>.from(data['permissions'] ?? {}),
              metadata: enhancedMetadata,
              createdAt: data['createdAt']?.toDate() ?? DateTime.now(),
              updatedAt: data['updatedAt']?.toDate() ?? DateTime.now(),
              lastLoginAt: data['lastLogin']?.toDate(),
              isActive: data['isApproved'] ?? false,
              address: data['address'],
            ));
          } catch (e) {
            Logger.logError('Error processing enhanced user', e, StackTrace.current);
          }
        }

        return enhancedUsers;
      });
    } catch (e, s) {
      Logger.logError('Error streaming enhanced users', e, s);
      return Stream.value([]);
    }
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
    try {
      return _firestore
          .collection(_categoriesCollection)
          .orderBy('name')
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => CategoryModel.fromFirestore(doc))
              .toList());
    } catch (e, s) {
      Logger.logError('Error getting categories', e, s);
      return Stream.value([]);
    }
  }

  Stream<List<CategoryModel>> getSubCategories(String parentId) {
    try {
      return _firestore
          .collection(_categoriesCollection)
          .where('parentId', isEqualTo: parentId)
          .orderBy('name')
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => CategoryModel.fromFirestore(doc))
              .toList());
    } catch (e, s) {
      Logger.logError('Error getting subcategories', e, s);
      return Stream.value([]);
    }
  }

  // Commission Management
  Stream<List<CommissionModel>> getAllCommissions() {
    try {
      return _firestore
          .collection(_commissionsCollection)
          .orderBy('updatedAt', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => CommissionModel.fromFirestore(doc))
              .toList());
    } catch (e, s) {
      Logger.logError('Error getting all commissions', e, s);
      return Stream.value([]);
    }
  }

  Future<void> updateCommissionRulesModel(CommissionModel commission) async {
    try {
      await _firestore
          .collection('commission_rules')
          .doc('global')
          .set(commission.toMap(), SetOptions(merge: true));
      Logger.log('Commission rules updated successfully');
    } catch (e, s) {
      Logger.logError('Error updating commission rules', e, s);
      throw Exception('Failed to update commission rules: $e');
    }
  }

  Future<void> updateCommissionRules({
    required double commissionRate,
    required double minPayoutThreshold,
  }) async {
    try {
      await _firestore
          .collection('commission_rules')
          .doc('global')
          .set({
        'commissionRate': commissionRate,
        'minPayoutThreshold': minPayoutThreshold,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      Logger.log('Commission settings updated successfully');
    } catch (e, s) {
      Logger.logError('Error updating commission settings', e, s);
      throw Exception('Failed to update commission settings: $e');
    }
  }

  // Analytics
  Future<Map<DateTime, double>> getSalesOverTime() async {
    try {
      final now = DateTime.now();
      final thirtyDaysAgo = now.subtract(const Duration(days: 30));

      final snapshot = await _firestore
          .collection(_ordersCollection)
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(thirtyDaysAgo))
          .where('status', isEqualTo: 'completed')
          .get();

      final salesData = <DateTime, double>{};

      for (var doc in snapshot.docs) {
        final order = OrderModel.fromFirestore(doc);
        final date = DateTime(
          order.createdAt.year,
          order.createdAt.month,
          order.createdAt.day,
        );
        salesData[date] = (salesData[date] ?? 0.0) + order.totalAmount;
      }

      return salesData;
    } catch (e, s) {
      Logger.logError('Error getting sales over time', e, s);
      return {};
    }
  }

  Future<Map<String, int>> getOrderCountsByStatus() async {
    try {
      final snapshot = await _firestore.collection(_ordersCollection).get();
      final statusCounts = <String, int>{};

      for (var doc in snapshot.docs) {
        final order = OrderModel.fromFirestore(doc);
        final status = order.status.toString().split('.').last;
        statusCounts[status] = (statusCounts[status] ?? 0) + 1;
      }

      return statusCounts;
    } catch (e, s) {
      Logger.logError('Error getting order counts by status', e, s);
      return {};
    }
  }

  Future<List<Map<String, dynamic>>> getTopSellingProducts(int limit) async {
    try {
      final snapshot = await _firestore
          .collection(_ordersCollection)
          .where('status', isEqualTo: 'completed')
          .get();

      final productSales = <String, Map<String, dynamic>>{};

      for (var doc in snapshot.docs) {
        final order = OrderModel.fromFirestore(doc);
        // Use rfqId as product identifier since OrderModel doesn't have productId
        final productId = order.rfqId ?? 'unknown';

        if (productSales.containsKey(productId)) {
          productSales[productId]!['quantity'] += 1;
          productSales[productId]!['totalSales'] += order.totalAmount;
        } else {
          productSales[productId] = {
            'productId': productId,
            'quantity': 1,
            'totalSales': order.totalAmount,
          };
        }
      }

      // Sort by quantity and return top products
      final sortedProducts = productSales.values.toList()
        ..sort((a, b) => (b['quantity'] as int).compareTo(a['quantity'] as int));

      return sortedProducts.take(limit).toList();
    } catch (e, s) {
      Logger.logError('Error getting top selling products', e, s);
      return [];
    }
  }

  Future<Map<DateTime, int>> getUserGrowthOverTime() async {
    try {
      final now = DateTime.now();
      final thirtyDaysAgo = now.subtract(const Duration(days: 30));

      final snapshot = await _firestore
          .collection(_usersCollection)
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(thirtyDaysAgo))
          .get();

      final userGrowthData = <DateTime, int>{};

      for (var doc in snapshot.docs) {
        final user = UserModel.fromFirestore(doc);
        final createdAt = user.createdAt ?? DateTime.now();
        final date = DateTime(
          createdAt.year,
          createdAt.month,
          createdAt.day,
        );
        userGrowthData[date] = (userGrowthData[date] ?? 0) + 1;
      }

      return userGrowthData;
    } catch (e, s) {
      Logger.logError('Error getting user growth over time', e, s);
      return {};
    }
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

  Future<ProductModel?> getProduct(String productId) async {
    try {
      final doc = await _firestore.collection(_productsCollection).doc(productId).get();
      if (doc.exists) {
        return ProductModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get product: $e');
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

      // Calculate total revenue from completed orders
      double totalRevenue = 0.0;
      try {
        final completedOrdersSnapshot = await _firestore
            .collection(_ordersCollection)
            .where('status', isEqualTo: 'completed')
            .get();

        for (var doc in completedOrdersSnapshot.docs) {
          final order = OrderModel.fromFirestore(doc);
          totalRevenue += order.totalAmount;
        }
      } catch (e) {
        Logger.logError('Error calculating total revenue', e, StackTrace.current);
      }

      return {
        'totalUsers': results[0].count ?? 0,
        'totalOrders': results[1].count ?? 0,
        'totalProducts': results[2].count ?? 0,
        'totalInquiries': results[3].count ?? 0,
        'totalRevenue': totalRevenue,
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
    try {
      await _firestore
          .collection('config')
          .doc('system')
          .set(newConfig.toMap(), SetOptions(merge: true));
      Logger.log('System config updated successfully');
    } catch (e, s) {
      Logger.logError('Error updating system config', e, s);
      throw Exception('Failed to update system config: $e');
    }
  }

  Future<void> rejectWithdrawal(String withdrawalId, String reason) async {
    try {
      await _firestore
          .collection(_withdrawalsCollection)
          .doc(withdrawalId)
          .update({
        'status': 'rejected',
        'rejectionReason': reason,
        'rejectedAt': FieldValue.serverTimestamp(),
      });
      Logger.log('Withdrawal $withdrawalId rejected');
    } catch (e, s) {
      Logger.logError('Error rejecting withdrawal', e, s);
      throw Exception('Failed to reject withdrawal: $e');
    }
  }

  Stream<List<CommissionModel>> streamTrashedCommissions() {
    try {
      return _firestore
          .collection(_userCommissionsCollection)
          .where('isDeleted', isEqualTo: true)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => CommissionModel.fromFirestore(doc))
              .toList());
    } catch (e, s) {
      Logger.logError('Error streaming trashed commissions', e, s);
      return Stream.value([]);
    }
  }

    Future<void> createQuote(QuoteModel newQuote) async {
    try {
      await _firestore
          .collection('quotes')
          .add(newQuote.toMap());
      Logger.log('Quote created successfully');
    } catch (e, s) {
      Logger.logError('Error creating quote', e, s);
      throw Exception('Failed to create quote: $e');
    }
  }

  Future<void> sendQuoteSubmissionNotification(QuoteModel quote) async {
    try {
      // Get the RFQ to find the customer
      final rfq = await getRFQ(quote.rfqId);
      if (rfq == null) return;

      // Create notification for the customer
      final notification = NotificationModel(
        id: _firestore.collection(_notificationsCollection).doc().id,
        userId: rfq.userId,
        title: 'New Quote Received',
        message: 'You have received a new quote for your RFQ: ${rfq.productName}',
        type: 'quote',
        relatedId: quote.id,
        createdAt: DateTime.now(),
        timestamp: DateTime.now(),
      );

      await createNotification(notification);

      // Send push notification if available
      final notificationService = NotificationService();
      await notificationService.showNotification(
        title: notification.title,
        body: notification.message,
        payload: 'quote/${quote.id}',
      );
    } catch (e, s) {
      Logger.logError('Error sending quote submission notification', e, s);
    }
  }

  // Content Moderation
  Future<List<Map<String, dynamic>>> getContentReports({String? status}) async {
    try {
      Query query = _firestore.collection('content_reports');

      if (status != null) {
        query = query.where('status', isEqualTo: status);
      }

      final snapshot = await query.orderBy('createdAt', descending: true).get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e, s) {
      Logger.logError('Error getting content reports', e, s);
      return [];
    }
  }

  Future<void> updateContentReportStatus(String reportId, String status, {String? moderatorNotes}) async {
    try {
      final updateData = {
        'status': status,
        'reviewedAt': FieldValue.serverTimestamp(),
      };

      if (moderatorNotes != null) {
        updateData['moderatorNotes'] = moderatorNotes;
      }

      await _firestore
          .collection('content_reports')
          .doc(reportId)
          .update(updateData);

      Logger.log('Content report $reportId status updated to $status');
    } catch (e, s) {
      Logger.logError('Error updating content report status', e, s);
      throw Exception('Failed to update content report: $e');
    }
  }

  // Commission Tiers
  Future<List<Map<String, dynamic>>> getCommissionTiers() async {
    try {
      final snapshot = await _firestore
          .collection('commission_tiers')
          .orderBy('level')
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e, s) {
      Logger.logError('Error getting commission tiers', e, s);
      return [];
    }
  }

  Future<List<UserModel>> getUsersWithTierInfo() async {
    try {
      final snapshot = await _firestore
          .collection(_usersCollection)
          .where('isApproved', isEqualTo: true)
          .get();

      return snapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .toList();
    } catch (e, s) {
      Logger.logError('Error getting users with tier info', e, s);
      return [];
    }
  }

  Future<void> createCommissionTier(Map<String, dynamic> tierData) async {
    try {
      await _firestore.collection('commission_tiers').add(tierData);
      Logger.log('Commission tier created successfully');
    } catch (e, s) {
      Logger.logError('Error creating commission tier', e, s);
      throw Exception('Failed to create commission tier: $e');
    }
  }

  Future<void> updateCommissionTier(String tierId, Map<String, dynamic> tierData) async {
    try {
      await _firestore
          .collection('commission_tiers')
          .doc(tierId)
          .update(tierData);
      Logger.log('Commission tier $tierId updated successfully');
    } catch (e, s) {
      Logger.logError('Error updating commission tier', e, s);
      throw Exception('Failed to update commission tier: $e');
    }
  }

  // Referral Management
  Future<List<Map<String, dynamic>>> getUserReferrals(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('referrals')
          .where('referrerId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e, s) {
      Logger.logError('Error getting user referrals', e, s);
      return [];
    }
  }

  Future<List<UserModel>> getUsersByIds(List<String> userIds) async {
    try {
      if (userIds.isEmpty) return [];

      final users = <UserModel>[];

      // Firestore 'in' queries are limited to 10 items, so we batch them
      for (int i = 0; i < userIds.length; i += 10) {
        final batch = userIds.skip(i).take(10).toList();
        final snapshot = await _firestore
            .collection(_usersCollection)
            .where(FieldPath.documentId, whereIn: batch)
            .get();

        users.addAll(snapshot.docs.map((doc) => UserModel.fromFirestore(doc)));
      }

      return users;
    } catch (e, s) {
      Logger.logError('Error getting users by IDs', e, s);
      return [];
    }
  }

  Future<void> createReferral({
    required String referrerId,
    required String referredUserId,
    required String referredUserName,
    required String referredUserEmail,
    double bonusAmount = 0.0,
  }) async {
    try {
      await _firestore.collection('referrals').add({
        'referrerId': referrerId,
        'referredUserId': referredUserId,
        'referredUserName': referredUserName,
        'referredUserEmail': referredUserEmail,
        'status': 'pending',
        'bonusAmount': bonusAmount,
        'createdAt': FieldValue.serverTimestamp(),
      });
      Logger.log('Referral created successfully');
    } catch (e, s) {
      Logger.logError('Error creating referral', e, s);
      throw Exception('Failed to create referral: $e');
    }
  }

  // Audit Logs
  Future<List<Map<String, dynamic>>> getAuditLogs({int limit = 100}) async {
    try {
      final snapshot = await _firestore
          .collection('audit_logs')
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e, s) {
      Logger.logError('Error getting audit logs', e, s);
      return [];
    }
  }

  Future<void> createAuditLog({
    required String actorId,
    required String actorName,
    required String targetUserId,
    required String targetUserName,
    required String action,
    Map<String, dynamic>? details,
  }) async {
    try {
      await _firestore.collection('audit_logs').add({
        'actorId': actorId,
        'actorName': actorName,
        'targetUserId': targetUserId,
        'targetUserName': targetUserName,
        'action': action,
        'details': details ?? {},
        'timestamp': FieldValue.serverTimestamp(),
      });
      Logger.log('Audit log created for action: $action');
    } catch (e, s) {
      Logger.logError('Error creating audit log', e, s);
      // Don't throw exception for audit logs to avoid breaking main functionality
    }
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

  // Support Ticket Management
  Future<List<SupportTicket>> getAllSupportTickets() async {
    try {
      final snapshot = await _firestore
          .collection('support_tickets')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return SupportTicket.fromMap(data, doc.id);
      }).toList();
    } catch (e, s) {
      Logger.logError('Error getting all support tickets', e, s);
      return [];
    }
  }

  Future<List<SupportTicket>> getUserSupportTickets(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('support_tickets')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return SupportTicket.fromMap(data, doc.id);
      }).toList();
    } catch (e, s) {
      Logger.logError('Error getting user support tickets', e, s);
      return [];
    }
  }

  Future<void> createSupportTicket(SupportTicket ticket) async {
    try {
      await _firestore.collection('support_tickets').add(ticket.toMap());
      Logger.log('Support ticket created successfully');
    } catch (e, s) {
      Logger.logError('Error creating support ticket', e, s);
      throw Exception('Failed to create support ticket: $e');
    }
  }

  Future<void> updateSupportTicketStatus(String ticketId, String status) async {
    try {
      await _firestore
          .collection('support_tickets')
          .doc(ticketId)
          .update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      Logger.log('Support ticket $ticketId status updated to $status');
    } catch (e, s) {
      Logger.logError('Error updating support ticket status', e, s);
      throw Exception('Failed to update support ticket: $e');
    }
  }

  // FAQ Management
  Future<List<FAQItem>> getFAQs() async {
    try {
      final snapshot = await _firestore
          .collection('faqs')
          .orderBy('isPopular', descending: true)
          .orderBy('question')
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return FAQItem.fromMap(data, doc.id);
      }).toList();
    } catch (e, s) {
      Logger.logError('Error getting FAQs', e, s);
      return [];
    }
  }

  Future<void> createFAQ(FAQItem faq) async {
    try {
      await _firestore.collection('faqs').add(faq.toMap());
      Logger.log('FAQ created successfully');
    } catch (e, s) {
      Logger.logError('Error creating FAQ', e, s);
      throw Exception('Failed to create FAQ: $e');
    }
  }

  Future<void> updateFAQ(FAQItem faq) async {
    try {
      await _firestore
          .collection('faqs')
          .doc(faq.id)
          .update(faq.toMap());
      Logger.log('FAQ ${faq.id} updated successfully');
    } catch (e, s) {
      Logger.logError('Error updating FAQ', e, s);
      throw Exception('Failed to update FAQ: $e');
    }
  }

  Future<void> deleteFAQ(String faqId) async {
    try {
      await _firestore.collection('faqs').doc(faqId).delete();
      Logger.log('FAQ $faqId deleted successfully');
    } catch (e, s) {
      Logger.logError('Error deleting FAQ', e, s);
      throw Exception('Failed to delete FAQ: $e');
    }
  }

}

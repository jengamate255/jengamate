import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jengamate/models/payment_model.dart';
import 'package:jengamate/models/enums/payment_enums.dart';
import 'package:jengamate/models/order_model.dart';
import 'package:jengamate/services/admin_notification_service.dart';
import 'package:jengamate/services/payment_service.dart';
import 'package:jengamate/utils/logger.dart';

class PaymentApprovalService {
  static final PaymentApprovalService _instance = PaymentApprovalService._internal();
  factory PaymentApprovalService() => _instance;

  PaymentApprovalService._internal() {
    _initializeAutomatedWorkflow();
  }

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AdminNotificationService _notificationService = AdminNotificationService();
  final PaymentService _paymentService = PaymentService();

  Timer? _automatedCheckTimer;
  StreamSubscription<QuerySnapshot>? _newPaymentsSubscription;

  void _initializeAutomatedWorkflow() {
    // Check for new payments every 5 minutes
    _automatedCheckTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      _processAutomatedApprovals();
      _checkStalePayments();
    });

    // Listen to new payments for immediate processing
    _newPaymentsSubscription = _firestore
        .collection('payments')
        .where('status', isEqualTo: PaymentStatus.pending.name)
        .where('createdAt', isGreaterThan: Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 24))))
        .snapshots()
        .listen(_handleNewPayment);

    Logger.log('Payment approval service initialized');
  }

  Future<void> _handleNewPayment(QuerySnapshot snapshot) async {
    for (var docChange in snapshot.docChanges) {
      if (docChange.type == DocumentChangeType.added) {
        final payment = PaymentModel.fromMap(docChange.doc.data() as Map<String, dynamic>);
        await _processNewPayment(payment);
      }
    }
  }

  Future<void> _processNewPayment(PaymentModel payment) async {
    try {
      // Check if payment meets auto-approval criteria
      if (await _shouldAutoApprove(payment)) {
        await _autoApprovePayment(payment);
      } else {
        // Move to manual approval queue
        await _moveToManualApproval(payment);
      }
    } catch (e) {
      Logger.logError('Failed to process new payment', e, StackTrace.current);
    }
  }

  Future<bool> _shouldAutoApprove(PaymentModel payment) async {
    try {
      // Auto-approve criteria:
      // 1. Amount is below threshold (e.g., $100)
      if (payment.amount > 100.0) return false;

      // 2. Payment method is trusted
      final trustedMethods = ['mpesa', 'creditCard', 'bankTransfer'];
      if (!trustedMethods.contains(payment.paymentMethod.toLowerCase())) return false;

      // 3. User has good payment history (no failed payments in last 30 days)
      final userPayments = await _firestore
          .collection('payments')
          .where('userId', isEqualTo: payment.userId)
          .where('createdAt', isGreaterThan: Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 30))))
          .get();

      final failedPayments = userPayments.docs
          .where((doc) => PaymentModel.fromMap(doc.data()).status == PaymentStatus.failed)
          .length;

      if (failedPayments > 0) return false;

      // 4. Order exists and is valid
      final orderDoc = await _firestore.collection('orders').doc(payment.orderId).get();
      if (!orderDoc.exists) return false;

      final order = OrderModel.fromFirestore(orderDoc.data() as Map<String, dynamic>, docId: orderDoc.id);
      if (order.status != 'confirmed') return false;

      return true;
    } catch (e) {
      Logger.logError('Error checking auto-approval criteria', e, StackTrace.current);
      return false;
    }
  }

  Future<void> _autoApprovePayment(PaymentModel payment) async {
    try {
      // Update payment status
      await _firestore.collection('payments').doc(payment.id).update({
        'status': PaymentStatus.approved.name,
        'updatedAt': FieldValue.serverTimestamp(),
        'autoApproved': true,
        'approvedAt': FieldValue.serverTimestamp(),
      });

      // Process the payment
      await _paymentService.updatePaymentStatus(payment.id, PaymentStatus.completed);

      // Send notification
      await _notificationService.createNotification(
        title: 'Payment Auto-Approved',
        message: 'Payment #${payment.id.substring(0, 8)} for \$${payment.amount.toStringAsFixed(2)} was automatically approved',
        type: NotificationType.success,
        priority: NotificationPriority.low,
        category: 'auto_approval',
        data: {'paymentId': payment.id, 'autoApproved': true},
        broadcastToAllAdmins: true,
      );

      Logger.log('Payment auto-approved: ${payment.id}');
    } catch (e) {
      Logger.logError('Failed to auto-approve payment', e, StackTrace.current);
    }
  }

  Future<void> _moveToManualApproval(PaymentModel payment) async {
    try {
      // Update payment status to require manual approval
      await _firestore.collection('payments').doc(payment.id).update({
        'status': PaymentStatus.pendingApproval.name,
        'updatedAt': FieldValue.serverTimestamp(),
        'requiresManualApproval': true,
        'approvalReason': _getApprovalReason(payment),
      });

      // Send notification to admins
      await _notificationService.createNotification(
        title: 'Payment Requires Approval',
        message: 'Payment #${payment.id.substring(0, 8)} for \$${payment.amount.toStringAsFixed(2)} requires manual approval',
        type: NotificationType.warning,
        priority: NotificationPriority.medium,
        category: 'manual_approval',
        data: {'paymentId': payment.id, 'reason': _getApprovalReason(payment)},
        broadcastToAllAdmins: true,
      );

      Logger.log('Payment moved to manual approval: ${payment.id}');
    } catch (e) {
      Logger.logError('Failed to move payment to manual approval', e, StackTrace.current);
    }
  }

  String _getApprovalReason(PaymentModel payment) {
    if (payment.amount > 100.0) {
      return 'High amount payment';
    }
    if (!['mpesa', 'creditCard', 'bankTransfer'].contains(payment.paymentMethod.toLowerCase())) {
      return 'Untrusted payment method';
    }
    if (payment.paymentProofUrl == null) {
      return 'Missing payment proof';
    }
    return 'Requires manual verification';
  }

  Future<void> _processAutomatedApprovals() async {
    try {
      // Process payments that have been awaiting verification for too long
      final stalePayments = await _firestore
          .collection('payments')
          .where('status', isEqualTo: PaymentStatus.awaitingVerification.name)
          .where('createdAt', isLessThan: Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 24))))
          .get();

      for (var doc in stalePayments.docs) {
        final payment = PaymentModel.fromMap(doc.data());

        // Move to under review status
        await _firestore.collection('payments').doc(payment.id).update({
          'status': PaymentStatus.underReview.name,
          'updatedAt': FieldValue.serverTimestamp(),
          'reviewReason': 'Stale payment requiring review',
        });

        // Notify admins
        await _notificationService.createNotification(
          title: 'Payment Review Required',
          message: 'Payment #${payment.id.substring(0, 8)} has been awaiting verification for 24+ hours',
          type: NotificationType.warning,
          priority: NotificationPriority.high,
          category: 'stale_payment',
          data: {'paymentId': payment.id, 'staleHours': 24},
          broadcastToAllAdmins: true,
        );
      }
    } catch (e) {
      Logger.logError('Failed to process automated approvals', e, StackTrace.current);
    }
  }

  Future<void> _checkStalePayments() async {
    try {
      // Check for payments stuck in pending state
      final pendingPayments = await _firestore
          .collection('payments')
          .where('status', isEqualTo: PaymentStatus.pending.name)
          .where('createdAt', isLessThan: Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 1))))
          .get();

      for (var doc in pendingPayments.docs) {
        final payment = PaymentModel.fromMap(doc.data());

        // Move to awaiting verification
        if (payment.id.isNotEmpty) {
          await _firestore.collection('payments').doc(payment.id).update({
            'status': PaymentStatus.awaitingVerification.name,
            'updatedAt': FieldValue.serverTimestamp(),
          });

          Logger.log('Payment moved to verification: ${payment.id}');
        }
      }
    } catch (e) {
      Logger.logError('Failed to check stale payments', e, StackTrace.current);
    }
  }

  // Manual approval methods
  Future<void> approvePayment(String paymentId, {String? adminNotes}) async {
    try {
      await _firestore.collection('payments').doc(paymentId).update({
        'status': PaymentStatus.approved.name,
        'updatedAt': FieldValue.serverTimestamp(),
        'approvedAt': FieldValue.serverTimestamp(),
        'approvedBy': 'admin', // In real app, get current admin user
        'adminNotes': adminNotes,
      });

      // Process the payment
      await _paymentService.updatePaymentStatus(paymentId, PaymentStatus.completed);

      Logger.log('Payment manually approved: $paymentId');
    } catch (e) {
      Logger.logError('Failed to approve payment', e, StackTrace.current);
      throw e;
    }
  }

  Future<void> rejectPayment(String paymentId, String reason, {String? adminNotes}) async {
    try {
      await _firestore.collection('payments').doc(paymentId).update({
        'status': PaymentStatus.rejected.name,
        'updatedAt': FieldValue.serverTimestamp(),
        'rejectedAt': FieldValue.serverTimestamp(),
        'rejectedBy': 'admin',
        'rejectionReason': reason,
        'adminNotes': adminNotes,
      });

      Logger.log('Payment manually rejected: $paymentId');
    } catch (e) {
      Logger.logError('Failed to reject payment', e, StackTrace.current);
      throw e;
    }
  }

  Future<void> requestAdditionalInfo(String paymentId, String requestDetails) async {
    try {
      await _firestore.collection('payments').doc(paymentId).update({
        'status': PaymentStatus.awaitingVerification.name,
        'updatedAt': FieldValue.serverTimestamp(),
        'additionalInfoRequested': true,
        'infoRequestDetails': requestDetails,
        'infoRequestedAt': FieldValue.serverTimestamp(),
      });

      Logger.log('Additional info requested for payment: $paymentId');
    } catch (e) {
      Logger.logError('Failed to request additional info', e, StackTrace.current);
      throw e;
    }
  }

  // Bulk operations
  Future<void> bulkApprovePayments(List<String> paymentIds, {String? adminNotes}) async {
    try {
      final batch = _firestore.batch();

      for (var paymentId in paymentIds) {
        final paymentRef = _firestore.collection('payments').doc(paymentId);
        batch.update(paymentRef, {
          'status': PaymentStatus.approved.name,
          'updatedAt': FieldValue.serverTimestamp(),
          'approvedAt': FieldValue.serverTimestamp(),
          'approvedBy': 'admin',
          'adminNotes': adminNotes,
          'bulkApproved': true,
        });
      }

      await batch.commit();

      // Process each payment
      for (var paymentId in paymentIds) {
        try {
          await _paymentService.updatePaymentStatus(paymentId, PaymentStatus.completed);
        } catch (e) {
          Logger.logError('Failed to process payment in bulk approval', e, StackTrace.current);
        }
      }

      Logger.log('Bulk approved ${paymentIds.length} payments');
    } catch (e) {
      Logger.logError('Failed to bulk approve payments', e, StackTrace.current);
      throw e;
    }
  }

  Future<void> bulkRejectPayments(List<String> paymentIds, String reason, {String? adminNotes}) async {
    try {
      final batch = _firestore.batch();

      for (var paymentId in paymentIds) {
        final paymentRef = _firestore.collection('payments').doc(paymentId);
        batch.update(paymentRef, {
          'status': PaymentStatus.rejected.name,
          'updatedAt': FieldValue.serverTimestamp(),
          'rejectedAt': FieldValue.serverTimestamp(),
          'rejectedBy': 'admin',
          'rejectionReason': reason,
          'adminNotes': adminNotes,
          'bulkRejected': true,
        });
      }

      await batch.commit();

      Logger.log('Bulk rejected ${paymentIds.length} payments');
    } catch (e) {
      Logger.logError('Failed to bulk reject payments', e, StackTrace.current);
      throw e;
    }
  }

  // Analytics methods
  Future<Map<String, dynamic>> getPaymentApprovalStats() async {
    try {
      final payments = await _firestore.collection('payments').get();

      final stats = {
        'totalPayments': payments.docs.length,
        'pendingApproval': payments.docs.where((doc) =>
          PaymentModel.fromMap(doc.data()).status == PaymentStatus.pendingApproval).length,
        'awaitingVerification': payments.docs.where((doc) =>
          PaymentModel.fromMap(doc.data()).status == PaymentStatus.awaitingVerification).length,
        'approved': payments.docs.where((doc) =>
          PaymentModel.fromMap(doc.data()).status == PaymentStatus.approved).length,
        'rejected': payments.docs.where((doc) =>
          PaymentModel.fromMap(doc.data()).status == PaymentStatus.rejected).length,
        'autoApproved': payments.docs.where((doc) =>
          PaymentModel.fromMap(doc.data()).autoApproved == true).length,
      };

      return stats;
    } catch (e) {
      Logger.logError('Failed to get payment approval stats', e, StackTrace.current);
      return {};
    }
  }

  // Cleanup method
  void dispose() {
    _automatedCheckTimer?.cancel();
    _newPaymentsSubscription?.cancel();
    Logger.log('Payment approval service disposed');
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jengamate/models/enums/payment_enums.dart';
import 'package:jengamate/models/payment_model.dart';
import '../models/order_model.dart';
import '../models/enums/order_enums.dart';

class PaymentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> initiatePayment(String orderId, double amount, String userId) async {
    final paymentRef = _firestore.collection('payments').doc();
    final payment = PaymentModel(
      id: paymentRef.id,
      orderId: orderId,
      userId: userId,
      amount: amount,
      paymentMethod: 'gateway',
      status: PaymentStatus.pending,
      createdAt: DateTime.now(),
    );

    await paymentRef.set(payment.toMap());

    // Simulate redirecting to a payment gateway
    // In a real app, this would be a URL from a payment provider
    return 'https://simulated-payment-gateway.com/pay?paymentId=${payment.uid}';
  }

  Stream<List<PaymentModel>> getPaymentsForOrder(String orderId) {
    return _firestore
        .collection('payments')
        .where('orderId', isEqualTo: orderId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PaymentModel.fromFirestore(doc))
            .toList());
  }

  Stream<List<PaymentModel>> streamUserPayments(String userId) {
    return _firestore
        .collection('payments')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PaymentModel.fromFirestore(doc))
            .toList());
  }

  Future<void> createPayment(PaymentModel payment) async {
    await _firestore.collection('payments').doc(payment.id).set(payment.toMap());
  }

  Future<void> processPayment(String paymentId) async {
    final paymentRef = _firestore.collection('payments').doc(paymentId);
    final paymentDoc = await paymentRef.get();

    if (!paymentDoc.exists) {
      throw Exception('Payment not found.');
    }

    final payment = PaymentModel.fromFirestore(paymentDoc);
    final orderRef = _firestore.collection('orders').doc(payment.orderId);

    await _firestore.runTransaction((transaction) async {
      final orderDoc = await transaction.get(orderRef);
      if (!orderDoc.exists) {
        throw Exception('Order not found.');
      }

      final order = OrderModel.fromFirestore(orderDoc);
      final newAmountPaid = (order.amountPaid ?? 0.0) + payment.amount;

      OrderStatus newStatus;
      if (newAmountPaid >= order.totalAmount) {
        newStatus = OrderStatus.fullyPaid;
      } else {
        newStatus = OrderStatus.partiallyPaid;
      }

      transaction.update(orderRef, {
        'amountPaid': newAmountPaid,
        'status': newStatus.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      transaction.update(paymentRef, {
        'status': PaymentStatus.completed.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }
}
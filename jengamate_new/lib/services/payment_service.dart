import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order_model.dart';
import '../models/enums/order_enums.dart';

class PaymentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Upload payment proof and update order status
  Future<void> uploadPaymentProof(String orderId, Map<String, dynamic> paymentProof) async {
    final orderRef = _firestore.collection('orders').doc(orderId);

    return _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(orderRef);
      final order = OrderModel.fromFirestore(snapshot);

      if (order.isLocked) {
        throw Exception('Order is locked and cannot be modified.');
      }

      List<Map<String, dynamic>> currentProofs = List<Map<String, dynamic>>.from(order.paymentProofs ?? []);
      currentProofs.add({
        ...paymentProof,
        'timestamp': Timestamp.now(),
      });

      double newAmountPaid = (order.amountPaid ?? 0.0) + (paymentProof['amount'] ?? 0.0);

      OrderStatus newStatus = OrderStatus.pendingPayment;
      if (newAmountPaid >= order.totalAmount) {
        newStatus = OrderStatus.fullyPaid;
      } else if (newAmountPaid > 0) {
        newStatus = OrderStatus.partiallyPaid;
      }

      transaction.update(orderRef, {
        'paymentProofs': currentProofs,
        'amountPaid': newAmountPaid,
        'status': newStatus.toString().split('.').last,
        'updatedAt': Timestamp.now(),
      });
    });
  }

  // Get payment details for an order
  Stream<OrderModel> getOrderPaymentDetails(String orderId) {
    return _firestore.collection('orders').doc(orderId).snapshots().map((doc) => OrderModel.fromFirestore(doc));
  }
}
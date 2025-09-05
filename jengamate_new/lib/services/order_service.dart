import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jengamate/models/payment_model.dart';
import 'package:jengamate/utils/logger.dart';
import '../models/order_model.dart';

class OrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get orders for a specific buyer (engineer)
  Stream<List<OrderModel>> getBuyerOrders(String buyerId) {
    return _firestore.collection('orders').where('buyerId', isEqualTo: buyerId).snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => OrderModel.fromFirestore(doc)).toList());
  }

  // Get orders for a specific supplier
  Stream<List<OrderModel>> getSupplierOrders(String supplierId) {
    return _firestore.collection('orders').where('supplierId', isEqualTo: supplierId).snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => OrderModel.fromFirestore(doc)).toList());
  }

  // Get a specific order by ID
  Stream<OrderModel> getOrder(String orderId) {
    return _firestore.collection('orders').doc(orderId).snapshots().map((doc) => OrderModel.fromFirestore(doc));
  }

  Future<OrderModel?> getOrderById(String orderId) async {
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

  // Get all orders (for admin)
  Stream<List<OrderModel>> getAllOrders() {
    return _firestore
        .collection('orders')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => OrderModel.fromFirestore(doc)).toList());
  }

  // Get orders by status (for admin)
  Stream<List<OrderModel>> getOrdersByStatus(String status) {
    return _firestore
        .collection('orders')
        .where('status', isEqualTo: status.toLowerCase())
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => OrderModel.fromFirestore(doc)).toList());
  }

  // Create a new order
  Future<void> createOrder(OrderModel order) async {
    await _firestore.collection('orders').doc(order.id).set(order.toMap());
  }

  Future<void> updateOrder(OrderModel order) async {
    try {
      await _firestore.collection('orders').doc(order.id).update(order.toMap());
    } catch (e) {
      Logger.logError('Error updating order', e);
      rethrow;
    }
  }

  // Update order status
  Future<void> updateOrderStatus(String orderId, String status) async {
    await _firestore.collection('orders').doc(orderId).update({
      'status': status,
      'updatedAt': Timestamp.now(),
    });
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
}

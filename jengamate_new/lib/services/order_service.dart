import 'package:cloud_firestore/cloud_firestore.dart';
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

  // Create a new order
  Future<void> createOrder(OrderModel order) async {
    await _firestore.collection('orders').doc(order.id).set(order.toMap());
  }

  // Update order status
  Future<void> updateOrderStatus(String orderId, String status) async {
    await _firestore.collection('orders').doc(orderId).update({
      'status': status,
      'updatedAt': Timestamp.now(),
    });
  }
}

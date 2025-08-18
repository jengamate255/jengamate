import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/quotation_model.dart';
import '../models/order_model.dart';
import '../models/enums/order_enums.dart'; // Import OrderStatus and OrderType

class QuotationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create a new quotation
  Future<void> createQuotation(Quotation quotation) async {
    await _firestore.collection('quotations').doc(quotation.id).set(quotation.toFirestore());
  }

  // Get a quotation by ID
  Stream<Quotation> getQuotation(String quotationId) {
    return _firestore.collection('quotations').doc(quotationId).snapshots().map((doc) => Quotation.fromFirestore(doc));
  }

  // Get quotations for a specific engineer
  Stream<List<Quotation>> getEngineerQuotations(String engineerId) {
    return _firestore.collection('quotations').where('engineerId', isEqualTo: engineerId).snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => Quotation.fromFirestore(doc)).toList());
  }

  // Get quotations for a specific supplier
  Stream<List<Quotation>> getSupplierQuotations(String supplierId) {
    return _firestore.collection('quotations').where('supplierId', isEqualTo: supplierId).snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => Quotation.fromFirestore(doc)).toList());
  }

  // Update quotation status
  Future<void> updateQuotationStatus(String quotationId, String status) async {
    await _firestore.collection('quotations').doc(quotationId).update({
      'status': status,
      'updatedAt': Timestamp.now(),
    });
  }

  // Confirm quotation and generate order
  Future<String> confirmQuotation(String quotationId) async {
    final quotationRef = _firestore.collection('quotations').doc(quotationId);
    final orderRef = _firestore.collection('orders');

    return _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(quotationRef);
      final quotation = Quotation.fromFirestore(snapshot);

      if (quotation.status != 'pending_review') {
        throw Exception('Quotation is not in pending review status.');
      }

      // Generate unique order number (e.g., SO2025-xxxx)
      // This is a simplified example, a more robust solution might involve Cloud Functions
      // to ensure true uniqueness and sequential numbering.
      // final String orderNumber = 'SO${DateTime.now().year}-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

      final newOrder = OrderModel(
        id: orderRef.doc().id, // Firestore will generate a unique ID
        buyerId: quotation.engineerId, // Assuming engineer is the user placing the order
        supplierId: quotation.supplierId,
        // products: quotation.products, // OrderModel does not have a 'products' field directly
        totalAmount: quotation.totalAmount,
        status: OrderStatus.pending, // Use the enum
        type: OrderType.product, // Default to product type for now
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      transaction.set(orderRef.doc(newOrder.id), newOrder.toMap());
      transaction.update(quotationRef, {
        'status': 'confirmed',
        'updatedAt': Timestamp.now(),
      });

      return newOrder.id;
    });
  }
}
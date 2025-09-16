import 'package:jengamate/models/enums/order_enums.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:jengamate/models/invoice_model.dart';
import 'package:uuid/uuid.dart';
import '../models/quotation_model.dart';
import '../models/order_model.dart';
import '../models/order_item_model.dart';
import '../utils/logger.dart' as utils_logger;

class QuotationService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create a new quotation
  Future<bool> createQuotation(Quotation quotation) async {
    try {
      final quotationData = quotation.toFirestore();

      await _supabase
          .from('quotations')
          .insert(quotationData);

      return true;
    } catch (e) {
      utils_logger.Logger.logError('Error creating quotation: $e');
      return false;
    }
  }

  // Get a quotation by ID
  Stream<Quotation> getQuotation(String quotationId) {
    return _firestore
        .collection('quotations')
        .doc(quotationId)
        .snapshots()
        .map((doc) => Quotation.fromFirestore((doc.data() as Map<String, dynamic>), docId: doc.id));
  }

  // Get quotations for a specific engineer
  Stream<List<Quotation>> getEngineerQuotations(String engineerId) {
    return _firestore
        .collection('quotations')
        .where('engineerId', isEqualTo: engineerId)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Quotation.fromFirestore((doc.data() as Map<String, dynamic>), docId: doc.id)).toList());
  }

  // Get quotations for a specific supplier
  Stream<List<Quotation>> getSupplierQuotations(String supplierId) {
    return _firestore
        .collection('quotations')
        .where('supplierId', isEqualTo: supplierId)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Quotation.fromFirestore((doc.data() as Map<String, dynamic>), docId: doc.id)).toList());
  }

  // Update quotation status
  Future<void> updateQuotationStatus(String quotationId, String status) async {
    await _firestore.collection('quotations').doc(quotationId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Confirm quotation and generate order
  Future<String> confirmQuotation(String quotationId) async {
    final quotationRef = _firestore.collection('quotations').doc(quotationId);
    final orderRef = _firestore.collection('orders');
    final invoiceRef = _firestore.collection('invoices');

    return _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(quotationRef);
      final quotation = Quotation.fromFirestore(snapshot.data() as Map<String, dynamic>, docId: snapshot.id);

      if (quotation.status != 'pending_review') {
        throw Exception('Quotation is not in pending review status.');
      }

      // Generate unique order number (e.g., SO2025-xxxx)
      final now = DateTime.now();
      final orderNumber =
          'SO${now.year}-${now.millisecondsSinceEpoch.toString().substring(8)}';

      final newOrderId = orderRef.doc().id;
      final newOrder = OrderModel(
        id: newOrderId, // Firestore will generate a unique ID
        orderNumber: orderNumber, // Add the generated order number
        buyerId: quotation
            .engineerId, // Assuming engineer is the user placing the order
        supplierId: quotation.supplierId,
        totalAmount: quotation.totalAmount,
        status: OrderStatus.pending, // Use the enum
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        customerId: quotation.engineerId,
        customerName: '', // Will need to be populated from user data
        supplierName: '', // Will need to be populated from user data
        customerEmail: '',
        items: quotation.products
            .map((product) => OrderItem.fromMap(product))
            .toList(),
        paymentMethod: 'pending',
      );

      transaction.set(orderRef.doc(newOrderId), newOrder.toMap());

      // Create and save the invoice
      final newInvoice = InvoiceModel(
        id: invoiceRef.doc().id,
        orderId: newOrderId,
        invoiceNumber: 'INV-${newOrder.orderNumber}',
        customerId: newOrder.customerId,
        customerName: newOrder.customerName,
        customerEmail: '', // Populate from user data
        issueDate: DateTime.now(),
        status: 'draft',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        dueDate: DateTime.now().add(const Duration(days: 30)),
        items: newOrder.items
            .map((item) => InvoiceItem(
                  id: const Uuid().v4(),
                  productId: item.productId,
                  description: item.productName,
                  quantity: item.quantity,
                  unitPrice: item.price,
                ))
            .toList(),
      );
      transaction.set(invoiceRef.doc(newInvoice.id), newInvoice.toMap());

      transaction.update(quotationRef, {
        'status': 'confirmed',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return newOrderId;
    });
  }
}

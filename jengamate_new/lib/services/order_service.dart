import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jengamate/models/payment_model.dart';
import 'package:jengamate/utils/logger.dart';
import '../models/order_model.dart';
import '../models/order_item_model.dart';
import '../models/invoice_model.dart'; // Import InvoiceModel
import 'invoice_service.dart'; // Import InvoiceService

class OrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get orders for a specific buyer (engineer)
  Stream<List<OrderModel>> getBuyerOrders(String buyerId) {
    return _firestore
        .collection('orders')
        .where('buyerId', isEqualTo: buyerId)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => OrderModel.fromFirestore(doc)).toList());
  }

  // Get orders for a specific supplier
  Stream<List<OrderModel>> getSupplierOrders(String supplierId) {
    return _firestore
        .collection('orders')
        .where('supplierId', isEqualTo: supplierId)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => OrderModel.fromFirestore(doc)).toList());
  }

  // Get a specific order by ID
  Stream<OrderModel> getOrder(String orderId) {
    return _firestore
        .collection('orders')
        .doc(orderId)
        .snapshots()
        .map((doc) => OrderModel.fromFirestore(doc));
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

    // After creating the order, create a corresponding invoice with populated items
    await createInvoiceForOrder(order);
  }

  // Create invoice for order with complete customer profile lookup
  Future<void> createInvoiceForOrder(OrderModel order) async {
    final invoiceService = InvoiceService();

    try {
      // Use the enhanced createInvoiceFromOrder method that fetches complete user profile
      await invoiceService.createInvoiceFromOrder(order);
      Logger.log(
          '✅ Invoice created successfully with complete customer information');
    } catch (e) {
      Logger.logError(
          'Error creating enhanced invoice, falling back to basic method', e);

      // Fallback to basic invoice creation if enhanced method fails
      final invoiceItems = order.items.isNotEmpty
          ? order.items
              .map((item) => InvoiceItem(
                    id: '',
                    description: item.productName,
                    quantity: item.quantity,
                    unitPrice: item.price,
                  ))
              .toList()
          : [
              InvoiceItem(
                id: '',
                description: 'Order Services',
                quantity: 1,
                unitPrice: order.totalAmount,
              )
            ];

      final invoice = InvoiceModel(
        id: '', // Firestore will generate this
        orderId: order.id!,
        invoiceNumber:
            'INV-${order.id!.substring(0, 8).toUpperCase()}', // Generate a simple invoice number
        customerId: order.customerId,
        customerName: order.customerName,
        customerEmail: order.customerEmail ?? '',
        customerPhone: order.customerPhone,
        customerAddress: order.deliveryAddress,
        issueDate: DateTime.now(),
        dueDate: DateTime.now().add(const Duration(days: 30)), // 30 days due
        items: invoiceItems,
        taxRate: 16.0,
        discountAmount: 0.0,
        status: 'sent',
        paymentTerms: 30,
        notes: 'Thank you for your business!',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await invoiceService.createInvoice(invoice);
      Logger.log('✅ Basic invoice created as fallback');
    }
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

  // Populate missing order items from quotation if available
  Future<OrderModel?> populateMissingOrderItems(OrderModel order) async {
    try {
      if (order.items.isNotEmpty ||
          (order.quotationId == null && order.rfqId == null)) {
        // Order already has items or no source to pull from
        return order;
      }

      Logger.log(
          '🔧 Attempting to populate missing order items for order: ${order.id}');

      // Try to populate from quotation first
      if (order.quotationId != null) {
        final quotationDoc = await _firestore
            .collection('quotations')
            .doc(order.quotationId)
            .get();
        if (quotationDoc.exists) {
          final quotationData = quotationDoc.data() as Map<String, dynamic>;
          final products = quotationData['products'] as List<dynamic>? ?? [];

          if (products.isNotEmpty) {
            Logger.log(
                '📋 Found ${products.length} items in quotation ${order.quotationId}');

            final populatedItems = products
                .map((product) =>
                    OrderItem.fromMap(product as Map<String, dynamic>))
                .toList();

            final updatedOrder = order.copyWith(items: populatedItems);

            // Update the order in database with populated items
            await updateOrder(updatedOrder);

            Logger.log(
                '✅ Successfully populated order with ${populatedItems.length} items');
            return updatedOrder;
          }
        }
      }

      // If no quotation items found, create a fallback item based on total amount
      if (order.items.isEmpty && order.totalAmount > 0) {
        Logger.log(
            '⚠️ WARNING: No items found in quotation, creating fallback item');

        final fallbackItem = OrderItem(
          productId: order.quotationId ?? 'unknown',
          productName: 'Order Services',
          quantity: 1,
          price: order.totalAmount,
        );

        final updatedOrder = order.copyWith(items: [fallbackItem]);
        await updateOrder(updatedOrder);

        Logger.log('✅ Created fallback item for order');
        return updatedOrder;
      }

      Logger.log('❌ Could not populate items for order ${order.id}');
      return order; // Return original if nothing could be populated
    } catch (e) {
      Logger.logError('Error populating missing order items: $e', e);
      return order; // Return original on error
    }
  }

  // Get order with populated items (automatically handles missing items)
  Future<OrderModel?> getOrderWithItems(String orderId) async {
    try {
      final order = await getOrderById(orderId);
      if (order == null) return null;

      // Try to populate missing items if any
      return await populateMissingOrderItems(order);
    } catch (e) {
      Logger.logError('Error getting order with items: $e', e);
      return null;
    }
  }
}

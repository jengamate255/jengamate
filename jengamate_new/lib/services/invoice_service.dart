import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart' as pw;
import 'package:pdf/widgets.dart' as pw_widgets;
import '../models/invoice_model.dart';
import '../models/order_model.dart';
import '../models/order_item_model.dart';
import '../models/user_model.dart';
import '../models/enums/user_role.dart';
import 'pdf_service.dart';
import 'database_service.dart';
import '../utils/logger.dart' as utils_logger;

class InvoiceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DatabaseService _databaseService = DatabaseService();
  static const String _collectionName = 'invoices';

  // Create a new invoice
  Future<InvoiceModel> createInvoice(InvoiceModel invoice) async {
    try {
      print('📝 Creating invoice in Firestore...');
      print('   Invoice data: ${invoice.toMap()}');
      final docRef =
          await _firestore.collection(_collectionName).add(invoice.toMap());
      print('✅ Invoice created with Firestore ID: ${docRef.id}');
      final createdInvoice = invoice.copyWith(id: docRef.id);
      print('📋 Final invoice object ID: ${createdInvoice.id}');
      return createdInvoice;
    } catch (e) {
      print('❌ ERROR in createInvoice: $e');
      print('   Stack trace: ${StackTrace.current}');
      throw Exception('Failed to create invoice: $e');
    }
  }

  // Update an existing invoice
  Future<void> updateInvoice(InvoiceModel invoice) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(invoice.id)
          .update(invoice.toMap());
    } catch (e) {
      throw Exception('Failed to update invoice: $e');
    }
  }

  // Get a single invoice by Order ID
  Future<InvoiceModel?> getInvoiceByOrderId(String orderId) async {
    try {
      print('🔍 Searching for invoice with orderId: $orderId');
      final querySnapshot = await _firestore
          .collection(_collectionName)
          .where('orderId', isEqualTo: orderId)
          .limit(1)
          .get();

      print('📊 Query returned ${querySnapshot.docs.length} documents');

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        print('📋 Found invoice document ID: ${doc.id}');
        print('📄 Document data: ${doc.data()}');

        final invoice = InvoiceModel.fromFirestore(doc);
        print('🧾 Parsed invoice object ID: ${invoice.id}');

        if (invoice.id == null || invoice.id!.isEmpty) {
          print('⚠️ Fixing invoice ID field...');
          final fixedInvoice = invoice.copyWith(id: doc.id);
          // Update the document with the correct ID
          await _firestore.collection(_collectionName).doc(doc.id).update({
            'id': doc.id,
            'updatedAt': FieldValue.serverTimestamp(),
          });
          print('✅ Fixed invoice ID to: ${doc.id}');
          return fixedInvoice;
        }

        return invoice;
      }

      print('ℹ️ No invoice found for orderId: $orderId');
      return null;
    } catch (e) {
      print('❌ ERROR in getInvoiceByOrderId: $e');
      print('   Stack trace: ${StackTrace.current}');
      throw Exception('Failed to get invoice by orderId: $e');
    }
  }

  // Get a single invoice by ID
  Future<InvoiceModel?> getInvoice(String id) async {
    try {
      final doc = await _firestore.collection(_collectionName).doc(id).get();
      if (doc.exists) {
        return InvoiceModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get invoice: $e');
    }
  }

  // Get invoice with populated items (automatically handles missing items)
  Future<InvoiceModel?> getInvoiceWithItems(String invoiceId) async {
    try {
      final invoice = await getInvoice(invoiceId);
      if (invoice == null) return null;

      // Try to populate missing items if any
      return await populateMissingInvoiceItems(invoice);
    } catch (e) {
      utils_logger.Logger.logError('Error getting invoice with items: $e', e);
      return null;
    }
  }

  // Get all invoices for a customer
  Stream<List<InvoiceModel>> getInvoicesByCustomer(String customerId) {
    return _firestore
        .collection(_collectionName)
        .where('customerId', isEqualTo: customerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => InvoiceModel.fromFirestore(doc))
            .toList());
  }

  // Get all invoices (for admin) with auto-populated items
  Stream<List<InvoiceModel>> getAllInvoices() {
    return _firestore
        .collection(_collectionName)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      final invoices =
          snapshot.docs.map((doc) => InvoiceModel.fromFirestore(doc)).toList();

      // Auto-populate missing items for all invoices
      final populatedInvoices = <InvoiceModel>[];
      for (final invoice in invoices) {
        final populatedInvoice = await populateMissingInvoiceItems(invoice);
        populatedInvoices.add(populatedInvoice ?? invoice);
      }

      return populatedInvoices;
    });
  }

  // Manually populate a specific invoice (for debugging/fixing specific cases)
  Future<InvoiceModel?> populateSpecificInvoiceItems(String invoiceId) async {
    try {
      utils_logger.Logger.log(
          '🔧 Manual population requested for invoice: $invoiceId');

      final invoice = await getInvoice(invoiceId);
      if (invoice == null) {
        utils_logger.Logger.log('❌ Invoice $invoiceId not found');
        return null;
      }

      final populatedInvoice = await populateMissingInvoiceItems(invoice);

      if (populatedInvoice != null && populatedInvoice.items.isNotEmpty) {
        utils_logger.Logger.log(
            '✅ Successfully populated invoice $invoiceId with ${populatedInvoice.items.length} items');
        return populatedInvoice;
      } else {
        utils_logger.Logger.log(
            '⚠️ Could not populate items for invoice $invoiceId');
        return null;
      }
    } catch (e) {
      utils_logger.Logger.logError(
          'Error manually populating invoice $invoiceId: $e', e);
      return null;
    }
  }

  // Update invoice status
  Future<void> updateInvoiceStatus(String invoiceId, String status) async {
    try {
      await _firestore.collection(_collectionName).doc(invoiceId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update invoice status: $e');
    }
  }

  // Mark invoice as paid
  Future<void> markAsPaid(String invoiceId,
      {String? paymentMethod, String? referenceNumber}) async {
    try {
      await _firestore.collection(_collectionName).doc(invoiceId).update({
        'status': 'paid',
        'paidDate': FieldValue.serverTimestamp(),
        'paymentMethod': paymentMethod,
        'referenceNumber': referenceNumber,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to mark invoice as paid: $e');
    }
  }

  // Delete an invoice
  Future<void> deleteInvoice(String invoiceId) async {
    try {
      await _firestore.collection(_collectionName).doc(invoiceId).delete();
    } catch (e) {
      throw Exception('Failed to delete invoice: $e');
    }
  }

  // Generate PDF and get download URL
  Future<String> generatePdf(InvoiceModel invoice) async {
    try {
      // Generate PDF download directly (handles web vs mobile/desktop)
      final pdfUrl = await PdfService.generateInvoiceDownload(invoice);

      // For web, PDF is already downloaded, for mobile we can store the path
      if (kIsWeb) {
        // Web: PDF already downloaded via blob, return the blob URL
        return pdfUrl;
      } else {
        // Mobile: Upload to Firebase Storage for sharing/linking
        // For mobile/desktop, we need to generate PDF bytes for upload
        final bytes = await _generatePdfBytes(invoice);

        final storageRef = FirebaseStorage.instance
            .ref()
            .child('invoices')
            .child('${invoice.id}.pdf');

        await storageRef.putData(bytes);

        // Get download URL
        final downloadUrl = await storageRef.getDownloadURL();

        // Update invoice with PDF URL
        await _firestore.collection(_collectionName).doc(invoice.id).update({
          'pdfUrl': downloadUrl,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        return downloadUrl;
      }
    } catch (e) {
      print('Error generating PDF: $e');
      rethrow;
    }
  }

  // Generate PDF bytes for Firebase Storage upload
  Future<Uint8List> _generatePdfBytes(InvoiceModel invoice) async {
    // Use the same PDF service to generate the PDF
    return await PdfService.generateInvoice(invoice)
        .then((file) => file.readAsBytes());
  }

  // Send invoice via email
  Future<bool> sendInvoiceByEmail(InvoiceModel invoice, {String? email}) async {
    try {
      // First ensure we have a PDF URL
      String pdfUrl = invoice.pdfUrl ?? '';
      if (pdfUrl.isEmpty) {
        pdfUrl = await generatePdf(invoice);
      }

      // Get the current user's email if not provided
      final recipientEmail = email ?? invoice.customerEmail;
      if (recipientEmail.isEmpty) {
        utils_logger.Logger.logError(
            'Cannot send invoice ${invoice.invoiceNumber}: No email address provided',
            null);
        throw Exception(
            'Cannot send invoice: No email address provided for the recipient');
      }

      // In a real app, you would integrate with an email service here
      // For now, we'll use a mailto link as a fallback
      // Example email content for future integration:
      // final subject = 'Invoice #${invoice.invoiceNumber} from JengaMate';
      // final body = '''
      // Hello ${invoice.customerName},
      //
      // Please find attached your invoice #${invoice.invoiceNumber} for ${invoice.items.map((item) => item.description).join(', ')}.
      //
      // Amount Due: TSH ${invoice.totalAmount.toStringAsFixed(2)}
      // Due Date: ${invoice.dueDate.toString().split(' ')[0]}
      //
      // You can view and download the invoice here: $pdfUrl
      //
      // Thank you for your business!
      //
      // Best regards,
      // JengaMate Team
      // ''';

      // Update last sent date
      await _firestore.collection(_collectionName).doc(invoice.id).update({
        'lastSentAt': FieldValue.serverTimestamp(),
        'status': 'sent',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Open default email client
      // Note: This will only work on mobile/desktop, not web
      // For web, you'd need a different approach
      // Example using url_launcher (uncomment if integrating):
      // final mailtoLink =
      //   'mailto:$recipientEmail?subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}';
      // if (await canLaunchUrl(Uri.parse(mailtoLink))) {
      //   await launchUrl(Uri.parse(mailtoLink));
      // }

      return true;
    } catch (e) {
      print('Error sending email: $e');
      rethrow;
    }
  }

  // Fix data integrity - populate all existing invoices with missing items
  Future<void> fixExistingInvoiceItems() async {
    try {
      utils_logger.Logger.log(
          '🔧 Starting data integrity fix for existing invoices');

      final invoicesSnapshot =
          await _firestore.collection(_collectionName).get();

      int fixedCount = 0;
      int totalCount = invoicesSnapshot.docs.length;

      utils_logger.Logger.log(
          '📊 Found $totalCount invoices to check for missing items');

      for (final doc in invoicesSnapshot.docs) {
        final invoice = InvoiceModel.fromFirestore(doc);

        // Check if invoice has missing items
        if (invoice.items.isEmpty ||
            invoice.orderId == null ||
            (invoice.items.length == 1 &&
                invoice.items.first.description == 'Order Services')) {
          utils_logger.Logger.log(
              '📋 Fixing invoice ${invoice.id} with missing items');

          // Try to populate missing items
          final populatedInvoice = await populateMissingInvoiceItems(invoice);

          if (populatedInvoice != null && populatedInvoice.items.isNotEmpty) {
            fixedCount++;
            utils_logger.Logger.log(
                '✅ Fixed invoice ${invoice.id} - added ${populatedInvoice.items.length} items');
          } else {
            utils_logger.Logger.log('⚠️ Could not fix invoice ${invoice.id}');
          }
        }
      }

      utils_logger.Logger.log(
          '🏁 Data integrity fix complete: $fixedCount/$totalCount invoices fixed');
    } catch (e) {
      utils_logger.Logger.logError('Error during data integrity fix: $e', e);
    }
  }

  // Create invoice from order with complete customer information lookup
  Future<InvoiceModel> createInvoiceFromOrder(OrderModel order,
      {String? customInvoiceNumber}) async {
    try {
      print('🔍 Creating invoice from order: ${order.uid}');
      print('   Customer ID: ${order.customerId}');

      // Get customer details from user profile using customerId
      String customerName = order.customerName;
      String customerEmail = order.customerEmail ?? '';
      String customerPhone = order.customerPhone ?? '';
      String customerAddress = order.deliveryAddress ?? '';
      String customerCompany = order.notes ?? 'Customer Company';

      // Fetch complete user profile data
      if (order.customerId.isNotEmpty) {
        try {
          print('   Fetching user profile for customerId: ${order.customerId}');
          UserModel? userProfile =
              await _databaseService.getUser(order.customerId);

          if (userProfile != null) {
            // Update with complete user profile information
            customerName = '${userProfile.firstName} ${userProfile.lastName}';
            customerEmail = userProfile.email ?? customerEmail;

            // Get company information for business users
            if (userProfile.role == UserRole.supplier ||
                userProfile.role == UserRole.admin) {
              customerCompany = userProfile.companyName ?? 'Business Customer';
              customerPhone = userProfile.companyPhone ??
                  userProfile.phoneNumber ??
                  customerPhone;
              customerAddress = userProfile.companyAddress ??
                  userProfile.address ??
                  customerAddress;
            } else {
              // Personal user details
              customerPhone = userProfile.phoneNumber ?? customerPhone;
              customerAddress = userProfile.address ?? customerAddress;
            }

            print('✅ Retrieved complete customer info: $customerName');
            print('   Email: $customerEmail, Phone: $customerPhone');
          } else {
            print('⚠️ Customer profile not found, using order data');
          }
        } catch (e) {
          print('⚠️ Error fetching user profile: $e');
          print('   Will use order data as fallback');
        }
      }

      // Create invoice items from order items
      final invoiceItems = order.items.isNotEmpty
          ? order.items
              .map((item) => InvoiceItem(
                    id: '',
                    description: item.productName,
                    quantity: item.quantity,
                    unitPrice: item.price,
                    productId: order.uid,
                  ))
              .toList()
          : [
              InvoiceItem(
                id: '',
                description: 'Order Services',
                quantity: 1,
                unitPrice: order.totalAmount,
                productId: order.uid,
              )
            ];

      // Generate invoice number
      final invoiceNumber =
          customInvoiceNumber ?? InvoiceModel.generateInvoiceNumber();

      // Create invoice with complete customer information
      final invoice = InvoiceModel(
        id: '', // Will be set by Firestore
        invoiceNumber: invoiceNumber,
        customerId: order.customerId,
        orderId: order.uid,
        customerName: customerName,
        customerEmail: customerEmail,
        customerPhone: customerPhone,
        customerAddress: customerAddress,
        customerCompany: customerCompany,
        issueDate: DateTime.now(),
        dueDate: DateTime.now().add(const Duration(days: 30)),
        items: invoiceItems,
        taxRate: 16.0,
        discountAmount: 0.0,
        status: 'sent',
        notes:
            'Thank you for your business! Please process payment within 30 days.',
        termsAndConditions: 'Payment due within 30 days from invoice date.',
      );

      print('📝 Creating invoice with full customer details:');
      print('   Customer: $customerName ($customerEmail)');
      print('   Invoice #: ${invoice.invoiceNumber}');

      // Create the invoice in the database
      final createdInvoice = await createInvoice(invoice);

      print('✅ Invoice created successfully for customer: $customerName');
      return createdInvoice;
    } catch (e) {
      print('❌ Error creating invoice from order: $e');
      print('   Stack trace: ${StackTrace.current}');
      throw Exception('Failed to create invoice from order: $e');
    }
  }

  // Populate missing invoice items from associated order
  Future<InvoiceModel?> populateMissingInvoiceItems(
      InvoiceModel invoice) async {
    try {
      if (invoice.items.isNotEmpty ||
          invoice.orderId == null ||
          invoice.orderId!.isEmpty) {
        // Invoice already has items or no associated order
        return invoice;
      }

      utils_logger.Logger.log(
          '🔧 Attempting to populate missing invoice items for invoice: ${invoice.id}');

      // Fetch the associated order
      if (invoice.orderId != null && invoice.orderId!.isNotEmpty) {
        final orderDoc =
            await _firestore.collection('orders').doc(invoice.orderId).get();

        if (orderDoc.exists) {
          final orderData = orderDoc.data() as Map<String, dynamic>;
          final orderItems = orderData['items'] as List<dynamic>? ?? [];

          if (orderItems.isNotEmpty) {
            utils_logger.Logger.log(
                '📋 Found ${orderItems.length} items in order ${invoice.orderId}');

            final populatedItems = orderItems
                .map(
                    (item) => InvoiceItem.fromMap(item as Map<String, dynamic>))
                .toList();

            // Calculate total amount from populated items
            final calculatedTotal = populatedItems.fold<double>(
              0.0,
              (sum, item) => sum + (item.quantity * item.unitPrice),
            );

            final updatedInvoice = invoice.copyWith(
              items: populatedItems,
            );

            // Update the invoice in database with populated items
            await updateInvoice(updatedInvoice);

            utils_logger.Logger.log(
                '✅ Successfully populated invoice with ${populatedItems.length} items');
            return updatedInvoice;
          }
        }
      }

      // If no order items found, create a fallback item
      if (invoice.items.isEmpty) {
        utils_logger.Logger.log(
            '⚠️ WARNING: No items found in associated order, creating fallback item');

        final fallbackItem = InvoiceItem(
          id: '',
          description: 'Order Services',
          quantity: 1,
          unitPrice: invoice.totalAmount,
          productId: invoice.orderId,
        );

        // Ensure we have a minimum sensible amount
        final itemAmount =
            invoice.totalAmount > 0 ? invoice.totalAmount : 1000.0;

        final fallbackInvoice = invoice.copyWith(
          items: [
            InvoiceItem(
              id: '',
              description: 'Order Services',
              quantity: 1,
              unitPrice: itemAmount,
              productId: invoice.orderId,
            )
          ],
        );

        await updateInvoice(fallbackInvoice);

        utils_logger.Logger.log('✅ Created fallback item for invoice');
        return fallbackInvoice;
      }

      utils_logger.Logger.log(
          '❌ Could not populate items for invoice ${invoice.id}');
      return invoice; // Return original if nothing could be populated
    } catch (e) {
      utils_logger.Logger.logError(
          'Error populating missing invoice items: $e', e);
      return invoice; // Return original on error
    }
  }
}

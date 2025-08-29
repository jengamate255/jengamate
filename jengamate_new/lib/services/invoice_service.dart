import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import '../models/invoice_model.dart';
import 'pdf_service.dart';

class InvoiceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionName = 'invoices';

  // Create a new invoice
  Future<InvoiceModel> createInvoice(InvoiceModel invoice) async {
    try {
      final docRef = await _firestore.collection(_collectionName).add(invoice.toMap());
      return invoice.copyWith(id: docRef.id);
    } catch (e) {
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

  // Get all invoices (for admin)
  Stream<List<InvoiceModel>> getAllInvoices() {
    return _firestore
        .collection(_collectionName)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => InvoiceModel.fromFirestore(doc))
            .toList());
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
  Future<void> markAsPaid(String invoiceId, {String? paymentMethod, String? referenceNumber}) async {
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
      // Generate PDF file
      final pdfFile = await PdfService.generateInvoice(invoice);
      
      // Upload to Firebase Storage
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('invoices')
          .child('${invoice.id}.pdf');
      
      await storageRef.putFile(pdfFile);
      
      // Get download URL
      final downloadUrl = await storageRef.getDownloadURL();
      
      // Update invoice with PDF URL
      await _firestore.collection(_collectionName).doc(invoice.id).update({
        'pdfUrl': downloadUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      return downloadUrl;
    } catch (e) {
      print('Error generating PDF: $e');
      rethrow;
    }
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
        throw Exception('No email address provided for the recipient');
      }
      
      // In a real app, you would integrate with an email service here
      // For now, we'll use a mailto link as a fallback
      final subject = 'Invoice #${invoice.invoiceNumber} from JengaMate';
      final body = '''
Hello ${invoice.customerName},

Please find attached your invoice #${invoice.invoiceNumber} for ${invoice.items.map((item) => item.description).join(', ')}.

Amount Due: KSh ${invoice.totalAmount.toStringAsFixed(2)}
Due Date: ${invoice.dueDate.toString().split(' ')[0]}

You can view and download the invoice here: $pdfUrl

Thank you for your business!

Best regards,
JengaMate Team
      ''';
      
      final mailtoLink = 'mailto:$recipientEmail?subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}';
      
      // Update last sent date
      await _firestore.collection(_collectionName).doc(invoice.id).update({
        'lastSentAt': FieldValue.serverTimestamp(),
        'status': 'sent',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // Open default email client
      // Note: This will only work on mobile/desktop, not web
      // For web, you'd need a different approach
      // import 'package:url_launcher/url_launcher.dart';
      // if (await canLaunch(mailtoLink)) {
      //   await launch(mailtoLink);
      // }
      
      return true;
    } catch (e) {
      print('Error sending email: $e');
      rethrow;
    }
  }
}

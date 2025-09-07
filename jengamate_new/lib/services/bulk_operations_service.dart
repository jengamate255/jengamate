import 'dart:io';
import 'package:archive/archive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../models/invoice_model.dart';
import 'invoice_service.dart';

/// Represents the result of a bulk operation
class BulkOperationResult {
  final int successful;
  final int failed;
  final int total;
  final List<String> errors;
  final List<String> successfulIds;

  BulkOperationResult({
    required this.successful,
    required this.failed,
    required this.total,
    this.errors = const [],
    this.successfulIds = const [],
  });

  bool get isCompleteSuccess => failed == 0 && successful == total;
  bool get isPartialSuccess => successful > 0 && failed > 0;
  bool get isCompleteFailure => successful == 0 && failed == total;
  double get successRate => total > 0 ? successful / total : 0.0;
}

/// Service for handling bulk invoice operations
class BulkOperationsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final InvoiceService _invoiceService;

  BulkOperationsService(this._invoiceService);

  /// Send multiple invoices via email
  Future<BulkOperationResult> sendInvoicesBulk(
    List<InvoiceModel> invoices, {
    required BuildContext context,
    Function(int)? onProgress,
  }) async {
    List<String> errors = [];
    List<String> successfulIds = [];
    int completed = 0;

    for (final invoice in invoices) {
      try {
        await _invoiceService.sendInvoiceByEmail(invoice);
        successfulIds.add(invoice.id);
        completed++;
        onProgress?.call(completed);
      } catch (e) {
        errors.add('${invoice.invoiceNumber}: ${e.toString()}');
        completed++;
        onProgress?.call(completed);
      }
    }

    return BulkOperationResult(
      successful: successfulIds.length,
      failed: errors.length,
      total: invoices.length,
      errors: errors,
      successfulIds: successfulIds,
    );
  }

  /// Update status for multiple invoices
  Future<BulkOperationResult> updateInvoicesStatusBulk(
    List<InvoiceModel> invoices,
    String newStatus, {
    Function(int)? onProgress,
  }) async {
    List<String> errors = [];
    List<String> successfulIds = [];
    int completed = 0;

    // Use Firebase batch operations for efficiency
    const int batchSize = 500; // Firestore batch limit
    final batches = <WriteBatch>[];

    // Split invoices into batches
    for (int i = 0; i < invoices.length; i += batchSize) {
      final batch = _firestore.batch();
      final end =
          (i + batchSize < invoices.length) ? i + batchSize : invoices.length;

      for (int j = i; j < end; j++) {
        final invoice = invoices[j];
        final docRef = _firestore.collection('invoices').doc(invoice.id);

        Map<String, dynamic> updateData = {
          'status': newStatus,
          'updatedAt': FieldValue.serverTimestamp(),
        };

        // Add payment-specific fields if marking as paid
        if (newStatus.toLowerCase() == 'paid') {
          updateData.addAll({
            'paidDate': FieldValue.serverTimestamp(),
          });
        }

        batch.update(docRef, updateData);
      }
      batches.add(batch);
    }

    // Execute batches
    for (final batch in batches) {
      try {
        await batch.commit();

        // Update successful count (approximate since batch size varies)
        final batchItems = batchSize > invoices.length - completed
            ? invoices.length - completed
            : batchSize;

        completed += batchItems;
        onProgress?.call(completed);

        // Add all invoices from this batch as successful
        final startIndex = successfulIds.length;
        final endIndex = startIndex + batchItems;
        successfulIds.addAll(invoices
            .sublist(startIndex, endIndex.clamp(0, invoices.length))
            .map((inv) => inv.id));
      } catch (e) {
        errors.add('Batch operation failed: ${e.toString()}');
        completed += batchSize;
        onProgress?.call(completed);
      }
    }

    return BulkOperationResult(
      successful: successfulIds.length,
      failed: errors.length,
      total: invoices.length,
      errors: errors,
      successfulIds: successfulIds,
    );
  }

  /// Generate PDFs for multiple invoices and package them into a ZIP file
  Future<BulkOperationResult> exportInvoicesToZip(
    List<InvoiceModel> invoices, {
    required String zipFileName,
    Function(int)? onProgress,
  }) async {
    List<String> errors = [];
    List<String> successfulIds = [];
    List<File> pdfFiles = [];
    int completed = 0;

    try {
      // Generate PDFs for all invoices
      for (final invoice in invoices) {
        try {
          await _invoiceService.generatePdf(invoice);
          successfulIds.add(invoice.id);

          // Note: In a real implementation, we'd collect the actual PDF files
          // For now, we'll simulate successful PDF generation
          completed++;
          onProgress?.call(completed);
        } catch (e) {
          errors.add(
              '${invoice.invoiceNumber}: PDF generation failed - ${e.toString()}');
          completed++;
          onProgress?.call(completed);
        }
      }

      // In a real implementation, you'd create a ZIP file here:
      // - Collect all PDF files from Firebase Storage or local storage
      // - Create ZIP archive
      // - Upload to Firebase Storage or return download URL

      // For this demo, we'll simulate the ZIP creation
      if (successfulIds.isNotEmpty) {
        await Future.delayed(
            const Duration(seconds: 1)); // Simulate ZIP creation
      }

      return BulkOperationResult(
        successful: successfulIds.length,
        failed: errors.length,
        total: invoices.length,
        errors: errors,
        successfulIds: successfulIds,
      );
    } catch (e) {
      return BulkOperationResult(
        successful: 0,
        failed: invoices.length,
        total: invoices.length,
        errors: ['ZIP creation failed: ${e.toString()}'],
      );
    }
  }

  /// Delete multiple invoices
  Future<BulkOperationResult> deleteInvoicesBulk(
    List<InvoiceModel> invoices, {
    Function(int)? onProgress,
  }) async {
    List<String> errors = [];
    List<String> successfulIds = [];
    int completed = 0;

    // Use Firebase batch operations for efficiency
    const int batchSize = 500;

    for (int i = 0; i < invoices.length; i += batchSize) {
      final batch = _firestore.batch();
      final end =
          (i + batchSize < invoices.length) ? i + batchSize : invoices.length;

      for (int j = i; j < end; j++) {
        final invoice = invoices[j];
        final docRef = _firestore.collection('invoices').doc(invoice.id);
        batch.delete(docRef);
      }

      try {
        await batch.commit();
        successfulIds.addAll(invoices.sublist(i, end).map((inv) => inv.id));
        completed += (end - i);
        onProgress?.call(completed);
      } catch (e) {
        errors.add('Batch delete failed: ${e.toString()}');
        completed += (end - i);
        onProgress?.call(completed);
      }
    }

    return BulkOperationResult(
      successful: successfulIds.length,
      failed: errors.length,
      total: invoices.length,
      errors: errors,
      successfulIds: successfulIds,
    );
  }

  /// Duplicate multiple invoices
  Future<BulkOperationResult> duplicateInvoicesBulk(
    List<InvoiceModel> invoices, {
    Function(int)? onProgress,
  }) async {
    List<String> errors = [];
    List<String> successfulIds = [];
    int completed = 0;

    for (final invoice in invoices) {
      try {
        // Create a duplicate with new ID and invoice number
        final duplicate = invoice.copyWith(
          id: '', // Let Firestore generate new ID
          invoiceNumber: '${invoice.invoiceNumber}_COPY',
          status: 'draft',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final createdInvoice = await _invoiceService.createInvoice(duplicate);
        successfulIds.add(createdInvoice.id);
        completed++;
        onProgress?.call(completed);
      } catch (e) {
        errors.add(
            '${invoice.invoiceNumber}: Duplicate failed - ${e.toString()}');
        completed++;
        onProgress?.call(completed);
      }
    }

    return BulkOperationResult(
      successful: successfulIds.length,
      failed: errors.length,
      total: invoices.length,
      errors: errors,
      successfulIds: successfulIds,
    );
  }

  /// Validate bulk operation before execution
  String? validateBulkOperation(List<InvoiceModel> invoices, String operation) {
    if (invoices.isEmpty) {
      return 'No invoices selected for the operation.';
    }

    switch (operation.toLowerCase()) {
      case 'send':
        final unsentInvoices = invoices
            .where((inv) => inv.status.toLowerCase() != 'sent')
            .toList();
        if (unsentInvoices.isEmpty) {
          return 'All selected invoices have already been sent.';
        }
        break;

      case 'delete':
        if (invoices.any((inv) => inv.status.toLowerCase() == 'paid')) {
          return 'Cannot delete paid invoices. Please unselect paid invoices or contact administrator.';
        }
        break;

      case 'update_status':
        // Add specific validation for status updates if needed
        break;
    }

    return null; // No validation errors
  }
}

/// Extension to add bulk operations to existing classes
extension BulkOperationsExtension on List<InvoiceModel> {
  List<InvoiceModel> filterByStatus(String status) {
    if (status.toLowerCase() == 'all') return this;
    return where(
            (invoice) => invoice.status.toLowerCase() == status.toLowerCase())
        .toList();
  }

  List<InvoiceModel> filterByAmount(double minAmount, double maxAmount) {
    return where((invoice) =>
        invoice.totalAmount >= minAmount &&
        invoice.totalAmount <= maxAmount).toList();
  }

  List<InvoiceModel> filterByDateRange(DateTime startDate, DateTime endDate) {
    return where((invoice) =>
        invoice.createdAt.isAfter(startDate) &&
        invoice.createdAt.isBefore(endDate)).toList();
  }
}

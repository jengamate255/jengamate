import 'package:flutter/material.dart';
import 'package:jengamate/models/invoice_model.dart';
import 'package:jengamate/services/pdf_service.dart';
import 'package:open_file/open_file.dart';

class PdfTestScreen extends StatelessWidget {
  const PdfTestScreen({super.key});

  Future<void> _testPdfGeneration() async {
    // Create a sample invoice
    final invoice = InvoiceModel(
      id: 'test_${DateTime.now().millisecondsSinceEpoch}',
      invoiceNumber: 'INV-${DateTime.now().millisecondsSinceEpoch}',
      customerId: 'test_customer',
      issueDate: DateTime.now(),
      customerName: 'Test Customer',
      customerEmail: 'test@example.com',
      customerPhone: '+254700000000',
      customerAddress: '123 Test Street, Nairobi',
      items: [
        InvoiceItem(
          id: 'item1',
          description: 'Test Product 1',
          quantity: 2,
          unitPrice: 1000.0,
        ),
        InvoiceItem(
          id: 'item2',
          description: 'Test Product 2',
          quantity: 1,
          unitPrice: 2000.0,
        ),
      ],
      taxRate: 16.0,
      discountAmount: 0.0,
      status: 'draft',
      notes: 'This is a test invoice',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      dueDate: DateTime.now().add(const Duration(days: 30)),
    );

    try {
      // Generate PDF
      final file = await PdfService.generateInvoice(invoice);
      
      // Open the generated PDF
      await OpenFile.open(file.path);
      
      print('PDF generated at: ${file.path}');
    } catch (e) {
      print('Error generating PDF: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF Generation Test'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: _testPdfGeneration,
          child: const Text('Generate Test PDF'),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jengamate/models/invoice_model.dart';
import 'package:jengamate/services/invoice_service.dart';
import 'package:jengamate/utils/theme.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class InvoiceDetailsScreen extends StatefulWidget {
  final String invoiceId;

  const InvoiceDetailsScreen({super.key, required this.invoiceId});

  @override
  State<InvoiceDetailsScreen> createState() => _InvoiceDetailsScreenState();
}

class _InvoiceDetailsScreenState extends State<InvoiceDetailsScreen> {
  bool _isLoading = true;
  InvoiceModel? _invoice;
  bool _isPaying = false;

  @override
  void initState() {
    super.initState();
    _loadInvoice();
  }

  Future<void> _loadInvoice() async {
    try {
      final invoiceService = Provider.of<InvoiceService>(context, listen: false);
      final invoice = await invoiceService.getInvoice(widget.invoiceId);
      
      if (mounted) {
        setState(() {
          _invoice = invoice;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load invoice: $e')),
        );
      }
    }
  }

  Future<void> _markAsPaid() async {
    if (_invoice == null) return;

    setState(() => _isPaying = true);
    
    try {
      final invoiceService = Provider.of<InvoiceService>(context, listen: false);
      await invoiceService.markAsPaid(
        _invoice!.id,
        paymentMethod: 'Bank Transfer',
        referenceNumber: 'REF-${DateTime.now().millisecondsSinceEpoch}',
      );
      
      if (mounted) {
        await _loadInvoice(); // Refresh the invoice
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invoice marked as paid')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to mark as paid: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPaying = false);
      }
    }
  }

  Future<void> _sendInvoice() async {
    if (_invoice == null) return;

    try {
      final invoiceService = Provider.of<InvoiceService>(context, listen: false);
      await invoiceService.sendInvoiceByEmail(_invoice!, email: _invoice!.customerEmail);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invoice sent to customer')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send invoice: $e')),
        );
      }
    }
  }

  Future<void> _downloadPdf() async {
    if (_invoice == null) return;

    try {
      final invoiceService = Provider.of<InvoiceService>(context, listen: false);
      final pdfUrl = await invoiceService.generatePdf(_invoice!);
      
      if (await canLaunchUrl(Uri.parse(pdfUrl))) {
        await launchUrl(Uri.parse(pdfUrl));
      } else {
        throw 'Could not launch PDF viewer';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to download PDF: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_invoice == null) {
      return const Scaffold(
        body: Center(child: Text('Invoice not found')),
      );
    }

    final invoice = _invoice!;
    final dateFormat = DateFormat('MMM dd, yyyy');
    final currencyFormat = NumberFormat.currency(symbol: 'TSh ');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoice Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _downloadPdf,
          ),
          IconButton(
            icon: const Icon(Icons.email),
            onPressed: _sendInvoice,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'INVOICE #${invoice.invoiceNumber}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Issued: ${dateFormat.format(invoice.issueDate)}',
                      style: const TextStyle(color: Colors.grey),
                    ),
                    Text(
                      'Due: ${dateFormat.format(invoice.dueDate)}',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(invoice.status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    invoice.status.toUpperCase(),
                    style: TextStyle(
                      color: _getStatusColor(invoice.status),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // From / To Section
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // From
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'From',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const Text('JengaMate'),
                      const Text('P.O. Box 12345'),
                      const Text('Dar es Salaam, Tanzania'),
                      const Text('Email: info@jengamate.co.tz'),
                      const Text('Phone: +255 712 345 678'),
                    ],
                  ),
                ),
                // To
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Bill To',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(invoice.customerName),
                      if (invoice.customerAddress != null)
                        Text(invoice.customerAddress!),
                      Text(invoice.customerEmail),
                      if (invoice.customerPhone != null)
                        Text(invoice.customerPhone!),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Items Table
            _buildItemsTable(invoice, currencyFormat),
            const SizedBox(height: 24),

            // Totals
            _buildTotals(invoice, currencyFormat),
            const SizedBox(height: 32),

            // Notes & Terms
            if (invoice.notes != null || invoice.termsAndConditions != null) ...[
              const Divider(),
              const SizedBox(height: 16),
              if (invoice.notes != null) ...[
                const Text(
                  'Notes',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(invoice.notes!),
                const SizedBox(height: 16),
              ],
              if (invoice.termsAndConditions != null) ...[
                const Text(
                  'Terms & Conditions',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(invoice.termsAndConditions!),
              ],
            ],

            const SizedBox(height: 32),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(invoice),
    );
  }

  Widget _buildItemsTable(InvoiceModel invoice, NumberFormat currencyFormat) {
    return Table(
      border: TableBorder.all(color: Colors.grey.shade200),
      columnWidths: const {
        0: FlexColumnWidth(3),
        1: FlexColumnWidth(1),
        2: FlexColumnWidth(1.5),
        3: FlexColumnWidth(1.5),
      },
      children: [
        // Header
        TableRow(
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
          ),
          children: const [
            Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                'Description',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                'Qty',
                style: TextStyle(fontWeight: FontWeight.bold),
                textAlign: TextAlign.right,
              ),
            ),
            Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                'Unit Price',
                style: TextStyle(fontWeight: FontWeight.bold),
                textAlign: TextAlign.right,
              ),
            ),
            Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                'Total',
                style: TextStyle(fontWeight: FontWeight.bold),
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
        // Items
        ...invoice.items.map((item) => TableRow(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(item.description),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    item.quantity.toString(),
                    textAlign: TextAlign.right,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    currencyFormat.format(item.unitPrice),
                    textAlign: TextAlign.right,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    currencyFormat.format(item.total),
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            )),
      ],
    );
  }

  Widget _buildTotals(InvoiceModel invoice, NumberFormat currencyFormat) {
    return Column(
      children: [
        // Subtotal
        _buildTotalRow('Subtotal', invoice.subtotal, currencyFormat: currencyFormat),
        // Tax
        if (invoice.taxRate > 0) ...[
          _buildTotalRow(
            'Tax (${invoice.taxRate}%)',
            invoice.taxAmount,
            currencyFormat: currencyFormat,
          ),
        ],
        // Discount
        if (invoice.discountAmount > 0) ...[
          _buildTotalRow(
            'Discount',
            -invoice.discountAmount,
            currencyFormat: currencyFormat,
            isDiscount: true,
          ),
        ],
        // Total
        _buildTotalRow(
          'TOTAL',
          invoice.totalAmount,
          currencyFormat: currencyFormat,
          isTotal: true,
        ),
      ],
    );
  }

  Widget _buildTotalRow(
    String label,
    double amount, {
    required NumberFormat currencyFormat,
    bool isDiscount = false,
    bool isTotal = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 16 : 14,
            ),
          ),
          Text(
            '${isDiscount ? '-' : ''}${currencyFormat.format(amount)}',
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 18 : 14,
              color: isDiscount ? Colors.red : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(InvoiceModel invoice) {
    if (invoice.status.toLowerCase() == 'paid') {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          border: Border(
            top: BorderSide(color: Colors.green.shade100, width: 1),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 20),
            const SizedBox(width: 8),
            Text(
              'PAID ON ${DateFormat('MMM dd, yyyy').format(DateTime.now())}',
              style: const TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _isPaying ? null : _markAsPaid,
              icon: _isPaying
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.check_circle, size: 20),
              label: Text(_isPaying ? 'Processing...' : 'Mark as Paid'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _sendInvoice,
              icon: const Icon(Icons.email, size: 20),
              label: const Text('Send'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(color: Theme.of(context).primaryColor),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return Colors.green;
      case 'overdue':
        return Colors.red;
      case 'sent':
        return Colors.blue;
      case 'draft':
        return Colors.orange;
      case 'cancelled':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }
}

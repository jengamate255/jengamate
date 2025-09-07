import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jengamate/models/invoice_model.dart';
import 'package:jengamate/services/invoice_service.dart';
import 'package:jengamate/widgets/loading_indicator.dart';
import 'package:jengamate/widgets/error_display.dart';
import 'package:jengamate/ui/design_system/components/jm_card.dart';
import 'package:jengamate/ui/design_system/tokens/spacing.dart';
import 'package:intl/intl.dart';

class InvoiceDetailsScreen extends StatefulWidget {
  final String orderId;

  const InvoiceDetailsScreen({Key? key, required this.orderId}) : super(key: key);

  @override
  _InvoiceDetailsScreenState createState() => _InvoiceDetailsScreenState();
}

class _InvoiceDetailsScreenState extends State<InvoiceDetailsScreen> {
  late InvoiceService _invoiceService;
  final _dateFormat = DateFormat('MMM dd, yyyy');
  final _currencyFormat = NumberFormat.currency(symbol: 'TSh ', decimalDigits: 2);

  @override
  void initState() {
    super.initState();
    _invoiceService = Provider.of<InvoiceService>(context, listen: false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoice Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () {
              // TODO: Implement PDF download functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Downloading invoice...')),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<InvoiceModel?>(
        future: _invoiceService.getInvoiceByOrderId(widget.orderId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingIndicator();
          }
          if (snapshot.hasError) {
            return ErrorDisplay(message: 'Error loading invoice: ${snapshot.error}');
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return const ErrorDisplay(message: 'No invoice found for this order.');
          }

          final invoice = snapshot.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                _buildInvoiceHeader(invoice),
                const SizedBox(height: JMSpacing.lg),
                
                // Customer and Order Info
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildCustomerInfo(invoice),
                    ),
                    const SizedBox(width: 16.0),
                    Expanded(
                      child: _buildOrderInfo(invoice),
                    ),
                  ],
                ),
                
                const SizedBox(height: JMSpacing.lg),
                
                // Invoice Items
                _buildInvoiceItems(invoice),
                
                const SizedBox(height: JMSpacing.lg),
                
                // Totals
                _buildInvoiceTotals(invoice),
                
                const SizedBox(height: JMSpacing.lg),
                
                // Notes and Terms
                if (invoice.notes != null || invoice.termsAndConditions != null) ...[
                  _buildNotesAndTerms(invoice),
                  const SizedBox(height: JMSpacing.lg),
                ],
                
                // Status
                _buildStatusSection(invoice),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInvoiceHeader(InvoiceModel invoice) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'INVOICE',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '#${invoice.invoiceNumber}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'JengaMate',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text('Building Connections, One Trade at a Time'),
          ],
        ),
      ],
    );
  }

  Widget _buildCustomerInfo(InvoiceModel invoice) {
    return JMCard(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bill To',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8.0),
            Text(
              invoice.customerName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            if (invoice.customerCompany != null && invoice.customerCompany!.isNotEmpty)
              Text(invoice.customerCompany!),
            Text(invoice.customerEmail),
            if (invoice.customerPhone != null) Text(invoice.customerPhone!),
            if (invoice.customerAddress != null) Text(invoice.customerAddress!),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderInfo(InvoiceModel invoice) {
    return JMCard(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Invoice Date', _dateFormat.format(invoice.issueDate)),
            _buildInfoRow('Due Date', _dateFormat.format(invoice.dueDate)),
            _buildInfoRow('Order ID', invoice.orderId ?? 'N/A'),
            _buildInfoRow('Status', _capitalize(invoice.status)),
            if (invoice.paymentMethod != null)
              _buildInfoRow('Payment Method', _capitalize(invoice.paymentMethod!)),
            if (invoice.referenceNumber != null)
              _buildInfoRow('Reference', invoice.referenceNumber!),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(value),
        ],
      ),
    );
  }

  Widget _buildInvoiceItems(InvoiceModel invoice) {
    return JMCard(
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8.0),
                topRight: Radius.circular(8.0),
              ),
            ),
            child: const Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text('Description', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  child: Text('Qty', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                ),
                Expanded(
                  child: Text('Price', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.right),
                ),
                Expanded(
                  child: Text('Total', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.right),
                ),
              ],
            ),
          ),
          
          // Items
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: invoice.items.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = invoice.items[index];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 12.0),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(item.description),
                    ),
                    Expanded(
                      child: Text(
                        item.quantity.toString(),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        _currencyFormat.format(item.unitPrice),
                        textAlign: TextAlign.right,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        _currencyFormat.format(item.total),
                        textAlign: TextAlign.right,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceTotals(InvoiceModel invoice) {
    return Align(
      alignment: Alignment.centerRight,
      child: SizedBox(
        width: 300,
        child: JMCard(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildTotalRow('Subtotal', invoice.subtotal),
                if (invoice.discountAmount > 0)
                  _buildTotalRow('Discount', -invoice.discountAmount),
                _buildTotalRow('Tax (${invoice.taxRate.toStringAsFixed(1)}%)', invoice.subtotal * (invoice.taxRate / 100)),
                const Divider(),
                _buildTotalRow(
                  'Total',
                  invoice.subtotal + (invoice.subtotal * (invoice.taxRate / 100)) - invoice.discountAmount,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                _buildTotalRow('Amount Paid', 0), // You'll need to calculate this based on payments
                _buildTotalRow(
                  'Amount Due',
                  invoice.subtotal + (invoice.subtotal * (invoice.taxRate / 100)) - invoice.discountAmount, // Adjust if you have payments
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTotalRow(String label, double amount, {TextStyle? style}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            _currencyFormat.format(amount),
            style: style,
          ),
        ],
      ),
    );
  }

  Widget _buildNotesAndTerms(InvoiceModel invoice) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (invoice.notes != null) ...[
          Expanded(
            child: _buildInfoCard('Notes', invoice.notes!),
          ),
          const SizedBox(width: 16.0),
        ],
        if (invoice.termsAndConditions != null)
          Expanded(
            child: _buildInfoCard('Terms & Conditions', invoice.termsAndConditions!),
          ),
      ],
    );
  }

  Widget _buildInfoCard(String title, String content) {
    return JMCard(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8.0),
            Text(content),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusSection(InvoiceModel invoice) {
    Color statusColor;
    switch (invoice.status.toLowerCase()) {
      case 'paid':
        statusColor = Colors.green;
        break;
      case 'overdue':
        statusColor = Colors.red;
        break;
      case 'pending':
      case 'sent':
        statusColor = Colors.orange;
        break;
      case 'cancelled':
        statusColor = Colors.grey;
        break;
      default:
        statusColor = Theme.of(context).primaryColor;
    }

    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
        decoration: BoxDecoration(
          color: statusColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20.0),
          border: Border.all(color: statusColor.withOpacity(0.3)),
        ),
        child: Text(
          _capitalize(invoice.status),
          style: TextStyle(
            color: statusColor,
            fontWeight: FontWeight.bold,
            fontSize: 16.0,
          ),
        ),
      ),
    );
  }

  String _capitalize(String input) {
    if (input.isEmpty) return input;
    return input[0].toUpperCase() + input.substring(1).toLowerCase();
  }
}

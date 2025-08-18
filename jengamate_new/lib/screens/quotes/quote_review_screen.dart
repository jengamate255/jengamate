import 'package:flutter/material.dart';
import 'package:jengamate/models/quote_model.dart';
import 'package:jengamate/models/rfq_model.dart';
import 'package:jengamate/services/database_service.dart';
import 'package:intl/intl.dart';

class QuoteReviewScreen extends StatelessWidget {
  final QuoteModel quote;
  final RFQModel rfq;

  const QuoteReviewScreen({super.key, required this.quote, required this.rfq});

  @override
  Widget build(BuildContext context) {
    final dbService = DatabaseService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Quotation'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const Divider(height: 32),
                _buildItemDetails(context),
                const Divider(height: 32),
                _buildFooter(context),
                const SizedBox(height: 32),
                _buildActionButtons(context, dbService),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'QUOTATION',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('Quote #: ${quote.id.substring(0, 8)}'),
            Text('Date: ${DateFormat.yMd().format(quote.createdAt)}'),
          ],
        ),
      ],
    );
  }

  Widget _buildItemDetails(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Items',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        DataTable(
          columns: const [
            DataColumn(label: Text('Description')),
            DataColumn(label: Text('Qty')),
            DataColumn(label: Text('Unit Price')),
            DataColumn(label: Text('Total')),
          ],
          rows: [
            DataRow(cells: [
              DataCell(Text(rfq.productName)),
              DataCell(Text(rfq.quantity.toString())),
              DataCell(Text(NumberFormat.currency(symbol: 'TSh ').format(quote.price))),
              DataCell(Text(NumberFormat.currency(symbol: 'TSh ').format(quote.price * rfq.quantity))),
            ]),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'Total: ${NumberFormat.currency(symbol: 'TSh ').format(quote.price * rfq.quantity)}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Notes',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        Text(quote.notes),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, DatabaseService dbService) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () {
            // TODO: Implement request modification logic
          },
          child: const Text('Request Modification'),
        ),
        const SizedBox(width: 16),
        ElevatedButton(
          onPressed: () async {
            // TODO: Implement confirm quote logic
          },
          child: const Text('Confirm Quote'),
        ),
      ],
    );
  }
}
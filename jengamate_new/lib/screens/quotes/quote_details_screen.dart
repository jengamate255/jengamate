import 'package:flutter/material.dart';
import 'package:jengamate/models/quote_model.dart';
import 'package:jengamate/models/rfq_model.dart';
import 'package:jengamate/models/user_model.dart';
import 'package:jengamate/services/database_service.dart';
import 'package:intl/intl.dart';

class QuoteDetailsScreen extends StatelessWidget {
  final QuoteModel quote;
  final RFQModel rfq;

  const QuoteDetailsScreen({super.key, required this.quote, required this.rfq});

  @override
  Widget build(BuildContext context) {
    final dbService = DatabaseService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pro Forma Invoice'),
      ),
      body: FutureBuilder<List<UserModel?>>(
        future: Future.wait([
          dbService.getUser(rfq.userId ?? ''),
          dbService.getUser(quote.supplierId ?? ''),
        ]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData || snapshot.data!.contains(null)) {
            return const Center(child: Text('Error loading details.'));
          }

          final customer = snapshot.data![0]!;
          final supplier = snapshot.data![1]!;

          return SingleChildScrollView(
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
                    _buildPartyDetails(context, 'Supplier', supplier),
                    const SizedBox(height: 16),
                    _buildPartyDetails(context, 'Customer', customer),
                    const Divider(height: 32),
                    _buildItemDetails(context),
                    const Divider(height: 32),
                    _buildFooter(context),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'PRO FORMA INVOICE',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('Invoice #: ${quote.id.substring(0, 8)}'),
            Text('Date: ${DateFormat.yMd().format(quote.createdAt)}'),
          ],
        ),
      ],
    );
  }

  Widget _buildPartyDetails(BuildContext context, String title, UserModel user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(user.displayName),
        Text(user.email ?? 'No email'),
        Text(user.phoneNumber ?? 'No phone number'),
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
        const SizedBox(height: 16),
        Text(
          'Terms & Conditions',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const Text('Payment is due upon receipt.'),
      ],
    );
  }
}
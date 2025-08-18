import 'package:flutter/material.dart';
import 'package:jengamate/models/quote_model.dart';
import 'package:jengamate/models/rfq_model.dart';
import 'package:jengamate/services/database_service.dart';
import 'package:jengamate/screens/rfq/widgets/quote_submission_form.dart';

import 'package:jengamate/screens/quotes/quote_review_screen.dart';
import 'package:intl/intl.dart';

class RfqDetailsScreen extends StatefulWidget {
  final String rfqId;

  const RfqDetailsScreen({super.key, required this.rfqId});

  @override
  State<RfqDetailsScreen> createState() => _RfqDetailsScreenState();
}

class _RfqDetailsScreenState extends State<RfqDetailsScreen> {

  @override
  Widget build(BuildContext context) {
    final dbService = DatabaseService();

    return FutureBuilder<RFQModel?>(
      future: dbService.getRFQ(widget.rfqId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: const Text('Loading RFQ...')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Error')),
            body: const Center(child: Text('Error loading RFQ details.')),
          );
        }

        final rfq = snapshot.data!;

        return Scaffold(
          appBar: AppBar(
            title: Text(rfq.productName),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Product: ${rfq.productName}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Quantity: ${rfq.quantity}'),
                const SizedBox(height: 8),
                Text('Status: ${rfq.status}'),
                const SizedBox(height: 16),
                const Text('Submitted Quotes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Expanded(
                  child: StreamBuilder<List<QuoteModel>>(
                    stream: dbService.streamQuotes(rfq.id),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }
                      final quotes = snapshot.data ?? [];
                      if (quotes.isEmpty) {
                        return const Center(child: Text('No quotes submitted yet.'));
                      }
                      return ListView.builder(
                        itemCount: quotes.length,
                        itemBuilder: (context, index) {
                          final quote = quotes[index];
                          return Card(
                            child: ListTile(
                              title: Text('Supplier: ${quote.supplierId}'),
                              subtitle: Text(
                                  'Price: ${NumberFormat.currency(symbol: 'TSh ').format(quote.price)}'),
                              trailing: const Icon(Icons.arrow_forward_ios),
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => QuoteReviewScreen(
                                      quote: quote,
                                      rfq: rfq,
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (_) => QuoteSubmissionForm(rfqId: rfq.id),
              );
            },
            child: const Icon(Icons.add_comment),
          ),
        );
      },
    );
  }
}

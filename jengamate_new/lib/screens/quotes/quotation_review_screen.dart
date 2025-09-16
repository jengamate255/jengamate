import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jengamate/services/user_state_provider.dart';
import '../../models/quotation_model.dart';
import '../../services/quotation_service.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/error_display.dart';

class QuotationReviewScreen extends StatefulWidget {
  final String quotationId;

    const QuotationReviewScreen({super.key, required this.quotationId});

  @override
  _QuotationReviewScreenState createState() => _QuotationReviewScreenState();
}

class _QuotationReviewScreenState extends State<QuotationReviewScreen> {
  late QuotationService _quotationService;

  @override
  void initState() {
    super.initState();
    _quotationService = Provider.of<QuotationService>(context, listen: false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quotation Review'),
      ),
      body: StreamBuilder<Quotation>(
        stream: _quotationService.getQuotation(widget.quotationId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingIndicator();
          }
          if (snapshot.hasError) {
            return ErrorDisplay(message: 'Error: ${snapshot.error}');
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return const ErrorDisplay(message: 'Quotation not found.');
          }

          final quotation = snapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Quotation ID: ${quotation.id}', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text('Inquiry ID: ${quotation.inquiryId}'),
                Text('Supplier ID: ${quotation.supplierId}'),
                Text('Engineer ID: ${quotation.engineerId}'),
                const SizedBox(height: 16),
                Text('Products:', style: Theme.of(context).textTheme.titleMedium),
                ...quotation.products.map((product) => Padding(
                  padding: const EdgeInsets.only(left: 8.0, bottom: 4.0),
                  child: Text('${product['name']} - ${product['quantity']} x \$${product['price']}'),
                )).toList(),
                const SizedBox(height: 16),
                Text('Total Amount: \$${quotation.totalAmount.toStringAsFixed(2)}', style: Theme.of(context).textTheme.titleLarge),
                Text('Status: ${quotation.status}', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 24),
                if (quotation.status == 'pending_review')
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      ElevatedButton(
                        onPressed: () async {
                          try {
                            await _quotationService.confirmQuotation(quotation.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Quotation confirmed and order generated!')),
                            );
                            // Navigate back or to order details
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed to confirm quotation: $e')),
                            );
                          }
                        },
                        child: const Text('Confirm Quote'),
                      ),
                      OutlinedButton(
                        onPressed: () async {
                          // Implement request modification logic
                          await _quotationService.updateQuotationStatus(quotation.id, 'modification_requested');
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Modification requested.')),
                          );
                        },
                        child: const Text('Request Modification'),
                      ),
                    ],
                  ),
                if (quotation.status == 'confirmed')
                  Center(
                    child: Text(
                      'This quotation has been confirmed. An order has been generated.',
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                  ),
                if (quotation.status == 'modification_requested')
                  Center(
                    child: Text(
                      'Modification has been requested for this quotation. Please await supplier response.',
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
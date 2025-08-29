import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jengamate/models/quote_model.dart';
import 'package:jengamate/models/rfq_model.dart';
import 'package:jengamate/services/database_service.dart';
import 'package:intl/intl.dart';
import 'package:jengamate/models/order_model.dart';
import 'package:jengamate/models/enums/order_enums.dart'; // Added import for OrderStatus and OrderType
import 'package:jengamate/utils/logger.dart'; // Import Logger

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
          onPressed: () async {
            await _requestModification(context, dbService);
          },
          child: const Text('Request Modification'),
        ),
        const SizedBox(width: 16),
        ElevatedButton(
          onPressed: () async {
            await _confirmQuote(context, dbService);
          },
          child: const Text('Confirm Quote'),
        ),
      ],
    );
  }
  
  Future<void> _requestModification(BuildContext context, DatabaseService dbService) async {
    final TextEditingController messageController = TextEditingController();
    
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          icon: const Icon(
            Icons.edit_note,
            color: Colors.orange,
            size: 48,
          ),
          title: const Text(
            'Request Quote Modification',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.orange,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Please describe the modifications you\'d like the supplier to make to this quote:',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current Quote Details:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('Product: ${rfq.productName}', style: TextStyle(color: Colors.blue.shade700)),
                      Text('Quantity: ${rfq.quantity}', style: TextStyle(color: Colors.blue.shade700)),
                      Text('Quoted Price: TSh ${quote.price.toStringAsFixed(2)}', style: TextStyle(color: Colors.blue.shade700)),
                      Text('Total: TSh ${(quote.price * rfq.quantity).toStringAsFixed(2)}', style: TextStyle(color: Colors.blue.shade700)),
                      if (quote.deliveryDate != null)
                        Text('Delivery Date: ${quote.deliveryDate!.toLocal().toString().split(' ')[0]}', style: TextStyle(color: Colors.blue.shade700)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: messageController,
                  decoration: const InputDecoration(
                    labelText: 'Modification Request',
                    hintText: 'e.g., "Could you adjust the price to TSh 15,000 per unit?" or "Can you deliver 2 weeks earlier?"',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (messageController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter your modification request')),
                  );
                  return;
                }
                
                try {
                  // Update RFQ status to indicate modification requested
                  await dbService.updateRFQStatus(rfq.id, 'modification_requested');
                  
                  // Here you could also create a message/notification to the supplier
                  Logger.log('Modification requested for quote ${quote.id}: ${messageController.text}');
                  
                  Navigator.of(context).pop(); // Close dialog
                  
                  // Show success message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Modification request sent to supplier'),
                      backgroundColor: Colors.green,
                      action: SnackBarAction(
                        label: 'OK',
                        textColor: Colors.white,
                        onPressed: () {},
                      ),
                    ),
                  );
                  
                  // Go back to previous screen
                  Navigator.of(context).pop();
                  
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to send modification request: $e')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('Send Request'),
            ),
          ],
        );
      },
    );
  }
  
  Future<void> _confirmQuote(BuildContext context, DatabaseService dbService) async {
    // Create a local variable to hold the quote that might be updated
    QuoteModel currentQuote = quote;

    try {
      // Enhanced logging to inspect IDs before validation
      Logger.log('=== Quote Confirmation Debug Info ===');
      Logger.log('Quote ID: ${currentQuote.id}');
      Logger.log('Quote created at: ${currentQuote.createdAt}');
      Logger.log('Quote updated at: ${currentQuote.updatedAt}');
      Logger.log('Quote price: ${currentQuote.price}');
      Logger.log('Quote notes: ${currentQuote.notes}');
      Logger.log('Quote delivery date: ${currentQuote.deliveryDate}');
      Logger.log('Quote supplierId: "${currentQuote.supplierId}" (Type: ${currentQuote.supplierId.runtimeType})');
      Logger.log('Quote supplierId isEmpty: ${currentQuote.supplierId?.isEmpty ?? "null"}');
      Logger.log('RFQ ID: ${rfq.id}');
      Logger.log('RFQ Buyer ID: "${rfq.userId}" (Type: ${rfq.userId.runtimeType})');
      Logger.log('RFQ userId isEmpty: ${rfq.userId?.isEmpty ?? "null"}');
      Logger.log('=====================================');

      // Enhanced validation with detailed error messages
      if (rfq.userId == null || rfq.userId!.isEmpty) {
        Logger.logError('Quote confirmation failed: RFQ buyer ID is missing', {
          'rfqId': rfq.id,
          'rfqUserId': rfq.userId,
          'quoteId': currentQuote.id,
        }, StackTrace.current);
        throw Exception('RFQ buyer ID is missing. This quote cannot be confirmed without a valid buyer.');
      }

      if (currentQuote.supplierId == null || currentQuote.supplierId!.isEmpty) {
        Logger.logError('Quote confirmation failed: Quote supplier ID is missing', {
          'rfqId': rfq.id,
          'quoteId': currentQuote.id,
          'quoteSupplierId': currentQuote.supplierId,
          'quoteCreatedAt': currentQuote.createdAt.toIso8601String(),
        }, StackTrace.current);

        // Try to find the supplier from the database by looking for quotes with the same RFQ ID
        try {
          final quotesForRFQ = await FirebaseFirestore.instance
              .collection('quotes')
              .where('rfqId', isEqualTo: rfq.id)
              .where('supplierId', isNotEqualTo: null)
              .where('supplierId', isNotEqualTo: '')
              .get();

          if (quotesForRFQ.docs.isNotEmpty) {
            final validQuote = QuoteModel.fromFirestore(quotesForRFQ.docs.first);
            if (validQuote.supplierId != null && validQuote.supplierId!.isNotEmpty) {
              Logger.log('Found valid supplier ID from another quote: ${validQuote.supplierId}');
              // Update the quote with the correct supplier ID
              await FirebaseFirestore.instance
                  .collection('quotes')
                  .doc(currentQuote.id)
                  .update({'supplierId': validQuote.supplierId});

              // Update the local quote object for further processing
              currentQuote = QuoteModel(
                id: currentQuote.id,
                rfqId: currentQuote.rfqId,
                supplierId: validQuote.supplierId,
                price: currentQuote.price,
                notes: currentQuote.notes,
                deliveryDate: currentQuote.deliveryDate,
                createdAt: currentQuote.createdAt,
                updatedAt: DateTime.now(),
              );

              Logger.log('Quote supplier ID updated successfully');
            }
          } else {
            throw Exception('No valid supplier found for this RFQ. Please contact the supplier to resubmit their quote.');
          }
        } catch (updateError) {
          Logger.logError('Failed to update quote supplier ID', updateError, StackTrace.current);
          throw Exception('Quote supplier ID is missing and could not be recovered. Please contact the supplier to resubmit their quote.');
        }
      }

      // 1. Update RFQ status to 'accepted'
      Logger.log('Updating RFQ status to accepted...');
      await dbService.updateRFQStatus(rfq.id, 'accepted');
      Logger.log('RFQ status updated successfully');

      // 2. Create an order based on the accepted quote
      Logger.log('Creating order from quote...');
      final newOrder = OrderModel(
        id: '', // Firestore will generate this
        buyerId: rfq.userId, // Assuming RFQ userId is the buyer
        supplierId: currentQuote.supplierId,
        rfqId: rfq.id,
        totalAmount: currentQuote.price * rfq.quantity,
        status: OrderStatus.pending, // Initial status
        type: OrderType.product, // Assuming it's a product order
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        orderNumber: 'ORD-${DateTime.now().millisecondsSinceEpoch}',
      );

      Logger.log('Order data prepared: ${newOrder.toMap()}');
      await dbService.createOrder(newOrder);
      Logger.log('Order created successfully');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quote confirmed and order created!')),
      );
      Navigator.of(context).pop(); // Go back to RFQ details
    } catch (e) {
      Logger.logError('Quote confirmation failed', e, StackTrace.current);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to confirm quote: $e'),
          duration: const Duration(seconds: 5), // Show longer for detailed error messages
        ),
      );
    }
  }
}
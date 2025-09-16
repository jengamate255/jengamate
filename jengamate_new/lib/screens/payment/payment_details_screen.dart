import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jengamate/services/user_state_provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:jengamate/models/payment_model.dart';
import 'package:jengamate/models/user_model.dart';
import 'package:jengamate/services/payment_service.dart';
import 'package:jengamate/services/console_error_handler.dart';
import 'package:jengamate/ui/design_system/components/jm_card.dart';
import 'package:jengamate/ui/design_system/tokens/spacing.dart';
import 'package:jengamate/ui/design_system/tokens/typography.dart';

class PaymentDetailsScreen extends StatefulWidget {
  final String paymentId;

  const PaymentDetailsScreen({Key? key, required this.paymentId}) : super(key: key);

  @override
  State<PaymentDetailsScreen> createState() => _PaymentDetailsScreenState();
}

class _PaymentDetailsScreenState extends State<PaymentDetailsScreen> {
  PaymentModel? _payment;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchPaymentDetails();
  }

  Future<void> _fetchPaymentDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final paymentService = Provider.of<PaymentService>(context, listen: false);
      final payment = await paymentService.getPaymentById(widget.paymentId);
      setState(() {
        _payment = payment;
      });
    } catch (e, st) {
      ConsoleErrorHandler.report(e, st);
      setState(() {
        _errorMessage = 'Failed to load payment details. Please try again.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _downloadPaymentProof(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      ConsoleErrorHandler.report(
          'Could not launch $url', StackTrace.current);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open payment proof.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<UserModel?>();
    final isAdmin = currentUser?.role == UserRole.admin;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Details'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(JmSpacing.spacing200),
                    child: Text(
                      _errorMessage!,
                      style: JmTypography.bodyStrong(context)
                          ?.copyWith(color: Theme.of(context).colorScheme.error),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : _payment == null
                  ? Center(
                      child: Text(
                        'Payment not found.',
                        style: JmTypography.bodyStrong(context),
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(JmSpacing.spacing200),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildPaymentSummaryCard(_payment!),
                          JmSpacing.verticalSpacing(JmSpacing.spacing200),
                          if (_payment!.paymentProofUrl != null)
                            _buildPaymentProofSection(_payment!.paymentProofUrl!, isAdmin),
                          JmSpacing.verticalSpacing(JmSpacing.spacing200),
                          _buildAssociatedInvoiceSection(_payment!),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildPaymentSummaryCard(PaymentModel payment) {
    return JmCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment Summary',
            style: JmTypography.heading6(context),
          ),
          JmSpacing.verticalSpacing(JmSpacing.spacing100),
          _buildDetailRow('Payment ID:', payment.id),
          _buildDetailRow('Amount:', '\$${payment.amount.toStringAsFixed(2)}'),
          _buildDetailRow('Method:', payment.paymentMethod),
          _buildDetailRow('Status:', payment.status),
          _buildDetailRow(
            'Date:',
            DateFormat('yyyy-MM-dd HH:mm').format(payment.timestamp),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentProofSection(String proofUrl, bool isAdmin) {
    return JmCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment Proof',
            style: JmTypography.heading6(context),
          ),
          JmSpacing.verticalSpacing(JmSpacing.spacing100),
          Text(
            'Proof available at:',
            style: JmTypography.body(context),
          ),
          GestureDetector(
            onTap: () => _downloadPaymentProof(proofUrl),
            child: Text(
              proofUrl,
              style: JmTypography.bodyLink(context),
            ),
          ),
          if (isAdmin)
            Padding(
              padding: const EdgeInsets.only(top: JmSpacing.spacing100),
              child: ElevatedButton(
                onPressed: () => _downloadPaymentProof(proofUrl),
                child: const Text('Download Proof'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAssociatedInvoiceSection(PaymentModel payment) {
    return JmCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Associated Invoice',
            style: JmTypography.heading6(context),
          ),
          JmSpacing.verticalSpacing(JmSpacing.spacing100),
          if (payment.invoiceId != null)
            _buildDetailRow('Invoice ID:', payment.invoiceId!),
          if (payment.invoiceId == null)
            Text(
              'No associated invoice.',
              style: JmTypography.body(context),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: JmSpacing.spacing50),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100, // Fixed width for labels
            child: Text(
              label,
              style: JmTypography.bodyStrong(context),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: JmTypography.body(context),
            ),
          ),
        ],
      ),
    );
  }
}

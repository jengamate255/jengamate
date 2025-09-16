import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jengamate/services/user_state_provider.dart';
import 'package:jengamate/models/invoice_model.dart';
import 'package:jengamate/models/user_model.dart'; // Import UserModel
import 'package:jengamate/services/invoice_service.dart';
import 'package:jengamate/services/email_service.dart';
import 'package:jengamate/services/console_error_handler.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:jengamate/screens/order/payment_screen.dart';
import 'package:jengamate/ui/design_system/components/jm_card.dart';
import 'package:jengamate/ui/design_system/tokens/spacing.dart';

class InvoiceDetailsScreen extends StatefulWidget {
  final String invoiceId;

  const InvoiceDetailsScreen({super.key, required this.invoiceId});

  @override
  State<InvoiceDetailsScreen> createState() => _InvoiceDetailsScreenState();
}

class _InvoiceDetailsScreenState extends State<InvoiceDetailsScreen> {
  bool _isLoading = true;
  InvoiceModel? _invoice;

  @override
  void initState() {
    super.initState();
    _loadInvoice();
  }

  Future<void> _loadInvoice() async {
    try {
      final invoiceService =
          Provider.of<InvoiceService>(context, listen: false);
      // Use auto-population method to ensure invoice items are populated
      final invoice =
          await invoiceService.getInvoiceWithItems(widget.invoiceId);

      if (mounted) {
        setState(() {
          _invoice = invoice;
          _isLoading = false;
        });
      }
    } catch (e) {
      ConsoleErrorHandler.logError(
          'Failed to load invoice with populated items', e, StackTrace.current);
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load invoice: $e')),
        );
      }
    }
  }

  void _navigateToPayment(InvoiceModel invoice) {
    if (invoice.orderId == null || invoice.orderId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This invoice is not linked to an order.'
              '\n\nStandalone invoices cannot be processed through payment.'
              '\n\nPlease contact administrator if this requires payment processing.'),
          duration: Duration(seconds: 5),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentScreen(orderId: invoice.orderId!),
      ),
    ).then((result) {
      if (result != null && result is String) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result)),
        );
      }
      _loadInvoice(); // Refresh invoice data after payment attempt
    });
  }

  Future<void> _sendInvoice() async {
    if (_invoice == null) return;

    // Validate that we have an email address to send to
    if (_invoice!.customerEmail.isEmpty) {
      _showEmailInputDialog();
      return;
    }

    // Show loading dialog
    _showSendingProgress();

    try {
      final emailService = Provider.of<EmailService>(context, listen: false);

      // Send invoice using branded template
      final success = await emailService.sendInvoiceEmailQuickly(
        invoice: _invoice!,
        recipientEmail: _invoice!.customerEmail,
      );

      // Close loading dialog
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invoice sent successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          // Refresh invoice to get updated sent status
          await _loadInvoice();
        }
        ConsoleErrorHandler.logSuccess('Invoice sent successfully');
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Failed to send invoice. Please try again.')),
          );
        }
      }
    } catch (e) {
      // Close loading dialog
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      ConsoleErrorHandler.logError(
          'Failed to send invoice', e, StackTrace.current);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send invoice: $e')),
        );
      }
    }
  }

  void _showSendingProgress() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Sending invoice email...'),
            ],
          ),
        );
      },
    );
  }

  void _showEmailInputDialog() {
    final TextEditingController emailController =
        TextEditingController(text: _invoice!.customerEmail);
    final _formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Send Invoice'),
          content: Form(
            key: _formKey,
            child: TextFormField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email Address',
                hintText: 'Enter customer email address',
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Email address is required';
                }
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                    .hasMatch(value)) {
                  return 'Please enter a valid email address';
                }
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  final email = emailController.text.trim();

                  // Close the dialog first
                  Navigator.of(context).pop();

                  // Show loading progress
                  _showSendingProgress();

                  // Send the invoice with the provided email
                  try {
                    final invoiceService =
                        Provider.of<InvoiceService>(context, listen: false);
                    final emailService =
                        Provider.of<EmailService>(context, listen: false);

                    // Update the invoice with the new email if it changed
                    if (email != _invoice!.customerEmail) {
                      final updatedInvoice =
                          _invoice!.copyWith(customerEmail: email);
                      await invoiceService.updateInvoice(updatedInvoice);
                    }

                    // Use the new EmailService with branded templates
                    final success = await emailService.sendInvoiceEmailQuickly(
                      invoice: _invoice!,
                      recipientEmail: email,
                    );

                    // Close loading dialog
                    if (mounted && Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    }

                    if (success && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Invoice sent successfully!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                      // Refresh to get updated sent status
                      await _loadInvoice();
                    } else if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                                'Failed to send invoice. Please try again.')),
                      );
                    }

                    ConsoleErrorHandler.logSuccess(
                        'Invoice sent successfully to $email');
                  } catch (e) {
                    // Close loading dialog
                    if (mounted && Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    }

                    ConsoleErrorHandler.logError(
                        'Failed to send invoice', e, StackTrace.current);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to send invoice: $e')),
                      );
                    }
                  }
                }
              },
              child: const Text('Send'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _downloadPdf() async {
    if (_invoice == null) return;

    try {
      final invoiceService =
          Provider.of<InvoiceService>(context, listen: false);
      final pdfUrl = await invoiceService.generatePdf(_invoice!);

      // Show success message that PDF was generated
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF downloaded successfully!')),
        );
      }

      // Try to open PDF viewer (optional, don't throw if it fails)
      try {
        if (await canLaunchUrl(Uri.parse(pdfUrl))) {
          await launchUrl(Uri.parse(pdfUrl));
        } else {
          ConsoleErrorHandler.logWarning(
              'Could not launch PDF viewer - using software default');
          // Don't show error message since PDF was already downloaded successfully
        }
      } catch (viewerError) {
        ConsoleErrorHandler.logWarning(
            'PDF viewer launch failed, but download succeeded: $viewerError');
        // PDF was downloaded successfully, just couldn't open viewer
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
      return Scaffold(
        appBar: AppBar(
          title: const Text('Invoice Details'),
          backgroundColor: Theme.of(context).primaryColor,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_invoice == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Invoice Details'),
          backgroundColor: Theme.of(context).primaryColor,
        ),
        body: const Center(child: Text('Invoice not found')),
      );
    }

    final invoice = _invoice!;
    final dateFormat = DateFormat('MMM dd, yyyy');
    final currencyFormat = NumberFormat.currency(symbol: 'TSh ');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoice Details'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _downloadPdf,
            tooltip: 'Download PDF',
          ),
          IconButton(
            icon: const Icon(Icons.email),
            onPressed: _sendInvoice,
            tooltip: 'Send Invoice',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(JMSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            _buildHeaderCard(invoice, dateFormat),

            const SizedBox(height: JMSpacing.lg),

            // Billing Information Section
            _buildBillingSection(invoice),

            const SizedBox(height: JMSpacing.lg),

            // Items Section
            _buildItemsSection(invoice, currencyFormat),

            const SizedBox(height: JMSpacing.lg),

            // Totals Section
            _buildTotalsSection(invoice, currencyFormat),

            const SizedBox(height: JMSpacing.lg),

            // Notes Section
            if (invoice.notes != null ||
                invoice.termsAndConditions != null) ...[
              _buildNotesSection(invoice),
            ],
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(invoice),
    );
  }

  Widget _buildHeaderCard(InvoiceModel invoice, DateFormat dateFormat) {
    return JMCard(
      child: Container(
        padding: const EdgeInsets.all(JMSpacing.md),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).primaryColor.withOpacity(0.1),
              Colors.transparent
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'INVOICE',
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '#${invoice.invoiceNumber}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: _getStatusColor(invoice.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _getStatusColor(invoice.status).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    invoice.status.toUpperCase(),
                    style: TextStyle(
                      color: _getStatusColor(invoice.status),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildDateColumn(
                      'Issue Date', dateFormat.format(invoice.issueDate)),
                ),
                Expanded(
                  child: _buildDateColumn(
                      'Due Date', dateFormat.format(invoice.dueDate)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildBillingSection(InvoiceModel invoice) {
    final currentUser = context.watch<UserModel?>(); // Access the current user

    String billToName = invoice.customerName;
    String? billToPhone = invoice.customerPhone;
    String? billToAddress = invoice.customerAddress;
    String billToEmail = invoice.customerEmail;
    String? billToCompany = invoice.customerCompany;

    // If the invoice is for the current user, use their profile data
    if (currentUser != null && currentUser?.uid == invoice.customerId) {
      billToName = currentUser.displayName;
      billToPhone = currentUser.phoneNumber ?? invoice.customerPhone; // Prefer user's phone
      billToAddress = currentUser.address ?? invoice.customerAddress; // Prefer user's address
      billToEmail = currentUser.email ?? invoice.customerEmail; // Prefer user's email
      billToCompany = currentUser.companyName ?? invoice.customerCompany; // Prefer user's company
    }

    return JMCard(
      child: Padding(
        padding: const EdgeInsets.all(JMSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Billing Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: JMSpacing.md),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // From (Company Info)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'From',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      const SizedBox(height: JMSpacing.sm),
                      const Text(
                        'JengaMate Ltd',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const Text('P.O. Box 12345'),
                      const Text('Dar es Salaam, Tanzania'),
                      const Text('Email: info@jengamate.co.tz'),
                      const Text('Phone: +255 712 345 678'),
                    ],
                  ),
                ),
                const SizedBox(width: JMSpacing.md),
                Container(
                  width: 1,
                  height: 120,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(width: JMSpacing.md),
                // To (Customer Info)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bill To',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      const SizedBox(height: JMSpacing.sm),
                      Text(
                        billToName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      if (billToAddress != null && billToAddress.isNotEmpty)
                        Text(billToAddress),
                      if (billToPhone != null && billToPhone.isNotEmpty)
                        Text('Phone: $billToPhone'),
                      Text(billToEmail),
                      if (billToCompany != null && billToCompany.isNotEmpty)
                        Text('Company: $billToCompany'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsSection(InvoiceModel invoice, NumberFormat currencyFormat) {
    return JMCard(
      child: Padding(
        padding: const EdgeInsets.all(JMSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Invoice Items',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  '${invoice.items.length} item${invoice.items.length != 1 ? 's' : ''}',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: JMSpacing.md),
            const Divider(),
            const SizedBox(height: JMSpacing.md),
            _buildItemsTable(invoice, currencyFormat),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalsSection(
      InvoiceModel invoice, NumberFormat currencyFormat) {
    return JMCard(
      child: Padding(
        padding: const EdgeInsets.all(JMSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Invoice Summary',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: JMSpacing.md),
            Container(
              padding: const EdgeInsets.all(JMSpacing.md),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: _buildTotals(invoice, currencyFormat),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesSection(InvoiceModel invoice) {
    return JMCard(
      child: Padding(
        padding: const EdgeInsets.all(JMSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Additional Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: JMSpacing.md),
            if (invoice.notes != null && invoice.notes!.isNotEmpty) ...[
              _buildInfoSection('Notes', invoice.notes!),
              const SizedBox(height: JMSpacing.md),
            ],
            if (invoice.termsAndConditions != null &&
                invoice.termsAndConditions!.isNotEmpty) ...[
              _buildInfoSection(
                  'Terms & Conditions', invoice.termsAndConditions!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: JMSpacing.xxs),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(JMSpacing.sm),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildItemsTable(InvoiceModel invoice, NumberFormat currencyFormat) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Table(
        border: TableBorder.symmetric(
          inside: BorderSide(color: Colors.grey.shade200),
        ),
        columnWidths: const {
          0: FlexColumnWidth(4), // Description - more space
          1: FlexColumnWidth(
              1.2), // Quantity - slightly more for better alignment
          2: FlexColumnWidth(1.8), // Unit Price - more space for currency
          3: FlexColumnWidth(1.8), // Total - more space for currency
        },
        children: [
          // Header
          TableRow(
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(8)),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text(
                  'Description',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text(
                  'Quantity',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Theme.of(context).primaryColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text(
                  'Unit Price',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Theme.of(context).primaryColor,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text(
                  'Total',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Theme.of(context).primaryColor,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
          // Items
          if (invoice.items.isEmpty) ...[
            TableRow(
              children: [
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text(
                    'No items found',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox.shrink(),
                const SizedBox.shrink(),
                const SizedBox.shrink(),
              ],
            )
          ] else
            ...invoice.items.map((item) => TableRow(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                  ),
                  children: [
                    // Description - always show, with fallback
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Text(
                        item.description.isNotEmpty
                            ? item.description
                            : 'Product Item',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    // Quantity - always show, with fallback
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Text(
                        item.quantity > 0 ? item.quantity.toString() : '1',
                        style: const TextStyle(
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    // Unit Price - always show, with fallback
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Text(
                        item.unitPrice >= 0
                            ? currencyFormat.format(item.unitPrice)
                            : currencyFormat.format(0.0),
                        style: const TextStyle(
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                    // Total - always show, calculated correctly
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Text(
                        currencyFormat.format(
                            (item.quantity > 0 ? item.quantity : 1) *
                                (item.unitPrice >= 0 ? item.unitPrice : 0.0)),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                )),
        ],
      ),
    );
  }

  Widget _buildTotals(InvoiceModel invoice, NumberFormat currencyFormat) {
    return Column(
      children: [
        // Subtotal
        _buildTotalRow('Subtotal', invoice.subtotal,
            currencyFormat: currencyFormat),
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

    // Don't show payment button for invoices without orderId
    if (invoice.orderId == null || invoice.orderId!.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          border: Border(
            top: BorderSide(color: Colors.orange.shade100, width: 1),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.info_outline, color: Colors.orange, size: 20),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'This standalone invoice cannot be processed through payment. Contact administrator for manual processing.',
                style: TextStyle(
                  color: Colors.orange,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
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
              onPressed: () => _navigateToPayment(invoice),
              icon: const Icon(Icons.payment, size: 20),
              label: const Text('Pay for Order'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
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

import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/email_template.dart';
import '../models/invoice_model.dart';
import '../models/order_model.dart';
import '../utils/logger.dart' as utils_logger;

class EmailService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionName = 'email_templates';

  // Template Management

  // Create a new email template
  Future<void> saveTemplate(EmailTemplate template) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(template.id)
          .set(template.toMap());
      utils_logger.Logger.log(
          '✅ Email template "${template.name}" saved successfully');
    } catch (e) {
      utils_logger.Logger.logError('Failed to save email template: $e', e);
      rethrow;
    }
  }

  // Get all email templates
  Stream<List<EmailTemplate>> getAllTemplates() {
    return _firestore
        .collection(_collectionName)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => EmailTemplate.fromFirestore(doc))
            .toList());
  }

  // Get templates by type
  Stream<List<EmailTemplate>> getTemplatesByType(EmailTemplateType type) {
    return _firestore
        .collection(_collectionName)
        .where('type', isEqualTo: type.toString().split('.').last)
        .where('isActive', isEqualTo: true)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => EmailTemplate.fromFirestore(doc))
            .toList());
  }

  // Get single template by ID
  Future<EmailTemplate?> getTemplate(String id) async {
    try {
      final doc = await _firestore.collection(_collectionName).doc(id).get();
      if (doc.exists) {
        return EmailTemplate.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      utils_logger.Logger.logError('Failed to get template $id: $e', e);
      return null;
    }
  }

  // Get default template by type
  Future<EmailTemplate?> getDefaultTemplate(EmailTemplateType type) async {
    try {
      final snapshot = await _firestore
          .collection(_collectionName)
          .where('type', isEqualTo: type.toString().split('.').last)
          .where('isActive', isEqualTo: true)
          .orderBy('updatedAt',
              descending: false) // Oldest first (manually created default)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return EmailTemplate.fromFirestore(snapshot.docs.first);
      }

      // If no custom template exists, return built-in default
      return _getBuiltInDefaultTemplate(type);
    } catch (e) {
      utils_logger.Logger.logError(
          'Failed to get default template for $type: $e', e);
      return _getBuiltInDefaultTemplate(type);
    }
  }

  // Delete template
  Future<void> deleteTemplate(String id) async {
    try {
      await _firestore.collection(_collectionName).doc(id).delete();
      utils_logger.Logger.log('🗑️ Email template deleted: $id');
    } catch (e) {
      utils_logger.Logger.logError('Failed to delete template $id: $e', e);
      rethrow;
    }
  }

  // Initialize built-in templates
  Future<void> initializeBuiltInTemplates() async {
    try {
      // Initialize invoice template
      await saveTemplate(EmailTemplate.invoiceTemplate);

      // Log initialization
      utils_logger.Logger.log('🔧 Built-in email templates initialized');
    } catch (e) {
      utils_logger.Logger.logError(
          'Failed to initialize built-in templates: $e', e);
    }
  }

  // Template Variable Processing

  // Replace variables in template with actual values
  String replaceVariables(String template, Map<String, dynamic> variables) {
    String result = template;

    // Replace all {variable_name} placeholders
    variables.forEach((key, value) {
      final placeholder = '{$key}';
      result = result.replaceAll(placeholder, value.toString());
    });

    return result;
  }

  // Generate variables from invoice
  Map<String, dynamic> generateInvoiceVariables(InvoiceModel invoice,
      [String? pdfUrl]) {
    final formattedDate = _formatDate(invoice.dueDate);
    final formattedTotal = invoice.formatCurrency(invoice.totalAmount);

    return {
      'customer_name': invoice.customerName.isNotEmpty
          ? invoice.customerName
          : 'Valued Customer',
      'invoice_number': invoice.invoiceNumber,
      'invoice_total': formattedTotal,
      'due_date': formattedDate,
      'payment_url': _generatePaymentUrl(invoice),
      'pdf_url': pdfUrl ?? 'https://example.com/download.pdf',
      'company_name': 'JengaMate Ltd',
      'company_email': 'info@jengamate.co.tz',
      'company_phone': '+255 712 345 678',
    };
  }

  // Email Sending

  // Send invoice email using template
  Future<bool> sendInvoiceEmail({
    required EmailTemplate template,
    required InvoiceModel invoice,
    required String recipientEmail,
    String? subject,
    String? htmlBody,
    String? textBody,
    String? pdfUrl,
  }) async {
    try {
      // Get or resolve variables
      final variables = generateInvoiceVariables(invoice, pdfUrl);

      // Use provided content or template content
      final subjectToUse = subject ?? template.subjectTemplate;
      final htmlToUse = htmlBody ?? template.htmlBodyTemplate;
      final textToUse = textBody ?? template.textBodyTemplate;

      // Replace variables in templates
      final resolvedSubject = replaceVariables(subjectToUse, variables);
      final resolvedHtmlBody = replaceVariables(htmlToUse, variables);
      final resolvedTextBody = replaceVariables(textToUse, variables);

      // Send email (currently using mailto, will be replaced with SendGrid)
      final success = await _sendEmailViaMailto(
        recipientEmail,
        resolvedSubject,
        resolvedHtmlBody,
        resolvedTextBody,
        pdfUrl,
      );

      if (success) {
        // Record email sent timestamp in invoice
        await _recordEmailSent(invoice.id);
        utils_logger.Logger.log(
            '📧 Invoice email sent to $recipientEmail for invoice ${invoice.invoiceNumber}');
      }

      return success;
    } catch (e) {
      utils_logger.Logger.logError('Failed to send invoice email: $e', e);
      return false;
    }
  }

  // Simplified send method for quick sending
  Future<bool> sendInvoiceEmailQuickly({
    required InvoiceModel invoice,
    required String recipientEmail,
  }) async {
    try {
      // Get default invoice template
      final template = await getDefaultTemplate(EmailTemplateType.invoice);
      if (template == null) {
        utils_logger.Logger.log('❌ No email template available for invoices');
        return false;
      }

      // Generate PDF URL (assuming only relative URL is needed here)
      final pdfUrl =
          '/invoices/${invoice.id}/download.pdf'; // We'll handle this properly

      return await sendInvoiceEmail(
        template: template,
        invoice: invoice,
        recipientEmail: recipientEmail,
        pdfUrl: pdfUrl,
      );
    } catch (e) {
      utils_logger.Logger.logError(
          'Failed to send invoice email quickly: $e', e);
      return false;
    }
  }

  // Private Helper Methods

  EmailTemplate? _getBuiltInDefaultTemplate(EmailTemplateType type) {
    switch (type) {
      case EmailTemplateType.invoice:
        return EmailTemplate.invoiceTemplate;
      case EmailTemplateType.receipt:
        return _createReceiptTemplate();
      case EmailTemplateType.reminder:
        return _createReminderTemplate();
      case EmailTemplateType.overdue:
        return _createOverdueTemplate();
      default:
        return EmailTemplate.invoiceTemplate;
    }
  }

  // Create built-in templates for different types
  EmailTemplate _createReceiptTemplate() {
    return EmailTemplate(
      id: 'built-in-receipt',
      name: 'Payment Receipt',
      subjectTemplate: 'Payment Receipt for Invoice #{invoice_number}',
      htmlBodyTemplate: _receiptHtmlTemplate,
      textBodyTemplate: _receiptTextTemplate,
      description: 'Payment confirmation receipt template',
      variables: [
        'customer_name',
        'invoice_number',
        'invoice_total',
        'payment_date'
      ],
      type: EmailTemplateType.receipt,
    );
  }

  EmailTemplate _createReminderTemplate() {
    return EmailTemplate(
      id: 'built-in-reminder',
      name: 'Payment Reminder',
      subjectTemplate: 'Friendly Reminder: Payment Due Soon',
      htmlBodyTemplate: _reminderHtmlTemplate,
      textBodyTemplate: _reminderTextTemplate,
      description: 'Friendly payment reminder template',
      variables: [
        'customer_name',
        'invoice_number',
        'invoice_total',
        'due_date',
        'days_overdue'
      ],
      type: EmailTemplateType.reminder,
    );
  }

  EmailTemplate _createOverdueTemplate() {
    return EmailTemplate(
      id: 'built-in-overdue',
      name: 'Overdue Notice',
      subjectTemplate: 'OVERDUE: Action Required on Invoice #{invoice_number}',
      htmlBodyTemplate: _overdueHtmlTemplate,
      textBodyTemplate: _overdueTextTemplate,
      description: 'Overdue payment notice template',
      variables: [
        'customer_name',
        'invoice_number',
        'invoice_total',
        'days_overdue'
      ],
      type: EmailTemplateType.overdue,
    );
  }

  // Send email via mailto (temporary implementation)
  Future<bool> _sendEmailViaMailto(String email, String subject,
      String htmlBody, String textBody, String? pdfUrl) async {
    try {
      final subjectEncoded = Uri.encodeComponent(subject);
      final bodyEncoded =
          Uri.encodeComponent(textBody); // Use text body for mailto

      final mailtoUrl =
          'mailto:$email?subject=$subjectEncoded&body=$bodyEncoded';

      if (await canLaunchUrl(Uri.parse(mailtoUrl))) {
        final result = await launchUrl(
          Uri.parse(mailtoUrl),
          mode: LaunchMode.externalApplication,
        );
        return result;
      }

      return false;
    } catch (e) {
      utils_logger.Logger.logError('Failed to send email via mailto: $e', e);
      return false;
    }
  }

  // Record when an email was sent
  Future<void> _recordEmailSent(String invoiceId) async {
    try {
      await _firestore.collection('invoices').doc(invoiceId).update({
        'lastSentAt': FieldValue.serverTimestamp(),
        'status': 'sent',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      utils_logger.Logger.logError(
          'Failed to record email sent for invoice $invoiceId: $e', e);
      // Don't throw - email was sent successfully even if record failed
    }
  }

  // Utility methods
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _generatePaymentUrl(InvoiceModel invoice) {
    // Generate a payment URL that the payment service can handle
    // This would typically be a web URL to your payment processing page
    return 'https://jengamate.co.tz/invoices/pay/${invoice.id}';
  }

  // Template HTML content for different types
  static const String _receiptHtmlTemplate = '''
<!DOCTYPE html>
<html>
<head>
    <style>
        body { font-family: Arial, sans-serif; padding: 20px; }
        .header { background: #4CAF50; color: white; padding: 20px; text-align: center; }
        .content { padding: 30px; background: white; }
        .success { color: #4CAF50; font-size: 24px; font-weight: bold; }
    </style>
</head>
<body>
    <div class="header"><h1>Payment Receipt</h1></div>
    <div class="content">
        <p>Dear {customer_name},</p>
        <p class="success">✓ Payment Received Successfully!</p>
        <p>Thank you for your payment of <strong>{invoice_total}</strong> for Invoice #{invoice_number}.</p>
        <p>Payment received on: {payment_date}</p>
        <p>If you have any questions, please contact us.</p>
        <p>Best regards,<br>The JengaMate Team</p>
    </div>
</body>
</html>
''';

  static const String _receiptTextTemplate = '''
Payment Receipt

Dear {customer_name},

✓ Payment Received Successfully!

Thank you for your payment of {invoice_total} for Invoice #{invoice_number}.
Payment received on: {payment_date}

Best regards,
The JengaMate Team
''';

  static const String _reminderHtmlTemplate = '''
<!DOCTYPE html>
<html>
<head>
    <style>
        body { font-family: Arial, sans-serif; padding: 20px; }
        .header { background: #FFC107; color: black; padding: 20px; text-align: center; }
        .content { padding: 30px; background: white; }
        .warning { color: #FF6B35; font-weight: bold; }
    </style>
</head>
<body>
    <div class="header"><h1>Payment Reminder</h1></div>
    <div class="content">
        <p>Dear {customer_name},</p>
        <p>This is a friendly reminder that payment is due soon for Invoice #{invoice_number}.</p>
        <p>Amount Due: <strong>{invoice_total}</strong></p>
        <p>Due Date: {due_date}</p>
        <p class="warning">Please ensure payment is received by the due date to avoid any late fees.</p>
        <p>Best regards,<br>The JengaMate Team</p>
    </div>
</body>
</html>
''';

  static const String _reminderTextTemplate = '''
Payment Reminder

Dear {customer_name},

This is a friendly reminder that payment is due soon for Invoice #{invoice_number}.
Amount Due: {invoice_total}
Due Date: {due_date}

Please ensure payment is received by the due date to avoid any late fees.

Best regards,
The JengaMate Team
''';

  static const String _overdueHtmlTemplate = '''
<!DOCTYPE html>
<html>
<head>
    <style>
        body { font-family: Arial, sans-serif; padding: 20px; }
        .header { background: #F44336; color: white; padding: 20px; text-align: center; }
        .content { padding: 30px; background: white; }
        .urgent { color: #F44336; font-weight: bold; font-size: 18px; }
    </style>
</head>
<body>
    <div class="header"><h1>OVERDUE NOTICE</h1></div>
    <div class="content">
        <p>Dear {customer_name},</p>
        <p class="urgent">⚠️ Urgent: Payment Overdue</p>
        <p>Invoice #{invoice_number} is currently {days_overdue} days overdue.</p>
        <p>Outstanding Amount: <strong>{invoice_total}</strong></p>
        <p>Please settle this matter immediately to avoid further collection actions.</p>
        <p>Contact us at {company_phone} or {company_email} to discuss payment arrangements.</p>
        <p>Best regards,<br>The JengaMate Team</p>
    </div>
</body>
</html>
''';

  static const String _overdueTextTemplate = '''
OVERDUE NOTICE

Dear {customer_name},

⚠️ Urgent: Payment Overdue

Invoice #{invoice_number} is currently {days_overdue} days overdue.
Outstanding Amount: {invoice_total}

Please settle this matter immediately to avoid further collection actions.

Contact us at {company_phone} or {company_email} to discuss payment arrangements.

Best regards,
The JengaMate Team
''';
}

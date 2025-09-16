// import 'package:cloud_firestore/cloud_firestore.dart'; // Removed Firebase dependency
import 'package:jengamate/models/email_template_type.dart'; // Import the consolidated enum

class EmailTemplate {
  final String id;
  final String name;
  final String subject;
  final String subjectTemplate;
  final String htmlBodyTemplate;
  final String textBodyTemplate;
  final String description;
  final bool isActive;
  final List<String>
      variables; // Dynamic variables like customer_name, invoice_total
  final EmailTemplateType type; // invoice, receipt, reminder, overdue
  final DateTime createdAt;
  final DateTime updatedAt;

  EmailTemplate({
    required this.id,
    required this.name,
    required this.subject,
    required this.subjectTemplate,
    required this.htmlBodyTemplate,
    required this.textBodyTemplate,
    required this.description,
    this.isActive = true,
    required this.variables,
    required this.type,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now().toUtc(),
        updatedAt = updatedAt ?? DateTime.now().toUtc();

  // Convert to Firestore document
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'subjectTemplate': subjectTemplate,
      'htmlBodyTemplate': htmlBodyTemplate,
      'textBodyTemplate': textBodyTemplate,
      'description': description,
      'isActive': isActive,
      'variables': variables,
      'type': type.toString().split('.').last, // Store as string
      'createdAt': createdAt.toIso8601String(), // Convert DateTime to ISO 8601 string
      'updatedAt': updatedAt.toIso8601String(), // Convert DateTime to ISO 8601 string
    };
  }

  // Create from Firestore document
  factory EmailTemplate.fromFirestore(Map<String, dynamic> data, {required String docId}) {
    return EmailTemplate(
      id: docId,
      name: data['name'] ?? '',
      subject: data['subject'] ?? '',
      subjectTemplate: data['subjectTemplate'] ?? '',
      htmlBodyTemplate: data['htmlBodyTemplate'] ?? '',
      textBodyTemplate: data['textBodyTemplate'] ?? '',
      description: data['description'] ?? '',
      isActive: data['isActive'] ?? true,
      variables: List<String>.from(data['variables'] ?? []),
      type: _parseEmailTemplateType(data['type'] ?? 'invoice'),
      createdAt: (data['createdAt'] is String) ? DateTime.parse(data['createdAt']) : null,
      updatedAt: (data['updatedAt'] is String) ? DateTime.parse(data['updatedAt']) : null,
    );
  }

  // Create a copy with some fields updated
  EmailTemplate copyWith({
    String? id,
    String? name,
    String? subject,
    String? subjectTemplate,
    String? htmlBodyTemplate,
    String? textBodyTemplate,
    String? description,
    bool? isActive,
    List<String>? variables,
    EmailTemplateType? type,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EmailTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      subject: subject ?? this.subject,
      subjectTemplate: subjectTemplate ?? this.subjectTemplate,
      htmlBodyTemplate: htmlBodyTemplate ?? this.htmlBodyTemplate,
      textBodyTemplate: textBodyTemplate ?? this.textBodyTemplate,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      variables: variables ?? this.variables,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static EmailTemplateType _parseEmailTemplateType(String type) {
    switch (type.toLowerCase()) {
      case 'invoice':
        return EmailTemplateType.invoice;
      case 'receipt':
        return EmailTemplateType.receipt;
      case 'reminder':
        return EmailTemplateType.reminder;
      case 'overdue':
        return EmailTemplateType.overdue;
      default:
        return EmailTemplateType.invoice;
    }
  }

  // Predefined templates
  static EmailTemplate get invoiceTemplate => EmailTemplate(
        id: 'default-invoice',
        name: 'Invoice Email',
        subject: 'Invoice #{invoice_number} from JengaMate Ltd', // Add subject
        subjectTemplate: 'Invoice #{invoice_number} from JengaMate Ltd',
        htmlBodyTemplate: _defaultInvoiceHtmlTemplate,
        textBodyTemplate: _defaultInvoiceTextTemplate,
        description:
            'Professional invoice email template with company branding',
        variables: [
          'customer_name',
          'invoice_number',
          'invoice_total',
          'due_date',
          'payment_url',
          'pdf_url',
          'company_name',
          'company_email',
          'company_phone'
        ],
        type: EmailTemplateType.invoice,
      );

  static const String _defaultInvoiceHtmlTemplate = '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Invoice from JengaMate Ltd</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 0; padding: 20px; background-color: #f5f5f5; }
        .container { max-width: 600px; margin: 0 auto; background-color: white; border-radius: 10px; overflow: hidden; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        .header { background: linear-gradient(135deg, #1a237e 0%, #3949ab 100%); color: white; padding: 30px; text-align: center; }
        .content { padding: 30px; }
        .invoice-details { background: #f8f9fa; padding: 20px; border-radius: 8px; margin: 20px 0; border-left: 4px solid #3949ab; }
        .cta-button { display: inline-block; background: #3949ab; color: white; padding: 12px 30px; text-decoration: none; border-radius: 25px; font-weight: bold; margin: 10px; }
        .invoice-total { font-size: 24px; color: #3949ab; font-weight: bold; }
        .footer { background: #212121; color: #9e9e9e; padding: 20px; text-align: center; font-size: 12px; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>Invoice #{invoice_number}</h1>
            <p>Professional Construction & Building Materials</p>
        </div>

        <div class="content">
            <p>Dear {customer_name},</p>

            <p>We hope this email finds you well. Please find attached Invoice #{invoice_number} for your recent order with JengaMate Ltd.</p>

            <div class="invoice-details">
                <h3>Invoice Summary</h3>
                <p><strong>Invoice Number:</strong> #{invoice_number}</p>
                <p><strong>Due Date:</strong> {due_date}</p>
                <p><strong>Total Amount:</strong> <span class="invoice-total">{invoice_total}</span></p>
            </div>

            <p>Please review the attached invoice and make payment before the due date to avoid any late fees.</p>

            <div style="text-align: center; margin: 30px 0;">
                <a href="{payment_url}" class="cta-button">Pay Invoice Now</a>
                <a href="{pdf_url}" class="cta-button">Download PDF</a>
            </div>

            <p>If you have any questions about this invoice or need assistance with your order, please don't hesitate to contact our team.</p>

            <p>Thank you for choosing JengaMate Ltd for your construction material needs. We look forward to serving you again.</p>

            <p>Best regards,<br/>
            <strong>The JengaMate Team</strong></p>
        </div>

        <div class="footer">
            <p>JengaMate Ltd | Construction & Building Materials<br/>
            Dar es Salaam, Tanzania | {company_email} | {company_phone}</p>
            <p>This is an automated invoice notification. Please do not reply to this email.</p>
        </div>
    </div>
</body>
</html>
''';

  static const String _defaultInvoiceTextTemplate = '''
Hello {customer_name},

Please find attached Invoice #{invoice_number} for your recent order with JengaMate Ltd.

INVOICE SUMMARY:
Invoice Number: #{invoice_number}
Due Date: {due_date}
Total Amount: {invoice_total}

Please review the attached invoice and make payment before the due date to avoid any late fees.

To pay this invoice: {payment_url}
To download PDF: {pdf_url}

If you have any questions about this invoice or need assistance with your order, please don't hesitate to contact our team.

Thank you for choosing JengaMate Ltd for your construction material needs.

Best regards,
The JengaMate Team

JengaMate Ltd | Construction & Building Materials
Dar es Salaam, Tanzania | {company_email} | {company_phone}
This is an automated invoice notification. Please do not reply to this email.
''';
}

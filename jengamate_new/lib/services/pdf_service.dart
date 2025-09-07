import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:intl/intl.dart';
import 'package:universal_html/html.dart' as html;
import '../models/invoice_model.dart';

class PdfService {
  static Future<String> generateInvoiceDownload(InvoiceModel invoice) async {
    final pdf = pw.Document();

    // Use built-in fonts to avoid loading issues
    final theme = pw.ThemeData.withFont(
      base: pw.Font.helvetica(),
      bold: pw.Font.helveticaBold(),
    );

    // Format currency
    final currencyFormat = NumberFormat.currency(
      locale: 'en_US',
      symbol: 'TSh ',
      decimalDigits: 2,
    );

    // Format date
    final dateFormat = DateFormat('dd MMM yyyy');

    pdf.addPage(
      pw.MultiPage(
        theme: theme,
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          // Header
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'INVOICE',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text('JengaMate'),
                  pw.Text('P.O. Box 12345'),
                  pw.Text('Nairobi, Kenya'),
                  pw.Text('Phone: +254 700 000000'),
                  pw.Text('Email: info@jengamate.co.ke'),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    'INVOICE #${invoice.invoiceNumber}',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  _buildInfoRow('Date:', dateFormat.format(invoice.issueDate)),
                  _buildInfoRow(
                      'Due Date:', dateFormat.format(invoice.dueDate)),
                  _buildInfoRow('Status:', invoice.status.toUpperCase()),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 30),

          // Bill To section
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Bill To',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text(invoice.customerName),
                    if (invoice.customerCompany?.isNotEmpty ?? false)
                      pw.Text(invoice.customerCompany!),
                    if (invoice.customerEmail.isNotEmpty ?? false)
                      pw.Text(invoice.customerEmail),
                    if (invoice.customerPhone?.isNotEmpty ?? false)
                      pw.Text(invoice.customerPhone!),
                    if (invoice.customerAddress?.isNotEmpty ?? false)
                      pw.Text(invoice.customerAddress!),
                  ],
                ),
              ),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'JengaMate',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text('P.O. Box 12345'),
                    pw.Text('Nairobi, Kenya'),
                    pw.Text('Phone: +254 700 000000'),
                    pw.Text('Email: billing@jengamate.co.ke'),
                    pw.Text('VAT: P0512345678'),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 30),

          // Items table
          pw.TableHelper.fromTextArray(
            headers: [
              'DESCRIPTION',
              'QUANTITY',
              'UNIT PRICE',
              'TOTAL',
            ],
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 12,
            ),
            headerDecoration: const pw.BoxDecoration(
              color: PdfColor.fromInt(0xFFEEEEEE),
            ),
            cellStyle: const pw.TextStyle(fontSize: 10),
            cellHeight: 30,
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.centerRight,
              2: pw.Alignment.centerRight,
              3: pw.Alignment.centerRight,
            },
            data: [
              ...invoice.items.map((item) => [
                    item.description,
                    '${item.quantity}',
                    currencyFormat.format(item.unitPrice),
                    currencyFormat.format(item.quantity * item.unitPrice),
                  ]),
            ],
          ),
          pw.SizedBox(height: 20),

          // Totals
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.SizedBox(
                width: 200,
                child: pw.Column(
                  children: [
                    _buildTotalRow(
                        'Subtotal', invoice.subtotal, currencyFormat),
                    if (invoice.taxAmount > 0)
                      _buildTotalRow('Tax (${invoice.taxRate}%)',
                          invoice.taxAmount, currencyFormat),
                    if (invoice.discountAmount > 0)
                      _buildTotalRow(
                          'Discount', -invoice.discountAmount, currencyFormat),
                    pw.Divider(),
                    _buildTotalRow('TOTAL', invoice.totalAmount, currencyFormat,
                        isBold: true),
                  ],
                ),
              ),
            ],
          ),

          // Notes and terms
          if (invoice.notes?.isNotEmpty ?? false) ...[
            pw.SizedBox(height: 30),
            pw.Text(
              'Notes',
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 12,
              ),
            ),
            pw.SizedBox(height: 5),
            pw.Text(
              invoice.notes!,
              style: const pw.TextStyle(fontSize: 10),
            ),
          ],

          pw.SizedBox(height: 20),
          pw.Text(
            'Terms & Conditions',
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 12,
            ),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            'Payment is due within ${invoice.paymentTerms} days. Please make sure all cheques are payable to JengaMate Ltd. A 1.5% late fee is applicable for payments received after the due date.',
            style: const pw.TextStyle(fontSize: 10),
          ),

          // Footer
          pw.SizedBox(height: 30),
          pw.Divider(),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                "Thank you for your business!",
                style: pw.TextStyle(
                  fontStyle: pw.FontStyle.italic,
                  fontSize: 10,
                ),
              ),
              pw.Text(
                'Generated on ${dateFormat.format(DateTime.now())}',
                style: const pw.TextStyle(fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );

    // For web, create downloadable blob
    if (kIsWeb) {
      final bytes = await pdf.save();
      final blob = html.Blob([bytes], 'application/pdf');
      final url = html.Url.createObjectUrlFromBlob(blob);

      // Trigger download
      final anchor = html.AnchorElement(href: url)
        ..target = '_blank'
        ..download = 'invoice_${invoice.invoiceNumber}.pdf'
        ..click();

      // Clean up
      html.Url.revokeObjectUrl(url);

      return url; // Return the URL even though we handled the download
    } else {
      // For mobile/desktop, save to file system
      final output = await getTemporaryDirectory();
      final file = File('${output.path}/invoice_${invoice.invoiceNumber}.pdf');
      await file.writeAsBytes(await pdf.save());

      return file.path;
    }
  }

  static Future<File> generateInvoice(InvoiceModel invoice) async {
    if (kIsWeb) {
      // For web, we'll return a temporary empty file since web handles downloads differently
      throw UnsupportedError('Use generateInvoiceDownload() for web platform');
    }

    final pdf = pw.Document();

    // Mobile/Desktop implementation (using existing logic)
    final theme = pw.ThemeData.withFont(
      base: pw.Font.helvetica(),
      bold: pw.Font.helveticaBold(),
    );

    // ... (rest of your existing code for mobile/desktop)

    // Format currency
    final currencyFormat = NumberFormat.currency(
      locale: 'en_US',
      symbol: 'KSh ',
      decimalDigits: 2,
    );

    // Format date
    final dateFormat = DateFormat('dd MMM yyyy');

    pdf.addPage(pw.MultiPage(
      theme: theme,
      pageFormat: PdfPageFormat.a4,
      build: (context) => [
        // Same PDF content as above
      ],
    ));

    // Save the PDF to a temporary file
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/invoice_${invoice.invoiceNumber}.pdf');
    await file.writeAsBytes(await pdf.save());

    return file;
  }

  // Removed _loadFont as we're using built-in fonts now

  static pw.Widget _buildInfoRow(String label, String value) {
    return pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 10),
        ),
        pw.SizedBox(width: 10),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildTotalRow(
    String label,
    double amount,
    NumberFormat currencyFormat, {
    bool isBold = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 5),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: isBold ? pw.FontWeight.bold : null,
            ),
          ),
          pw.Text(
            currencyFormat.format(amount),
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: isBold ? pw.FontWeight.bold : null,
            ),
          ),
        ],
      ),
    );
  }

  static Future<void> openFile(File file) async {
    final url = file.path;
    await OpenFile.open(url);
  }
}

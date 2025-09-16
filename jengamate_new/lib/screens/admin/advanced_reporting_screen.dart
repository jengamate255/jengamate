import 'package:flutter/material.dart';
import 'package:jengamate/services/reporting_service.dart';
import 'package:intl/intl.dart';
import 'package:csv/csv.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:universal_html/html.dart' as html;
import 'package:jengamate/utils/logger.dart';

class AdvancedReportingScreen extends StatefulWidget {
  const AdvancedReportingScreen({super.key});

  @override
  State<AdvancedReportingScreen> createState() =>
      _AdvancedReportingScreenState();
}

class _AdvancedReportingScreenState extends State<AdvancedReportingScreen> {
  final _reportingService = ReportingService();
  DateTime? _startDate;
  DateTime? _endDate;
  List<Map<String, dynamic>> _reportData = [];

  void _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 800;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Advanced Reporting'),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: _selectDateRange,
          ),
        ],
      ),
      body: Center(
        child: Container(
          constraints: BoxConstraints(
            maxWidth: isDesktop ? 800 : double.infinity,
          ),
          child: ListView(
            padding: EdgeInsets.all(isDesktop ? 24.0 : 16.0),
            children: [
              Card(
                elevation: isDesktop ? 4 : 2,
                child: Padding(
                  padding: EdgeInsets.all(isDesktop ? 24.0 : 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Report Configuration',
                        style: TextStyle(
                          fontSize: isDesktop ? 24 : 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Date Range: ${_startDate != null ? DateFormat.yMd().format(_startDate!) : 'N/A'} - ${_endDate != null ? DateFormat.yMd().format(_endDate!) : 'N/A'}',
                        style: TextStyle(
                          fontSize: isDesktop ? 16 : 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final crossAxisCount = isDesktop ? 2 : 1;
                          final childAspectRatio = isDesktop ? 3.0 : 4.0;
                          
                          return GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: crossAxisCount,
                            childAspectRatio: childAspectRatio,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            children: [
                              _buildReportButton(
                                'User Report',
                                Icons.people,
                                Colors.blue,
                                () => _generateReport('User Report'),
                                isDesktop,
                              ),
                              _buildReportButton(
                                'Order Report',
                                Icons.shopping_cart,
                                Colors.green,
                                () => _generateReport('Order Report'),
                                isDesktop,
                              ),
                              _buildReportButton(
                                'Financial Report',
                                Icons.attach_money,
                                Colors.orange,
                                () => _generateReport('Financial Report'),
                                isDesktop,
                              ),
                              _buildReportButton(
                                'RFQ Report',
                                Icons.request_quote,
                                Colors.purple,
                                () => _generateReport('RFQ Report'),
                                isDesktop,
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReportButton(
    String title,
    IconData icon,
    Color color,
    VoidCallback onPressed,
    bool isDesktop,
  ) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withValues(alpha: 0.1),
        foregroundColor: color,
        padding: EdgeInsets.all(isDesktop ? 24.0 : 16.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      onPressed: onPressed,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: isDesktop ? 48 : 32),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: isDesktop ? 16 : 14,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _generateReport(String reportType) async {
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a date range first'),
        ),
      );
      return;
    }
    
    setState(() {
      _reportData = []; // Clear previous data
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Generating $reportType...'),
      ),
    );

    try {
      List<Map<String, dynamic>> fetchedData = [];
      switch (reportType) {
        case 'User Report':
          fetchedData = await _reportingService.generateUserReport(
            _startDate!,
            _endDate!,
          );
          break;
        case 'Order Report':
          fetchedData = await _reportingService.generateOrderReport(
            _startDate!,
            _endDate!,
          );
          break;
        case 'Financial Report':
          fetchedData = await _reportingService.generateFinancialReport(
            _startDate!,
            _endDate!,
          );
          break;
        case 'RFQ Report':
          fetchedData = await _reportingService.generateRFQReport(
            _startDate!,
            _endDate!,
          );
          break;
      }

      setState(() {
        _reportData = fetchedData;
      });

      _exportReportToCsv(reportType, fetchedData);

    } catch (e) {
      Logger.logError('Error generating report', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating report: $e')),
        );
      }
    }
  }

  Future<void> _exportReportToCsv(String reportType, List<Map<String, dynamic>> data) async {
    if (data.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No data to export.')),
        );
      }
      return;
    }

    try {
      List<List<dynamic>> rows = [];
      List<dynamic> headers = [];

      switch (reportType) {
        case 'User Report':
          headers = ['UID', 'Name', 'Email', 'Phone Number', 'Role', 'Company', 'Created At'];
          for (var item in data) {
            rows.add_parseOptionalDateTime([
              item['uid'] ?? '',
              item['name'] ?? '',
              item['email'] ?? '',
              item['phoneNumber'] ?? '',
              item['role'] ?? '',
              item['company'] ?? '',
              (item['createdAt'])?.toIso8601String() ?? '',
            ]);
          }
          break;
        case 'Order Report':
          headers = ['Order ID', 'Customer Name', 'Total Amount', 'Status', 'Created At'];
          for (var item in data) {
            rows.add([
              item['id'] ?? '',
              item['customerName'] ?? '',
              item['totalAmount']?.toStringAsFixed(2) ?? '',
              item['status'] ?? '',
              _parseOptionalDateTime(item['createdAt'])?.toIso8601String() ?? '',
            ]);
          }
          break;
        case 'Financial Report':
          headers = ['Transaction ID', 'Type', 'Amount', 'Date'];
          for (var item in data) {
            rows.add([
              item['id'] ?? '',
              item['type'] ?? '',
              item['amount']?.toStringAsFixed(2) ?? '',
              _parseOptionalDateTime(item['date'])?.toIso8601String() ?? '',
            ]);
          }
          break;
        case 'RFQ Report':
          headers = ['RFQ ID', 'Product Name', 'Quantity', 'Status', 'Created At'];
          for (var item in data) {
            rows.add([
              item['id'] ?? '',
              item['productName'] ?? '',
              item['quantity']?.toString() ?? '',
              item['status'] ?? '',
              _parseOptionalDateTime(item['createdAt'])?.toIso8601String() ?? '',
            ]);
          }
          break;
      }

      rows.insert(0, headers);

      String csv = const ListToCsvConverter().convert(rows);

      final directory = await getTemporaryDirectory();
      final fileName = '${reportType.replaceAll(' ', '_').toLowerCase()}_report_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv';
      final path = '${directory.path}/$fileName';
      final file = File(path);
      await file.writeAsString(csv);

      // For web compatibility, create a download link
      if (html.document != null) {
        final bytes = await file.readAsBytes();
        final blob = html.Blob([bytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..target = '_blank'
          ..download = fileName;
        anchor.click();
        html.Url.revokeObjectUrl(url);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Report exported to $path')),
        );
      }
    } catch (e) {
      Logger.logError('Error exporting report to CSV', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error exporting report: $e')),
        );
      }
    }
  }
}
import 'package:flutter/material.dart';
import 'package:jengamate/services/reporting_service.dart';
import 'package:intl/intl.dart';

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

  void _generateReport(String reportType) {
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a date range first'),
        ),
      );
      return;
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Generating $reportType...'),
      ),
    );
    
    // TODO: Implement actual report generation
  }
}
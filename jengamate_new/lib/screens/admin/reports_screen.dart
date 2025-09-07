import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({Key? key}) : super(key: key);

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  String _selectedReportType = 'sales';
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  bool _isLoading = false;
  List<Map<String, dynamic>> _reportData = [];
  double _totalAmount = 0.0;

  Future<void> _generateReport() async {
    setState(() {
      _isLoading = true;
      _reportData = [];
      _totalAmount = 0.0;
    });

    try {
      Query query;
      
      switch (_selectedReportType) {
        case 'sales':
          query = _firestore
              .collection('orders')
              .where('createdAt', isGreaterThanOrEqualTo: _startDate)
              .where('createdAt', isLessThanOrEqualTo: _endDate);
          break;
        case 'users':
          query = _firestore
              .collection('users')
              .where('createdAt', isGreaterThanOrEqualTo: _startDate)
              .where('createdAt', isLessThanOrEqualTo: _endDate);
          break;
        case 'withdrawals':
          query = _firestore
              .collection('withdrawals')
              .where('createdAt', isGreaterThanOrEqualTo: _startDate)
              .where('createdAt', isLessThanOrEqualTo: _endDate);
          break;
        case 'commissions':
          query = _firestore
              .collection('commissions')
              .where('createdAt', isGreaterThanOrEqualTo: _startDate)
              .where('createdAt', isLessThanOrEqualTo: _endDate);
          break;
        default:
          query = _firestore.collection('orders');
      }

      final snapshot = await query.get();
      final data = snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
      
      setState(() {
        _reportData = data;
        _calculateTotal();
        _isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating report: ${e.toString()}')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _calculateTotal() {
    double total = 0.0;
    
    for (var item in _reportData) {
      switch (_selectedReportType) {
        case 'sales':
          total += (item['totalAmount'] ?? 0.0).toDouble();
          break;
        case 'withdrawals':
          total += (item['amount'] ?? 0.0).toDouble();
          break;
        case 'commissions':
          total += (item['amount'] ?? 0.0).toDouble();
          break;
      }
    }
    
    setState(() {
      _totalAmount = total;
    });
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );
    
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  Widget _buildReportTable() {
    if (_reportData.isEmpty) {
      return const Center(
        child: Text('No data available for the selected period'),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: _getColumns(),
        rows: _getRows(),
      ),
    );
  }

  List<DataColumn> _getColumns() {
    switch (_selectedReportType) {
      case 'sales':
        return const [
          DataColumn(label: Text('Order ID')),
          DataColumn(label: Text('Customer')),
          DataColumn(label: Text('Amount')),
          DataColumn(label: Text('Status')),
          DataColumn(label: Text('Date')),
        ];
      case 'users':
        return const [
          DataColumn(label: Text('User ID')),
          DataColumn(label: Text('Name')),
          DataColumn(label: Text('Email')),
          DataColumn(label: Text('Role')),
          DataColumn(label: Text('Date')),
        ];
      case 'withdrawals':
        return const [
          DataColumn(label: Text('Withdrawal ID')),
          DataColumn(label: Text('User')),
          DataColumn(label: Text('Amount')),
          DataColumn(label: Text('Status')),
          DataColumn(label: Text('Date')),
        ];
      case 'commissions':
        return const [
          DataColumn(label: Text('Commission ID')),
          DataColumn(label: Text('User')),
          DataColumn(label: Text('Amount')),
          DataColumn(label: Text('Type')),
          DataColumn(label: Text('Date')),
        ];
      default:
        return const [DataColumn(label: Text('Data'))];
    }
  }

  List<DataRow> _getRows() {
    return _reportData.map((item) {
      switch (_selectedReportType) {
        case 'sales':
          return DataRow(cells: [
            DataCell(Text(item['id'] ?? 'N/A')),
            DataCell(Text(item['customerName'] ?? 'N/A')),
            DataCell(Text('KES ${item['totalAmount']?.toStringAsFixed(2) ?? '0.00'}')),
            DataCell(Text(item['status'] ?? 'N/A')),
            DataCell(Text(DateFormat('MMM dd, yyyy').format(item['createdAt'].toDate()))),
          ]);
        case 'users':
          return DataRow(cells: [
            DataCell(Text(item['uid'] ?? 'N/A')),
            DataCell(Text(item['name'] ?? 'N/A')),
            DataCell(Text(item['email'] ?? 'N/A')),
            DataCell(Text(item['role'] ?? 'user')),
            DataCell(Text(DateFormat('MMM dd, yyyy').format(item['createdAt'].toDate()))),
          ]);
        case 'withdrawals':
          return DataRow(cells: [
            DataCell(Text(item['id'] ?? 'N/A')),
            DataCell(Text(item['userName'] ?? 'N/A')),
            DataCell(Text('KES ${item['amount']?.toStringAsFixed(2) ?? '0.00'}')),
            DataCell(Text(item['status'] ?? 'N/A')),
            DataCell(Text(DateFormat('MMM dd, yyyy').format(item['createdAt'].toDate()))),
          ]);
        case 'commissions':
          return DataRow(cells: [
            DataCell(Text(item['id'] ?? 'N/A')),
            DataCell(Text(item['userName'] ?? 'N/A')),
            DataCell(Text('KES ${item['amount']?.toStringAsFixed(2) ?? '0.00'}')),
            DataCell(Text(item['type'] ?? 'N/A')),
            DataCell(Text(DateFormat('MMM dd, yyyy').format(item['createdAt'].toDate()))),
          ]);
        default:
          return const DataRow(cells: [DataCell(Text('N/A'))]);
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedReportType,
                    decoration: const InputDecoration(
                      labelText: 'Report Type',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'sales', child: Text('Sales Report')),
                      DropdownMenuItem(value: 'users', child: Text('Users Report')),
                      DropdownMenuItem(value: 'withdrawals', child: Text('Withdrawals Report')),
                      DropdownMenuItem(value: 'commissions', child: Text('Commissions Report')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedReportType = value!;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _selectDateRange,
                  child: Text(
                    '${DateFormat('MMM dd').format(_startDate)} - ${DateFormat('MMM dd').format(_endDate)}',
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _isLoading ? null : _generateReport,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Generate'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (_reportData.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total: KES ${_totalAmount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          // TODO: Implement export functionality
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Export functionality coming soon')),
                          );
                        },
                        icon: const Icon(Icons.download),
                        label: const Text('Export'),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 20),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildReportTable(),
            ),
          ],
        ),
      ),
    );
  }
}
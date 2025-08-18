import 'package:flutter/material.dart';
import 'package:jengamate/models/rfq_model.dart';
import 'package:jengamate/services/database_service.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:jengamate/config/app_routes.dart';

class RfqManagementDashboard extends StatefulWidget {
  const RfqManagementDashboard({super.key});

  @override
  State<RfqManagementDashboard> createState() => _RfqManagementDashboardState();
}

class _RfqManagementDashboardState extends State<RfqManagementDashboard> {
  final _dbService = DatabaseService();

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 800;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('RFQ Management Dashboard'),
      ),
      body: StreamBuilder<List<RFQModel>>(
        stream: _dbService.streamAllRFQs(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final rfqs = snapshot.data ?? [];
          if (rfqs.isEmpty) {
            return const Center(child: Text('No RFQs found.'));
          }
          
          return LayoutBuilder(
            builder: (context, constraints) {
              if (isWideScreen) {
                // Desktop/Tablet layout - DataTable
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: constraints.maxWidth),
                    child: DataTable(
                      columnSpacing: 24,
                      columns: const [
                        DataColumn(label: Text('Title')),
                        DataColumn(label: Text('User ID')),
                        DataColumn(label: Text('Created At')),
                        DataColumn(label: Text('Status')),
                        DataColumn(label: Text('Actions')),
                      ],
                      rows: rfqs.map((rfq) => DataRow(
                        cells: [
                          DataCell(Text(rfq.productName)),
                          DataCell(Text(rfq.userId)),
                          DataCell(Text(DateFormat.yMd().add_jm().format(rfq.createdAt))),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getStatusColor(rfq.status).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                rfq.status,
                                style: TextStyle(
                                  color: _getStatusColor(rfq.status),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          DataCell(
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.visibility),
                                  onPressed: () => _viewRfqDetails(rfq),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () => _editRfqStatus(rfq),
                                ),
                              ],
                            ),
                          ),
                        ],
                      )).toList(),
                    ),
                  ),
                );
              } else {
                // Mobile layout - ListView
                return ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: rfqs.length,
                  itemBuilder: (context, index) {
                    final rfq = rfqs[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4.0),
                      child: ListTile(
                        title: Text(
                          rfq.productName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('User: ${rfq.userId}'),
                            Text(DateFormat.yMd().add_jm().format(rfq.createdAt)),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: _getStatusColor(rfq.status).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                rfq.status,
                                style: TextStyle(
                                  color: _getStatusColor(rfq.status),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        trailing: PopupMenuButton(
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'view',
                              child: Text('View Details'),
                            ),
                            const PopupMenuItem(
                              value: 'edit',
                              child: Text('Edit Status'),
                            ),
                          ],
                          onSelected: (value) {
                            if (value == 'view') {
                              _viewRfqDetails(rfq);
                            } else if (value == 'edit') {
                              _editRfqStatus(rfq);
                            }
                          },
                        ),
                      ),
                    );
                  },
                );
              }
            },
          );
        },
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'processing':
        return Colors.blue;
      case 'completed':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  void _viewRfqDetails(RFQModel rfq) {
    final path = AppRouteBuilders.rfqDetailsPath(rfq.id);
    context.go(path);
  }

  void _editRfqStatus(RFQModel rfq) {
    final statuses = ['Pending', 'Approved', 'Rejected', 'Processing', 'Completed'];
    String selected = rfq.status;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Status - ${rfq.productName}'),
          content: DropdownButtonFormField<String>(
            value: selected,
            decoration: const InputDecoration(
              labelText: 'Status',
              border: OutlineInputBorder(),
            ),
            items: statuses
                .map((s) => DropdownMenuItem<String>(value: s, child: Text(s)))
                .toList(),
            onChanged: (val) {
              if (val != null) selected = val;
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await _dbService.updateRFQStatus(rfq.id, selected);
                  if (context.mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Status updated to "$selected"')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to update status: $e')),
                    );
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}
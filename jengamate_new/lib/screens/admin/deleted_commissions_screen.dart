import 'package:flutter/material.dart';
import 'package:jengamate/models/commission_model.dart';
import 'package:jengamate/models/user_model.dart';
import 'package:jengamate/services/database_service.dart';
import 'package:intl/intl.dart';

class DeletedCommissionsScreen extends StatefulWidget {
  const DeletedCommissionsScreen({super.key});

  @override
  State<DeletedCommissionsScreen> createState() => _DeletedCommissionsScreenState();
}

class _DeletedCommissionsScreenState extends State<DeletedCommissionsScreen> {
  final DatabaseService _databaseService = DatabaseService();

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 800;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Deleted Commissions'),
      ),
      body: StreamBuilder<List<CommissionModel>>(
        stream: _databaseService.streamTrashedCommissions(), // Stream for deleted commissions
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final commissions = snapshot.data!;

          if (commissions.isEmpty) {
            return const Center(child: Text('No deleted commissions found.'));
          }

          if (isDesktop) {
            return _buildDesktopTable(commissions);
          } else {
            return _buildMobileList(commissions);
          }
        },
      ),
    );
  }

  Widget _buildDesktopTable(List<CommissionModel> commissions) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('ID')),
          DataColumn(label: Text('Engineer')),
          DataColumn(label: Text('Amount')),
          DataColumn(label: Text('Type')),
          DataColumn(label: Text('Deleted At')),
          DataColumn(label: Text('Actions')),
        ],
        rows: commissions.map((commission) {
          return DataRow(
            cells: [
              DataCell(Text(commission.id.substring(0, 6))), // Shorten ID for display
              DataCell(FutureBuilder<UserModel?>(
                future: _databaseService.getUser(commission.userId),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Text('Loading...');
                  return Text(snapshot.data!.displayName);
                },
              )),
              DataCell(Text('TSh ${NumberFormat('#,##0').format(commission.total)}')),
              DataCell(Text(commission.status)), // Assuming status can represent type
              DataCell(Text(DateFormat('MMM dd, yyyy').format(commission.updatedAt))), // Assuming updatedAt is when it was "trashed"
              DataCell(
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.restore),
                      onPressed: () async {
                        await _databaseService.restoreCommission(commission.id);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Commission ${commission.id} restored')),
                          );
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_forever),
                      onPressed: () {
                        // TODO: Implement permanent delete functionality
                        _showDeleteConfirmationDialog(context, commission.id);
                      },
                    ),
                  ],
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMobileList(List<CommissionModel> commissions) {
    return ListView.builder(
      itemCount: commissions.length,
      itemBuilder: (context, index) {
        final commission = commissions[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            title: FutureBuilder<UserModel?>(
              future: _databaseService.getUser(commission.userId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Text('Loading user...');
                return Text('Engineer: ${snapshot.data!.displayName}');
              },
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Amount: TSh ${NumberFormat('#,##0').format(commission.total)}'),
                Text('Type: ${commission.status}'),
                Text('Deleted At: ${DateFormat('MMM dd, yyyy').format(commission.updatedAt)}'),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.restore),
                  onPressed: () async {
                    await _databaseService.restoreCommission(commission.id);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Commission ${commission.id} restored')),
                      );
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete_forever),
                  onPressed: () {
                    // TODO: Implement permanent delete functionality
                    _showDeleteConfirmationDialog(context, commission.id);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context, String commissionId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Permanent Deletion'),
          content: const Text('Are you sure you want to permanently delete this commission? This action cannot be undone.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  await _databaseService.deleteCommissionPermanently(commissionId);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Commission permanently deleted')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error deleting commission: $e')),
                    );
                  }
                }
              },
              child: const Text('Delete Permanently'),
            ),
          ],
        );
      },
    );
  }
}
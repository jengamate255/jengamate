import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jengamate/models/withdrawal_model.dart';
import 'package:jengamate/models/user_model.dart';
import 'package:jengamate/services/database_service.dart';
import 'package:intl/intl.dart';

class WithdrawalManagementScreen extends StatefulWidget {
  const WithdrawalManagementScreen({super.key});

  @override
  State<WithdrawalManagementScreen> createState() => _WithdrawalManagementScreenState();
}

class _WithdrawalManagementScreenState extends State<WithdrawalManagementScreen> {
  final DatabaseService _databaseService = DatabaseService();
  String _selectedStatus = 'All';
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _updateWithdrawalStatus(String withdrawalId, String newStatus) async {
    try {
      await _databaseService.updateWithdrawalStatus(withdrawalId, newStatus);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Withdrawal status updated to $newStatus')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating status: $e')),
      );
    }
  }

  Future<void> _showWithdrawalDetails(WithdrawalModel withdrawal, UserModel user) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Withdrawal Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('User', user.displayName),
              _buildDetailRow('Email', user.email ?? 'N/A'),
              _buildDetailRow('Amount', 'TSh ${NumberFormat('#,##0').format(withdrawal.amount)}'),
              _buildDetailRow('Status', withdrawal.status),
              _buildDetailRow('Requested', DateFormat('MMM dd, yyyy HH:mm').format(withdrawal.createdAt.toDate())),
            ],
          ),
        ),
        actions: [
          if (withdrawal.status == 'Pending') ...[
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _updateWithdrawalStatus(withdrawal.id, 'Approved');
              },
              child: const Text('Approve'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _showRejectDialog(withdrawal.id);
              },
              child: const Text('Reject'),
            ),
          ],
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _showRejectDialog(String withdrawalId) async {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Withdrawal'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            labelText: 'Rejection reason (optional)',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await _databaseService.rejectWithdrawal(withdrawalId, reasonController.text);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Withdrawal rejected')),
              );
            },
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Stream<List<WithdrawalModel>> _getWithdrawalsStream() {
    Query query = FirebaseFirestore.instance.collection('withdrawals');
    
    if (_selectedStatus != 'All') {
      query = query.where('status', isEqualTo: _selectedStatus);
    }
    
    if (_isSearching && _searchController.text.isNotEmpty) {
      // We'll filter by user email/name after fetching
    }
    
    return query.snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => WithdrawalModel.fromFirestore(doc)).toList());
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 800;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Withdrawal Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Filter by Status'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: ['All', 'Pending', 'Approved', 'Rejected', 'Completed']
                        .map((status) => RadioListTile<String>(
                              title: Text(status),
                              value: status,
                              groupValue: _selectedStatus,
                              onChanged: (value) {
                                setState(() {
                                  _selectedStatus = value!;
                                });
                                Navigator.pop(context);
                              },
                            ))
                        .toList(),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search by user email or name',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _isSearching
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _isSearching = false;
                          });
                        },
                      )
                    : null,
                border: const OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _isSearching = value.isNotEmpty;
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<List<WithdrawalModel>>(
              stream: _getWithdrawalsStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final withdrawals = snapshot.data!;

                if (withdrawals.isEmpty) {
                  return const Center(child: Text('No withdrawals found'));
                }

                if (isDesktop) {
                  return _buildDesktopTable(withdrawals);
                } else {
                  return _buildMobileList(withdrawals);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopTable(List<WithdrawalModel> withdrawals) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('User')),
          DataColumn(label: Text('Amount')),
          DataColumn(label: Text('Status')),
          DataColumn(label: Text('Requested')),
          DataColumn(label: Text('Actions')),
        ],
        rows: withdrawals.map((withdrawal) {
          return DataRow(
            cells: [
              DataCell(
                FutureBuilder<UserModel?>(
                  future: _databaseService.getUser(withdrawal.userId),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const Text('Loading...');
                    return Text(snapshot.data!.displayName ?? 'Unknown');
                  },
                ),
              ),
              DataCell(
                Text('TSh ${NumberFormat('#,##0').format(withdrawal.amount)}'),
              ),
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(withdrawal.status).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    withdrawal.status,
                    style: TextStyle(
                      color: _getStatusColor(withdrawal.status),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              DataCell(
                Text(DateFormat('MMM dd, yyyy').format(withdrawal.createdAt.toDate())),
              ),
              DataCell(
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.visibility),
                      onPressed: () async {
                        final user = await _databaseService.getUser(withdrawal.userId);
                        if (user != null) {
                          _showWithdrawalDetails(withdrawal, user);
                        }
                      },
                    ),
                    if (withdrawal.status == 'Pending') ...[
                      IconButton(
                        icon: const Icon(Icons.check, color: Colors.green),
                        onPressed: () => _updateWithdrawalStatus(withdrawal.id, 'Approved'),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () => _showRejectDialog(withdrawal.id),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMobileList(List<WithdrawalModel> withdrawals) {
    return ListView.builder(
      itemCount: withdrawals.length,
      itemBuilder: (context, index) {
        final withdrawal = withdrawals[index];
        return FutureBuilder<UserModel?>(
          future: _databaseService.getUser(withdrawal.userId),
          builder: (context, userSnapshot) {
            if (!userSnapshot.hasData) {
              return const ListTile(
                title: Text('Loading user...'),
              );
            }

            final user = userSnapshot.data!;
            
            // Filter by search if needed
            if (_isSearching && _searchController.text.isNotEmpty) {
              final searchTerm = _searchController.text.toLowerCase();
              final userName = user.displayName.toLowerCase();
              final userEmail = user.email?.toLowerCase() ?? '';
              
              if (!userName.contains(searchTerm) && !userEmail.contains(searchTerm)) {
                return const SizedBox.shrink();
              }
            }

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: ListTile(
                title: Text(user.displayName),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('TSh ${NumberFormat('#,##0').format(withdrawal.amount)}'),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getStatusColor(withdrawal.status).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        withdrawal.status,
                        style: TextStyle(
                          color: _getStatusColor(withdrawal.status),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending':
        return Colors.orange;
      case 'Approved':
        return Colors.green;
      case 'Rejected':
        return Colors.red;
      case 'Completed':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}
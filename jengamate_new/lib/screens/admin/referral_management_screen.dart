import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jengamate/models/referral_model.dart';
import 'package:jengamate/models/user_model.dart';
import 'package:jengamate/services/database_service.dart';
import 'package:intl/intl.dart';

class ReferralManagementScreen extends StatefulWidget {
  const ReferralManagementScreen({super.key});

  @override
  State<ReferralManagementScreen> createState() => _ReferralManagementScreenState();
}

class _ReferralManagementScreenState extends State<ReferralManagementScreen> {
  final DatabaseService _databaseService = DatabaseService();
  String _selectedStatus = 'All';
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _isSearching = _searchController.text.isNotEmpty;
    });
  }

  Future<void> _showReferralDetails(ReferralModel referral, UserModel referrer, UserModel referredUser) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Referral Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Referrer', referrer.displayName),
              _buildDetailRow('Referred User', referredUser.displayName),
              _buildDetailRow('Bonus Amount', 'TSh ${NumberFormat('#,##0').format(referral.bonusAmount)}'),
              _buildDetailRow('Status', referral.status),
              _buildDetailRow('Created At', DateFormat('MMM dd, yyyy HH:mm').format(referral.createdAt)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
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
            width: 120,
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

  Stream<List<ReferralModel>> _getReferralsStream() {
    Query query = FirebaseFirestore.instance.collection('referrals');

    if (_selectedStatus != 'All') {
      query = query.where('status', isEqualTo: _selectedStatus);
    }

    return query.snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => ReferralModel.fromFirestore(doc)).toList());
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 800;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Referral Management'),
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
                    children: ['All', 'Pending', 'Completed', 'Cancelled']
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
                labelText: 'Search by referrer or referred user email/name',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _isSearching
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged();
                        },
                      )
                    : null,
                border: const OutlineInputBorder(),
              ),
              onChanged: (value) {
                _onSearchChanged();
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<List<ReferralModel>>(
              stream: _getReferralsStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final referrals = snapshot.data!;

                if (referrals.isEmpty) {
                  return const Center(child: Text('No referrals found'));
                }

                final filteredReferrals = referrals.where((referral) {
                  if (!_isSearching) return true;
                  final query = _searchController.text.toLowerCase();
                  return referral.referrerId.toLowerCase().contains(query) ||
                         referral.referredUserId.toLowerCase().contains(query); // Simplified search for now
                }).toList();

                if (filteredReferrals.isEmpty) {
                  return const Center(child: Text('No referrals match your search.'));
                }

                if (isDesktop) {
                  return _buildDesktopTable(filteredReferrals);
                } else {
                  return _buildMobileList(filteredReferrals);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopTable(List<ReferralModel> referrals) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Referrer')),
          DataColumn(label: Text('Referred User')),
          DataColumn(label: Text('Bonus Amount')),
          DataColumn(label: Text('Status')),
          DataColumn(label: Text('Created At')),
          DataColumn(label: Text('Actions')),
        ],
        rows: referrals.map((referral) {
          return DataRow(
            cells: [
              DataCell(FutureBuilder<UserModel?>(
                future: _databaseService.getUser(referral.referrerId),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Text('Loading...');
                  return Text(snapshot.data!.displayName);
                },
              )),
              DataCell(FutureBuilder<UserModel?>(
                future: _databaseService.getUser(referral.referredUserId),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Text('Loading...');
                  return Text(snapshot.data!.displayName);
                },
              )),
              DataCell(Text('TSh ${NumberFormat('#,##0').format(referral.bonusAmount)}')),
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(referral.status).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    referral.status,
                    style: TextStyle(
                      color: _getStatusColor(referral.status),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              DataCell(Text(DateFormat('MMM dd, yyyy').format(referral.createdAt))),
              DataCell(
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.visibility),
                      onPressed: () async {
                        final referrer = await _databaseService.getUser(referral.referrerId);
                        final referredUser = await _databaseService.getUser(referral.referredUserId);
                        if (referrer != null && referredUser != null) {
                          _showReferralDetails(referral, referrer, referredUser);
                        }
                      },
                    ),
                    // Add more actions like approve/reject if needed
                  ],
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMobileList(List<ReferralModel> referrals) {
    return ListView.builder(
      itemCount: referrals.length,
      itemBuilder: (context, index) {
        final referral = referrals[index];
        return FutureBuilder<List<UserModel?>>(
          future: Future.wait([
            _databaseService.getUser(referral.referrerId),
            _databaseService.getUser(referral.referredUserId),
          ]),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const ListTile(title: Text('Loading referral...'));
            }
            final users = snapshot.data!;
            final referrer = users[0];
            final referredUser = users[1];

            if (referrer == null || referredUser == null) {
              return const ListTile(title: Text('User data not found.'));
            }

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: ListTile(
                title: Text('Referrer: ${referrer.displayName}'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Referred: ${referredUser.displayName}'),
                    Text('Bonus: TSh ${NumberFormat('#,##0').format(referral.bonusAmount)}'),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getStatusColor(referral.status).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        referral.status,
                        style: TextStyle(
                          color: _getStatusColor(referral.status),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                trailing: Text(DateFormat('MMM dd').format(referral.createdAt)),
                onTap: () => _showReferralDetails(referral, referrer, referredUser),
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
      case 'Completed':
        return Colors.green;
      case 'Cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
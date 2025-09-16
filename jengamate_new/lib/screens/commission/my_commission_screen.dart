import 'package:flutter/material.dart';
import 'package:jengamate/models/commission_model.dart';
import 'package:jengamate/services/database_service.dart';
import 'package:provider/provider.dart';
import 'package:jengamate/services/user_state_provider.dart';
import 'package:jengamate/models/user_model.dart';
import 'package:intl/intl.dart';

class MyCommissionScreen extends StatelessWidget {
  const MyCommissionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userState = Provider.of<UserStateProvider>(context);
    final currentUser = userState.currentUser;
    final dbService = DatabaseService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Commission'),
      ),
      body: StreamBuilder<List<CommissionModel>>(
        stream: dbService.streamUserCommissions(currentUser?.uid ?? ''),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final commissions = snapshot.data ?? [];
          if (commissions.isEmpty) {
            return const Center(
                child: Text('You have not earned any commissions yet.'));
          }
          return ListView.builder(
            itemCount: commissions.length,
            itemBuilder: (context, index) {
              final commission = commissions[index];
              return Card(
                margin: const EdgeInsets.all(8.0),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Commission: ${NumberFormat.currency(symbol: 'TSh ').format(commission.total)}',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text('Direct Commission: ${NumberFormat.currency(symbol: 'TSh ').format(commission.direct)}'),
                      Text('Referral Commission: ${NumberFormat.currency(symbol: 'TSh ').format(commission.referral)}'),
                      Text('Active Commission: ${NumberFormat.currency(symbol: 'TSh ').format(commission.active)}'),
                      Text('Minimum Payout Threshold: ${NumberFormat.currency(symbol: 'TSh ').format(commission.minPayoutThreshold)}'),
                      const SizedBox(height: 8),
                      Text('Date: ${DateFormat.yMd().format(commission.updatedAt)}'),
                      Text('Status: ${commission.status}'),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
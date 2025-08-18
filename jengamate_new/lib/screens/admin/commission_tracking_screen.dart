import 'package:flutter/material.dart';
import 'package:jengamate/models/commission_model.dart';
import 'package:jengamate/services/database_service.dart';
import 'package:intl/intl.dart';

class CommissionTrackingScreen extends StatefulWidget {
  const CommissionTrackingScreen({super.key});

  @override
  State<CommissionTrackingScreen> createState() =>
      _CommissionTrackingScreenState();
}

class _CommissionTrackingScreenState extends State<CommissionTrackingScreen> {
  final _dbService = DatabaseService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Commission Tracking'),
      ),
      body: StreamBuilder<List<CommissionModel>>(
        stream: _dbService.getAllCommissions(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final commissions = snapshot.data ?? [];
          if (commissions.isEmpty) {
            return const Center(child: Text('No commissions found.'));
          }
          return ListView.builder(
            itemCount: commissions.length,
            itemBuilder: (context, index) {
              final commission = commissions[index];
              return Card(
                margin: const EdgeInsets.all(8.0),
                child: ListTile(
                  title: Text('User: ${commission.userId}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Total: ${NumberFormat.currency(symbol: 'TSh ').format(commission.total)}'),
                      Text('Direct: ${NumberFormat.currency(symbol: 'TSh ').format(commission.direct)}'),
                      Text('Referral: ${NumberFormat.currency(symbol: 'TSh ').format(commission.referral)}'),
                      Text('Active: ${NumberFormat.currency(symbol: 'TSh ').format(commission.active)}'),
                      Text('Min Payout: ${NumberFormat.currency(symbol: 'TSh ').format(commission.minPayoutThreshold)}'),
                    ],
                  ),
                  trailing: Text(
                      DateFormat.yMd().add_jm().format(commission.updatedAt)),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
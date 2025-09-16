import 'package:flutter/material.dart';
import 'package:jengamate/models/commission_model.dart';
import 'package:jengamate/services/database_service.dart';
import 'package:provider/provider.dart';
import 'package:jengamate/services/user_state_provider.dart';

import '../../models/user_model.dart';
import 'package:jengamate/models/enums/user_role.dart';

class CommissionScreen extends StatelessWidget {
  const CommissionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userState = Provider.of<UserStateProvider>(context);
    final currentUser = userState.currentUser;
    final dbService = DatabaseService();

    if (currentUser == null ||
        (currentUser.role != UserRole.admin &&
            currentUser.role != UserRole.supplier)) {
      return const Scaffold(
        body: Center(
          child: Text('You do not have permission to view this page.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Commission'),
      ),
      body: StreamBuilder<List<CommissionModel>>(
        stream: currentUser != null ? dbService.streamUserCommissions(currentUser.uid) : Stream.empty(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData ||
              snapshot.data == null ||
              snapshot.data!.isEmpty) {
            return const Center(child: Text('No commission data found.'));
          }

          final commission = snapshot.data!.first;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCommissionCard('Total Commission', commission.total),
                _buildCommissionCard('Direct Commission', commission.direct),
                _buildCommissionCard(
                    'Referral Commission', commission.referral),
                _buildCommissionCard('Active Commission', commission.active),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCommissionCard(String title, double amount) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontSize: 16)),
            Text('KES ${amount.toStringAsFixed(2)}',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

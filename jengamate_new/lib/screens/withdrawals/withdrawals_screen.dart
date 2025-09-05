import 'package:flutter/material.dart';
import 'package:jengamate/models/user_model.dart';
import 'package:jengamate/models/withdrawal_model.dart';
import 'package:jengamate/services/database_service.dart';
import 'package:provider/provider.dart';
import 'package:jengamate/models/enums/user_role.dart';
import 'package:jengamate/screens/withdrawals/request_withdrawal_screen.dart';

class WithdrawalsScreen extends StatelessWidget {
  const WithdrawalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = Provider.of<UserModel?>(context, listen: false);
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
        title: const Text('Withdrawals'),
      ),
      body: StreamBuilder<List<WithdrawalModel>>(
        stream: dbService.streamWithdrawals(currentUser.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No withdrawals found.'));
          }

          final withdrawals = snapshot.data!;

          return ListView.builder(
            itemCount: withdrawals.length,
            itemBuilder: (context, index) {
              final withdrawal = withdrawals[index];
              return ListTile(
                title: Text('TSH ${withdrawal.amount.toStringAsFixed(2)}'),
                subtitle: Text(withdrawal.createdAt.toString()),
                trailing: Text(withdrawal.status),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: "addWithdrawalButton", // Unique tag for this button
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const RequestWithdrawalScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

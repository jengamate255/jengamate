import 'package:flutter/material.dart';
import 'package:jengamate/models/financial_transaction_model.dart';
import 'package:jengamate/models/enums/transaction_enums.dart';
import 'package:jengamate/models/commission_model.dart';
import 'package:jengamate/services/database_service.dart';
import 'package:intl/intl.dart';

class FinancialOversightScreen extends StatefulWidget {
  const FinancialOversightScreen({super.key});

  @override
  State<FinancialOversightScreen> createState() =>
      _FinancialOversightScreenState();
}

class _FinancialOversightScreenState extends State<FinancialOversightScreen> {
  final _dbService = DatabaseService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial Oversight'),
      ),
      body: Column(
        children: [
          // Commission Summary Section
          StreamBuilder<List<CommissionModel>>(
            stream: _dbService.getAllCommissions(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Center(child: Text('Error loading commissions: ${snapshot.error}')),
                );
              }
              final allCommissions = snapshot.data ?? [];
              double totalEarned = 0.0;
              double totalPaidOut = 0.0; // Assuming a way to track paid out commissions
              double totalPendingPayout = 0.0;

              for (var comm in allCommissions) {
                totalEarned += comm.total;
                // For simplicity, assuming 'completed' status means paid out for now
                // In a real system, you'd have a separate payout transaction
                if (comm.status == 'Completed') {
                  totalPaidOut += comm.total;
                } else {
                  totalPendingPayout += comm.total;
                }
              }

              return Card(
                margin: const EdgeInsets.all(16.0),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Commission Summary', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 10),
                      _buildSummaryRow('Total Earned:', totalEarned),
                      _buildSummaryRow('Total Paid Out:', totalPaidOut),
                      _buildSummaryRow('Total Pending Payout:', totalPendingPayout),
                    ],
                  ),
                ),
              );
            },
          ),
          // Financial Transactions List
          Expanded(
            child: StreamBuilder<List<FinancialTransaction>>(
              stream: _dbService.getFinancialTransactions(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                final transactions = snapshot.data ?? [];
                if (transactions.isEmpty) {
                  return const Center(child: Text('No financial transactions found.'));
                }
                return ListView.builder(
                  itemCount: transactions.length,
                  itemBuilder: (context, index) {
                    final transaction = transactions[index];
                    return Card(
                      margin: const EdgeInsets.all(8.0),
                      child: ListTile(
                        leading: Icon(_getTransactionIcon(transaction.type)),
                        title: Text(
                            '${transaction.type.toString().split('.').last} - ${NumberFormat.currency(symbol: 'TSh ').format(transaction.amount)}'),
                        subtitle: Text(
                            'User: ${transaction.userId} - ${DateFormat.yMd().add_jm().format(transaction.createdAt)}'),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, double amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.titleMedium),
          Text(NumberFormat.currency(symbol: 'TSh ').format(amount), style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  IconData _getTransactionIcon(TransactionType type) {
    switch (type) {
      case TransactionType.purchase:
        return Icons.shopping_cart;
      case TransactionType.withdrawal:
        return Icons.money;
      case TransactionType.commission:
        return Icons.star;
      case TransactionType.refund:
        return Icons.refresh;
      default:
        return Icons.attach_money; // Default icon for unhandled types
    }
  }
}
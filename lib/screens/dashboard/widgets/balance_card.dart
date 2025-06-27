import 'package:flutter/material.dart';
import 'package:jengamate/utils/theme.dart';

class BalanceCard extends StatelessWidget {
  const BalanceCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Available Balance',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.subTextColor),
            ),
            const SizedBox(height: 8),
            Text(
              'TSH 0',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: AppTheme.textColor, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _QuickActionButton(icon: Icons.shopping_bag_outlined, label: 'Products'),
                _QuickActionButton(icon: Icons.receipt_long_outlined, label: 'Orders'),
                _QuickActionButton(icon: Icons.account_balance_wallet_outlined, label: 'Withdrawals'),
                _QuickActionButton(icon: Icons.group_add_outlined, label: 'Referrals'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;

  const _QuickActionButton({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
          child: Icon(icon, color: AppTheme.primaryColor, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.subTextColor, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

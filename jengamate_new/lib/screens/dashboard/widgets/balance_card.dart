import 'package:flutter/material.dart';
import 'package:jengamate/models/commission_model.dart';
import 'package:jengamate/models/order_stats_model.dart';
import 'package:jengamate/models/user_model.dart';
import 'package:jengamate/screens/withdrawals/withdrawals_screen.dart';
import 'package:jengamate/utils/theme.dart';
import 'package:provider/provider.dart';
import 'package:jengamate/services/user_state_provider.dart';

class BalanceCard extends StatelessWidget {
  final CommissionModel? commission;
  final OrderStatsModel? orderStats;

  const BalanceCard({super.key, this.commission, this.orderStats});

  @override
  Widget build(BuildContext context) {
    final balance = commission?.total ?? orderStats?.totalSales ?? 0;
    final balanceText = 'TSH ${balance.toStringAsFixed(0)}';

    return Card(
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.1),
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
              balanceText,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: AppTheme.textColor, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                const _QuickActionButton(icon: Icons.shopping_bag_outlined, label: 'Products'),
                const _QuickActionButton(icon: Icons.receipt_long_outlined, label: 'Orders'),
                _QuickActionButton(
                  icon: Icons.account_balance_wallet_outlined,
                  label: 'Withdrawals',
                  onPressed: () {
                    final userState = Provider.of<UserStateProvider>(context);
    final user = userState.currentUser;
                    if (user != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const WithdrawalsScreen(),
                        ),
                      );
                    }
                  },
                ),
                const _QuickActionButton(icon: Icons.group_add_outlined, label: 'Referrals'),
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
  final VoidCallback? onPressed;

  const _QuickActionButton({required this.icon, required this.label, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
            child: Icon(icon, color: AppTheme.primaryColor, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.subTextColor, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

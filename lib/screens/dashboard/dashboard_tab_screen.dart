import 'package:flutter/material.dart';
import 'package:jengamate/models/stat_item.dart';
import 'package:jengamate/models/user_model.dart';
import 'package:jengamate/screens/dashboard/widgets/balance_card.dart';
import 'package:jengamate/screens/dashboard/widgets/stats_grid.dart';
import 'package:jengamate/screens/dashboard/widgets/supplier_promo_card.dart';
import 'package:jengamate/utils/theme.dart';
import 'package:jengamate/models/commission_model.dart';
import 'package:jengamate/models/order_stats_model.dart';
import 'package:jengamate/services/database_service.dart';
import 'package:provider/provider.dart';

class DashboardTabScreen extends StatelessWidget {
  const DashboardTabScreen({super.key});

  // Mock data for the stats grids
  static final List<StatItem> _orderStats = [
    StatItem(label: 'TOTAL ORDERS', value: '2', color: Colors.blue.shade800),
    StatItem(label: 'PENDING', value: '1', color: AppTheme.pendingColor),
    StatItem(label: 'COMPLETED', value: '1', color: AppTheme.completedColor),
    StatItem(label: 'TOTAL SALES', value: 'TSH 1,236,000', color: Colors.orange.shade800),
  ];

  static final List<StatItem> _commissionStats = [
    StatItem(label: 'TOTAL', value: 'TSH 1,000,000', color: Colors.purple.shade800),
    StatItem(label: 'DIRECT', value: 'TSH 1,000,000', color: Colors.teal.shade800),
    StatItem(label: 'REFERRAL', value: 'TSH 0', color: Colors.amber.shade800),
    StatItem(label: 'ACTIVE', value: 'TSH 0', color: Colors.green.shade800),
  ];

  Widget _buildEngineerUI(BuildContext context, UserModel currentUser) {
    final dbService = DatabaseService();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const BalanceCard(),
        const SizedBox(height: 24),
        const SupplierPromoCard(),
        const SizedBox(height: 24),
        StreamBuilder<CommissionModel?>(
          stream: dbService.streamCommission(currentUser.uid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            if (!snapshot.hasData || snapshot.data == null) {
              return const Center(child: Text('No commission data available.'));
            }

            final commission = snapshot.data!;
            final commissionStats = [
              StatItem(label: 'TOTAL', value: 'TSH ${commission.total.toStringAsFixed(0)}', color: Colors.purple.shade800),
              StatItem(label: 'DIRECT', value: 'TSH ${commission.direct.toStringAsFixed(0)}', color: Colors.teal.shade800),
              StatItem(label: 'REFERRAL', value: 'TSH ${commission.referral.toStringAsFixed(0)}', color: Colors.amber.shade800),
              StatItem(label: 'ACTIVE', value: 'TSH ${commission.active.toStringAsFixed(0)}', color: Colors.green.shade800),
            ];

            return StatsGrid(title: 'COMMISSION EARNED', stats: commissionStats);
          },
        ),
      ],
    );
  }

  Widget _buildSupplierUI(BuildContext context, UserModel currentUser) {
    final dbService = DatabaseService();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const BalanceCard(),
        const SizedBox(height: 24),
        StreamBuilder<OrderStatsModel?>(
          stream: dbService.streamOrderStats(currentUser.uid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            if (!snapshot.hasData || snapshot.data == null) {
              return const Center(child: Text('No order data available.'));
            }

            final orderStats = snapshot.data!;
            final stats = [
              StatItem(label: 'TOTAL ORDERS', value: orderStats.totalOrders.toString(), color: Colors.blue.shade800),
              StatItem(label: 'PENDING', value: orderStats.pending.toString(), color: AppTheme.pendingColor),
              StatItem(label: 'COMPLETED', value: orderStats.completed.toString(), color: AppTheme.completedColor),
              StatItem(label: 'TOTAL SALES', value: 'TSH ${orderStats.totalSales.toStringAsFixed(0)}', color: Colors.orange.shade800),
            ];

            return StatsGrid(title: 'ORDER STATISTICS', stats: stats);
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<UserModel?>();

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Custom Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (currentUser == null)
                        const Text('Loading...', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold))
                      else
                        Text('Hello, ${currentUser.displayName}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      Text(currentUser == null ? '' : '@${currentUser.email.split('@').first}', style: const TextStyle(color: AppTheme.subTextColor)),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.notifications_none_rounded, size: 28),
                    onPressed: () {},
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Role-specific UI
              if (currentUser == null)
                const Center(child: CircularProgressIndicator())
              else if (currentUser.role == 'engineer')
                _buildEngineerUI(context, currentUser)
              else if (currentUser.role == 'supplier')
                _buildSupplierUI(context, currentUser)
              else // Default or other roles
                Text('Welcome! Your role: ${currentUser.role}'),
            ],
          ),
        ),
      ),
    );
  }
}

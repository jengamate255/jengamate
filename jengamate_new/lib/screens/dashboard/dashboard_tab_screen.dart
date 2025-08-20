import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:jengamate/models/stat_item.dart';
import 'package:jengamate/utils/sentry_test.dart';
import 'package:jengamate/models/user_model.dart';
import 'package:jengamate/models/enums/user_role.dart';
import 'package:jengamate/screens/dashboard/widgets/balance_card.dart';
import 'package:jengamate/screens/dashboard/widgets/stats_grid.dart';
import 'package:jengamate/screens/dashboard/widgets/supplier_promo_card.dart';
import 'package:jengamate/utils/theme.dart';
import 'package:jengamate/models/commission_model.dart';
import 'package:jengamate/models/order_stats_model.dart';
import 'package:jengamate/services/database_service.dart';
import 'package:provider/provider.dart';

import 'package:jengamate/config/app_routes.dart';
import 'package:go_router/go_router.dart';
import 'package:jengamate/screens/admin/enhanced_analytics_dashboard.dart';
import 'package:jengamate/ui/design_system/layout/adaptive_padding.dart';
import 'package:jengamate/ui/design_system/tokens/spacing.dart';

class DashboardTabScreen extends StatelessWidget {
  const DashboardTabScreen({super.key});

  Widget _buildQuickActions(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick Actions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    context,
                    'Referral Dashboard',
                    Icons.card_giftcard,
                    Colors.purple,
                    () => context.go('/referral-dashboard'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    context,
                    'Financial History',
                    Icons.account_balance,
                    Colors.green,
                    () => context.go('/financial-dashboard'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    context,
                    'Support Center',
                    Icons.support_agent,
                    Colors.blue,
                    () => context.go('/support-dashboard'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(), // Empty space for symmetry
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEngineerUI(BuildContext context, UserModel currentUser) {
    final dbService = DatabaseService();

    return StreamBuilder<CommissionModel?>(
      stream: dbService.streamCommissionRules(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final commission = snapshot.data;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BalanceCard(commission: commission),
            const SizedBox(height: 24),
            _buildQuickActions(context),
            const SizedBox(height: 24),
            if (commission != null)
              StatsGrid(
                title: 'COMMISSION EARNED',
                stats: <StatItem>[
                  StatItem(
                      label: 'TOTAL',
                      value: 'TSH ${commission.total.toStringAsFixed(0)}',
                      color: Colors.purple.shade800),
                  StatItem(
                      label: 'DIRECT',
                      value: 'TSH ${commission.direct.toStringAsFixed(0)}',
                      color: Colors.teal.shade800),
                  StatItem(
                      label: 'REFERRAL',
                      value: 'TSH ${commission.referral.toStringAsFixed(0)}',
                      color: Colors.amber.shade800),
                  StatItem(
                      label: 'ACTIVE',
                      value: 'TSH ${commission.active.toStringAsFixed(0)}',
                      color: Colors.green.shade800),
                ],
              ),
          ],
        );
      },
    );
  }

  Widget _buildSupplierUI(BuildContext context, UserModel currentUser) {
    final dbService = DatabaseService();

    return StreamBuilder<Map<String, int>>(
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

        final stats = snapshot.data!;
        // Safely read all possible statuses with defaults
        final pending = stats['pending'] ?? 0;
        final processing = stats['processing'] ?? 0;
        final shipped = stats['shipped'] ?? 0;
        final delivered = stats['delivered'] ?? 0; // maps to completed in UI
        final cancelled = stats['cancelled'] ?? 0;

        final orderStats = OrderStatsModel(
          // Total should include all known statuses
          totalOrders: pending + processing + shipped + delivered + cancelled,
          pendingOrders: pending,
          // Use delivered as the completed count
          completedOrders: delivered,
          totalSales: 0, // This needs to be calculated from actual sales data
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BalanceCard(orderStats: orderStats),
            const SizedBox(height: 24),
            const SupplierPromoCard(),
            const SizedBox(height: 24),
            StatsGrid(
              title: 'ORDER STATISTICS',
              stats: <StatItem>[
                StatItem(
                    label: 'TOTAL ORDERS',
                    value: orderStats.totalOrders.toString(),
                    color: Colors.blue.shade800),
                StatItem(
                    label: 'PENDING',
                    value: orderStats.pendingOrders.toString(),
                    color: AppTheme.pendingColor),
                StatItem(
                    label: 'COMPLETED',
                    value: orderStats.completedOrders.toString(),
                    color: AppTheme.completedColor),
                StatItem(
                    label: 'TOTAL SALES',
                    value: 'TSH ${orderStats.totalSales.toStringAsFixed(0)}',
                    color: Colors.orange.shade800),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildAdminUI(BuildContext context) {
    return const EnhancedAnalyticsDashboard();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = Provider.of<UserModel?>(context);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: AdaptivePadding(
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
                          const Text(
                            'Loading...',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        else
                          Text(
                            'Welcome back, ${currentUser.displayName}!',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        Text(
                          currentUser == null
                              ? ''
                              : '@${(currentUser.email?.split('@').first ?? 'user')}',
                          style: const TextStyle(color: AppTheme.subTextColor),
                        ),
                      ],
                    ),
                    IconButton(
                      icon:
                          const Icon(Icons.notifications_none_rounded, size: 28),
                      onPressed: () {},
                    ),
                  ],
                ),
                const SizedBox(height: JMSpacing.xl),

              // Role-specific UI
              if (currentUser == null)
                const Center(child: CircularProgressIndicator())
              else if (currentUser.role == UserRole.engineer)
                _buildEngineerUI(context, currentUser)
              else if (currentUser.role == UserRole.supplier)
                _buildSupplierUI(context, currentUser)
              else if (currentUser.role == UserRole.admin)
                _buildAdminUI(context)
              else // Default or other roles
                Text(
                    'Welcome! Your role: ${currentUser.role.toString().split('.').last}'),

              // Sentry Test Widget (Debug Mode Only)
              if (kDebugMode) ...[
                const SizedBox(height: JMSpacing.xl),
                const SentryTestWidget(),
              ],
            ],
          ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:jengamate/models/stat_item.dart';
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
import 'package:jengamate/services/user_state_provider.dart';

import 'package:go_router/go_router.dart';
import 'package:jengamate/screens/admin/admin_tools_screen.dart';
import 'package:jengamate/utils/responsive.dart';

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

  Widget _salesLineChart(BuildContext context, List<double> data, Color color) {
    if (data.isEmpty) {
      return const SizedBox(height: 40);
    }
    final maxVal = data.reduce((a, b) => a > b ? a : b);
    final spots = <FlSpot>[];
    for (int i = 0; i < data.length; i++) {
      spots.add(FlSpot(i.toDouble(), data[i]));
    }
    return SizedBox(
      height: 120,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: (data.length - 1).toDouble(),
          minY: 0,
          maxY: (maxVal <= 0 ? 1.0 : maxVal) * 1.1,
          gridData: const FlGridData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 18,
                interval: (data.length / 6).clamp(1, data.length).toDouble(),
                getTitlesWidget: (value, meta) {
                  final int v = value.round();
                  if (v < 0 || v >= data.length) return const SizedBox.shrink();
                  final daysAgo = (data.length - 1) - v; // 0=today
                  String label;
                  if (daysAgo == 0) label = 'T';
                  else if (daysAgo == 1) label = 'Y';
                  else label = '${daysAgo}d';
                  return Text(label, style: Theme.of(context).textTheme.labelSmall);
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineTouchData: LineTouchData(
            enabled: true,
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((ts) {
                  final idx = ts.x.round();
                  final daysAgo = (data.length - 1) - idx;
                  final when = daysAgo == 0
                      ? 'Today'
                      : daysAgo == 1
                          ? 'Yesterday'
                          : '${daysAgo}d ago';
                  return LineTooltipItem(
                    '$when\n${_formatTsh(ts.y)}',
                    const TextStyle(color: Colors.white, fontSize: 11),
                  );
                }).toList();
              },
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: color,
              barWidth: 2.5,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: color.withValues(alpha: 0.15),
                applyCutOffY: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sparklineBars(BuildContext context, List<double> data, Color color) {
    final maxVal = data.isEmpty ? 0.0 : data.reduce((a, b) => a > b ? a : b);
    final barCount = data.length;
    const barWidth = 6.0;
    const barSpacing = 4.0;
    const height = 40.0;
    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(barCount, (i) {
          final v = data[i];
          final h = maxVal <= 0 ? 2.0 : ((v / maxVal) * (height - 2)).clamp(2.0, height - 2);
          final daysAgo = (barCount - 1) - i; // 0 = today, 1 = yesterday
          final label = daysAgo == 0
              ? 'Today'
              : daysAgo == 1
                  ? 'Yesterday'
                  : '${daysAgo}d ago';
          return Padding(
            padding: EdgeInsets.only(right: i == barCount - 1 ? 0 : barSpacing),
            child: Tooltip(
              message: '$label • ${_formatTsh(v)}',
              child: Container(
                width: barWidth,
                height: h,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          );
        }),
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
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
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
      stream: dbService
          .streamCommissionRules()
          .map((list) => list.isNotEmpty ? list.first : null),
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
      stream: dbService
          .streamOrderStats(currentUser.uid ?? '')
          .map((m) => m.map((k, v) => MapEntry(k, (v as num).toInt()))),
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
    final db = DatabaseService();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildQuickActions(context),
        const SizedBox(height: 24),
        Text(
          'Platform Overview',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: StatefulBuilder(
              builder: (context, setLocalState) {
                // 0 = All, 1 = 7d, 2 = 30d
                int salesWindow = 0;
                const spacing = 16.0;
                Widget salesValueForWindow() {
                  if (salesWindow == 1) {
                    return StreamBuilder<double>(
                      stream: db.streamTotalSalesAmountTSHWindow(days: 7),
                      builder: (context, snapshot) => _kpiValue(context, _formatTsh(snapshot.data)),
                    );
                  } else if (salesWindow == 2) {
                    return StreamBuilder<double>(
                      stream: db.streamTotalSalesAmountTSHWindow(days: 30),
                      builder: (context, snapshot) => _kpiValue(context, _formatTsh(snapshot.data)),
                    );
                  }
                  return StreamBuilder<double>(
                    stream: db.streamTotalSalesAmountTSH(),
                    builder: (context, snapshot) => _kpiValue(context, _formatTsh(snapshot.data)),
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        const Text('Total Sales window:'),
                        ChoiceChip(
                          label: const Text('All'),
                          selected: salesWindow == 0,
                          onSelected: (_) => setLocalState(() => salesWindow = 0),
                        ),
                        ChoiceChip(
                          label: const Text('7d'),
                          selected: salesWindow == 1,
                          onSelected: (_) => setLocalState(() => salesWindow = 1),
                        ),
                        ChoiceChip(
                          label: const Text('30d'),
                          selected: salesWindow == 2,
                          onSelected: (_) => setLocalState(() => salesWindow = 2),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: spacing,
                      runSpacing: spacing,
                      children: [
                        _buildKpiCard(
                          context,
                          title: 'Total Users',
                          icon: Icons.people,
                          color: Colors.blue,
                          value: StreamBuilder<int>(
                            stream: db.streamTotalUsersCount(),
                            builder: (context, snapshot) => _kpiValue(context, snapshot.data?.toString()),
                          ),
                        ),
                        _buildKpiCard(
                          context,
                          title: 'Total Orders',
                          icon: Icons.shopping_cart,
                          color: Colors.green,
                          value: StreamBuilder<int>(
                            stream: db.streamTotalOrdersCount(),
                            builder: (context, snapshot) => _kpiValue(context, snapshot.data?.toString()),
                          ),
                        ),
                        _buildKpiCard(
                          context,
                          title: 'Pending Orders',
                          icon: Icons.timelapse,
                          color: Colors.orange,
                          value: StreamBuilder<int>(
                            stream: db.streamPendingOrdersCount(),
                            builder: (context, snapshot) => _kpiValue(context, snapshot.data?.toString()),
                          ),
                        ),
                        _buildKpiCard(
                          context,
                          title: salesWindow == 0
                              ? 'Total Sales (All)'
                              : salesWindow == 1
                                  ? 'Total Sales (7d)'
                                  : 'Total Sales (30d)',
                          icon: Icons.payments,
                          color: Colors.purple,
                          value: salesValueForWindow(),
                        ),
                    _buildKpiCard(
                      context,
                      title: 'Completed Orders',
                      icon: Icons.check_circle,
                      color: Colors.teal,
                      value: StreamBuilder<int>(
                        stream: db.streamCompletedOrdersCount(),
                        builder: (context, snapshot) => _kpiValue(context, snapshot.data?.toString()),
                      ),
                    ),
                    _buildKpiCard(
                      context,
                      title: 'New Users (7d)',
                      icon: Icons.person_add,
                      color: Colors.indigo,
                      value: StreamBuilder<int>(
                        stream: db.streamNewUsersCount(days: 7),
                        builder: (context, snapshot) => _kpiValue(context, snapshot.data?.toString()),
                      ),
                    ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sales Trend',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Last 7 days'),
                          const SizedBox(height: 8),
                          StreamBuilder<List<double>>(
                            stream: db.streamDailySalesTSH(days: 7),
                            builder: (context, snapshot) {
                              if (snapshot.hasError) {
                                return Text(
                                  'Needs index for orders(status, createdAt)',
                                  style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12),
                                );
                              }
                              final data = snapshot.data;
                              if (data == null) {
                                return const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                );
                              }
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _salesLineChart(context, data, Colors.purple),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Total: ${_formatTsh(data.fold<double>(0, (s, v) => s + v))}',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Last 30 days'),
                          const SizedBox(height: 8),
                          StreamBuilder<List<double>>(
                            stream: db.streamDailySalesTSH(days: 30),
                            builder: (context, snapshot) {
                              if (snapshot.hasError) {
                                return Text(
                                  'Needs index for orders(status, createdAt)',
                                  style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12),
                                );
                              }
                              final data = snapshot.data;
                              if (data == null) {
                                return const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                );
                              }
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _salesLineChart(context, data, Colors.orange),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Total: ${_formatTsh(data.fold<double>(0, (s, v) => s + v))}',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _formatTsh(double? v) {
    if (v == null) return 'TSH 0';
    // Whole-number TSH formatting without intl dependency here
    final rounded = v.round().toString();
    final buffer = StringBuffer();
    for (int i = 0; i < rounded.length; i++) {
      final idxFromEnd = rounded.length - i;
      buffer.write(rounded[i]);
      if (idxFromEnd > 1 && idxFromEnd % 3 == 1) buffer.write(',');
    }
    return 'TSH ${buffer.toString()}';
  }

  Widget _kpiValue(BuildContext context, String? value) {
    if (value == null) {
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }
    return Text(
      value,
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }

  Widget _buildKpiCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required Widget value,
  }) {
    final isDesktop = Responsive.isDesktop(context);
    final width = isDesktop ? 360.0 : 300.0;
    return SizedBox(
      width: width,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).dividerColor),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ],
            ),
            const SizedBox(height: 12),
            DefaultTextStyle(
              style: Theme.of(context).textTheme.headlineSmall ?? const TextStyle(fontSize: 20),
              child: value,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userState = Provider.of<UserStateProvider>(context);
    final currentUser = userState.currentUser;

    // Show loading state if user data is still loading
    if (userState.isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading your dashboard...'),
            ],
          ),
        ),
      );
    }

    // Show error state if no user data
    if (currentUser == null) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red),
              SizedBox(height: 16),
              Text('Unable to load user data'),
              Text('Please try logging in again'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              // Add a bit of guaranteed bottom padding to avoid tiny overflows
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).padding.bottom + 56,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Custom Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Welcome back, ${currentUser.displayName}!',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  '@${(currentUser.email?.split('@').first ?? 'user')}',
                                  style: const TextStyle(
                                      color: AppTheme.subTextColor),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              if (currentUser?.role == UserRole.admin)
                                IconButton(
                                  tooltip: 'Admin Tools',
                                  icon: const Icon(Icons.admin_panel_settings,
                                      size: 26),
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => const AdminToolsScreen(),
                                      ),
                                    );
                                  },
                                ),
                              IconButton(
                                icon: const Icon(
                                  Icons.notifications_none_rounded,
                                  size: 28,
                                ),
                                onPressed: () {},
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

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

                      // Sentry test widget removed.

                      // Extra spacing retained; combined with outer padding this prevents overflow
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

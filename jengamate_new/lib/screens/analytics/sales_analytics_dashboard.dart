import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jengamate/models/order_model.dart';
import 'package:jengamate/models/order_status.dart';
import 'package:jengamate/services/database_service.dart';
import 'package:jengamate/ui/design_system/layout/adaptive_padding.dart';
import 'package:jengamate/ui/design_system/tokens/spacing.dart';
import 'package:jengamate/ui/design_system/components/jm_card.dart';
import 'package:jengamate/models/user_model.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

class SalesAnalyticsDashboard extends StatefulWidget {
  const SalesAnalyticsDashboard({super.key});

  @override
  State<SalesAnalyticsDashboard> createState() =>
      _SalesAnalyticsDashboardState();
}

class _SalesAnalyticsDashboardState extends State<SalesAnalyticsDashboard> {
  final DatabaseService _dbService = DatabaseService();
  String _selectedPeriod = '30'; // 7, 30, 90, 365 days
  String _selectedMetric = 'revenue'; // revenue, orders, customers

  @override
  Widget build(BuildContext context) {
    final currentUser = Provider.of<UserModel?>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales Analytics'),
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () => _exportAnalytics(),
            tooltip: 'Export Analytics',
          ),
        ],
      ),
      body: AdaptivePadding(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPeriodSelector(),
              const SizedBox(height: JMSpacing.lg),
              _buildKeyMetrics(currentUser?.uid ?? ''),
              const SizedBox(height: JMSpacing.lg),
              _buildRevenueChart(currentUser?.uid ?? ''),
              const SizedBox(height: JMSpacing.lg),
              _buildTopProducts(currentUser?.uid ?? ''),
              const SizedBox(height: JMSpacing.lg),
              _buildCustomerInsights(currentUser?.uid ?? ''),
              const SizedBox(height: JMSpacing.lg),
              _buildOrderPerformance(currentUser?.uid ?? ''),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return JMCard(
      child: Padding(
        padding: const EdgeInsets.all(JMSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Analytics Period',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: JMSpacing.md),
            Row(
              children: [
                _buildPeriodChip('7', '7 Days'),
                const SizedBox(width: JMSpacing.sm),
                _buildPeriodChip('30', '30 Days'),
                const SizedBox(width: JMSpacing.sm),
                _buildPeriodChip('90', '90 Days'),
                const SizedBox(width: JMSpacing.sm),
                _buildPeriodChip('365', '1 Year'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodChip(String value, String label) {
    final isSelected = _selectedPeriod == value;
    return InkWell(
      onTap: () => setState(() => _selectedPeriod = value),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: JMSpacing.md, vertical: JMSpacing.sm),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).primaryColor
              : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildKeyMetrics(String userId) {
    return StreamBuilder<List<OrderModel>>(
      stream: _dbService.getOrders(userId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const JMCard(
            child: Padding(
              padding: EdgeInsets.all(JMSpacing.lg),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final orders = snapshot.data!;
        final periodDays = int.parse(_selectedPeriod);
        final cutoffDate = DateTime.now().subtract(Duration(days: periodDays));

        final periodOrders = orders
            .where((order) => order.createdAt.isAfter(cutoffDate))
            .toList();
        final totalRevenue =
            periodOrders.fold(0.0, (sum, order) => sum + order.totalAmount);
        final totalOrders = periodOrders.length;
        final uniqueCustomers = periodOrders
            .map((order) => order.buyerId)
            .where((id) => id != null)
            .toSet()
            .length;
        final averageOrderValue =
            totalOrders > 0 ? totalRevenue / totalOrders : 0.0;

        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    title: 'Total Revenue',
                    value: 'TSh ${NumberFormat('#,##0').format(totalRevenue)}',
                    icon: Icons.attach_money,
                    color: Colors.green,
                    trend: _calculateTrend(orders, 'revenue'),
                  ),
                ),
                const SizedBox(width: JMSpacing.md),
                Expanded(
                  child: _buildMetricCard(
                    title: 'Total Orders',
                    value: totalOrders.toString(),
                    icon: Icons.shopping_cart,
                    color: Colors.blue,
                    trend: _calculateTrend(orders, 'orders'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: JMSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    title: 'Unique Customers',
                    value: uniqueCustomers.toString(),
                    icon: Icons.people,
                    color: Colors.purple,
                    trend: _calculateTrend(orders, 'customers'),
                  ),
                ),
                const SizedBox(width: JMSpacing.md),
                Expanded(
                  child: _buildMetricCard(
                    title: 'Average Order Value',
                    value:
                        'TSh ${NumberFormat('#,##0').format(averageOrderValue)}',
                    icon: Icons.analytics,
                    color: Colors.orange,
                    trend: _calculateTrend(orders, 'aov'),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required double trend,
  }) {
    return JMCard(
      child: Padding(
        padding: const EdgeInsets.all(JMSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 24),
                Row(
                  children: [
                    Icon(
                      trend >= 0 ? Icons.trending_up : Icons.trending_down,
                      color: trend >= 0 ? Colors.green : Colors.red,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${trend.abs().toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: trend >= 0 ? Colors.green : Colors.red,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: JMSpacing.sm),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueChart(String userId) {
    return JMCard(
      child: Padding(
        padding: const EdgeInsets.all(JMSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Revenue Trend',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: JMSpacing.md),
            SizedBox(
              height: 200,
              child: StreamBuilder<List<OrderModel>>(
                stream: _dbService.getOrders(userId),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final orders = snapshot.data!;
                  final chartData = _generateChartData(orders);

                  return LineChart(
                    LineChartData(
                      gridData: FlGridData(show: true),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                'TSh ${(value / 1000).toInt()}K',
                                style: const TextStyle(fontSize: 10),
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              if (value.toInt() % 7 == 0) {
                                return Text(
                                  DateFormat('MMM dd').format(
                                    DateTime.now().subtract(
                                        Duration(days: 30 - value.toInt())),
                                  ),
                                  style: const TextStyle(fontSize: 10),
                                );
                              }
                              return const Text('');
                            },
                          ),
                        ),
                        topTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        rightTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: true),
                      lineBarsData: [
                        LineChartBarData(
                          spots: chartData,
                          isCurved: true,
                          color: Theme.of(context).primaryColor,
                          barWidth: 3,
                          dotData: FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            color:
                                Theme.of(context).primaryColor.withOpacity(0.1),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopProducts(String userId) {
    return JMCard(
      child: Padding(
        padding: const EdgeInsets.all(JMSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Top Products',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () => _viewAllProducts(),
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: JMSpacing.md),
            StreamBuilder<List<OrderModel>>(
              stream: _dbService.getOrders(userId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final orders = snapshot.data!;
                final topProducts = _getTopProducts(orders);

                return Column(
                  children: topProducts
                      .take(5)
                      .map((product) => _buildProductItem(product))
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductItem(Map<String, dynamic> product) {
    return Container(
      margin: const EdgeInsets.only(bottom: JMSpacing.sm),
      padding: const EdgeInsets.all(JMSpacing.sm),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.inventory,
              color: Theme.of(context).primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: JMSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product['name'] ?? 'Unknown Product',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '${product['orders']} orders',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            'TSh ${NumberFormat('#,##0').format(product['revenue'])}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerInsights(String userId) {
    return JMCard(
      child: Padding(
        padding: const EdgeInsets.all(JMSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Customer Insights',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: JMSpacing.md),
            StreamBuilder<List<OrderModel>>(
              stream: _dbService.getOrders(userId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final orders = snapshot.data!;
                final insights = _getCustomerInsights(orders);

                return Column(
                  children: [
                    _buildInsightItem(
                      'New Customers',
                      insights['newCustomers'].toString(),
                      Icons.person_add,
                      Colors.green,
                    ),
                    _buildInsightItem(
                      'Repeat Customers',
                      insights['repeatCustomers'].toString(),
                      Icons.people,
                      Colors.blue,
                    ),
                    _buildInsightItem(
                      'Customer Retention Rate',
                      '${insights['retentionRate'].toStringAsFixed(1)}%',
                      Icons.trending_up,
                      Colors.orange,
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightItem(
      String title, String value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: JMSpacing.sm),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: JMSpacing.sm),
          Expanded(
            child: Text(title),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderPerformance(String userId) {
    return JMCard(
      child: Padding(
        padding: const EdgeInsets.all(JMSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Order Performance',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: JMSpacing.md),
            StreamBuilder<List<OrderModel>>(
              stream: _dbService.getOrders(userId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final orders = snapshot.data!;
                final performance = _getOrderPerformance(orders);

                return Column(
                  children: [
                    _buildPerformanceItem('Pending Orders',
                        performance['pending'] ?? 0, Colors.orange),
                    _buildPerformanceItem('Processing Orders',
                        performance['processing'] ?? 0, Colors.blue),
                    _buildPerformanceItem('Shipped Orders',
                        performance['shipped'] ?? 0, Colors.purple),
                    _buildPerformanceItem('Delivered Orders',
                        performance['delivered'] ?? 0, Colors.green),
                    _buildPerformanceItem('Cancelled Orders',
                        performance['cancelled'] ?? 0, Colors.red),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceItem(String title, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: JMSpacing.sm),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(width: JMSpacing.sm),
          Expanded(
            child: Text(title),
          ),
          Text(
            count.toString(),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods
  double _calculateTrend(List<OrderModel> orders, String metric) {
    // Simple trend calculation - in a real app, you'd compare with previous period
    return 12.5; // Placeholder - would calculate actual trend
  }

  List<FlSpot> _generateChartData(List<OrderModel> orders) {
    // Generate chart data for the last 30 days
    final spots = <FlSpot>[];
    for (int i = 0; i < 30; i++) {
      final date = DateTime.now().subtract(Duration(days: 29 - i));
      final dayOrders = orders
          .where((order) =>
              order.createdAt.year == date.year &&
              order.createdAt.month == date.month &&
              order.createdAt.day == date.day)
          .toList();

      final revenue =
          dayOrders.fold(0.0, (sum, order) => sum + order.totalAmount);
      spots.add(FlSpot(i.toDouble(), revenue));
    }
    return spots;
  }

  List<Map<String, dynamic>> _getTopProducts(List<OrderModel> orders) {
    // Placeholder - would analyze actual product data
    return [
      {'name': 'Product A', 'orders': 15, 'revenue': 250000},
      {'name': 'Product B', 'orders': 12, 'revenue': 180000},
      {'name': 'Product C', 'orders': 8, 'revenue': 120000},
      {'name': 'Product D', 'orders': 6, 'revenue': 90000},
      {'name': 'Product E', 'orders': 4, 'revenue': 60000},
    ];
  }

  Map<String, dynamic> _getCustomerInsights(List<OrderModel> orders) {
    // Placeholder - would analyze actual customer data
    return {
      'newCustomers': 25,
      'repeatCustomers': 18,
      'retentionRate': 72.0,
    };
  }

  Map<String, int> _getOrderPerformance(List<OrderModel> orders) {
    final pending =
        orders.where((order) => order.status == OrderStatus.pending).length;
    final processing =
        orders.where((order) => order.status == OrderStatus.processing).length;
    final shipped =
        orders.where((order) => order.status == OrderStatus.shipped).length;
    final delivered =
        orders.where((order) => order.status == OrderStatus.delivered).length;
    final cancelled =
        orders.where((order) => order.status == OrderStatus.cancelled).length;

    return {
      'pending': pending,
      'processing': processing,
      'shipped': shipped,
      'delivered': delivered,
      'cancelled': cancelled,
    };
  }

  void _exportAnalytics() {
    // TODO: Implement analytics export
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Analytics export feature coming soon!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _viewAllProducts() {
    // TODO: Navigate to products screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Products screen coming soon!'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}

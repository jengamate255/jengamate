import 'package:flutter/material.dart';
import 'package:jengamate/services/database_service.dart';
import 'package:jengamate/utils/responsive.dart';
import 'package:jengamate/utils/logger.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

class AdvancedAnalyticsScreen extends StatefulWidget {
  const AdvancedAnalyticsScreen({super.key});

  @override
  State<AdvancedAnalyticsScreen> createState() => _AdvancedAnalyticsScreenState();
}

class _AdvancedAnalyticsScreenState extends State<AdvancedAnalyticsScreen> with TickerProviderStateMixin {
  final DatabaseService _databaseService = DatabaseService();
  late TabController _tabController;

  bool _isLoading = true;
  Map<String, dynamic> _analyticsData = {};
  List<FlSpot> _salesData = [];
  List<FlSpot> _userGrowthData = [];
  List<PieChartSectionData> _categoryData = [];
  String _selectedPeriod = '30d';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadAnalyticsData();
  }

  Future<void> _loadAnalyticsData() async {
    setState(() => _isLoading = true);
    try {
      final analytics = await _databaseService.getAdminAnalytics();
      final salesOverTime = await _databaseService.getSalesOverTime();
      final topProducts = await _databaseService.getTopSellingProducts(5);
      final userGrowthData = await _databaseService.getUserGrowthOverTime();

      setState(() {
        _analyticsData = {
          ...analytics,
          'topProducts': topProducts,
        };
        _salesData = _generateSalesData(salesOverTime);
        _userGrowthData = _generateUserGrowthData(userGrowthData);
        _categoryData = _generateCategoryData();
      });

      Logger.log('Analytics data loaded successfully');
    } catch (e) {
      Logger.logError('Error loading analytics data', e, StackTrace.current);
      // Set empty data - no fallback sample data
      setState(() {
        _analyticsData = {};
        _salesData = _generateSalesData({});
        _userGrowthData = _generateUserGrowthData({});
        _categoryData = _generateCategoryData();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load analytics data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<FlSpot> _generateSalesData(Map<DateTime, double> salesMap) {
    final data = <FlSpot>[];
    if (salesMap.isNotEmpty) {
      final sortedDates = salesMap.keys.toList()..sort();
      for (int i = 0; i < sortedDates.length; i++) {
        final date = sortedDates[i];
        final value = salesMap[date] ?? 0.0;
        data.add(FlSpot(i.toDouble(), value));
      }
    } else {
      // Show empty chart with zero values for last 30 days
      for (int i = 29; i >= 0; i--) {
        data.add(FlSpot(i.toDouble(), 0.0));
      }
    }
    return data;
  }

  List<FlSpot> _generateUserGrowthData(Map<DateTime, int> userGrowthMap) {
    final data = <FlSpot>[];
    if (userGrowthMap.isNotEmpty) {
      final sortedDates = userGrowthMap.keys.toList()..sort();
      for (int i = 0; i < sortedDates.length; i++) {
        final date = sortedDates[i];
        final value = userGrowthMap[date] ?? 0;
        data.add(FlSpot(i.toDouble(), value.toDouble()));
      }
    } else {
      // Show empty chart with zero values for last 30 days
      for (int i = 0; i < 30; i++) {
        data.add(FlSpot(i.toDouble(), 0.0));
      }
    }

    return data;
  }

  List<PieChartSectionData> _generateCategoryData() {
    // Get category data from analytics or show "No Data" message
    final categoryData = _analyticsData['categoryData'] as List<Map<String, dynamic>>? ?? [];

    if (categoryData.isEmpty) {
      // Show single section indicating no data
      return [
        PieChartSectionData(
          color: Colors.grey.shade300,
          value: 100,
          title: 'No Data\nAvailable',
          radius: 60,
          titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54),
        ),
      ];
    }

    final colors = [Colors.blue, Colors.green, Colors.orange, Colors.purple, Colors.red, Colors.teal];

    return categoryData.asMap().entries.map((entry) {
      final index = entry.key;
      final category = entry.value;
      final color = colors[index % colors.length];
      final value = (category['value'] as num?)?.toDouble() ?? 0.0;
      final name = category['name'] as String? ?? 'Unknown';
      final percentage = category['percentage'] as num? ?? 0;

      return PieChartSectionData(
        color: color,
        value: value,
        title: '$name\n${percentage.toStringAsFixed(1)}%',
        radius: 60,
        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Advanced Analytics'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.date_range),
            onSelected: (period) {
              setState(() => _selectedPeriod = period);
              _loadAnalyticsData();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: '7d', child: Text('Last 7 days')),
              const PopupMenuItem(value: '30d', child: Text('Last 30 days')),
              const PopupMenuItem(value: '90d', child: Text('Last 90 days')),
              const PopupMenuItem(value: '1y', child: Text('Last year')),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAnalyticsData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Overview', icon: Icon(Icons.dashboard)),
            Tab(text: 'Sales', icon: Icon(Icons.trending_up)),
            Tab(text: 'Users', icon: Icon(Icons.people)),
            Tab(text: 'Products', icon: Icon(Icons.inventory)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildSalesTab(),
                _buildUsersTab(),
                _buildProductsTab(),
              ],
            ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildKPICards(),
          const SizedBox(height: 24),
          _buildSectionTitle('Sales Trend (Last 30 Days)'),
          const SizedBox(height: 16),
          _buildSalesChart(),
          const SizedBox(height: 24),
          _buildSectionTitle('Category Distribution'),
          const SizedBox(height: 16),
          _buildCategoryChart(),
        ],
      ),
    );
  }

  Widget _buildSalesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSalesMetrics(),
          const SizedBox(height: 24),
          _buildSectionTitle('Sales Performance'),
          const SizedBox(height: 16),
          _buildSalesChart(),
          const SizedBox(height: 24),
          _buildTopProductsList(),
        ],
      ),
    );
  }

  Widget _buildUsersTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildUserMetrics(),
          const SizedBox(height: 24),
          _buildSectionTitle('User Growth'),
          const SizedBox(height: 16),
          _buildUserGrowthChart(),
          const SizedBox(height: 24),
          _buildUserEngagementMetrics(),
        ],
      ),
    );
  }

  Widget _buildProductsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProductMetrics(),
          const SizedBox(height: 24),
          _buildSectionTitle('Category Performance'),
          const SizedBox(height: 16),
          _buildCategoryChart(),
          const SizedBox(height: 24),
          _buildTopProductsList(),
        ],
      ),
    );
  }

  Widget _buildKPICards() {
    final totalRevenue = _analyticsData['totalRevenue']?.toDouble() ?? 0.0;
    final totalOrders = _analyticsData['totalOrders'] ?? 0;
    final totalUsers = _analyticsData['totalUsers'] ?? 0;
    final avgOrderValue = totalOrders > 0 ? totalRevenue / totalOrders : 0.0;

    return Responsive.isMobile(context)
        ? Column(children: _buildKPICardsList(totalRevenue, totalOrders, totalUsers, avgOrderValue))
        : Wrap(
            spacing: Responsive.getResponsiveSpacing(context),
            runSpacing: Responsive.getResponsiveSpacing(context),
            children: _buildKPICardsList(totalRevenue, totalOrders, totalUsers, avgOrderValue)
                .map((card) => SizedBox(width: Responsive.getResponsiveCardWidth(context), child: card))
                .toList(),
          );
  }

  List<Widget> _buildKPICardsList(double revenue, int orders, int users, double avgOrder) {
    return [
      _buildKPICard('Total Revenue', 'TSh ${NumberFormat('#,##0.00').format(revenue)}', Icons.attach_money, Colors.green),
      _buildKPICard('Total Orders', NumberFormat('#,##0').format(orders), Icons.shopping_cart, Colors.blue),
      _buildKPICard('Total Users', NumberFormat('#,##0').format(users), Icons.people, Colors.purple),
      _buildKPICard('Avg Order Value', 'TSh ${avgOrder.toStringAsFixed(2)}', Icons.trending_up, Colors.orange),
    ];
  }

  Widget _buildKPICard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildSalesChart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 300,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(show: true),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 60,
                    getTitlesWidget: (value, meta) {
                      return Text('TSh ${(value / 1000).toStringAsFixed(0)}K');
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final date = DateTime.now().subtract(Duration(days: (29 - value.toInt())));
                      return Text(DateFormat('M/d').format(date));
                    },
                  ),
                ),
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: true),
              lineBarsData: [
                LineChartBarData(
                  spots: _salesData,
                  isCurved: true,
                  color: Theme.of(context).primaryColor,
                  barWidth: 3,
                  dotData: FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 300,
          child: PieChart(
            PieChartData(
              sections: _categoryData,
              centerSpaceRadius: 40,
              sectionsSpace: 2,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserGrowthChart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 300,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(show: true),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      return Text(value.toInt().toString());
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      return Text('Day ${value.toInt() + 1}');
                    },
                  ),
                ),
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: true),
              lineBarsData: [
                LineChartBarData(
                  spots: _userGrowthData,
                  isCurved: true,
                  color: Colors.green,
                  barWidth: 3,
                  dotData: FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: Colors.green.withOpacity(0.1),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSalesMetrics() {
    final todaySales = _analyticsData['todaySales']?.toDouble() ?? 0.0;
    final weekSales = _analyticsData['weekSales']?.toDouble() ?? 0.0;
    final monthSales = _analyticsData['monthSales']?.toDouble() ?? 0.0;

    return Row(
      children: [
        Expanded(child: _buildMetricCard('Today\'s Sales', 'TSh ${todaySales.toStringAsFixed(2)}', '', Colors.green)),
        const SizedBox(width: 16),
        Expanded(child: _buildMetricCard('This Week', 'TSh ${weekSales.toStringAsFixed(2)}', '', Colors.blue)),
        const SizedBox(width: 16),
        Expanded(child: _buildMetricCard('This Month', 'TSh ${monthSales.toStringAsFixed(2)}', '', Colors.purple)),
      ],
    );
  }

  Widget _buildUserMetrics() {
    final newUsers = _analyticsData['newUsers'] ?? 0;
    final activeUsers = _analyticsData['activeUsers'] ?? 0;
    final retentionRate = _analyticsData['retentionRate']?.toDouble() ?? 0.0;

    return Row(
      children: [
        Expanded(child: _buildMetricCard('New Users', '$newUsers', '', Colors.green)),
        const SizedBox(width: 16),
        Expanded(child: _buildMetricCard('Active Users', '$activeUsers', '', Colors.blue)),
        const SizedBox(width: 16),
        Expanded(child: _buildMetricCard('Retention Rate', '${retentionRate.toStringAsFixed(1)}%', '', Colors.orange)),
      ],
    );
  }

  Widget _buildProductMetrics() {
    final totalProducts = _analyticsData['totalProducts'] ?? 0;
    final outOfStock = _analyticsData['outOfStock'] ?? 0;
    final lowStock = _analyticsData['lowStock'] ?? 0;

    return Row(
      children: [
        Expanded(child: _buildMetricCard('Total Products', '$totalProducts', '', Colors.blue)),
        const SizedBox(width: 16),
        Expanded(child: _buildMetricCard('Out of Stock', '$outOfStock', '', Colors.red)),
        const SizedBox(width: 16),
        Expanded(child: _buildMetricCard('Low Stock', '$lowStock', '', Colors.orange)),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, String change, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              change,
              style: TextStyle(color: color, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopProductsList() {
    final products = _analyticsData['topProducts'] as List<Map<String, dynamic>>? ?? [];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Top Selling Products',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (products.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(
                  child: Text(
                    'No product sales data available',
                    style: TextStyle(
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              )
            else
              ...products.map((product) => ListTile(
                title: Text(product['name'] as String? ?? 'Unknown Product'),
                subtitle: Text('${product['quantity'] ?? 0} units sold'),
                trailing: Text(
                  'TSh ${NumberFormat('#,##0.00').format((product['totalSales'] as num?)?.toDouble() ?? 0.0)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              )),
          ],
        ),
      ),
    );
  }

  Widget _buildUserEngagementMetrics() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'User Engagement',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildEngagementRow('Daily Active Users', '1,234', '85%'),
            _buildEngagementRow('Weekly Active Users', '3,456', '78%'),
            _buildEngagementRow('Monthly Active Users', '8,901', '65%'),
            _buildEngagementRow('Average Session Duration', '12m 34s', '+5%'),
          ],
        ),
      ),
    );
  }

  Widget _buildEngagementRow(String metric, String value, String change) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(metric),
          Row(
            children: [
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              Text(change, style: TextStyle(color: Colors.green[600])),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

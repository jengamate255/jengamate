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
      
      setState(() {
        _analyticsData = {
          ...analytics,
          'topProducts': topProducts,
        };
        _salesData = _generateSalesData();
        _userGrowthData = _generateUserGrowthData();
        _categoryData = _generateCategoryData();
      });
      
      Logger.log('Analytics data loaded successfully');
    } catch (e) {
      Logger.logError('Error loading analytics data', e, StackTrace.current);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading analytics: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<FlSpot> _generateSalesData() {
    // Generate sample sales data for the last 30 days
    final now = DateTime.now();
    final data = <FlSpot>[];
    
    for (int i = 29; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final value = 1000 + (i * 50) + (i % 7 * 200); // Sample data with some variation
      data.add(FlSpot(i.toDouble(), value.toDouble()));
    }
    
    return data;
  }

  List<FlSpot> _generateUserGrowthData() {
    // Generate sample user growth data
    final data = <FlSpot>[];
    
    for (int i = 0; i < 30; i++) {
      final value = 100 + (i * 5) + (i % 3 * 10); // Sample growth data
      data.add(FlSpot(i.toDouble(), value.toDouble()));
    }
    
    return data;
  }

  List<PieChartSectionData> _generateCategoryData() {
    return [
      PieChartSectionData(
        color: Colors.blue,
        value: 35,
        title: 'Electronics\n35%',
        radius: 60,
        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
      ),
      PieChartSectionData(
        color: Colors.green,
        value: 25,
        title: 'Clothing\n25%',
        radius: 60,
        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
      ),
      PieChartSectionData(
        color: Colors.orange,
        value: 20,
        title: 'Home\n20%',
        radius: 60,
        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
      ),
      PieChartSectionData(
        color: Colors.red,
        value: 20,
        title: 'Other\n20%',
        radius: 60,
        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
      ),
    ];
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
    final totalRevenue = 125000.0;
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
      _buildKPICard('Total Revenue', '\$${NumberFormat('#,##0.00').format(revenue)}', Icons.attach_money, Colors.green),
      _buildKPICard('Total Orders', NumberFormat('#,##0').format(orders), Icons.shopping_cart, Colors.blue),
      _buildKPICard('Total Users', NumberFormat('#,##0').format(users), Icons.people, Colors.purple),
      _buildKPICard('Avg Order Value', '\$${avgOrder.toStringAsFixed(2)}', Icons.trending_up, Colors.orange),
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
                      return Text('\$${(value / 1000).toStringAsFixed(0)}K');
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
    return Row(
      children: [
        Expanded(child: _buildMetricCard('Today\'s Sales', '\$2,450', '+12%', Colors.green)),
        const SizedBox(width: 16),
        Expanded(child: _buildMetricCard('This Week', '\$18,200', '+8%', Colors.blue)),
        const SizedBox(width: 16),
        Expanded(child: _buildMetricCard('This Month', '\$75,600', '+15%', Colors.purple)),
      ],
    );
  }

  Widget _buildUserMetrics() {
    return Row(
      children: [
        Expanded(child: _buildMetricCard('New Users', '45', '+20%', Colors.green)),
        const SizedBox(width: 16),
        Expanded(child: _buildMetricCard('Active Users', '1,234', '+5%', Colors.blue)),
        const SizedBox(width: 16),
        Expanded(child: _buildMetricCard('Retention Rate', '78%', '+2%', Colors.orange)),
      ],
    );
  }

  Widget _buildProductMetrics() {
    return Row(
      children: [
        Expanded(child: _buildMetricCard('Total Products', '456', '+12', Colors.blue)),
        const SizedBox(width: 16),
        Expanded(child: _buildMetricCard('Out of Stock', '23', '-5', Colors.red)),
        const SizedBox(width: 16),
        Expanded(child: _buildMetricCard('Low Stock', '67', '+3', Colors.orange)),
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
    final products = [
      {'name': 'Wireless Headphones', 'sales': 245, 'revenue': 12250.0},
      {'name': 'Smart Watch', 'sales': 189, 'revenue': 37800.0},
      {'name': 'Laptop Stand', 'sales': 156, 'revenue': 4680.0},
      {'name': 'USB-C Cable', 'sales': 134, 'revenue': 2010.0},
      {'name': 'Phone Case', 'sales': 98, 'revenue': 1960.0},
    ];

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
            ...products.map((product) => ListTile(
              title: Text(product['name'] as String),
              subtitle: Text('${product['sales']} units sold'),
              trailing: Text(
                '\$${NumberFormat('#,##0.00').format(product['revenue'])}',
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

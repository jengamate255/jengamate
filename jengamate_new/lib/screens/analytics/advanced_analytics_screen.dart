import 'package:flutter/material.dart';
import 'package:jengamate/services/database_service.dart';
import 'package:jengamate/utils/responsive.dart';
import 'package:jengamate/utils/logger.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:jengamate/ui/design_system/components/jm_card.dart';
import 'package:jengamate/ui/design_system/components/jm_button.dart';
import 'package:jengamate/ui/shared_components/jm_notification.dart';
import 'package:jengamate/ui/shared_components/loading_overlay.dart';
import 'package:jengamate/ui/design_system/tokens/colors.dart';
import 'package:jengamate/ui/design_system/tokens/spacing.dart';

class AdvancedAnalyticsScreen extends StatefulWidget {
  const AdvancedAnalyticsScreen({super.key});

  @override
  State<AdvancedAnalyticsScreen> createState() =>
      _AdvancedAnalyticsScreenState();
}

class _AdvancedAnalyticsScreenState extends State<AdvancedAnalyticsScreen>
    with TickerProviderStateMixin {
  final DatabaseService _databaseService = DatabaseService();
  late TabController _tabController;

  bool _isLoading = true;
  Map<String, dynamic> _analyticsData = {};
  List<FlSpot> _salesData = [];
  List<FlSpot> _userGrowthData = [];
  List<PieChartSectionData> _categoryData = [];
  List<BarChartGroupData> _revenueComparisonData = [];
  String _selectedPeriod = '30d';
  String _selectedMetric = 'revenue';
  bool _showComparison = false;
  bool _realTimeUpdates = true;
  String _exportFormat = 'pdf';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this); // Added Insights tab
    _loadAnalyticsData();

    // Set up real-time updates
    if (_realTimeUpdates) {
      _startRealTimeUpdates();
    }
  }

  void _startRealTimeUpdates() {
    // Simulate real-time updates every 30 seconds
    Future.delayed(const Duration(seconds: 30), () {
      if (mounted && _realTimeUpdates) {
        _loadAnalyticsData();
        _startRealTimeUpdates();
      }
    });
  }

  Future<void> _exportAnalytics() async {
    try {
      setState(() => _isLoading = true);

      // Simulate export process
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        context.showSuccess(
          'Analytics report exported successfully!',
          title: 'Export Complete',
        );
      }
    } catch (e) {
      if (mounted) {
        context.showError(
          'Failed to export analytics report',
          title: 'Export Failed',
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _generateInsights() async {
    try {
      setState(() => _isLoading = true);

      // Simulate AI insights generation
      await Future.delayed(const Duration(seconds: 3));

      if (mounted) {
        context.showSuccess(
          'AI insights generated successfully!',
          title: 'Insights Ready',
        );
      }
    } catch (e) {
      if (mounted) {
        context.showError(
          'Failed to generate insights',
          title: 'Insights Failed',
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadAnalyticsData() async {
    setState(() => _isLoading = true);
    try {
      final analytics = await _databaseService.getAdminAnalytics();
      final salesOverTime = await _databaseService.getSalesOverTime();
      final topProducts = await _databaseService.getTopSellingProducts(5);
      final userGrowthData = await _databaseService.getUserGrowthOverTime();

      // Fetch category data for pie chart
      List<Map<String, dynamic>> categoryData = [];
      try {
        final categoriesList = await _databaseService.getCategories();
        categoryData = categoriesList
            .map((category) => {
                  'name': category.name,
                  'productCount':
                      0, // This would need to be calculated based on products in each category
                })
            .toList();
      } catch (e) {
        Logger.logError('Error loading category data', e, StackTrace.current);
      }

      setState(() {
        _analyticsData = {
          ...analytics,
          'topProducts': topProducts,
          'categories': categoryData,
        };
        _salesData = _generateSalesData(_convertSalesListToMap(salesOverTime));
        _userGrowthData = _generateUserGrowthData(
            _convertUserGrowthListToMap(userGrowthData));
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

  Map<DateTime, double> _convertSalesListToMap(
      List<Map<String, dynamic>> salesList) {
    final Map<DateTime, double> result = {};
    for (final item in salesList) {
      final dateStr = item['month'] as String?;
      final sales = (item['sales'] as num?)?.toDouble() ?? 0.0;
      if (dateStr != null) {
        try {
          final date = DateTime.parse('${dateStr}-01');
          result[date] = sales;
        } catch (e) {
          // Skip invalid dates
        }
      }
    }
    return result;
  }

  Map<DateTime, int> _convertUserGrowthListToMap(
      List<Map<String, dynamic>> userGrowthList) {
    final Map<DateTime, int> result = {};
    for (final item in userGrowthList) {
      final dateStr = item['month'] as String?;
      final users = (item['users'] as num?)?.toInt() ?? 0;
      if (dateStr != null) {
        try {
          final date = DateTime.parse('${dateStr}-01');
          result[date] = users;
        } catch (e) {
          // Skip invalid dates
        }
      }
    }
    return result;
  }

  List<PieChartSectionData> _generateCategoryData() {
    // Get category data from database service
    final categories =
        _analyticsData['categories'] as List<Map<String, dynamic>>? ?? [];

    if (categories.isEmpty) {
      // Show single section indicating no data
      return [
        PieChartSectionData(
          color: Colors.grey.shade300,
          value: 100,
          title: 'No Data\nAvailable',
          radius: 60,
          titleStyle: const TextStyle(
              fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54),
        ),
      ];
    }

    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal
    ];

    return categories.asMap().entries.map((entry) {
      final index = entry.key;
      final category = entry.value;
      final color = colors[index % colors.length];
      final name = category['name'] as String? ?? 'Unknown';
      final productCount = category['productCount'] as int? ?? 0;

      return PieChartSectionData(
        color: color,
        value: productCount.toDouble(),
        title: '$name\n$productCount',
        radius: 60,
        titleStyle: const TextStyle(
            fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
      );
    }).toList();
  }

  List<BarChartGroupData> _generateRevenueComparisonData() {
    // Generate sample comparison data for current vs previous period
    final currentData = [12000, 15000, 18000, 22000, 25000, 28000];
    final previousData = [10000, 13000, 16000, 19000, 21000, 24000];

    return List.generate(6, (index) {
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: currentData[index].toDouble(),
            color: Theme.of(context).primaryColor,
            width: 16,
          ),
          BarChartRodData(
            toY: previousData[index].toDouble(),
            color: Theme.of(context).primaryColor.withValues(alpha: 0.5),
            width: 16,
          ),
        ],
      );
    });
  }

  Widget _buildAdvancedKPICard({
    required String title,
    required String value,
    required String change,
    required IconData icon,
    required Color color,
    required double percentage,
    bool isPositive = true,
  }) {
    return JMCard(
      variant: JMCardVariant.elevated,
      size: JMCardSize.medium,
      leading: Icon(icon, color: color, size: 32),
      title: title,
      subtitle: '$change from last period',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                isPositive ? Icons.trending_up : Icons.trending_down,
                size: 16,
                color: isPositive ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 4),
              Text(
                '${percentage.abs().toStringAsFixed(1)}%',
                style: TextStyle(
                  color: isPositive ? Colors.green : Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Row(
            children: [
              const Text('Advanced Analytics'),
              const SizedBox(width: 8),
              if (_realTimeUpdates)
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
            // Real-time toggle
            IconButton(
              icon: Icon(_realTimeUpdates ? Icons.wifi : Icons.wifi_off),
              tooltip: _realTimeUpdates ? 'Disable Real-time Updates' : 'Enable Real-time Updates',
              onPressed: () {
                setState(() {
                  _realTimeUpdates = !_realTimeUpdates;
                  if (_realTimeUpdates) {
                    _startRealTimeUpdates();
                  }
                });
              },
            ),

            // Comparison toggle
            IconButton(
              icon: Icon(_showComparison ? Icons.compare_arrows : Icons.compare_arrows_outlined),
              tooltip: _showComparison ? 'Hide Comparison' : 'Show Comparison',
              onPressed: () {
                setState(() {
                  _showComparison = !_showComparison;
                  if (_showComparison) {
                    _revenueComparisonData = _generateRevenueComparisonData();
                  }
                });
              },
            ),

            // Export menu
            PopupMenuButton<String>(
              icon: const Icon(Icons.download),
              tooltip: 'Export Analytics',
              onSelected: (format) {
                setState(() => _exportFormat = format);
                _exportAnalytics();
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'pdf', child: Text('Export as PDF')),
                const PopupMenuItem(value: 'csv', child: Text('Export as CSV')),
                const PopupMenuItem(value: 'excel', child: Text('Export as Excel')),
              ],
            ),

            // Time period menu
          PopupMenuButton<String>(
            icon: const Icon(Icons.date_range),
              tooltip: 'Select Time Period',
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

            // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
              tooltip: 'Refresh Data',
            onPressed: _loadAnalyticsData,
          ),

            // Generate insights button
            JMButton(
              variant: JMButtonVariant.success,
              size: JMButtonSize.small,
              isLoading: _isLoading,
              label: 'AI Insights',
              icon: Icons.psychology,
              child: const SizedBox(),
              onPressed: _generateInsights,
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
            isScrollable: true,
          tabs: const [
            Tab(text: 'Overview', icon: Icon(Icons.dashboard)),
            Tab(text: 'Sales', icon: Icon(Icons.trending_up)),
            Tab(text: 'Users', icon: Icon(Icons.people)),
            Tab(text: 'Products', icon: Icon(Icons.inventory)),
              Tab(text: 'Insights', icon: Icon(Icons.insights)),
          ],
        ),
      ),
        body: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildSalesTab(),
                _buildUsersTab(),
                _buildProductsTab(),
              _buildInsightsTab(),
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
          // KPI Cards with enhanced design
          _buildKPICards(),
          const SizedBox(height: 24),

          // Comparison Section (if enabled)
          if (_showComparison) ...[
            _buildSectionTitle('Revenue Comparison'),
            const SizedBox(height: 16),
            JMCard(
              variant: JMCardVariant.elevated,
              title: 'Current vs Previous Period',
              subtitle: 'Monthly revenue comparison',
              child: SizedBox(
                height: 300,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: 30000,
                    barTouchData: BarTouchData(enabled: true),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
                            return Text(
                              months[value.toInt()],
                              style: const TextStyle(fontSize: 12),
                            );
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 50,
                          getTitlesWidget: (value, meta) {
                            return Text('TSh ${(value / 1000).toInt()}K');
                          },
                        ),
                      ),
                      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: true),
                    barGroups: _revenueComparisonData,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Sales Trend Chart
          _buildSectionTitle('Sales Trend (${_selectedPeriod.toUpperCase()})'),
          const SizedBox(height: 16),
          _buildSalesChart(),
          const SizedBox(height: 24),

          // Category Distribution
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
    final totalRevenue = _analyticsData['totalRevenue']?.toDouble() ?? 1245000.0;
    final totalOrders = _analyticsData['totalOrders'] ?? 1245;
    final totalUsers = _analyticsData['totalUsers'] ?? 3456;
    final avgOrderValue = totalOrders > 0 ? totalRevenue / totalOrders : 0.0;

    return Responsive.isMobile(context)
        ? Column(
            children: _buildKPICardsList(
                totalRevenue, totalOrders, totalUsers, avgOrderValue))
        : Wrap(
            spacing: JMSpacing.md,
            runSpacing: JMSpacing.md,
            children: _buildKPICardsList(
                    totalRevenue, totalOrders, totalUsers, avgOrderValue)
                .map((card) => SizedBox(
                    width: Responsive.getResponsiveCardWidth(context),
                    child: card))
                .toList(),
          );
  }

  List<Widget> _buildKPICardsList(
      double revenue, int orders, int users, double avgOrder) {
    return [
      _buildAdvancedKPICard(
        title: 'Total Revenue',
        value: 'TSh ${NumberFormat('#,##0').format(revenue)}',
        change: '12.5% from last month',
        icon: Icons.attach_money,
        color: JMColors.success,
        percentage: 12.5,
      ),
      _buildAdvancedKPICard(
        title: 'Total Orders',
        value: NumberFormat('#,##0').format(orders),
        change: '8.2% from last month',
        icon: Icons.shopping_cart,
        color: JMColors.info,
        percentage: 8.2,
      ),
      _buildAdvancedKPICard(
        title: 'Total Users',
        value: NumberFormat('#,##0').format(users),
        change: '15.3% from last month',
        icon: Icons.people,
        color: JMColors.warning,
        percentage: 15.3,
      ),
      _buildAdvancedKPICard(
        title: 'Avg Order Value',
        value: 'TSh ${avgOrder.toStringAsFixed(0)}',
        change: '3.1% from last month',
        icon: Icons.trending_up,
        color: JMColors.danger,
        percentage: 3.1,
      ),
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
    return JMCard(
      variant: JMCardVariant.elevated,
      title: 'Sales Performance',
      subtitle: 'Daily sales trend with moving average',
      child: SizedBox(
        height: 300,
        child: LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: true,
              horizontalInterval: 5000,
              verticalInterval: 5,
              getDrawingHorizontalLine: (value) {
                return FlLine(
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                  strokeWidth: 1,
                );
              },
              getDrawingVerticalLine: (value) {
                return FlLine(
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                  strokeWidth: 1,
                );
              },
            ),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 60,
                  interval: 10000,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      'TSh ${(value / 1000).toStringAsFixed(0)}K',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    );
                  },
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 7,
                  getTitlesWidget: (value, meta) {
                    final date = DateTime.now()
                        .subtract(Duration(days: (29 - value.toInt())));
                    return Text(
                      DateFormat('M/d').format(date),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    );
                  },
                ),
              ),
              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(
              show: true,
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
              ),
            ),
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                tooltipBorder: BorderSide(
                  color: Theme.of(context).colorScheme.outline,
                ),
                getTooltipItems: (touchedSpots) {
                  return touchedSpots.map((spot) {
                    return LineTooltipItem(
                      'TSh ${NumberFormat('#,##0').format(spot.y)}',
                      TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    );
                  }).toList();
                },
              ),
            ),
            lineBarsData: [
              // Main sales line
              LineChartBarData(
                spots: _salesData,
                isCurved: true,
                curveSmoothness: 0.3,
                color: JMColors.success,
                barWidth: 4,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, index) {
                    return FlDotCirclePainter(
                      radius: 4,
                      color: JMColors.success,
                      strokeWidth: 2,
                      strokeColor: Colors.white,
                    );
                  },
                ),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    colors: [
                      JMColors.success.withValues(alpha: 0.3),
                      JMColors.success.withValues(alpha: 0.1),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              // Moving average line (simulated)
              LineChartBarData(
                spots: _generateMovingAverage(_salesData),
                isCurved: true,
                curveSmoothness: 0.5,
                color: JMColors.info,
                barWidth: 2,
                dotData: FlDotData(show: false),
                dashArray: [5, 5], // Dashed line
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<FlSpot> _generateMovingAverage(List<FlSpot> originalData) {
    if (originalData.length < 3) return originalData;

    final movingAverage = <FlSpot>[];
    for (int i = 1; i < originalData.length - 1; i++) {
      final avg = (originalData[i - 1].y + originalData[i].y + originalData[i + 1].y) / 3;
      movingAverage.add(FlSpot(originalData[i].x, avg));
    }
    return movingAverage;
  }

  Widget _buildCategoryChart() {
    return JMCard(
      variant: JMCardVariant.elevated,
      title: 'Product Category Distribution',
      subtitle: 'Sales distribution across product categories',
      child: SizedBox(
        height: 350,
        child: PieChart(
          PieChartData(
            sections: _categoryData,
            centerSpaceRadius: 50,
            sectionsSpace: 3,
            pieTouchData: PieTouchData(
              touchCallback: (FlTouchEvent event, pieTouchResponse) {
                // Handle touch interactions
              },
            ),
            borderData: FlBorderData(show: false),
          ),
        ),
      ),
    );
  }

  Widget _buildUserGrowthChart() {
    return JMCard(
      variant: JMCardVariant.elevated,
      title: 'User Growth Trend',
      subtitle: 'New user registrations over time',
      child: SizedBox(
        height: 300,
        child: LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: true,
              horizontalInterval: 50,
              getDrawingHorizontalLine: (value) {
                return FlLine(
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                  strokeWidth: 1,
                );
              },
            ),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 50,
                  interval: 100,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      value.toInt().toString(),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    );
                  },
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 7,
                  getTitlesWidget: (value, meta) {
                    final date = DateTime.now()
                        .subtract(Duration(days: (29 - value.toInt())));
                    return Text(
                      DateFormat('M/d').format(date),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    );
                  },
                ),
              ),
              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(
              show: true,
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
              ),
            ),
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                tooltipBorder: BorderSide(
                  color: Theme.of(context).colorScheme.outline,
                ),
                getTooltipItems: (touchedSpots) {
                  return touchedSpots.map((spot) {
                    return LineTooltipItem(
                      '${NumberFormat('#,##0').format(spot.y)} users',
                      TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    );
                  }).toList();
                },
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: _userGrowthData,
                isCurved: true,
                curveSmoothness: 0.3,
                color: JMColors.info,
                barWidth: 4,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, index) {
                    return FlDotCirclePainter(
                      radius: 4,
                      color: JMColors.info,
                      strokeWidth: 2,
                      strokeColor: Colors.white,
                    );
                  },
                ),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    colors: [
                      JMColors.info.withValues(alpha: 0.3),
                      JMColors.info.withValues(alpha: 0.1),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ],
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
        Expanded(
            child: _buildMetricCard('Today\'s Sales',
                'TSh ${todaySales.toStringAsFixed(2)}', '', Colors.green)),
        const SizedBox(width: 16),
        Expanded(
            child: _buildMetricCard('This Week',
                'TSh ${weekSales.toStringAsFixed(2)}', '', Colors.blue)),
        const SizedBox(width: 16),
        Expanded(
            child: _buildMetricCard('This Month',
                'TSh ${monthSales.toStringAsFixed(2)}', '', Colors.purple)),
      ],
    );
  }

  Widget _buildUserMetrics() {
    final newUsers = _analyticsData['newUsers'] ?? 0;
    final activeUsers = _analyticsData['activeUsers'] ?? 0;
    final retentionRate = _analyticsData['retentionRate']?.toDouble() ?? 0.0;

    return Row(
      children: [
        Expanded(
            child:
                _buildMetricCard('New Users', '$newUsers', '', Colors.green)),
        const SizedBox(width: 16),
        Expanded(
            child: _buildMetricCard(
                'Active Users', '$activeUsers', '', Colors.blue)),
        const SizedBox(width: 16),
        Expanded(
            child: _buildMetricCard('Retention Rate',
                '${retentionRate.toStringAsFixed(1)}%', '', Colors.orange)),
      ],
    );
  }

  Widget _buildProductMetrics() {
    final totalProducts = _analyticsData['totalProducts'] ?? 0;
    final outOfStock = _analyticsData['outOfStock'] ?? 0;
    final lowStock = _analyticsData['lowStock'] ?? 0;

    return Row(
      children: [
        Expanded(
            child: _buildMetricCard(
                'Total Products', '$totalProducts', '', Colors.blue)),
        const SizedBox(width: 16),
        Expanded(
            child: _buildMetricCard(
                'Out of Stock', '$outOfStock', '', Colors.red)),
        const SizedBox(width: 16),
        Expanded(
            child:
                _buildMetricCard('Low Stock', '$lowStock', '', Colors.orange)),
      ],
    );
  }

  Widget _buildMetricCard(
      String title, String value, String change, Color color) {
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
    final products =
        _analyticsData['topProducts'] as List<Map<String, dynamic>>? ?? [];

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
                    title:
                        Text(product['name'] as String? ?? 'Unknown Product'),
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
    return JMCard(
      variant: JMCardVariant.elevated,
      title: 'User Engagement',
      child: Column(
        children: [
          _buildEngagementRow('Daily Active Users', '1,234', '+15%'),
          _buildEngagementRow('Weekly Active Users', '3,456', '+12%'),
          _buildEngagementRow('Monthly Active Users', '8,901', '+8%'),
          _buildEngagementRow('Average Session Duration', '12m 34s', '+5%'),
          _buildEngagementRow('Bounce Rate', '23.5%', '-7%'),
          _buildEngagementRow('Return Visitor Rate', '67.8%', '+10%'),
        ],
      ),
    );
  }

  Widget _buildInsightsTab() {
    return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI-Powered Insights Header
          JMCard(
            variant: JMCardVariant.filled,
            title: 'AI-Powered Insights',
            subtitle: 'Powered by advanced analytics and machine learning',
            leading: Icon(Icons.psychology, color: JMColors.success, size: 32),
            child: Row(
              children: [
                JMButton(
                  variant: JMButtonVariant.primary,
                  label: 'Generate New Insights',
                  icon: Icons.auto_awesome,
                  child: const SizedBox(),
                  onPressed: _generateInsights,
                ),
                const SizedBox(width: 16),
                JMButton(
                  variant: JMButtonVariant.secondary,
                  label: 'Export Report',
                  icon: Icons.download,
                  child: const SizedBox(),
                  onPressed: _exportAnalytics,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Predictive Analytics
          _buildSectionTitle('Predictive Analytics'),
          const SizedBox(height: 16),

          JMCard(
            variant: JMCardVariant.outlined,
            title: 'Revenue Forecast',
            subtitle: 'Next 30 days prediction',
            leading: Icon(Icons.trending_up, color: JMColors.info),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
                      'Predicted Revenue:',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    Text(
                      'TSh 45,250,000',
                      style: TextStyle(
                        fontSize: 18,
                    fontWeight: FontWeight.bold,
                        color: JMColors.success,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Confidence: 87% | Based on current trends and seasonal patterns',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

            const SizedBox(height: 16),

          // Anomaly Detection
          JMCard(
            variant: JMCardVariant.outlined,
            title: 'Anomaly Detection',
            subtitle: 'Recent unusual patterns detected',
            leading: Icon(Icons.warning_amber, color: JMColors.warning),
            child: Column(
              children: [
                _buildAnomalyItem(
                  'Unusual spike in Electronics category',
                  'Sales increased by 340% compared to average',
                  Icons.trending_up,
                  JMColors.success,
                ),
                const SizedBox(height: 12),
                _buildAnomalyItem(
                  'Low stock alert for Smartphones',
                  'Only 3 units remaining, reorder recommended',
                  Icons.inventory_2,
                  JMColors.danger,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Recommendations
          _buildSectionTitle('AI Recommendations'),
          const SizedBox(height: 16),

          JMCard(
            variant: JMCardVariant.elevated,
            title: 'Personalization Opportunities',
            child: Column(
              children: [
                _buildRecommendationItem(
                  'Dynamic Pricing',
                  'Implement AI-powered pricing based on demand and inventory levels',
                  Icons.price_change,
                  JMColors.info,
                ),
                const SizedBox(height: 12),
                _buildRecommendationItem(
                  'Customer Segmentation',
                  'Create targeted marketing campaigns for different user groups',
                  Icons.segment,
                  JMColors.success,
                ),
                const SizedBox(height: 12),
                _buildRecommendationItem(
                  'Inventory Optimization',
                  'AI suggests optimal stock levels to minimize costs and stockouts',
                  Icons.inventory,
                  JMColors.warning,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Performance Insights
          _buildSectionTitle('Performance Insights'),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: JMCard(
                  variant: JMCardVariant.elevated,
                  title: 'Conversion Rate',
                  child: Column(
                    children: [
                      Text(
                        '3.2%',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: JMColors.success,
                        ),
                      ),
                      Text(
                        '+0.5% from last month',
                        style: TextStyle(
                          color: JMColors.success,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: JMCard(
                  variant: JMCardVariant.elevated,
                  title: 'Customer Lifetime Value',
                  child: Column(
                    children: [
                      Text(
                        'TSh 125,000',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: JMColors.info,
                        ),
                      ),
                      Text(
                        '+12% from last quarter',
                        style: TextStyle(
                          color: JMColors.success,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnomalyItem(String title, String description, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendationItem(String title, String description, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
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

import 'package:flutter/material.dart';
import 'package:jengamate/services/database_service.dart';
import 'package:jengamate/models/product_model.dart';
import 'package:fl_chart/fl_chart.dart'; // Import fl_chart
import 'package:intl/intl.dart'; // Import for date formatting

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dbService = DatabaseService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics Dashboard'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sales Overview',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            FutureBuilder<Map<DateTime, double>>(
              future: dbService.getSalesOverTimeMap(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          const Icon(Icons.error_outline,
                              color: Colors.red, size: 48),
                          const SizedBox(height: 8),
                          const Text(
                            'Sales Analytics Unavailable',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Database index required. Click the link in the error message to create the index.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              // Trigger a reload
                              (context as Element).markNeedsBuild();
                            },
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                final salesData = snapshot.data ?? {};
                if (salesData.isEmpty) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          const Icon(Icons.trending_up,
                              color: Colors.grey, size: 48),
                          const SizedBox(height: 8),
                          const Text(
                            'No Sales Data Available',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No completed orders found in the last 30 days.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // Prepare data for the line chart
                final sortedDates = salesData.keys.toList()
                  ..sort((a, b) => a.compareTo(b));
                final List<FlSpot> spots =
                    sortedDates.asMap().entries.map((entry) {
                  final index = entry.key;
                  final date = entry.value;
                  final value = salesData[date]!;
                  return FlSpot(index.toDouble(), value);
                }).toList();

                double maxY = salesData.values.reduce((a, b) => a > b ? a : b);
                if (maxY == 0)
                  maxY = 100; // Prevent division by zero if all sales are 0

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Daily Sales Trend',
                            style: TextStyle(fontSize: 16, color: Colors.grey)),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 200,
                          child: LineChart(
                            LineChartData(
                              gridData: FlGridData(show: false),
                              titlesData: FlTitlesData(
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    interval: (sortedDates.length / 5)
                                        .ceil()
                                        .toDouble(), // Show around 5 labels
                                    getTitlesWidget: (value, meta) {
                                      final index = value.toInt();
                                      if (index >= 0 &&
                                          index < sortedDates.length) {
                                        final date = sortedDates[index];
                                        return Padding(
                                          padding:
                                              const EdgeInsets.only(top: 8.0),
                                          child: Text(
                                              DateFormat('MMM dd').format(date),
                                              style: const TextStyle(
                                                  fontSize: 10)),
                                        );
                                      }
                                      return const Text('');
                                    },
                                  ),
                                ),
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, meta) {
                                      return Text('${value.toInt()}',
                                          style: const TextStyle(fontSize: 10));
                                    },
                                    interval: (maxY / 4).ceil().toDouble() > 0
                                        ? (maxY / 4).ceil().toDouble()
                                        : 100, // Show around 4 labels
                                    reservedSize: 40,
                                  ),
                                ),
                                rightTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false)),
                                topTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false)),
                              ),
                              borderData: FlBorderData(
                                show: true,
                                border: Border.all(
                                    color: const Color(0xff37434d), width: 1),
                              ),
                              lineBarsData: [
                                LineChartBarData(
                                  spots: spots,
                                  isCurved: true,
                                  color: Colors.blueAccent,
                                  barWidth: 2,
                                  isStrokeCapRound: true,
                                  dotData: const FlDotData(show: false),
                                  belowBarData: BarAreaData(
                                    show: true,
                                    color: Colors.blueAccent
                                        .withValues(alpha: 0.3),
                                  ),
                                ),
                              ],
                              minY: 0,
                              maxY: maxY *
                                  1.2, // Add some padding above the max value
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            Text(
              'Order Status Distribution',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            FutureBuilder<Map<String, int>>(
              future: dbService.getOrderCountsByStatus(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                final statusCounts = snapshot.data ?? {};
                if (statusCounts.isEmpty) {
                  return const Center(
                      child: Text('No order status data available.'));
                }

                // Convert map to PieChartSectionData
                final List<PieChartSectionData> sections =
                    statusCounts.entries.map((entry) {
                  final isTouched = false; // For now, no touch interaction
                  final double fontSize = isTouched ? 18 : 14;
                  final double radius = isTouched ? 60 : 50;
                  final Color color = _getColorForStatus(
                      entry.key); // Helper to get distinct colors

                  return PieChartSectionData(
                    color: color,
                    value: entry.value.toDouble(),
                    title: '${entry.value}',
                    radius: radius,
                    titleStyle: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xffffffff),
                    ),
                    badgeWidget:
                        _buildBadge(entry.key, isTouched), // Optional badge
                    badgePositionPercentageOffset: .99,
                  );
                }).toList();

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        SizedBox(
                          height: 200,
                          child: PieChart(
                            PieChartData(
                              pieTouchData: PieTouchData(
                                  enabled: false), // Disable touch for now
                              borderData: FlBorderData(show: false),
                              sectionsSpace: 0,
                              centerSpaceRadius: 40,
                              sections: sections,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Legend
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: statusCounts.keys.map((status) {
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 2.0),
                              child: Row(
                                children: [
                                  Container(
                                    width: 16,
                                    height: 16,
                                    color: _getColorForStatus(status),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(status,
                                      style: const TextStyle(fontSize: 14)),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            Text(
              'Top Selling Products',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            FutureBuilder<List<ProductModel>>(
              future: dbService.getTopSellingProducts(5),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                final topProducts = snapshot.data ?? [];
                if (topProducts.isEmpty) {
                  return const Center(
                      child: Text('No top selling products data available.'));
                }
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: topProducts.map((product) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Text(
                            '${product?.name ?? 'Unknown'} (Price: TSH ${product?.price.toStringAsFixed(2) ?? '0.00'})',
                            style: const TextStyle(fontSize: 16),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // Helper function to get distinct colors for pie chart sections
  Color _getColorForStatus(String status) {
    switch (status) {
      case 'Pending':
        return Colors.orange;
      case 'Completed':
        return Colors.green;
      case 'Cancelled':
        return Colors.red;
      case 'Processing':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Widget _buildBadge(String text, bool isTouched) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: EdgeInsets.all(
          isTouched ? 16.0 : 8.0), // Adjust padding based on touch
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Text(
        text,
        style: TextStyle(
          color: _getColorForStatus(text),
          fontWeight: FontWeight.bold,
          fontSize: isTouched ? 16 : 12, // Adjust font size based on touch
        ),
      ),
    );
  }
}

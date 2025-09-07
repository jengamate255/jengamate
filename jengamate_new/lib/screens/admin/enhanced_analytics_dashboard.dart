import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jengamate/services/database_service.dart';
import 'package:jengamate/models/user_model.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:collection/collection.dart';
import 'package:jengamate/ui/design_system/components/jm_card.dart';
import 'package:jengamate/ui/design_system/components/jm_skeleton.dart';
import 'package:jengamate/ui/design_system/layout/adaptive_padding.dart';
import 'package:jengamate/ui/design_system/tokens/spacing.dart';

enum TimeRange { last7Days, last30Days, last90Days, lastYear }

class EnhancedAnalyticsDashboard extends StatefulWidget {
  const EnhancedAnalyticsDashboard({super.key});

  @override
  State<EnhancedAnalyticsDashboard> createState() =>
      _EnhancedAnalyticsDashboardState();
}

class _EnhancedAnalyticsDashboardState
    extends State<EnhancedAnalyticsDashboard> {
  final DatabaseService _databaseService = DatabaseService();
  Map<String, dynamic> _analyticsData = {};
  bool _isLoading = true;
  TimeRange _selectedTimeRange = TimeRange.last30Days;
  List<Map<String, dynamic>> _userGrowthData = [];
  bool _showUserGrowthChart = true;

  @override
  void initState() {
    super.initState();
    _loadAnalyticsData();
  }

  Future<void> _loadAnalyticsData() async {
    try {
      final analytics = await _databaseService.getAdminAnalytics();
      final withdrawalStats = await _databaseService.getWithdrawalStats();

      if (mounted) {
        setState(() {
          _analyticsData = {
            ...analytics,
            'withdrawalStats': withdrawalStats,
          };
        });
      }

      await _loadUserGrowthData();

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading analytics: $e')),
      );
    }
  }

  Widget _buildMetricCard(
      String title, dynamic value, IconData icon, Color color) {
    return JMCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 30),
              const SizedBox(width: JMSpacing.sm),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: JMSpacing.sm),
          Text(
            value.toString(),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWithdrawalStats() {
    final withdrawalStats = _analyticsData['withdrawalStats'] ?? {};

    return JMCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Withdrawal Statistics',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: JMSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                  'Pending', withdrawalStats['pending'] ?? 0, Colors.orange),
              _buildStatItem(
                  'Approved', withdrawalStats['approved'] ?? 0, Colors.blue),
              _buildStatItem(
                  'Rejected', withdrawalStats['rejected'] ?? 0, Colors.red),
              _buildStatItem(
                  'Completed', withdrawalStats['completed'] ?? 0, Colors.green),
            ],
          ),
          const SizedBox(height: JMSpacing.lg),
          Text(
            'Total Processed: TSh ${NumberFormat('#,##0').format(withdrawalStats['totalAmount'] ?? 0)}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, int value, Color color) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Future<void> _loadUserGrowthData() async {
    try {
      final now = DateTime.now();
      DateTime startDate;

      switch (_selectedTimeRange) {
        case TimeRange.last7Days:
          startDate = now.subtract(const Duration(days: 7));
          break;
        case TimeRange.last30Days:
          startDate = now.subtract(const Duration(days: 30));
          break;
        case TimeRange.last90Days:
          startDate = now.subtract(const Duration(days: 90));
          break;
        case TimeRange.lastYear:
          startDate = DateTime(now.year - 1, now.month, now.day);
          break;
      }

      final users = await _databaseService.getUsersCreatedAfter(startDate);

      // Filter out users without createdAt and group by date
      final filteredUsers = users.where((u) => u.createdAt != null).toList();
      final groupedUsers = groupBy<UserModel, String>(
        filteredUsers,
        (user) {
          final c = user.createdAt!;
          return '${c.year}-${c.month.toString().padLeft(2, '0')}-${c.day.toString().padLeft(2, '0')}';
        },
      );

      // Create a map with all dates in the range
      final dateMap = <String, int>{};
      for (var i = 0; i <= now.difference(startDate).inDays; i++) {
        final date = startDate.add(Duration(days: i));
        final dateKey =
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        dateMap[dateKey] = 0;
      }

      // Fill in the actual user counts
      groupedUsers.forEach((date, users) {
        dateMap[date] = users.length;
      });

      // Convert to list and sort by date
      final growthData = dateMap.entries
          .map((e) => {
                'date': DateTime.parse(e.key),
                'count': e.value,
                'cumulative': 0, // Will be calculated next
              })
          .toList()
        ..sort(
            (a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));

      // Calculate cumulative values
      int runningTotal = 0;
      for (var i = 0; i < growthData.length; i++) {
        runningTotal += growthData[i]['count'] as int;
        growthData[i]['cumulative'] = runningTotal;
      }

      if (mounted) {
        setState(() {
          _userGrowthData = growthData;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading user growth data: $e')),
        );
      }
    }
  }

  Widget _buildTimeRangeSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: SegmentedButton<TimeRange>(
        segments: const [
          ButtonSegment<TimeRange>(
            value: TimeRange.last7Days,
            label: Text('7d'),
          ),
          ButtonSegment<TimeRange>(
            value: TimeRange.last30Days,
            label: Text('30d'),
          ),
          ButtonSegment<TimeRange>(
            value: TimeRange.last90Days,
            label: Text('90d'),
          ),
          ButtonSegment<TimeRange>(
            value: TimeRange.lastYear,
            label: Text('1y'),
          ),
        ],
        selected: {_selectedTimeRange},
        onSelectionChanged: (Set<TimeRange> selection) {
          setState(() {
            _selectedTimeRange = selection.first;
            _loadUserGrowthData();
          });
        },
      ),
    );
  }

  Widget _buildUserGrowthChart() {
    if (_userGrowthData.isEmpty) {
      return const Center(child: Text('No user growth data available'));
    }

    return JMCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'User Growth',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: Icon(_showUserGrowthChart
                    ? Icons.visibility_off
                    : Icons.visibility),
                onPressed: () {
                  setState(() {
                    _showUserGrowthChart = !_showUserGrowthChart;
                  });
                },
              ),
            ],
          ),
          _buildTimeRangeSelector(),
          if (_showUserGrowthChart) ...[
            const SizedBox(height: JMSpacing.lg),
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.4,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() % 5 != 0) return const SizedBox();
                          final date = _userGrowthData[value.toInt()]['date']
                              as DateTime;
                          return Text(DateFormat('MMM d').format(date));
                        },
                        reservedSize: 30,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text(value.toInt().toString());
                        },
                        reservedSize: 40,
                      ),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _userGrowthData.asMap().entries.map((entry) {
                        return FlSpot(
                          entry.key.toDouble(),
                          (entry.value['cumulative'] as int).toDouble(),
                        );
                      }).toList(),
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.blue.withValues(alpha: 0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                'Total Users: ${_userGrowthData.last['cumulative']}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOrderStatusChart() {
    return JMCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Order Status Distribution',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: JMSpacing.lg),
          SizedBox(
            height: 200,
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance.collection('orders').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final orders = snapshot.data!.docs;
                final statusCounts = <String, int>{};

                for (var order in orders) {
                  final data = order.data() as Map<String, dynamic>;
                  final status = data['status'] ?? 'Unknown';
                  statusCounts[status] = (statusCounts[status] ?? 0) + 1;
                }

                return PieChart(
                  PieChartData(
                    sections: statusCounts.entries.map((entry) {
                      return PieChartSectionData(
                        color: _getStatusColor(entry.key),
                        value: entry.value.toDouble(),
                        title: '${entry.key}\n${entry.value}',
                        radius: 50,
                      );
                    }).toList(),
                    sectionsSpace: 2,
                    centerSpaceRadius: 40,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'processing':
        return Colors.blue;
      case 'shipped':
        return Colors.purple;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildRecentActivity() {
    return JMCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent Activity',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: JMSpacing.lg),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .orderBy('lastLoginAt', descending: true)
                .limit(5)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final users = snapshot.data!.docs;

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index].data() as Map<String, dynamic>;
                  final lastLogin = user['lastLoginAt'] as Timestamp?;

                  return ListTile(
                    leading: CircleAvatar(
                      child: Text(
                          user['name']?.substring(0, 1).toUpperCase() ?? '?'),
                    ),
                    title: Text(user['name'] ?? 'Unknown'),
                    subtitle: Text(
                      lastLogin != null
                          ? 'Last login: ${DateFormat('MMM dd, HH:mm').format(lastLogin.toDate())}'
                          : 'Never logged in',
                    ),
                    trailing: Icon(
                      user['isOnline'] == true
                          ? Icons.circle
                          : Icons.circle_outlined,
                      color:
                          user['isOnline'] == true ? Colors.green : Colors.grey,
                      size: 12,
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 800;

    return _isLoading
        ? _buildLoadingSkeleton(isWideScreen)
        : RefreshIndicator(
            onRefresh: _loadAnalyticsData,
            child: SingleChildScrollView(
              child: AdaptivePadding(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Platform Overview',
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: JMSpacing.lg),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final crossAxisCount = isWideScreen
                            ? (constraints.maxWidth > 1200 ? 4 : 2)
                            : 2;

                        return GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing:
                              isWideScreen ? JMSpacing.xl : JMSpacing.lg,
                          mainAxisSpacing:
                              isWideScreen ? JMSpacing.xl : JMSpacing.lg,
                          childAspectRatio: isWideScreen ? 1.5 : 1.2,
                          children: [
                            _buildMetricCard(
                              'Total Users',
                              _analyticsData['totalUsers'] ?? 0,
                              Icons.people,
                              Colors.blue,
                            ),
                            _buildMetricCard(
                              'Total Orders',
                              _analyticsData['totalOrders'] ?? 0,
                              Icons.shopping_cart,
                              Colors.green,
                            ),
                            _buildMetricCard(
                              'Total Products',
                              _analyticsData['totalProducts'] ?? 0,
                              Icons.inventory,
                              Colors.orange,
                            ),
                            _buildMetricCard(
                              'Total Inquiries',
                              _analyticsData['totalInquiries'] ?? 0,
                              Icons.question_answer,
                              Colors.purple,
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: JMSpacing.xl),
                    if (isWideScreen) ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: Column(
                              children: [
                                _buildWithdrawalStats(),
                                const SizedBox(height: JMSpacing.xl),
                                _buildUserGrowthChart(),
                              ],
                            ),
                          ),
                          const SizedBox(width: JMSpacing.xl),
                          Expanded(
                            flex: 1,
                            child: _buildRecentActivity(),
                          ),
                        ],
                      ),
                    ] else ...[
                      _buildWithdrawalStats(),
                      const SizedBox(height: JMSpacing.xl),
                      _buildUserGrowthChart(),
                      const SizedBox(height: JMSpacing.xl),
                      _buildOrderStatusChart(),
                      const SizedBox(height: JMSpacing.xl),
                      _buildRecentActivity(),
                      // Add bottom padding to prevent overflow
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 0.05),
                    ],
                  ],
                ),
              ),
            ),
          );
  }

  Widget _buildLoadingSkeleton(bool isWideScreen) {
    return SingleChildScrollView(
      child: AdaptivePadding(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const JMSkeleton(height: 28, width: 220),
            const SizedBox(height: JMSpacing.lg),
            LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount =
                    isWideScreen ? (constraints.maxWidth > 1200 ? 4 : 2) : 2;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 4,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing:
                        isWideScreen ? JMSpacing.xl : JMSpacing.lg,
                    mainAxisSpacing: isWideScreen ? JMSpacing.xl : JMSpacing.lg,
                    childAspectRatio: isWideScreen ? 1.5 : 1.2,
                  ),
                  itemBuilder: (_, __) => const JMCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        JMSkeleton(height: 20, width: 120),
                        SizedBox(height: JMSpacing.sm),
                        JMSkeleton(height: 28, width: 80),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: JMSpacing.xl),
            if (isWideScreen) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        JMCard(child: JMSkeleton(height: 140)),
                        SizedBox(height: JMSpacing.xl),
                        JMCard(child: JMSkeleton(height: 320)),
                      ],
                    ),
                  ),
                  SizedBox(width: JMSpacing.xl),
                  Expanded(
                    flex: 1,
                    child: JMCard(child: JMSkeleton(height: 320)),
                  ),
                ],
              ),
            ] else ...[
              const JMCard(child: JMSkeleton(height: 140)),
              const SizedBox(height: JMSpacing.xl),
              const JMCard(child: JMSkeleton(height: 320)),
              const SizedBox(height: JMSpacing.xl),
              const JMCard(child: JMSkeleton(height: 200)),
              const SizedBox(height: JMSpacing.xl),
              const JMCard(child: JMSkeleton(height: 320)),
            ],
          ],
        ),
      ),
    );
  }
}

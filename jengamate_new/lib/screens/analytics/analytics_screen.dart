import 'package:flutter/material.dart';
import 'package:jengamate/services/database_service.dart';
import 'package:jengamate/utils/responsive.dart';
import 'package:jengamate/screens/analytics/advanced_analytics_screen.dart';
import 'package:jengamate/ui/design_system/components/jm_button.dart';
import 'package:jengamate/ui/shared_components/jm_notification.dart';
import 'package:jengamate/ui/design_system/tokens/colors.dart';
import 'package:intl/intl.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final DatabaseService _dbService = DatabaseService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics Dashboard'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(Responsive.getResponsivePadding(context).horizontal),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'Business Overview',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Key Metrics Cards
            _buildKeyMetricsSection(),

            const SizedBox(height: 32),

            // Recent Activity
            Text(
              'Recent Activity',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            _buildRecentActivitySection(),

            const SizedBox(height: 32),

            // Performance Insights
            Text(
              'Performance Insights',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            _buildPerformanceInsightsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildKeyMetricsSection() {
    return Column(
      children: [
        // First Row - Total Users & Total Orders
        Row(
          children: [
            Expanded(
              child: StreamBuilder<int>(
                stream: _dbService.streamTotalUsersCount(),
                builder: (context, snapshot) {
                  return _buildMetricCard(
                    title: 'Total Users',
                    value: snapshot.data?.toString() ?? '0',
                    icon: Icons.people,
                    color: Colors.blue,
                    subtitle: 'Registered users',
                    isLoading: snapshot.connectionState == ConnectionState.waiting,
                  );
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: StreamBuilder<int>(
                stream: _dbService.streamTotalOrdersCount(),
                builder: (context, snapshot) {
                  return _buildMetricCard(
                    title: 'Total Orders',
                    value: snapshot.data?.toString() ?? '0',
                    icon: Icons.shopping_cart,
                    color: Colors.green,
                    subtitle: 'All time orders',
                    isLoading: snapshot.connectionState == ConnectionState.waiting,
                  );
                },
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Second Row - Pending Orders & New Users (7 days)
        Row(
          children: [
            Expanded(
              child: StreamBuilder<int>(
                stream: _dbService.streamPendingOrdersCount(),
                builder: (context, snapshot) {
                  return _buildMetricCard(
                    title: 'Pending Orders',
                    value: snapshot.data?.toString() ?? '0',
                    icon: Icons.pending_actions,
                    color: Colors.orange,
                    subtitle: 'Awaiting processing',
                    isLoading: snapshot.connectionState == ConnectionState.waiting,
                  );
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: StreamBuilder<int>(
                stream: _dbService.streamNewUsersCount(days: 7),
                builder: (context, snapshot) {
                  return _buildMetricCard(
                    title: 'New Users (7d)',
                    value: snapshot.data?.toString() ?? '0',
                    icon: Icons.person_add,
                    color: Colors.purple,
                    subtitle: 'Recent registrations',
                    isLoading: snapshot.connectionState == ConnectionState.waiting,
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String subtitle,
    required bool isLoading,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const Spacer(),
                if (isLoading)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivitySection() {
    return Column(
      children: [
        _buildActivityItem(
          icon: Icons.shopping_cart,
          title: 'New Order Received',
          subtitle: 'Order #1234 - \$2,450.00',
          time: '2 hours ago',
          color: Colors.blue,
        ),
        const SizedBox(height: 8),
        _buildActivityItem(
          icon: Icons.person_add,
          title: 'New User Registration',
          subtitle: 'John Doe joined as Engineer',
          time: '4 hours ago',
          color: Colors.green,
        ),
        const SizedBox(height: 8),
        _buildActivityItem(
          icon: Icons.payment,
          title: 'Payment Processed',
          subtitle: 'Invoice #5678 - \$1,200.00',
          time: '6 hours ago',
          color: Colors.purple,
        ),
        const SizedBox(height: 8),
        _buildActivityItem(
          icon: Icons.message,
          title: 'New RFQ Submitted',
          subtitle: 'Steel pipes - High priority',
          time: '8 hours ago',
          color: Colors.orange,
        ),
      ],
    );
  }

  Widget _buildActivityItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required String time,
    required Color color,
  }) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
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
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Text(
              time,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceInsightsSection() {
    return Column(
      children: [
        // Quick Stats Grid
        Row(
          children: [
            Expanded(
              child: _buildInsightCard(
                title: 'Conversion Rate',
                value: '24.5%',
                trend: '+2.1%',
                trendColor: Colors.green,
                icon: Icons.trending_up,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildInsightCard(
                title: 'Avg Order Value',
                value: 'TSh 1,250',
                trend: '+15.3%',
                trendColor: Colors.green,
                icon: Icons.attach_money,
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: _buildInsightCard(
                title: 'User Retention',
                value: '78.2%',
                trend: '-1.2%',
                trendColor: Colors.orange,
                icon: Icons.refresh,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildInsightCard(
                title: 'Response Time',
                value: '2.3h',
                trend: '-0.5h',
                trendColor: Colors.green,
                icon: Icons.timer,
              ),
            ),
          ],
        ),

        const SizedBox(height: 32),

        // Action Buttons
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  // Navigate to advanced analytics
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const AdvancedAnalyticsScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.analytics),
                label: const Text('View Detailed Analytics'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _showExportDialog,
                icon: const Icon(Icons.download),
                label: const Text('Export Report'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInsightCard({
    required String title,
    required String value,
    required String trend,
    required Color trendColor,
    required IconData icon,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.blue, size: 20),
                const Spacer(),
                Text(
                  trend,
                  style: TextStyle(
                    color: trendColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String selectedFormat = 'PDF';
        String selectedPeriod = 'Last 30 days';
        bool includeCharts = true;
        bool includeRawData = false;

        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.download, color: JMColors.lightScheme.primary),
                const SizedBox(width: 12),
                const Text('Export Analytics Report'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Export Format
                  const Text(
                    'Export Format',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: ['PDF', 'Excel', 'CSV'].map((format) {
                      return ChoiceChip(
                        label: Text(format),
                        selected: selectedFormat == format,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => selectedFormat = format);
                          }
                        },
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 16),

                  // Time Period
                  const Text(
                    'Time Period',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: selectedPeriod,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: [
                      'Last 7 days',
                      'Last 30 days',
                      'Last 90 days',
                      'Last year',
                      'Custom range',
                    ].map((period) {
                      return DropdownMenuItem(
                        value: period,
                        child: Text(period),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => selectedPeriod = value!);
                    },
                  ),

                  const SizedBox(height: 16),

                  // Content Options
                  const Text(
                    'Content Options',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),

                  CheckboxListTile(
                    title: const Text('Include Charts & Visualizations'),
                    subtitle: const Text('Add charts and graphs to the report'),
                    value: includeCharts,
                    onChanged: (value) {
                      setState(() => includeCharts = value ?? true);
                    },
                  ),

                  CheckboxListTile(
                    title: const Text('Include Raw Data'),
                    subtitle: const Text('Add detailed data tables'),
                    value: includeRawData,
                    onChanged: (value) {
                      setState(() => includeRawData = value ?? false);
                    },
                  ),

                  const SizedBox(height: 16),

                  // File Size Estimate
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: JMColors.info.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: JMColors.info.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: JMColors.info, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Estimated file size: ~${_calculateEstimatedSize(selectedFormat, includeCharts, includeRawData)}',
                            style: TextStyle(
                              color: JMColors.info,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              JMButton(
                variant: JMButtonVariant.primary,
                label: 'Export',
                icon: Icons.download,
                child: const SizedBox(),
                onPressed: () {
                  Navigator.of(context).pop();
                  _performExport(selectedFormat, selectedPeriod, includeCharts, includeRawData);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  String _calculateEstimatedSize(String format, bool includeCharts, bool includeRawData) {
    int baseSize = 0;

    switch (format) {
      case 'PDF':
        baseSize = 2; // MB
        if (includeCharts) baseSize += 3;
        if (includeRawData) baseSize += 1;
        break;
      case 'Excel':
        baseSize = 1;
        if (includeCharts) baseSize += 2;
        if (includeRawData) baseSize += 2;
        break;
      case 'CSV':
        baseSize = 1;
        if (includeRawData) baseSize += 1;
        break;
    }

    return '${baseSize}MB';
  }

  Future<void> _performExport(
    String format,
    String period,
    bool includeCharts,
    bool includeRawData,
  ) async {
    try {
      // Show progress notification
      context.showInfo(
        'Generating your analytics report...',
        title: 'Export in Progress',
      );

      // Simulate export process
      await Future.delayed(const Duration(seconds: 3));

      // Generate filename
      final timestamp = DateFormat('yyyy-MM-dd_HH-mm').format(DateTime.now());
      final filename = 'jengamate_analytics_${timestamp}';

      // Show success notification
      context.showSuccess(
        '$format report generated successfully!\nFile: $filename.$format',
        title: 'Export Complete',
      );

      // In a real implementation, you would:
      // 1. Gather data from database service
      // 2. Format data according to selected options
      // 3. Generate the file (PDF, Excel, CSV)
      // 4. Save to device or share
      // 5. Handle errors appropriately

    } catch (e) {
      context.showError(
        'Failed to export report: ${e.toString()}',
        title: 'Export Failed',
      );
    }
  }
} 
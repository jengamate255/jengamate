import 'package:flutter/material.dart';
import 'package:jengamate/models/product_interaction_model.dart';
import 'package:jengamate/services/product_interaction_service.dart';
import 'package:intl/intl.dart';
import 'package:jengamate/screens/admin/detailed_rfq_analytics_screen.dart';

class RFQAnalyticsDashboard extends StatefulWidget {
  const RFQAnalyticsDashboard({super.key});

  @override
  State<RFQAnalyticsDashboard> createState() => _RFQAnalyticsDashboardState();
}

class _RFQAnalyticsDashboardState extends State<RFQAnalyticsDashboard> {
  final ProductInteractionService _interactionService = ProductInteractionService();
  
  String _selectedTimeRange = '7d';
  final List<String> _timeRangeOptions = ['24h', '7d', '30d', '90d', 'all'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('RFQ Analytics Dashboard'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedTimeRange,
                items: _timeRangeOptions.map((range) => DropdownMenuItem(
                  value: range,
                  child: Text(_formatTimeRange(range)),
                )).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedTimeRange = value!;
                  });
                },
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOverviewCards(),
            const SizedBox(height: 32),
            _buildTopProductsSection(),
            const SizedBox(height: 32),
            _buildRecentActivitySection(),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewCards() {
    return StreamBuilder<List<RFQTrackingModel>>(
      stream: _interactionService.getAllRFQTracking(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final allRFQs = snapshot.data ?? [];
        final filteredRFQs = _filterByTimeRange(allRFQs);

        final totalRFQs = filteredRFQs.length;
        final pendingRFQs = filteredRFQs.where((rfq) => rfq.status == 'initiated').length;
        final quotedRFQs = filteredRFQs.where((rfq) => rfq.status == 'quoted').length;
        final acceptedRFQs = filteredRFQs.where((rfq) => rfq.status == 'accepted').length;

        return Row(
          children: [
            Expanded(child: _buildOverviewCard('Total RFQs', totalRFQs.toString(), Colors.blue, Icons.request_quote)),
            const SizedBox(width: 16),
            Expanded(child: _buildOverviewCard('Pending', pendingRFQs.toString(), Colors.orange, Icons.pending)),
            const SizedBox(width: 16),
            Expanded(child: _buildOverviewCard('Quoted', quotedRFQs.toString(), Colors.purple, Icons.format_quote)),
            const SizedBox(width: 16),
            Expanded(child: _buildOverviewCard('Accepted', acceptedRFQs.toString(), Colors.green, Icons.check_circle)),
          ],
        );
      },
    );
  }

  Widget _buildOverviewCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 32),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _formatTimeRange(_selectedTimeRange),
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopProductsSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Top Products by RFQ Activity',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              TextButton(
                onPressed: () {
                  // TODO: Navigate to detailed analytics
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DetailedRFQAnalyticsScreen(),
                    ),
                  );
                },
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FutureBuilder<List<RFQAnalyticsModel>>(
            future: _interactionService.getTopProductsByRFQActivity(limit: 5),
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
                  child: Text('No product analytics available'),
                );
              }

              return Column(
                children: topProducts.map((analytics) => _buildProductAnalyticsRow(analytics)).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProductAnalyticsRow(RFQAnalyticsModel analytics) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!, width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  analytics.productName,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Conversion: ${(analytics.conversionRate * 100).toStringAsFixed(1)}%',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Column(
              children: [
                Text(
                  analytics.totalViews.toString(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Views',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Column(
              children: [
                Text(
                  analytics.totalRFQs.toString(),
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                ),
                Text(
                  'RFQs',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Column(
              children: [
                Text(
                  analytics.totalQuotes.toString(),
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                ),
                Text(
                  'Quotes',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivitySection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent RFQ Activity',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          StreamBuilder<List<RFQTrackingModel>>(
            stream: _interactionService.getAllRFQTracking(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final allRFQs = snapshot.data ?? [];
              final recentRFQs = allRFQs.take(10).toList();

              if (recentRFQs.isEmpty) {
                return const Center(
                  child: Text('No recent RFQ activity'),
                );
              }

              return Column(
                children: recentRFQs.map((rfq) => _buildRecentActivityRow(rfq)).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivityRow(RFQTrackingModel rfq) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!, width: 1),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _getStatusColor(rfq.status),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${rfq.engineerName} requested quote for ${rfq.productName}',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Quantity: ${rfq.quantity} • Status: ${_formatStatus(rfq.status)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Text(
            DateFormat('MMM dd, HH:mm').format(rfq.createdAt),
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  List<RFQTrackingModel> _filterByTimeRange(List<RFQTrackingModel> rfqs) {
    final now = DateTime.now();
    DateTime cutoff;

    switch (_selectedTimeRange) {
      case '24h':
        cutoff = now.subtract(const Duration(hours: 24));
        break;
      case '7d':
        cutoff = now.subtract(const Duration(days: 7));
        break;
      case '30d':
        cutoff = now.subtract(const Duration(days: 30));
        break;
      case '90d':
        cutoff = now.subtract(const Duration(days: 90));
        break;
      default:
        return rfqs; // 'all' case
    }

    return rfqs.where((rfq) => rfq.createdAt.isAfter(cutoff)).toList();
  }

  String _formatTimeRange(String range) {
    switch (range) {
      case '24h':
        return 'Last 24 Hours';
      case '7d':
        return 'Last 7 Days';
      case '30d':
        return 'Last 30 Days';
      case '90d':
        return 'Last 90 Days';
      case 'all':
        return 'All Time';
      default:
        return range;
    }
  }

  String _formatStatus(String status) {
    switch (status) {
      case 'initiated':
        return 'New';
      case 'viewed_by_supplier':
        return 'Viewed';
      case 'quoted':
        return 'Quoted';
      case 'accepted':
        return 'Accepted';
      case 'rejected':
        return 'Rejected';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'initiated':
        return Colors.blue;
      case 'viewed_by_supplier':
        return Colors.orange;
      case 'quoted':
        return Colors.purple;
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

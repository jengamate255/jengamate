import 'package:flutter/material.dart';
import 'package:jengamate/models/content_moderation_dashboard_model.dart';
import 'package:jengamate/services/database_service.dart';
import 'package:jengamate/utils/responsive.dart';
import 'package:jengamate/utils/logger.dart';
import 'package:intl/intl.dart';

class ContentModerationDashboard extends StatefulWidget {
  const ContentModerationDashboard({super.key});

  @override
  State<ContentModerationDashboard> createState() => _ContentModerationDashboardState();
}

class _ContentModerationDashboardState extends State<ContentModerationDashboard> with TickerProviderStateMixin {
  final DatabaseService _databaseService = DatabaseService();
  late TabController _tabController;
  
  List<ContentModerationModel> _pendingContent = [];
  List<ContentModerationModel> _reviewedContent = [];
  bool _isLoading = true;
  
  final TextEditingController _searchController = TextEditingController();
  String _selectedContentType = 'all';
  String _selectedSeverity = 'all';
  
  final List<String> _contentTypes = ['all', 'product', 'review', 'message', 'profile', 'inquiry'];
  final List<String> _severityLevels = ['all', 'low', 'medium', 'high', 'critical'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadModerationData();
  }

  Future<void> _loadModerationData() async {
    setState(() => _isLoading = true);
    try {
      // Load real moderation data from database
      final dbService = DatabaseService();

      // Get pending content reports
      final pendingReports = await dbService.getContentReports(status: 'pending');
      _pendingContent = pendingReports.map((report) => ContentModerationModel(
        id: report['id'] ?? '',
        contentType: report['contentType'] ?? 'unknown',
        contentId: report['contentId'] ?? '',
        reportedBy: report['reportedBy'] ?? '',
        reporterName: report['reporterName'] ?? 'Unknown User',
        reason: report['reason'] ?? 'No reason provided',
        description: report['description'] ?? '',
        severity: report['severity'] ?? 'low',
        status: report['status'] ?? 'pending',
        createdAt: report['createdAt'] ?? DateTime.now(),
        content: report['content'] ?? {},
      )).toList();

      // Get reviewed content reports
      final reviewedReports = await dbService.getContentReports(status: 'reviewed');
      _reviewedContent = reviewedReports.map((report) => ContentModerationModel(
        id: report['id'] ?? '',
        contentType: report['contentType'] ?? 'unknown',
        contentId: report['contentId'] ?? '',
        reportedBy: report['reportedBy'] ?? '',
        reporterName: report['reporterName'] ?? 'Unknown User',
        reason: report['reason'] ?? 'No reason provided',
        description: report['description'] ?? '',
        severity: report['severity'] ?? 'low',
        status: report['status'] ?? 'reviewed',
        createdAt: report['createdAt'] ?? DateTime.now(),
        content: report['content'] ?? {},
      )).toList();

      Logger.log('Loaded ${_pendingContent.length} pending and ${_reviewedContent.length} reviewed items');
    } catch (e) {
      Logger.logError('Error loading moderation data', e, StackTrace.current);
      // Set empty lists instead of fallback sample data
      _pendingContent = [];
      _reviewedContent = [];

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load content moderation data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }





  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Content Moderation'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadModerationData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: [
            Tab(
              text: 'Pending (${_pendingContent.length})',
              icon: const Icon(Icons.pending),
            ),
            Tab(
              text: 'Reviewed (${_reviewedContent.length})',
              icon: const Icon(Icons.check_circle),
            ),
            const Tab(
              text: 'Analytics',
              icon: Icon(Icons.analytics),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildPendingTab(),
                _buildReviewedTab(),
                _buildAnalyticsTab(),
              ],
            ),
    );
  }

  Widget _buildPendingTab() {
    return Column(
      children: [
        _buildFiltersSection(),
        _buildStatsBar(_pendingContent),
        Expanded(child: _buildContentList(_pendingContent, isPending: true)),
      ],
    );
  }

  Widget _buildReviewedTab() {
    return Column(
      children: [
        _buildFiltersSection(),
        _buildStatsBar(_reviewedContent),
        Expanded(child: _buildContentList(_reviewedContent, isPending: false)),
      ],
    );
  }

  Widget _buildAnalyticsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Moderation Statistics'),
          const SizedBox(height: 16),
          _buildAnalyticsCards(),
          const SizedBox(height: 24),
          _buildSectionTitle('Content Type Breakdown'),
          const SizedBox(height: 16),
          _buildContentTypeChart(),
          const SizedBox(height: 24),
          _buildSectionTitle('Recent Activity'),
          const SizedBox(height: 16),
          _buildRecentActivityList(),
        ],
      ),
    );
  }

  Widget _buildFiltersSection() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search content...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (value) => setState(() {}),
            ),
            const SizedBox(height: 16),
            Responsive.isMobile(context)
                ? Column(children: _buildFilterDropdowns())
                : Row(children: _buildFilterDropdowns()),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildFilterDropdowns() {
    return [
      Expanded(
        child: DropdownButtonFormField<String>(
          value: _selectedContentType,
          decoration: const InputDecoration(
            labelText: 'Content Type',
            border: OutlineInputBorder(),
          ),
          items: _contentTypes.map((type) {
            return DropdownMenuItem(
              value: type,
              child: Text(type == 'all' ? 'All Types' : type.toUpperCase()),
            );
          }).toList(),
          onChanged: (value) {
            setState(() => _selectedContentType = value!);
          },
        ),
      ),
      const SizedBox(width: 16, height: 16),
      Expanded(
        child: DropdownButtonFormField<String>(
          value: _selectedSeverity,
          decoration: const InputDecoration(
            labelText: 'Severity',
            border: OutlineInputBorder(),
          ),
          items: _severityLevels.map((severity) {
            return DropdownMenuItem(
              value: severity,
              child: Text(severity == 'all' ? 'All Severities' : severity.toUpperCase()),
            );
          }).toList(),
          onChanged: (value) {
            setState(() => _selectedSeverity = value!);
          },
        ),
      ),
    ];
  }

  Widget _buildStatsBar(List<ContentModerationModel> items) {
    final criticalCount = items.where((item) => item.severity == 'critical').length;
    final highCount = items.where((item) => item.severity == 'high').length;
    final todayCount = items.where((item) {
      final today = DateTime.now();
      return item.createdAt.year == today.year &&
             item.createdAt.month == today.month &&
             item.createdAt.day == today.day;
    }).length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Theme.of(context).primaryColor.withOpacity(0.1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Total', items.length.toString(), Colors.blue),
          _buildStatItem('Critical', criticalCount.toString(), Colors.red),
          _buildStatItem('High', highCount.toString(), Colors.orange),
          _buildStatItem('Today', todayCount.toString(), Colors.green),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildContentList(List<ContentModerationModel> items, {required bool isPending}) {
    final filteredItems = items.where((item) {
      if (_searchController.text.isNotEmpty) {
        final searchTerm = _searchController.text.toLowerCase();
        if (!item.reason.toLowerCase().contains(searchTerm) &&
            !item.description.toLowerCase().contains(searchTerm) &&
            !item.reporterName.toLowerCase().contains(searchTerm)) {
          return false;
        }
      }
      
      if (_selectedContentType != 'all' && item.contentType != _selectedContentType) {
        return false;
      }
      
      if (_selectedSeverity != 'all' && item.severity != _selectedSeverity) {
        return false;
      }
      
      return true;
    }).toList();

    if (filteredItems.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.content_paste_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No content found', style: TextStyle(fontSize: 18, color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredItems.length,
      itemBuilder: (context, index) {
        final item = filteredItems[index];
        return _buildContentCard(item, isPending: isPending);
      },
    );
  }

  Widget _buildContentCard(ContentModerationModel item, {required bool isPending}) {
    final severityColor = _getSeverityColor(item.severity);
    final contentIcon = _getContentTypeIcon(item.contentType);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: severityColor.withOpacity(0.2),
          child: Icon(contentIcon, color: severityColor, size: 20),
        ),
        title: Text(
          '${item.contentType.toUpperCase()} - ${item.reason}',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Reported by: ${item.reporterName}'),
            Text(item.description),
            const SizedBox(height: 4),
            Text(
              DateFormat('MMM dd, yyyy HH:mm').format(item.createdAt),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        trailing: _buildSeverityChip(item.severity),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('Content ID', item.contentId),
                _buildDetailRow('Reporter', '${item.reporterName} (${item.reportedBy})'),
                _buildDetailRow('Created', DateFormat('yyyy-MM-dd HH:mm:ss').format(item.createdAt)),
                if (!isPending && item.reviewedAt != null) ...[
                  _buildDetailRow('Reviewed', DateFormat('yyyy-MM-dd HH:mm:ss').format(item.reviewedAt!)),
                  _buildDetailRow('Reviewer', item.reviewerName ?? 'Unknown'),
                  if (item.reviewNotes != null)
                    _buildDetailRow('Review Notes', item.reviewNotes!),
                ],
                const SizedBox(height: 16),
                const Text('Content Preview:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    item.content.toString(),
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                  ),
                ),
                if (isPending) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _approveContent(item),
                          icon: const Icon(Icons.check),
                          label: const Text('Approve'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _rejectContent(item),
                          icon: const Icon(Icons.close),
                          label: const Text('Reject'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.yellow[700]!;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getContentTypeIcon(String contentType) {
    switch (contentType.toLowerCase()) {
      case 'product':
        return Icons.inventory;
      case 'review':
        return Icons.rate_review;
      case 'message':
        return Icons.message;
      case 'profile':
        return Icons.person;
      case 'inquiry':
        return Icons.help;
      default:
        return Icons.content_paste;
    }
  }

  Widget _buildSeverityChip(String severity) {
    final color = _getSeverityColor(severity);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        severity.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w500,
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

  Widget _buildAnalyticsCards() {
    return Responsive.isMobile(context)
        ? Column(children: _buildAnalyticsCardsList())
        : Wrap(
            spacing: Responsive.getResponsiveSpacing(context),
            runSpacing: Responsive.getResponsiveSpacing(context),
            children: _buildAnalyticsCardsList()
                .map((card) => SizedBox(width: Responsive.getResponsiveCardWidth(context), child: card))
                .toList(),
          );
  }

  List<Widget> _buildAnalyticsCardsList() {
    return [
      _buildAnalyticsCard('Total Reports', '${_pendingContent.length + _reviewedContent.length}', Icons.report, Colors.blue),
      _buildAnalyticsCard('Pending Review', '${_pendingContent.length}', Icons.pending, Colors.orange),
      _buildAnalyticsCard('Approved', '${_reviewedContent.where((item) => item.status == 'approved').length}', Icons.check_circle, Colors.green),
      _buildAnalyticsCard('Rejected', '${_reviewedContent.where((item) => item.status == 'rejected').length}', Icons.cancel, Colors.red),
    ];
  }

  Widget _buildAnalyticsCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentTypeChart() {
    // Placeholder for content type chart
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text('Content Type Distribution'),
            const SizedBox(height: 16),
            ...['product', 'review', 'message', 'profile', 'inquiry'].map((type) {
              final count = (_pendingContent + _reviewedContent)
                  .where((item) => item.contentType == type)
                  .length;
              return ListTile(
                leading: Icon(_getContentTypeIcon(type)),
                title: Text(type.toUpperCase()),
                trailing: Text(count.toString()),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivityList() {
    final recentItems = (_pendingContent + _reviewedContent)
        .where((item) => item.createdAt.isAfter(DateTime.now().subtract(const Duration(days: 7))))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Recent Activity (Last 7 days)', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...recentItems.take(5).map((item) => ListTile(
              leading: Icon(_getContentTypeIcon(item.contentType)),
              title: Text(item.reason),
              subtitle: Text('by ${item.reporterName}'),
              trailing: Text(DateFormat('MMM dd').format(item.createdAt)),
            )),
          ],
        ),
      ),
    );
  }

  void _approveContent(ContentModerationModel item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve Content'),
        content: const Text('Are you sure you want to approve this content? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement actual approval logic
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Content approved successfully')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Approve'),
          ),
        ],
      ),
    );
  }

  void _rejectContent(ContentModerationModel item) {
    final notesController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Content'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please provide a reason for rejection:'),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                hintText: 'Rejection reason...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement actual rejection logic
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Content rejected successfully')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}

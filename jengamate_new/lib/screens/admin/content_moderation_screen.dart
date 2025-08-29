import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jengamate/models/content_moderation.dart';
import 'package:jengamate/services/admin_analytics_service.dart';
import 'package:jengamate/widgets/advanced_filter_panel.dart';
import 'package:jengamate/widgets/user_activity_timeline.dart';

class ContentModerationScreen extends StatefulWidget {
  const ContentModerationScreen({Key? key}) : super(key: key);

  @override
  _ContentModerationScreenState createState() => _ContentModerationScreenState();
}

class _ContentModerationScreenState extends State<ContentModerationScreen> {
  final AdminAnalyticsService _analyticsService = AdminAnalyticsService();
  final TextEditingController _searchController = TextEditingController();
  
  Map<String, dynamic> _currentFilters = {};
  String _searchQuery = '';
  bool _isLoading = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Content Moderation'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(),
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _exportContent,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildStatsCards(),
          Expanded(
            child: _buildContentList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search content by title, author, or keywords...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          const SizedBox(width: 8),
          if (_currentFilters.isNotEmpty)
            Chip(
              label: Text('${_currentFilters.length} filters'),
              onDeleted: () {
                setState(() {
                  _currentFilters.clear();
                });
              },
            ),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    return StreamBuilder<Map<String, dynamic>>(
      stream: _analyticsService.getContentAnalytics(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data!;
        final stats = [
          {
            'title': 'Total Content',
            'value': data['totalContent']?.toString() ?? '0',
            'icon': Icons.article,
            'color': Colors.blue,
          },
          {
            'title': 'Pending',
            'value': data['pendingContent']?.toString() ?? '0',
            'icon': Icons.pending,
            'color': Colors.orange,
          },
          {
            'title': 'Approved',
            'value': data['approvedContent']?.toString() ?? '0',
            'icon': Icons.check_circle,
            'color': Colors.green,
          },
          {
            'title': 'Flagged',
            'value': data['flaggedContent']?.toString() ?? '0',
            'icon': Icons.flag,
            'color': Colors.red,
          },
        ];

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: stats.map((stat) {
              return Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Icon(stat['icon'] as IconData, color: stat['color'] as Color),
                        const SizedBox(height: 8),
                        Text(
                          stat['value'] as String,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          stat['title'] as String,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildContentList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _getFilteredContent(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final content = snapshot.data!.docs
            .map((doc) => ContentModeration.fromFirestore(doc))
            .where((item) => _matchesSearch(item))
            .toList();

        if (content.isEmpty) {
          return const Center(
            child: Text('No content found matching your criteria'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: content.length,
          itemBuilder: (context, index) {
            return _buildContentCard(content[index]);
          },
        );
      },
    );
  }

  Widget _buildContentCard(ContentModeration content) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(content.status),
          child: Icon(
            _getContentIcon(content.contentType),
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(content.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Author: ${content.authorName}'),
            Text('Type: ${content.contentType.toUpperCase()}'),
            Text('Status: ${content.status.toUpperCase()}'),
            Text('Created: ${_formatDate(content.createdAt)}'),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.visibility),
              onPressed: () => _viewContentDetails(content),
            ),
            if (content.status == 'pending') ...[
              IconButton(
                icon: const Icon(Icons.check_circle, color: Colors.green),
                onPressed: () => _approveContent(content),
              ),
              IconButton(
                icon: const Icon(Icons.cancel, color: Colors.red),
                onPressed: () => _rejectContent(content),
              ),
            ],
            if (content.status == 'approved')
              IconButton(
                icon: const Icon(Icons.flag, color: Colors.orange),
                onPressed: () => _flagContent(content),
              ),
          ],
        ),
      ),
    );
  }

  Stream<QuerySnapshot> _getFilteredContent() {
    Query query = FirebaseFirestore.instance.collection('content_moderation');

    // Apply filters
    if (_currentFilters['contentType'] != null) {
      query = query.where('contentType', isEqualTo: _currentFilters['contentType']);
    }

    if (_currentFilters['contentStatus'] != null) {
      query = query.where('status', isEqualTo: _currentFilters['contentStatus']);
    }

    if (_currentFilters['startDate'] != null) {
      query = query.where('createdAt', isGreaterThanOrEqualTo: _currentFilters['startDate']);
    }

    if (_currentFilters['endDate'] != null) {
      query = query.where('createdAt', isLessThanOrEqualTo: _currentFilters['endDate']);
    }

    return query.orderBy('createdAt', descending: true).snapshots();
  }

  bool _matchesSearch(ContentModeration content) {
    if (_searchQuery.isEmpty) return true;
    
    return content.title.toLowerCase().contains(_searchQuery) ||
           content.authorName.toLowerCase().contains(_searchQuery) ||
           content.content.toLowerCase().contains(_searchQuery) ||
           content.tags.any((tag) => tag.toLowerCase().contains(_searchQuery));
  }

  IconData _getContentIcon(String contentType) {
    switch (contentType.toLowerCase()) {
      case 'post':
        return Icons.post_add;
      case 'comment':
        return Icons.comment;
      case 'review':
        return Icons.rate_review;
      case 'profile':
        return Icons.person;
      case 'project':
        return Icons.work;
      case 'portfolio':
        return Icons.folder;
      default:
        return Icons.article;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      case 'flagged':
        return Colors.deepOrange;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.8,
          child: AdvancedFilterPanel(
            initialFilters: _currentFilters,
            onFiltersChanged: (filters) {
              setState(() {
                _currentFilters = filters;
              });
            },
            onClearFilters: () {
              setState(() {
                _currentFilters.clear();
              });
            },
          ),
        ),
      ),
    );
  }

  void _viewContentDetails(ContentModeration content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Content Details: ${content.title}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Title', content.title),
              _buildDetailRow('Author', content.authorName),
              _buildDetailRow('Type', content.contentType.toUpperCase()),
              _buildDetailRow('Status', content.status.toUpperCase()),
              _buildDetailRow('Created', _formatDate(content.createdAt)),
              _buildDetailRow('Updated', _formatDate(content.updatedAt)),
              _buildDetailRow('Moderated By', content.moderatedBy ?? 'N/A'),
              if (content.rejectionReason != null)
                _buildDetailRow('Rejection Reason', content.rejectionReason!),
              if (content.flaggedReason != null)
                _buildDetailRow('Flagged Reason', content.flaggedReason!),
              const SizedBox(height: 16),
              const Text(
                'Content Preview',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  content.content,
                  maxLines: 10,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (content.mediaUrls.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Media Attachments',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: content.mediaUrls.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Image.network(
                          content.mediaUrls[index],
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 100,
                              height: 100,
                              color: Colors.grey,
                              child: const Icon(Icons.broken_image),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
              if (content.tags.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Tags',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  children: content.tags
                      .map((tag) => Chip(label: Text(tag)))
                      .toList(),
                ),
              ],
              const SizedBox(height: 16),
              const Text(
                'Recent Activity',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 200,
                width: 400,
                child: StreamBuilder<List<AdminUserActivity>>(
                  stream: _analyticsService.getUserActivities(
                    userId: content.authorId,
                    limit: 10,
                  ),
                  builder: (context, snapshot) {
                    return UserActivityTimeline(
                      activities: snapshot.data ?? [],
                      isLoading: !snapshot.hasData,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (content.status == 'pending') ...[
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _approveContent(content);
              },
              child: const Text('Approve'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _rejectContent(content);
              },
              child: const Text('Reject'),
            ),
          ],
          if (content.status == 'approved')
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _flagContent(content);
              },
              child: const Text('Flag'),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Future<void> _approveContent(ContentModeration content) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve Content'),
        content: Text('Are you sure you want to approve "${content.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Approve'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      setState(() => _isLoading = true);

      await FirebaseFirestore.instance
          .collection('content_moderation')
          .doc(content.id)
          .update({
        'status': 'approved',
        'moderatedAt': DateTime.now(),
        'moderatedBy': 'admin',
      });

      // Log the action
      await _analyticsService.logUserActivity(
        userId: content.authorId,
        action: 'content_approved',
        ipAddress: 'admin_panel',
        userAgent: 'admin_dashboard',
        metadata: {
          'contentType': content.contentType,
          'contentId': content.id,
        },
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Content approved successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _rejectContent(ContentModeration content) async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Content'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Are you sure you want to reject "${content.title}"?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Rejection Reason (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      setState(() => _isLoading = true);

      await FirebaseFirestore.instance
          .collection('content_moderation')
          .doc(content.id)
          .update({
        'status': 'rejected',
        'moderatedAt': DateTime.now(),
        'moderatedBy': 'admin',
        'rejectionReason': reasonController.text,
      });

      // Log the action
      await _analyticsService.logUserActivity(
        userId: content.authorId,
        action: 'content_rejected',
        ipAddress: 'admin_panel',
        userAgent: 'admin_dashboard',
        metadata: {
          'contentType': content.contentType,
          'contentId': content.id,
          'rejectionReason': reasonController.text,
        },
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Content rejected successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _flagContent(ContentModeration content) async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Flag Content'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Why are you flagging "${content.title}"?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Flagging Reason',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Flag'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      setState(() => _isLoading = true);

      await FirebaseFirestore.instance
          .collection('content_moderation')
          .doc(content.id)
          .update({
        'status': 'flagged',
        'moderatedAt': DateTime.now(),
        'moderatedBy': 'admin',
        'flaggedReason': reasonController.text,
      });

      // Log the action
      await _analyticsService.logUserActivity(
        userId: content.authorId,
        action: 'content_flagged',
        ipAddress: 'admin_panel',
        userAgent: 'admin_dashboard',
        metadata: {
          'contentType': content.contentType,
          'contentId': content.id,
          'flaggedReason': reasonController.text,
        },
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Content flagged successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _exportContent() async {
    try {
      setState(() => _isLoading = true);
      
      final csvData = await _analyticsService.exportContentToCSV(
        filters: _currentFilters,
      );

      if (csvData.isNotEmpty) {
        // In a real app, you would save this to a file
        // For now, we'll show a success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Content exported successfully')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error exporting content: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
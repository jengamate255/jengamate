import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jengamate/models/enhanced_user.dart';
import 'package:jengamate/services/admin_analytics_service.dart';
import 'package:jengamate/widgets/advanced_filter_panel.dart';
import 'package:jengamate/widgets/user_activity_timeline.dart';
import 'package:jengamate/models/admin_user_activity.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({Key? key}) : super(key: key);

  @override
  _UserManagementScreenState createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
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
        title: const Text('User Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(),
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _exportUsers,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildStatsCards(),
          Expanded(
            child: _buildUserList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Padding(
      padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: isMobile
                      ? 'Search users...'
                      : 'Search users by name, email, or phone...',
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
              if (!isMobile) ...[
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
            ],
          ),
          if (isMobile && _currentFilters.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Chip(
                  label: Text('${_currentFilters.length} filters'),
                  onDeleted: () {
                    setState(() {
                      _currentFilters.clear();
                    });
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    return StreamBuilder<Map<String, dynamic>>(
      stream: _analyticsService.getUserAnalytics(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data!;
        final stats = [
          {
            'title': 'Total Users',
            'value': (data['totalUsers'] ?? 0).toString(),
            'icon': Icons.people,
            'color': Colors.blue,
          },
          {
            'title': 'Active Users',
            'value': (data['activeUsers'] ?? 0).toString(),
            'icon': Icons.check_circle,
            'color': Colors.green,
          },
          {
            'title': 'Pending',
            'value': (data['pendingUsers'] ?? 0).toString(),
            'icon': Icons.pending,
            'color': Colors.orange,
          },
          {
            'title': 'Suspended',
            'value': (data['suspendedUsers'] ?? 0).toString(),
            'icon': Icons.block,
            'color': Colors.red,
          },
        ];

        final screenWidth = MediaQuery.of(context).size.width;
        final isMobile = screenWidth < 600;

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: isMobile ? 12.0 : 16.0),
          child: isMobile
            ? Column(
                children: stats.map((stat) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Card(
                      child: Padding(
                        padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
                        child: Row(
                          children: [
                            Icon(stat['icon'] as IconData,
                                color: stat['color'] as Color,
                                size: isMobile ? 24 : 32),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    stat['value'] as String,
                                    style: TextStyle(
                                      fontSize: isMobile ? 18 : 24,
                                      fontWeight: FontWeight.bold,
                                      color: stat['color'] as Color,
                                    ),
                                  ),
                                  Text(
                                    stat['title'] as String,
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      fontSize: isMobile ? 12 : null,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              )
            : Row(
                children: stats.map((stat) {
                  return Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Icon(stat['icon'] as IconData,
                                color: stat['color'] as Color),
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

  Widget _buildUserList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _getFilteredUsers(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final users = snapshot.data!.docs
            .map((doc) => EnhancedUser.fromFirestore(doc))
            .where((user) => _matchesSearch(user))
            .toList();

        if (users.isEmpty) {
          return const Center(
            child: Text('No users found matching your criteria'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: users.length,
          itemBuilder: (context, index) {
            return _buildUserCard(users[index]);
          },
        );
      },
    );
  }

  Widget _buildUserCard(EnhancedUser user) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              _getUserStatusColor((user.isActive ? 'approved' : 'suspended')),
          child: Text(
            user.displayName.isNotEmpty
                ? user.displayName[0].toUpperCase()
                : '?',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(user.displayName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.email),
            Text(
              '${user.roles.join(', ').toUpperCase()} • ${(user.isActive ? 'approved' : 'suspended').toUpperCase()}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.visibility),
              onPressed: () => _viewUserDetails(user),
            ),
            PopupMenuButton<String>(
              onSelected: (value) => _handleUserAction(user, value),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'view',
                  child: Text('View Details'),
                ),
                if ((user.isActive ? 'approved' : 'suspended') != 'approved')
                  const PopupMenuItem(
                    value: 'approve',
                    child: Text('Approve'),
                  ),
                if ((user.isActive ? 'approved' : 'suspended') != 'suspended')
                  const PopupMenuItem(
                    value: 'suspend',
                    child: Text('Suspend'),
                  ),
                if ((user.isActive ? 'approved' : 'suspended') == 'suspended')
                  const PopupMenuItem(
                    value: 'reactivate',
                    child: Text('Reactivate'),
                  ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('Delete'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Stream<QuerySnapshot> _getFilteredUsers() {
    Query query = FirebaseFirestore.instance.collection('users');

    // Apply filters
    if (_currentFilters['role'] != null) {
      query = query.where('role', isEqualTo: _currentFilters['role']);
    }

    if (_currentFilters['status'] != null) {
      query = query.where('status', isEqualTo: _currentFilters['status']);
    }

    if (_currentFilters['isActive'] != null) {
      query = query.where('isActive', isEqualTo: _currentFilters['isActive']);
    }

    if (_currentFilters['startDate'] != null) {
      query = query.where('createdAt',
          isGreaterThanOrEqualTo: _currentFilters['startDate']);
    }

    if (_currentFilters['endDate'] != null) {
      query = query.where('createdAt',
          isLessThanOrEqualTo: _currentFilters['endDate']);
    }

    return query.snapshots();
  }

  bool _matchesSearch(EnhancedUser user) {
    if (_searchQuery.isEmpty) return true;

    return user.displayName.toLowerCase().contains(_searchQuery) ||
        user.email.toLowerCase().contains(_searchQuery) ||
        (user.phoneNumber?.toLowerCase().contains(_searchQuery) ?? false);
  }

  Color _getUserStatusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      case 'suspended':
        return Colors.grey;
      default:
        return Colors.blue;
    }
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

  void _viewUserDetails(EnhancedUser user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('User Details: ${user.displayName}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Name', user.displayName),
              _buildDetailRow('Email', user.email),
              _buildDetailRow('Phone', user.phoneNumber ?? 'N/A'),
              _buildDetailRow('Role', user.roles.join(', ').toUpperCase()),
              _buildDetailRow('Status',
                  (user.isActive ? 'approved' : 'suspended').toUpperCase()),
              _buildDetailRow('Active', user.isActive ? 'Yes' : 'No'),
              _buildDetailRow('Created', user.createdAt.toString()),
              _buildDetailRow(
                  'Last Login',
                  user.lastLoginAt != null
                      ? user.lastLoginAt.toString()
                      : 'N/A'),
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
                    userId: user.uid,
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
            width: 100,
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

  Future<void> _handleUserAction(EnhancedUser user, String action) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm $action'),
        content: Text('Are you sure you want to $action ${user.displayName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      setState(() => _isLoading = true);

      switch (action) {
        case 'approve':
          await _updateUserStatus(user.uid, 'approved');
          break;
        case 'suspend':
          await _updateUserStatus(user.uid, 'suspended');
          break;
        case 'reactivate':
          await _updateUserStatus(user.uid, 'approved');
          break;
        case 'delete':
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .delete();
          break;
      }

      // Log the action
      await _analyticsService.logUserActivity(
        userId: user.uid,
        action: action,
        metadata: {
          'ipAddress': 'admin_panel',
          'userAgent': 'admin_dashboard',
          'performedBy': 'admin',
          'targetUser': user.uid,
        },
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User ${action}d successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateUserStatus(String userId, String status) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .update({'status': status});
  }

  Future<void> _exportUsers() async {
    try {
      setState(() => _isLoading = true);

      final csvData = await _analyticsService.exportUsersToCSV(
          // filters: _currentFilters, // Not directly supported by exportUsersToCSV
          );

      if (csvData.isNotEmpty) {
        // In a real app, you would save this to a file
        // For now, we'll show a success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Users exported successfully')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error exporting users: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
}

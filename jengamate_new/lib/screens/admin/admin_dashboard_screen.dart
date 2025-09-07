import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jengamate/services/admin_analytics_service.dart';
import 'package:jengamate/screens/admin/document_verification_screen.dart';
import 'package:jengamate/screens/admin/content_moderation_screen.dart';
import 'package:jengamate/screens/admin/rfq_management_screen.dart';
import 'package:jengamate/screens/admin/user_management_screen.dart';
import 'package:jengamate/screens/admin/system_config_screen.dart';
import 'package:jengamate/screens/admin/reports_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  _AdminDashboardScreenState createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final AdminAnalyticsService _analyticsService = AdminAnalyticsService();
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const AdminOverviewScreen(),
    const DocumentVerificationScreen(),
    const ContentModerationScreen(),
    const RFQManagementScreen(),
    const UserManagementScreen(),
    const SystemConfigScreen(),
    const ReportsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            extended: MediaQuery.of(context).size.width > 800,
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.dashboard),
                selectedIcon: Icon(Icons.dashboard),
                label: Text('Overview'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.verified_user),
                selectedIcon: Icon(Icons.verified_user),
                label: Text('Documents'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.policy),
                selectedIcon: Icon(Icons.policy),
                label: Text('Content'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.request_quote),
                selectedIcon: Icon(Icons.request_quote),
                label: Text('RFQs'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.people),
                selectedIcon: Icon(Icons.people),
                label: Text('Users'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.settings),
                selectedIcon: Icon(Icons.settings),
                label: Text('System'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.analytics),
                selectedIcon: Icon(Icons.analytics),
                label: Text('Reports'),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: _screens[_selectedIndex],
          ),
        ],
      ),
    );
  }
}

class AdminOverviewScreen extends StatefulWidget {
  const AdminOverviewScreen({Key? key}) : super(key: key);

  @override
  _AdminOverviewScreenState createState() => _AdminOverviewScreenState();
}

class _AdminOverviewScreenState extends State<AdminOverviewScreen> {
  final AdminAnalyticsService _analyticsService = AdminAnalyticsService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard Overview'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeHeader(),
            const SizedBox(height: 24),
            _buildQuickStats(),
            const SizedBox(height: 24),
            _buildRecentActivity(),
            const SizedBox(height: 24),
            _buildSystemHealth(),
            const SizedBox(height: 24),
            _buildQuickActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Welcome to Admin Dashboard',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Manage and monitor all aspects of the JengaMate platform',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            StreamBuilder<Map<String, dynamic>>(
              stream: _analyticsService.getSystemHealth(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const LinearProgressIndicator();
                }

                final health = snapshot.data!;
                return Row(
                  children: [
                    _buildHealthIndicator(
                      'System Status',
                      health['status'] == 'healthy' ? Colors.green : Colors.red,
                      (health['status']?.toString() ?? 'unknown').toUpperCase(),
                    ),
                    const SizedBox(width: 16),
                    _buildHealthIndicator(
                      'Last Updated',
                      Colors.blue,
                      _formatDateTime(health['lastUpdated']),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthIndicator(String label, Color color, String value) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text('$label: $value'),
      ],
    );
  }

  Widget _buildQuickStats() {
    return StreamBuilder<Map<String, dynamic>>(
      stream: _analyticsService.getDashboardStats(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final stats = snapshot.data!;
        final statCards = [
          {
            'title': 'Total Users',
            'value': (stats['totalUsers'] ?? 0).toString(),
            'icon': Icons.people,
            'color': Colors.blue,
            'route': 4, // UserManagementScreen
          },
          {
            'title': 'Pending Documents',
            'value': (stats['pendingDocuments'] ?? 0).toString(),
            'icon': Icons.verified_user,
            'color': Colors.orange,
            'route': 1, // DocumentVerificationScreen
          },
          {
            'title': 'Active RFQs',
            'value': (stats['activeRFQs'] ?? 0).toString(),
            'icon': Icons.request_quote,
            'color': Colors.green,
            'route': 3, // RFQManagementScreen
          },
          {
            'title': 'Flagged Content',
            'value': (stats['flaggedContent'] ?? 0).toString(),
            'icon': Icons.flag,
            'color': Colors.red,
            'route': 2, // ContentModerationScreen
          },
        ];

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
          childAspectRatio: 1.5,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          children: statCards.map((stat) {
            return _buildStatCard(
              stat['title'] as String,
              stat['value'] as String,
              stat['icon'] as IconData,
              stat['color'] as Color,
              stat['route'] as int,
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    int routeIndex,
  ) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: () {
          // Navigate to the corresponding screen
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => AdminDashboardScreen(),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
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
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Activity',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: _analyticsService.getRecentActivity(limit: 5),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final activities = snapshot.data!;
                if (activities.isEmpty) {
                  return const Text('No recent activity');
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: activities.length,
                  itemBuilder: (context, index) {
                    final activity = activities[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _getActivityColor(activity['type']),
                        child: Icon(
                          _getActivityIcon(activity['type']),
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      title: Text(activity['description'] != null ? activity['description'].toString() : 'No description'),
                      subtitle: Text(
                        _formatDateTime(activity['timestamp']),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.open_in_new),
                        onPressed: () {
                          // Navigate to relevant screen based on activity type
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemHealth() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'System Health',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            StreamBuilder<Map<String, dynamic>>(
              stream: _analyticsService.getSystemHealth(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final health = snapshot.data!;
                return Column(
                  children: [
                    _buildHealthMetric(
                      'Database',
                      health['databaseStatus'] == 'healthy',
                      health['databaseResponseTime'] != null ? health['databaseResponseTime'].toString() : 'N/A',
                    ),
                    _buildHealthMetric(
                      'Authentication',
                      health['authStatus'] == 'healthy',
                      health['authResponseTime'] != null ? health['authResponseTime'].toString() : 'N/A',
                    ),
                    _buildHealthMetric(
                      'Storage',
                      health['storageStatus'] == 'healthy',
                      health['storageUsage'] != null ? health['storageUsage'].toString() : 'N/A',
                    ),
                    _buildHealthMetric(
                      'API',
                      health['apiStatus'] == 'healthy',
                      health['apiResponseTime'] != null ? health['apiResponseTime'].toString() : 'N/A',
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthMetric(String name, bool isHealthy, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: isHealthy ? Colors.green : Colors.red,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(name)),
          Text(value),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _buildQuickActionButton(
                  'Verify Documents',
                  Icons.verified_user,
                  Colors.blue,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DocumentVerificationScreen(),
                    ),
                  ),
                ),
                _buildQuickActionButton(
                  'Moderate Content',
                  Icons.policy,
                  Colors.orange,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ContentModerationScreen(),
                    ),
                  ),
                ),
                _buildQuickActionButton(
                  'Manage RFQs',
                  Icons.request_quote,
                  Colors.green,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RFQManagementScreen(),
                    ),
                  ),
                ),
                _buildQuickActionButton(
                  'User Management',
                  Icons.people,
                  Colors.purple,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const UserManagementScreen(),
                    ),
                  ),
                ),
                _buildQuickActionButton(
                  'System Settings',
                  Icons.settings,
                  Colors.grey,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SystemConfigScreen(),
                    ),
                  ),
                ),
                _buildQuickActionButton(
                  'Generate Reports',
                  Icons.analytics,
                  Colors.teal,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ReportsScreen(),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return SizedBox(
      width: 150,
      child: ElevatedButton.icon(
        icon: Icon(icon, color: Colors.white),
        label: Text(
          label,
          style: const TextStyle(color: Colors.white),
          textAlign: TextAlign.center,
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        onPressed: onPressed,
      ),
    );
  }

  Color _getActivityColor(String type) {
    switch (type) {
      case 'user_registered':
        return Colors.blue;
      case 'document_uploaded':
        return Colors.orange;
      case 'rfq_created':
        return Colors.green;
      case 'content_flagged':
        return Colors.red;
      case 'login':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getActivityIcon(String type) {
    switch (type) {
      case 'user_registered':
        return Icons.person_add;
      case 'document_uploaded':
        return Icons.upload_file;
      case 'rfq_created':
        return Icons.note_add;
      case 'content_flagged':
        return Icons.flag;
      case 'login':
        return Icons.login;
      default:
        return Icons.info;
    }
  }

  String _formatDateTime(dynamic timestamp) {
    if (timestamp == null) return 'N/A';

    DateTime dateTime;
    if (timestamp is Timestamp) {
      dateTime = timestamp.toDate();
    } else if (timestamp is DateTime) {
      dateTime = timestamp;
    } else {
      return 'N/A';
    }

    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

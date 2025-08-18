import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jengamate/models/user_model.dart';
import 'package:jengamate/services/database_service.dart';
import 'package:jengamate/models/enums/user_role.dart';
import 'package:intl/intl.dart';

class UserAnalyticsDashboard extends StatelessWidget {
  const UserAnalyticsDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 800;

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Analytics Dashboard'),
      ),
      body: StreamBuilder<List<UserModel>>(
        stream: DatabaseService().streamAllUsers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No user data available'));
          }

          final users = snapshot.data!;
          return _buildAnalyticsContent(users, isDesktop);
        },
      ),
    );
  }

  Widget _buildAnalyticsContent(List<UserModel> users, bool isDesktop) {
    final stats = _calculateUserStats(users);
    
    return SingleChildScrollView(
      padding: EdgeInsets.all(isDesktop ? 24 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMetricsGrid(stats, users, isDesktop),
          const SizedBox(height: 20),
          _buildDistributionSection(users, isDesktop),
          const SizedBox(height: 20),
          _buildActivitySection(users, isDesktop),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid(Map<String, int> stats, List<UserModel> users, bool isDesktop) {
    final crossAxisCount = isDesktop ? 4 : 2;
    
    return LayoutBuilder(
      builder: (context, constraints) {
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          childAspectRatio: isDesktop ? 1.8 : 1.5,
          mainAxisSpacing: isDesktop ? 16 : 8,
          crossAxisSpacing: isDesktop ? 16 : 8,
          children: [
            _buildMetricCard('Total Users', users.length.toString(), Icons.people, Colors.blue, isDesktop),
            _buildMetricCard('Active Users', stats['active']?.toString() ?? '0', Icons.check_circle, Colors.green, isDesktop),
            _buildMetricCard('Engineers', stats['engineers']?.toString() ?? '0', Icons.engineering, Colors.orange, isDesktop),
            _buildMetricCard('Suppliers', stats['suppliers']?.toString() ?? '0', Icons.business, Colors.purple, isDesktop),
          ],
        );
      },
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color, bool isDesktop) {
    return Card(
      elevation: isDesktop ? 4 : 2,
      child: Padding(
        padding: EdgeInsets.all(isDesktop ? 20 : 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: isDesktop ? 40 : 32),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(
              fontSize: isDesktop ? 28 : 24,
              fontWeight: FontWeight.bold
            )),
            Text(title, style: TextStyle(
              fontSize: isDesktop ? 14 : 12,
              color: Colors.grey
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildDistributionSection(List<UserModel> users, bool isDesktop) {
    final roleCounts = _getRoleCounts(users);
    final statusCounts = _getStatusCounts(users);
    
    if (isDesktop) {
      return Row(
        children: [
          Expanded(child: _buildDistributionCard('By Role', roleCounts, isDesktop)),
          const SizedBox(width: 16),
          Expanded(child: _buildDistributionCard('By Status', statusCounts, isDesktop)),
        ],
      );
    } else {
      return Column(
        children: [
          _buildDistributionCard('By Role', roleCounts, isDesktop),
          const SizedBox(height: 16),
          _buildDistributionCard('By Status', statusCounts, isDesktop),
        ],
      );
    }
  }

  Widget _buildDistributionCard(String title, Map<String, int> counts, bool isDesktop) {
    return Card(
      elevation: isDesktop ? 4 : 2,
      child: Padding(
        padding: EdgeInsets.all(isDesktop ? 20 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: isDesktop ? 18 : 16,
            )),
            const SizedBox(height: 8),
            ...counts.entries.map((entry) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Text('${entry.key}: ', style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(entry.value.toString()),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildActivitySection(List<UserModel> users, bool isDesktop) {
    final recentUsers = users.where((u) => u.createdAt != null)
        .toList()
      ..sort((a, b) => b.createdAt!.compareTo(a.createdAt!));
    
    return Card(
      elevation: isDesktop ? 4 : 2,
      child: Padding(
        padding: EdgeInsets.all(isDesktop ? 20 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Recent Activity', style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: isDesktop ? 18 : 16,
            )),
            const SizedBox(height: 8),
            if (recentUsers.isEmpty)
              const Text('No recent activity')
            else
              ...recentUsers.take(isDesktop ? 10 : 5).map((user) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: isDesktop ? 20 : 16,
                      backgroundImage: user.photoUrl != null
                          ? NetworkImage(user.photoUrl!)
                          : null,
                      child: user.photoUrl == null
                          ? Text(user.displayName[0].toUpperCase())
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user.displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text(
                            'Joined ${DateFormat('MMM dd, yyyy').format(user.createdAt!)}',
                            style: TextStyle(
                              fontSize: isDesktop ? 14 : 12,
                              color: Colors.grey
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
          ],
        ),
      ),
    );
  }

  Map<String, int> _calculateUserStats(List<UserModel> users) {
    return {
      'active': users.where((u) => u.isApproved).length, // Assuming 'active' means approved
      'engineers': users.where((u) => u.role == UserRole.engineer).length,
      'suppliers': users.where((u) => u.role == UserRole.supplier).length,
    };
  }

  Map<String, int> _getRoleCounts(List<UserModel> users) {
    final counts = <String, int>{};
    for (final role in UserRole.values) {
      counts[role.name] = users.where((u) => u.role == role).length;
    }
    return counts;
  }

  Map<String, int> _getStatusCounts(List<UserModel> users) {
    return {
      'Approved': users.where((u) => u.isApproved).length,
      'Pending': users.where((u) => u.approvalStatus == 'pending').length,
      'Rejected': users.where((u) => u.approvalStatus == 'rejected').length,
    };
  }
}
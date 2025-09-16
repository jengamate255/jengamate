import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jengamate/services/admin_analytics_service.dart';
import 'package:jengamate/services/admin_notification_service.dart';
import 'package:jengamate/services/notification_trigger_service.dart';
import 'package:jengamate/screens/admin/document_verification_screen.dart';
import 'package:jengamate/screens/admin/content_moderation_screen.dart';
import 'package:jengamate/screens/admin/rfq_management_screen.dart';
import 'package:jengamate/screens/admin/user_management_screen.dart';
import 'package:jengamate/screens/admin/system_config_screen.dart';
import 'package:jengamate/screens/admin/reports_screen.dart';
import 'package:jengamate/screens/admin/notifications_screen.dart';
import 'package:jengamate/screens/admin/payment_approval_screen.dart';
import 'package:jengamate/screens/admin/bulk_operations_screen.dart';
import 'package:jengamate/screens/admin/audit_log_screen.dart';
import 'package:jengamate/screens/admin/product_management_screen.dart';
import 'package:jengamate/screens/admin/financial_oversight_screen.dart';
import 'package:jengamate/screens/admin/analytics_screen.dart';
import 'package:jengamate/screens/admin/commission_management_screen.dart';
import 'package:jengamate/screens/admin/rfq_management_dashboard.dart';
import 'package:jengamate/screens/admin/withdrawal_management_screen.dart';
import 'package:jengamate/screens/admin/rank_management_screen.dart';
import 'package:jengamate/screens/admin/referral_management_screen.dart';
import 'package:jengamate/screens/admin/admin_tools_screen.dart';
import 'package:jengamate/screens/test/image_upload_test_screen.dart';
import 'package:jengamate/screens/admin/rfq_analytics_dashboard.dart';
import 'package:jengamate/screens/finance/financial_dashboard_screen.dart';
import 'package:jengamate/screens/analytics/advanced_analytics_screen.dart';
import 'package:jengamate/screens/admin/commission_tier_management_screen.dart';
import 'package:jengamate/screens/support/support_dashboard_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  _AdminDashboardScreenState createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final AdminAnalyticsService _analyticsService = AdminAnalyticsService();
  final AdminNotificationService _notificationService = AdminNotificationService();
  final NotificationTriggerService _triggerService = NotificationTriggerService();
  int _selectedIndex = 0;
  int _unreadNotificationCount = 0;
  List<AdminNotification> _criticalAlerts = [];
  bool _showCriticalAlert = false;

  void _onOverviewNavigate(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  List<Widget> get _screens => [
    AdminOverviewScreen(
      onNavigate: (index) => _onOverviewNavigate(index),
      analyticsService: _analyticsService,
    ),              // 0
    const DocumentVerificationScreen(),       // 1
    const ContentModerationScreen(),          // 2
    const RFQManagementScreen(),              // 3
    const UserManagementScreen(),             // 4
    const ProductManagementScreen(),          // 5
    const SystemConfigScreen(),               // 6
    const ReportsScreen(),                    // 7
    const AnalyticsScreen(),                  // 8
    const PaymentApprovalScreen(),            // 9
    const FinancialOversightScreen(),         // 10
    const CommissionManagementScreen(),       // 11
    const WithdrawalManagementScreen(),       // 12
    const BulkOperationsScreen(),             // 13
    const NotificationsScreen(),              // 14
    const AuditLogScreen(),                   // 15
    const RfqManagementDashboard(),           // 16
    const RankManagementScreen(),             // 17
    const ReferralManagementScreen(),         // 18
    const AdminToolsScreen(),                 // 19
    const ImageUploadTestScreen(),             // 20
    const RFQAnalyticsDashboard(),            // 21
    const FinancialDashboardScreen(),         // 22
    const AdvancedAnalyticsScreen(),          // 23
    const CommissionTierManagementScreen(),   // 24
    const SupportDashboardScreen(),           // 25
  ];

  @override
  void initState() {
    super.initState();
    _setupNotificationListeners();
    _initializeNotifications();
  }

  @override
  void dispose() {
    _notificationService.dispose();
    _triggerService.dispose();
    super.dispose();
  }

  void _setupNotificationListeners() {
    // Listen to unread count changes
    _notificationService.unreadCountStream.listen((count) {
      if (mounted) {
        setState(() {
          _unreadNotificationCount = count;
        });
      }
    });

    // Listen to critical alerts
    _notificationService.criticalAlertsStream.listen((alerts) {
      if (mounted && alerts.isNotEmpty) {
        setState(() {
          _criticalAlerts = alerts;
          _showCriticalAlert = true;
        });
        _showCriticalAlertBanner();
      }
    });
  }

  Future<void> _initializeNotifications() async {
    try {
      await _notificationService.checkAndCreateSystemAlerts();
    } catch (e) {
      debugPrint('Failed to initialize notifications: $e');
    }
  }

  void _showCriticalAlertBanner() {
    if (!_showCriticalAlert || _criticalAlerts.isEmpty) return;

    final alert = _criticalAlerts.first;
    ScaffoldMessenger.of(context).showMaterialBanner(
      MaterialBanner(
        content: Row(
          children: [
            Icon(alert.getTypeIcon(), color: alert.getTypeColor(), size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    alert.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    alert.message,
                    style: const TextStyle(fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
              setState(() => _showCriticalAlert = false);
            },
            child: const Text('DISMISS'),
          ),
          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
              _showNotifications(context);
              setState(() => _showCriticalAlert = false);
            },
            child: const Text('VIEW'),
          ),
        ],
        backgroundColor: alert.getTypeColor().withOpacity(0.1),
      ),
    );

    // Auto-hide after 10 seconds
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
        setState(() => _showCriticalAlert = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 900;
    final isTablet = screenWidth > 600 && screenWidth <= 900;
    final isMobile = screenWidth <= 600;

    return Scaffold(
      appBar: isMobile || isTablet ? AppBar(
        title: const Text('Admin Dashboard'),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications),
                onPressed: () => _showNotifications(context),
              ),
              if (_unreadNotificationCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      _unreadNotificationCount > 99 ? '99+' : _unreadNotificationCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ) : null,

      drawer: isMobile || isTablet ? _buildDrawer() : null,

      bottomNavigationBar: isMobile ? _buildBottomNavigationBar() : null,

      body: Row(
        children: [
          if (isDesktop)
            NavigationRail(
              extended: screenWidth > 1200,
              selectedIndex: _selectedIndex,
              onDestinationSelected: _handleRailNavigation,
              destinations: _buildNavigationDestinations(),
            ),
          if (isDesktop) const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: _screens[_selectedIndex],
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.blue,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.admin_panel_settings, size: 30, color: Colors.blue),
                ),
                SizedBox(height: 10),
                Text(
                  'Admin Panel',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Management Dashboard',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          ..._buildNavigationItems(),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex.clamp(0, 4), // Clamp to prevent index out of range
      onTap: (index) {
        if (index == 4) {
          // "More" button pressed - show menu with all screens
          _showMoreMenu();
        } else {
          setState(() {
            _selectedIndex = index;
          });
        }
      },
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard),
          label: 'Overview',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.verified_user),
          label: 'Verify',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.policy),
          label: 'Content',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.request_quote),
          label: 'RFQs',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.more_horiz),
          label: 'More',
        ),
      ],
    );
  }

  void _showMoreMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Admin Functions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildMenuButton('Users', Icons.people, 4),
                _buildMenuButton('Products', Icons.inventory, 5),
                _buildMenuButton('System', Icons.settings, 6),
                _buildMenuButton('Reports', Icons.analytics, 7),
                _buildMenuButton('Analytics', Icons.bar_chart, 8),
                _buildMenuButton('Payments', Icons.payment, 9),
                _buildMenuButton('Finance', Icons.account_balance, 10),
                _buildMenuButton('Commissions', Icons.money, 11),
                _buildMenuButton('Withdrawals', Icons.payments, 12),
                _buildMenuButton('Bulk Ops', Icons.work, 13),
                _buildMenuButton('Notifications', Icons.notifications, 14),
                _buildMenuButton('Audit', Icons.receipt_long, 15),
                _buildMenuButton('RFQ Dash', Icons.dashboard, 16),
                _buildMenuButton('Ranks', Icons.grade, 17),
                _buildMenuButton('Referrals', Icons.people_outline, 18),
                _buildMenuButton('Tools', Icons.build, 19),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuButton(String label, IconData icon, int index) {
    return ElevatedButton.icon(
      onPressed: () {
        Navigator.of(context).pop(); // Close bottom sheet
        setState(() {
          _selectedIndex = index;
        });
      },
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  List<NavigationRailDestination> _buildNavigationDestinations() {
    return const [
      NavigationRailDestination(
        icon: Icon(Icons.dashboard),
        selectedIcon: Icon(Icons.dashboard),
        label: Text('Overview'),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.verified_user),
        selectedIcon: Icon(Icons.verified_user),
        label: Text('Verify'),
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
        icon: Icon(Icons.inventory),
        selectedIcon: Icon(Icons.inventory),
        label: Text('Products'),
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
      NavigationRailDestination(
        icon: Icon(Icons.bar_chart),
        selectedIcon: Icon(Icons.bar_chart),
        label: Text('Analytics'),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.payment),
        selectedIcon: Icon(Icons.payment),
        label: Text('Payments'),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.account_balance),
        selectedIcon: Icon(Icons.account_balance),
        label: Text('Finance'),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.money),
        selectedIcon: Icon(Icons.money),
        label: Text('Commissions'),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.payments),
        selectedIcon: Icon(Icons.payments),
        label: Text('Withdrawals'),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.work),
        selectedIcon: Icon(Icons.work),
        label: Text('Bulk Ops'),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.notifications),
        selectedIcon: Icon(Icons.notifications),
        label: Text('Notifications'),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.receipt_long),
        selectedIcon: Icon(Icons.receipt_long),
        label: Text('Audit'),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.grade),
        selectedIcon: Icon(Icons.grade),
        label: Text('Ranks'),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.people_outline),
        selectedIcon: Icon(Icons.people_outline),
        label: Text('Referrals'),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.build),
        selectedIcon: Icon(Icons.build),
        label: Text('Tools'),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.more_horiz),
        selectedIcon: Icon(Icons.more_horiz),
        label: Text('More'),
      ),
    ];
  }

  List<Widget> _buildNavigationItems() {
    return [
      // Core Management
      _buildSectionHeader('Core Management'),
      _buildNavItem('Overview', Icons.dashboard, 0),
      _buildNavItem('Users', Icons.people, 4),
      _buildNavItem('Products', Icons.inventory, 5),

      // Verification & Content
      _buildSectionHeader('Verification & Content'),
      _buildNavItem('Document Verification', Icons.verified_user, 1),
      _buildNavItem('Content Moderation', Icons.policy, 2),

      // Financial Management
      _buildSectionHeader('Financial Management'),
      _buildNavItem('Payment Approval', Icons.payment, 9),
      _buildNavItem('Financial Oversight', Icons.account_balance, 10),
      _buildNavItem('Commissions', Icons.money, 11),
      _buildNavItem('Withdrawals', Icons.payments, 12),

      // RFQ Management
      _buildSectionHeader('RFQ Management'),
      _buildNavItem('RFQ Management', Icons.request_quote, 3),
      _buildNavItem('RFQ Dashboard', Icons.dashboard, 16),

      // Analytics & Reports
      _buildSectionHeader('Analytics & Reports'),
      _buildNavItem('Reports', Icons.analytics, 7),
      _buildNavItem('Analytics', Icons.bar_chart, 8),

      // Operations
      _buildSectionHeader('Operations'),
      _buildNavItem('Bulk Operations', Icons.work, 13),
      _buildNavItem('Notifications', Icons.notifications, 14),

      // System & Audit
      _buildSectionHeader('System & Audit'),
      _buildNavItem('System Config', Icons.settings, 6),
      _buildNavItem('Audit Logs', Icons.receipt_long, 15),

      // Advanced Features
      _buildSectionHeader('Advanced Features'),
      _buildNavItem('Rank Management', Icons.grade, 17),
      _buildNavItem('Referral Management', Icons.people_outline, 18),
      _buildNavItem('Admin Tools', Icons.build, 19),
    ];
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildNavItem(String label, IconData icon, int index) {
    return ListTile(
      leading: Icon(icon, size: 20),
      title: Text(
        label,
        style: const TextStyle(fontSize: 14),
      ),
      selected: _selectedIndex == index,
      selectedTileColor: Theme.of(context).primaryColor.withOpacity(0.1),
      dense: true,
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
        Navigator.of(context).pop(); // Close drawer
      },
    );
  }

  void _showNotifications(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const NotificationsScreen(),
      ),
    );
  }

  void _handleRailNavigation(int index) {
    if (index == 19) { // More button
      _showMoreMenu();
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }
}

class AdminOverviewScreen extends StatefulWidget {
  final ValueChanged<int> onNavigate;
  final AdminAnalyticsService analyticsService;

  const AdminOverviewScreen({
    Key? key,
    required this.onNavigate,
    required this.analyticsService,
  }) : super(key: key);

  @override
  _AdminOverviewScreenState createState() => _AdminOverviewScreenState();
}

class _AdminOverviewScreenState extends State<AdminOverviewScreen> {
  final AdminNotificationService _notificationService = AdminNotificationService();
  List<AdminNotification> _recentNotifications = [];
  StreamSubscription<List<AdminNotification>>? _notificationsSubscription;

  @override
  void initState() {
    super.initState();
    _setupNotificationsListener();
  }

  @override
  void dispose() {
    _notificationsSubscription?.cancel();
    super.dispose();
  }

  void _setupNotificationsListener() {
    _notificationsSubscription = _notificationService.notificationsStream.listen((notifications) {
      if (mounted) {
        setState(() {
          _recentNotifications = notifications.take(5).toList();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 900;
    final isMobile = screenWidth <= 600;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isDesktop)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Dashboard Overview',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () => setState(() {}),
                ),
              ],
            ),
          if (!isDesktop) const SizedBox(height: 16),
          _buildWelcomeHeader(isMobile),
          const SizedBox(height: 24),
          _buildQuickStats(isMobile),
          const SizedBox(height: 24),
          if (!isMobile) _buildRecentActivity(),
          if (!isMobile) const SizedBox(height: 24),
          _buildSystemHealth(isMobile),
          const SizedBox(height: 24),
          _buildRecentNotifications(isMobile),
          const SizedBox(height: 24),
          _buildQuickActions(isMobile),
        ],
      ),
    );
  }

  Widget _buildWelcomeHeader(bool isMobile) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome to Admin Dashboard',
              style: TextStyle(
                fontSize: isMobile ? 20 : 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Manage and monitor all aspects of the JengaMate platform',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontSize: isMobile ? 14 : null,
              ),
            ),
            const SizedBox(height: 16),
            StreamBuilder<Map<String, dynamic>>(
              stream: widget.analyticsService.getSystemHealth(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const LinearProgressIndicator();
                }

                final health = snapshot.data!;
                return isMobile
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHealthIndicator(
                          'System Status',
                          health['status'] == 'healthy' ? Colors.green : Colors.red,
                          (health['status']?.toString() ?? 'unknown').toUpperCase(),
                        ),
                        const SizedBox(height: 8),
                        _buildHealthIndicator(
                          'Last Updated',
                          Colors.blue,
                          _formatDateTime(health['lastUpdated']),
                        ),
                      ],
                    )
                  : Row(
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

  Widget _buildQuickStats(bool isMobile) {
    return StreamBuilder<Map<String, dynamic>>(
      stream: widget.analyticsService.getDashboardStats(),
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
            'title': 'Pending Payments',
            'value': (stats['pendingPayments'] ?? 0).toString(),
            'icon': Icons.payment,
            'color': Colors.amber,
            'route': 9, // PaymentApprovalScreen
          },
          {
            'title': 'Pending Withdrawals',
            'value': (stats['pendingWithdrawals'] ?? 0).toString(),
            'icon': Icons.payments,
            'color': Colors.deepOrange,
            'route': 12, // WithdrawalManagementScreen
          },
          {
            'title': 'Pending Referrals',
            'value': (stats['pendingReferrals'] ?? 0).toString(),
            'icon': Icons.people_outline,
            'color': Colors.pink,
            'route': 18, // ReferralManagementScreen
          },
          {
            'title': 'Active RFQs',
            'value': (stats['activeRFQs'] ?? 0).toString(),
            'icon': Icons.request_quote,
            'color': Colors.green,
            'route': 3, // RFQManagementScreen
          },
          {
            'title': 'Open Audit Items',
            'value': (stats['openAuditItems'] ?? 0).toString(),
            'icon': Icons.receipt_long,
            'color': Colors.indigo,
            'route': 15, // AuditLogScreen
          },
          {
            'title': 'Flagged Content',
            'value': (stats['flaggedContent'] ?? 0).toString(),
            'icon': Icons.flag,
            'color': Colors.red,
            'route': 2, // ContentModerationScreen
          },
        ];

        if (isMobile) {
          return Column(
            children: statCards.map((stat) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: _buildStatCard(
                  stat['title'] as String,
                  stat['value'] as String,
                  stat['icon'] as IconData,
                  stat['color'] as Color,
                  stat['route'] as int,
                  isMobile: true,
                ),
              );
            }).toList(),
          );
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: MediaQuery.of(context).size.width > 1200 ? 5 : (MediaQuery.of(context).size.width > 800 ? 4 : 2),
            childAspectRatio: 1.3,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
          ),
          itemCount: statCards.length,
          itemBuilder: (context, index) {
            final stat = statCards[index];
            return _buildStatCard(
              stat['title'] as String,
              stat['value'] as String,
              stat['icon'] as IconData,
              stat['color'] as Color,
              stat['route'] as int,
              isMobile: false,
            );
          },
        );
      },
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    int routeIndex, {
    bool isMobile = false,
  }) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: () {
          widget.onNavigate(routeIndex);
        },
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
          child: isMobile
            ? Row(
                children: [
                  Icon(icon, size: 28, color: color),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          value,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                        Text(
                          title,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: Colors.grey),
                ],
              )
            : Column(
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
              stream: widget.analyticsService.getRecentActivity(limit: 5),
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

  Widget _buildSystemHealth(bool isMobile) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'System Health',
              style: TextStyle(
                fontSize: isMobile ? 18 : 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            StreamBuilder<Map<String, dynamic>>(
              stream: widget.analyticsService.getSystemHealth(),
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
                      isMobile,
                    ),
                    _buildHealthMetric(
                      'Authentication',
                      health['authStatus'] == 'healthy',
                      health['authResponseTime'] != null ? health['authResponseTime'].toString() : 'N/A',
                      isMobile,
                    ),
                    _buildHealthMetric(
                      'Storage',
                      health['storageStatus'] == 'healthy',
                      health['storageUsage'] != null ? health['storageUsage'].toString() : 'N/A',
                      isMobile,
                    ),
                    _buildHealthMetric(
                      'API',
                      health['apiStatus'] == 'healthy',
                      health['apiResponseTime'] != null ? health['apiResponseTime'].toString() : 'N/A',
                      isMobile,
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

  Widget _buildHealthMetric(String name, bool isHealthy, String value, bool isMobile) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: isMobile ? 6.0 : 8.0),
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
          Expanded(
            child: Text(
              name,
              style: TextStyle(fontSize: isMobile ? 14 : null),
            ),
          ),
          Text(
            value,
            style: TextStyle(fontSize: isMobile ? 12 : null),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentNotifications(bool isMobile) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Notifications',
                  style: TextStyle(
                    fontSize: isMobile ? 16 : 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _showNotifications(context),
                  icon: Icon(Icons.notifications, size: isMobile ? 16 : 18),
                  label: Text(
                    'View All',
                    style: TextStyle(fontSize: isMobile ? 12 : 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_recentNotifications.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'No recent notifications',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ..._recentNotifications.map((notification) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: notification.getTypeColor().withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          notification.getTypeIcon(),
                          color: notification.getTypeColor(),
                          size: isMobile ? 16 : 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    notification.title,
                                    style: TextStyle(
                                      fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                                      fontSize: isMobile ? 13 : 14,
                                    ),
                                  ),
                                ),
                                if (!notification.isRead)
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: Colors.blue,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              notification.message,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: isMobile ? 11 : 12,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatDateTime(notification.timestamp),
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: isMobile ? 10 : 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.more_vert,
                          size: isMobile ? 16 : 18,
                          color: Colors.grey,
                        ),
                        onPressed: () => _showNotificationActions(notification),
                      ),
                    ],
                  ),
                );
              }).toList(),
          ],
        ),
      ),
    );
  }

  void _showNotificationActions(AdminNotification notification) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.check),
            title: const Text('Mark as Read'),
            onTap: () {
              Navigator.of(context).pop();
              _notificationService.markAsRead(notification.id);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete),
            title: const Text('Delete'),
            onTap: () {
              Navigator.of(context).pop();
              _notificationService.deleteNotification(notification.id);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0.0),
          child: Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: isMobile ? 18 : 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: isMobile ? 2 : (MediaQuery.of(context).size.width > 1200 ? 5 : 4),
          childAspectRatio: 1.0,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          children: [
            _buildQuickActionButton(
              'Verify Documents',
              Icons.verified_user,
              Colors.blue,
              () => widget.onNavigate(1), // DocumentVerificationScreen
              isMobile: isMobile,
            ),
            _buildQuickActionButton(
              'Moderate Content',
              Icons.policy,
              Colors.orange,
              () => widget.onNavigate(2), // ContentModerationScreen
              isMobile: isMobile,
            ),
            _buildQuickActionButton(
              'Manage RFQs',
              Icons.request_quote,
              Colors.green,
              () => widget.onNavigate(3), // RFQManagementScreen
              isMobile: isMobile,
            ),
            _buildQuickActionButton(
              'User Management',
              Icons.people,
              Colors.purple,
              () => widget.onNavigate(4), // UserManagementScreen
              isMobile: isMobile,
            ),
            _buildQuickActionButton(
              'Product Management',
              Icons.inventory,
              Colors.brown,
              () => widget.onNavigate(5), // ProductManagementScreen
              isMobile: isMobile,
            ),
            _buildQuickActionButton(
              'System Config',
              Icons.settings,
              Colors.grey,
              () => widget.onNavigate(6), // SystemConfigScreen
              isMobile: isMobile,
            ),
            _buildQuickActionButton(
              'Reports',
              Icons.analytics,
              Colors.blueGrey,
              () => widget.onNavigate(7), // ReportsScreen
              isMobile: isMobile,
            ),
            _buildQuickActionButton(
              'Analytics',
              Icons.bar_chart,
              Colors.lightBlue,
              () => widget.onNavigate(8), // AnalyticsScreen
              isMobile: isMobile,
            ),
            _buildQuickActionButton(
              'Financial Oversight',
              Icons.account_balance,
              Colors.green.shade700,
              () => widget.onNavigate(10), // FinancialOversightScreen
              isMobile: isMobile,
            ),
            _buildQuickActionButton(
              'Commission Management',
              Icons.money,
              Colors.teal.shade700,
              () => widget.onNavigate(11), // CommissionManagementScreen
              isMobile: isMobile,
            ),
            _buildQuickActionButton(
              'Bulk Operations',
              Icons.work,
              Colors.purple,
              () => widget.onNavigate(13), // BulkOperationsScreen
              isMobile: isMobile,
            ),
            _buildQuickActionButton(
              'Notifications',
              Icons.notifications,
              Colors.redAccent,
              () => widget.onNavigate(14), // NotificationsScreen
              isMobile: isMobile,
            ),
            _buildQuickActionButton(
              'Audit Logs',
              Icons.receipt_long,
              Colors.indigo,
              () => widget.onNavigate(15), // AuditLogScreen
              isMobile: isMobile,
            ),
            _buildQuickActionButton(
              'RFQ Dashboard',
              Icons.dashboard,
              Colors.orangeAccent,
              () => widget.onNavigate(16), // RfqManagementDashboard
              isMobile: isMobile,
            ),
            _buildQuickActionButton(
              'Rank Management',
              Icons.grade,
              Colors.amber.shade700,
              () => widget.onNavigate(17), // RankManagementScreen
              isMobile: isMobile,
            ),
            _buildQuickActionButton(
              'Referral Management',
              Icons.people_outline,
              Colors.pink.shade700,
              () => widget.onNavigate(18), // ReferralManagementScreen
              isMobile: isMobile,
            ),
            _buildQuickActionButton(
              'Admin Tools',
              Icons.build,
              Colors.cyan.shade700,
              () => widget.onNavigate(19), // AdminToolsScreen
              isMobile: isMobile,
            ),
            _buildQuickActionButton(
              'Payment Approvals',
              Icons.verified,
              Colors.green,
              () => widget.onNavigate(9), // PaymentApprovalScreen
              isMobile: isMobile,
            ),
            _buildQuickActionButton(
              'Withdrawal Approvals',
              Icons.money_off,
              Colors.deepOrange,
              () => widget.onNavigate(12), // WithdrawalManagementScreen
              isMobile: isMobile,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionButton(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap, {
    bool isMobile = false,
  }) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: isMobile ? 32 : 40, color: color),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isMobile ? 12 : 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
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

  void _showNotifications(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const NotificationsScreen(),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import 'package:jengamate/screens/admin/advanced_reporting_screen.dart';
import 'package:jengamate/screens/admin/commission_rules_screen.dart';
import 'package:jengamate/screens/admin/commission_tracking_screen.dart';
import 'package:jengamate/screens/admin/content_moderation_screen.dart';
import 'package:jengamate/screens/admin/enhanced_analytics_dashboard.dart';
import 'package:jengamate/screens/admin/enhanced_user_management_screen.dart';
import 'package:jengamate/screens/admin/financial_oversight_screen.dart';
import 'package:jengamate/screens/admin/rfq_management_dashboard.dart';

import 'package:jengamate/screens/admin/system_configuration_screen.dart';
import 'package:jengamate/screens/admin/withdrawal_management_screen.dart';

class AdminScaffold extends StatefulWidget {
  const AdminScaffold({super.key});

  @override
  State<AdminScaffold> createState() => _AdminScaffoldState();
}

class _AdminScaffoldState extends State<AdminScaffold> {
  int _selectedIndex = 0;

  static const List<Widget> _widgetOptions = <Widget>[
    EnhancedAnalyticsDashboard(),
    EnhancedUserManagementScreen(),
    WithdrawalManagementScreen(),
    SystemConfigurationScreen(),
    ContentModerationScreen(),
    FinancialOversightScreen(),
    AdvancedReportingScreen(),
    CommissionRulesScreen(),
    CommissionTrackingScreen(),
    RfqManagementDashboard(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar Navigation for larger screens
          if (MediaQuery.of(context).size.width > 600)
            NavigationRail(
              selectedIndex: _selectedIndex,
              onDestinationSelected: _onItemTapped,
              labelType: NavigationRailLabelType.all,
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.analytics),
                  label: Text('Analytics'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.people),
                  label: Text('Users'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.money),
                  label: Text('Withdrawals'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.settings),
                  label: Text('Settings'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.policy),
                  label: Text('Moderation'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.attach_money),
                  label: Text('Financial'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.report),
                  label: Text('Reporting'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.star),
                  label: Text('Commission Rules'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.track_changes),
                  label: Text('Commission Tracking'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.request_quote),
                  label: Text('RFQs'),
                ),
              ],
            ),
          // Main content area
          Expanded(
            child: _widgetOptions.elementAt(_selectedIndex),
          ),
        ],
      ),
      // Bottom navigation for smaller screens
      bottomNavigationBar: MediaQuery.of(context).size.width <= 600
          ? BottomNavigationBar(
              items: const <BottomNavigationBarItem>[
                BottomNavigationBarItem(
                  icon: Icon(Icons.analytics),
                  label: 'Analytics',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.people),
                  label: 'Users',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.money),
                  label: 'Withdrawals',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.settings),
                  label: 'Settings',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.policy),
                  label: 'Moderation',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.attach_money),
                  label: 'Financial',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.report),
                  label: 'Reporting',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.star),
                  label: 'Commission Rules',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.track_changes),
                  label: 'Commission Tracking',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.request_quote),
                  label: 'RFQs',
                ),
              ],
              currentIndex: _selectedIndex,
              selectedItemColor: Theme.of(context).primaryColor,
              onTap: _onItemTapped,
              type: BottomNavigationBarType.fixed,
            )
          : null,
    );
  }
}
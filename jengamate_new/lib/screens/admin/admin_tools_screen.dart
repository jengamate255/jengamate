import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:jengamate/config/app_routes.dart';
import 'package:provider/provider.dart';
import 'package:jengamate/services/tier_metadata_service.dart';
import 'package:jengamate/screens/admin/providers/admin_metrics_provider.dart';
import 'package:jengamate/screens/admin/image_migration_screen.dart';

class AdminToolsScreen extends StatelessWidget {
  final AdminMetricsProvider? _providedMetrics;
  final bool _autoRefresh;

  const AdminToolsScreen({super.key})
      : _providedMetrics = null,
        _autoRefresh = true;

  const AdminToolsScreen.withProvider(this._providedMetrics,
      {super.key, bool autoRefresh = false})
      : _autoRefresh = autoRefresh;

  int _calculateCrossAxisCount(double width) {
    if (width < 600) return 1; // phones
    if (width < 1000) return 2; // small/medium tablets
    return 3; // large tablets / desktop
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> adminToolsFor(AdminMetricsProvider m) => [
          {
            'title': 'Financial Oversight',
            'icon': Icons.monetization_on,
            'routeName': 'adminFinancialOversight',
            'badgeCount': m.openAuditItems,
          },
          {
            'title': 'User Management',
            'icon': Icons.people,
            'routeName': 'adminUserManagement',
            'badgeCount': m.pendingUserApprovals,
          },
          {
            'title': 'Withdrawal Management',
            'icon': Icons.account_balance_wallet,
            'routeName': 'adminWithdrawalManagement',
            'badgeCount': m.pendingWithdrawals,
          },
          {
            'title': 'Referral Management',
            'icon': Icons.group,
            'routeName': 'adminReferralManagement',
            'badgeCount': m.pendingReferrals,
          },
          {
            'title': 'Product Management',
            'icon': Icons.store,
            'routeName': 'adminProductManagement',
          },
          {
            'title': 'Category Management',
            'icon': Icons.category,
            'routeName': 'adminCategoryManagement',
          },
          {
            'title': 'Analytics & Reporting',
            'icon': Icons.analytics,
            'routeName': 'adminAnalyticsReporting',
          },
          {
            'title': 'Commission Tools',
            'icon': Icons.attach_money,
            'routeName': 'adminCommissionTools',
          },
          {
            'title': 'RFQ Management',
            'icon': Icons.request_quote,
            'route': '/rfq-management-dashboard',
          },
          {
            'title': 'RFQ Analytics',
            'icon': Icons.analytics,
            'route': '/rfq-analytics-dashboard',
          },
          {
            'title': 'Commission Tiers',
            'icon': Icons.stacked_bar_chart,
            'routeName': 'adminCommissionTiers',
          },
          {
            'title': 'Add/Edit Product',
            'icon': Icons.add_business,
            'route': AppRoutes.addEditProduct,
          },
          {
            'title': 'Financial Dashboard',
            'icon': Icons.account_balance,
            'route': '/financial-dashboard',
          },
          {
            'title': 'System Settings',
            'icon': Icons.settings,
            'route': '/system-settings',
          },
          {
            'title': 'Advanced Analytics',
            'icon': Icons.bar_chart,
            'route': '/advanced-analytics',
          },
          {
            'title': 'Image Migration',
            'icon': Icons.image,
            'widget': const ImageMigrationScreen(),
          },
          {
            'title': 'Audit Logs',
            'icon': Icons.history,
            'route': '/enhanced-audit-logs',
          },
          {
            'title': 'Commission Tiers',
            'icon': Icons.layers,
            'route': '/commission-tier-management',
          },
          {
            'title': 'Content Moderation',
            'icon': Icons.policy,
            'route': '/content-moderation',
          },
          {
            'title': 'Support Management',
            'icon': Icons.support_agent,
            'route': '/admin-support',
          },
        ];

    return ChangeNotifierProvider<AdminMetricsProvider>(
      create: (_) {
        final provider = _providedMetrics ?? AdminMetricsProvider();
        if (_autoRefresh) provider.startAutoRefresh();
        return provider;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin Dashboard'),
          centerTitle: true,
        ),
        body: Consumer<AdminMetricsProvider>(
          builder: (context, metrics, _) {
            final adminTools = adminToolsFor(metrics);
            return Column(
              children: [
                const _PreloadTierMeta(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: _KpiRow(metrics: metrics),
                ),
                if (metrics.error != null)
                  Container(
                    width: double.infinity,
                    color: Colors.red.withValues(alpha: 0.1),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Failed to load some metrics. Tap retry.',
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                        TextButton(
                          onPressed: metrics.fetchOnce,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final crossAxisCount =
                          _calculateCrossAxisCount(constraints.maxWidth);
                      final grid = GridView.builder(
                        padding: const EdgeInsets.all(16.0),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 16.0,
                          mainAxisSpacing: 16.0,
                          childAspectRatio: 1.2,
                        ),
                        itemCount: metrics.loading ? 5 : adminTools.length,
                        itemBuilder: (context, index) {
                          if (metrics.loading) {
                            return const _SkeletonToolCard();
                          }
                          final tool = adminTools[index];
                          final int? badgeCount = tool['badgeCount'];
                          return _AdminToolCard(
                            title: tool['title'],
                            icon: tool['icon'],
                            onTap: () {
                              if (tool.containsKey('routeName')) {
                                context.goNamed(tool['routeName']);
                              } else {
                                context.go(tool['route']);
                              }
                            },
                            badgeCount: badgeCount,
                          );
                        },
                      );
                      return RefreshIndicator(
                        onRefresh: metrics.fetchOnce,
                        child: grid,
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PreloadTierMeta extends StatefulWidget {
  const _PreloadTierMeta();
  @override
  State<_PreloadTierMeta> createState() => _PreloadTierMetaState();
}

class _PreloadTierMetaState extends State<_PreloadTierMeta> {
  @override
  void initState() {
    super.initState();
    // Fire and forget; result cached for later consumers
    TierMetadataService.instance.loadAll();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class _SkeletonToolCard extends StatelessWidget {
  const _SkeletonToolCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: 120,
              height: 14,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KpiRow extends StatelessWidget {
  final AdminMetricsProvider metrics;
  const _KpiRow({required this.metrics});

  @override
  Widget build(BuildContext context) {
    final items = <_KpiItem>[
      _KpiItem(
          label: 'Pending Withdrawals',
          value: metrics.pendingWithdrawals,
          icon: Icons.account_balance_wallet),
      _KpiItem(
          label: 'Pending Referrals',
          value: metrics.pendingReferrals,
          icon: Icons.group_add),
      _KpiItem(
          label: 'Open Audit Items',
          value: metrics.openAuditItems,
          icon: Icons.fact_check),
      _KpiItem(
          label: 'User Approvals',
          value: metrics.pendingUserApprovals,
          icon: Icons.verified_user),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 600;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children:
              items.map((i) => _KpiTile(item: i, compact: isNarrow)).toList(),
        );
      },
    );
  }
}

class _KpiItem {
  final String label;
  final int value;
  final IconData icon;
  _KpiItem({required this.label, required this.value, required this.icon});
}

class _KpiTile extends StatelessWidget {
  final _KpiItem item;
  final bool compact;
  const _KpiTile({required this.item, required this.compact});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      constraints: BoxConstraints(minWidth: compact ? 140 : 200),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(item.icon, color: theme.colorScheme.primary),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(item.label, style: theme.textTheme.labelMedium),
              Text(
                item.value.toString(),
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AdminToolCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final int? badgeCount;

  const _AdminToolCard({
    required this.title,
    required this.icon,
    required this.onTap,
    this.badgeCount,
  });

  @override
  Widget build(BuildContext context) {
    final showBadge = (badgeCount ?? 0) > 0;
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 48, color: Theme.of(context).primaryColor),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            if (showBadge)
              Positioned(
                right: 12,
                top: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    badgeCount!.toString(),
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

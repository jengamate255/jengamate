import 'package:jengamate/models/commission_tier_model.dart';
import 'package:flutter/material.dart';
import 'package:jengamate/models/user_model.dart';
import 'package:jengamate/services/database_service.dart';
import 'package:jengamate/utils/responsive.dart';
import 'package:jengamate/utils/logger.dart';
import 'package:intl/intl.dart';

class CommissionTierManagementScreen extends StatefulWidget {
  const CommissionTierManagementScreen({super.key});

  @override
  State<CommissionTierManagementScreen> createState() =>
      _CommissionTierManagementScreenState();
}

class _CommissionTierManagementScreenState
    extends State<CommissionTierManagementScreen>
    with TickerProviderStateMixin {
  final DatabaseService _databaseService = DatabaseService();
  late TabController _tabController;

  List<CommissionTier> _tiers = [];
  List<UserModel> _usersInTiers = [];
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadTierData();
  }

  Future<void> _loadTierData() async {
    setState(() => _isLoading = true);
    try {
      final dbService = DatabaseService();

      // Load real commission tiers from database
      _tiers = await dbService.getCommissionTiers();

      // Load users with their tier information
      _usersInTiers = await dbService.getUsersWithTierInfo();

      Logger.log(
          'Loaded ${_tiers.length} commission tiers and ${_usersInTiers.length} users');
    } catch (e) {
      Logger.logError('Error loading tier data', e, StackTrace.current);
      // Set empty lists instead of fallback sample data
      _tiers = [];
      _usersInTiers = [];

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load commission tier data: $e'),
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
        title: const Text('Commission Tier Management'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTierData,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddTierDialog,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Tiers', icon: Icon(Icons.layers)),
            Tab(text: 'Users', icon: Icon(Icons.people)),
            Tab(text: 'Analytics', icon: Icon(Icons.analytics)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildTiersTab(),
                _buildUsersTab(),
                _buildAnalyticsTab(),
              ],
            ),
    );
  }

  Widget _buildTiersTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Commission Tiers Overview'),
          const SizedBox(height: 16),
          _buildTiersList(),
          const SizedBox(height: 24),
          _buildTierProgressionChart(),
        ],
      ),
    );
  }

  Widget _buildUsersTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Users by Tier'),
          const SizedBox(height: 16),
          _buildUserDistributionCards(),
          const SizedBox(height: 24),
          _buildUsersList(),
        ],
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Tier Performance Analytics'),
          const SizedBox(height: 16),
          _buildPerformanceMetrics(),
          const SizedBox(height: 24),
          _buildTierEffectivenessChart(),
          const SizedBox(height: 24),
          _buildPromotionHistory(),
        ],
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

  Widget _buildTiersList() {
    return Column(
      children: _tiers.map((tier) => _buildTierCard(tier)).toList(),
    );
  }

  Widget _buildTierCard(CommissionTier tier) {
    final tierColor = Color(int.parse(tier.color.replaceFirst('#', '0xFF')));

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: tierColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      tier.level.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tier.name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: tierColor,
                            ),
                      ),
                      Text(
                        '${(tier.commissionRate * 100).toStringAsFixed(1)}% Commission',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: tier.isActive,
                  onChanged: (value) => _toggleTierStatus(tier, value),
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _showEditTierDialog(tier),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Responsive.isMobile(context)
                ? Column(children: _buildTierDetails(tier))
                : Row(children: _buildTierDetails(tier)),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildTierDetails(CommissionTier tier) {
    return [
      Expanded(
        child: _buildDetailSection(
          'Sales Range',
          tier.maxSales == double.infinity
              ? '\$${NumberFormat('#,##0').format(tier.minSales)}+'
              : '\$${NumberFormat('#,##0').format(tier.minSales)} - \$${NumberFormat('#,##0').format(tier.maxSales)}',
          Icons.trending_up,
        ),
      ),
      const SizedBox(width: 16, height: 8),
      Expanded(
        child: _buildDetailSection(
          'Bonus',
          tier.bonusAmount > 0
              ? '\$${tier.bonusAmount.toStringAsFixed(0)}'
              : 'None',
          Icons.card_giftcard,
        ),
      ),
      const SizedBox(width: 16, height: 8),
      Expanded(
        child: _buildDetailSection(
          'Requirements',
          '${tier.requirements.length} items',
          Icons.checklist,
        ),
      ),
    ];
  }

  Widget _buildDetailSection(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: Theme.of(context).primaryColor),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTierProgressionChart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tier Progression Path',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _tiers.length,
                itemBuilder: (context, index) {
                  final tier = _tiers[index];
                  final tierColor =
                      Color(int.parse(tier.color.replaceFirst('#', '0xFF')));

                  return Row(
                    children: [
                      Column(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: tierColor,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                tier.name[0],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            tier.name,
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      if (index < _tiers.length - 1) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward, color: Colors.grey),
                        const SizedBox(width: 8),
                      ],
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserDistributionCards() {
    return Responsive.isMobile(context)
        ? Column(children: _buildDistributionCardsList())
        : Wrap(
            spacing: Responsive.getResponsiveSpacing(context),
            runSpacing: Responsive.getResponsiveSpacing(context),
            children: _buildDistributionCardsList()
                .map((card) => SizedBox(
                    width: Responsive.getResponsiveCardWidth(context),
                    child: card))
                .toList(),
          );
  }

  List<Widget> _buildDistributionCardsList() {
    return _tiers.map((tier) {
      final tierColor = Color(int.parse(tier.color.replaceFirst('#', '0xFF')));
      final userCount = _getUserCountForTier(tier.name);

      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(Icons.people, color: tierColor, size: 32),
              const SizedBox(height: 8),
              Text(
                userCount.toString(),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: tierColor,
                ),
              ),
              Text(
                tier.name,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  int _getUserCountForTier(String tierName) {
    // Sample data - in real app, this would come from database
    switch (tierName) {
      case 'Bronze':
        return 45;
      case 'Silver':
        return 23;
      case 'Gold':
        return 12;
      case 'Platinum':
        return 5;
      case 'Diamond':
        return 2;
      default:
        return 0;
    }
  }

  Widget _buildUsersList() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Tier Changes',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...List.generate(5, (index) {
              final users = [
                'John Doe',
                'Jane Smith',
                'Bob Wilson',
                'Alice Johnson',
                'Charlie Brown'
              ];
              final tiers = ['Silver', 'Gold', 'Bronze', 'Platinum', 'Silver'];
              final changes = [
                'Promoted',
                'Promoted',
                'New',
                'Promoted',
                'Promoted'
              ];

              return ListTile(
                leading: CircleAvatar(
                  child: Text(users[index][0]),
                ),
                title: Text(users[index]),
                subtitle: Text('${changes[index]} to ${tiers[index]}'),
                trailing: Text(
                  '${index + 1}d ago',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceMetrics() {
    return Responsive.isMobile(context)
        ? Column(children: _buildMetricCardsList())
        : Row(
            children: _buildMetricCardsList()
                .map((card) => Expanded(child: card))
                .toList());
  }

  List<Widget> _buildMetricCardsList() {
    return [
      _buildMetricCard(
          'Avg. Promotion Time', '45 days', Icons.schedule, Colors.blue),
      const SizedBox(width: 16, height: 8),
      _buildMetricCard('Top Tier Users', '7 users', Icons.star, Colors.amber),
      const SizedBox(width: 16, height: 8),
      _buildMetricCard(
          'Monthly Promotions', '12 users', Icons.trending_up, Colors.green),
      const SizedBox(width: 16, height: 8),
      _buildMetricCard('Tier Retention', '89%', Icons.loyalty, Colors.purple),
    ];
  }

  Widget _buildMetricCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
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
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTierEffectivenessChart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tier Effectiveness',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...['Bronze', 'Silver', 'Gold', 'Platinum', 'Diamond'].map((tier) {
              final effectiveness = _getTierEffectiveness(tier);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    SizedBox(width: 80, child: Text(tier)),
                    Expanded(
                      child: LinearProgressIndicator(
                        value: effectiveness / 100,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _getTierColor(tier),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('${effectiveness.toStringAsFixed(0)}%'),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  double _getTierEffectiveness(String tier) {
    // Sample effectiveness data
    switch (tier) {
      case 'Bronze':
        return 75;
      case 'Silver':
        return 85;
      case 'Gold':
        return 92;
      case 'Platinum':
        return 88;
      case 'Diamond':
        return 95;
      default:
        return 0;
    }
  }

  Color _getTierColor(String tier) {
    switch (tier) {
      case 'Bronze':
        return const Color(0xFFCD7F32);
      case 'Silver':
        return const Color(0xFFC0C0C0);
      case 'Gold':
        return const Color(0xFFFFD700);
      case 'Platinum':
        return const Color(0xFFE5E4E2);
      case 'Diamond':
        return const Color(0xFFB9F2FF);
      default:
        return Colors.grey;
    }
  }

  Widget _buildPromotionHistory() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Promotions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...List.generate(3, (index) {
              final promotions = [
                {
                  'user': 'John Doe',
                  'from': 'Silver',
                  'to': 'Gold',
                  'date': '2 days ago'
                },
                {
                  'user': 'Jane Smith',
                  'from': 'Bronze',
                  'to': 'Silver',
                  'date': '5 days ago'
                },
                {
                  'user': 'Bob Wilson',
                  'from': 'Gold',
                  'to': 'Platinum',
                  'date': '1 week ago'
                },
              ];

              final promo = promotions[index];
              return ListTile(
                leading: const Icon(Icons.trending_up, color: Colors.green),
                title: Text(promo['user']!),
                subtitle: Text('${promo['from']} → ${promo['to']}'),
                trailing: Text(promo['date']!),
              );
            }),
          ],
        ),
      ),
    );
  }

  void _toggleTierStatus(CommissionTier tier, bool isActive) {
    setState(() {
      final idx = _tiers.indexWhere((t) => t.uid == tier.uid);
      if (idx != -1) {
        _tiers[idx] = _tiers[idx].copyWith(isActive: isActive);
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text('${tier.name} tier ${isActive ? 'activated' : 'deactivated'}'),
      ),
    );
  }

  void _showAddTierDialog() {
    _showTierDialog(null);
  }

  void _showEditTierDialog(CommissionTier tier) {
    _showTierDialog(tier);
  }

  void _showTierDialog(CommissionTier? tier) {
    final isEditing = tier != null;
    final nameController = TextEditingController(text: tier?.name ?? '');
    final levelController =
        TextEditingController(text: tier?.level.toString() ?? '');
    final minSalesController =
        TextEditingController(text: tier?.minSales.toString() ?? '');
    final maxSalesController =
        TextEditingController(text: tier?.maxSales.toString() ?? '');
    final commissionController = TextEditingController(
        text: ((tier?.commissionRate ?? 0) * 100).toString());
    final bonusController =
        TextEditingController(text: tier?.bonusAmount.toString() ?? '0');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'Edit Tier' : 'Add New Tier'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Tier Name'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: levelController,
                decoration: const InputDecoration(labelText: 'Level'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: minSalesController,
                decoration: const InputDecoration(labelText: 'Minimum Sales'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: maxSalesController,
                decoration: const InputDecoration(labelText: 'Maximum Sales'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: commissionController,
                decoration:
                    const InputDecoration(labelText: 'Commission Rate (%)'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: bonusController,
                decoration: const InputDecoration(labelText: 'Bonus Amount'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(
                        'Tier ${isEditing ? 'updated' : 'created'} successfully')),
              );
            },
            child: Text(isEditing ? 'Update' : 'Create'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

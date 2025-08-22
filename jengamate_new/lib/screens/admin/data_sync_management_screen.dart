import 'package:flutter/material.dart';
import 'package:jengamate/services/data_sync_service.dart';
import 'package:jengamate/services/dynamic_data_service.dart';
import 'package:jengamate/utils/logger.dart';
import 'package:jengamate/widgets/admin_scaffold.dart';
import 'package:intl/intl.dart';

class DataSyncManagementScreen extends StatefulWidget {
  const DataSyncManagementScreen({super.key});

  @override
  State<DataSyncManagementScreen> createState() => _DataSyncManagementScreenState();
}

class _DataSyncManagementScreenState extends State<DataSyncManagementScreen> {
  final DataSyncService _dataSyncService = DataSyncService();
  final DynamicDataService _dynamicDataService = DynamicDataService();
  
  bool _isLoading = false;
  bool _isSyncNeeded = false;
  DateTime? _lastSyncTime;
  Map<String, dynamic> _systemConfig = {};
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _commissionTiers = [];

  @override
  void initState() {
    super.initState();
    _loadSyncStatus();
  }

  Future<void> _loadSyncStatus() async {
    setState(() => _isLoading = true);
    
    try {
      // Check if sync is needed
      _isSyncNeeded = await _dataSyncService.isSyncNeeded();
      
      // Get system configuration
      final config = await _dataSyncService.getSystemConfig();
      if (config != null) {
        _systemConfig = config;
        _lastSyncTime = config['last_sync']?.toDate();
      }
      
      // Get categories
      _categories = await _dynamicDataService.getCategories();
      
      // Get commission tiers
      final engineerTiers = await _dynamicDataService.getCommissionTiers('engineer');
      final supplierTiers = await _dynamicDataService.getCommissionTiers('supplier');
      _commissionTiers = [...engineerTiers, ...supplierTiers];
      
    } catch (e, s) {
      Logger.logError('Error loading sync status', e, s);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading sync status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _performSync() async {
    setState(() => _isLoading = true);
    
    try {
      await _dataSyncService.syncAllData();
      await _loadSyncStatus();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data synchronization completed successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e, s) {
      Logger.logError('Error during sync', e, s);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sync failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _forceRefresh() async {
    setState(() => _isLoading = true);
    
    try {
      await _dynamicDataService.forceRefresh();
      await _loadSyncStatus();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Force refresh completed successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e, s) {
      Logger.logError('Error during force refresh', e, s);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Force refresh failed: $e'),
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
    return AdminScaffold(
      title: 'Data Sync Management',
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSyncStatusCard(),
                  const SizedBox(height: 16),
                  _buildSyncActionsCard(),
                  const SizedBox(height: 16),
                  _buildSystemConfigCard(),
                  const SizedBox(height: 16),
                  _buildCategoriesCard(),
                  const SizedBox(height: 16),
                  _buildCommissionTiersCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildSyncStatusCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _isSyncNeeded ? Icons.warning : Icons.check_circle,
                  color: _isSyncNeeded ? Colors.orange : Colors.green,
                ),
                const SizedBox(width: 8),
                Text(
                  'Sync Status',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Status:',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        _isSyncNeeded ? 'Sync Needed' : 'Up to Date',
                        style: TextStyle(
                          color: _isSyncNeeded ? Colors.orange : Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Last Sync:',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        _lastSyncTime != null
                            ? DateFormat('MMM dd, yyyy HH:mm').format(_lastSyncTime!)
                            : 'Never',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSyncActionsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sync Actions',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _performSync,
                    icon: const Icon(Icons.sync),
                    label: const Text('Sync Data'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _forceRefresh,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Force Refresh'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
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

  Widget _buildSystemConfigCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'System Configuration',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildConfigItem('Order Statuses', _systemConfig['order_statuses'] ?? []),
            _buildConfigItem('Inquiry Statuses', _systemConfig['inquiry_statuses'] ?? []),
            _buildConfigItem('Priorities', _systemConfig['priorities'] ?? []),
            _buildConfigItem('Content Types', _systemConfig['content_types'] ?? []),
            _buildConfigItem('Severity Levels', _systemConfig['severity_levels'] ?? []),
            _buildConfigItem('RFQ Statuses', _systemConfig['rfq_statuses'] ?? []),
            _buildConfigItem('RFQ Types', _systemConfig['rfq_types'] ?? []),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigItem(String label, List<dynamic> items) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label (${items.length}):',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Wrap(
            spacing: 8,
            children: items.map((item) => Chip(
              label: Text(item.toString()),
              backgroundColor: Colors.blue.shade100,
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Categories (${_categories.length})',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categories.map((category) => Chip(
                label: Text(category['name'] ?? 'Unknown'),
                backgroundColor: Colors.green.shade100,
                deleteIcon: const Icon(Icons.category),
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommissionTiersCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Commission Tiers (${_commissionTiers.length})',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _commissionTiers.map((tier) => Chip(
                label: Text('${tier['role']} - ${tier['name']}'),
                backgroundColor: Colors.purple.shade100,
                deleteIcon: const Icon(Icons.star),
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
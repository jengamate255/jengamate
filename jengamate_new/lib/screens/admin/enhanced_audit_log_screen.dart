import 'package:flutter/material.dart';
import 'package:jengamate/models/audit_log_model.dart';
import 'package:jengamate/services/database_service.dart';
import 'package:jengamate/utils/responsive.dart';
import 'package:jengamate/utils/logger.dart';
// Removed populate_audit_logs import - using real data only
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EnhancedAuditLogScreen extends StatefulWidget {
  const EnhancedAuditLogScreen({super.key});

  @override
  State<EnhancedAuditLogScreen> createState() => _EnhancedAuditLogScreenState();
}

class _EnhancedAuditLogScreenState extends State<EnhancedAuditLogScreen> {
  final DatabaseService _databaseService = DatabaseService();
  List<AuditLogModel> _auditLogs = [];
  List<AuditLogModel> _filteredLogs = [];
  bool _isLoading = true;
  
  final TextEditingController _searchController = TextEditingController();
  String _selectedAction = 'all';
  String _selectedUser = 'all';
  DateTimeRange? _dateRange;
  
  final List<String> _actionTypes = [
    'all', 'login', 'logout', 'create', 'update', 'delete', 
    'approve', 'reject', 'payment', 'withdrawal', 'system'
  ];

  @override
  void initState() {
    super.initState();
    _loadAuditLogs();
  }

  Future<void> _loadAuditLogs() async {
    setState(() => _isLoading = true);
    try {
      final dbService = DatabaseService();

      // Load real audit logs from database
      final auditData = await dbService.getAuditLogs();
      _auditLogs = auditData.map((data) => AuditLogModel(
        id: data['id'] ?? '',
        actorId: data['actorId'] ?? '',
        actorName: data['actorName'] ?? 'Unknown User',
        targetUserId: data['targetUserId'] ?? '',
        targetUserName: data['targetUserName'] ?? 'Unknown User',
        action: data['action'] ?? 'unknown',
        details: Map<String, dynamic>.from(data['details'] ?? {}),
        timestamp: data['timestamp'] ?? Timestamp.now(),
      )).toList();

      _applyFilters();
      Logger.log('Loaded ${_auditLogs.length} audit log entries');
    } catch (e) {
      Logger.logError('Error loading audit logs', e, StackTrace.current);
      // Set empty list instead of fallback sample data
      _auditLogs = [];
      _applyFilters();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load audit logs: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }



  void _applyFilters() {
    _filteredLogs = _auditLogs.where((log) {
      // Search filter
      if (_searchController.text.isNotEmpty) {
        final searchTerm = _searchController.text.toLowerCase();
        if (!log.actorName.toLowerCase().contains(searchTerm) &&
            !log.action.toLowerCase().contains(searchTerm) &&
            !(log.details?['resource']?.toString().toLowerCase().contains(searchTerm) ?? false) &&
            !(log.details?['message']?.toString().toLowerCase().contains(searchTerm) ?? false)) {
          return false;
        }
      }
      
      // Action filter
      if (_selectedAction != 'all' && log.action != _selectedAction) {
        return false;
      }
      
      // User filter
      if (_selectedUser != 'all' && log.actorId != _selectedUser && log.targetUserId != _selectedUser) {
        return false;
      }
      
      // Date range filter
      if (_dateRange != null) {
        final logDate = log.timestamp.toDate();
        if (logDate.isBefore(_dateRange!.start) ||
            logDate.isAfter(_dateRange!.end)) {
          return false;
        }
      }
      
      return true;
    }).toList();
    
    // Sort by timestamp (newest first)
    _filteredLogs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('System Audit Logs'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAuditLogs,
          ),
          // Removed test data population - using real audit logs only
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _exportLogs,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildFiltersSection(),
                _buildStatsBar(),
                Expanded(child: _buildLogsList()),
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
            // Search bar
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search logs...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _applyFilters());
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (value) => setState(() => _applyFilters()),
            ),
            const SizedBox(height: 16),
            // Filter chips
            Responsive.isMobile(context)
                ? Column(children: _buildFilterRows())
                : Row(children: _buildFilterRows()),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildFilterRows() {
    return [
      Expanded(
        child: DropdownButtonFormField<String>(
          value: _selectedAction,
          decoration: const InputDecoration(
            labelText: 'Action Type',
            border: OutlineInputBorder(),
          ),
          items: _actionTypes.map((action) {
            return DropdownMenuItem(
              value: action,
              child: Text(action == 'all' ? 'All Actions' : action.toUpperCase()),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedAction = value!;
              _applyFilters();
            });
          },
        ),
      ),
      const SizedBox(width: 16, height: 16),
      Expanded(
        child: OutlinedButton.icon(
          onPressed: _selectDateRange,
          icon: const Icon(Icons.date_range),
          label: Text(_dateRange == null 
              ? 'Select Date Range' 
              : '${DateFormat('M/d').format(_dateRange!.start)} - ${DateFormat('M/d').format(_dateRange!.end)}'),
        ),
      ),
    ];
  }

  Widget _buildStatsBar() {
    final totalLogs = _auditLogs.length;
    final filteredCount = _filteredLogs.length;
    final todayLogs = _auditLogs.where((log) {
      final today = DateTime.now();
      final logDate = log.timestamp.toDate();
      return logDate.year == today.year &&
             logDate.month == today.month &&
             logDate.day == today.day;
    }).length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Total', totalLogs.toString()),
          _buildStatItem('Filtered', filteredCount.toString()),
          _buildStatItem('Today', todayLogs.toString()),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildLogsList() {
    if (_filteredLogs.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No audit logs found', style: TextStyle(fontSize: 18, color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredLogs.length,
      itemBuilder: (context, index) {
        final log = _filteredLogs[index];
        return _buildLogCard(log);
      },
    );
  }

  Widget _buildLogCard(AuditLogModel log) {
    final actionColor = _getActionColor(log.action);
    final actionIcon = _getActionIcon(log.action);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: actionColor.withValues(alpha: 0.2),
          child: Icon(actionIcon, color: actionColor, size: 20),
        ),
        title: Text(
          '${log.actorName} - ${log.action.toUpperCase()}',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(log.details?['message']?.toString() ?? 'No details available'),
            const SizedBox(height: 4),
            Text(
              DateFormat('MMM dd, yyyy HH:mm:ss').format(log.timestamp.toDate()),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        trailing: _buildSeverityChip(log.action),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('Actor ID', log.actorId),
                _buildDetailRow('Resource', '${log.details?['resource']}:${log.details?['resourceId']}'),
                _buildDetailRow('Timestamp', DateFormat('yyyy-MM-dd HH:mm:ss').format(log.timestamp.toDate())),
                if (log.details != null)
                  _buildDetailRow('Full Details', log.details!.toString()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
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
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
  }

  Color _getActionColor(String action) {
    switch (action.toLowerCase()) {
      case 'login':
      case 'approve':
        return Colors.green;
      case 'logout':
      case 'delete':
      case 'reject':
        return Colors.red;
      case 'create':
      case 'payment':
        return Colors.blue;
      case 'update':
        return Colors.orange;
      case 'system':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getActionIcon(String action) {
    switch (action.toLowerCase()) {
      case 'login':
        return Icons.login;
      case 'logout':
        return Icons.logout;
      case 'create':
        return Icons.add;
      case 'update':
        return Icons.edit;
      case 'delete':
        return Icons.delete;
      case 'approve':
        return Icons.check_circle;
      case 'reject':
        return Icons.cancel;
      case 'payment':
        return Icons.payment;
      case 'withdrawal':
        return Icons.account_balance_wallet;
      case 'system':
        return Icons.settings;
      default:
        return Icons.info;
    }
  }

  Widget _buildSeverityChip(String action) {
    String severity;
    Color color;
    
    switch (action.toLowerCase()) {
      case 'delete':
      case 'reject':
        severity = 'HIGH';
        color = Colors.red;
        break;
      case 'approve':
      case 'payment':
      case 'withdrawal':
        severity = 'MEDIUM';
        color = Colors.orange;
        break;
      default:
        severity = 'LOW';
        color = Colors.green;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        severity,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
    );
    
    if (picked != null) {
      setState(() {
        _dateRange = picked;
        _applyFilters();
      });
    }
  }

  void _exportLogs() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Logs'),
        content: const Text('Export functionality will be implemented soon. This will allow you to export audit logs in CSV or JSON format.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // Removed test data population method - using real audit logs only

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

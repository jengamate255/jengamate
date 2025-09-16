import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jengamate/services/user_state_provider.dart';
import 'package:jengamate/services/audit_service.dart';
import 'package:jengamate/models/audit_log_model.dart';
import 'package:intl/intl.dart';

class AuditLogScreen extends StatefulWidget {
  const AuditLogScreen({super.key});

  @override
  State<AuditLogScreen> createState() => _AuditLogScreenState();
}

class _AuditLogScreenState extends State<AuditLogScreen> {
  String _selectedFilter = 'All';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auditService = Provider.of<AuditService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Audit Logs'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search logs...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 16),
                _buildFilterChips(),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<AuditLogModel>>(
              stream: auditService.streamAuditLogs(limit: 100), // Adjust limit as needed
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No audit logs found.'));
                }

                final allLogs = snapshot.data!;
                final filteredLogs = allLogs.where((log) {
                  final lowerCaseQuery = _searchController.text.toLowerCase();
                  final logDetails = '${log.action} ${log.actorName} ${log.targetName} ${log.details}'.toLowerCase();

                  if (_selectedFilter != 'All' && log.action != _selectedFilter) {
                    return false;
                  }
                  if (lowerCaseQuery.isNotEmpty && !logDetails.contains(lowerCaseQuery)) {
                    return false;
                  }
                  return true;
                }).toList();

                if (filteredLogs.isEmpty) {
                  return const Center(child: Text('No matching audit logs found.'));
                }

                return ListView.builder(
                  itemCount: filteredLogs.length,
                  itemBuilder: (context, index) {
                    final log = filteredLogs[index];
                    return AuditLogCard(log: log);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final List<String> filters = ['All', 'LOGIN', 'LOGOUT', 'CREATE_ORDER', 'UPDATE_ORDER', 'UPDATE_ORDER_STATUS', 'CREATE_USER', 'UPDATE_USER', 'DELETE_USER', 'PASSWORD_RESET_REQUEST', 'CREATE_PAYMENT'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Wrap(
        spacing: 8.0,
        children: filters.map((filter) {
          return FilterChip(
            label: Text(filter.replaceAll('_', ' ').toCapitalized()),
            selected: _selectedFilter == filter,
            onSelected: (selected) {
              setState(() {
                _selectedFilter = selected ? filter : 'All';
              });
            },
            selectedColor: Theme.of(context).primaryColor.withOpacity(0.3),
            checkmarkColor: Theme.of(context).primaryColor,
            labelStyle: TextStyle(color: _selectedFilter == filter ? Theme.of(context).primaryColor : null),
          );
        }).toList(),
      ),
    );
  }
}

class AuditLogCard extends StatelessWidget {
  final AuditLogModel log;

  const AuditLogCard({super.key, required this.log});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              log.actionDisplayName.toCapitalized(),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: _getActionColor(log.action),
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Actor: ${log.actorName} (ID: ${log.actorId.substring(0, 8)}...)',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Text(
              'Target: ${log.targetType.toCapitalized()} - ${log.targetName} (ID: ${log.targetId.substring(0, 8)}...)',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Details: ${log.details}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                DateFormat('MMM dd, yyyy HH:mm:ss').format(log.timestamp),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
              ),
            ),
            if (log.metadata != null && log.metadata!.isNotEmpty)
              ExpansionTile(
                title: const Text('Metadata'),
                children: log.metadata!.entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(left: 16.0, bottom: 4.0),
                    child: Text('${entry.key}: ${entry.value}'),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Color _getActionColor(String action) {
    switch (action) {
      case 'LOGIN':
      case 'CREATE_USER':
      case 'CREATE_ORDER':
      case 'CREATE_PAYMENT':
        return Colors.green;
      case 'LOGOUT':
      case 'DELETE_USER':
      case 'DELETE_ORDER': // Assuming a delete order action
        return Colors.red;
      case 'UPDATE_USER':
      case 'UPDATE_ORDER':
      case 'UPDATE_ORDER_STATUS':
        return Colors.blue;
      case 'PASSWORD_RESET_REQUEST':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}

extension StringExtension on String {
  String toCapitalized() => length > 0 ? '${this[0].toUpperCase()}' + substring(1).toLowerCase() : '';
}

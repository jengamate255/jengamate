import 'package:flutter/material.dart';
import 'package:jengamate/services/audit_log_service.dart';
import 'package:jengamate/models/audit_log_model.dart';

class EnhancedAuditLogScreen extends StatefulWidget {
  const EnhancedAuditLogScreen({Key? key}) : super(key: key);

  @override
  State<EnhancedAuditLogScreen> createState() => _EnhancedAuditLogScreenState();
}

class _EnhancedAuditLogScreenState extends State<EnhancedAuditLogScreen> {
  final AuditLogService _auditLogService = AuditLogService();
  List<AuditLogModel> _auditLogs = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedAction = 'All';
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _loadAuditLogs();
  }

  Future<void> _loadAuditLogs() async {
    try {
      final logs = await _auditLogService.getAuditLogs(limit: 1000).first;
      setState(() {
        _auditLogs = logs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading audit logs: $e')),
      );
    }
  }

  List<AuditLogModel> get _filteredLogs {
    return _auditLogs.where((log) {
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        if (!log.actorName.toLowerCase().contains(query) &&
            !log.targetName.toLowerCase().contains(query) &&
            !log.details.toLowerCase().contains(query)) {
          return false;
        }
      }

      if (_selectedAction != 'All' && log.action != _selectedAction) {
        return false;
      }

      if (_startDate != null && log.timestamp.isBefore(_startDate!)) {
        return false;
      }

      if (_endDate != null && log.timestamp.isAfter(_endDate!)) {
        return false;
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enhanced Audit Log'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAuditLogs,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildAuditLogList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Search',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedAction,
                    decoration: const InputDecoration(
                      labelText: 'Action',
                      border: OutlineInputBorder(),
                    ),
                    items:
                        ['All', 'CREATE', 'UPDATE', 'DELETE', 'LOGIN', 'LOGOUT']
                            .map((action) => DropdownMenuItem(
                                  value: action,
                                  child: Text(action),
                                ))
                            .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedAction = value!;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _startDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setState(() {
                          _startDate = date;
                        });
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Start Date',
                        border: OutlineInputBorder(),
                      ),
                      child: Text(
                        _startDate?.toString().split(' ')[0] ?? 'Select date',
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _endDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setState(() {
                          _endDate = date;
                        });
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'End Date',
                        border: OutlineInputBorder(),
                      ),
                      child: Text(
                        _endDate?.toString().split(' ')[0] ?? 'Select date',
                      ),
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

  Widget _buildAuditLogList() {
    if (_filteredLogs.isEmpty) {
      return const Center(
        child: Text('No audit logs found'),
      );
    }

    return ListView.builder(
      itemCount: _filteredLogs.length,
      itemBuilder: (context, index) {
        final log = _filteredLogs[index];
        return _buildAuditLogCard(log);
      },
    );
  }

  Widget _buildAuditLogCard(AuditLogModel log) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ExpansionTile(
        title: Row(
          children: [
            _buildActionChip(log.action),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                log.targetName,
                style: const TextStyle(fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        subtitle: Text(
          '${log.actorName} • ${log.timestamp.toString().substring(0, 16)}',
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('Actor', log.actorName),
                _buildDetailRow('Action', log.action),
                _buildDetailRow('Target Type', log.targetType),
                _buildDetailRow('Target Name', log.targetName),
                _buildDetailRow('Details', log.details),
                if (log.metadata != null && log.metadata!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Metadata:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  ...log.metadata!.entries.map(
                    (entry) => _buildDetailRow(
                      entry.key,
                      entry.value.toString(),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionChip(String action) {
    Color color;
    switch (action.toUpperCase()) {
      case 'CREATE':
        color = Colors.green;
        break;
      case 'UPDATE':
        color = Colors.blue;
        break;
      case 'DELETE':
        color = Colors.red;
        break;
      case 'LOGIN':
        color = Colors.purple;
        break;
      case 'LOGOUT':
        color = Colors.orange;
        break;
      default:
        color = Colors.grey;
    }

    return Chip(
      label: Text(
        action,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
      backgroundColor: color,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
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
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}

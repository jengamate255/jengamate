import 'package:flutter/material.dart';
import 'package:jengamate/models/audit_log_model.dart';
import 'package:jengamate/services/audit_log_service.dart';
import 'package:jengamate/services/database_service.dart';
// import removed: responsive_helper no longer used

import 'package:intl/intl.dart';

class AuditLogScreen extends StatefulWidget {
  final String? userId;
  final String? userName;

  const AuditLogScreen({super.key, this.userId, this.userName});

  @override
  State<AuditLogScreen> createState() => _AuditLogScreenState();
}

class _AuditLogScreenState extends State<AuditLogScreen> {
  final AuditLogService _auditLogService = AuditLogService();
  final DatabaseService _databaseService = DatabaseService();
  List<AuditLogModel> _auditLogs = [];
  List<AuditLogModel> _filteredLogs = [];
  bool _isLoading = true;

  final TextEditingController _searchController = TextEditingController();
  String _selectedAction = 'all';
  String _selectedUser = 'all';
  DateTimeRange? _dateRange;

  final List<String> _actionTypes = [
    'all',
    'login',
    'logout',
    'create',
    'update',
    'delete',
    'approve',
    'reject',
    'payment',
    'withdrawal',
    'system'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Audit Log for ${widget.userName}'),
      ),
      body: StreamBuilder<List<AuditLogModel>>(
        stream: _auditLogService.streamAuditLogs(widget.userId ?? ''),
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

          final logs = snapshot.data!;

          return ListView.builder(
            itemCount: logs.length,
            itemBuilder: (context, index) {
              final log = logs[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text('${log.actorName} ${log.action}'),
                  subtitle:
                      Text(DateFormat.yMMMd().add_jm().format(log.timestamp)),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Log Details'),
                        content: SingleChildScrollView(
                          child: Text(log.details.toString()),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    );
                                    },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

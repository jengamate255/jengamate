import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jengamate/services/bulk_operations_service.dart';
import 'package:jengamate/models/user_model.dart';
import 'package:jengamate/services/database_service.dart';
import 'package:jengamate/services/supabase_moderation_service.dart'; // Add this import
import 'package:jengamate/models/moderation_item_model.dart'; // Add this import
import 'package:jengamate/models/enums/moderation_status.dart'; // Add this import
import 'package:jengamate/utils/logger.dart';

class BulkOperationsScreen extends StatefulWidget {
  const BulkOperationsScreen({Key? key}) : super(key: key);

  @override
  _BulkOperationsScreenState createState() => _BulkOperationsScreenState();
}

class _BulkOperationsScreenState extends State<BulkOperationsScreen> {
  final BulkOperationsService _bulkService = BulkOperationsService();
  final DatabaseService _databaseService = DatabaseService();
  final SupabaseModerationService _supabaseModerationService = SupabaseModerationService(); // Add this line

  StreamSubscription<List<BulkOperationResult>>? _operationsSubscription;
  List<BulkOperationResult> _activeOperations = [];
  bool _isLoading = false;

  // Selection state
  final Set<String> _selectedUserIds = {};
  final Set<String> _selectedContentIds = {};
  bool _selectAllUsers = false;
  bool _selectAllContent = false;

  // Data
  List<UserModel> _users = [];
  List<ModerationItem> _contentReports = []; // Modified type

  @override
  void initState() {
    super.initState();
    _setupOperationsListener();
    _loadData();
  }

  @override
  void dispose() {
    _operationsSubscription?.cancel();
    _bulkService.dispose();
    super.dispose();
  }

  void _setupOperationsListener() {
    _operationsSubscription = _bulkService.getActiveOperations().listen(
      (operations) {
        if (mounted) {
          setState(() {
            _activeOperations = operations;
          });
        }
      },
      onError: (error) {
        Logger.logError('Error listening to bulk operations', error, StackTrace.current);
      },
    );
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // Load users
      _users = await _databaseService.getAllUsers();

      // Load content reports from Supabase
      _contentReports = await _supabaseModerationService.streamModerationItems(status: ModerationStatus.pending.name).first; // Modified line

    } catch (e) {
      Logger.logError('Failed to load data', e, StackTrace.current);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load data: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bulk Operations'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : DefaultTabController(
              length: 4,
              child: Column(
                children: [
                  TabBar(
                    isScrollable: isMobile,
                    tabs: const [
                      Tab(text: 'Users', icon: Icon(Icons.people)),
                      Tab(text: 'Content', icon: Icon(Icons.article)),
                      Tab(text: 'Data Export', icon: Icon(Icons.download)),
                      Tab(text: 'Operations', icon: Icon(Icons.work)),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildUsersTab(isMobile),
                        _buildContentTab(isMobile),
                        _buildDataExportTab(isMobile),
                        _buildOperationsTab(isMobile),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildUsersTab(bool isMobile) {
    return Column(
      children: [
        // Selection controls
        Container(
          padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
          color: Colors.grey.shade50,
          child: Row(
            children: [
              Checkbox(
                value: _selectAllUsers,
                onChanged: (value) {
                  setState(() {
                    _selectAllUsers = value ?? false;
                    if (_selectAllUsers) {
                      _selectedUserIds.addAll(_users.map((u) => u.uid));
                    } else {
                      _selectedUserIds.clear();
                    }
                  });
                },
              ),
              Text('${_selectedUserIds.length} of ${_users.length} selected'),
              const Spacer(),
              if (_selectedUserIds.isNotEmpty) ...[
                ElevatedButton.icon(
                  onPressed: () => _showBulkUserActionDialog('approve'),
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text('Approve'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _showBulkUserActionDialog('reject'),
                  icon: const Icon(Icons.close, size: 16),
                  label: const Text('Reject'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ],
          ),
        ),

        // Users list
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
            itemCount: _users.length,
            itemBuilder: (context, index) {
              final user = _users[index];
              final isSelected = _selectedUserIds.contains(user.uid);

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: CheckboxListTile(
                  value: isSelected,
                  onChanged: (value) {
                    setState(() {
                      if (value ?? false) {
                        _selectedUserIds.add(user.uid);
                      } else {
                        _selectedUserIds.remove(user.uid);
                      }
                      _updateSelectAllUsers();
                    });
                  },
                  title: Text(user.displayName ?? user.email ?? 'Unknown'),
                  subtitle: Text(user.email ?? ''),
                  secondary: CircleAvatar(
                    child: Text((user.displayName ?? user.email ?? '?')[0].toUpperCase()),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildContentTab(bool isMobile) {
    return Column(
      children: [
        // Selection controls
        Container(
          padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
          color: Colors.grey.shade50,
          child: Row(
            children: [
              Checkbox(
                value: _selectAllContent,
                onChanged: (value) {
                  setState(() {
                    _selectAllContent = value ?? false;
                    if (_selectAllContent) {
                      _selectedContentIds.addAll(_contentReports.map((c) => c.id));
                    } else {
                      _selectedContentIds.clear();
                    }
                  });
                },
              ),
              Text('${_selectedContentIds.length} of ${_contentReports.length} selected'),
              const Spacer(),
              if (_selectedContentIds.isNotEmpty) ...[
                ElevatedButton.icon(
                  onPressed: () => _showBulkContentActionDialog('approve'),
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text('Approve'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _showBulkContentActionDialog('reject'),
                  icon: const Icon(Icons.close, size: 16),
                  label: const Text('Reject'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ],
          ),
        ),

        // Content list
        Expanded(
          child: _contentReports.isEmpty
              ? const Center(
                  child: Text('No pending content reports'),
                )
              : ListView.builder(
                  padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
                  itemCount: _contentReports.length,
                  itemBuilder: (context, index) {
                    final content = _contentReports[index];
                    final isSelected = _selectedContentIds.contains(content.id);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: CheckboxListTile(
                        value: isSelected,
                        onChanged: (value) {
                          setState(() {
                            if (value ?? false) {
                              _selectedContentIds.add(content.id);
                            } else {
                              _selectedContentIds.remove(content.id);
                            }
                            _updateSelectAllContent();
                          });
                        },
                        title: Text(content.title ?? 'Content Report'),
                        subtitle: Text(content.description ?? ''),
                        secondary: const Icon(Icons.article),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildDataExportTab(bool isMobile) {
    return Padding(
      padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Export Data',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Export your data in CSV format for analysis or backup purposes.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 32),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Users Data Export',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Export all user data including profiles and account information.'),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _exportUsersData(_selectedUserIds.toList()),
                          icon: const Icon(Icons.download),
                          label: Text(_selectedUserIds.isEmpty
                              ? 'Export All Users'
                              : 'Export Selected (${_selectedUserIds.length})'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Orders Data Export',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text('Export order history and transaction data.'),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _exportOrdersData,
                    icon: const Icon(Icons.download),
                    label: const Text('Export Orders Data'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOperationsTab(bool isMobile) {
    return _activeOperations.isEmpty
        ? const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.work_off, size: 80, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No active operations',
                  style: TextStyle(color: Colors.grey, fontSize: 18),
                ),
              ],
            ),
          )
        : ListView.builder(
            padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
            itemCount: _activeOperations.length,
            itemBuilder: (context, index) {
              final operation = _activeOperations[index];
              return _buildOperationCard(operation, isMobile);
            },
          );
  }

  Widget _buildOperationCard(BulkOperationResult operation, bool isMobile) {
    final progressColor = _getProgressColor(operation.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _getOperationTypeLabel(operation.type),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: progressColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: progressColor),
                  ),
                  child: Text(
                    _getStatusLabel(operation.status),
                    style: TextStyle(
                      color: progressColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Progress bar
            LinearProgressIndicator(
              value: operation.progress,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            ),

            const SizedBox(height: 8),

            // Progress text
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${operation.processedItems}/${operation.totalItems} processed',
                  style: const TextStyle(fontSize: 12),
                ),
                Text(
                  '${(operation.progress * 100).toInt()}%',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
            ),

            // Stats
            if (operation.successfulItems > 0 || operation.failedItems > 0) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    '✅ ${operation.successfulItems} successful',
                    style: const TextStyle(color: Colors.green, fontSize: 12),
                  ),
                  if (operation.failedItems > 0) ...[
                    const SizedBox(width: 16),
                    Text(
                      '❌ ${operation.failedItems} failed',
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ],

            // Errors
            if (operation.errors.isNotEmpty) ...[
              const SizedBox(height: 8),
              ExpansionTile(
                title: Text(
                  '${operation.errors.length} error(s)',
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
                children: operation.errors
                    .map((error) => ListTile(
                          dense: true,
                          title: Text(
                            error,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ))
                    .toList(),
              ),
            ],

            // Action buttons
            if (operation.status == BulkOperationStatus.processing) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _cancelOperation(operation.id),
                      child: const Text('Cancel'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _updateSelectAllUsers() {
    setState(() {
      _selectAllUsers = _selectedUserIds.length == _users.length && _users.isNotEmpty;
    });
  }

  void _updateSelectAllContent() {
    setState(() {
      _selectAllContent = _selectedContentIds.length == _contentReports.length && _contentReports.isNotEmpty;
    });
  }

  Future<void> _showBulkUserActionDialog(String action) async {
    final reason = action == 'reject' ? await _showReasonDialog('Reject Users') : null;
    if (action == 'reject' && reason == null) return;

    final notes = await _showNotesDialog();

    try {
      String operationId;
      if (action == 'approve') {
        operationId = await _bulkService.bulkUserApproval(
          _selectedUserIds.toList(),
          adminNotes: notes,
        );
      } else {
        operationId = await _bulkService.bulkUserRejection(
          _selectedUserIds.toList(),
          reason!,
          adminNotes: notes,
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bulk operation started: $operationId')),
      );

      // Clear selection
      setState(() {
        _selectedUserIds.clear();
        _selectAllUsers = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to start bulk operation: $e')),
      );
    }
  }

  Future<void> _showBulkContentActionDialog(String action) async {
    final reason = action == 'reject' ? await _showReasonDialog('Reject Content') : null;
    if (action == 'reject' && reason == null) return;

    final notes = await _showNotesDialog();

    try {
      String operationId;
      if (action == 'approve') {
        operationId = await _bulkService.bulkContentApproval(
          _selectedContentIds.toList(),
          adminNotes: notes,
        );
      } else {
        operationId = await _bulkService.bulkContentRejection(
          _selectedContentIds.toList(),
          reason!,
          adminNotes: notes,
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bulk operation started: $operationId')),
      );

      // Clear selection
      setState(() {
        _selectedContentIds.clear();
        _selectAllContent = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to start bulk operation: $e')),
      );
    }
  }

  Future<String?> _showReasonDialog(String title) async {
    String? reason;
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          decoration: const InputDecoration(
            hintText: 'Enter reason...',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
          onChanged: (value) => reason = value,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(reason),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  Future<String?> _showNotesDialog() async {
    String? notes;
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Admin Notes (Optional)'),
        content: TextField(
          decoration: const InputDecoration(
            hintText: 'Enter admin notes...',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
          onChanged: (value) => notes = value,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Skip'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(notes),
            child: const Text('Add Notes'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportUsersData(List<String> userIds) async {
    try {
      final operationId = await _bulkService.exportUsersData(
        userIds: userIds.isNotEmpty ? userIds : null,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export started: $operationId')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to start export: $e')),
      );
    }
  }

  Future<void> _exportOrdersData() async {
    try {
      final operationId = await _bulkService.exportOrdersData();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Orders export started: $operationId')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to start orders export: $e')),
      );
    }
  }

  Future<void> _cancelOperation(String operationId) async {
    try {
      await _bulkService.cancelOperation(operationId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Operation cancelled')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to cancel operation: $e')),
      );
    }
  }

  String _getOperationTypeLabel(BulkOperationType type) {
    switch (type) {
      case BulkOperationType.userManagement:
        return 'User Management';
      case BulkOperationType.contentModeration:
        return 'Content Moderation';
      case BulkOperationType.dataExport:
        return 'Data Export';
      default:
        return 'Unknown Operation';
    }
  }

  String _getStatusLabel(BulkOperationStatus status) {
    switch (status) {
      case BulkOperationStatus.pending:
        return 'PENDING';
      case BulkOperationStatus.processing:
        return 'PROCESSING';
      case BulkOperationStatus.completed:
        return 'COMPLETED';
      case BulkOperationStatus.failed:
        return 'FAILED';
      case BulkOperationStatus.cancelled:
        return 'CANCELLED';
    }
  }

  Color _getProgressColor(BulkOperationStatus status) {
    switch (status) {
      case BulkOperationStatus.pending:
        return Colors.grey;
      case BulkOperationStatus.processing:
        return Colors.blue;
      case BulkOperationStatus.completed:
        return Colors.green;
      case BulkOperationStatus.failed:
        return Colors.red;
      case BulkOperationStatus.cancelled:
        return Colors.orange;
    }
  }

  Future<void> _processBulkContentApproval(String operationId, List<String> contentIds, String? adminNotes) async {
    int processed = 0;
    int successful = 0;
    int failed = 0;
    final errors = <String>[];

    for (final contentId in contentIds) {
      try {
        await _supabaseModerationService.updateModerationItemStatus( // Modified line
          contentId,
          ModerationStatus.approved,
          metadata: {
            'moderatedAt': DateTime.now().toIso8601String(),
            'moderatedBy': 'admin',
            'adminNotes': adminNotes,
          },
        );

        successful++;
        Logger.log('Content approved: $contentId');
      } catch (e) {
        failed++;
        errors.add('Failed to approve content $contentId: $e');
        Logger.logError('Failed to approve content', e, StackTrace.current);
      }

      processed++;
      await _bulkService.updateBulkOperation(operationId,
        processedItems: processed,
        successfulItems: successful,
        failedItems: failed,
        errors: errors,
      );
    }

    await _bulkService.updateBulkOperation(operationId,
      status: BulkOperationStatus.completed,
      processedItems: processed,
      successfulItems: successful,
      failedItems: failed,
      errors: errors,
    );
  }

  Future<void> _processBulkContentRejection(String operationId, List<String> contentIds, String reason, String? adminNotes) async {
    int processed = 0;
    int successful = 0;
    int failed = 0;
    final errors = <String>[];

    for (final contentId in contentIds) {
      try {
        await _supabaseModerationService.updateModerationItemStatus( // Modified line
          contentId,
          ModerationStatus.rejected,
          metadata: {
            'moderatedAt': DateTime.now().toIso8601String(),
            'moderatedBy': 'admin',
            'moderationReason': reason,
            'adminNotes': adminNotes,
          },
        );

        successful++;
        Logger.log('Content rejected: $contentId');
      } catch (e) {
        failed++;
        errors.add('Failed to reject content $contentId: $e');
        Logger.logError('Failed to reject content', e, StackTrace.current);
      }

      processed++;
      await _bulkService.updateBulkOperation(operationId,
        processedItems: processed,
        successfulItems: successful,
        failedItems: failed,
        errors: errors,
      );
    }

    await _bulkService.updateBulkOperation(operationId,
      status: BulkOperationStatus.completed,
      processedItems: processed,
      successfulItems: successful,
      failedItems: failed,
      errors: errors,
    );
  }
}

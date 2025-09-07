import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:jengamate/models/commission_model.dart';
import 'package:jengamate/models/user_model.dart';
import 'package:jengamate/services/database_service.dart';
import 'package:intl/intl.dart';
import 'package:jengamate/services/tier_metadata_service.dart';
import 'package:jengamate/widgets/tier_chip.dart';

class CommissionListScreen extends StatefulWidget {
  const CommissionListScreen({super.key});

  @override
  State<CommissionListScreen> createState() => _CommissionListScreenState();
}

class _CommissionListScreenState extends State<CommissionListScreen> {
  final DatabaseService _databaseService = DatabaseService();
  String _selectedEngineer = 'All Engineers';
  String _selectedType = 'All Types';
  DateTime? _startDate;
  DateTime? _endDate;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  int? _sortColumnIndex;
  bool _sortAscending = true;
  Map<String, TierMeta> _tierCache = {};

  @override
  void initState() {
    super.initState();
    TierMetadataService.instance.loadAll().then((map) {
      if (mounted) setState(() => _tierCache = map);
    });
  }

  Color _parseBadgeColor(String code) {
    // Accept hex like #RRGGBB or #AARRGGBB
    try {
      String c = code.trim();
      if (c.startsWith('#')) c = c.substring(1);
      if (c.length == 6) c = 'FF$c';
      final value = int.parse(c, radix: 16);
      return Color(value);
    } catch (_) {
      return Colors.blueGrey; // fallback
    }
  }

  String _deriveType(CommissionModel c) {
    final metaType = c.metadata != null ? c.metadata!['commissionType'] : null;
    if (metaType is String && metaType.isNotEmpty) {
      final t = metaType.toLowerCase();
      if (t == 'direct' || t == 'referral' || t == 'active') {
        return t[0].toUpperCase() + t.substring(1);
      }
    }
    if (c.direct > 0) return 'Direct';
    if (c.referral > 0) return 'Referral';
    if (c.active > 0) return 'Active';
    return 'Unknown';
  }

  Future<void> _confirmDelete(CommissionModel c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Commission'),
        content: Text('Are you sure you want to delete commission ${c.id}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok == true) {
      await _databaseService.deleteCommissionRecord(c.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Commission deleted')));
      }
    }
  }

  void _viewDetails(CommissionModel c) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Commission Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ID: ${c.id}'),
            Text('User ID: ${c.userId}'),
            Text('Type: ${_deriveType(c)}'),
            Text('Total: TSh ${NumberFormat('#,##0').format(c.total)}'),
            Text('Direct: ${c.direct}'),
            Text('Referral: ${c.referral}'),
            Text('Active: ${c.active}'),
            Text('Status: ${c.status}'),
            Text('Updated: ${DateFormat.yMd().add_jm().format(c.updatedAt)}'),
            if (c.metadata != null && c.metadata!['appliedRate'] != null)
              Text('Applied Rate: ${((c.metadata!['appliedRate'] as num) * 100).toStringAsFixed(1)}%'),
            if (c.metadata != null && c.metadata!['appliedTierId'] != null)
              Text('Applied Tier ID: ${c.metadata!['appliedTierId']}'),
            if (c.metadata != null && c.metadata!['note'] != null) Text('Note: ${c.metadata!['note']}'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  Future<void> _editCommission(CommissionModel c) async {
    final TextEditingController amountCtrl = TextEditingController(text: c.total.toStringAsFixed(0));
    String type = _deriveType(c);
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Edit Commission', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: type,
                    decoration: const InputDecoration(labelText: 'Type', border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'Direct', child: Text('Direct')),
                      DropdownMenuItem(value: 'Referral', child: Text('Referral')),
                      DropdownMenuItem(value: 'Active', child: Text('Active')),
                    ],
                    onChanged: (v) => type = v ?? type,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amountCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Amount (TSh)', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Save'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    if (result == true) {
      final amount = double.tryParse(amountCtrl.text.trim());
      if (amount == null || amount <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid amount')));
        return;
      }
      double direct = 0, referral = 0, active = 0;
      switch (type) {
        case 'Direct':
          direct = amount; break;
        case 'Referral':
          referral = amount; break;
        case 'Active':
          active = amount; break;
      }
      final newMeta = Map<String, dynamic>.from(c.metadata ?? {});
      newMeta['commissionType'] = type.toLowerCase();
      await _databaseService.updateCommissionRecord(c.id, {
        'total': amount,
        'direct': direct,
        'referral': referral,
        'active': active,
        'metadata': newMeta,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Commission updated')));
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _isSearching = _searchController.text.isNotEmpty;
    });
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final initialDateRange = DateTimeRange(
      start: _startDate ?? DateTime.now().subtract(const Duration(days: 30)),
      end: _endDate ?? DateTime.now(),
    );

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: initialDateRange,
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  Stream<List<CommissionModel>> _getCommissionsStream() {
    // For now, we'll fetch all and filter in client.
    // In a real app, you'd use Firestore queries for better performance.
    return _databaseService.getAllCommissions();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 800;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Commissions List'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // Navigate to Admin -> Commission Tools -> Send Commission
              context.goNamed('adminSendCommission');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Search by user name or ID',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _isSearching
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _onSearchChanged();
                            },
                          )
                        : null,
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    _onSearchChanged();
                  },
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedEngineer,
                        decoration: const InputDecoration(
                          labelText: 'Filter by Engineer',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: <String>['All Engineers', 'Engineer 1', 'Engineer 2'] // Replace with actual engineers
                            .map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedEngineer = newValue!;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedType,
                        decoration: const InputDecoration(
                          labelText: 'Filter by Type',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: <String>['All Types', 'Direct', 'Referral', 'Active']
                            .map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedType = newValue!;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _selectDateRange(context),
                        child: Text(
                          _startDate == null
                              ? 'Select Date Range'
                              : '${DateFormat.yMd().format(_startDate!)} - ${DateFormat.yMd().format(_endDate!)}',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.filter_list),
                      onPressed: () {
                        // Apply filters (already handled by setState in dropdowns and date picker)
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<CommissionModel>>(
              stream: _getCommissionsStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                List<CommissionModel> commissions = snapshot.data!;

                // Apply client-side filters
                commissions = commissions.where((commission) {
                  if (_selectedEngineer != 'All Engineers' && commission.userId != _selectedEngineer) {
                    return false;
                  }
                  final cType = _deriveType(commission);
                  if (_selectedType != 'All Types' && cType != _selectedType) {
                    return false;
                  }
                  if (_startDate != null && commission.createdAt.isBefore(_startDate!)) {
                    return false;
                  }
                  if (_endDate != null && commission.createdAt.isAfter(_endDate!)) {
                    return false;
                  }
                  if (_isSearching) {
                    final query = _searchController.text.toLowerCase();
                    // For now, search by userId. In a real app, fetch user name for search.
                    if (!commission.userId.toLowerCase().contains(query)) {
                      return false;
                    }
                  }
                  return true;
                }).toList();

                if (commissions.isEmpty) {
                  return const Center(child: Text('No commissions found.'));
                }

                if (isDesktop) {
                  return _buildDesktopTable(commissions);
                } else {
                  return _buildMobileList(commissions);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopTable(List<CommissionModel> commissions) {
    // Apply sorting
    final rows = [...commissions];
    if (_sortColumnIndex != null) {
      rows.sort((a, b) {
        int cmp = 0;
        switch (_sortColumnIndex) {
          case 2: // Amount
            cmp = a.total.compareTo(b.total);
            break;
          case 3: // Applied Rate
            final arA = (a.metadata != null && a.metadata!['appliedRate'] != null) ? (a.metadata!['appliedRate'] as num).toDouble() : -1.0;
            final arB = (b.metadata != null && b.metadata!['appliedRate'] != null) ? (b.metadata!['appliedRate'] as num).toDouble() : -1.0;
            cmp = arA.compareTo(arB);
            break;
          case 5: // Type
            cmp = _deriveType(a).compareTo(_deriveType(b));
            break;
          case 6: // Date
            cmp = a.updatedAt.compareTo(b.updatedAt);
            break;
          default:
            cmp = 0;
        }
        return _sortAscending ? cmp : -cmp;
      });
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        sortColumnIndex: _sortColumnIndex,
        sortAscending: _sortAscending,
        columns: [
          const DataColumn(label: Text('ID')),
          const DataColumn(label: Text('Engineer')),
          DataColumn(
            label: const Text('Amount'),
            onSort: (index, asc) => setState(() {
              _sortColumnIndex = index; _sortAscending = asc;
            }),
          ),
          DataColumn(
            label: const Text('Applied Rate'),
            numeric: true,
            onSort: (index, asc) => setState(() {
              _sortColumnIndex = index; _sortAscending = asc;
            }),
          ),
          const DataColumn(label: Text('Tier')),
          DataColumn(
            label: const Text('Type'),
            onSort: (index, asc) => setState(() { _sortColumnIndex = index; _sortAscending = asc; }),
          ),
          DataColumn(
            label: const Text('Date'),
            onSort: (index, asc) => setState(() { _sortColumnIndex = index; _sortAscending = asc; }),
          ),
          const DataColumn(label: Text('Actions')),
        ],
        rows: rows.map((commission) {
          return DataRow(
            cells: [
              DataCell(Text(commission.id.substring(0, 6))), // Shorten ID for display
              DataCell(FutureBuilder<UserModel?>(
                future: _databaseService.getUser(commission.userId),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Text('Loading...');
                  return Text(snapshot.data!.displayName);
                },
              )),
              DataCell(Text('TSh ${NumberFormat('#,##0').format(commission.total)}')),
              DataCell(Text(
                commission.metadata != null && commission.metadata!['appliedRate'] != null
                    ? '${(((commission.metadata!['appliedRate'] as num).toDouble()) * 100).toStringAsFixed(1)}%'
                    : '-',
              )),
              DataCell(() {
                final id = commission.metadata != null ? commission.metadata!['appliedTierId'] as String? : null;
                if (id == null) return const Text('-');
                final meta = _tierCache[id];
                if (meta == null) return Text(id);
                return TierChip(text: meta.name, color: _parseBadgeColor(meta.badgeColor));
              }()),
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(_deriveType(commission)).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _deriveType(commission),
                    style: TextStyle(
                      color: _getStatusColor(_deriveType(commission)),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              DataCell(Text(DateFormat('MMM dd, yyyy').format(commission.updatedAt))),
              DataCell(
                Row(
                  children: [
                    IconButton(icon: const Icon(Icons.visibility), onPressed: () => _viewDetails(commission)),
                    IconButton(icon: const Icon(Icons.edit), onPressed: () => _editCommission(commission)),
                    IconButton(icon: const Icon(Icons.delete), onPressed: () => _confirmDelete(commission)),
                  ],
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMobileList(List<CommissionModel> commissions) {
    return ListView.builder(
      itemCount: commissions.length,
      itemBuilder: (context, index) {
        final commission = commissions[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            title: FutureBuilder<UserModel?>(
              future: _databaseService.getUser(commission.userId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Text('Loading user...');
                return Text('Engineer: ${snapshot.data!.displayName}');
              },
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Amount: TSh ${NumberFormat('#,##0').format(commission.total)}'),
                Text('Type: ${_deriveType(commission)}'),
                Text('Date: ${DateFormat('MMM dd, yyyy').format(commission.updatedAt)}'),
                if (commission.metadata != null && commission.metadata!['appliedRate'] != null)
                  Text('Applied Rate: ${((commission.metadata!['appliedRate'] as num) * 100).toStringAsFixed(1)}%'),
                if (commission.metadata != null && commission.metadata!['appliedTierId'] != null)
                  Builder(builder: (context) {
                    final id = commission.metadata!['appliedTierId'] as String;
                    final meta = _tierCache[id];
                    if (meta == null) return Text('Applied Tier: $id');
                    return Row(
                      children: [
                        const Text('Applied Tier: '),
                        TierChip(text: meta.name, color: _parseBadgeColor(meta.badgeColor)),
                      ],
                    );
                  }),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(icon: const Icon(Icons.visibility), onPressed: () => _viewDetails(commission)),
                IconButton(icon: const Icon(Icons.edit), onPressed: () => _editCommission(commission)),
                IconButton(icon: const Icon(Icons.delete), onPressed: () => _confirmDelete(commission)),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Completed':
        return Colors.green;
      case 'Pending':
        return Colors.orange;
      case 'Active':
        return Colors.blue;
      case 'Inactive':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }
}
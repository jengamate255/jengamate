import 'package:flutter/material.dart';
import 'package:jengamate/models/inquiry.dart';
import 'package:jengamate/services/database_service.dart';
import 'package:jengamate/models/enums/user_role.dart';
import 'package:provider/provider.dart';
import 'package:jengamate/services/user_state_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:jengamate/config/app_routes.dart';
import 'package:jengamate/ui/design_system/components/responsive_wrapper.dart';
import 'package:jengamate/ui/design_system/tokens/spacing.dart';
import 'package:jengamate/ui/design_system/components/jm_card.dart';
import 'package:jengamate/screens/inquiry/inquiry_details_screen.dart';

class InquiryScreen extends StatefulWidget {
  // Changed to StatefulWidget
  const InquiryScreen({super.key});

  @override
  State<InquiryScreen> createState() => _InquiryScreenState();
}

class _InquiryScreenState extends State<InquiryScreen> {
  final DatabaseService dbService = DatabaseService();
  String _searchQuery = '';
  String? _selectedStatusFilter;
  int? _daysFilter; // null = All, 7, 30
  DateTimeRange? _customRange;
  bool _selectionMode = false;
  final Set<String> _selectedIds = <String>{};
  List<Inquiry> _visibleInquiries = const [];
  // You can add more filter options here later, e.g., date range

  @override
  Widget build(BuildContext context) {
    final userState = Provider.of<UserStateProvider>(context);
    final currentUser = userState.currentUser;

    final bool isAdmin = currentUser?.role == UserRole.admin;
    final Stream<List<Inquiry>> stream = isAdmin
        ? dbService.streamAllInquiries()
        : dbService.streamInquiriesForUser(currentUser?.uid ?? '');

    return ResponsiveScaffold(
      appBar: AppBar(
        title: const Text('Inquiries'),
        actions: [
          if (isAdmin)
            IconButton(
              tooltip: _selectionMode ? 'Exit selection' : 'Select',
              icon: Icon(_selectionMode
                  ? Icons.check_box
                  : Icons.check_box_outline_blank),
              onPressed: () => setState(() {
                _selectionMode = !_selectionMode;
                if (!_selectionMode) _selectedIds.clear();
              }),
            ),
          PopupMenuButton<String?>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) =>
                setState(() => _selectedStatusFilter = value),
            itemBuilder: (context) => <PopupMenuEntry<String?>>[
              const PopupMenuItem<String?>(
                  value: null, child: Text('All statuses')),
              const PopupMenuItem<String?>(value: 'open', child: Text('Open')),
              const PopupMenuItem<String?>(
                  value: 'in_progress', child: Text('In Progress')),
              const PopupMenuItem<String?>(
                  value: 'waiting_for_response',
                  child: Text('Waiting for Response')),
              const PopupMenuItem<String?>(
                  value: 'resolved', child: Text('Resolved')),
              const PopupMenuItem<String?>(
                  value: 'closed', child: Text('Closed')),
            ],
          ),
          IconButton(
            tooltip: 'Custom date range',
            icon: const Icon(Icons.date_range),
            onPressed: () async {
              final now = DateTime.now();
              final picked = await showDateRangePicker(
                context: context,
                firstDate: DateTime(now.year - 2),
                lastDate: now,
                initialDateRange: _customRange,
              );
              if (picked != null) {
                setState(() {
                  _customRange = picked;
                  _daysFilter =
                      null; // override quick chips when custom range is set
                });
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar at the top with minimal padding
          Padding(
            padding: EdgeInsets.only(
              left: JMSpacing.md,
              right: JMSpacing.md,
              top: JMSpacing.xxs,
              bottom: JMSpacing.xxs,
            ),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search inquiries...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(JMSpacing.sm),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor:
                    Theme.of(context).colorScheme.surfaceContainerHighest,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: JMSpacing.md,
                  vertical: JMSpacing.sm,
                ),
              ),
            ),
          ),
          // Date range filter chips with minimal spacing
          Padding(
            padding: EdgeInsets.only(
              left: JMSpacing.md,
              right: JMSpacing.md,
              bottom: JMSpacing.xxs,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: JMSpacing.xxs.toDouble(),
                runSpacing: JMSpacing.xxs.toDouble(),
                children: [
                  FilterChip(
                    label: const Text('All'),
                    selected: _daysFilter == null,
                    onSelected: (_) => setState(() => _daysFilter = null),
                  ),
                  FilterChip(
                    label: const Text('7d'),
                    selected: _daysFilter == 7,
                    onSelected: (_) => setState(() => _daysFilter = 7),
                  ),
                  FilterChip(
                    label: const Text('30d'),
                    selected: _daysFilter == 30,
                    onSelected: (_) => setState(() => _daysFilter = 30),
                  ),
                ],
              ),
            ),
          ),
            Expanded(
              child: StreamBuilder<List<Inquiry>>(
                stream: stream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('No inquiries found.'),
                        const SizedBox(height: JMSpacing.md),
                        (currentUser?.role == UserRole.engineer || isAdmin)
                            ? ElevatedButton.icon(
                                onPressed: () => context.go(AppRoutes.newInquiry),
                                icon: const Icon(Icons.add),
                                label: const Text('New Inquiry'),
                              )
                            : const SizedBox.shrink(),
                      ],
                    );
                  }

                  var inquiries = snapshot.data!;
                  // Apply search
                  if (_searchQuery.isNotEmpty) {
                    final q = _searchQuery.toLowerCase();
                    inquiries = inquiries.where((i) {
                      return i.subject.toLowerCase().contains(q) ||
                          i.description.toLowerCase().contains(q) ||
                          i.status.toLowerCase().contains(q);
                    }).toList();
                  }
                  // Apply status filter
                  if (_selectedStatusFilter != null) {
                    inquiries = inquiries
                        .where((i) => i.status == _selectedStatusFilter)
                        .toList();
                  }
                  // Apply days filter
                  if (_daysFilter != null) {
                    final cutoff =
                        DateTime.now().subtract(Duration(days: _daysFilter!));
                    inquiries = inquiries
                        .where((i) => i.createdAt.isAfter(cutoff))
                        .toList();
                  }
                  // Apply custom range
                  if (_customRange != null) {
                    final start = DateTime(_customRange!.start.year,
                        _customRange!.start.month, _customRange!.start.day);
                    final end = DateTime(
                        _customRange!.end.year,
                        _customRange!.end.month,
                        _customRange!.end.day,
                        23,
                        59,
                        59);
                    inquiries = inquiries
                        .where((i) =>
                            i.createdAt.isAfter(start) &&
                            i.createdAt.isBefore(end))
                        .toList();
                  }

                  // Update visible inquiries only when selection mode is active
                  _visibleInquiries =
                      inquiries; // Simple assignment without triggering rebuild

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: JMSpacing.sm),
                    itemCount: inquiries.length,
                    itemBuilder: (context, index) {
                      final inquiry = inquiries[index];
                      final selected = _selectedIds.contains(inquiry.uid);
                      return Padding(
                        padding: EdgeInsets.only(bottom: JMSpacing.xxs),
                        child: JMCard(
                          child: ListTile(
                            leading: _selectionMode
                                ? Checkbox(
                                    value: selected,
                                    onChanged: (v) {
                                      setState(() {
                                        if (v == true) {
                                          _selectedIds.add(inquiry.uid);
                                        } else {
                                          _selectedIds.remove(inquiry.uid);
                                        }
                                      });
                                    },
                                  )
                                : null,
                            title: Text(inquiry.subject),
                            subtitle: Text(inquiry.statusDisplayName),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              if (_selectionMode) {
                                setState(() {
                                  if (selected) {
                                    _selectedIds.remove(inquiry.uid);
                                  } else {
                                    _selectedIds.add(inquiry.uid);
                                  }
                                });
                              } else {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        InquiryDetailsScreen(inquiry: inquiry),
                                  ),
                                );
                              }
                            },
                            onLongPress: isAdmin
                                ? () => setState(() {
                                      _selectionMode = true;
                                      _selectedIds.add(inquiry.uid);
                                    })
                                : null,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          if (_selectionMode)
            SafeArea(
              top: false,
              child: Row(
                children: [
                  TextButton(
                    onPressed: () => setState(() => _selectedIds.clear()),
                    child: const Text('Clear'),
                  ),
                  const SizedBox(width: JMSpacing.sm),
                  TextButton(
                    onPressed: () => setState(() => _selectedIds
                        .addAll(_visibleInquiries.map((e) => e.uid))),
                    child: const Text('Select all (visible)'),
                  ),
                  const Spacer(),
                  PopupMenuButton<String>(
                    tooltip: 'Change status',
                    icon: const Icon(Icons.flag_outlined),
                    onSelected: (value) async {
                      final ids = _selectedIds.toList();
                      for (final id in ids) {
                        await dbService.updateInquiryStatus(id, value);
                      }
                      if (mounted) setState(() => _selectedIds.clear());
                      if (mounted)
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Status updated')));
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'open', child: Text('Open')),
                      PopupMenuItem(
                          value: 'in_progress', child: Text('In Progress')),
                      PopupMenuItem(
                          value: 'waiting_for_response',
                          child: Text('Waiting for Response')),
                      PopupMenuItem(
                          value: 'resolved', child: Text('Resolved')),
                      PopupMenuItem(value: 'closed', child: Text('Closed')),
                    ],
                  ),
                  const SizedBox(width: JMSpacing.sm),
                  TextButton.icon(
                    onPressed: () async {
                      // Simple assign to user dialog reusing search
                      await _openBulkAssignDialog();
                    },
                    icon: const Icon(Icons.person_add_alt),
                    label: const Text('Assign'),
                  ),
                ],
              ),
            ),
          ],
        ),
      floatingActionButton: (currentUser?.role == UserRole.engineer ||
              currentUser?.role == UserRole.admin)
          ? FloatingActionButton.extended(
              heroTag: "newInquiryButton",
              label: const Text('New Inquiry'),
              icon: const Icon(Icons.add),
              onPressed: () => context.go(AppRoutes.newInquiry),
            )
          : null,
    );
  }

  Future<void> _openBulkAssignDialog() async {
    final controller = TextEditingController();
    List<Map<String, dynamic>> results = [];
    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSt) {
            return AlertDialog(
              title: const Text('Assign selected to user'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      labelText: 'Search by name',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (v) async {
                      final q = v.trim();
                      if (q.isEmpty) {
                        setSt(() => results = []);
                        return;
                      }
                      final r = await dbService.searchUsers(q, limit: 10);
                      setSt(() => results = r);
                    },
                  ),
                  const SizedBox(height: JMSpacing.md),
                  SizedBox(
                    width: 400,
                    height: 240,
                    child: results.isEmpty
                        ? const Center(child: Text('No results'))
                        : ListView.builder(
                            itemCount: results.length,
                            itemBuilder: (context, index) {
                              final u = results[index];
                              return ListTile(
                                title:
                                    Text(u['name'] ?? u['email'] ?? 'Unknown'),
                                subtitle: Text(u['email'] ?? ''),
                                onTap: () async {
                                  final ids = _selectedIds.toList();
                                  for (final id in ids) {
                                    await dbService.assignInquiry(
                                      inquiryId: id,
                                      assignedTo: u['uid'] as String?,
                                      assignedToName:
                                          (u['name'] ?? u['email']) as String?,
                                    );
                                  }
                                  if (mounted)
                                    setState(() => _selectedIds.clear());
                                  if (mounted) Navigator.of(ctx).pop();
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Assigned')),
                                    );
                                  }
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

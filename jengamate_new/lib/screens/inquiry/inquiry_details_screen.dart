import 'package:jengamate/models/inquiry.dart';
import 'package:flutter/material.dart';
import 'package:jengamate/ui/design_system/layout/adaptive_padding.dart';
import 'package:jengamate/ui/design_system/tokens/spacing.dart';
import 'package:jengamate/ui/design_system/components/jm_card.dart';
import 'package:jengamate/services/database_service.dart';
import 'package:provider/provider.dart';
import 'package:jengamate/services/user_state_provider.dart';
import 'package:jengamate/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;

class InquiryDetailsScreen extends StatefulWidget {
  final Inquiry inquiry;

  const InquiryDetailsScreen({super.key, required this.inquiry});

  @override
  State<InquiryDetailsScreen> createState() => _InquiryDetailsScreenState();
}

class _InquiryDetailsScreenState extends State<InquiryDetailsScreen> {
  final _db = DatabaseService();
  late String _status;
  late String _priority;
  String? _assignedTo;
  String? _assignedToName;
  
  void _logInquiryDetails(String methodName) {
    print('🔍 $methodName()');
    print('   Inquiry ID: ${widget.inquiry.uid} (length: ${widget.inquiry.uid.length})');
    print('   Status: ${widget.inquiry.status}');
    print('   Priority: ${widget.inquiry.priority}');
    
    // Safely log description with null check and length handling
    final description = widget.inquiry.description ?? '';
    final descriptionPreview = description.isNotEmpty 
        ? '${description.substring(0, description.length > 30 ? 30 : description.length)}...' 
        : 'No description';
    print('   Description: $descriptionPreview');
  }

  @override
  void initState() {
    super.initState();
    _logInquiryDetails('initState');
    
    try {
      _status = widget.inquiry.status.toLowerCase();
      _priority = widget.inquiry.priority;
      _assignedTo = widget.inquiry.assignedTo;
      _assignedToName = widget.inquiry.assignedToName;
      
      print('✅ Local state initialized');
      print('   _status: "$_status" (length: ${_status.length})');
      print('   _priority: "$_priority"');
      print('   _assignedTo: $_assignedTo');
      print('   _assignedToName: $_assignedToName');
    } catch (e) {
      print('❌ Error initializing state: $e');
      print('   Stack trace: ${e is Error ? e.stackTrace : ''}');
      rethrow;
    }
  }

  Widget _buildActivityTimeline(Inquiry inquiry) {
    return JMCard(
      child: Padding(
        padding: const EdgeInsets.all(JMSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Activity',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: JMSpacing.sm),
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: _db.streamInquiryActivities(inquiry.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: LinearProgressIndicator(),
                  );
                }
                final items = snapshot.data ?? const [];
                if (items.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('No activity yet.'),
                  );
                }
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const Divider(height: 8),
                  itemBuilder: (context, index) {
                    final a = items[index];
                    final type = a['type'] as String? ?? 'comment';
                    final userName = a['userName'] as String? ?? 'Unknown';
                    final ts = a['timestamp'];
                    final time = ts is Timestamp ? (ts).toDate() : null;
                    if (type == 'status') {
                      final from =
                          (a['from'] as String? ?? '').replaceAll('_', ' ');
                      final to =
                          (a['to'] as String? ?? '').replaceAll('_', ' ');
                      return ListTile(
                        leading: const Icon(Icons.flag_outlined),
                        title: Text('Status changed: $from → $to'),
                        subtitle: Text(
                            'by $userName${time != null ? ' • ${time.toLocal()}' : ''}'),
                      );
                    }
                    return ListTile(
                      leading: const Icon(Icons.chat_bubble_outline),
                      title: Text(a['text'] as String? ?? ''),
                      subtitle: Text(
                          'by $userName${time != null ? ' • ${time.toLocal()}' : ''}'),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentComposer(Inquiry inquiry) {
    final controller = TextEditingController();
    return JMCard(
      child: Padding(
        padding: const EdgeInsets.all(JMSpacing.md),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'Add a comment',
                ),
                minLines: 1,
                maxLines: 4,
              ),
            ),
            const SizedBox(width: JMSpacing.md),
            ElevatedButton.icon(
              icon: const Icon(Icons.send),
              label: const Text('Post'),
              onPressed: () async {
                final text = controller.text.trim();
                if (text.isEmpty) return;
                final currentUser = context.read<UserModel?>();
                await _db.addInquiryComment(
                  inquiryId: inquiry.uid,
                  userId: currentUser?.uid ?? 'system',
                  userName: currentUser?.name ?? 'System',
                  text: text,
                );
                await _db.sendInquiryNotification(
                  userId: inquiry.userId,
                  title:
                      'New comment on inquiry ${inquiry.uid.length >= 8 ? inquiry.uid.substring(0, 8) : inquiry.uid}',
                  body: text,
                );
                controller.clear();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Comment posted')),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void didUpdateWidget(InquiryDetailsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _logInquiryDetails('didUpdateWidget');
    
    if (oldWidget.inquiry.uid != widget.inquiry.uid) {
      print('🔄 Inquiry ID changed from ${oldWidget.inquiry.uid} to ${widget.inquiry.uid}');
      setState(() {
        _status = widget.inquiry.status.toLowerCase();
        _priority = widget.inquiry.priority;
        _assignedTo = widget.inquiry.assignedTo;
        _assignedToName = widget.inquiry.assignedToName;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    _logInquiryDetails('build');
    final inquiry = widget.inquiry;
    
    if (inquiry.uid.isEmpty) {
      print('❌ CRITICAL: Empty inquiry ID in build()');
      return const Scaffold(
        body: Center(
          child: Text('Error: Invalid inquiry data. Please try again.'),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(
            'Inquiry #${inquiry.uid.length >= 8 ? inquiry.uid.substring(0, 8) : inquiry.uid}'),
        actions: [
          IconButton(
            tooltip: 'Mark Resolved',
            icon: const Icon(Icons.check_circle_outline),
            onPressed: () async {
              final currentUser = context.read<UserModel?>();
              final old = _status;
              await _db.updateInquiryStatus(inquiry.uid, 'resolved');
              await _db.logInquiryStatusChange(
                inquiryId: inquiry.uid,
                fromStatus: old,
                toStatus: 'resolved',
                userId: currentUser?.uid ?? 'system',
                userName: currentUser?.name ?? 'System',
              );
              await _db.sendInquiryNotification(
                userId: inquiry.userId,
                title:
                    'Inquiry ${inquiry.uid.length >= 8 ? inquiry.uid.substring(0, 8) : inquiry.uid} updated',
                body: 'Status changed to Resolved',
              );
              setState(() => _status = 'resolved');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Inquiry marked as Resolved')),
              );
            },
          ),
          IconButton(
            tooltip: 'Close Inquiry',
            icon: const Icon(Icons.cancel_outlined),
            onPressed: () async {
              final currentUser = context.read<UserModel?>();
              final old = _status;
              await _db.updateInquiryStatus(inquiry.uid, 'closed');
              await _db.logInquiryStatusChange(
                inquiryId: inquiry.uid,
                fromStatus: old,
                toStatus: 'closed',
                userId: currentUser?.uid ?? 'system',
                userName: currentUser?.name ?? 'System',
              );
              await _db.sendInquiryNotification(
                userId: inquiry.userId,
                title:
                    'Inquiry ${inquiry.uid.length >= 8 ? inquiry.uid.substring(0, 8) : inquiry.uid} updated',
                body: 'Status changed to Closed',
              );
              setState(() => _status = 'closed');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Inquiry closed')),
              );
            },
          ),
        ],
      ),
      body: AdaptivePadding(
        child: ListView(
          children: [
            _buildHeaderCard(inquiry),
            const SizedBox(height: JMSpacing.md),
            _buildProjectInfoCard(inquiry),
            const SizedBox(height: JMSpacing.md),
            _buildProductList(inquiry),
            const SizedBox(height: JMSpacing.md),
            _buildActivityTimeline(inquiry),
            const SizedBox(height: JMSpacing.md),
            _buildCommentComposer(inquiry),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard(Inquiry inquiry) {
    return JMCard(
      child: Padding(
        padding: const EdgeInsets.all(JMSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(inquiry.subject,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: JMSpacing.sm),
            Text(inquiry.description),
            const SizedBox(height: JMSpacing.md),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _status,
                    decoration: const InputDecoration(labelText: 'Status'),
                    items: const [
                      DropdownMenuItem(value: 'open', child: Text('Open')),
                      DropdownMenuItem(
                          value: 'pending', child: Text('Open (Legacy)')),
                      DropdownMenuItem(
                          value: 'in_progress', child: Text('In Progress')),
                      DropdownMenuItem(
                          value: 'waiting_for_response',
                          child: Text('Waiting for Response')),
                      DropdownMenuItem(
                          value: 'resolved', child: Text('Resolved')),
                      DropdownMenuItem(value: 'closed', child: Text('Closed')),
                    ],
                    onChanged: (v) async {
                      if (v == null) return;
                      
                      print('🔄 === STATUS CHANGE INITIATED ===');
                      print('   Inquiry ID: "${inquiry.uid}" (length: ${inquiry.uid.length})');
                      print('   Current status: "$_status" (length: ${_status.length})');
                      print('   New status: "$v" (length: ${v.length})');
                      
                      if (inquiry.uid.isEmpty) {
                        final error = '❌ CRITICAL: Cannot update status - Empty inquiry ID';
                        print(error);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(error)),
                        );
                        return;
                      }
                      
                      final currentUser = context.read<UserModel?>();
                      final old = _status;
                      
                      try {
                        print('📡 Attempting to update status in Firestore...');
                        print('   Calling updateInquiryStatus("${inquiry.uid}", "$v")');
                        
                        await _db.updateInquiryStatus(inquiry.uid, v);
                        
                        print('✅ Status updated successfully');
                        print('   Updating local state...');
                        
                        setState(() {
                          _status = v;
                        });
                        
                        print('✅ Local state updated');
                      } catch (e, stack) {
                        final error = '❌ Error updating inquiry status: $e';
                        print(error);
                        print('   Stack trace: $stack');
                        
                        // Show error to user
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to update status: ${e.toString()}'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                      await _db.logInquiryStatusChange(
                        inquiryId: inquiry.uid,
                        fromStatus: old,
                        toStatus: v,
                        userId: currentUser?.uid ?? 'system',
                        userName: currentUser?.name ?? 'System',
                      );
                      await _db.sendInquiryNotification(
                        userId: inquiry.userId,
                        title:
                            'Inquiry ${inquiry.uid.length >= 8 ? inquiry.uid.substring(0, 8) : inquiry.uid} updated',
                        body: 'Status changed to ${v.replaceAll('_', ' ')}',
                      );
                      setState(() => _status = v);
                    },
                  ),
                ),
                const SizedBox(width: JMSpacing.md),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _priority,
                    decoration: const InputDecoration(labelText: 'Priority'),
                    items: const [
                      DropdownMenuItem(value: 'low', child: Text('Low')),
                      DropdownMenuItem(value: 'medium', child: Text('Medium')),
                      DropdownMenuItem(value: 'high', child: Text('High')),
                      DropdownMenuItem(value: 'urgent', child: Text('Urgent')),
                    ],
                    onChanged: (v) async {
                      if (v == null) return;
                      await _db.updateInquiryPriority(inquiry.uid, v);
                      setState(() => _priority = v);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: JMSpacing.md),
            Row(
              children: [
                Expanded(
                  child: Text(
                      _assignedToName == null || _assignedToName!.isEmpty
                          ? 'Unassigned'
                          : 'Assigned to: $_assignedToName'),
                ),
                TextButton.icon(
                  onPressed: () => _openAssignDialog(inquiry),
                  icon: const Icon(Icons.person_add_alt),
                  label: const Text('Assign'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openAssignDialog(Inquiry inquiry) async {
    final controller = TextEditingController();
    List<Map<String, dynamic>> results = [];
    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSt) {
            return AlertDialog(
              title: const Text('Assign to user'),
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
                      final r = await _db.searchUsers(q, limit: 10);
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
                                  await _db.assignInquiry(
                                    inquiryId: inquiry.uid,
                                    assignedTo: u['uid'] as String?,
                                    assignedToName:
                                        (u['name'] ?? u['email']) as String?,
                                  );
                                  setState(() {
                                    _assignedTo = u['uid'] as String?;
                                    _assignedToName =
                                        (u['name'] ?? u['email']) as String?;
                                  });
                                  if (mounted) Navigator.of(ctx).pop();
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

  Widget _buildProjectInfoCard(Inquiry inquiry) {
    return JMCard(
      child: Padding(
        padding: const EdgeInsets.all(JMSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Project Information',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: JMSpacing.sm),
            Text(
                'Project Name: ${inquiry.projectInfo?['projectName'] ?? 'N/A'}'),
            Text(
                'Delivery Address: ${inquiry.projectInfo?['deliveryAddress'] ?? 'N/A'}'),
            Text(
                'Expected Delivery Date: ${inquiry.projectInfo?['expectedDeliveryDate'] ?? 'N/A'}'),
            Text(
                'Transport Needed: ${(inquiry.projectInfo?['transportNeeded'] ?? false) ? 'Yes' : 'No'}'),
          ],
        ),
      ),
    );
  }

  Widget _buildProductList(Inquiry inquiry) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Products',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: JMSpacing.sm),
        ...?inquiry.products?.map((productId) {
          return JMCard(
            margin: const EdgeInsets.only(bottom: JMSpacing.md),
            child: Padding(
              padding: const EdgeInsets.all(JMSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Product ID: $productId'),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }
}

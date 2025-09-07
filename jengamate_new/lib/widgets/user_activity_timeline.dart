import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:jengamate/models/admin_user_activity.dart';

class UserActivityTimeline extends StatelessWidget {
  final List<AdminUserActivity> activities;
  final bool isLoading;

  const UserActivityTimeline({
    Key? key,
    required this.activities,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (activities.isEmpty) {
      return const Center(
        child: Text('No activities found'),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: activities.length,
      itemBuilder: (context, index) {
        final activity = activities[index];
        return _buildActivityItem(context, activity, index);
      },
    );
  }

  Widget _buildActivityItem(
      BuildContext context, AdminUserActivity activity, int index) {
    final isLast = index == activities.length - 1;
    final icon = _getActivityIcon(activity.action);
    final color = _getActivityColor(activity.action);
    final description = _getActivityDescription(activity);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 60,
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: Colors.grey[300],
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Card(
                elevation: 1,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            activity.action.toUpperCase(),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                          Text(
                            DateFormat('MMM dd, yyyy HH:mm')
                                .format(activity.timestamp),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        description,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      if (activity.ipAddress.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          'IP: ${activity.ipAddress}',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                        ),
                      ],
                      if (activity.metadata?.isNotEmpty ?? false) ...[
                        const SizedBox(height: 8),
                        _buildMetadataSection(activity.metadata!),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataSection(Map<String, dynamic> metadata) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Additional Details:',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        ...metadata.entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(left: 8.0, bottom: 2.0),
            child: Text(
              '${entry.key}: ${entry.value}',
              style: const TextStyle(fontSize: 11),
            ),
          );
        }).toList(),
      ],
    );
  }

  IconData _getActivityIcon(String action) {
    switch (action.toLowerCase()) {
      case 'login':
        return Icons.login;
      case 'logout':
        return Icons.logout;
      case 'register':
        return Icons.person_add;
      case 'update_profile':
        return Icons.edit;
      case 'upload_document':
        return Icons.upload_file;
      case 'submit_rfq':
        return Icons.assignment_add;
      case 'submit_quote':
        return Icons.price_check;
      case 'approve':
        return Icons.check_circle;
      case 'reject':
        return Icons.cancel;
      case 'suspend':
        return Icons.block;
      case 'reactivate':
        return Icons.refresh;
      case 'delete':
        return Icons.delete;
      case 'view':
        return Icons.visibility;
      case 'download':
        return Icons.download;
      default:
        return Icons.info;
    }
  }

  Color _getActivityColor(String action) {
    switch (action.toLowerCase()) {
      case 'login':
      case 'register':
        return Colors.green;
      case 'logout':
        return Colors.orange;
      case 'update_profile':
      case 'upload_document':
        return Colors.blue;
      case 'submit_rfq':
      case 'submit_quote':
        return Colors.purple;
      case 'approve':
      case 'reactivate':
        return Colors.green;
      case 'reject':
      case 'suspend':
      case 'delete':
        return Colors.red;
      case 'view':
      case 'download':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  String _getActivityDescription(AdminUserActivity activity) {
    switch (activity.action.toLowerCase()) {
      case 'login':
        return 'User logged in from ${activity.ipAddress}';
      case 'logout':
        return 'User logged out';
      case 'register':
        return 'New user registration completed';
      case 'update_profile':
        return 'Profile information updated';
      case 'upload_document':
        final docType = activity.metadata?['documentType'] ?? 'document';
        return 'Uploaded $docType for verification';
      case 'submit_rfq':
        return 'Submitted new RFQ request';
      case 'submit_quote':
        return 'Submitted quote for RFQ';
      case 'approve':
        final target = activity.metadata?['target'] ?? 'user';
        return 'Approved $target';
      case 'reject':
        final target = activity.metadata?['target'] ?? 'user';
        return 'Rejected $target';
      case 'suspend':
        final reason = activity.metadata?['reason'] ?? '';
        return 'Account suspended${reason.isNotEmpty ? ': $reason' : ''}';
      case 'reactivate':
        return 'Account reactivated';
      case 'delete':
        final target = activity.metadata?['target'] ?? 'user';
        return 'Deleted $target';
      case 'view':
        final target = activity.metadata?['target'] ?? 'page';
        return 'Viewed $target';
      case 'download':
        final file = activity.metadata?['file'] ?? 'file';
        return 'Downloaded $file';
      default:
        return 'Activity: ${activity.action}';
    }
  }
}

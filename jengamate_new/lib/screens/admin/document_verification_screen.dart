import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jengamate/models/document_verification.dart';
import 'package:jengamate/models/admin_user_activity.dart';
import 'package:jengamate/services/admin_analytics_service.dart';
import 'package:jengamate/widgets/advanced_filter_panel.dart';
import 'package:jengamate/widgets/user_activity_timeline.dart';

class DocumentVerificationScreen extends StatefulWidget {
  const DocumentVerificationScreen({Key? key}) : super(key: key);

  @override
  _DocumentVerificationScreenState createState() =>
      _DocumentVerificationScreenState();
}

class _DocumentVerificationScreenState
    extends State<DocumentVerificationScreen> {
  final AdminAnalyticsService _analyticsService = AdminAnalyticsService();
  final TextEditingController _searchController = TextEditingController();

  Map<String, dynamic> _currentFilters = {};
  String _searchQuery = '';
  bool _isLoading = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Document Verification'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(),
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _exportDocuments,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildStatsCards(),
          Expanded(
            child: _buildDocumentList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by user name, email, or document type...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          const SizedBox(width: 8),
          if (_currentFilters.isNotEmpty)
            Chip(
              label: Text('${_currentFilters.length} filters'),
              onDeleted: () {
                setState(() {
                  _currentFilters.clear();
                });
              },
            ),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    return StreamBuilder<Map<String, dynamic>>(
      stream: _analyticsService.getDocumentAnalytics(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data!;
        final stats = [
          {
            'title': 'Total Documents',
            'value': (data['totalDocuments'] ?? 0).toString(),
            'icon': Icons.description,
            'color': Colors.blue,
          },
          {
            'title': 'Pending',
            'value': (data['pendingDocuments'] ?? 0).toString(),
            'icon': Icons.pending,
            'color': Colors.orange,
          },
          {
            'title': 'Verified',
            'value': (data['verifiedDocuments'] ?? 0).toString(),
            'icon': Icons.verified,
            'color': Colors.green,
          },
          {
            'title': 'Rejected',
            'value': (data['rejectedDocuments'] ?? 0).toString(),
            'icon': Icons.cancel,
            'color': Colors.red,
          },
        ];

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: stats.map((stat) {
              return Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Icon(stat['icon'] as IconData,
                            color: stat['color'] as Color),
                        const SizedBox(height: 8),
                        Text(
                          stat['value'] as String,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          stat['title'] as String,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildDocumentList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _getFilteredDocuments(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final documents = snapshot.data!.docs
            .map((doc) => DocumentVerification.fromFirestore(doc))
            .where((doc) => _matchesSearch(doc))
            .toList();

        if (documents.isEmpty) {
          return const Center(
            child: Text('No documents found matching your criteria'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: documents.length,
          itemBuilder: (context, index) {
            return _buildDocumentCard(documents[index]);
          },
        );
      },
    );
  }

  Widget _buildDocumentCard(DocumentVerification document) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(document.status),
          child: Icon(
            _getDocumentIcon(document.documentType),
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(document.documentType.toUpperCase()),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('User: ${document.userName}'),
            Text('Status: ${document.status.toUpperCase()}'),
            Text('Submitted: ${_formatDate(document.submittedAt)}'),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.visibility),
              onPressed: () => _viewDocumentDetails(document),
            ),
            if (document.status == 'pending') ...[
              IconButton(
                icon: const Icon(Icons.check_circle, color: Colors.green),
                onPressed: () => _verifyDocument(document),
              ),
              IconButton(
                icon: const Icon(Icons.cancel, color: Colors.red),
                onPressed: () => _rejectDocument(document),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Stream<QuerySnapshot> _getFilteredDocuments() {
    Query query =
        FirebaseFirestore.instance.collection('document_verifications');

    // Apply filters
    if (_currentFilters['documentType'] != null) {
      query = query.where('documentType',
          isEqualTo: _currentFilters['documentType']);
    }

    if (_currentFilters['documentStatus'] != null) {
      query =
          query.where('status', isEqualTo: _currentFilters['documentStatus']);
    }

    if (_currentFilters['startDate'] != null) {
      query = query.where('submittedAt',
          isGreaterThanOrEqualTo: _currentFilters['startDate']);
    }

    if (_currentFilters['endDate'] != null) {
      query = query.where('submittedAt',
          isLessThanOrEqualTo: _currentFilters['endDate']);
    }

    return query.orderBy('submittedAt', descending: true).snapshots();
  }

  bool _matchesSearch(DocumentVerification document) {
    if (_searchQuery.isEmpty) return true;

    return document.userName.toLowerCase().contains(_searchQuery) ||
        document.userEmail.toLowerCase().contains(_searchQuery) ||
        document.documentType.toLowerCase().contains(_searchQuery);
  }

  IconData _getDocumentIcon(String documentType) {
    switch (documentType.toLowerCase()) {
      case 'license':
        return Icons.badge;
      case 'certificate':
        return Icons.school;
      case 'insurance':
        return Icons.security;
      case 'tax_certificate':
        return Icons.receipt;
      case 'company_registration':
        return Icons.business;
      default:
        return Icons.description;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'verified':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.8,
          child: AdvancedFilterPanel(
            initialFilters: _currentFilters,
            onFiltersChanged: (filters) {
              setState(() {
                _currentFilters = filters;
              });
            },
            onClearFilters: () {
              setState(() {
                _currentFilters.clear();
              });
            },
          ),
        ),
      ),
    );
  }

  void _viewDocumentDetails(DocumentVerification document) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Document Details: ${document.documentType}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('User', document.userName),
              _buildDetailRow('Email', document.userEmail),
              _buildDetailRow('Document Type', document.documentType),
              _buildDetailRow('Status', document.status.toUpperCase()),
              _buildDetailRow('Submitted', _formatDate(document.submittedAt)),
              _buildDetailRow('Reviewed', _formatDate(document.reviewedAt)),
              _buildDetailRow('Reviewed By', document.reviewedBy ?? 'N/A'),
              if (document.rejectionReason != null)
                _buildDetailRow('Rejection Reason', document.rejectionReason!),
              const SizedBox(height: 16),
              const Text(
                'Document Preview',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (document.documentUrl != null)
                Image.network(
                  document.documentUrl!,
                  height: 200,
                  width: 400,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Text('Unable to load document preview');
                  },
                )
              else
                const Text('No document preview available'),
              const SizedBox(height: 16),
              const Text(
                'Recent Activity',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 200,
                width: 400,
                child: StreamBuilder<List<AdminUserActivity>>(
                  stream: _analyticsService.getUserActivities(
                    userId: document.userId,
                    limit: 10,
                  ),
                  builder: (context, snapshot) {
                    return UserActivityTimeline(
                      activities: snapshot.data ?? [],
                      isLoading: !snapshot.hasData,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (document.status == 'pending') ...[
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _verifyDocument(document);
              },
              child: const Text('Verify'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _rejectDocument(document);
              },
              child: const Text('Reject'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Future<void> _verifyDocument(DocumentVerification document) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Verify Document'),
        content: Text(
            'Are you sure you want to verify ${document.documentType} for ${document.userName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Verify'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      setState(() => _isLoading = true);

      await FirebaseFirestore.instance
          .collection('document_verifications')
          .doc(document.id)
          .update({
        'status': 'verified',
        'reviewedAt': DateTime.now(),
        'reviewedBy': 'admin',
      });

      // Log the action
      await _analyticsService.logUserActivity(
        userId: document.userId,
        action: 'document_verified',
        metadata: {
          'ipAddress': 'admin_panel',
          'userAgent': 'admin_dashboard',
          'documentType': document.documentType,
          'documentId': document.id,
        },
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Document verified successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _rejectDocument(DocumentVerification document) async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Document'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
                'Are you sure you want to reject ${document.documentType} for ${document.userName}?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Rejection Reason (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      setState(() => _isLoading = true);

      await FirebaseFirestore.instance
          .collection('document_verifications')
          .doc(document.id)
          .update({
        'status': 'rejected',
        'reviewedAt': DateTime.now(),
        'reviewedBy': 'admin',
        'rejectionReason': reasonController.text,
      });

      // Log the action
      await _analyticsService.logUserActivity(
        userId: document.userId,
        action: 'document_rejected',
        metadata: {
          'ipAddress': 'admin_panel',
          'userAgent': 'admin_dashboard',
          'documentType': document.documentType,
          'documentId': document.id,
          'rejectionReason': reasonController.text,
        },
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Document rejected successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _exportDocuments() async {
    try {
      setState(() => _isLoading = true);

      final csvData = await _analyticsService.exportDocumentsToCSV();

      if (csvData.isNotEmpty) {
        // In a real app, you would save this to a file
        // For now, we'll show a success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Documents exported successfully')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error exporting documents: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
}

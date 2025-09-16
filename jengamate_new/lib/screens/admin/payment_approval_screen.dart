import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jengamate/models/payment_model.dart';
import 'package:jengamate/models/enums/payment_enums.dart';
import 'package:jengamate/services/payment_service.dart';
import 'package:jengamate/services/admin_notification_service.dart';
import 'package:jengamate/utils/logger.dart';
import 'package:intl/intl.dart';
import 'package:jengamate/utils/string_utils.dart';

enum PaymentFilter {
  all,
  pendingApproval,
  awaitingVerification,
  underReview,
  approved,
  rejected,
  completed,
  failed
}

class PaymentApprovalScreen extends StatefulWidget {
  const PaymentApprovalScreen({Key? key}) : super(key: key);

  @override
  _PaymentApprovalScreenState createState() => _PaymentApprovalScreenState();
}

class _PaymentApprovalScreenState extends State<PaymentApprovalScreen> {
  final PaymentService _paymentService = PaymentService();
  final AdminNotificationService _notificationService = AdminNotificationService();

  PaymentFilter _currentFilter = PaymentFilter.all;
  String _searchQuery = '';
  bool _showFilters = false;
  final NumberFormat _currencyFormat = NumberFormat.currency(symbol: 'TSH ', decimalDigits: 2);
  bool _isLoading = false;

  StreamSubscription<QuerySnapshot>? _paymentsSubscription;
  List<PaymentModel> _payments = [];
  List<PaymentModel> _filteredPayments = [];
  Set<String> _selectedPayments = {};
  final Map<String, String?> _proofUrlCache = {};
  final Set<String> _proofsFetching = {};

  @override
  void initState() {
    super.initState();
    _setupPaymentsListener();
  }

  @override
  void dispose() {
    _paymentsSubscription?.cancel();
    super.dispose();
  }

  void _setupPaymentsListener() {
    _paymentsSubscription = FirebaseFirestore.instance
        .collection('payments')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen(_handlePaymentsUpdate);
  }

  void _handlePaymentsUpdate(QuerySnapshot snapshot) {
    if (mounted) {
      final payments = snapshot.docs
          .map((doc) => PaymentModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();

      setState(() {
        _payments = payments;
        _applyFilters();
      });

      // For payments without a proof URL in Firestore, try fetching from Supabase
      for (final p in payments) {
        if ((p.paymentProofUrl == null || p.paymentProofUrl!.isEmpty) && !_proofsFetching.contains(p.id)) {
          _fetchProofUrlFromSupabase(p.id);
        } else if (p.paymentProofUrl != null) {
          // keep cache up to date
          _proofUrlCache[p.id] = p.paymentProofUrl;
        }
      }
    }
  }

  Future<void> _fetchProofUrlFromSupabase(String paymentId) async {
    try {
      _proofsFetching.add(paymentId);
      
      // Only attempt Supabase lookup for valid UUIDs (Supabase payment IDs)
      // Skip Firebase document IDs as they won't exist in Supabase
      if (!PaymentService.isValidUUID(paymentId)) {
        // This is expected behavior - Firebase uses different ID format than Supabase
        // Only log as debug to reduce noise, not as regular info
        Logger.log('Firebase payment ID detected (not Supabase UUID): $paymentId');
        return;
      }
      
      final supPayment = await _paymentService.getPaymentById(paymentId);
      if (supPayment != null && supPayment.paymentProofUrl != null && supPayment.paymentProofUrl!.isNotEmpty) {
        _proofUrlCache[paymentId] = supPayment.paymentProofUrl;
        if (mounted) setState(() {});
      }
    } catch (e, st) {
      Logger.logError('Failed to fetch proof URL from Supabase for $paymentId', e, st);
    } finally {
      _proofsFetching.remove(paymentId);
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredPayments = _payments.where((payment) {
        // Apply status filter
        final statusMatch = _currentFilter == PaymentFilter.all ||
            _matchesFilter(payment.status);

        // Apply search filter
        final searchMatch = _searchQuery.isEmpty ||
            payment.id.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            payment.orderId.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            payment.userId.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            (payment.transactionId?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);

        return statusMatch && searchMatch;
      }).toList();
    });
  }

  bool _matchesFilter(PaymentStatus status) {
    switch (_currentFilter) {
      case PaymentFilter.all:
        return true;
      case PaymentFilter.pendingApproval:
        return status == PaymentStatus.pendingApproval;
      case PaymentFilter.awaitingVerification:
        return status == PaymentStatus.awaitingVerification;
      case PaymentFilter.underReview:
        return status == PaymentStatus.underReview;
      case PaymentFilter.approved:
        return status == PaymentStatus.approved;
      case PaymentFilter.rejected:
        return status == PaymentStatus.rejected;
      case PaymentFilter.completed:
        return status == PaymentStatus.completed;
      case PaymentFilter.failed:
        return status == PaymentStatus.failed;
      // All enum cases handled above
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Approval'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => setState(() => _showFilters = !_showFilters),
            tooltip: 'Toggle Filters',
          ),
        ],
      ),
        body: Column(
        children: [
          if (_showFilters) _buildFilterPanel(isMobile),
          _buildSearchBar(isMobile),
          _buildStatsCards(isMobile),
          if (_filteredPayments.isNotEmpty && _currentFilter != PaymentFilter.approved && _currentFilter != PaymentFilter.completed)
            _buildBulkActionsBar(isMobile),
          Expanded(
            child: _buildPaymentsList(isMobile),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: "paymentApprovalAdd",
        onPressed: _showAddOptions,
        tooltip: 'Add Options',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFilterPanel(bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
      color: Colors.grey.shade50,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filter by Status',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: PaymentFilter.values.map((filter) {
              final isSelected = _currentFilter == filter;
              final count = _getFilterCount(filter);
              return FilterChip(
                label: Text('${_getFilterLabel(filter)} ($count)'),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _currentFilter = selected ? filter : PaymentFilter.all;
                    _applyFilters();
                  });
                },
                backgroundColor: isSelected ? Theme.of(context).primaryColor.withOpacity(0.1) : null,
                selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(bool isMobile) {
    return Padding(
      padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search payments by ID, order, transaction...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      _searchQuery = '';
                      _applyFilters();
                    });
                  },
                )
              : null,
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
            _applyFilters();
          });
        },
      ),
    );
  }

  Widget _buildStatsCards(bool isMobile) {
    final pendingCount = _payments.where((p) => p.status == PaymentStatus.pendingApproval).length;
    final awaitingVerificationCount = _payments.where((p) => p.status == PaymentStatus.awaitingVerification).length;
    final underReviewCount = _payments.where((p) => p.status == PaymentStatus.underReview).length;
    final approvedCount = _payments.where((p) => p.status == PaymentStatus.approved).length;
    final rejectedCount = _payments.where((p) => p.status == PaymentStatus.rejected).length;
    final autoApprovedCount = _payments.where((p) => p.autoApproved == true).length;

    final stats = [
      {'title': 'Pending Approval', 'value': pendingCount.toString(), 'color': Colors.orange},
      {'title': 'Awaiting Verification', 'value': awaitingVerificationCount.toString(), 'color': Colors.blue},
      {'title': 'Under Review', 'value': underReviewCount.toString(), 'color': Colors.purple},
      {'title': 'Approved', 'value': approvedCount.toString(), 'color': Colors.green},
      {'title': 'Rejected', 'value': rejectedCount.toString(), 'color': Colors.red},
      {'title': 'Auto-Approved', 'value': autoApprovedCount.toString(), 'color': Colors.teal},
    ];

    return Container(
      height: 100,
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 12.0 : 16.0),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: stats.length,
        itemBuilder: (context, index) {
          final stat = stats[index];
          return Container(
            width: isMobile ? 140 : 180,
            margin: const EdgeInsets.only(right: 12),
            child: Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      stat['value'] as String,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: stat['color'] as Color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      stat['title'] as String,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBulkActionsBar(bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
      color: Colors.blue.shade50,
      child: Row(
        children: [
          Checkbox(
            value: _selectedPayments.length == _filteredPayments.length && _filteredPayments.isNotEmpty,
            onChanged: (value) {
              setState(() {
                if (value == true) {
                  _selectedPayments = _filteredPayments.map((p) => p.id).toSet();
                } else {
                  _selectedPayments.clear();
                }
              });
            },
          ),
          Text(
            'Select All (${_selectedPayments.length} selected)',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          if (_selectedPayments.isNotEmpty) ...[
            ElevatedButton.icon(
              onPressed: _bulkApproveSelected,
              icon: const Icon(Icons.check, size: 16),
              label: const Text('Approve Selected'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: _bulkRejectSelected,
              icon: const Icon(Icons.close, size: 16),
              label: const Text('Reject Selected'),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                foregroundColor: Colors.red,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentsList(bool isMobile) {
    if (_filteredPayments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.payment,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No payments found',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Try adjusting your search or filters'
                  : 'All payments have been processed',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
      itemCount: _filteredPayments.length,
      itemBuilder: (context, index) {
        final payment = _filteredPayments[index];
        return _buildPaymentCard(payment, isMobile);
      },
    );
  }

  Widget _buildPaymentCard(PaymentModel payment, bool isMobile) {
    final canApprove = payment.status == PaymentStatus.pendingApproval ||
                      payment.status == PaymentStatus.awaitingVerification ||
                      payment.status == PaymentStatus.underReview;
    final canSelect = _currentFilter != PaymentFilter.approved && _currentFilter != PaymentFilter.completed;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Selection checkbox (only for pending payments)
            if (canSelect) ...[
              Row(
                children: [
                  Checkbox(
                    value: _selectedPayments.contains(payment.id),
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          _selectedPayments.add(payment.id);
                        } else {
                          _selectedPayments.remove(payment.id);
                        }
                      });
                    },
                  ),
                  const Text('Select for bulk action'),
                  const Spacer(),
                ],
              ),
              const Divider(),
            ],
            // Header with status and amount
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Payment #${safePrefix(payment.id, 8)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Order: ${safePrefix(payment.orderId, 8)}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(payment.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _getStatusColor(payment.status),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    _getStatusText(payment.status),
                    style: TextStyle(
                      color: _getStatusColor(payment.status),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Amount and details
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _currencyFormat.format(payment.amount),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    Text(
                      'Method: ${payment.paymentMethod}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _formatDateTime(payment.createdAt),
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                    if (payment.transactionId != null)
                      Text(
                        'Txn: ${payment.transactionId!.substring(0, 8)}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 10,
                        ),
                      ),
                  ],
                ),
              ],
            ),

            // Payment proof (show thumbnail + view). Use cached Supabase URL if Firestore doesn't have one.
            if ((payment.paymentProofUrl ?? _proofUrlCache[payment.id]) != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  // Thumbnail (image or file icon)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: () {
                      final proof = payment.paymentProofUrl ?? _proofUrlCache[payment.id];
                      if (proof == null) return Container(width: 60, height: 60);
                      final lower = proof.toLowerCase();
                      if (lower.endsWith('.pdf')) {
                        return Container(
                          width: 60,
                          height: 60,
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.picture_as_pdf, color: Colors.red, size: 36),
                        );
                      }
                      return Image.network(
                        proof,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 60,
                          height: 60,
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.broken_image, color: Colors.grey, size: 28),
                        ),
                      );
                    }(),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Payment proof available',
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _viewPaymentProof(payment.copyWith(paymentProofUrl: payment.paymentProofUrl ?? _proofUrlCache[payment.id])),
                    icon: const Icon(Icons.visibility, size: 16),
                    label: const Text('View'),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 0),
                    ),
                  ),
                ],
              ),
            ],

            // Action buttons
            if (canApprove) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _approvePayment(payment),
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Approve'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _rejectPayment(payment),
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('Reject'),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        foregroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 8),
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

  String _getFilterLabel(PaymentFilter filter) {
    switch (filter) {
      case PaymentFilter.all:
        return 'All';
      case PaymentFilter.pendingApproval:
        return 'Pending';
      case PaymentFilter.awaitingVerification:
        return 'Verification';
      case PaymentFilter.underReview:
        return 'Review';
      case PaymentFilter.approved:
        return 'Approved';
      case PaymentFilter.rejected:
        return 'Rejected';
      case PaymentFilter.completed:
        return 'Completed';
      case PaymentFilter.failed:
        return 'Failed';
    }
  }

  int _getFilterCount(PaymentFilter filter) {
    return _payments.where((payment) => _matchesFilter(payment.status)).length;
  }

  Color _getStatusColor(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.pendingApproval:
        return Colors.orange;
      case PaymentStatus.awaitingVerification:
        return Colors.blue;
      case PaymentStatus.underReview:
        return Colors.purple;
      case PaymentStatus.approved:
        return Colors.green;
      case PaymentStatus.rejected:
        return Colors.red;
      case PaymentStatus.completed:
        return Colors.teal;
      case PaymentStatus.failed:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.pendingApproval:
        return 'PENDING';
      case PaymentStatus.awaitingVerification:
        return 'VERIFY';
      case PaymentStatus.underReview:
        return 'REVIEW';
      case PaymentStatus.approved:
        return 'APPROVED';
      case PaymentStatus.rejected:
        return 'REJECTED';
      case PaymentStatus.completed:
        return 'COMPLETED';
      case PaymentStatus.failed:
        return 'FAILED';
      default:
        return 'UNKNOWN';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  Future<void> _approvePayment(PaymentModel payment) async {
    try {
      setState(() => _isLoading = true);

      // Update payment status
      await FirebaseFirestore.instance
          .collection('payments')
          .doc(payment.id)
          .update({
            'status': PaymentStatus.approved.name,
            'updatedAt': FieldValue.serverTimestamp(),
          });

      // Process the payment
      await _paymentService.updatePaymentStatus(payment.id, PaymentStatus.completed);

      // Send notification
      await _notificationService.createNotification(
        title: 'Payment Approved',
        message: 'Payment #${safePrefix(payment.id, 8)} for ${_currencyFormat.format(payment.amount)} has been approved',
        type: NotificationType.success,
        priority: NotificationPriority.medium,
        category: 'payment_approval',
        data: {'paymentId': payment.id, 'orderId': payment.orderId},
        broadcastToAllAdmins: true,
      );

      Logger.log('Payment approved: ${payment.id}');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment approved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      Logger.logError('Failed to approve payment', e, StackTrace.current);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to approve payment: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _rejectPayment(PaymentModel payment) async {
    try {
      setState(() => _isLoading = true);

      // Show rejection reason dialog
      final reason = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Reject Payment'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Please provide a reason for rejection:'),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  hintText: 'Rejection reason...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                onChanged: (value) {
                  // Store the reason temporarily
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                // Return the reason (for now, using a default)
                Navigator.of(context).pop('Invalid payment proof or insufficient documentation');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('Reject'),
            ),
          ],
        ),
      );

      if (reason == null) return;

      // Update payment status
      await FirebaseFirestore.instance
          .collection('payments')
          .doc(payment.id)
          .update({
            'status': PaymentStatus.rejected.name,
            'updatedAt': FieldValue.serverTimestamp(),
            'rejectionReason': reason,
          });

      // Send notification
      await _notificationService.createNotification(
        title: 'Payment Rejected',
        message: 'Payment #${payment.id.substring(0, 8)} has been rejected: $reason',
        type: NotificationType.warning,
        priority: NotificationPriority.medium,
        category: 'payment_rejection',
        data: {'paymentId': payment.id, 'reason': reason},
        broadcastToAllAdmins: true,
      );

      Logger.log('Payment rejected: ${payment.id}');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment rejected'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      Logger.logError('Failed to reject payment', e, StackTrace.current);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to reject payment: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _viewPaymentProof(PaymentModel payment) {
    if (payment.paymentProofUrl == null) return;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Payment Proof',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              payment.paymentProofUrl!.contains('.jpg') ||
              payment.paymentProofUrl!.contains('.png') ||
              payment.paymentProofUrl!.contains('.jpeg')
                  ? Image.network(
                      payment.paymentProofUrl!,
                      height: 300,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const Text('Failed to load image');
                      },
                    )
                  : const Text('Payment proof document'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.payment),
            title: const Text('Create Test Payment'),
            subtitle: const Text('Generate a sample payment for testing'),
            onTap: () {
              Navigator.of(context).pop();
              _createTestPayment();
            },
          ),
          ListTile(
            leading: const Icon(Icons.refresh),
            title: const Text('Refresh Payments'),
            subtitle: const Text('Reload payment data'),
            onTap: () {
              Navigator.of(context).pop();
              _refreshPayments();
            },
          ),
          ListTile(
            leading: const Icon(Icons.analytics),
            title: const Text('View Statistics'),
            subtitle: const Text('Show payment approval stats'),
            onTap: () {
              Navigator.of(context).pop();
              _showStatistics();
            },
          ),
          ListTile(
            leading: const Icon(Icons.sync),
            title: const Text('Resync Missing Proofs'),
            subtitle: const Text('Fetch missing proof URLs from Supabase and update Firestore'),
            onTap: () {
              Navigator.of(context).pop();
              _resyncMissingProofs();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _resyncMissingProofs() async {
    final missing = _payments.where((p) => p.paymentProofUrl == null || p.paymentProofUrl!.isEmpty).toList();
    if (missing.isEmpty) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No missing proofs to resync')));
      return;
    }

    setState(() => _isLoading = true);
    int updated = 0;

    for (final p in missing) {
      try {
        final sup = await _paymentService.getPaymentById(p.id);
        final proof = sup?.paymentProofUrl;
        if (proof != null && proof.isNotEmpty) {
          await FirebaseFirestore.instance.collection('payments').doc(p.id).update({'payment_proof_url': proof});
          _proofUrlCache[p.id] = proof;
          updated += 1;
        }
      } catch (e, st) {
        Logger.logError('Failed to resync proof for ${p.id}', e, st);
      }
    }

    // Refresh local list
    _refreshPayments();
    setState(() => _isLoading = false);

    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Resynced $updated/${missing.length} proofs')));
  }

  Future<void> _createTestPayment() async {
    try {
      // Create a test payment with proof
      final testPayment = PaymentModel(
        id: '',
        orderId: _generateTestUUID(),
        userId: 'test_user_${DateTime.now().millisecondsSinceEpoch}',
        amount: 50.0, // Small amount to potentially auto-approve
        status: PaymentStatus.pending,
        paymentMethod: 'bankTransfer',
        createdAt: DateTime.now(),
        paymentProofUrl: 'https://example.com/payment-proof.jpg', // Mock proof
      );

      final paymentId = await PaymentService().createPayment(testPayment);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Test payment created: ${paymentId.substring(0, 8)}'),
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create test payment: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _refreshPayments() {
    setState(() {
      // This will trigger the stream listener to refresh data
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Payments refreshed'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _showStatistics() async {
    // This would show detailed statistics about payment approvals
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Payment Approval Statistics'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total Payments: ${_payments.length}'),
            Text('Pending Approval: ${_payments.where((p) => p.status == PaymentStatus.pendingApproval).length}'),
            Text('Auto-Approved: ${_payments.where((p) => p.metadata?['autoApproved'] == true).length}'),
            Text('Approved: ${_payments.where((p) => p.status == PaymentStatus.approved).length}'),
            Text('Rejected: ${_payments.where((p) => p.status == PaymentStatus.rejected).length}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _bulkApproveSelected() async {
    if (_selectedPayments.isEmpty) return;

    try {
      setState(() => _isLoading = true);

      for (var paymentId in _selectedPayments) {
        // Update payment status
        await FirebaseFirestore.instance
            .collection('payments')
            .doc(paymentId)
            .update({
              'status': PaymentStatus.approved.name,
              'updatedAt': FieldValue.serverTimestamp(),
              'bulkApproved': true,
            });

        // Process the payment
        await _paymentService.updatePaymentStatus(paymentId, PaymentStatus.completed);
      }

      // Send notification
      await _notificationService.createNotification(
        title: 'Bulk Payment Approval',
        message: '${_selectedPayments.length} payments have been approved',
        type: NotificationType.success,
        priority: NotificationPriority.medium,
        category: 'bulk_payment_approval',
        data: {'paymentIds': _selectedPayments.toList()},
        broadcastToAllAdmins: true,
      );

      Logger.log('Bulk approved ${_selectedPayments.length} payments');

      setState(() => _selectedPayments.clear());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_selectedPayments.length} payments approved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      Logger.logError('Failed to bulk approve payments', e, StackTrace.current);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to approve payments: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _bulkRejectSelected() async {
    if (_selectedPayments.isEmpty) return;

    try {
      setState(() => _isLoading = true);

      final reason = 'Bulk rejection - Multiple payments rejected for review';

      for (var paymentId in _selectedPayments) {
        // Update payment status
        await FirebaseFirestore.instance
            .collection('payments')
            .doc(paymentId)
            .update({
              'status': PaymentStatus.rejected.name,
              'updatedAt': FieldValue.serverTimestamp(),
              'rejectionReason': reason,
              'bulkRejected': true,
            });
      }

      // Send notification
      await _notificationService.createNotification(
        title: 'Bulk Payment Rejection',
        message: '${_selectedPayments.length} payments have been rejected',
        type: NotificationType.warning,
        priority: NotificationPriority.medium,
        category: 'bulk_payment_rejection',
        data: {'paymentIds': _selectedPayments.toList(), 'reason': reason},
        broadcastToAllAdmins: true,
      );

      Logger.log('Bulk rejected ${_selectedPayments.length} payments');

      setState(() => _selectedPayments.clear());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_selectedPayments.length} payments rejected'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      Logger.logError('Failed to bulk reject payments', e, StackTrace.current);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to reject payments: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Generate a valid UUID v4 for testing purposes
  String _generateTestUUID() {
    // Simple UUID v4 generator for testing
    final random = DateTime.now().millisecondsSinceEpoch;
    const template = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx';
    return template.replaceAllMapped(RegExp(r'[xy]'), (match) {
      final r = (random + DateTime.now().microsecondsSinceEpoch) % 16;
      final v = match.group(0) == 'x' ? r : (r & 0x3 | 0x8);
      return v.toRadixString(16);
    });
  }
}

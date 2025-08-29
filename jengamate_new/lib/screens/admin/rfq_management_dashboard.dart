import 'package:flutter/material.dart';
import 'package:jengamate/models/rfq_model.dart';
import 'package:jengamate/services/database_service.dart';
import 'package:jengamate/services/notification_service.dart';
import 'package:jengamate/services/reporting_service.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:jengamate/config/app_routes.dart';
import 'package:jengamate/utils/theme.dart';
import 'package:jengamate/utils/logger.dart';
import 'dart:async';

class RfqManagementDashboard extends StatefulWidget {
  const RfqManagementDashboard({super.key});

  @override
  State<RfqManagementDashboard> createState() => _RfqManagementDashboardState();
}

class _RfqManagementDashboardState extends State<RfqManagementDashboard> with WidgetsBindingObserver {
   final _dbService = DatabaseService();
   final _notificationService = NotificationService();
   final _reportingService = ReportingService();
   final _searchController = TextEditingController();
   String _selectedStatus = 'All';
   String _selectedType = 'All';
   List<RFQModel> _filteredRfqs = [];
   List<RFQModel> _allRfqs = [];
   StreamSubscription<List<RFQModel>>? _rfqSubscription;
   bool _isLoading = true;
   bool _hasError = false;
   String _errorMessage = '';
   int _retryCount = 0;
   static const int _maxRetries = 3;

   final List<String> _statusOptions = ['All', 'Pending', 'Approved', 'Rejected', 'Processing', 'Completed'];
   final List<String> _typeOptions = ['All', 'Standard', 'Bid', 'Catalog', 'Marketplace'];

   // Date range filtering
   DateTime? _startDate;
   DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeStream();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _rfqSubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _retryConnection();
    }
  }

  void _initializeStream() {
    _rfqSubscription?.cancel();
    _rfqSubscription = _dbService.streamAllRFQs().listen(
      _onDataReceived,
      onError: _onStreamError,
      onDone: _onStreamDone,
    );
  }

  void _onDataReceived(List<RFQModel> rfqs) {
    setState(() {
      _allRfqs = rfqs;
      _isLoading = false;
      _hasError = false;
      _retryCount = 0;
      _filterRfqs();
    });
  }

  void _onStreamError(Object error) {
    Logger.logError('RFQ Stream Error', error, StackTrace.current);
    setState(() {
      _hasError = true;
      _errorMessage = error.toString();
      _isLoading = false;
    });
    _handleStreamError(error);
  }

  void _onStreamDone() {
    Logger.log('RFQ Stream completed');
  }

  void _handleStreamError(Object error) {
    if (_retryCount < _maxRetries) {
      _retryCount++;
      Future.delayed(Duration(seconds: _retryCount * 2), () {
        if (mounted) {
          _initializeStream();
        }
      });
    }
  }

  void _retryConnection() {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _retryCount = 0;
    });
    _initializeStream();
  }

  void _filterRfqs() {
    setState(() {
      _filteredRfqs = _allRfqs.where((rfq) {
        final matchesSearch = rfq.productName.toLowerCase().contains(_searchController.text.toLowerCase()) ||
                            rfq.customerName.toLowerCase().contains(_searchController.text.toLowerCase()) ||
                            rfq.id.toLowerCase().contains(_searchController.text.toLowerCase());
        final matchesStatus = _selectedStatus == 'All' || rfq.status == _selectedStatus;
        final matchesType = _selectedType == 'All' || _getTypeFromRfq(rfq) == _selectedType;
        
        return matchesSearch && matchesStatus && matchesType;
      }).toList();
    });
  }

  String _getTypeFromRfq(RFQModel rfq) {
    if (rfq.productName.toLowerCase().contains('bid')) return 'Bid';
    if (rfq.productName.toLowerCase().contains('catalog')) return 'Catalog';
    if (rfq.productName.toLowerCase().contains('marketplace')) return 'Marketplace';
    return 'Standard';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('RFQ List View - Dashboard'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: Colors.grey[200],
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_hasError) {
      return _buildErrorState();
    }

    if (_allRfqs.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        _buildFilterSection(),
        Expanded(child: _buildRfqTable()),
      ],
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading RFQs...', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red),
          SizedBox(height: 16),
          Text('Connection Error', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text(_errorMessage, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
          SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _retryConnection,
            icon: Icon(Icons.refresh),
            label: Text('Retry (${_retryCount}/${_maxRetries})'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.request_quote, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('No RFQs found', style: TextStyle(fontSize: 18, color: Colors.grey)),
          SizedBox(height: 8),
          Text('RFQs will appear here once customers submit requests', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => _filterRfqs(),
                    decoration: const InputDecoration(
                      hintText: 'Search RFQs...',
                      prefixIcon: Icon(Icons.search, color: Colors.grey),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedType,
                    hint: const Text('Type'),
                    items: _typeOptions.map((type) => DropdownMenuItem(
                      value: type,
                      child: Text(type),
                    )).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedType = value!;
                        _filterRfqs();
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedStatus,
                    hint: const Text('Status'),
                    items: _statusOptions.map((status) => DropdownMenuItem(
                      value: status,
                      child: Text(status),
                    )).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedStatus = value!;
                        _filterRfqs();
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_filteredRfqs.length} of ${_allRfqs.length}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: () {
                      setState(() {
                        _searchController.clear();
                        _selectedStatus = 'All';
                        _selectedType = 'All';
                        _filteredRfqs = _allRfqs;
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  const Text('Previous'),
                  const SizedBox(width: 16),
                  const Text('Next →'),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRfqTable() {
    return Container(
      margin: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                const Expanded(flex: 2, child: Text('Product/Service', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87))),
                const Expanded(flex: 2, child: Text('Type', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87))),
                const Expanded(flex: 2, child: Text('Quantity', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87))),
                const Expanded(flex: 2, child: Text('Date', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87))),
                const Expanded(flex: 2, child: Text('Status', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87))),
                const Expanded(flex: 2, child: Text('Amount', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87))),
                const Expanded(flex: 1, child: Text('Action', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87))),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _filteredRfqs.length,
              itemBuilder: (context, index) {
                final rfq = _filteredRfqs[index];
                return _buildTableRow(rfq, index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableRow(RFQModel rfq, int index) {
    final isEven = index % 2 == 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: isEven ? Colors.white : Colors.grey[25],
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!, width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              rfq.productName,
              style: const TextStyle(fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              _getTypeFromRfq(rfq),
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'SE-${rfq.id.substring(0, 6)}',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              DateFormat('dd MMM yy').format(rfq.createdAt),
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          Expanded(
            flex: 2,
            child: Wrap(
              spacing: 4.0, // gap between adjacent chips
              runSpacing: 4.0, // gap between lines
              children: [
                _buildStatusBadge('Received', Colors.blue),
                _buildStatusBadge('Responded', Colors.green),
                _buildStatusBadge('Evaluated', Colors.orange),
                _buildStatusBadge('Awarded', Colors.purple),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'TSh ${(rfq.quantity * 1000).toString()}',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            flex: 1,
            child: PopupMenuButton<String>(
              icon: const Icon(Icons.more_horiz),
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'view', child: Text('View')),
                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                const PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
              onSelected: (value) {
                switch (value) {
                  case 'view':
                    _viewRfqDetails(rfq);
                    break;
                  case 'edit':
                    _editRfqStatus(rfq);
                    break;
                  case 'delete':
                    _deleteRfq(rfq);
                    break;
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  void _deleteRfq(RFQModel rfq) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete RFQ'),
        content: Text('Are you sure you want to delete RFQ "${rfq.productName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('RFQ deleted successfully')),
                );
              } catch (e) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error deleting RFQ: $e')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'processing':
        return Colors.blue;
      case 'completed':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  void _viewRfqDetails(RFQModel rfq) {
    final path = AppRouteBuilders.rfqDetailsPath(rfq.id);
    context.go(path);
  }

  void _editRfqStatus(RFQModel rfq) {
    final statuses = ['Pending', 'Approved', 'Rejected', 'Processing', 'Completed'];
    String selected = rfq.status;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Status - ${rfq.productName}'),
          content: DropdownButtonFormField<String>(
            value: selected,
            decoration: const InputDecoration(
              labelText: 'Status',
              border: OutlineInputBorder(),
            ),
            items: statuses
                .map((s) => DropdownMenuItem<String>(value: s, child: Text(s)))
                .toList(),
            onChanged: (val) {
              if (val != null) selected = val;
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await _dbService.updateRFQStatus(rfq.id, selected);
                  if (context.mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Status updated to "$selected"')),
                    );
                    // Send notification for status change
                    await _sendStatusChangeNotification(rfq, selected);
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to update status: $e')),
                    );
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
   Future<void> _sendStatusChangeNotification(RFQModel rfq, String newStatus) async {
     try {
       await _notificationService.showNotification(
         title: 'RFQ Status Updated',
         body: 'RFQ "${rfq.productName}" status changed to $newStatus',
         payload: 'rfq/${rfq.id}',
       );
       Logger.log('Status change notification sent for RFQ: ${rfq.id}');
     } catch (e) {
       Logger.logError('Failed to send status change notification', e, StackTrace.current);
     }
   }
 }

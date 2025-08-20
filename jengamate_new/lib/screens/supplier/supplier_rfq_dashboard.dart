import 'package:flutter/material.dart';
import 'package:jengamate/models/product_interaction_model.dart';
import 'package:jengamate/models/user_model.dart';
import 'package:jengamate/services/product_interaction_service.dart';
import 'package:jengamate/services/auth_service.dart';
import 'package:jengamate/utils/logger.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class SupplierRFQDashboard extends StatefulWidget {
  const SupplierRFQDashboard({super.key});

  @override
  State<SupplierRFQDashboard> createState() => _SupplierRFQDashboardState();
}

class _SupplierRFQDashboardState extends State<SupplierRFQDashboard> {
  final ProductInteractionService _interactionService = ProductInteractionService();
  final AuthService _authService = AuthService();
  
  String _selectedStatus = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  
  final List<String> _statusOptions = ['All', 'initiated', 'viewed_by_supplier', 'quoted', 'accepted', 'rejected'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = Provider.of<UserModel?>(context);
    
    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to view RFQ dashboard')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('RFQ Dashboard'),
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
      body: Column(
        children: [
          _buildFilterSection(),
          Expanded(
            child: StreamBuilder<List<RFQTrackingModel>>(
              stream: _interactionService.getSupplierRFQs(currentUser.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text('Error: ${snapshot.error}'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => setState(() {}),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                final allRFQs = snapshot.data ?? [];
                final filteredRFQs = _filterRFQs(allRFQs);

                if (filteredRFQs.isEmpty) {
                  return _buildEmptyState();
                }

                return _buildRFQList(filteredRFQs);
              },
            ),
          ),
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
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                    decoration: const InputDecoration(
                      hintText: 'Search RFQs by product name or engineer...',
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
                    value: _selectedStatus,
                    hint: const Text('Status'),
                    items: _statusOptions.map((status) => DropdownMenuItem(
                      value: status,
                      child: Text(_formatStatus(status)),
                    )).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedStatus = value!;
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.request_quote, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No RFQs Found',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'RFQs for your products will appear here',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildRFQList(List<RFQTrackingModel> rfqs) {
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
                const Expanded(flex: 2, child: Text('Product', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87))),
                const Expanded(flex: 2, child: Text('Engineer', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87))),
                const Expanded(flex: 1, child: Text('Quantity', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87))),
                const Expanded(flex: 2, child: Text('Created', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87))),
                const Expanded(flex: 2, child: Text('Status', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87))),
                const Expanded(flex: 1, child: Text('Action', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87))),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: rfqs.length,
              itemBuilder: (context, index) {
                final rfq = rfqs[index];
                return _buildRFQRow(rfq, index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRFQRow(RFQTrackingModel rfq, int index) {
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rfq.productName,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
                if (rfq.budgetRange != null)
                  Text(
                    'Budget: ${rfq.budgetRange}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rfq.engineerName,
                  style: TextStyle(color: Colors.grey[600]),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  rfq.engineerEmail,
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              rfq.quantity.toString(),
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('dd MMM yy').format(rfq.createdAt),
                  style: TextStyle(color: Colors.grey[600]),
                ),
                if (rfq.preferredDeliveryDate != null)
                  Text(
                    'Delivery: ${rfq.preferredDeliveryDate}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getStatusColor(rfq.status).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _formatStatus(rfq.status),
                style: TextStyle(
                  color: _getStatusColor(rfq.status),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: PopupMenuButton<String>(
              icon: const Icon(Icons.more_horiz),
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'view', child: Text('View Details')),
                const PopupMenuItem(value: 'quote', child: Text('Send Quote')),
                if (rfq.status == 'initiated')
                  const PopupMenuItem(value: 'mark_viewed', child: Text('Mark as Viewed')),
              ],
              onSelected: (value) => _handleRFQAction(rfq, value),
            ),
          ),
        ],
      ),
    );
  }

  List<RFQTrackingModel> _filterRFQs(List<RFQTrackingModel> rfqs) {
    return rfqs.where((rfq) {
      final matchesSearch = _searchQuery.isEmpty ||
          rfq.productName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          rfq.engineerName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          rfq.engineerEmail.toLowerCase().contains(_searchQuery.toLowerCase());
      
      final matchesStatus = _selectedStatus == 'All' || rfq.status == _selectedStatus;
      
      return matchesSearch && matchesStatus;
    }).toList();
  }

  String _formatStatus(String status) {
    switch (status) {
      case 'initiated':
        return 'New';
      case 'viewed_by_supplier':
        return 'Viewed';
      case 'quoted':
        return 'Quoted';
      case 'accepted':
        return 'Accepted';
      case 'rejected':
        return 'Rejected';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'initiated':
        return Colors.blue;
      case 'viewed_by_supplier':
        return Colors.orange;
      case 'quoted':
        return Colors.purple;
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _handleRFQAction(RFQTrackingModel rfq, String action) {
    final currentUser = Provider.of<UserModel?>(context, listen: false);
    if (currentUser == null) return;

    switch (action) {
      case 'view':
        _showRFQDetails(rfq);
        break;
      case 'quote':
        _showQuoteDialog(rfq);
        break;
      case 'mark_viewed':
        _markAsViewed(rfq, currentUser);
        break;
    }
  }

  void _showRFQDetails(RFQTrackingModel rfq) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('RFQ Details - ${rfq.productName}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Engineer', rfq.engineerName),
              _buildDetailRow('Email', rfq.engineerEmail),
              _buildDetailRow('Product', rfq.productName),
              _buildDetailRow('Quantity', rfq.quantity.toString()),
              _buildDetailRow('Status', _formatStatus(rfq.status)),
              _buildDetailRow('Created', DateFormat('dd MMM yyyy, HH:mm').format(rfq.createdAt)),
              if (rfq.preferredDeliveryDate != null)
                _buildDetailRow('Preferred Delivery', rfq.preferredDeliveryDate!),
              if (rfq.budgetRange != null)
                _buildDetailRow('Budget Range', rfq.budgetRange!),
              if (rfq.rfqDetails.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text('Additional Details:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...rfq.rfqDetails.entries.map((entry) => 
                  _buildDetailRow(entry.key, entry.value.toString())),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showQuoteDialog(rfq);
            },
            child: const Text('Send Quote'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
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

  void _showQuoteDialog(RFQTrackingModel rfq) {
    // TODO: Implement quote dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Quote functionality will be implemented'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _markAsViewed(RFQTrackingModel rfq, UserModel currentUser) async {
    try {
      await _interactionService.trackSupplierRFQView(
        rfqId: rfq.rfqId,
        supplierId: currentUser.uid,
        supplierName: currentUser.name,
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('RFQ marked as viewed'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error marking RFQ as viewed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

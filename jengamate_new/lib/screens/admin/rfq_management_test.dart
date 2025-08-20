import 'package:flutter/material.dart';
import 'package:jengamate/models/rfq_model.dart';
import 'package:jengamate/services/database_service.dart';
import 'package:intl/intl.dart';

class RfqManagementTest extends StatefulWidget {
  const RfqManagementTest({super.key});

  @override
  State<RfqManagementTest> createState() => _RfqManagementTestState();
}

class _RfqManagementTestState extends State<RfqManagementTest> {
  final _dbService = DatabaseService();
  final _searchController = TextEditingController();
  String _selectedStatus = 'All';
  String _selectedType = 'All';
  List<RFQModel> _filteredRfqs = [];
  List<RFQModel> _allRfqs = [];

  final List<String> _statusOptions = ['All', 'Pending', 'Approved', 'Rejected', 'Processing', 'Completed'];
  final List<String> _typeOptions = ['All', 'Standard', 'Bid', 'Catalog', 'Marketplace'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
        title: const Text('RFQ Management Dashboard'),
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
      body: StreamBuilder<List<RFQModel>>(
        stream: _dbService.streamAllRFQs(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          _allRfqs = snapshot.data ?? [];
          if (_allRfqs.isEmpty) {
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

          // Initialize filtered list if empty
          if (_filteredRfqs.isEmpty && _allRfqs.isNotEmpty) {
            _filteredRfqs = _allRfqs;
          }

          return Column(
            children: [
              _buildFilterSection(),
              Expanded(child: _buildRfqTable()),
            ],
          );
        },
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
                const Expanded(flex: 2, child: Text('Knowledge', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87))),
                const Expanded(flex: 2, child: Text('Type', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87))),
                const Expanded(flex: 2, child: Text('Customer', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87))),
                const Expanded(flex: 2, child: Text('Quantity', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87))),
                const Expanded(flex: 2, child: Text('Created', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87))),
                const Expanded(flex: 2, child: Text('Status', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87))),
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
              rfq.customerName,
              style: TextStyle(color: Colors.grey[600]),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              rfq.quantity.toString(),
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
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getStatusColor(rfq.status).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                rfq.status,
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('RFQ Details - ${rfq.productName}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Customer', rfq.customerName),
              _buildDetailRow('Email', rfq.customerEmail),
              _buildDetailRow('Phone', rfq.customerPhone),
              _buildDetailRow('Delivery Address', rfq.deliveryAddress),
              _buildDetailRow('Quantity', rfq.quantity.toString()),
              _buildDetailRow('Status', rfq.status),
              _buildDetailRow('Created', DateFormat('dd MMM yyyy, HH:mm').format(rfq.createdAt)),
              if (rfq.additionalNotes.isNotEmpty)
                _buildDetailRow('Notes', rfq.additionalNotes),
            ],
          ),
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
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

  void _editRfqStatus(RFQModel rfq) {
    final statuses = ['Pending', 'Approved', 'Rejected', 'Processing', 'Completed'];
    String selected = rfq.status;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
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
                  if (val != null) {
                    setState(() {
                      selected = val;
                    });
                  }
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
      },
    );
  }

  void _deleteRfq(RFQModel rfq) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete RFQ'),
        content: Text('Are you sure you want to delete RFQ "${rfq.productName}"?\n\nThis action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                // Note: You'll need to add a deleteRFQ method to DatabaseService
                // await _dbService.deleteRFQ(rfq.id);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('RFQ deletion feature will be implemented'),
                    backgroundColor: Colors.orange,
                  ),
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
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/invoice_model.dart';
import '../../services/invoice_service.dart';
import '../../services/bulk_operations_service.dart';
import '../../widgets/bulk_operations_dialog.dart';
import '../../services/status_automation_service.dart';
import '../../ui/design_system/components/jm_card.dart';
import '../../ui/design_system/tokens/spacing.dart';
import '../order/invoice_details_screen.dart';
import '../invoices/edit_invoice_screen.dart';

class InvoiceManagementDashboard extends StatefulWidget {
  const InvoiceManagementDashboard({super.key});

  @override
  State<InvoiceManagementDashboard> createState() =>
      _InvoiceManagementDashboardState();
}

class _InvoiceManagementDashboardState extends State<InvoiceManagementDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<InvoiceModel> _allInvoices = [];
  List<InvoiceModel> _filteredInvoices = [];
  bool _isLoading = true;

  // Selection state
  bool _isSelectionMode = false;
  Set<String> _selectedInvoiceIds = {};

  // Filter states
  String _statusFilter = 'All';
  String _searchQuery = '';
  DateTimeRange? _dateRange;

  // Summary metrics
  double _totalOutstanding = 0.0;
  double _thisWeekRevenue = 0.0;
  double _thisMonthRevenue = 0.0;
  int _activeInvoices = 0;

  // Automation service
  late StatusAutomationService _automationService;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    // Initialize services
    // final invoiceService = Provider.of<InvoiceService>(context, listen: false);
    _automationService = StatusAutomationService();
    _loadInvoices();
    _startAutomationProcessing();
  }

  void _startAutomationProcessing() async {
    try {
      // Process automated rules on dashboard load
      await _automationService.processAutomatedRules();
    } catch (e) {
      // Silent failure for automation - don't block UI
      print('Automation processing failed: $e');
    }
  }

  Future<void> _loadInvoices() async {
    setState(() => _isLoading = true);

    try {
      final invoiceService =
          Provider.of<InvoiceService>(context, listen: false);
      final invoicesStream = invoiceService.getAllInvoices();

      invoicesStream.listen((invoices) {
        if (mounted) {
          setState(() {
            _allInvoices = invoices;
            _filteredInvoices = invoices;
            _calculateMetrics();
            _applyFilters();
            _isLoading = false;
          });
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load invoices: $e')),
        );
      }
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredInvoices = _allInvoices.where((invoice) {
        // Status filter
        if (_statusFilter != 'All' &&
            invoice.status.toLowerCase() != _statusFilter.toLowerCase()) {
          return false;
        }

        // Date range filter
        if (_dateRange != null) {
          final invoiceDate = invoice.createdAt;
          if (invoiceDate.isBefore(_dateRange!.start) ||
              invoiceDate.isAfter(_dateRange!.end)) {
            return false;
          }
        }

        // Search query filter
        if (_searchQuery.isNotEmpty) {
          final query = _searchQuery.toLowerCase();
          return invoice.invoiceNumber.toLowerCase().contains(query) ||
              invoice.customerName.toLowerCase().contains(query) ||
              invoice.customerEmail.toLowerCase().contains(query);
        }

        return true;
      }).toList();
    });
  }

  void _calculateMetrics() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final startOfMonth = DateTime(now.year, now.month, 1);

    double totalOutstanding = 0.0;
    double weekRevenue = 0.0;
    double monthRevenue = 0.0;
    int activeInvoices = 0;

    for (final invoice in _allInvoices) {
      // Outstanding calculation
      if (invoice.status.toLowerCase() != 'paid') {
        totalOutstanding += invoice.totalAmount;
        activeInvoices++;
      }

      // Weekly revenue (from this week)
      if (invoice.createdAt.isAfter(startOfWeek) &&
          invoice.status.toLowerCase() == 'paid') {
        weekRevenue += invoice.totalAmount;
      }

      // Monthly revenue (from this month)
      if (invoice.createdAt.isAfter(startOfMonth) &&
          invoice.status.toLowerCase() == 'paid') {
        monthRevenue += invoice.totalAmount;
      }
    }

    _totalOutstanding = totalOutstanding;
    _thisWeekRevenue = weekRevenue;
    _thisMonthRevenue = monthRevenue;
    _activeInvoices = activeInvoices;
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: 'TSH ');

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Invoice Dashboard'),
          backgroundColor: Theme.of(context).primaryColor,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoice Dashboard'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Pending'),
            Tab(text: 'Paid'),
            Tab(text: 'Overdue'),
          ],
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showSearchDialog,
            tooltip: 'Search Invoices',
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
            tooltip: 'Filter Invoices',
          ),
        ],
      ),
      body: Column(
        children: [
          // Summary Cards
          _buildSummaryCards(currencyFormat),

          const SizedBox(height: JMSpacing.md),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildInvoiceList(_filteredInvoices),
                _buildInvoiceList(_filteredInvoices
                    .where(
                        (invoice) => invoice.status.toLowerCase() == 'pending')
                    .toList()),
                _buildInvoiceList(_filteredInvoices
                    .where((invoice) => invoice.status.toLowerCase() == 'paid')
                    .toList()),
                _buildInvoiceList(_filteredInvoices
                    .where(
                        (invoice) => invoice.status.toLowerCase() == 'overdue')
                    .toList()),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: "invoiceBulkActions",
        onPressed: _showBulkActions,
        tooltip: 'Bulk Actions',
        child: const Icon(Icons.more_vert),
      ),
    );
  }

  Widget _buildSummaryCards(NumberFormat currencyFormat) {
    return Container(
      padding: const EdgeInsets.all(JMSpacing.md),
      color: Colors.grey.shade100,
      child: Row(
        children: [
          _buildMetricCard(
            'Outstanding',
            currencyFormat.format(_totalOutstanding),
            Icons.pending,
            Colors.orange,
          ),
          _buildMetricCard(
            'This Week',
            currencyFormat.format(_thisWeekRevenue),
            Icons.trending_up,
            Colors.blue,
          ),
          _buildMetricCard(
            'This Month',
            currencyFormat.format(_thisMonthRevenue),
            Icons.calendar_today,
            Colors.green,
          ),
          _buildMetricCard(
            'Active',
            _activeInvoices.toString(),
            Icons.receipt,
            Colors.purple,
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
      String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        height: 70,
        child: JMCard(
          child: Padding(
            padding: const EdgeInsets.all(JMSpacing.sm),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInvoiceList(List<InvoiceModel> invoices) {
    if (invoices.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: JMSpacing.lg),
            Text(
              'No invoices found',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadInvoices,
      child: ListView.builder(
        padding: const EdgeInsets.all(JMSpacing.md),
        itemCount: invoices.length,
        itemBuilder: (context, index) {
          final invoice = invoices[index];
          return _buildInvoiceCard(invoice);
        },
      ),
    );
  }

  Widget _buildInvoiceCard(InvoiceModel invoice) {
    final currencyFormat = NumberFormat.currency(symbol: 'TSH ');
    final dateFormat = DateFormat('MMM dd, yyyy');

    return JMCard(
      margin: const EdgeInsets.only(bottom: JMSpacing.sm),
      child: InkWell(
        onTap: () => _navigateToInvoiceDetail(invoice),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(JMSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Invoice number and customer
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          invoice.invoiceNumber,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          invoice.customerName,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Status chip and amount
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildStatusChip(invoice.status),
                      const SizedBox(height: 4),
                      Text(
                        currencyFormat.format(invoice.totalAmount),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: JMSpacing.sm),

              // Due date and items count
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Due: ${dateFormat.format(invoice.dueDate)}',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.shopping_cart,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${invoice.items.length} items',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),

              // Quick action buttons
              const SizedBox(height: JMSpacing.sm),
              Row(
                children: [
                  _buildQuickActionButton(
                    'Send',
                    Icons.send,
                    () => _sendInvoice(invoice),
                  ),
                  _buildQuickActionButton(
                    'PDF',
                    Icons.download,
                    () => _downloadPdf(invoice),
                  ),
                  _buildQuickActionButton(
                    'Edit',
                    Icons.edit,
                    () => _editInvoice(invoice),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'paid':
        color = Colors.green;
        break;
      case 'pending':
        color = Colors.orange;
        break;
      case 'overdue':
        color = Colors.red;
        break;
      case 'sent':
        color = Colors.blue;
        break;
      case 'draft':
        color = Colors.grey;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildQuickActionButton(
      String label, IconData icon, VoidCallback onPressed) {
    return Expanded(
      child: TextButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 16),
        label: Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        ),
      ),
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Invoices'),
        content: TextField(
          onChanged: (value) => _searchQuery = value,
          onSubmitted: (value) {
            _applyFilters();
            Navigator.pop(context);
          },
          decoration: const InputDecoration(
            hintText: 'Invoice #, customer name, or email',
            prefixIcon: Icon(Icons.search),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() => _searchQuery = '');
              _applyFilters();
              Navigator.pop(context);
            },
            child: const Text('Clear'),
          ),
          TextButton(
            onPressed: () {
              _applyFilters();
              Navigator.pop(context);
            },
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Invoices'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: _statusFilter,
              items: ['All', 'Pending', 'Paid', 'Sent', 'Overdue', 'Draft']
                  .map((status) => DropdownMenuItem(
                        value: status,
                        child: Text(status),
                      ))
                  .toList(),
              onChanged: (value) => _statusFilter = value ?? 'All',
              decoration: const InputDecoration(labelText: 'Status'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _statusFilter = 'All';
                _dateRange = null;
              });
              _applyFilters();
              Navigator.pop(context);
            },
            child: const Text('Reset'),
          ),
          TextButton(
            onPressed: () {
              _applyFilters();
              Navigator.pop(context);
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  void _showBulkActions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(JMSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Bulk Actions',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: Icon(_isSelectionMode ? Icons.close : Icons.checklist),
                  onPressed: () {
                    Navigator.pop(context);
                    _toggleSelectionMode();
                  },
                  tooltip: _isSelectionMode
                      ? 'Exit Selection Mode'
                      : 'Enter Selection Mode',
                ),
              ],
            ),
            const SizedBox(height: JMSpacing.lg),
            ListTile(
              leading: const Icon(Icons.send),
              title: const Text('Bulk Send Invoices'),
              subtitle: Text(_isSelectionMode
                  ? '${_selectedInvoiceIds.length} selected'
                  : 'Select invoices to send via email'),
              onTap: _isSelectionMode && _selectedInvoiceIds.isNotEmpty
                  ? () {
                      Navigator.pop(context);
                      _executeBulkSend();
                    }
                  : null,
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Update Status'),
              subtitle: Text(_isSelectionMode
                  ? '${_selectedInvoiceIds.length} selected'
                  : 'Select invoices to update status'),
              onTap: _isSelectionMode && _selectedInvoiceIds.isNotEmpty
                  ? () {
                      Navigator.pop(context);
                      _showBulkStatusUpdateDialog();
                    }
                  : null,
            ),
            ListTile(
              leading: const Icon(Icons.download),
              title: const Text('Export as PDFs'),
              subtitle: Text(_isSelectionMode
                  ? '${_selectedInvoiceIds.length} selected'
                  : 'Select invoices to export as PDFs'),
              onTap: _isSelectionMode && _selectedInvoiceIds.isNotEmpty
                  ? () {
                      Navigator.pop(context);
                      _exportSelectedInvoices();
                    }
                  : null,
            ),
            ListTile(
              leading: const Icon(Icons.delete_sweep),
              title: const Text('Bulk Delete'),
              subtitle: Text(_isSelectionMode
                  ? '${_selectedInvoiceIds.length} selected'
                  : 'Select invoices to delete'),
              onTap: _isSelectionMode && _selectedInvoiceIds.isNotEmpty
                  ? () {
                      Navigator.pop(context);
                      _executeBulkDelete();
                    }
                  : null,
            ),
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Duplicate Invoices'),
              subtitle: Text(_isSelectionMode
                  ? '${_selectedInvoiceIds.length} selected'
                  : 'Select invoices to duplicate'),
              onTap: _isSelectionMode && _selectedInvoiceIds.isNotEmpty
                  ? () {
                      Navigator.pop(context);
                      _executeBulkDuplicate();
                    }
                  : null,
            ),
            if (_isSelectionMode) ...[
              const Divider(),
              ListTile(
                leading: const Icon(Icons.select_all),
                title: const Text('Select All'),
                onTap: () {
                  Navigator.pop(context);
                  _selectAllInvoices();
                },
              ),
              ListTile(
                leading: const Icon(Icons.clear),
                title: const Text('Clear Selection'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _selectedInvoiceIds.clear();
                  });
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedInvoiceIds.clear();
      }
    });
  }

  void _selectAllInvoices() {
    setState(() {
      _selectedInvoiceIds = _filteredInvoices.map((inv) => inv.id).toSet();
    });
  }

  List<InvoiceModel> _getSelectedInvoices() {
    return _filteredInvoices
        .where((inv) => _selectedInvoiceIds.contains(inv.id))
        .toList();
  }

  // Placeholder methods for quick actions
  void _navigateToInvoiceDetail(InvoiceModel invoice) {
    // TODO: Navigate to invoice detail screen
    // ScaffoldMessenger.of(context).showSnackBar(
    //   SnackBar(content: Text('Navigate to ${invoice.invoiceNumber}')),
    // );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InvoiceDetailsScreen(orderId: invoice.orderId!),
      ),
    );
  }

  void _sendInvoice(InvoiceModel invoice) async {
    try {
      final invoiceService =
          Provider.of<InvoiceService>(context, listen: false);
      await invoiceService.sendInvoiceByEmail(invoice);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invoice sent successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send invoice: $e')),
        );
      }
    }
  }

  void _downloadPdf(InvoiceModel invoice) async {
    try {
      final invoiceService =
          Provider.of<InvoiceService>(context, listen: false);
      await invoiceService.generatePdf(invoice);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF downloaded successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to download PDF: $e')),
        );
      }
    }
  }

  void _editInvoice(InvoiceModel invoice) {
    // TODO: Navigate to edit invoice screen
    // ScaffoldMessenger.of(context).showSnackBar(
    //   SnackBar(content: Text('Edit ${invoice.invoiceNumber}')),
    // );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditInvoiceScreen(invoice: invoice),
      ),
    );
  }

  void _executeBulkSend() async {
    final selectedInvoices = _getSelectedInvoices();
    if (selectedInvoices.isEmpty) return;

    final result = await showDialog<BulkOperationResult?>(
      context: context,
      builder: (context) => BulkOperationsDialog(
        selectedInvoices: selectedInvoices,
        operationType: 'send',
      ),
    );

    if (result != null) {
      _handleBulkOperationResult(result, 'send');
    }
  }

  void _showBulkStatusUpdateDialog() async {
    final selectedInvoices = _getSelectedInvoices();
    if (selectedInvoices.isEmpty) return;

    // Show status selection dialog
    final newStatus = await showDialog<String?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select New Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['paid', 'pending', 'sent', 'draft', 'overdue']
              .map((status) => ListTile(
                    title: Text(status.toUpperCase()),
                    leading: Icon(
                      status == 'paid'
                          ? Icons.check_circle
                          : status == 'pending'
                              ? Icons.schedule
                              : status == 'sent'
                                  ? Icons.send
                                  : status == 'overdue'
                                      ? Icons.warning
                                      : Icons.description,
                      color: status == 'paid'
                          ? Colors.green
                          : status == 'pending'
                              ? Colors.orange
                              : status == 'overdue'
                                  ? Colors.red
                                  : Colors.blue,
                    ),
                    onTap: () => Navigator.pop(context, status),
                  ))
              .toList(),
        ),
      ),
    );

    if (newStatus != null) {
      final result = await showDialog<BulkOperationResult?>(
        context: context,
        builder: (context) => BulkOperationsDialog(
          selectedInvoices: selectedInvoices,
          operationType: 'status_update',
          newStatus: newStatus,
        ),
      );

      if (result != null) {
        _handleBulkOperationResult(result, 'status_update');
      }
    }
  }

  void _exportSelectedInvoices() async {
    final selectedInvoices = _getSelectedInvoices();
    if (selectedInvoices.isEmpty) return;

    final result = await showDialog<BulkOperationResult?>(
      context: context,
      builder: (context) => BulkOperationsDialog(
        selectedInvoices: selectedInvoices,
        operationType: 'export',
      ),
    );

    if (result != null) {
      _handleBulkOperationResult(result, 'export');
    }
  }

  void _executeBulkDelete() async {
    final selectedInvoices = _getSelectedInvoices();
    if (selectedInvoices.isEmpty) return;

    final result = await showDialog<BulkOperationResult?>(
      context: context,
      builder: (context) => BulkOperationsDialog(
        selectedInvoices: selectedInvoices,
        operationType: 'delete',
      ),
    );

    if (result != null) {
      _handleBulkOperationResult(result, 'delete');
    }
  }

  void _executeBulkDuplicate() async {
    final selectedInvoices = _getSelectedInvoices();
    if (selectedInvoices.isEmpty) return;

    final result = await showDialog<BulkOperationResult?>(
      context: context,
      builder: (context) => BulkOperationsDialog(
        selectedInvoices: selectedInvoices,
        operationType: 'duplicate',
      ),
    );

    if (result != null) {
      _handleBulkOperationResult(result, 'duplicate');
    }
  }

  void _handleBulkOperationResult(
      BulkOperationResult result, String operationType) {
    if (result.isCompleteSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${result.successful} invoices processed successfully'),
          backgroundColor: Colors.green,
        ),
      );
      // Reload invoices to reflect changes
      _loadInvoices();
    } else if (result.isCompleteFailure) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Operation failed: ${result.errors.join(', ')}'),
          backgroundColor: Colors.red,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Partial success: ${result.successful} successful, ${result.failed} failed'),
          backgroundColor: Colors.orange,
        ),
      );
      // Reload invoices to reflect partial changes
      _loadInvoices();
    }

    // Reset selection mode after bulk operation
    setState(() {
      _isSelectionMode = false;
      _selectedInvoiceIds.clear();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

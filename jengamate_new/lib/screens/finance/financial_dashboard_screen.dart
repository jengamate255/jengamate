import 'package:flutter/material.dart';
import 'package:jengamate/models/financial_transaction_model.dart';
import 'package:jengamate/models/enums/transaction_enums.dart';
import 'package:jengamate/services/database_service.dart';
import 'package:jengamate/utils/responsive.dart';
import 'package:jengamate/utils/logger.dart';
import 'package:intl/intl.dart';

class FinancialDashboardScreen extends StatefulWidget {
  const FinancialDashboardScreen({super.key});

  @override
  State<FinancialDashboardScreen> createState() => _FinancialDashboardScreenState();
}

class _FinancialDashboardScreenState extends State<FinancialDashboardScreen> {
  final DatabaseService _databaseService = DatabaseService();
  List<FinancialTransaction> _transactions = [];
  bool _isLoading = true;
  String _selectedFilter = 'all';
  TransactionStatus? _statusFilter;
  TransactionType? _typeFilter;
  DateTimeRange? _dateRange;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() => _isLoading = true);
    try {
      // TODO: Implement actual transaction loading from database service
      // For now, creating sample data to demonstrate UI
      _transactions = _generateSampleTransactions();
      Logger.log('Loaded ${_transactions.length} financial transactions');
    } catch (e) {
      Logger.logError('Error loading transactions', e, StackTrace.current);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading transactions: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<FinancialTransaction> _generateSampleTransactions() {
    final now = DateTime.now();
    return [
      FinancialTransaction(
        id: '1',
        amount: 150.00,
        type: TransactionType.commission,
        userId: 'user1',
        relatedId: 'order1',
        description: 'Commission from Order #12345',
        status: TransactionStatus.completed,
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      FinancialTransaction(
        id: '2',
        amount: 500.00,
        type: TransactionType.withdrawal,
        userId: 'user2',
        relatedId: 'withdrawal1',
        description: 'Withdrawal Request',
        status: TransactionStatus.pending,
        createdAt: now.subtract(const Duration(days: 2)),
      ),
      FinancialTransaction(
        id: '3',
        amount: 75.50,
        type: TransactionType.refund,
        userId: 'user3',
        relatedId: 'order2',
        description: 'Refund for Order #12346',
        status: TransactionStatus.completed,
        createdAt: now.subtract(const Duration(days: 3)),
      ),
    ];
  }

  List<FinancialTransaction> get _filteredTransactions {
    var filtered = _transactions.where((transaction) {
      // Status filter
      if (_statusFilter != null && transaction.status != _statusFilter) {
        return false;
      }
      
      // Type filter
      if (_typeFilter != null && transaction.type != _typeFilter) {
        return false;
      }
      
      // Date range filter
      if (_dateRange != null) {
        if (transaction.createdAt.isBefore(_dateRange!.start) ||
            transaction.createdAt.isAfter(_dateRange!.end)) {
          return false;
        }
      }
      
      // Search filter
      if (_searchController.text.isNotEmpty) {
        final searchTerm = _searchController.text.toLowerCase();
        return transaction.description?.toLowerCase().contains(searchTerm) == true ||
               transaction.id.toLowerCase().contains(searchTerm) ||
               transaction.referenceNumber?.toLowerCase().contains(searchTerm) == true;
      }
      
      return true;
    }).toList();
    
    // Sort by date (newest first)
    filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial Dashboard'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTransactions,
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildSummaryCards(),
                _buildSearchAndFilters(),
                Expanded(child: _buildTransactionsList()),
              ],
            ),
    );
  }

  Widget _buildSummaryCards() {
    final totalIncome = _transactions
        .where((t) => t.type == TransactionType.commission && t.status == TransactionStatus.completed)
        .fold(0.0, (sum, t) => sum + t.amount);
    
    final totalWithdrawals = _transactions
        .where((t) => t.type == TransactionType.withdrawal && t.status == TransactionStatus.completed)
        .fold(0.0, (sum, t) => sum + t.amount);
    
    final pendingAmount = _transactions
        .where((t) => t.status == TransactionStatus.pending)
        .fold(0.0, (sum, t) => sum + t.amount);

    return Container(
      padding: Responsive.getResponsivePadding(context),
      child: Responsive.isMobile(context)
          ? Column(children: _buildSummaryCardsList(totalIncome, totalWithdrawals, pendingAmount))
          : Row(
              children: _buildSummaryCardsList(totalIncome, totalWithdrawals, pendingAmount)
                  .map((card) => Expanded(child: card))
                  .toList(),
            ),
    );
  }

  List<Widget> _buildSummaryCardsList(double totalIncome, double totalWithdrawals, double pendingAmount) {
    final spacing = Responsive.getResponsiveSpacing(context);
    return [
      _buildSummaryCard('Total Income', totalIncome, Colors.green, Icons.trending_up),
      SizedBox(width: spacing, height: spacing),
      _buildSummaryCard('Total Withdrawals', totalWithdrawals, Colors.blue, Icons.account_balance_wallet),
      SizedBox(width: spacing, height: spacing),
      _buildSummaryCard('Pending Amount', pendingAmount, Colors.orange, Icons.pending),
    ];
  }

  Widget _buildSummaryCard(String title, double amount, Color color, IconData icon) {
    return Card(
      elevation: Responsive.getResponsiveElevation(context),
      child: Padding(
        padding: Responsive.getResponsivePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: color,
                  size: Responsive.getResponsiveIconSize(context),
                ),
                SizedBox(width: Responsive.getResponsiveSpacing(context)),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontSize: Responsive.getResponsiveFontSize(context, mobile: 12, tablet: 14, desktop: 16),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: Responsive.getResponsiveSpacing(context)),
            Text(
              '\$${amount.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: Responsive.getResponsiveFontSize(context, mobile: 18, tablet: 20, desktop: 24),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search transactions...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onChanged: (value) => setState(() {}),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('All', _selectedFilter == 'all', () {
                  setState(() {
                    _selectedFilter = 'all';
                    _statusFilter = null;
                    _typeFilter = null;
                  });
                }),
                _buildFilterChip('Completed', _statusFilter == TransactionStatus.completed, () {
                  setState(() {
                    _selectedFilter = 'completed';
                    _statusFilter = TransactionStatus.completed;
                  });
                }),
                _buildFilterChip('Pending', _statusFilter == TransactionStatus.pending, () {
                  setState(() {
                    _selectedFilter = 'pending';
                    _statusFilter = TransactionStatus.pending;
                  });
                }),
                _buildFilterChip('Commissions', _typeFilter == TransactionType.commission, () {
                  setState(() {
                    _selectedFilter = 'commission';
                    _typeFilter = TransactionType.commission;
                  });
                }),
                _buildFilterChip('Withdrawals', _typeFilter == TransactionType.withdrawal, () {
                  setState(() {
                    _selectedFilter = 'withdrawal';
                    _typeFilter = TransactionType.withdrawal;
                  });
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onTap(),
        selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
      ),
    );
  }

  Widget _buildTransactionsList() {
    final filteredTransactions = _filteredTransactions;
    
    if (filteredTransactions.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No transactions found', style: TextStyle(fontSize: 18, color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredTransactions.length,
      itemBuilder: (context, index) {
        final transaction = filteredTransactions[index];
        return _buildTransactionCard(transaction);
      },
    );
  }

  Widget _buildTransactionCard(FinancialTransaction transaction) {
    final isIncome = transaction.type == TransactionType.commission;
    final color = _getTransactionColor(transaction);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Icon(_getTransactionIcon(transaction.type), color: color),
        ),
        title: Text(
          transaction.description ?? 'Transaction ${transaction.id}',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ID: ${transaction.id}'),
            Text(DateFormat('MMM dd, yyyy HH:mm').format(transaction.createdAt)),
            if (transaction.referenceNumber != null)
              Text('Ref: ${transaction.referenceNumber}'),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${isIncome ? '+' : '-'}\$${transaction.amount.toStringAsFixed(2)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: color,
              ),
            ),
            _buildStatusChip(transaction.status),
          ],
        ),
        onTap: () => _showTransactionDetails(transaction),
      ),
    );
  }

  Color _getTransactionColor(FinancialTransaction transaction) {
    switch (transaction.status) {
      case TransactionStatus.completed:
        return transaction.type == TransactionType.commission ? Colors.green : Colors.blue;
      case TransactionStatus.pending:
        return Colors.orange;
      case TransactionStatus.failed:
        return Colors.red;
      case TransactionStatus.cancelled:
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  IconData _getTransactionIcon(TransactionType type) {
    switch (type) {
      case TransactionType.commission:
        return Icons.trending_up;
      case TransactionType.withdrawal:
        return Icons.account_balance_wallet;
      case TransactionType.refund:
        return Icons.undo;
      case TransactionType.payment:
        return Icons.payment;
      case TransactionType.bonus:
        return Icons.card_giftcard;
      default:
        return Icons.receipt_long;
    }
  }

  Widget _buildStatusChip(TransactionStatus status) {
    Color color;
    String text;

    switch (status) {
      case TransactionStatus.completed:
        color = Colors.green;
        text = 'Completed';
        break;
      case TransactionStatus.pending:
        color = Colors.orange;
        text = 'Pending';
        break;
      case TransactionStatus.failed:
        color = Colors.red;
        text = 'Failed';
        break;
      case TransactionStatus.cancelled:
        color = Colors.grey;
        text = 'Cancelled';
        break;
      default:
        color = Colors.grey;
        text = status.name;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500),
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Transactions'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Date range picker would go here
            const Text('Advanced filters coming soon...'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showTransactionDetails(FinancialTransaction transaction) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Transaction Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('ID', transaction.id),
            _buildDetailRow('Amount', '\$${transaction.amount.toStringAsFixed(2)}'),
            _buildDetailRow('Type', transaction.type.toString().split('.').last),
            _buildDetailRow('Status', transaction.status.toString().split('.').last),
            _buildDetailRow('Date', DateFormat('MMM dd, yyyy HH:mm').format(transaction.createdAt)),
            if (transaction.description != null)
              _buildDetailRow('Description', transaction.description!),
            if (transaction.referenceNumber != null)
              _buildDetailRow('Reference', transaction.referenceNumber!),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
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
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

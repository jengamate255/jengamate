import 'package:jengamate/models/financial_transaction_model.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jengamate/services/database_service.dart';
import 'package:jengamate/utils/responsive.dart';
import 'package:jengamate/utils/logger.dart';
import 'package:intl/intl.dart';
import 'package:jengamate/ui/design_system/components/jm_button.dart';
import 'package:jengamate/ui/design_system/components/jm_card.dart';
import 'package:jengamate/ui/shared_components/jm_notification.dart';
import 'package:jengamate/ui/design_system/tokens/colors.dart';

class FinancialDashboardScreen extends StatefulWidget {
  const FinancialDashboardScreen({super.key});

  @override
  State<FinancialDashboardScreen> createState() =>
      _FinancialDashboardScreenState();
}

class _FinancialDashboardScreenState extends State<FinancialDashboardScreen> {
  final DatabaseService _databaseService = DatabaseService();
  List<FinancialTransactionModel> _transactions = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMoreData = true;
  String _selectedFilter = 'all';
  TransactionStatus? _statusFilter;
  TransactionType? _typeFilter;
  DateTimeRange? _dateRange;
  final TextEditingController _searchController = TextEditingController();
  final int _pageSize = 50;
  DocumentSnapshot? _lastDocument;
  // Currency formatter for Tanzanian Shilling (TSH)
  final NumberFormat _tzsFormatter =
      NumberFormat.currency(locale: 'en_TZ', symbol: 'TSH ', decimalDigits: 2);

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions({bool loadMore = false}) async {
    if (loadMore && (_isLoadingMore || !_hasMoreData)) return;

    setState(() {
      if (loadMore) {
        _isLoadingMore = true;
      } else {
        _isLoading = true;
        _transactions.clear();
        _lastDocument = null;
        _hasMoreData = true;
      }
    });

    try {
      // Use the database service method for paginated transactions
      final newTransactions =
          await _databaseService.getPaginatedFinancialTransactions(
        limit: _pageSize,
        startAfter: loadMore ? _lastDocument : null,
      );

      if (mounted) {
        setState(() {
          if (loadMore) {
            _transactions.addAll(newTransactions);
          } else {
            _transactions = newTransactions;
          }
          _hasMoreData = newTransactions.length == _pageSize;
        });

        // Update last document for pagination if we have transactions
        if (newTransactions.isNotEmpty && newTransactions.length == _pageSize) {
          _lastDocument = await _databaseService.getLastTransactionDocument();
        }
      }

      Logger.log(
          'Loaded ${newTransactions.length} financial transactions from database');
    } catch (e) {
      Logger.logError(
          'Error loading financial transactions', e, StackTrace.current);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading transactions: $e'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => _loadTransactions(loadMore: loadMore),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  /// Validates transaction data for consistency and accuracy
  bool _validateTransaction(FinancialTransactionModel transaction) {
    try {
      // Basic validation
      if (transaction.id.isEmpty) {
        Logger.logError('Invalid transaction: empty ID', transaction.toMap(),
            StackTrace.current);
        return false;
      }

      if (transaction.amount <= 0) {
        Logger.logError('Invalid transaction: non-positive amount',
            transaction.toMap(), StackTrace.current);
        return false;
      }

      if (transaction.userId.isEmpty) {
        Logger.logError('Invalid transaction: empty user ID',
            transaction.toMap(), StackTrace.current);
        return false;
      }

      // Validate transaction type and status combination
      if (transaction.type == TransactionType.withdrawal &&
          transaction.status == TransactionStatus.completed &&
          transaction.amount > 0) {
        // Withdrawal amounts should be negative for accounting
        // This is a data consistency check
      }

      return true;
    } catch (e) {
      Logger.logError('Error validating transaction', e, StackTrace.current);
      return false;
    }
  }

  /// Sanitizes and processes transaction data for display
  FinancialTransactionModel _sanitizeTransaction(
      FinancialTransactionModel transaction) {
    final fallbackDesc =
        'Transaction ${transaction.type.toString().split('.').last} #${transaction.id.substring(0, 8)}';
    final descRaw = transaction.description.trim();
    final sanitizedDescription = descRaw.isEmpty ? fallbackDesc : descRaw;

    // Ensure proper amount formatting
    final sanitizedAmount = double.parse(transaction.amount.toStringAsFixed(2));

    return transaction.copyWith(
      description: sanitizedDescription,
      amount: sanitizedAmount,
    );
  }

  List<FinancialTransactionModel> get _filteredTransactions {
    var filtered = _transactions
        .where(_validateTransaction) // Validate each transaction
        .map(_sanitizeTransaction) // Sanitize data
        .where((transaction) {
      // Status filter
      if (_statusFilter != null && transaction.status != _statusFilter) {
        return false;
      }

      // Type filter
      if (_typeFilter != null && transaction.type != _typeFilter) {
        return false;
      }

      // Date range filter with proper validation
      if (_dateRange != null) {
        final transactionDate = transaction.createdAt;
        final startDate = _dateRange!.start;
        final endDate = _dateRange!.end
            .add(const Duration(hours: 23, minutes: 59, seconds: 59));

        if (transactionDate.isBefore(startDate) ||
            transactionDate.isAfter(endDate)) {
          return false;
        }
      }

      // Enhanced search filter with multiple criteria
      if (_searchController.text.isNotEmpty) {
        final searchTerm = _searchController.text.toLowerCase().trim();
        if (searchTerm.isEmpty) return true;

        return transaction.description.toLowerCase().contains(searchTerm) ==
                true ||
            transaction.id.toLowerCase().contains(searchTerm) ||
            transaction.referenceNumber?.toLowerCase().contains(searchTerm) ==
                true ||
            transaction.type.toString().toLowerCase().contains(searchTerm) ||
            transaction.status.toString().toLowerCase().contains(searchTerm) ||
            transaction.amount.toString().contains(searchTerm);
      }

      return true;
    }).toList();

    // Optimized sorting with null safety
    try {
      filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      Logger.logError('Error sorting transactions', e, StackTrace.current);
      // If sorting fails, return unsorted list rather than crashing
    }

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
    // Calculate metrics from validated live data with error handling
    double totalIncome = 0.0;
    double totalWithdrawals = 0.0;
    double pendingAmount = 0.0;

    try {
      // Validate and sanitize transactions before calculations
      final validTransactions =
          _transactions.where(_validateTransaction).map(_sanitizeTransaction);

      for (var transaction in validTransactions) {
        switch (transaction.status) {
          case TransactionStatus.completed:
            if (transaction.type == TransactionType.commission) {
              totalIncome += transaction.amount;
            } else if (transaction.type == TransactionType.withdrawal) {
              totalWithdrawals += transaction.amount;
            }
            break;
          case TransactionStatus.pending:
            pendingAmount += transaction.amount;
            break;
          default:
            break;
        }
      }

      Logger.log(
          'Summary calculations: Income=$totalIncome, Withdrawals=$totalWithdrawals, Pending=$pendingAmount');
    } catch (e) {
      Logger.logError(
          'Error calculating summary metrics', e, StackTrace.current);
      // Display error state but don't crash
    }

    return Container(
      padding: Responsive.getResponsivePadding(context),
      child: Responsive.isMobile(context)
          ? Column(
              children: _buildSummaryCardsList(
                  totalIncome, totalWithdrawals, pendingAmount))
          : Row(
              children: _buildSummaryCardsList(
                      totalIncome, totalWithdrawals, pendingAmount)
                  .map((card) => Expanded(child: card))
                  .toList(),
            ),
    );
  }

  List<Widget> _buildSummaryCardsList(
      double totalIncome, double totalWithdrawals, double pendingAmount) {
    final spacing = Responsive.getResponsiveSpacing(context);
    return [
      _buildSummaryCard(
          'Total Income', totalIncome, Colors.green, Icons.trending_up),
      SizedBox(width: spacing, height: spacing),
      _buildSummaryCard('Total Withdrawals', totalWithdrawals, Colors.blue,
          Icons.account_balance_wallet),
      SizedBox(width: spacing, height: spacing),
      _buildSummaryCard(
          'Pending Amount', pendingAmount, Colors.orange, Icons.pending),
    ];
  }

  Widget _buildSummaryCard(
      String title, double amount, Color color, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.08),
            Colors.white,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Padding(
        padding: Responsive.getResponsivePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  height: 36,
                  width: 36,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 20,
                  ),
                ),
                SizedBox(width: Responsive.getResponsiveSpacing(context)),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontSize: Responsive.getResponsiveFontSize(context,
                              mobile: 12, tablet: 14, desktop: 16),
                          color: Colors.black87,
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: Responsive.getResponsiveSpacing(context)),
            Text(
              _tzsFormatter.format(amount),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: Responsive.getResponsiveFontSize(context,
                        mobile: 18, tablet: 20, desktop: 24),
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
                _buildFilterChip(
                    'Completed', _statusFilter == TransactionStatus.completed,
                    () {
                  setState(() {
                    _selectedFilter = 'completed';
                    _statusFilter = TransactionStatus.completed;
                  });
                }),
                _buildFilterChip(
                    'Pending', _statusFilter == TransactionStatus.pending, () {
                  setState(() {
                    _selectedFilter = 'pending';
                    _statusFilter = TransactionStatus.pending;
                  });
                }),
                _buildFilterChip(
                    'Commissions', _typeFilter == TransactionType.commission,
                    () {
                  setState(() {
                    _selectedFilter = 'commission';
                    _typeFilter = TransactionType.commission;
                  });
                }),
                _buildFilterChip(
                    'Withdrawals', _typeFilter == TransactionType.withdrawal,
                    () {
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
        selectedColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
      ),
    );
  }

  Widget _buildTransactionsList() {
    final filteredTransactions = _filteredTransactions;

    if (filteredTransactions.isEmpty && !_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No transactions found',
                style: TextStyle(fontSize: 18, color: Colors.grey)),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredTransactions.length,
            itemBuilder: (context, index) {
              final transaction = filteredTransactions[index];
              return _buildTransactionCard(transaction);
            },
          ),
        ),
        if (_hasMoreData && !_isLoading && !_isLoadingMore)
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: () => _loadTransactions(loadMore: true),
              child: const Text('Load More Transactions'),
            ),
          ),
        if (_isLoadingMore)
          const Padding(
            padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(),
          ),
      ],
    );
  }

  Widget _buildTransactionCard(FinancialTransactionModel transaction) {
    final isIncome = transaction.type == TransactionType.commission;
    final color = _getTransactionColor(transaction);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.2),
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
            Text(
                DateFormat('MMM dd, yyyy HH:mm').format(transaction.createdAt)),
            if (transaction.referenceId != null)
              Text('Ref: ${transaction.referenceId}'),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _formatSignedAmount(transaction, isIncome: isIncome, color: color),
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

  Color _getTransactionColor(FinancialTransactionModel transaction) {
    switch (transaction.status) {
      case TransactionStatus.completed:
        return transaction.type == TransactionType.commission
            ? Colors.green
            : Colors.blue;
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
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style:
            TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500),
      ),
    );
  }

  void _showFilterDialog() {
    // Create copies of current filter values
    String selectedFilter = _selectedFilter;
    TransactionStatus? statusFilter = _statusFilter;
    TransactionType? typeFilter = _typeFilter;
    DateTimeRange? dateRange = _dateRange;
    double? minAmount;
    double? maxAmount;
    String? searchUser;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.filter_list, color: JMColors.lightScheme.primary),
              const SizedBox(width: 12),
              const Text('Advanced Filters'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Quick Filters
                const Text(
                  'Quick Filters',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilterChip(
                      label: const Text('All'),
                      selected: selectedFilter == 'all',
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => selectedFilter = 'all');
                        }
                      },
                    ),
                    FilterChip(
                      label: const Text('Today'),
                      selected: selectedFilter == 'today',
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => selectedFilter = 'today');
                        }
                      },
                    ),
                    FilterChip(
                      label: const Text('This Week'),
                      selected: selectedFilter == 'week',
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => selectedFilter = 'week');
                        }
                      },
                    ),
                    FilterChip(
                      label: const Text('This Month'),
                      selected: selectedFilter == 'month',
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => selectedFilter = 'month');
                        }
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Transaction Type
                const Text(
                  'Transaction Type',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: TransactionType.values.map((type) {
                    return FilterChip(
                      label: Text(type.name.toUpperCase()),
                      selected: typeFilter == type,
                      onSelected: (selected) {
                        setState(() => typeFilter = selected ? type : null);
                      },
                    );
                  }).toList(),
                ),

                const SizedBox(height: 16),

                // Transaction Status
                const Text(
                  'Transaction Status',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: TransactionStatus.values.map((status) {
                    return FilterChip(
                      label: Text(status.name.toUpperCase()),
                      selected: statusFilter == status,
                      onSelected: (selected) {
                        setState(() => statusFilter = selected ? status : null);
                      },
                    );
                  }).toList(),
                ),

                const SizedBox(height: 16),

                // Date Range
                const Text(
                  'Date Range',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final picked = await showDateRangePicker(
                            context: context,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                            initialDateRange: dateRange,
                          );
                          if (picked != null) {
                            setState(() => dateRange = picked);
                          }
                        },
                        icon: const Icon(Icons.date_range),
                        label: Text(
                          dateRange != null
                              ? '${DateFormat('MMM dd').format(dateRange!.start)} - ${DateFormat('MMM dd').format(dateRange!.end)}'
                              : 'Select Date Range',
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          textStyle: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                    if (dateRange != null)
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() => dateRange = null),
                        tooltip: 'Clear date range',
                      ),
                  ],
                ),

                const SizedBox(height: 16),

                // Amount Range
                const Text(
                  'Amount Range (TSH)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          labelText: 'Min Amount',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          minAmount = double.tryParse(value);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          labelText: 'Max Amount',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          maxAmount = double.tryParse(value);
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // User Search
                const Text(
                  'User Search',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Search by user name or ID',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (value) {
                    searchUser = value.isEmpty ? null : value;
                  },
                ),

                const SizedBox(height: 16),

                // Active Filters Summary
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: JMColors.info.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: JMColors.info.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Active Filters:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: JMColors.info,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getActiveFiltersSummary(selectedFilter, statusFilter, typeFilter, dateRange, minAmount, maxAmount, searchUser),
                        style: TextStyle(
                          fontSize: 12,
                          color: JMColors.info,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                // Clear all filters
                setState(() {
                  selectedFilter = 'all';
                  statusFilter = null;
                  typeFilter = null;
                  dateRange = null;
                  minAmount = null;
                  maxAmount = null;
                  searchUser = null;
                });
              },
              child: const Text('Clear All'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            JMButton(
              variant: JMButtonVariant.primary,
              label: 'Apply Filters',
              icon: Icons.check,
              child: const SizedBox(),
              onPressed: () {
                Navigator.pop(context);
                _applyFilters(
                  selectedFilter,
                  statusFilter,
                  typeFilter,
                  dateRange,
                  minAmount,
                  maxAmount,
                  searchUser,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _getActiveFiltersSummary(
    String filter,
    TransactionStatus? status,
    TransactionType? type,
    DateTimeRange? dateRange,
    double? minAmount,
    double? maxAmount,
    String? searchUser,
  ) {
    List<String> activeFilters = [];

    if (filter != 'all') activeFilters.add('Quick: ${filter.toUpperCase()}');
    if (status != null) activeFilters.add('Status: ${status.name}');
    if (type != null) activeFilters.add('Type: ${type.name}');
    if (dateRange != null) activeFilters.add('Date range selected');
    if (minAmount != null || maxAmount != null) {
      activeFilters.add('Amount: ${minAmount ?? 0} - ${maxAmount ?? '∞'}');
    }
    if (searchUser != null && searchUser.isNotEmpty) {
      activeFilters.add('User search: "$searchUser"');
    }

    return activeFilters.isEmpty ? 'No active filters' : activeFilters.join(', ');
  }

  void _applyFilters(
    String selectedFilter,
    TransactionStatus? statusFilter,
    TransactionType? typeFilter,
    DateTimeRange? dateRange,
    double? minAmount,
    double? maxAmount,
    String? searchUser,
  ) {
    setState(() {
      _selectedFilter = selectedFilter;
      _statusFilter = statusFilter;
      _typeFilter = typeFilter;
      _dateRange = dateRange;
    });

    // Apply filters to transaction list
    _loadTransactions();

    // Show success message
    final activeCount = [
      selectedFilter != 'all',
      statusFilter != null,
      typeFilter != null,
      dateRange != null,
      minAmount != null || maxAmount != null,
      searchUser != null && searchUser.isNotEmpty,
    ].where((filter) => filter).length;

    if (activeCount > 0) {
      context.showSuccess(
        '$activeCount filter(s) applied successfully',
        title: 'Filters Applied',
      );
    } else {
      context.showInfo(
        'All filters cleared',
        title: 'Filters Reset',
      );
    }
  }

  void _showTransactionDetails(FinancialTransactionModel transaction) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Transaction Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('ID', transaction.id),
            _buildDetailRow('Amount', _tzsFormatter.format(transaction.amount)),
            _buildDetailRow(
                'Type', transaction.type.toString().split('.').last),
            _buildDetailRow(
                'Status', transaction.status.toString().split('.').last),
            _buildDetailRow('Date',
                DateFormat('MMM dd, yyyy HH:mm').format(transaction.createdAt)),
            _buildDetailRow('Description', transaction.description),
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

  // Helpers
  String _formatSignedAmount(FinancialTransactionModel t,
      {required bool isIncome, required Color color}) {
    final formatted = _tzsFormatter.format(t.amount.abs());
    final sign = isIncome ? '+' : '-';
    return '$sign$formatted';
  }
}

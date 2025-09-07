import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/invoice_model.dart';
import '../services/bulk_operations_service.dart';
import '../services/invoice_service.dart';

/// Dialog for showing bulk operation progress and results
class BulkOperationsDialog extends StatefulWidget {
  final List<InvoiceModel> selectedInvoices;
  final String
      operationType; // 'send', 'status_update', 'export', 'delete', 'duplicate'
  final String? newStatus; // Only for status_update operation

  const BulkOperationsDialog({
    super.key,
    required this.selectedInvoices,
    required this.operationType,
    this.newStatus,
  });

  @override
  State<BulkOperationsDialog> createState() => _BulkOperationsDialogState();
}

class _BulkOperationsDialogState extends State<BulkOperationsDialog> {
  bool _isInProgress = false;
  double _progress = 0.0;
  String _currentAction = '';
  BulkOperationResult? _result;
  bool _isConfirmed = false;

  late BulkOperationsService _bulkOpsService;

  @override
  void initState() {
    super.initState();
    final invoiceService = Provider.of<InvoiceService>(context, listen: false);
    _bulkOpsService = BulkOperationsService(invoiceService);
  }

  String _getOperationTitle() {
    switch (widget.operationType) {
      case 'send':
        return 'Send Invoices';
      case 'status_update':
        return 'Update Status';
      case 'export':
        return 'Export PDFs';
      case 'delete':
        return 'Delete Invoices';
      case 'duplicate':
        return 'Duplicate Invoices';
      default:
        return 'Bulk Operation';
    }
  }

  String _getOperationDescription() {
    final count = widget.selectedInvoices.length;
    final itemText = count == 1 ? 'invoice' : 'invoices';

    switch (widget.operationType) {
      case 'send':
        return 'Send $count $itemText via email';
      case 'status_update':
        return 'Change status of $count $itemText to "${widget.newStatus}"';
      case 'export':
        return 'Export $count $itemText as PDFs';
      case 'delete':
        return 'Permanently delete $count $itemText';
      case 'duplicate':
        return 'Create copies of $count $itemText';
      default:
        return '$count $itemText';
    }
  }

  IconData _getOperationIcon() {
    switch (widget.operationType) {
      case 'send':
        return Icons.send;
      case 'status_update':
        return Icons.edit;
      case 'export':
        return Icons.download;
      case 'delete':
        return Icons.delete_forever;
      case 'duplicate':
        return Icons.copy;
      default:
        return Icons.build;
    }
  }

  Color _getOperationColor() {
    switch (widget.operationType) {
      case 'send':
        return Colors.blue;
      case 'status_update':
        return Colors.orange;
      case 'export':
        return Colors.green;
      case 'delete':
        return Colors.red;
      case 'duplicate':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Future<void> _executeOperation() async {
    if (!mounted) return;

    setState(() {
      _isInProgress = true;
      _progress = 0.0;
      _currentAction = 'Preparing operation...';
    });

    try {
      final validationError = _bulkOpsService.validateBulkOperation(
        widget.selectedInvoices,
        widget.operationType,
      );

      if (validationError != null) {
        if (mounted) {
          setState(() {
            _isInProgress = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(validationError)),
          );
        }
        return;
      }

      // Execute the appropriate bulk operation
      switch (widget.operationType) {
        case 'send':
          _result = await _bulkOpsService.sendInvoicesBulk(
            widget.selectedInvoices,
            context: context,
            onProgress: (completed) {
              if (mounted) {
                setState(() {
                  _progress = completed / widget.selectedInvoices.length;
                  _currentAction =
                      'Sending invoice ${completed}/${widget.selectedInvoices.length}...';
                });
              }
            },
          );
          break;

        case 'status_update':
          if (widget.newStatus != null) {
            _result = await _bulkOpsService.updateInvoicesStatusBulk(
              widget.selectedInvoices,
              widget.newStatus!,
              onProgress: (completed) {
                if (mounted) {
                  setState(() {
                    _progress = completed / widget.selectedInvoices.length;
                    _currentAction =
                        'Updating status ${completed}/${widget.selectedInvoices.length}...';
                  });
                }
              },
            );
          }
          break;

        case 'export':
          _result = await _bulkOpsService.exportInvoicesToZip(
            widget.selectedInvoices,
            zipFileName: 'invoices_export.zip',
            onProgress: (completed) {
              if (mounted) {
                setState(() {
                  _progress = completed / widget.selectedInvoices.length;
                  _currentAction =
                      'Generating PDFs ${completed}/${widget.selectedInvoices.length}...';
                });
              }
            },
          );
          break;

        case 'delete':
          _result = await _bulkOpsService.deleteInvoicesBulk(
            widget.selectedInvoices,
            onProgress: (completed) {
              if (mounted) {
                setState(() {
                  _progress = completed / widget.selectedInvoices.length;
                  _currentAction =
                      'Deleting invoice ${completed}/${widget.selectedInvoices.length}...';
                });
              }
            },
          );
          break;

        case 'duplicate':
          _result = await _bulkOpsService.duplicateInvoicesBulk(
            widget.selectedInvoices,
            onProgress: (completed) {
              if (mounted) {
                setState(() {
                  _progress = completed / widget.selectedInvoices.length;
                  _currentAction =
                      'Duplicating invoice ${completed}/${widget.selectedInvoices.length}...';
                });
              }
            },
          );
          break;
      }

      if (mounted) {
        setState(() {
          _isInProgress = false;
          _currentAction = 'Operation completed!';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isInProgress = false;
          _result = BulkOperationResult(
            successful: 0,
            failed: widget.selectedInvoices.length,
            total: widget.selectedInvoices.length,
            errors: ['Operation failed: ${e.toString()}'],
            successfulIds: [],
          );
        });
      }
    }
  }

  Widget _buildConfirmationView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header
        Row(
          children: [
            Icon(
              _getOperationIcon(),
              color: _getOperationColor(),
              size: 28,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getOperationTitle(),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${widget.selectedInvoices.length} invoice${widget.selectedInvoices.length == 1 ? '' : 's'} selected',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Description
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _getOperationColor().withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _getOperationColor().withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                color: _getOperationColor(),
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _getOperationDescription(),
                  style: TextStyle(
                    color: _getOperationColor().withOpacity(0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Confirmation checkbox
        Row(
          children: [
            Checkbox(
              value: _isConfirmed,
              onChanged: (value) {
                setState(() => _isConfirmed = value ?? false);
              },
            ),
            Expanded(
              child: Text(
                'I confirm that I want to proceed with this bulk operation',
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Action buttons
        Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _isConfirmed ? () => _executeOperation() : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _getOperationColor(),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Execute'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProgressView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header
        Row(
          children: [
            Icon(
              _getOperationIcon(),
              color: _getOperationColor(),
              size: 28,
            ),
            const SizedBox(width: 16),
            Text(
              _getOperationTitle(),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Progress indicator
        Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              CircularProgressIndicator(
                value: _progress,
                valueColor: AlwaysStoppedAnimation(_getOperationColor()),
              ),
              const SizedBox(height: 16),
              Text(
                '${(_progress * 100).round()}% Complete',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _currentAction,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),

        // Summary
        if (_result != null) ...[
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildStatChip('Successful', _result!.successful, Colors.green),
                const SizedBox(width: 8),
                _buildStatChip('Failed', _result!.failed, Colors.red),
                const SizedBox(width: 8),
                _buildStatChip('Total', _result!.total, Colors.blue),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildResultView() {
    if (_result == null) return const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header with result status
        Row(
          children: [
            Icon(
              _result!.isCompleteSuccess
                  ? Icons.check_circle
                  : _result!.isPartialSuccess
                      ? Icons.warning
                      : Icons.error,
              color: _result!.isCompleteSuccess
                  ? Colors.green
                  : _result!.isPartialSuccess
                      ? Colors.orange
                      : Colors.red,
              size: 28,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _result!.isCompleteSuccess
                        ? 'Operation Completed Successfully!'
                        : _result!.isPartialSuccess
                            ? 'Operation Partially Completed'
                            : 'Operation Failed',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_result!.successful} successful, ${_result!.failed} failed out of ${_result!.total}',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        // Error details (if any)
        if (_result!.errors.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            constraints: const BoxConstraints(maxHeight: 150),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.withOpacity(0.3)),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _result!.errors.length,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: const Icon(Icons.error, color: Colors.red, size: 16),
                  dense: true,
                  title: Text(
                    _result!.errors[index],
                    style: const TextStyle(fontSize: 12),
                  ),
                );
              },
            ),
          ),
        ],

        const SizedBox(height: 24),

        // Action buttons
        Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(_result),
                child: const Text('Close'),
              ),
            ),
            if (_result!.isPartialSuccess || _result!.isCompleteSuccess) ...[
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(_result),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _getOperationColor(),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Done'),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildStatChip(String label, int value, Color color) {
    return Chip(
      label: Text(
        '$label: $value',
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: color.withOpacity(0.1),
      side: BorderSide(color: color.withOpacity(0.3), width: 1),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: _isInProgress
              ? _buildProgressView()
              : _result != null
                  ? _buildResultView()
                  : _buildConfirmationView(),
        ),
      ),
    );
  }
}

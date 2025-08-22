import 'package:flutter/material.dart';
import 'package:jengamate/services/dynamic_data_service.dart';

class OrderFilterDialog extends StatefulWidget {
  final Function(Map<String, dynamic>) onApplyFilters;
  final Map<String, dynamic> initialFilters;

  const OrderFilterDialog({
    super.key,
    required this.onApplyFilters,
    this.initialFilters = const {},
  });

  @override
  State<OrderFilterDialog> createState() => _OrderFilterDialogState();
}

class _OrderFilterDialogState extends State<OrderFilterDialog> {
  late String selectedStatus;
  late DateTime? startDate;
  late DateTime? endDate;
  late double minAmount;
  late double maxAmount;

  List<String> orderStatuses = [];
  final DynamicDataService _dynamicDataService = DynamicDataService();

  @override
  void initState() {
    super.initState();
    selectedStatus = widget.initialFilters['status'] ?? 'all';
    startDate = widget.initialFilters['startDate'];
    endDate = widget.initialFilters['endDate'];
    minAmount = widget.initialFilters['minAmount'] ?? 0.0;
    maxAmount = widget.initialFilters['maxAmount'] ?? 999999.0;
    _loadOrderStatuses();
  }

  Future<void> _loadOrderStatuses() async {
    try {
      await _dynamicDataService.initialize();
      setState(() {
        orderStatuses = _dynamicDataService.getOrderStatuses();
      });
    } catch (e) {
      // Fallback to default values if service fails
      setState(() {
        orderStatuses = ['all', 'PENDING', 'PROCESSING', 'SHIPPED', 'DELIVERED', 'CANCELLED', 'REFUNDED'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Filter Orders'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Status Filter
            DropdownButtonFormField<String>(
              value: selectedStatus,
              decoration: const InputDecoration(
                labelText: 'Order Status',
                border: OutlineInputBorder(),
              ),
              items: orderStatuses.map((status) => DropdownMenuItem(
                value: status,
                child: Text(status == 'all' ? 'All Status' : status),
              )).toList(),
              onChanged: (value) {
                setState(() {
                  selectedStatus = value!;
                });
              },
            ),
            
            const SizedBox(height: 16),
            
            // Date Range
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    title: const Text('Start Date'),
                    subtitle: Text(
                      startDate?.toString().split(' ')[0] ?? 'Select date',
                    ),
                    onTap: () => _selectDate(context, true),
                  ),
                ),
                Expanded(
                  child: ListTile(
                    title: const Text('End Date'),
                    subtitle: Text(
                      endDate?.toString().split(' ')[0] ?? 'Select date',
                    ),
                    onTap: () => _selectDate(context, false),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Amount Range
            Text(
              'Amount Range: TZS ${minAmount.toInt()} - TZS ${maxAmount.toInt()}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            RangeSlider(
              values: RangeValues(minAmount, maxAmount),
              min: 0,
              max: 1000000,
              divisions: 100,
              labels: RangeLabels(
                'TZS ${minAmount.toInt()}',
                'TZS ${maxAmount.toInt()}',
              ),
              onChanged: (values) {
                setState(() {
                  minAmount = values.start;
                  maxAmount = values.end;
                });
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            final filters = {
              'status': selectedStatus,
              'startDate': startDate,
              'endDate': endDate,
              'minAmount': minAmount,
              'maxAmount': maxAmount,
            };
            widget.onApplyFilters(filters);
            Navigator.pop(context);
          },
          child: const Text('Apply Filters'),
        ),
        TextButton(
          onPressed: () {
            setState(() {
              selectedStatus = 'all';
              startDate = null;
              endDate = null;
              minAmount = 0.0;
              maxAmount = 999999.0;
            });
            widget.onApplyFilters({});
            Navigator.pop(context);
          },
          child: const Text('Clear All'),
        ),
      ],
    );
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStart ? (startDate ?? DateTime.now()) : (endDate ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    
    if (picked != null) {
      setState(() {
        if (isStart) {
          startDate = picked;
        } else {
          endDate = picked;
        }
      });
    }
  }
}
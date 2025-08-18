import 'package:flutter/material.dart';

class InquiryFilterDialog extends StatefulWidget {
  final Function(Map<String, dynamic>) onApplyFilters;
  final Map<String, dynamic> initialFilters;

  const InquiryFilterDialog({
    Key? key,
    required this.onApplyFilters,
    this.initialFilters = const {},
  }) : super(key: key);

  @override
  State<InquiryFilterDialog> createState() => _InquiryFilterDialogState();
}

class _InquiryFilterDialogState extends State<InquiryFilterDialog> {
  late String selectedStatus;
  late DateTime? startDate;
  late DateTime? endDate;
  late String selectedPriority;

  final List<String> inquiryStatuses = [
    'all',
    'PENDING',
    'IN_PROGRESS',
    'RESOLVED',
    'CLOSED'
  ];

  final List<String> priorities = [
    'all',
    'LOW',
    'MEDIUM',
    'HIGH',
    'URGENT'
  ];

  @override
  void initState() {
    super.initState();
    selectedStatus = widget.initialFilters['status'] ?? 'all';
    startDate = widget.initialFilters['startDate'];
    endDate = widget.initialFilters['endDate'];
    selectedPriority = widget.initialFilters['priority'] ?? 'all';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Filter Inquiries'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Status Filter
            DropdownButtonFormField<String>(
              value: selectedStatus,
              decoration: const InputDecoration(
                labelText: 'Inquiry Status',
                border: OutlineInputBorder(),
              ),
              items: inquiryStatuses.map((status) => DropdownMenuItem(
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
            
            // Priority Filter
            DropdownButtonFormField<String>(
              value: selectedPriority,
              decoration: const InputDecoration(
                labelText: 'Priority',
                border: OutlineInputBorder(),
              ),
              items: priorities.map((priority) => DropdownMenuItem(
                value: priority,
                child: Text(priority == 'all' ? 'All Priorities' : priority),
              )).toList(),
              onChanged: (value) {
                setState(() {
                  selectedPriority = value!;
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
              'priority': selectedPriority,
              'startDate': startDate,
              'endDate': endDate,
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
              selectedPriority = 'all';
              startDate = null;
              endDate = null;
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
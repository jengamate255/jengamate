import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AdvancedFilterPanel extends StatefulWidget {
  final Map<String, dynamic> initialFilters;
  final Function(Map<String, dynamic>) onFiltersChanged;
  final VoidCallback onClearFilters;

  const AdvancedFilterPanel({
    Key? key,
    required this.initialFilters,
    required this.onFiltersChanged,
    required this.onClearFilters,
  }) : super(key: key);

  @override
  _AdvancedFilterPanelState createState() => _AdvancedFilterPanelState();
}

class _AdvancedFilterPanelState extends State<AdvancedFilterPanel> {
  late Map<String, dynamic> _currentFilters;
  final _dateFormat = DateFormat('yyyy-MM-dd');

  @override
  void initState() {
    super.initState();
    _currentFilters = Map.from(widget.initialFilters);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Advanced Filters',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Row(
                  children: [
                    TextButton(
                      onPressed: widget.onClearFilters,
                      child: const Text('Clear All'),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildRoleFilter(),
            const SizedBox(height: 16),
            _buildStatusFilter(),
            const SizedBox(height: 16),
            _buildDateRangeFilter(),
            const SizedBox(height: 16),
            _buildActivityLevelFilter(),
            const SizedBox(height: 16),
            _buildGeographicFilter(),
            const SizedBox(height: 16),
            _buildDocumentVerificationFilter(),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  widget.onFiltersChanged(_currentFilters);
                  Navigator.pop(context);
                },
                child: const Text('Apply Filters'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Role', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: ['admin', 'supplier', 'engineer'].map((role) {
            return FilterChip(
              label: Text(role.toUpperCase()),
              selected: _currentFilters['role'] == role,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _currentFilters['role'] = role;
                  } else {
                    _currentFilters.remove('role');
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildStatusFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Status', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: ['pending', 'approved', 'rejected', 'suspended'].map((status) {
            return FilterChip(
              label: Text(status.toUpperCase()),
              selected: _currentFilters['status'] == status,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _currentFilters['status'] = status;
                  } else {
                    _currentFilters.remove('status');
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDateRangeFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Registration Date Range', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => _selectDate(context, true),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Start Date',
                    border: OutlineInputBorder(),
                  ),
                  child: Text(
                    _currentFilters['startDate'] != null
                        ? _dateFormat.format(_currentFilters['startDate'])
                        : 'Select start date',
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: InkWell(
                onTap: () => _selectDate(context, false),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'End Date',
                    border: OutlineInputBorder(),
                  ),
                  child: Text(
                    _currentFilters['endDate'] != null
                        ? _dateFormat.format(_currentFilters['endDate'])
                        : 'Select end date',
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActivityLevelFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Activity Level', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            {'label': 'High', 'value': 'high'},
            {'label': 'Medium', 'value': 'medium'},
            {'label': 'Low', 'value': 'low'},
            {'label': 'Inactive', 'value': 'inactive'},
          ].map((level) {
            return FilterChip(
              label: Text(level['label']!),
              selected: _currentFilters['activityLevel'] == level['value'],
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _currentFilters['activityLevel'] = level['value'];
                  } else {
                    _currentFilters.remove('activityLevel');
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildGeographicFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Location', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                initialValue: _currentFilters['country'] ?? '',
                decoration: const InputDecoration(
                  labelText: 'Country',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  setState(() {
                    if (value.isNotEmpty) {
                      _currentFilters['country'] = value;
                    } else {
                      _currentFilters.remove('country');
                    }
                  });
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                initialValue: _currentFilters['region'] ?? '',
                decoration: const InputDecoration(
                  labelText: 'Region/State',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  setState(() {
                    if (value.isNotEmpty) {
                      _currentFilters['region'] = value;
                    } else {
                      _currentFilters.remove('region');
                    }
                  });
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDocumentVerificationFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Document Verification', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            {'label': 'Verified', 'value': 'verified'},
            {'label': 'Pending', 'value': 'pending'},
            {'label': 'Rejected', 'value': 'rejected'},
            {'label': 'Expired', 'value': 'expired'},
          ].map((status) {
            return FilterChip(
              label: Text(status['label']!),
              selected: _currentFilters['documentStatus'] == status['value'],
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _currentFilters['documentStatus'] = status['value'];
                  } else {
                    _currentFilters.remove('documentStatus');
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _currentFilters['startDate'] = picked;
        } else {
          _currentFilters['endDate'] = picked;
        }
      });
    }
  }
}
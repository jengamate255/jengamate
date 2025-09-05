import 'package:flutter/material.dart';
import 'package:jengamate/models/order_status.dart';
import 'package:jengamate/models/order_model.dart';
import 'package:jengamate/services/database_service.dart';

class TrackingUpdateDialog extends StatefulWidget {
  final OrderModel order;

  const TrackingUpdateDialog({super.key, required this.order});

  @override
  State<TrackingUpdateDialog> createState() => _TrackingUpdateDialogState();
}

class _TrackingUpdateDialogState extends State<TrackingUpdateDialog> {
  late OrderStatus _selectedStatus;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.order.status;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Update Order Status'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Order ID: ${widget.order.id}'),
          const SizedBox(height: 16),
          DropdownButtonFormField<OrderStatus>(
            value: _selectedStatus,
            items: OrderStatus.values.map((OrderStatus status) {
              return DropdownMenuItem<OrderStatus>(
                value: status,
                child: Text(status.name.toUpperCase()),
              );
            }).toList(),
            onChanged: (OrderStatus? newValue) {
              if (newValue != null) {
                setState(() {
                  _selectedStatus = newValue;
                });
              }
            },
            decoration: const InputDecoration(
              labelText: 'Order Status',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            // Update the order in Firestore
            final updatedOrder = widget.order.copyWith(
              status: _selectedStatus,
              updatedAt: DateTime.now(),
            );
            await DatabaseService().updateOrder(updatedOrder);
            if (mounted) {
              Navigator.of(context).pop();
            }
          },
          child: const Text('Update'),
        ),
      ],
    );
  }
}

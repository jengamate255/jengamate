import 'package:flutter/material.dart';
import 'package:jengamate/models/order_model.dart';
import 'package:jengamate/services/database_service.dart';
import 'package:provider/provider.dart';
import 'package:jengamate/services/user_state_provider.dart';
import 'package:jengamate/ui/design_system/layout/adaptive_padding.dart';
import 'package:jengamate/ui/design_system/tokens/spacing.dart';
import 'package:jengamate/ui/design_system/components/jm_card.dart';
import 'package:jengamate/ui/design_system/components/jm_skeleton.dart';
import 'package:jengamate/screens/order/widgets/order_filter_dialog.dart';
import 'package:jengamate/screens/order/order_details_screen.dart';
import 'package:jengamate/screens/invoices/create_invoice_screen.dart';
import 'package:jengamate/screens/order/payment_processing_screen.dart';
import 'package:jengamate/services/print_service.dart';

import '../../models/user_model.dart';

class OrderScreen extends StatefulWidget {
  const OrderScreen({super.key});

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  final DatabaseService dbService = DatabaseService();
  String _searchQuery = '';
  String? _selectedStatusFilter;
  Map<String, dynamic> _activeFilters = {};

  @override
  Widget build(BuildContext context) {
    final userState = Provider.of<UserStateProvider>(context);
    final currentUser = userState.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Orders Management'),
        actions: [
          IconButton(
            icon: Icon(
              Icons.filter_list,
              color: _activeFilters.isNotEmpty
                  ? Theme.of(context).primaryColor
                  : null,
            ),
            onPressed: () async {
              final result = await showDialog<Map<String, dynamic>>(
                context: context,
                builder: (context) => OrderFilterDialog(
                  onApplyFilters: (filters) {
                    Navigator.of(context).pop(filters);
                  },
                  initialFilters: _activeFilters,
                ),
              );

              if (result != null) {
                setState(() {
                  _activeFilters = result;
                  _selectedStatusFilter = result['status'];
                });
              }
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60.0),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search orders...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),
        ),
      ),
      body: StreamBuilder<List<OrderModel>>(
        stream: dbService.getOrders(currentUser?.uid ?? ''),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return AdaptivePadding(
              child: ListView.separated(
                itemCount: 8,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: JMSpacing.md),
                itemBuilder: (context, index) => const JMCard(
                  child: ListTile(
                    leading: CircleAvatar(),
                    title: JMSkeleton(height: 16, width: 180),
                    subtitle: JMSkeleton(height: 14, width: 220),
                    trailing: JMSkeleton(height: 16, width: 60),
                  ),
                ),
              ),
            );
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const AdaptivePadding(
              child: Center(child: Text('No orders found.')),
            );
          }

          final orders = snapshot.data!;

          return AdaptivePadding(
            child: ListView.separated(
              itemCount: orders.length,
              separatorBuilder: (_, __) => const SizedBox(height: JMSpacing.md),
              itemBuilder: (context, index) {
                final order = orders[index];
                return JMCard(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getStatusColor(
                          order.status.toString().split('.').last),
                      child: Icon(
                        _getStatusIcon(order.status.toString().split('.').last),
                        color: Colors.white,
                      ),
                    ),
                    title: Text(
                      'Order #${order.id}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            'Status: ${order.status.toString().split('.').last}'),
                        Text('Date: ${_formatDate(order.createdAt)}'),
                        Text(
                            'Total: TSh ${order.totalAmount.toStringAsFixed(2)}'),
                      ],
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) => _handleOrderAction(value, order),
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'view',
                          child: Row(
                            children: [
                              Icon(Icons.visibility),
                              SizedBox(width: 8),
                              Text('View Details'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'invoice',
                          child: Row(
                            children: [
                              Icon(Icons.receipt),
                              SizedBox(width: 8),
                              Text('Create Invoice'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'print',
                          child: Row(
                            children: [
                              Icon(Icons.print),
                              SizedBox(width: 8),
                              Text('Print Order'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'payment',
                          child: Row(
                            children: [
                              Icon(Icons.payment),
                              SizedBox(width: 8),
                              Text('Process Payment'),
                            ],
                          ),
                        ),
                      ],
                    ),
                    onTap: () => _handleOrderAction('view', order),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'shipped':
        return Colors.purple;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.schedule;
      case 'confirmed':
        return Icons.check_circle;
      case 'shipped':
        return Icons.local_shipping;
      case 'delivered':
        return Icons.done_all;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _handleOrderAction(String action, OrderModel order) {
    switch (action) {
      case 'view':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OrderDetailsScreen(orderId: order.id ?? ''),
          ),
        );
        break;
      case 'invoice':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const CreateInvoiceScreen(),
          ),
        );
        break;
      case 'print':
        _printOrder(order);
        break;
      case 'payment':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentProcessingScreen(orderId: order.id ?? ''),
          ),
        );
        break;
    }
  }

  void _printOrder(OrderModel order) async {
    try {
      await PrintService.printOrder(order);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Order #${order.id?.substring(0, 8) ?? ''} printed successfully!'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error printing order: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}

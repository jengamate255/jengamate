import 'package:jengamate/config/app_route_builders.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jengamate/models/order_model.dart';
import 'package:jengamate/models/enums/order_enums.dart';
import 'package:jengamate/models/user_model.dart';
import 'package:jengamate/models/enums/user_role.dart';
import 'package:provider/provider.dart';
import 'package:jengamate/services/user_state_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:jengamate/screens/order/create_order_screen.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  OrderStatus? _selectedStatus;
  // final DatabaseService _databaseService = DatabaseService(); // Removed unused field

  @override
  Widget build(BuildContext context) {
    final userState = Provider.of<UserStateProvider>(context);
    final currentUser = userState.currentUser;

    // Show loading state if user data is still loading
    if (userState.isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading orders...'),
            ],
          ),
        ),
      );
    }

    // Show error state if no user data
    if (currentUser == null) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red),
              SizedBox(height: 16),
              Text('Unable to load user data'),
              Text('Please try logging in again'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Orders Management'),
        actions: [
          // Status filter dropdown
          DropdownButton<OrderStatus?>(
            value: _selectedStatus,
            hint: const Text('Filter by Status'),
            items: [
              const DropdownMenuItem<OrderStatus?>(
                value: null,
                child: Text('All Orders'),
              ),
              ...OrderStatus.values.map((status) {
                return DropdownMenuItem<OrderStatus?>(
                  value: status,
                  child: Text(status.toString().split('.').last),
                );
              }),
            ],
            onChanged: (value) {
              setState(() {
                _selectedStatus = value;
              });
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _getOrdersStream(currentUser),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading orders...'),
                ],
              ),
            );
          }

          if (snapshot.hasError) {
            final errorMessage = snapshot.error.toString();
            // Check if it's an index error
            if (errorMessage.contains('index') || errorMessage.contains('requires an index')) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.warning, size: 48, color: Colors.orange),
                      const SizedBox(height: 16),
                      const Text(
                        'Database Index Required',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Orders data is temporarily unavailable.\nPlease contact support to resolve this issue.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          // Refresh the stream
                          setState(() {});
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              );
            }
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    const Text('Error loading orders'),
                    const SizedBox(height: 8),
                    Text(
                      'Error: ${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox, size: 48, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No orders found'),
                  Text('Orders will appear here when available'),
                ],
              ),
            );
          }

          final orders = snapshot.data!.docs
              .map((doc) {
                try {
                  final order = OrderModel.fromFirestore(doc.data()! as Map<String, dynamic>, docId: doc.id);
                  // Ensure the order has a valid ID
                  if (order.id == null || order.id!.isEmpty) {
                    print('Warning: Order ${doc.id} has no valid ID, using document ID as fallback');
                  }
                  return order;
                } catch (e) {
                  print('Error parsing order ${doc.id}: $e');
                  return null;
                }
              })
              .where((order) => order != null)
              .cast<OrderModel>()
              .toList();

          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];

              // Ensure order has valid data
              final id = order.id ?? '';
              final orderNumber = order.orderNumber?.isNotEmpty == true
                  ? order.orderNumber!
                  : (id.length > 8 ? id.substring(0, 8).toUpperCase() : id.toUpperCase());

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text('Order #$orderNumber'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Status: ${order.statusDisplayName}'),
                      Text(
                          'Total: ${order.currency} ${order.totalAmount.toStringAsFixed(2)}'),
                      Text(
                          'Created: ${order.createdAt.toString().split(' ')[0]}'),
                    ],
                  ),
                  trailing: _buildStatusChip(order.status),
                  onTap: () {
                    final id = order.id ?? order.externalId ?? '';
                    if (id.isNotEmpty) {
                      context.go(AppRouteBuilders.orderDetailsPath(id));
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Order details not available - missing order ID')),
                      );
                    }
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: currentUser.role == UserRole.admin
          ? FloatingActionButton(
              heroTag: "createOrderAdmin",
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreateOrderScreen(),
                  ),
                );
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Stream<QuerySnapshot> _getOrdersStream(UserModel currentUser) {
    Query query = FirebaseFirestore.instance.collection('orders');

    // Filter based on user role
    if (currentUser.role == UserRole.supplier) {
      query = query.where('supplierId', isEqualTo: currentUser.uid);
    } else if (currentUser.role == UserRole.engineer) {
      query = query.where('customerId', isEqualTo: currentUser.uid);
    }
    // Admin can see all orders

    // Filter by status if selected
    if (_selectedStatus != null) {
      query = query.where('status',
          isEqualTo: _selectedStatus!.name);
    }

    return query.orderBy('createdAt', descending: true).snapshots();
  }

  Widget _buildStatusChip(OrderStatus status) {
    Color color;
    switch (status) {
      case OrderStatus.pending:
        color = Colors.orange;
        break;
      case OrderStatus.processing:
        color = Colors.blue;
        break;
      case OrderStatus.shipped:
        color = Colors.purple;
        break;
      case OrderStatus.delivered:
        color = Colors.green;
        break;
      case OrderStatus.cancelled:
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Chip(
      label: Text(
        status.toString().split('.').last,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
      backgroundColor: color,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:jengamate/models/order_model.dart';
import 'package:jengamate/screens/order/order_list_item.dart';
import 'package:jengamate/services/order_service.dart';

class OrdersManagementScreen extends StatefulWidget {
  const OrdersManagementScreen({super.key});

  @override
  State<OrdersManagementScreen> createState() => _OrdersManagementScreenState();
}

class _OrdersManagementScreenState extends State<OrdersManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<String> _tabs = [
    'All',
    'Pending',
    'Processing',
    'Shipped',
    'Delivered',
    'Cancelled'
  ];

  final OrderService _orderService = OrderService();
  late Stream<List<OrderModel>> _ordersStream;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _updateOrdersStream();
    _tabController.addListener(_updateOrdersStream);
  }

  void _updateOrdersStream() {
    setState(() {
      final selectedTab = _tabs[_tabController.index];
      if (selectedTab == 'All') {
        _ordersStream = _orderService.getAllOrders();
      } else {
        _ordersStream = _orderService.getOrdersByStatus(selectedTab);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Orders Management'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: _tabs.map((String tab) => Tab(text: tab.toUpperCase())).toList(),
        ),
      ),
      body: StreamBuilder<List<OrderModel>>(
        stream: _ordersStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No orders found.'));
          }

          final orders = snapshot.data!;

          return TabBarView(
            controller: _tabController,
            children: _tabs.map((String tab) {
              if (orders.isEmpty) {
                return Center(child: Text('No orders with status: $tab'));
              }

              return ListView.builder(
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  return OrderListItem(order: orders[index]);
                },
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

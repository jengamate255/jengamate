import 'package:flutter/material.dart';
import 'package:jengamate/models/order_model.dart';
import 'package:jengamate/services/database_service.dart';
import 'package:provider/provider.dart';
import 'package:jengamate/ui/design_system/layout/adaptive_padding.dart';
import 'package:jengamate/ui/design_system/tokens/spacing.dart';
import 'package:jengamate/ui/design_system/components/jm_card.dart';
import 'package:jengamate/ui/design_system/components/jm_skeleton.dart';
import 'package:jengamate/screens/order/widgets/order_filter_dialog.dart';

import '../../models/user_model.dart';

class OrderScreen extends StatefulWidget { // Changed to StatefulWidget
  const OrderScreen({super.key});

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  final DatabaseService dbService = DatabaseService();
  String _searchQuery = '';
  Map<String, dynamic> _activeFilters = {};

  @override
  Widget build(BuildContext context) {
    final currentUser = Provider.of<UserModel?>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Orders'),
        actions: [
          IconButton(
            icon: Icon(
              Icons.filter_list,
              color: _activeFilters.isNotEmpty ? Theme.of(context).primaryColor : null,
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
                });
              }
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
        stream: dbService.getOrders(currentUser?.uid ?? '', searchQuery: _searchQuery, statusFilter: _selectedStatusFilter), // Pass filters
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return AdaptivePadding(
              child: ListView.separated(
                itemCount: 8,
                separatorBuilder: (_, __) => const SizedBox(height: JMSpacing.md),
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
                    title: Text('Order #${order.id}'),
                    subtitle: Text('Status: ${order.statusDisplayName}'),
                    trailing: Text('TSh ${order.totalAmount.toStringAsFixed(2)}'),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

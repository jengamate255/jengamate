import 'package:flutter/material.dart';
import 'package:jengamate/models/order_model.dart';
import 'package:jengamate/models/inquiry_model.dart';
import 'package:jengamate/services/database_service.dart';
import 'package:provider/provider.dart';
import 'package:jengamate/models/user_model.dart';
import 'package:jengamate/models/enums/order_enums.dart';
import 'package:jengamate/ui/design_system/layout/adaptive_padding.dart';
import 'package:jengamate/ui/design_system/components/jm_card.dart';
import 'package:jengamate/ui/design_system/tokens/spacing.dart';

class OrderAndInquiryManagementScreen extends StatelessWidget {
  const OrderAndInquiryManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dbService = DatabaseService();
    final currentUser = context.watch<UserModel?>();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Order & Inquiry Management'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Orders'),
              Tab(text: 'Inquiries'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Orders Tab
            StreamBuilder<List<OrderModel>>(
              stream: dbService.getOrders(null), // Admin gets all orders
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

                return AdaptivePadding(
                  child: ListView.separated(
                    itemCount: orders.length,
                    separatorBuilder: (_, __) => const SizedBox(height: JMSpacing.sm),
                    itemBuilder: (context, index) {
                      final order = orders[index];
                      return JMCard(
                        child: ListTile(
                          title: Text('Order #${order.id}'),
                          subtitle: Text('Buyer ID: ${order.buyerId}'),
                          trailing: DropdownButton<OrderStatus>(
                            value: order.status,
                            onChanged: (OrderStatus? newStatus) {
                              if (newStatus != null) {
                                dbService.updateOrderStatus(order.id, newStatus.name);
                              }
                            },
                            items: OrderStatus.values
                                .map<DropdownMenuItem<OrderStatus>>((OrderStatus value) {
                              return DropdownMenuItem<OrderStatus>(
                                value: value,
                                child: Text(value.toString().split('.').last),
                              );
                            }).toList(),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),

            // Inquiries Tab
            StreamBuilder<List<InquiryModel>>(
              stream: dbService.streamAllInquiries(), // Admin gets all inquiries
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No inquiries found.'));
                }

                final inquiries = snapshot.data!;

                return AdaptivePadding(
                  child: ListView.separated(
                    itemCount: inquiries.length,
                    separatorBuilder: (_, __) => const SizedBox(height: JMSpacing.sm),
                    itemBuilder: (context, index) {
                      final inquiry = inquiries[index];
                      return JMCard(
                        child: ListTile(
                          title: Text('Inquiry #${inquiry.id.substring(0, 8)}'),
                          subtitle: Text(inquiry.status),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

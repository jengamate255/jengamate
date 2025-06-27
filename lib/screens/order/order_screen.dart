import 'package:flutter/material.dart';
import 'package:jengamate/models/order_model.dart';
import 'package:jengamate/screens/order/widgets/order_card.dart';

class OrderScreen extends StatelessWidget {
  const OrderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock data for the order list
    final List<Order> orders = [
      Order(
        id: '626925',
        type: 'NORMAL',
        status: 'DELIVERED',
        customerName: 'No name',
        customerEmail: 'No email',
        customerPhone: 'No phone',
        totalAmount: '1,236,000.00 TZS',
        paymentMethod: 'CASH ON DELIVERY',
        date: 'May 10, 2025 - 12:44 PM',
        handler: 'jack master',
      ),
      Order(
        id: '030698',
        type: 'NORMAL',
        status: 'PENDING',
        customerName: 'No name',
        customerEmail: 'No email',
        customerPhone: 'No phone',
        totalAmount: '840,000.00 TZS',
        paymentMethod: 'PAY NOW',
        date: 'May 10, 2025 - 08:32 AM',
        handler: 'jack master',
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
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
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          return OrderCard(order: orders[index]);
        },
      ),
    );
  }
}

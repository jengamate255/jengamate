import 'package:cloud_firestore/cloud_firestore.dart';

class OrderStatsModel {
  final int totalOrders;
  final int pending;
  final int completed;
  final double totalSales;

  OrderStatsModel({
    required this.totalOrders,
    required this.pending,
    required this.completed,
    required this.totalSales,
  });

  factory OrderStatsModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return OrderStatsModel(
      totalOrders: data['totalOrders'] ?? 0,
      pending: data['pending'] ?? 0,
      completed: data['completed'] ?? 0,
      totalSales: (data['totalSales'] ?? 0).toDouble(),
    );
  }
}

class OrderStatsModel {
  final int totalOrders;
  final int pendingOrders;
  final int completedOrders;
  final double totalSales;

  OrderStatsModel({
    required this.totalOrders,
    required this.pendingOrders,
    required this.completedOrders,
    this.totalSales = 0.0,
  });

  int get pending => pendingOrders;
  int get completed => completedOrders;
}

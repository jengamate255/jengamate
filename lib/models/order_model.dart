class Order {
  final String id;
  final String type;
  final String status;
  final String customerName;
  final String customerEmail;
  final String customerPhone;
  final String totalAmount;
  final String paymentMethod;
  final String date;
  final String handler;

  Order({
    required this.id,
    required this.type,
    required this.status,
    required this.customerName,
    required this.customerEmail,
    required this.customerPhone,
    required this.totalAmount,
    required this.paymentMethod,
    required this.date,
    required this.handler,
  });
}

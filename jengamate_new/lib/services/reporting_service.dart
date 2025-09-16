import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jengamate/models/financial_transaction_model.dart';
import 'package:jengamate/models/order_model.dart';
import 'package:jengamate/models/user_model.dart';
import 'package:jengamate/models/rfq_model.dart';

class ReportingService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<List<UserModel>> getUsersReport(
      {DateTime? startDate, DateTime? endDate}) async {
    Query query = _db.collection('users');
    if (startDate != null) {
      query = query.where('createdAt', isGreaterThanOrEqualTo: startDate);
    }
    if (endDate != null) {
      query = query.where('createdAt', isLessThanOrEqualTo: endDate);
    }
    final snapshot = await query.get();
    return snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
  }

  Future<List<OrderModel>> getOrdersReport(
      {DateTime? startDate, DateTime? endDate}) async {
    Query query = _db.collection('orders');
    if (startDate != null) {
      query = query.where('createdAt', isGreaterThanOrEqualTo: startDate);
    }
    if (endDate != null) {
      query = query.where('createdAt', isLessThanOrEqualTo: endDate);
    }
    final snapshot = await query.get();
    return snapshot.docs.map((doc) => OrderModel.fromFirestore((doc.data() as Map<String, dynamic>), docId: doc.id)).toList();
  }

  Future<List<FinancialTransactionModel>> getFinancialTransactionsReport(
      {DateTime? startDate, DateTime? endDate}) async {
    Query query = _db.collection('transactions');
    if (startDate != null) {
      query = query.where('createdAt', isGreaterThanOrEqualTo: startDate);
    }
    if (endDate != null) {
      query = query.where('createdAt', isLessThanOrEqualTo: endDate);
    }
    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) => FinancialTransactionModel.fromFirestore((doc.data() as Map<String, dynamic>), docId: doc.id))
        .toList();
  }

  Future<List<RFQModel>> getRfqsReport(
      {DateTime? startDate, DateTime? endDate}) async {
    Query query = _db.collection('rfqs');
    if (startDate != null) {
      query = query.where('createdAt', isGreaterThanOrEqualTo: startDate);
    }
    if (endDate != null) {
      query = query.where('createdAt', isLessThanOrEqualTo: endDate);
    }
    final snapshot = await query.get();
    return snapshot.docs.map((doc) => RFQModel.fromFirestore((doc.data() as Map<String, dynamic>), docId: doc.id)).toList();
  }

  Future<List<Map<String, dynamic>>> generateUserReport(DateTime startDate, DateTime endDate) async {
    final users = await getUsersReport(startDate: startDate, endDate: endDate);
    return users.map((user) => {
          'uid': user.uid,
          'name': user.name,
          'email': user.email,
          'phoneNumber': user.phoneNumber,
          'role': user.role,
          'company': user.companyName,
          'createdAt': user.createdAt,
        }).toList();
  }

  Future<List<Map<String, dynamic>>> generateOrderReport(DateTime startDate, DateTime endDate) async {
    final orders = await getOrdersReport(startDate: startDate, endDate: endDate);
    return orders.map((order) => {
          'id': order.id,
          'customerName': order.customerName,
          'totalAmount': order.totalAmount,
          'status': order.status,
          'createdAt': order.createdAt,
        }).toList();
  }

  Future<List<Map<String, dynamic>>> generateFinancialReport(DateTime startDate, DateTime endDate) async {
    final transactions = await getFinancialTransactionsReport(startDate: startDate, endDate: endDate);
    return transactions.map((transaction) => {
          'id': transaction.id,
          'type': transaction.type,
          'amount': transaction.amount,
          'date': transaction.createdAt, // Assuming createdAt is the relevant date
        }).toList();
  }

  Future<List<Map<String, dynamic>>> generateRFQReport(DateTime startDate, DateTime endDate) async {
    final rfqs = await getRfqsReport(startDate: startDate, endDate: endDate);
    return rfqs.map((rfq) => {
          'id': rfq.id,
          'productName': rfq.productName,
          'quantity': rfq.quantity,
          'status': rfq.status,
          'createdAt': rfq.createdAt,
        }).toList();
  }
}

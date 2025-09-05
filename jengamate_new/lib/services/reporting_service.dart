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
    return snapshot.docs.map((doc) => OrderModel.fromFirestore(doc)).toList();
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
        .map((doc) => FinancialTransactionModel.fromFirestore(doc))
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
    return snapshot.docs.map((doc) => RFQModel.fromFirestore(doc)).toList();
  }
}

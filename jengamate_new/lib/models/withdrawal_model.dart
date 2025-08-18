import 'package:cloud_firestore/cloud_firestore.dart';

class WithdrawalModel {
  final String id;
  final double amount;
  final String status;
  final Timestamp createdAt;
  final String userId;

  WithdrawalModel({
    required this.id,
    required this.amount,
    required this.status,
    required this.createdAt,
    required this.userId,
  });

  factory WithdrawalModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return WithdrawalModel(
      id: doc.id,
      amount: data['amount'] ?? 0.0,
      status: data['status'] ?? '',
      createdAt: data['createdAt'] ?? Timestamp.now(),
      userId: data['userId'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'amount': amount,
      'status': status,
      'createdAt': createdAt,
      'userId': userId,
    };
  }
}
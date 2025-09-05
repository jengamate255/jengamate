import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jengamate/models/enums/payment_enums.dart';

class PaymentModel {
  final String id;
  final String orderId;
  final String userId;
  final double amount;
  final PaymentStatus status;
  final String paymentMethod;
  final String? transactionId;
  final String? paymentProofUrl;
  final DateTime createdAt;
  final DateTime? completedAt;
  final Map<String, dynamic>? metadata;

  PaymentModel({
    required this.id,
    required this.orderId,
    required this.userId,
    required this.amount,
    required this.status,
    required this.paymentMethod,
    this.transactionId,
    this.paymentProofUrl,
    required this.createdAt,
    this.completedAt,
    this.metadata,
  });

  String get uid => id;

  factory PaymentModel.fromMap(Map<String, dynamic> map) {
    return PaymentModel(
      id: map['id'] ?? '',
      orderId: map['orderId'] ?? '',
      userId: map['userId'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      status: PaymentStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => PaymentStatus.unknown,
      ),
      paymentMethod: map['paymentMethod'] ?? 'unknown',
      transactionId: map['transactionId'],
      paymentProofUrl: map['paymentProofUrl'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      completedAt: map['completedAt'] != null
          ? (map['completedAt'] as Timestamp).toDate()
          : null,
      metadata: map['metadata'] as Map<String, dynamic>?,
    );
  }

  factory PaymentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PaymentModel.fromMap(data);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'orderId': orderId,
      'userId': userId,
      'amount': amount,
      'status': status.name,
      'paymentMethod': paymentMethod,
      'transactionId': transactionId,
      'paymentProofUrl': paymentProofUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'completedAt':
          completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'metadata': metadata,
    };
  }

  Map<String, dynamic> toFirestore() {
    return toMap();
  }

  PaymentModel copyWith({
    String? id,
    String? orderId,
    String? userId,
    double? amount,
    PaymentStatus? status,
    String? paymentMethod,
    String? transactionId,
    String? paymentProofUrl,
    DateTime? createdAt,
    DateTime? completedAt,
    Map<String, dynamic>? metadata,
  }) {
    return PaymentModel(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      transactionId: transactionId ?? this.transactionId,
      paymentProofUrl: paymentProofUrl ?? this.paymentProofUrl,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      metadata: metadata ?? this.metadata,
    );
  }
}

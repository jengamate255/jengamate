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
  final DateTime? updatedAt;
  final Map<String, dynamic>? metadata;
  final bool autoApproved;

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
    this.updatedAt,
    this.metadata,
    this.autoApproved = false,
  });

  String get uid => id;

  factory PaymentModel.fromMap(Map<String, dynamic> map) {
    return PaymentModel(
      id: map['id'] ?? '',
      orderId: map['order_id'] ?? '',
      userId: map['user_id'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      status: PaymentStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => PaymentStatus.unknown,
      ),
      paymentMethod: map['payment_method'] ?? 'unknown',
      transactionId: map['transaction_id'],
      paymentProofUrl: map['payment_proof_url'],
      createdAt: DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
      completedAt: map['completed_at'] != null
          ? DateTime.parse(map['completed_at'])
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'])
          : null,
      metadata: map['metadata'] as Map<String, dynamic>?,
      autoApproved: map['auto_approved'] as bool? ?? false,
    );
  }

  factory PaymentModel.fromSupabase(Map<String, dynamic> data) {
    return PaymentModel.fromMap(data);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'order_id': orderId,
      'user_id': userId,
      'amount': amount,
      'status': status.name,
      'payment_method': paymentMethod,
      'transaction_id': transactionId,
      'payment_proof_url': paymentProofUrl,
      'created_at': createdAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'metadata': metadata,
      'auto_approved': autoApproved,
    };
  }

  Map<String, dynamic> toSupabase() {
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
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
    bool? autoApproved,
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
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
      autoApproved: autoApproved ?? this.autoApproved,
    );
  }
}

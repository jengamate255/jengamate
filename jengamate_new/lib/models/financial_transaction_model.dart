import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jengamate/models/enums/transaction_enums.dart';


class FinancialTransaction {
  final String id;
  final double amount;
  final TransactionType type;
  final TransactionStatus status;
  final String userId;
  final String relatedId;
  final String? orderId;
  final String? paymentId;
  final String? commissionRuleId;
  final double? commissionRate;
  final String currency;
  final String? description;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? processedBy;
  final String? rejectionReason;
  final String? referenceNumber;

  FinancialTransaction({
    required this.id,
    required this.amount,
    required this.type,
    required this.userId,
    required this.relatedId,
    this.orderId,
    this.paymentId,
    this.commissionRuleId,
    this.commissionRate,
    this.currency = 'USD',
    this.description,
    this.metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.processedBy,
    this.rejectionReason,
    this.referenceNumber,
    this.status = TransactionStatus.pending,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory FinancialTransaction.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    // Parse transaction type
    TransactionType transactionType = TransactionType.values.firstWhere(
      (e) => e.toString().split('.').last == (data['type'] as String? ?? '').toLowerCase(),
      orElse: () => TransactionType.payment, // Default to payment as per new enum
    );
    
    // Parse transaction status
    TransactionStatus transactionStatus = TransactionStatus.values.firstWhere(
      (e) => e.toString().split('.').last == (data['status'] as String? ?? '').toLowerCase(),
      orElse: () => TransactionStatus.pending,
    );

    return FinancialTransaction(
      id: doc.id,
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      type: transactionType,
      status: transactionStatus,
      userId: data['userId'] ?? '',
      relatedId: data['relatedId'] ?? '',
      orderId: data['orderId'],
      paymentId: data['paymentId'],
      commissionRuleId: data['commissionRuleId'],
      commissionRate: (data['commissionRate'] as num?)?.toDouble(),
      currency: data['currency'] ?? 'USD',
      description: data['description'],
      metadata: data['metadata'] as Map<String, dynamic>?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      processedBy: data['processedBy'],
      rejectionReason: data['rejectionReason'],
      referenceNumber: data['referenceNumber'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'amount': amount,
      'type': type.toString().split('.').last,
      'status': status.toString().split('.').last,
      'userId': userId,
      'relatedId': relatedId,
      'orderId': orderId,
      'paymentId': paymentId,
      'commissionRuleId': commissionRuleId,
      'commissionRate': commissionRate,
      'currency': currency,
      'description': description,
      'metadata': metadata,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'processedBy': processedBy,
      'rejectionReason': rejectionReason,
      'referenceNumber': referenceNumber,
    };
  }

  FinancialTransaction copyWith({
    String? id,
    double? amount,
    TransactionType? type,
    TransactionStatus? status,
    String? userId,
    String? relatedId,
    String? orderId,
    String? paymentId,
    String? commissionRuleId,
    double? commissionRate,
    String? currency,
    String? description,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? processedBy,
    String? rejectionReason,
    String? referenceNumber,
  }) {
    return FinancialTransaction(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      status: status ?? this.status,
      userId: userId ?? this.userId,
      relatedId: relatedId ?? this.relatedId,
      orderId: orderId ?? this.orderId,
      paymentId: paymentId ?? this.paymentId,
      commissionRuleId: commissionRuleId ?? this.commissionRuleId,
      commissionRate: commissionRate ?? this.commissionRate,
      currency: currency ?? this.currency,
      description: description ?? this.description,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      processedBy: processedBy ?? this.processedBy,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      referenceNumber: referenceNumber ?? this.referenceNumber,
    );
  }

  // Helper methods
  bool get isPending => status == TransactionStatus.pending;
  bool get isCompleted => status == TransactionStatus.completed;
  bool get isFailed => status == TransactionStatus.failed;
  bool get isProcessing => status == TransactionStatus.processing;

  String get typeDisplayName {
    switch (type) {
      case TransactionType.purchase:
        return 'Purchase';
      case TransactionType.withdrawal:
        return 'Withdrawal';
      case TransactionType.deposit:
        return 'Deposit';
      case TransactionType.commission:
        return 'Commission';
      case TransactionType.refund:
        return 'Refund';
      case TransactionType.payment:
        return 'Payment';
      case TransactionType.adjustment:
        return 'Adjustment';
      default:
        return 'Unknown';
    }
  }

  String get statusDisplayName {
    switch (status) {
      case TransactionStatus.pending:
        return 'Pending';
      case TransactionStatus.completed:
        return 'Completed';
      case TransactionStatus.failed:
        return 'Failed';
      case TransactionStatus.cancelled:
        return 'Cancelled';
      case TransactionStatus.processing:
        return 'Processing';
      case TransactionStatus.reversed:
        return 'Reversed';
      default:
        return 'Unknown';
    }
  }

  // Commission calculation helper
  double? calculateCommission(double baseAmount) {
    if (commissionRate == null) return null;
    return baseAmount * (commissionRate! / 100);
  }
}
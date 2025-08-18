import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jengamate/models/enums/payment_enums.dart';


class PaymentModel {
  final String id;
  final String orderId;
  final String userId;
  final double amount;
  final PaymentStatus status;
  final PaymentMethod method;
  final String? proofUrl;
  final String? transactionId;
  final String? referenceNumber;
  final String? notes;
  final String? verifiedBy;
  final DateTime? verifiedAt;
  final String? rejectionReason;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  PaymentModel({
    required this.id,
    required this.orderId,
    required this.userId,
    required this.amount,
    required this.status,
    required this.method,
    this.proofUrl,
    this.transactionId,
    this.referenceNumber,
    this.notes,
    this.verifiedBy,
    this.verifiedAt,
    this.rejectionReason,
    this.metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory PaymentModel.fromMap(Map<String, dynamic> data) {
    // Parse payment status
    PaymentStatus paymentStatus = PaymentStatus.values.firstWhere(
      (e) => e.toString().split('.').last == (data['status'] as String? ?? '').toLowerCase(),
      orElse: () => PaymentStatus.pending,
    );

    // Parse payment method
    PaymentMethod paymentMethod = PaymentMethod.values.firstWhere(
      (e) => e.toString().split('.').last == (data['method'] as String? ?? '').toLowerCase(),
      orElse: () => PaymentMethod.mpesa, // Default to mpesa as per new enum
    );

    return PaymentModel(
      id: data['id'] ?? '',
      orderId: data['orderId'] ?? '',
      userId: data['userId'] ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      status: paymentStatus,
      method: paymentMethod,
      proofUrl: data['proofUrl'],
      transactionId: data['transactionId'],
      referenceNumber: data['referenceNumber'],
      notes: data['notes'],
      verifiedBy: data['verifiedBy'],
      verifiedAt: (data['verifiedAt'] as Timestamp?)?.toDate(),
      rejectionReason: data['rejectionReason'],
      metadata: data['metadata'] as Map<String, dynamic>?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  factory PaymentModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // Parse payment status
    PaymentStatus paymentStatus = PaymentStatus.values.firstWhere(
      (e) => e.toString().split('.').last == (data['status'] as String? ?? '').toLowerCase(),
      orElse: () => PaymentStatus.pending,
    );

    // Parse payment method
    PaymentMethod paymentMethod = PaymentMethod.values.firstWhere(
      (e) => e.toString().split('.').last == (data['method'] as String? ?? '').toLowerCase(),
      orElse: () => PaymentMethod.mpesa, // Default to mpesa as per new enum
    );

    return PaymentModel(
      id: doc.id,
      orderId: data['orderId'] ?? '',
      userId: data['userId'] ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      status: paymentStatus,
      method: paymentMethod,
      proofUrl: data['proofUrl'],
      transactionId: data['transactionId'],
      referenceNumber: data['referenceNumber'],
      notes: data['notes'],
      verifiedBy: data['verifiedBy'],
      verifiedAt: (data['verifiedAt'] as Timestamp?)?.toDate(),
      rejectionReason: data['rejectionReason'],
      metadata: data['metadata'] as Map<String, dynamic>?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'orderId': orderId,
      'userId': userId,
      'amount': amount,
      'status': status.toString().split('.').last,
      'method': method.toString().split('.').last,
      'proofUrl': proofUrl,
      'transactionId': transactionId,
      'referenceNumber': referenceNumber,
      'notes': notes,
      'verifiedBy': verifiedBy,
      'verifiedAt': verifiedAt != null ? Timestamp.fromDate(verifiedAt!) : null,
      'rejectionReason': rejectionReason,
      'metadata': metadata,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  PaymentModel copyWith({
    String? id,
    String? orderId,
    String? userId,
    double? amount,
    PaymentStatus? status,
    PaymentMethod? method,
    String? proofUrl,
    String? transactionId,
    String? referenceNumber,
    String? notes,
    String? verifiedBy,
    DateTime? verifiedAt,
    String? rejectionReason,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PaymentModel(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      method: method ?? this.method,
      proofUrl: proofUrl ?? this.proofUrl,
      transactionId: transactionId ?? this.transactionId,
      referenceNumber: referenceNumber ?? this.referenceNumber,
      notes: notes ?? this.notes,
      verifiedBy: verifiedBy ?? this.verifiedBy,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper methods
  bool get isPending => status == PaymentStatus.pending;
  bool get isVerified => status == PaymentStatus.verified;
  bool get isRejected => status == PaymentStatus.rejected;
  bool get isCancelled => status == PaymentStatus.cancelled;
  bool get isProcessing => status == PaymentStatus.processing;

  String get statusDisplayName {
    return status.toString().split('.').last.replaceAllMapped(
          RegExp(r'([A-Z])'),
          (match) => ' ${match.group(1)}',
        ).trim();
  }

  String get methodDisplayName {
    return method.toString().split('.').last.replaceAllMapped(
          RegExp(r'([A-Z])'),
          (match) => ' ${match.group(1)}',
        ).trim();
  }

  // Status update methods
  PaymentModel markAsVerified(String verifiedByUser) {
    return copyWith(
      status: PaymentStatus.verified,
      verifiedBy: verifiedByUser,
      verifiedAt: DateTime.now(),
    );
  }

  PaymentModel markAsRejected(String reason) {
    return copyWith(
      status: PaymentStatus.rejected,
      rejectionReason: reason,
    );
  }

  PaymentModel markAsCancelled() {
    return copyWith(status: PaymentStatus.cancelled);
  }

  PaymentModel markAsProcessing() {
    return copyWith(status: PaymentStatus.processing);
  }
}
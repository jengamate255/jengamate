import 'package:cloud_firestore/cloud_firestore.dart';

enum TransactionType {
  commission,
  withdrawal,
  deposit,
  refund,
  payment,
  fee,
  bonus,
  penalty,
  adjustment,
  transfer,
  purchase,
}

enum TransactionStatus {
  pending,
  completed,
  failed,
  cancelled,
  refunded,
}

class FinancialTransactionModel {
  final String uid;
  final String userId;
  final String userName;
  final TransactionType type;
  final TransactionStatus status;
  final double amount;
  final String currency;
  final String description;
  final String? referenceId;
  final String? orderId;
  final String? paymentMethod;
  final DateTime timestamp;
  final DateTime? processedAt;
  final Map<String, dynamic>? metadata;
  final String? notes;

  FinancialTransactionModel({
    required this.uid,
    required this.userId,
    required this.userName,
    required this.type,
    required this.status,
    required this.amount,
    required this.currency,
    required this.description,
    this.referenceId,
    this.orderId,
    this.paymentMethod,
    required this.timestamp,
    this.processedAt,
    this.metadata,
    this.notes,
  });

  factory FinancialTransactionModel.fromMap(Map<String, dynamic> map) {
    return FinancialTransactionModel(
      uid: map['uid'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      type: TransactionType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => TransactionType.adjustment,
      ),
      status: TransactionStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => TransactionStatus.pending,
      ),
      amount: (map['amount'] ?? 0).toDouble(),
      currency: map['currency'] ?? 'TZS',
      description: map['description'] ?? '',
      referenceId: map['referenceId'],
      orderId: map['orderId'],
      paymentMethod: map['paymentMethod'],
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      processedAt: map['processedAt'] != null
          ? (map['processedAt'] as Timestamp).toDate()
          : null,
      metadata: map['metadata'] as Map<String, dynamic>?,
      notes: map['notes'],
    );
  }

  factory FinancialTransactionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FinancialTransactionModel.fromMap(data);
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'userId': userId,
      'userName': userName,
      'type': type.name,
      'status': status.name,
      'amount': amount,
      'currency': currency,
      'description': description,
      'referenceId': referenceId,
      'orderId': orderId,
      'paymentMethod': paymentMethod,
      'timestamp': Timestamp.fromDate(timestamp),
      'processedAt':
          processedAt != null ? Timestamp.fromDate(processedAt!) : null,
      'metadata': metadata,
      'notes': notes,
    };
  }

  Map<String, dynamic> toFirestore() {
    return toMap();
  }

  FinancialTransactionModel copyWith({
    String? uid,
    String? userId,
    String? userName,
    TransactionType? type,
    TransactionStatus? status,
    double? amount,
    String? currency,
    String? description,
    String? referenceId,
    String? orderId,
    String? paymentMethod,
    DateTime? timestamp,
    DateTime? processedAt,
    Map<String, dynamic>? metadata,
    String? notes,
  }) {
    return FinancialTransactionModel(
      uid: uid ?? this.uid,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      type: type ?? this.type,
      status: status ?? this.status,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      description: description ?? this.description,
      referenceId: referenceId ?? this.referenceId,
      orderId: orderId ?? this.orderId,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      timestamp: timestamp ?? this.timestamp,
      processedAt: processedAt ?? this.processedAt,
      metadata: metadata ?? this.metadata,
      notes: notes ?? this.notes,
    );
  }

  // Compatibility getters for legacy call sites
  String get id => uid;
  DateTime get createdAt => timestamp;
  DateTime get updatedAt => processedAt ?? timestamp;
  String? get referenceNumber => referenceId;
  String? get relatedId => orderId;
  String? get descriptionOrNull => description.isEmpty ? null : description;

  // Computed properties
  String get formattedAmount {
    return '${amount >= 0 ? '+' : ''}${currency} ${amount.abs().toStringAsFixed(2)}';
  }

  String get typeDisplayName {
    switch (type) {
      case TransactionType.commission:
        return 'Commission';
      case TransactionType.withdrawal:
        return 'Withdrawal';
      case TransactionType.deposit:
        return 'Deposit';
      case TransactionType.refund:
        return 'Refund';
      case TransactionType.payment:
        return 'Payment';
      case TransactionType.fee:
        return 'Fee';
      case TransactionType.bonus:
        return 'Bonus';
      case TransactionType.penalty:
        return 'Penalty';
      case TransactionType.adjustment:
        return 'Adjustment';
      case TransactionType.transfer:
        return 'Transfer';
      case TransactionType.purchase:
        return 'Purchase';
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
      case TransactionStatus.refunded:
        return 'Refunded';
    }
  }

  bool get isCredit => amount >= 0;
  bool get isDebit => amount < 0;
  bool get isPending => status == TransactionStatus.pending;
  bool get isCompleted => status == TransactionStatus.completed;
  bool get isFailed => status == TransactionStatus.failed;

  // Helper methods
  FinancialTransactionModel markAsCompleted({DateTime? processedAt}) {
    return copyWith(
      status: TransactionStatus.completed,
      processedAt: processedAt ?? DateTime.now(),
    );
  }

  FinancialTransactionModel markAsFailed({String? failureReason}) {
    return copyWith(
      status: TransactionStatus.failed,
      notes: failureReason,
    );
  }

  // Static factory methods for common transaction types
  static FinancialTransactionModel commission({
    required String userId,
    required String userName,
    required double amount,
    required String orderId,
    String? referenceId,
    String currency = 'TZS',
  }) {
    return FinancialTransactionModel(
      uid: '',
      userId: userId,
      userName: userName,
      type: TransactionType.commission,
      status: TransactionStatus.completed,
      amount: amount,
      currency: currency,
      description: 'Commission earned from order #$orderId',
      referenceId: referenceId,
      orderId: orderId,
      timestamp: DateTime.now(),
      processedAt: DateTime.now(),
    );
  }

  static FinancialTransactionModel withdrawal({
    required String userId,
    required String userName,
    required double amount,
    String? paymentMethod,
    String currency = 'TZS',
  }) {
    return FinancialTransactionModel(
      uid: '',
      userId: userId,
      userName: userName,
      type: TransactionType.withdrawal,
      status: TransactionStatus.pending,
      amount: -amount.abs(), // Negative for debit
      currency: currency,
      description: 'Withdrawal request',
      paymentMethod: paymentMethod,
      timestamp: DateTime.now(),
    );
  }

  static FinancialTransactionModel deposit({
    required String userId,
    required String userName,
    required double amount,
    String? paymentMethod,
    String? referenceId,
    String currency = 'TZS',
  }) {
    return FinancialTransactionModel(
      uid: '',
      userId: userId,
      userName: userName,
      type: TransactionType.deposit,
      status: TransactionStatus.completed,
      amount: amount,
      currency: currency,
      description: 'Deposit to account',
      paymentMethod: paymentMethod,
      referenceId: referenceId,
      timestamp: DateTime.now(),
      processedAt: DateTime.now(),
    );
  }

  static FinancialTransactionModel fee({
    required String userId,
    required String userName,
    required double amount,
    required String description,
    String? orderId,
    String currency = 'TZS',
  }) {
    return FinancialTransactionModel(
      uid: '',
      userId: userId,
      userName: userName,
      type: TransactionType.fee,
      status: TransactionStatus.completed,
      amount: -amount.abs(), // Negative for debit
      currency: currency,
      description: description,
      orderId: orderId,
      timestamp: DateTime.now(),
      processedAt: DateTime.now(),
    );
  }

  // Utility methods for filtering and sorting
  static List<FinancialTransactionModel> filterByType(
    List<FinancialTransactionModel> transactions,
    TransactionType type,
  ) {
    return transactions.where((t) => t.type == type).toList();
  }

  static List<FinancialTransactionModel> filterByStatus(
    List<FinancialTransactionModel> transactions,
    TransactionStatus status,
  ) {
    return transactions.where((t) => t.status == status).toList();
  }

  static List<FinancialTransactionModel> filterByUser(
    List<FinancialTransactionModel> transactions,
    String userId,
  ) {
    return transactions.where((t) => t.userId == userId).toList();
  }

  static List<FinancialTransactionModel> sortByTimestamp(
    List<FinancialTransactionModel> transactions, {
    bool descending = true,
  }) {
    return List<FinancialTransactionModel>.from(transactions)
      ..sort((a, b) {
        return descending
            ? b.timestamp.compareTo(a.timestamp)
            : a.timestamp.compareTo(b.timestamp);
      });
  }

  static double calculateTotalAmount(
    List<FinancialTransactionModel> transactions,
  ) {
    return transactions.fold<double>(0, (sum, t) => sum + t.amount);
  }

  static Map<String, double> calculateTotalsByType(
    List<FinancialTransactionModel> transactions,
  ) {
    final Map<String, double> totals = {};
    for (final transaction in transactions) {
      final typeName = transaction.type.name;
      totals[typeName] = (totals[typeName] ?? 0) + transaction.amount;
    }
    return totals;
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jengamate/models/enums/order_enums.dart';


class OrderModel {
  final String id;
  final String buyerId;
  final String supplierId;
  final double totalAmount;
  final OrderStatus status;
  final OrderType type;
  final String currency;
  final String? quotationId;
  final String? rfqId;
  final bool isLocked;
  final DateTime? expectedDeliveryDate;
  final Map<String, dynamic>? deliveryAddress;
  final String? notes;
  final Map<String, dynamic>? metadata;
  final List<Map<String, dynamic>>? paymentProofs; // New field for payment proofs
  final double? amountPaid; // New field to track total amount paid
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? cancelledBy;
  final String? cancellationReason;
  final DateTime? cancelledAt;

  OrderModel({
    required this.id,
    required this.buyerId,
    required this.supplierId,
    required this.totalAmount,
    required this.status,
    required this.type,
    this.currency = 'USD',
    this.quotationId,
    this.rfqId,
    this.isLocked = false,
    this.expectedDeliveryDate,
    this.deliveryAddress,
    this.notes,
    this.metadata,
    this.paymentProofs,
    this.amountPaid,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.cancelledBy,
    this.cancellationReason,
    this.cancelledAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory OrderModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    // Parse order status
    OrderStatus orderStatus = OrderStatus.values.firstWhere(
      (e) => e.toString().split('.').last == (data['status'] as String? ?? '').toLowerCase(),
      orElse: () => OrderStatus.pending,
    );
    
    // Parse order type
    OrderType orderType = OrderType.values.firstWhere(
      (e) => e.toString().split('.').last == (data['type'] as String? ?? '').toLowerCase(),
      orElse: () => OrderType.product, // Default to product as per new enum
    );

    return OrderModel(
      id: doc.id,
      buyerId: data['buyerId'] ?? '',
      supplierId: data['supplierId'] ?? '',
      totalAmount: (data['totalAmount'] as num?)?.toDouble() ?? 0.0,
      status: orderStatus,
      type: orderType,
      currency: data['currency'] ?? 'USD',
      quotationId: data['quotationId'],
      rfqId: data['rfqId'],
      isLocked: data['isLocked'] ?? false,
      expectedDeliveryDate: data['expectedDeliveryDate']?.toDate(),
      deliveryAddress: data['deliveryAddress'] as Map<String, dynamic>?,
      notes: data['notes'],
      metadata: data['metadata'] as Map<String, dynamic>?,
      paymentProofs: (data['paymentProofs'] as List?)?.map((e) => e as Map<String, dynamic>).toList(),
      amountPaid: (data['amountPaid'] as num?)?.toDouble(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      cancelledBy: data['cancelledBy'],
      cancellationReason: data['cancellationReason'],
      cancelledAt: data['cancelledAt']?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'buyerId': buyerId,
      'supplierId': supplierId,
      'totalAmount': totalAmount,
      'status': status.toString().split('.').last,
      'type': type.toString().split('.').last,
      'currency': currency,
      'quotationId': quotationId,
      'rfqId': rfqId,
      'isLocked': isLocked,
      'expectedDeliveryDate': expectedDeliveryDate != null ? Timestamp.fromDate(expectedDeliveryDate!) : null,
      'deliveryAddress': deliveryAddress,
      'notes': notes,
      'metadata': metadata,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'cancelledBy': cancelledBy,
      'cancellationReason': cancellationReason,
      'cancelledAt': cancelledAt != null ? Timestamp.fromDate(cancelledAt!) : null,
    };
  }

  OrderModel copyWith({
    String? id,
    String? buyerId,
    String? supplierId,
    double? totalAmount,
    OrderStatus? status,
    OrderType? type,
    String? currency,
    String? quotationId,
    String? rfqId,
    bool? isLocked,
    DateTime? expectedDeliveryDate,
    Map<String, dynamic>? deliveryAddress,
    String? notes,
    Map<String, dynamic>? metadata,
    List<Map<String, dynamic>>? paymentProofs,
    double? amountPaid,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? cancelledBy,
    String? cancellationReason,
    DateTime? cancelledAt,
  }) {
    return OrderModel(
      id: id ?? this.id,
      buyerId: buyerId ?? this.buyerId,
      supplierId: supplierId ?? this.supplierId,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      type: type ?? this.type,
      currency: currency ?? this.currency,
      quotationId: quotationId ?? this.quotationId,
      rfqId: rfqId ?? this.rfqId,
      isLocked: isLocked ?? this.isLocked,
      expectedDeliveryDate: expectedDeliveryDate ?? this.expectedDeliveryDate,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      notes: notes ?? this.notes,
      metadata: metadata ?? this.metadata,
      paymentProofs: paymentProofs ?? this.paymentProofs,
      amountPaid: amountPaid ?? this.amountPaid,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      cancelledBy: cancelledBy ?? this.cancelledBy,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      cancelledAt: cancelledAt ?? this.cancelledAt,
    );
  }

  // Helper methods
  bool get isPending => status == OrderStatus.pending;
  bool get isConfirmed => status == OrderStatus.confirmed;
  bool get isProcessing => status == OrderStatus.processing;
  bool get isShipped => status == OrderStatus.shipped;
  bool get isDelivered => status == OrderStatus.delivered;
  bool get isCancelled => status == OrderStatus.cancelled;
  bool get isDisputed => status == OrderStatus.disputed;
  bool get isRefunded => status == OrderStatus.refunded;

  String get statusDisplayName {
    switch (status) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.confirmed:
        return 'Confirmed';
      case OrderStatus.processing:
        return 'Processing';
      case OrderStatus.completed:
        return 'Completed';
      case OrderStatus.shipped:
        return 'Shipped';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
      case OrderStatus.disputed:
        return 'Disputed';
      case OrderStatus.refunded:
        return 'Refunded';
      default:
        return 'Unknown';
    }
  }

  String get typeDisplayName {
    switch (type) {
      case OrderType.product:
        return 'Product';
      case OrderType.standard:
        return 'Standard';
      case OrderType.urgent:
        return 'Urgent';
      case OrderType.bulk:
        return 'Bulk';
      case OrderType.custom:
        return 'Custom';
      default:
        return 'Unknown';
    }
  }

  // Lock management
  OrderModel lock() => copyWith(isLocked: true);
  OrderModel unlock() => copyWith(isLocked: false);
}

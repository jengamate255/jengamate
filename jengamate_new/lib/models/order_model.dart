import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jengamate/models/enums/order_enums.dart';
import 'package:jengamate/models/order_item_model.dart';

class OrderModel {
  final String? id;
  final String customerId;
  final String customerName;
  final String supplierId;
  final String supplierName;
  final List<OrderItem> items;
  final double totalAmount;
  final OrderStatus status;
  final String paymentMethod;
  final String? platformFee;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? metadata;

  // Additional properties
  final String? buyerId;
  final String currency;
  final double? amountPaid;
  final String? orderNumber;
  final String? quotationId;
  final String? rfqId;
  final List<String>? paymentProofs;
  final DateTime? expectedDeliveryDate;
  final String? notes;
  final bool isLocked;
  final bool isDelivered;
  final bool isCancelled;

  OrderModel({
    this.id,
    required this.customerId,
    required this.customerName,
    required this.supplierId,
    required this.supplierName,
    required this.items,
    required this.totalAmount,
    required this.status,
    required this.paymentMethod,
    this.platformFee,
    required this.createdAt,
    required this.updatedAt,
    this.metadata,
    this.buyerId,
    this.currency = 'TSh',
    this.amountPaid,
    this.orderNumber,
    this.quotationId,
    this.rfqId,
    this.paymentProofs,
    this.expectedDeliveryDate,
    this.notes,
    this.isLocked = false,
    this.isDelivered = false,
    this.isCancelled = false,
  });

  String get uid => id ?? '';

  // Computed properties
  double get amountDue => totalAmount - (amountPaid ?? 0.0);
  String get statusDisplayName => status.displayName;
  String get typeDisplayName => 'Standard';

  factory OrderModel.fromMap(Map<String, dynamic> map, {String? docId}) {
    return OrderModel(
      id: docId ?? map['id'],
      customerId: map['customerId'] ?? '',
      customerName: map['customerName'] ?? 'Unknown Customer',
      supplierId: map['supplierId'] ?? '',
      supplierName: map['supplierName'] ?? 'Unknown Supplier',
      items: (map['items'] as List<dynamic>?)
              ?.map((item) => OrderItem.fromMap(item as Map<String, dynamic>))
              .toList() ??
          [],
      totalAmount: (map['totalAmount'] ?? 0).toDouble(),
      status: _parseOrderStatus(map['status']),
      paymentMethod: map['paymentMethod'] ?? 'unknown',
      platformFee: map['platformFee'],
      createdAt: _parseTimestamp(map['createdAt'], fallbackToNow: true),
      updatedAt: _parseTimestamp(map['updatedAt'], fallbackToNow: false),
      metadata: map['metadata'] as Map<String, dynamic>?,
      buyerId: map['buyerId'],
      currency: map['currency'] ?? 'TSh',
      amountPaid: map['amountPaid']?.toDouble(),
      orderNumber: map['orderNumber'],
      quotationId: map['quotationId'],
      rfqId: map['rfqId'],
      paymentProofs: map['paymentProofs'] != null
          ? List<String>.from(map['paymentProofs'])
          : null,
      expectedDeliveryDate:
          _parseOptionalTimestamp(map['expectedDeliveryDate']),
      notes: map['notes'],
      isLocked: map['isLocked'] ?? false,
      isDelivered: map['isDelivered'] ?? false,
      isCancelled: map['isCancelled'] ?? false,
    );
  }

  static OrderStatus _parseOrderStatus(dynamic statusValue) {
    if (statusValue == null) return OrderStatus.pending;
    if (statusValue is String) {
      return OrderStatus.values.firstWhere(
        (e) => e.name == statusValue,
        orElse: () => OrderStatus.pending,
      );
    } else if (statusValue is int) {
      return OrderStatus.values[statusValue];
    }
    return OrderStatus.pending;
  }

  static DateTime _parseTimestamp(dynamic timestamp, {bool fallbackToNow = true}) {
    if (timestamp is Timestamp) {
      return timestamp.toDate();
    }
    if (fallbackToNow) {
      return DateTime.now();
    }
    return DateTime.now();
  }

  static DateTime? _parseOptionalTimestamp(dynamic timestamp) {
    if (timestamp is Timestamp) {
      return timestamp.toDate();
    }
    return null;
  }

  factory OrderModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return OrderModel.fromMap(data, docId: doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'customerId': customerId,
      'customerName': customerName,
      'supplierId': supplierId,
      'supplierName': supplierName,
      'items': items.map((item) => item.toMap()).toList(),
      'totalAmount': totalAmount,
      'status': status.name,
      'paymentMethod': paymentMethod,
      'platformFee': platformFee,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'metadata': metadata,
      'buyerId': buyerId,
      'currency': currency,
      'amountPaid': amountPaid,
      'orderNumber': orderNumber,
      'quotationId': quotationId,
      'rfqId': rfqId,
      'paymentProofs': paymentProofs,
      'expectedDeliveryDate': expectedDeliveryDate != null
          ? Timestamp.fromDate(expectedDeliveryDate!)
          : null,
      'notes': notes,
      'isLocked': isLocked,
      'isDelivered': isDelivered,
      'isCancelled': isCancelled,
    };
  }

  Map<String, dynamic> toFirestore() {
    return toMap();
  }

  OrderModel copyWith({
    String? id,
    String? customerId,
    String? customerName,
    String? supplierId,
    String? supplierName,
    List<OrderItem>? items,
    double? totalAmount,
    OrderStatus? status,
    String? paymentMethod,
    String? platformFee,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
    String? buyerId,
    String? currency,
    double? amountPaid,
    String? orderNumber,
    String? quotationId,
    String? rfqId,
    List<String>? paymentProofs,
    DateTime? expectedDeliveryDate,
    String? notes,
    bool? isLocked,
    bool? isDelivered,
    bool? isCancelled,
  }) {
    return OrderModel(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      supplierId: supplierId ?? this.supplierId,
      supplierName: supplierName ?? this.supplierName,
      items: items ?? this.items,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      platformFee: platformFee ?? this.platformFee,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
      buyerId: buyerId ?? this.buyerId,
      currency: currency ?? this.currency,
      amountPaid: amountPaid ?? this.amountPaid,
      orderNumber: orderNumber ?? this.orderNumber,
      quotationId: quotationId ?? this.quotationId,
      rfqId: rfqId ?? this.rfqId,
      paymentProofs: paymentProofs ?? this.paymentProofs,
      expectedDeliveryDate: expectedDeliveryDate ?? this.expectedDeliveryDate,
      notes: notes ?? this.notes,
      isLocked: isLocked ?? this.isLocked,
      isDelivered: isDelivered ?? this.isDelivered,
      isCancelled: isCancelled ?? this.isCancelled,
    );
  }
}

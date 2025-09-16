// import 'package:cloud_firestore/cloud_firestore.dart'; // Removed Firebase dependency
import 'package:intl/intl.dart';

class InvoiceItem {
  final String id;
  final String description;
  final int quantity;
  final double unitPrice;
  final String? productId;

  const InvoiceItem({
    required this.id,
    required this.description,
    required this.quantity,
    required this.unitPrice,
    this.productId,
  });

  double get total => quantity * unitPrice;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'description': description,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'productId': productId,
    };
  }

  factory InvoiceItem.fromMap(Map<String, dynamic> map) {
    return InvoiceItem(
      id: map['id'] ?? '',
      description: map['description'] ?? '',
      quantity: (map['quantity'] ?? 0).toInt(),
      unitPrice: (map['unitPrice'] ?? 0.0).toDouble(),
      productId: map['productId'],
    );
  }
}

class InvoiceModel {
  final String id;
  final String invoiceNumber;
  final String customerId;
  final String? orderId;
  final String customerName;
  final String customerEmail;
  final String? customerPhone;
  final String? customerAddress;
  final DateTime issueDate;
  final DateTime dueDate;
  final List<InvoiceItem> items;
  final double taxRate;
  final double discountAmount;
  final String status; // draft, sent, paid, overdue, cancelled
  final String? notes;
  final String? termsAndConditions;
  final DateTime? paidDate;
  final String? paymentMethod;
  final String? referenceNumber;
  final String? pdfUrl;
  final String? customerCompany;
  final int paymentTerms;
  final DateTime? lastSentAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  InvoiceModel({
    required this.id,
    required this.invoiceNumber,
    required this.customerId,
    this.orderId,
    required this.customerName,
    required this.customerEmail,
    this.customerPhone,
    this.customerAddress,
    required this.issueDate,
    required this.dueDate,
    required this.items,
    this.taxRate = 16.0,
    this.discountAmount = 0.0,
    this.status = 'draft',
    this.notes,
    this.termsAndConditions,
    this.paidDate,
    this.paymentMethod,
    this.referenceNumber,
    this.pdfUrl,
    this.customerCompany = '',
    this.paymentTerms = 30,
    this.lastSentAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now().toUtc(),
        updatedAt = updatedAt ?? DateTime.now().toUtc();

  // Calculate subtotal (sum of all items before tax and discount)
  double get subtotal {
    return items.fold(0.0, (sum, item) => sum + item.total);
  }

  // Calculate tax amount
  double get taxAmount => subtotal * (taxRate / 100);

  // Calculate total amount after tax and discount
  double get totalAmount => (subtotal + taxAmount) - discountAmount;

  // Format currency
  String formatCurrency(double amount) {
    return NumberFormat.currency(
      symbol: 'TSh ',
      decimalDigits: 2,
    ).format(amount);
  }

  // Convert to map for Supabase
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'invoiceNumber': invoiceNumber,
      'customerId': customerId,
      'orderId': orderId,
      'customerName': customerName,
      'customerEmail': customerEmail,
      'customerPhone': customerPhone,
      'customerAddress': customerAddress,
      'customerCompany': customerCompany,
      'issueDate': issueDate.toIso8601String(),
      'dueDate': dueDate.toIso8601String(),
      'items': items.map((item) => item.toMap()).toList(),
      'taxRate': taxRate,
      'discountAmount': discountAmount,
      'status': status,
      'notes': notes,
      'termsAndConditions': termsAndConditions,
      'paidDate': paidDate?.toIso8601String(),
      'paymentMethod': paymentMethod,
      'referenceNumber': referenceNumber,
      'pdfUrl': pdfUrl,
      'paymentTerms': paymentTerms,
      'lastSentAt': lastSentAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Create from Map (e.g., from Supabase JSON response)
  factory InvoiceModel.fromMap(Map<String, dynamic> map) {
    return InvoiceModel(
      id: map['id'] is String ? map['id'] : '',
      invoiceNumber:
          map['invoiceNumber'] is String ? map['invoiceNumber'] : '',
      customerId: map['customerId'] is String ? map['customerId'] : '',
      orderId: map['orderId'] is String ? map['orderId'] : null,
      customerName: map['customerName'] is String ? map['customerName'] : '',
      customerEmail:
          map['customerEmail'] is String ? map['customerEmail'] : '',
      customerPhone:
          map['customerPhone'] is String ? map['customerPhone'] : null,
      customerAddress:
          map['customerAddress'] is String ? map['customerAddress'] : null,
      customerCompany:
          map['customerCompany'] is String ? map['customerCompany'] : '',
      issueDate: _parseDateTime(map['issueDate']),
      dueDate: _parseDateTime(map['dueDate']),
      items: (map['items'] as List<dynamic>?)
              ?.map((item) =>
                  InvoiceItem.fromMap(Map<String, dynamic>.from(item)))
              .toList() ??
          [],
      taxRate: (map['taxRate'] ?? 0.0).toDouble(),
      discountAmount: (map['discountAmount'] ?? 0.0).toDouble(),
      status: map['status'] is String ? map['status'] : 'draft',
      notes: map['notes'] is String ? map['notes'] : null,
      termsAndConditions: map['termsAndConditions'] is String
          ? map['termsAndConditions']
          : null,
      paidDate: _parseOptionalDateTime(map['paidDate']),
      paymentMethod:
          map['paymentMethod'] is String ? map['paymentMethod'] : null,
      referenceNumber:
          map['referenceNumber'] is String ? map['referenceNumber'] : null,
      pdfUrl: map['pdfUrl'] is String ? map['pdfUrl'] : null,
      paymentTerms: (map['paymentTerms'] ?? 30).toInt(),
      lastSentAt: _parseOptionalDateTime(map['lastSentAt']),
      createdAt: _parseDateTime(map['createdAt']),
      updatedAt: _parseDateTime(map['updatedAt']),
    );
  }

  // Create from Firestore document (now also uses fromMap)
  factory InvoiceModel.fromFirestore(Map<String, dynamic> data, {required String docId}) {
    return InvoiceModel.fromMap({
      ...data,
      'id': docId, // Ensure the Firebase document ID is used as the InvoiceModel's ID
    });
  }

  // Helper method to parse timestamps safely from Firestore
  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    
    if (value is String) {
      return DateTime.parse(value);
    }
    
    if (value is DateTime) {
      return value;
    }
    
    // Handle Firestore Timestamp
    if (value.runtimeType.toString().contains('Timestamp')) {
      try {
        return value.toDate();
      } catch (e) {
        print('Error converting Timestamp to DateTime: $e');
        return DateTime.now();
      }
    }
    
    return DateTime.now();
  }

  // Helper method to parse optional timestamps safely from Firestore
  static DateTime? _parseOptionalDateTime(dynamic value) {
    if (value == null) return null;
    
    if (value is String) {
      return DateTime.tryParse(value);
    }
    
    if (value is DateTime) {
      return value;
    }
    
    // Handle Firestore Timestamp
    if (value.runtimeType.toString().contains('Timestamp')) {
      try {
        return value.toDate();
      } catch (e) {
        print('Error converting Timestamp to DateTime: $e');
        return null;
      }
    }
    
    return null;
  }

  // Create a copy with some fields updated
  InvoiceModel copyWith({
    String? id,
    String? invoiceNumber,
    String? customerId,
    String? orderId,
    String? customerName,
    String? customerEmail,
    String? customerPhone,
    String? customerAddress,
    String? customerCompany,
    DateTime? issueDate,
    DateTime? dueDate,
    List<InvoiceItem>? items,
    double? taxRate,
    double? discountAmount,
    String? status,
    String? notes,
    String? termsAndConditions,
    DateTime? paidDate,
    String? paymentMethod,
    String? referenceNumber,
    String? pdfUrl,
    int? paymentTerms,
    DateTime? lastSentAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return InvoiceModel(
      id: id ?? this.id,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      customerId: customerId ?? this.customerId,
      orderId: orderId ?? this.orderId,
      customerName: customerName ?? this.customerName,
      customerEmail: customerEmail ?? this.customerEmail,
      customerPhone: customerPhone ?? this.customerPhone,
      customerAddress: customerAddress ?? this.customerAddress,
      customerCompany: customerCompany ?? this.customerCompany,
      issueDate: issueDate ?? this.issueDate,
      dueDate: dueDate ?? this.dueDate,
      items: items ?? this.items,
      taxRate: taxRate ?? this.taxRate,
      discountAmount: discountAmount ?? this.discountAmount,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      termsAndConditions: termsAndConditions ?? this.termsAndConditions,
      paidDate: paidDate ?? this.paidDate,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      referenceNumber: referenceNumber ?? this.referenceNumber,
      pdfUrl: pdfUrl ?? this.pdfUrl,
      paymentTerms: paymentTerms ?? this.paymentTerms,
      lastSentAt: lastSentAt ?? this.lastSentAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Generate a new invoice number (you can customize this based on your needs)
  static String generateInvoiceNumber() {
    final now = DateTime.now();
    final year = now.year.toString().substring(2);
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    final random = (DateTime.now().millisecondsSinceEpoch % 10000)
        .toString()
        .padLeft(4, '0');

    return 'INV-$year$month$day-$random';
  }
}

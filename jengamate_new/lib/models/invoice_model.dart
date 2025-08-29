import 'package:cloud_firestore/cloud_firestore.dart';
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
  }) :
    createdAt = createdAt ?? DateTime.now().toUtc(),
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

  // Convert to map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'invoiceNumber': invoiceNumber,
      'customerId': customerId,
      'customerName': customerName,
      'customerEmail': customerEmail,
      'customerPhone': customerPhone,
      'customerAddress': customerAddress,
      'customerCompany': customerCompany,
      'issueDate': Timestamp.fromDate(issueDate),
      'dueDate': Timestamp.fromDate(dueDate),
      'items': items.map((item) => item.toMap()).toList(),
      'taxRate': taxRate,
      'discountAmount': discountAmount,
      'status': status,
      'notes': notes,
      'termsAndConditions': termsAndConditions,
      'paidDate': paidDate != null ? Timestamp.fromDate(paidDate!) : null,
      'paymentMethod': paymentMethod,
      'referenceNumber': referenceNumber,
      'pdfUrl': pdfUrl,
      'paymentTerms': paymentTerms,
      'lastSentAt': lastSentAt != null ? Timestamp.fromDate(lastSentAt!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Create from Firestore document
  factory InvoiceModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return InvoiceModel(
      id: data['id'] ?? '',
      invoiceNumber: data['invoiceNumber'] ?? '',
      customerId: data['customerId'] ?? '',
      customerName: data['customerName'] ?? '',
      customerEmail: data['customerEmail'] ?? '',
      customerPhone: data['customerPhone'],
      customerAddress: data['customerAddress'],
      customerCompany: data['customerCompany'] ?? '',
      issueDate: (data['issueDate'] as Timestamp).toDate(),
      dueDate: (data['dueDate'] as Timestamp).toDate(),
      items: (data['items'] as List<dynamic>?)
              ?.map((item) => InvoiceItem.fromMap(Map<String, dynamic>.from(item)))
              .toList() ??
          [],
      taxRate: (data['taxRate'] ?? 0.0).toDouble(),
      discountAmount: (data['discountAmount'] ?? 0.0).toDouble(),
      status: data['status'] ?? 'draft',
      notes: data['notes'],
      termsAndConditions: data['termsAndConditions'],
      paidDate: data['paidDate'] != null ? (data['paidDate'] as Timestamp).toDate() : null,
      paymentMethod: data['paymentMethod'],
      referenceNumber: data['referenceNumber'],
      pdfUrl: data['pdfUrl'],
      paymentTerms: (data['paymentTerms'] ?? 30).toInt(),
      lastSentAt: data['lastSentAt'] != null ? (data['lastSentAt'] as Timestamp).toDate() : null,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  // Create a copy with some fields updated
  InvoiceModel copyWith({
    String? id,
    String? invoiceNumber,
    String? customerId,
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
    final random = (DateTime.now().millisecondsSinceEpoch % 10000).toString().padLeft(4, '0');
    
    return 'INV-$year$month$day-$random';
  }
}

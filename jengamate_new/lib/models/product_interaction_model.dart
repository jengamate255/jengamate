// import 'package:cloud_firestore/cloud_firestore.dart'; // Removed Firebase dependency

/// Model for tracking product interactions and clicks
class ProductInteractionModel {
  final String id;
  final String productId;
  final String productName;
  final String userId;
  final String userName;
  final String userEmail;
  final String userRole; // engineer, supplier, admin
  final String interactionType; // view, rfq_click, inquiry_click, favorite, share
  final DateTime timestamp;
  final Map<String, dynamic> productDetails;
  final Map<String, dynamic> userContext;
  final String? sessionId;
  final String? deviceInfo;
  final String? location;

  ProductInteractionModel({
    required this.id,
    required this.productId,
    required this.productName,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.userRole,
    required this.interactionType,
    required this.timestamp,
    required this.productDetails,
    required this.userContext,
    this.sessionId,
    this.deviceInfo,
    this.location,
  });

  factory ProductInteractionModel.fromFirestore(Map<String, dynamic> data, {required String docId}) {
    return ProductInteractionModel(
      id: docId,
      productId: data['productId'] ?? '',
      productName: data['productName'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userEmail: data['userEmail'] ?? '',
      userRole: data['userRole'] ?? '',
      interactionType: data['interactionType'] ?? '',
      timestamp: (data['timestamp'] is String) ? DateTime.parse(data['timestamp']) : _parseOptionalDateTime(data['timestamp']) ?? DateTime.now(),
      productDetails: Map<String, dynamic>.from(data['productDetails'] ?? {}),
      userContext: Map<String, dynamic>.from(data['userContext'] ?? {}),
      sessionId: data['sessionId'],
      deviceInfo: data['deviceInfo'],
      location: data['location'],
    );
  }

  factory ProductInteractionModel.fromMap(Map<String, dynamic> data, String docId) {
    return ProductInteractionModel(
      id: docId,
      productId: data['productId'] ?? '',
      productName: data['productName'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userEmail: data['userEmail'] ?? '',
      userRole: data['userRole'] ?? '',
      interactionType: data['interactionType'] ?? '',
      timestamp: (data['timestamp'] is String) ? DateTime.parse(data['timestamp']) : _parseOptionalDateTime(data['timestamp']) ?? DateTime.now(),
      productDetails: Map<String, dynamic>.from(data['productDetails'] ?? {}),
      userContext: Map<String, dynamic>.from(data['userContext'] ?? {}),
      sessionId: data['sessionId'],
      deviceInfo: data['deviceInfo'],
      location: data['location'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'userRole': userRole,
      'interactionType': interactionType,
      'timestamp': timestamp.toIso8601String(),
      'productDetails': productDetails,
      'userContext': userContext,
      'sessionId': sessionId,
      'deviceInfo': deviceInfo,
      'location': location,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productId': productId,
      'productName': productName,
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'userRole': userRole,
      'interactionType': interactionType,
      'timestamp': timestamp.toIso8601String(),
      'productDetails': productDetails,
      'userContext': userContext,
      'sessionId': sessionId,
      'deviceInfo': deviceInfo,
      'location': location,
    };
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
        return value.toDate(); // This is the key fix!
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
}

/// Model for RFQ tracking with enhanced details
class RFQTrackingModel {
  final String id;
  final String rfqId;
  final String productId;
  final String productName;
  final String engineerId;
  final String engineerName;
  final String engineerEmail;
  final String? supplierId;
  final String? supplierName;
  final String status; // initiated, viewed_by_supplier, quoted, accepted, rejected
  final DateTime createdAt;
  final DateTime? lastUpdated;
  final Map<String, dynamic> productSpecs;
  final Map<String, dynamic> rfqDetails;
  final List<String> supplierViews; // List of supplier IDs who viewed this RFQ
  final List<Map<String, dynamic>> statusHistory;
  final int quantity;
  final String? preferredDeliveryDate;
  final String? budgetRange;

  RFQTrackingModel({
    required this.id,
    required this.rfqId,
    required this.productId,
    required this.productName,
    required this.engineerId,
    required this.engineerName,
    required this.engineerEmail,
    this.supplierId,
    this.supplierName,
    required this.status,
    required this.createdAt,
    this.lastUpdated,
    required this.productSpecs,
    required this.rfqDetails,
    required this.supplierViews,
    required this.statusHistory,
    required this.quantity,
    this.preferredDeliveryDate,
    this.budgetRange,
  });

  factory RFQTrackingModel.fromFirestore(Map<String, dynamic> data, {required String docId}) {
    return RFQTrackingModel(
      id: docId,
      rfqId: data['rfqId'] ?? '',
      productId: data['productId'] ?? '',
      productName: data['productName'] ?? '',
      engineerId: data['engineerId'] ?? '',
      engineerName: data['engineerName'] ?? '',
      engineerEmail: data['engineerEmail'] ?? '',
      supplierId: data['supplierId'],
      supplierName: data['supplierName'],
      status: data['status'] ?? 'initiated',
      createdAt: (data['createdAt'] is String) ? DateTime.parse(data['createdAt']) : _parseOptionalDateTime(data['createdAt']) ?? DateTime.now(),
      lastUpdated: (data['lastUpdated'] is String) ? DateTime.parse(data['lastUpdated']) : null,
      productSpecs: Map<String, dynamic>.from(data['productSpecs'] ?? {}),
      rfqDetails: Map<String, dynamic>.from(data['rfqDetails'] ?? {}),
      supplierViews: List<String>.from(data['supplierViews'] ?? []),
      statusHistory: List<Map<String, dynamic>>.from(data['statusHistory'] ?? []),
      quantity: data['quantity'] ?? 0,
      preferredDeliveryDate: data['preferredDeliveryDate'],
      budgetRange: data['budgetRange'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'rfqId': rfqId,
      'productId': productId,
      'productName': productName,
      'engineerId': engineerId,
      'engineerName': engineerName,
      'engineerEmail': engineerEmail,
      'supplierId': supplierId,
      'supplierName': supplierName,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'lastUpdated': lastUpdated?.toIso8601String(),
      'productSpecs': productSpecs,
      'rfqDetails': rfqDetails,
      'supplierViews': supplierViews,
      'statusHistory': statusHistory,
      'quantity': quantity,
      'preferredDeliveryDate': preferredDeliveryDate,
      'budgetRange': budgetRange,
    };
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
        return value.toDate(); // This is the key fix!
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
}

/// Analytics model for RFQ insights
class RFQAnalyticsModel {
  final String productId;
  final String productName;
  final int totalViews;
  final int totalRFQs;
  final int totalQuotes;
  final double conversionRate; // RFQs / Views
  final double quoteRate; // Quotes / RFQs
  final List<String> topEngineers; // Most active engineers
  final List<String> topSuppliers; // Most responsive suppliers
  final Map<String, int> statusBreakdown;
  final DateTime lastUpdated;

  RFQAnalyticsModel({
    required this.productId,
    required this.productName,
    required this.totalViews,
    required this.totalRFQs,
    required this.totalQuotes,
    required this.conversionRate,
    required this.quoteRate,
    required this.topEngineers,
    required this.topSuppliers,
    required this.statusBreakdown,
    required this.lastUpdated,
  });

  factory RFQAnalyticsModel.fromMap(Map<String, dynamic> data) {
    return RFQAnalyticsModel(
      productId: data['productId'] ?? '',
      productName: data['productName'] ?? '',
      totalViews: data['totalViews'] ?? 0,
      totalRFQs: data['totalRFQs'] ?? 0,
      totalQuotes: data['totalQuotes'] ?? 0,
      conversionRate: (data['conversionRate'] ?? 0.0).toDouble(),
      quoteRate: (data['quoteRate'] ?? 0.0).toDouble(),
      topEngineers: List<String>.from(data['topEngineers'] ?? []),
      topSuppliers: List<String>.from(data['topSuppliers'] ?? []),
      statusBreakdown: Map<String, int>.from(data['statusBreakdown'] ?? {}),
      lastUpdated: DateTime.parse(data['lastUpdated'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'totalViews': totalViews,
      'totalRFQs': totalRFQs,
      'totalQuotes': totalQuotes,
      'conversionRate': conversionRate,
      'quoteRate': quoteRate,
      'topEngineers': topEngineers,
      'topSuppliers': topSuppliers,
      'statusBreakdown': statusBreakdown,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
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
        return value.toDate(); // This is the key fix!
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
}

import 'package:cloud_firestore/cloud_firestore.dart';

class Inquiry {
  final String uid;
  final String userId;
  final String userName;
  final String userEmail;
  final String subject;
  final String description;
  final String
      category; // 'product', 'service', 'quotation', 'support', 'general'
  final String priority; // 'low', 'medium', 'high', 'urgent'
  final String
      status; // 'open', 'in_progress', 'waiting_for_response', 'resolved', 'closed'
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? resolvedAt;
  final String? assignedTo;
  final String? assignedToName;
  final String? response;
  final List<String> tags;
  final Map<String, dynamic>? projectInfo; // For project-specific inquiries
  final List<String>?
      products; // Product IDs if inquiry is about specific products
  final Map<String, dynamic>? metadata;

  Inquiry({
    required this.uid,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.subject,
    required this.description,
    required this.category,
    required this.priority,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.resolvedAt,
    this.assignedTo,
    this.assignedToName,
    this.response,
    required this.tags,
    this.projectInfo,
    this.products,
    this.metadata,
  });

  factory Inquiry.fromMap(Map<String, dynamic> map) {
    // Validate required fields to prevent incomplete inquiry errors
    final userId = map['userId'] ?? 'unknown_user'; // Provide a default
    final subject = map['subject'] ?? 'No Subject'; // Provide a default
    final uid = map['uid'] ??
        ''; // uid is used for display, so empty might be okay if it's a new inquiry being created

    // Silently assign defaults for missing fields to reduce console noise
    if (userId == 'unknown_user') {
      // Silent default assignment
    }
    if (subject == 'No Subject') {
      // Silent default assignment
    }

    // Safe products parsing - handles both List<String> and List<Map>
    List<String>? safeProducts;
    final rawProducts = map['products'];
    if (rawProducts is List) {
      List<String> result = [];
      for (var item in rawProducts) {
        if (item is String) {
          result.add(item);
        } else if (item is Map) {
          if (item['id'] is String) {
            result.add(item['id']);
          } else {
            // Create ID from available fields
            String id = '';
            if (item['type'] is String) id = item['type'];
            if (item['quantity'] != null) id += '_${item['quantity']}';
            if (item['color'] is String) id += '_${item['color']}';
            if (item['length'] != null) id += '_L${item['length']}';
            if (id.isNotEmpty) result.add(id);
          }
        }
      }
      safeProducts = result.isNotEmpty ? result : null;
    }

    return Inquiry(
      uid: map['uid'] is String ? map['uid'] : '',
      userId: map['userId'] is String ? map['userId'] : 'unknown_user',
      userName: map['userName'] is String ? map['userName'] : 'Unknown User',
      userEmail: map['userEmail'] is String ? map['userEmail'] : 'Unknown',
      subject: map['subject'] is String ? map['subject'] : 'No Subject',
      description: map['description'] is String
          ? map['description']
          : 'No description provided',
      category: map['category'] is String ? map['category'] : 'general',
      priority: map['priority'] is String ? map['priority'] : 'medium',
      status: map['status'] is String ? map['status'] : 'open',
      createdAt: _parseTimestamp(map['createdAt'], fallbackToNow: true),
      updatedAt: _parseTimestamp(map['updatedAt'], fallbackToNow: false),
      resolvedAt: map['resolvedAt'] != null
          ? _parseOptionalTimestamp(map['resolvedAt'])
          : null,
      assignedTo: map['assignedTo'] is String ? map['assignedTo'] : null,
      assignedToName:
          map['assignedToName'] is String ? map['assignedToName'] : null,
      response: map['response'] is String ? map['response'] : null,
      tags: List<String>.from(map['tags'] ?? []),
      projectInfo: map['projectInfo'] is Map<String, dynamic>
          ? map['projectInfo']
          : null,
      products: safeProducts,
      metadata:
          map['metadata'] is Map<String, dynamic> ? map['metadata'] : null,
    );
  }

  // Helper method to parse timestamps safely
  static DateTime _parseTimestamp(dynamic timestamp,
      {bool fallbackToNow = true}) {
    if (timestamp is Timestamp) {
      return timestamp.toDate();
    }
    if (fallbackToNow) {
      return DateTime.now();
    }
    return DateTime.now(); // Fallback anyway
  }

  // Helper method to parse optional timestamps
  static DateTime? _parseOptionalTimestamp(dynamic timestamp) {
    if (timestamp is Timestamp) {
      return timestamp.toDate();
    }
    return null;
  }

  factory Inquiry.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Inquiry.fromMap(data);
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'subject': subject,
      'description': description,
      'category': category,
      'priority': priority,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'resolvedAt': resolvedAt != null ? Timestamp.fromDate(resolvedAt!) : null,
      'assignedTo': assignedTo,
      'assignedToName': assignedToName,
      'response': response,
      'tags': tags,
      'projectInfo': projectInfo,
      'products': products,
      'metadata': metadata,
    };
  }

  Map<String, dynamic> toFirestore() {
    return toMap();
  }

  Inquiry copyWith({
    String? uid,
    String? userId,
    String? userName,
    String? userEmail,
    String? subject,
    String? description,
    String? category,
    String? priority,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? resolvedAt,
    String? assignedTo,
    String? assignedToName,
    String? response,
    List<String>? tags,
    Map<String, dynamic>? projectInfo,
    List<String>? products,
    Map<String, dynamic>? metadata,
  }) {
    return Inquiry(
      uid: uid ?? this.uid,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      subject: subject ?? this.subject,
      description: description ?? this.description,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      assignedTo: assignedTo ?? this.assignedTo,
      assignedToName: assignedToName ?? this.assignedToName,
      response: response ?? this.response,
      tags: tags ?? this.tags,
      projectInfo: projectInfo ?? this.projectInfo,
      products: products ?? this.products,
      metadata: metadata ?? this.metadata,
    );
  }

  // Computed properties
  bool get isOpen => status == 'open';
  bool get isInProgress => status == 'in_progress';
  bool get isResolved => status == 'resolved';
  bool get isClosed => status == 'closed';
  bool get isWaitingForResponse => status == 'waiting_for_response';

  bool get isUrgent => priority == 'urgent';
  bool get isHighPriority => priority == 'high';

  String get statusDisplayName {
    switch (status) {
      case 'open':
        return 'Open';
      case 'in_progress':
        return 'In Progress';
      case 'waiting_for_response':
        return 'Waiting for Response';
      case 'resolved':
        return 'Resolved';
      case 'closed':
        return 'Closed';
      default:
        return 'Unknown';
    }
  }

  String get priorityDisplayName {
    switch (priority) {
      case 'low':
        return 'Low';
      case 'medium':
        return 'Medium';
      case 'high':
        return 'High';
      case 'urgent':
        return 'Urgent';
      default:
        return 'Unknown';
    }
  }

  String get categoryDisplayName {
    switch (category) {
      case 'product':
        return 'Product Inquiry';
      case 'service':
        return 'Service Inquiry';
      case 'quotation':
        return 'Quotation Request';
      case 'support':
        return 'Support Request';
      case 'general':
        return 'General Inquiry';
      default:
        return category.replaceAll('_', ' ').toLowerCase();
    }
  }

  // Helper methods
  Duration get timeToResolution {
    if (resolvedAt == null) return Duration.zero;
    return resolvedAt!.difference(createdAt);
  }

  bool get isOverdue {
    if (isResolved || isClosed) return false;

    final daysOpen = DateTime.now().difference(createdAt).inDays;
    switch (priority) {
      case 'urgent':
        return daysOpen > 1;
      case 'high':
        return daysOpen > 3;
      case 'medium':
        return daysOpen > 7;
      case 'low':
        return daysOpen > 14;
      default:
        return false;
    }
  }

  String get projectName => projectInfo?['projectName'] ?? 'N/A';
  String get deliveryAddress => projectInfo?['deliveryAddress'] ?? 'N/A';
  DateTime? get expectedDeliveryDate {
    final dateStr = projectInfo?['expectedDeliveryDate'];
    if (dateStr is String) {
      return DateTime.tryParse(dateStr);
    }
    return null;
  }

  bool get transportNeeded => projectInfo?['transportNeeded'] ?? false;

  // Static factory methods for common inquiry types
  static Inquiry productInquiry({
    required String userId,
    required String userName,
    required String userEmail,
    required String subject,
    required String description,
    required List<String> productIds,
    String priority = 'medium',
  }) {
    return Inquiry(
      uid: '',
      userId: userId,
      userName: userName,
      userEmail: userEmail,
      subject: subject,
      description: description,
      category: 'product',
      priority: priority,
      status: 'open',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      tags: ['product'],
      products: productIds,
    );
  }

  static Inquiry quotationRequest({
    required String userId,
    required String userName,
    required String userEmail,
    required String subject,
    required String description,
    Map<String, dynamic>? projectInfo,
    String priority = 'high',
  }) {
    return Inquiry(
      uid: '',
      userId: userId,
      userName: userName,
      userEmail: userEmail,
      subject: subject,
      description: description,
      category: 'quotation',
      priority: priority,
      status: 'open',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      tags: ['quotation'],
      projectInfo: projectInfo,
    );
  }

  static Inquiry supportRequest({
    required String userId,
    required String userName,
    required String userEmail,
    required String subject,
    required String description,
    String priority = 'medium',
  }) {
    return Inquiry(
      uid: '',
      userId: userId,
      userName: userName,
      userEmail: userEmail,
      subject: subject,
      description: description,
      category: 'support',
      priority: priority,
      status: 'open',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      tags: ['support'],
    );
  }
}
